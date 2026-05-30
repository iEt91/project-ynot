import 'package:flutter_test/flutter_test.dart';

import 'package:ynot_mobile/src/core/data/local_session_store.dart';
import 'package:ynot_mobile/src/core/models/activity.dart';
import 'package:ynot_mobile/src/core/state/app_controller.dart';

void main() {
  group('AppController mock flows', () {
    test('existing local session restores the app on startup', () async {
      final store = _TestSessionStore(
        clientUid: 'persisted_client_001',
        phone: '+82 10 1234 5678',
      );
      final controller = await _buildController(sessionStore: store);

      expect(controller.state.stage, AppStage.ready);
      expect(controller.state.user, isNotNull);
      expect(controller.state.user!.id, 'persisted_client_001');
      expect(controller.state.user!.phoneMasked, contains('5678'));
      expect(controller.state.activities, isNotEmpty);
    });

    test('login with demo code stores a local session and enters the app', () async {
      final store = _TestSessionStore();
      final controller = await _buildController(sessionStore: store);

      expect(controller.state.stage, AppStage.phoneAuth);

      controller.updatePhoneInput('+82 10 0000 0000');
      await controller.sendVerificationCode();
      controller.updateVerificationInput('000000');
      await controller.verifyCode();

      expect(controller.state.stage, AppStage.ready);
      expect(controller.state.user, isNotNull);
      expect(store.savedClientUid, isNotNull);
      expect(store.savedPhone, '+82 10 0000 0000');
    });

    test('create activity updates local state and is visible in the map/list', () async {
      final controller = await _buildLoggedInController();

      await controller.createActivity(
        title: 'Café & Talk',
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
      expect(created.title, 'Café & Talk');
      expect(created.visibility, ActivityVisibility.privateActivity);
      expect(created.status, ActivityStatus.active);
      expect(created.isMine, isTrue);
      expect(controller.filteredActivities().first.title, 'Café & Talk');
    });

    test('joining, confirming, cancelling and leaving remain reversible', () async {
      final controller = await _buildLoggedInController();
      final activityId = controller.state.activities.first.id;

      await controller.joinActivity(activityId);
      var activity = controller.state.activities.firstWhere((item) => item.id == activityId);
      expect(activity.myStatus, ParticipantStatus.joinedPendingConfirmation);
      expect(activity.pendingCount, 2);

      await controller.confirmAttendance(activityId);
      activity = controller.state.activities.firstWhere((item) => item.id == activityId);
      expect(activity.myStatus, ParticipantStatus.confirmed);
      expect(activity.confirmedCount, 4);
      expect(activity.pendingCount, 1);

      await controller.cancelAttendance(activityId);
      activity = controller.state.activities.firstWhere((item) => item.id == activityId);
      expect(activity.myStatus, ParticipantStatus.cancelled);
      expect(activity.confirmedCount, 3);
      expect(activity.pendingCount, 1);

      await controller.joinActivity(activityId);
      activity = controller.state.activities.firstWhere((item) => item.id == activityId);
      expect(activity.myStatus, ParticipantStatus.joinedPendingConfirmation);
      expect(activity.pendingCount, 2);

      await controller.leaveActivity(activityId);
      activity = controller.state.activities.firstWhere((item) => item.id == activityId);
      expect(activity.myStatus, ParticipantStatus.left);
      expect(activity.pendingCount, 1);

      await controller.joinActivity(activityId);
      activity = controller.state.activities.firstWhere((item) => item.id == activityId);
      expect(activity.myStatus, ParticipantStatus.joinedPendingConfirmation);
      expect(activity.pendingCount, 2);
    });

    test('chat messages are kept in memory while the app is open', () async {
      final controller = await _buildLoggedInController();
      final activityId = controller.state.activities.first.id;

      await controller.joinActivity(activityId);
      await controller.confirmAttendance(activityId);

      await controller.loadChatMessages(activityId);
      expect(controller.state.chatMessages[activityId], isEmpty);

      await controller.sendChatMessage(activityId, 'Hola');
      await controller.sendChatMessage(activityId, '¿Ya llegaron?');
      await controller.sendChatMessage(activityId, 'Mantengamos la vibra suave');

      await controller.loadChatMessages(activityId);
      final messages = controller.state.chatMessages[activityId];
      expect(messages, isNotNull);
      expect(messages, hasLength(3));
      expect(messages!.map((message) => message.content), containsAll([
        'Hola',
        '¿Ya llegaron?',
        'Mantengamos la vibra suave',
      ]));
      expect(controller.state.activities.firstWhere((item) => item.id == activityId).lastMessagePreview,
          'Mantengamos la vibra suave');
    });

    test('logout clears the session and returns to auth', () async {
      final controller = await _buildLoggedInController();

      controller.signOut();

      expect(controller.state.stage, AppStage.phoneAuth);
      expect(controller.state.user, isNull);
      expect(controller.state.activities, isEmpty);
    });
  });
}

Future<AppController> _buildController({
  _TestSessionStore? sessionStore,
}) async {
  final controller = AppController(
    sessionStore: sessionStore ?? _TestSessionStore(),
    autoInitialize: false,
  );
  await controller.initialize();
  return controller;
}

Future<AppController> _buildLoggedInController() async {
  final controller = AppController(
    sessionStore: _TestSessionStore(
      clientUid: 'client_001',
      phone: '+82 10 1234 5678',
    ),
    autoInitialize: false,
  );
  await controller.initialize();
  return controller;
}

class _TestSessionStore extends LocalSessionStore {
  _TestSessionStore({
    this.clientUid,
    this.phone,
  });

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
