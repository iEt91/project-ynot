import 'package:flutter_test/flutter_test.dart';

import 'package:ynot_mobile/src/core/data/local_mock_store.dart';
import 'package:ynot_mobile/src/core/data/local_session_store.dart';
import 'package:ynot_mobile/src/core/models/activity.dart';
import 'package:ynot_mobile/src/core/models/private_feedback.dart';
import 'package:ynot_mobile/src/core/state/app_controller.dart';

void main() {
  group('AppController mock flows', () {
    test('existing local session restores the app on startup', () async {
      final controller = await _buildController(
        sessionStore: _TestSessionStore(
          clientUid: 'persisted_client_001',
          phone: '+82 10 1234 5678',
        ),
        mockStore: _TestMockStore(),
      );

      expect(controller.state.stage, AppStage.ready);
      expect(controller.state.user, isNotNull);
      expect(controller.state.user!.id, 'persisted_client_001');
      expect(controller.state.user!.phoneMasked, contains('5678'));
      expect(controller.state.activities, isNotEmpty);
    });

    test(
      'login with demo code stores a local session and enters the app',
      () async {
        final store = _TestSessionStore();
        final controller = await _buildController(
          sessionStore: store,
          mockStore: _TestMockStore(),
        );

        expect(controller.state.stage, AppStage.phoneAuth);

        controller.updatePhoneInput('+82 10 0000 0000');
        await controller.sendVerificationCode();
        controller.updateVerificationInput('000000');
        await controller.verifyCode();

        expect(controller.state.stage, AppStage.ready);
        expect(controller.state.user, isNotNull);
        expect(store.savedClientUid, isNotNull);
        expect(store.savedPhone, '+82 10 0000 0000');
      },
    );

    test(
      'create activity updates local state and is visible in the map/list',
      () async {
        final controller = await _buildLoggedInController();

        await controller.createActivity(
          title: 'Cafe Talk',
          description: 'Charlita suave y tranquila.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          startTime: DateTime(2026, 6, 1, 18, 0),
          duration: const Duration(hours: 2),
          maxPeople: 6,
          realLat: 37.5563,
          realLng: 126.9228,
          visibility: ActivityVisibility.privateActivity,
        );

        expect(controller.state.activities, isNotEmpty);
        final created = controller.state.activities.first;
        expect(created.title, 'Cafe Talk');
        expect(created.visibility, ActivityVisibility.privateActivity);
        expect(created.status, ActivityStatus.active);
        expect(created.isMine, isTrue);
        expect(created.creatorId, controller.state.user!.id);
        expect(controller.filteredActivities().first.title, 'Cafe Talk');
      },
    );

    test('user cannot create a second active activity', () async {
      final controller = await _buildLoggedInController();

      await controller.createActivity(
        title: 'Cafe Talk',
        description: 'Charlita suave y tranquila.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        startTime: DateTime(2026, 6, 1, 18, 0),
        duration: const Duration(hours: 2),
        maxPeople: 6,
        realLat: 37.5563,
        realLng: 126.9228,
      );

      expect(controller.canCreateActivity(), isFalse);

      await controller.createActivity(
        title: 'Second Talk',
        description: 'Otra actividad.',
        category: 'Study',
        vibe: 'Productive',
        zone: 'Gangnam',
        startTime: DateTime(2026, 6, 1, 20, 0),
        duration: const Duration(hours: 1),
        maxPeople: 4,
        realLat: 37.4981,
        realLng: 127.0276,
      );

      final createdByUser = controller.state.activities
          .where((activity) => activity.creatorId == controller.state.user!.id)
          .toList();
      expect(createdByUser, hasLength(1));
      expect(createdByUser.single.title, 'Cafe Talk');
      expect(
        controller.state.errorMessage,
        'Ya tienes una actividad activa. Elimínala o espera a que termine para crear otra.',
      );
    });

    test('creator can delete own activity', () async {
      final controller = await _buildLoggedInController();

      await controller.createActivity(
        title: 'Cafe Talk',
        description: 'Charlita suave y tranquila.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        startTime: DateTime(2026, 6, 1, 18, 0),
        duration: const Duration(hours: 2),
        maxPeople: 6,
        realLat: 37.5563,
        realLng: 126.9228,
      );

      final createdId = controller.state.activities.first.id;
      expect(await controller.deleteActivity(createdId), isTrue);
      expect(
        controller.state.activities.any((activity) => activity.id == createdId),
        isFalse,
      );
      expect(controller.canCreateActivity(), isTrue);
    });

    test('non-creator cannot delete activity', () async {
      final controller = await _buildLoggedInController();

      await controller.createActivity(
        title: 'Cafe Talk',
        description: 'Charlita suave y tranquila.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        startTime: DateTime(2026, 6, 1, 18, 0),
        duration: const Duration(hours: 2),
        maxPeople: 6,
        realLat: 37.5563,
        realLng: 126.9228,
      );

      final createdId = controller.state.activities.first.id;
      controller.state = controller.state.copyWith(
        user: controller.state.user!.copyWith(id: 'other_user_001'),
      );

      expect(await controller.deleteActivity(createdId), isFalse);
      expect(
        controller.state.activities.any((activity) => activity.id == createdId),
        isTrue,
      );
    });

    test(
      'joining, confirming, cancelling and leaving remain reversible',
      () async {
        final controller = await _buildLoggedInController();
        final activityId = controller.state.activities.first.id;

        await controller.joinActivity(activityId);
        var activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.joinedPendingConfirmation);
        expect(activity.pendingCount, 2);

        await controller.confirmAttendance(activityId);
        activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.confirmed);
        expect(activity.confirmedCount, 4);
        expect(activity.pendingCount, 1);

        await controller.cancelAttendance(activityId);
        activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.cancelled);
        expect(activity.confirmedCount, 3);
        expect(activity.pendingCount, 1);

        await controller.joinActivity(activityId);
        activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.joinedPendingConfirmation);
        expect(activity.pendingCount, 2);

        await controller.leaveActivity(activityId);
        activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.left);
        expect(activity.pendingCount, 1);

        await controller.joinActivity(activityId);
        activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.joinedPendingConfirmation);
        expect(activity.pendingCount, 2);
      },
    );

    test('chat messages are kept in memory while the app is open', () async {
      final controller = await _buildLoggedInController();
      final activityId = controller.state.activities.first.id;

      await controller.joinActivity(activityId);
      await controller.confirmAttendance(activityId);

      await controller.loadChatMessages(activityId);
      expect(controller.state.chatMessages[activityId], isEmpty);

      await controller.sendChatMessage(activityId, 'Hola');
      await controller.sendChatMessage(activityId, 'Ya llegamos?');
      await controller.sendChatMessage(
        activityId,
        'Mantengamos la vibra suave',
      );

      await controller.loadChatMessages(activityId);
      final messages = controller.state.chatMessages[activityId];
      expect(messages, isNotNull);
      expect(messages, hasLength(3));
      expect(
        messages!.map((message) => message.content),
        containsAll(['Hola', 'Ya llegamos?', 'Mantengamos la vibra suave']),
      );
      expect(
        controller.state.activities
            .firstWhere((item) => item.id == activityId)
            .lastMessagePreview,
        'Mantengamos la vibra suave',
      );
    });

    test('private feedback is saved once per reviewer and activity', () async {
      final controller = await _buildLoggedInController();
      final activity = controller.state.activities.first;
      final reviewerId = controller.state.user!.id;
      final reviewedId = activity.feedbackTargets.first.userId;

      await controller.joinActivity(activity.id);

      expect(
        await controller.submitPrivateFeedback(
          activityId: activity.id,
          reviewerUserId: reviewerId,
          reviewedUserId: reviewedId,
          selectedFeedback: PrivateFeedbackOption.goodVibe,
        ),
        isTrue,
      );

      expect(
        await controller.submitPrivateFeedback(
          activityId: activity.id,
          reviewerUserId: reviewerId,
          reviewedUserId: reviewedId,
          selectedFeedback: PrivateFeedbackOption.veryNice,
        ),
        isFalse,
      );
      expect(controller.state.feedbackEntries, hasLength(1));
      expect(
        controller.state.feedbackEntries.first.selectedFeedback,
        PrivateFeedbackOption.goodVibe,
      );
    });

    test(
      'deleting activity removes related state and allows a new activity',
      () async {
        final controller = await _buildLoggedInController();

        await controller.createActivity(
          title: 'Cafe Talk',
          description: 'Charlita suave y tranquila.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          startTime: DateTime(2026, 6, 1, 18, 0),
          duration: const Duration(hours: 2),
          maxPeople: 6,
          realLat: 37.5563,
          realLng: 126.9228,
        );

        final createdId = controller.state.activities.first.id;
        await controller.joinActivity(createdId);
        await controller.confirmAttendance(createdId);
        await controller.sendChatMessage(createdId, 'Hola');

        expect(controller.state.chatMessages[createdId], isNotNull);
        expect(controller.state.chatMessages[createdId], isNotEmpty);

        expect(await controller.deleteActivity(createdId), isTrue);
        expect(
          controller.state.activities.any(
            (activity) => activity.id == createdId,
          ),
          isFalse,
        );
        expect(controller.state.chatMessages.containsKey(createdId), isFalse);
        expect(controller.canCreateActivity(), isTrue);

        await controller.createActivity(
          title: 'Second Cafe',
          description: 'Nueva actividad tras eliminar la anterior.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          startTime: DateTime(2026, 6, 2, 18, 0),
          duration: const Duration(hours: 2),
          maxPeople: 4,
          realLat: 37.5563,
          realLng: 126.9228,
        );

        expect(
          controller.state.activities.any(
            (activity) => activity.title == 'Second Cafe',
          ),
          isTrue,
        );
      },
    );

    test('logout clears the session and returns to auth', () async {
      final controller = await _buildLoggedInController();

      controller.signOut();

      expect(controller.state.stage, AppStage.phoneAuth);
      expect(controller.state.user, isNull);
      expect(controller.state.activities, isEmpty);
    });

    test('local persistence survives controller restart', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final createdActivity = firstController.state.activities.firstWhere(
        (item) => item.id == 'seed_1',
      );
      await firstController.joinActivity(createdActivity.id);
      await firstController.confirmAttendance(createdActivity.id);
      await firstController.sendChatMessage(createdActivity.id, 'Persisted');
      final reviewedId = createdActivity.feedbackTargets.first.userId;
      await firstController.submitPrivateFeedback(
        activityId: createdActivity.id,
        reviewerUserId: firstController.state.user!.id,
        reviewedUserId: reviewedId,
        selectedFeedback: PrivateFeedbackOption.normal,
      );

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.activities, isNotEmpty);
      final restored = secondController.state.activities.firstWhere(
        (item) => item.id == createdActivity.id,
      );
      expect(restored.myStatus, ParticipantStatus.confirmed);
      await secondController.loadChatMessages(createdActivity.id);
      expect(
        secondController.state.chatMessages[createdActivity.id],
        isNotNull,
      );
      expect(
        secondController.state.chatMessages[createdActivity.id]!.last.content,
        'Persisted',
      );
      expect(secondController.state.feedbackEntries, hasLength(1));
    });
  });
}

Future<AppController> _buildController({
  _TestSessionStore? sessionStore,
  _TestMockStore? mockStore,
}) async {
  final controller = AppController(
    sessionStore: sessionStore ?? _TestSessionStore(),
    mockStore: mockStore ?? _TestMockStore(),
    autoInitialize: false,
  );
  await controller.initialize();
  return controller;
}

Future<AppController> _buildLoggedInController() async {
  return _buildController(
    sessionStore: _TestSessionStore(
      clientUid: 'client_001',
      phone: '+82 10 1234 5678',
    ),
    mockStore: _TestMockStore(),
  );
}

class _TestSessionStore extends LocalSessionStore {
  _TestSessionStore({this.clientUid, this.phone});

  String? clientUid;
  String? phone;
  String? savedClientUid;
  String? savedPhone;

  @override
  Future<String> getOrCreateClientUid() async {
    final existing = clientUid;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    clientUid = 'client_${DateTime.now().microsecondsSinceEpoch}';
    return clientUid!;
  }

  @override
  Future<String?> peekClientUid() async => clientUid;

  @override
  Future<String?> peekPhone() async => phone;

  @override
  Future<void> saveClientSession({
    required String clientUid,
    String? phone,
  }) async {
    savedClientUid = clientUid;
    savedPhone = phone;
    this.clientUid = clientUid;
    this.phone = phone;
  }

  @override
  Future<void> clear() async {
    clientUid = null;
    phone = null;
    savedClientUid = null;
    savedPhone = null;
  }
}

class _TestMockStore extends LocalMockStore {
  LocalMockSnapshot? snapshot;

  @override
  Future<LocalMockSnapshot?> load() async => snapshot;

  @override
  Future<void> save(LocalMockSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}
