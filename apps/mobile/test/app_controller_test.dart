import 'package:flutter_test/flutter_test.dart';

import 'package:ynot_mobile/src/core/data/local_mock_store.dart';
import 'package:ynot_mobile/src/core/data/local_session_store.dart';
import 'package:ynot_mobile/src/core/models/activity.dart';
import 'package:ynot_mobile/src/core/models/moderation_report.dart';
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
        expect(created.status, ActivityStatus.open);
        expect(created.myStatus, ParticipantStatus.confirmed);
        expect(created.confirmedCount, 1);
        expect(created.isMine, isTrue);
        expect(created.creatorId, controller.state.user!.id);
        expect(controller.state.user!.attendingActivityCount, 1);
        expect(controller.filteredActivities().first.title, 'Cafe Talk');
      },
    );

    test('saved activities persist and can be unsaved', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final activityId = firstController.state.activities.first.id;
      expect(firstController.isActivitySaved(activityId), isFalse);

      expect(await firstController.toggleSavedActivity(activityId), isTrue);
      expect(firstController.isActivitySaved(activityId), isTrue);
      expect(firstController.savedActivities(), hasLength(1));
      expect(firstController.savedActivities().first.id, activityId);

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.isActivitySaved(activityId), isTrue);
      expect(secondController.savedActivities(), hasLength(1));
      expect(secondController.savedActivities().first.id, activityId);

      expect(await secondController.toggleSavedActivity(activityId), isTrue);
      expect(secondController.isActivitySaved(activityId), isFalse);
      expect(secondController.savedActivities(), isEmpty);
    });

    test('settings persist locally and clear with local data', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      await firstController.setChatMessagesNotifications(false);
      await firstController.setRecommendedActivitiesNotifications(false);
      await firstController.setActivityStartingSoonNotifications(false);
      await firstController.setHidePreciseLocationUntilUnlock(false);
      await firstController.setPersonalizedRecommendations(false);

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.settings, isNotNull);
      expect(
        secondController.state.settings.chatMessagesNotifications,
        isFalse,
      );
      expect(
        secondController.state.settings.recommendedActivitiesNotifications,
        isFalse,
      );
      expect(
        secondController.state.settings.activityStartingSoonNotifications,
        isFalse,
      );
      expect(
        secondController.state.settings.hidePreciseLocationUntilUnlock,
        isFalse,
      );
      expect(
        secondController.state.settings.personalizedRecommendations,
        isFalse,
      );

      await secondController.clearLocalData();

      expect(secondController.state.stage, AppStage.phoneAuth);
      expect(secondController.state.activities, isEmpty);
      expect(secondController.state.savedActivityIds, isEmpty);
      expect(secondController.state.chatMessages, isEmpty);
      expect(secondController.state.reports, isEmpty);
      expect(secondController.state.feedbackEntries, isEmpty);
      expect(secondController.state.user, isNull);
      expect(sessionStore.clientUid, isNull);
      expect(mockStore.snapshot, isNull);
    });

    test('local wipe disables seed data on the next login', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final controller = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(controller.state.activities, isNotEmpty);

      await controller.clearLocalData();

      expect(controller.state.stage, AppStage.phoneAuth);
      expect(controller.state.activities, isEmpty);
      expect(sessionStore.mockSeedDisabledAfterWipe, isTrue);

      controller.updatePhoneInput('+82 10 0000 0000');
      await controller.sendVerificationCode();
      controller.updateVerificationInput('000000');
      await controller.verifyCode();

      expect(controller.state.stage, AppStage.ready);
      expect(controller.state.activities, isEmpty);
      expect(controller.filteredActivities(), isEmpty);
      expect(controller.state.chatMessages, isEmpty);
      expect(controller.savedActivities(), isEmpty);
      expect(controller.historyActivitiesForUser(controller.state.user!.id), isEmpty);
    });

    test('joined or confirmed activities can open chat from the list', () {
      final activity = Activity(
        id: 'activity_001',
        creatorId: 'creator_001',
        creatorLabel: 'Luna',
        activityType: ActivityType.userActivity,
        title: 'Cafe Talk',
        description: 'Charlita suave y tranquila.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        status: ActivityStatus.open,
        realLat: 37.5563,
        realLng: 126.9228,
        displayLat: 37.5569,
        displayLng: 126.9234,
        locationPrivacyRadiusM: 180,
        exactLocationUnlockAt: DateTime(2026, 6, 1, 17, 50),
        startTime: DateTime(2026, 6, 1, 18, 0),
        endTime: DateTime(2026, 6, 1, 20, 0),
        maxPeople: 6,
        confirmedCount: 2,
        pendingCount: 0,
        myStatus: ParticipantStatus.confirmed,
        isMine: false,
      );

      expect(activity.isJoinedOrConfirmed, isTrue);
      expect(
        activity.copyWith(myStatus: ParticipantStatus.joinedPendingConfirmation)
            .isJoinedOrConfirmed,
        isTrue,
      );
      expect(
        Activity(
          id: 'activity_002',
          creatorId: 'creator_001',
          creatorLabel: 'Luna',
          activityType: ActivityType.userActivity,
          title: 'Cafe Talk',
          description: 'Charlita suave y tranquila.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          status: ActivityStatus.open,
          realLat: 37.5563,
          realLng: 126.9228,
          displayLat: 37.5569,
          displayLng: 126.9234,
          locationPrivacyRadiusM: 180,
          exactLocationUnlockAt: DateTime(2026, 6, 1, 17, 50),
          startTime: DateTime(2026, 6, 1, 18, 0),
          endTime: DateTime(2026, 6, 1, 20, 0),
          maxPeople: 6,
          confirmedCount: 0,
          pendingCount: 0,
          myStatus: null,
          isMine: false,
        ).isJoinedOrConfirmed,
        isFalse,
      );
    });

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
      expect(await controller.toggleSavedActivity(createdId), isTrue);
      expect(controller.isActivitySaved(createdId), isTrue);
      expect(await controller.deleteActivity(createdId), isTrue);
      expect(
        controller.state.activities.any((activity) => activity.id == createdId),
        isFalse,
      );
      expect(controller.isActivitySaved(createdId), isFalse);
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

    test(
      'creator can start and finish an activity and it moves to history',
      () async {
        final controller = await _buildLoggedInController();

        await controller.createActivity(
          title: 'Lifecycle Cafe',
          description: 'Para probar el ciclo de vida.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          startTime: DateTime(2026, 6, 1, 18, 0),
          duration: const Duration(hours: 2),
          maxPeople: 6,
          realLat: 37.5563,
          realLng: 126.9228,
        );

        final activityId = controller.state.activities.first.id;
        expect(
          controller.state.activities.first.status,
          ActivityStatus.open,
        );

        expect(await controller.startActivity(activityId), isTrue);
        expect(
          controller.state.activities.first.status,
          ActivityStatus.ongoing,
        );

        expect(await controller.finishActivity(activityId), isTrue);
        expect(
          controller.state.activities.first.status,
          ActivityStatus.finished,
        );
        expect(
          controller.filteredActivities().any((item) => item.id == activityId),
          isFalse,
        );
        expect(
          controller.historyActivitiesForUser(controller.state.user!.id)
              .any((item) => item.id == activityId),
          isTrue,
        );
        expect(controller.canCreateActivity(), isTrue);

        expect(await controller.archiveActivity(activityId), isTrue);
        expect(
          controller.state.activities.first.status,
          ActivityStatus.archived,
        );
        expect(
          controller.historyActivitiesForUser(controller.state.user!.id)
              .any((item) => item.id == activityId),
          isTrue,
        );
        expect(controller.isActivitySaved(activityId), isFalse);
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

    test('finished chat becomes read only and keeps prior messages', () async {
      final controller = await _buildLoggedInController();

      await controller.createActivity(
        title: 'Read Only Chat',
        description: 'Actividad para probar chat en solo lectura.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        startTime: DateTime(2026, 6, 1, 18, 0),
        duration: const Duration(hours: 2),
        maxPeople: 6,
        realLat: 37.5563,
        realLng: 126.9228,
      );

      final activityId = controller.state.activities.first.id;
      await controller.joinActivity(activityId);
      await controller.confirmAttendance(activityId);
      await controller.sendChatMessage(activityId, 'Antes de terminar');

      expect(
        controller.state.chatMessages[activityId],
        isNotNull,
      );
      expect(
        controller.state.chatMessages[activityId],
        hasLength(1),
      );

      expect(await controller.startActivity(activityId), isTrue);
      expect(
        controller.state.activities.first.status,
        ActivityStatus.ongoing,
      );
      expect(await controller.finishActivity(activityId), isTrue);
      await controller.sendChatMessage(activityId, 'No debería entrar');

      expect(
        controller.state.chatMessages[activityId],
        hasLength(1),
      );
      expect(
        controller.filteredActivities().any((item) => item.id == activityId),
        isFalse,
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
      'feedback targets expand to all confirmed attendees except the current user',
      () async {
        final controller = await _buildLoggedInController();
        final userId = controller.state.user!.id;
        final activity = controller.state.activities.first.copyWith(
          confirmedCount: 8,
          feedbackTargets: [
            ActivityFeedbackTarget(
              userId: userId,
              label: 'Tú',
              emoji: '🌙',
            ),
            const ActivityFeedbackTarget(
              userId: 'participant_001',
              label: 'Mina',
              emoji: '🌸',
            ),
            const ActivityFeedbackTarget(
              userId: 'participant_002',
              label: 'Jisoo',
              emoji: '✨',
            ),
          ],
        );

        final targets = controller.feedbackTargetsForActivity(activity, userId);

        expect(targets, hasLength(7));
        expect(targets.any((target) => target.userId == userId), isFalse);
      },
    );

    test('reports are saved once per reporter and target', () async {
      final controller = await _buildLoggedInController();
      final activity = controller.state.activities.first;
      final reporterId = controller.state.user!.id;

      expect(
        await controller.submitReport(
          reporterUserId: reporterId,
          targetType: ReportTargetType.activity,
          targetId: activity.id,
          activityId: activity.id,
          reason: ReportReason.noShow,
          note: 'No estaba donde decía',
        ),
        isTrue,
      );

      expect(
        await controller.submitReport(
          reporterUserId: reporterId,
          targetType: ReportTargetType.activity,
          targetId: activity.id,
          activityId: activity.id,
          reason: ReportReason.other,
        ),
        isFalse,
      );
      expect(controller.state.reports, hasLength(1));
      expect(controller.state.reports.first.targetType, ReportTargetType.activity);
      expect(controller.state.reports.first.reason, ReportReason.noShow);
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

    test('reports survive a controller restart', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final activity = firstController.state.activities.first;
      final reporterId = firstController.state.user!.id;

      await firstController.submitReport(
        reporterUserId: reporterId,
        targetType: ReportTargetType.user,
        targetId: activity.creatorId,
        activityId: activity.id,
        reason: ReportReason.badAttitude,
        note: 'Actitud rara',
      );

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.reports, hasLength(1));
      expect(
        secondController.state.reports.first.targetType,
        ReportTargetType.user,
      );
      expect(
        secondController.state.reports.first.reason,
        ReportReason.badAttitude,
      );
    });

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
      await firstController.toggleSavedActivity(createdActivity.id);
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
      expect(secondController.isActivitySaved(createdActivity.id), isTrue);
      expect(secondController.savedActivities(), hasLength(1));
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
  bool mockSeedDisabledAfterWipe = false;

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

  @override
  Future<void> setMockSeedDisabledAfterWipe(bool value) async {
    mockSeedDisabledAfterWipe = value;
  }

  @override
  Future<bool> peekMockSeedDisabledAfterWipe() async {
    return mockSeedDisabledAfterWipe;
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
