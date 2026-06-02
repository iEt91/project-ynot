import 'package:flutter_test/flutter_test.dart';

import 'package:ynot_mobile/src/core/data/local_mock_store.dart';
import 'package:ynot_mobile/src/core/data/local_session_store.dart';
import 'package:ynot_mobile/src/core/models/blocked_user.dart';
import 'package:ynot_mobile/src/core/models/activity.dart';
import 'package:ynot_mobile/src/core/models/activity_filters.dart';
import 'package:ynot_mobile/src/core/models/app_user.dart';
import 'package:ynot_mobile/src/core/models/chat_message.dart';
import 'package:ynot_mobile/src/core/models/in_app_notification.dart';
import 'package:ynot_mobile/src/core/models/moderation_flag.dart';
import 'package:ynot_mobile/src/core/models/moderation_report.dart';
import 'package:ynot_mobile/src/core/models/private_feedback.dart';
import 'package:ynot_mobile/src/core/state/app_controller.dart';

void main() {
  group('AppController mock flows', () {
    test(
      'existing complete local session restores the app on startup',
      () async {
        final controller = await _buildLoggedInController();

        expect(controller.state.stage, AppStage.ready);
        expect(controller.state.user, isNotNull);
        expect(controller.state.user!.id, 'client_001');
        expect(controller.state.user!.phoneMasked, contains('5678'));
        expect(controller.state.activities, isNotEmpty);
      },
    );

    test('public profiles resolve current and demo users', () async {
      final controller = await _buildLoggedInController();

      final current = controller.publicProfileForUserId(
        controller.state.user!.id,
      );
      expect(current, isNotNull);
      expect(current!.nickname, 'Luna');
      expect(current.avatarEmoji, '🌙');

      final demo = controller.publicProfileForUserId('seed_creator_mina');
      expect(demo, isNotNull);
      expect(demo!.nickname, 'Mina');
      expect(demo.languages, isNotEmpty);
      expect(demo.vibes, isNotEmpty);
      expect(demo.interests, isNotEmpty);
    });

    test(
      'blocking a creator persists and keeps their activity visible',
      () async {
        final sessionStore = _TestSessionStore(
          clientUid: 'client_001',
          phone: '+82 10 1234 5678',
        );
        final mockStore = _TestMockStore();
        final controller = await _buildController(
          sessionStore: sessionStore,
          mockStore: mockStore,
        );

        final creatorProfile = controller.publicProfileForUserId(
          'seed_creator_mina',
        );
        expect(creatorProfile, isNotNull);

        final creatorActivities = controller
            .filteredActivities()
            .where((activity) => activity.creatorId == 'seed_creator_mina')
            .toList();
        expect(creatorActivities, isNotEmpty);

        final blocked = await controller.blockUser(creatorProfile!);
        expect(blocked, isTrue);
        expect(
          controller.publicProfileForUserId('seed_creator_mina'),
          isNotNull,
        );
        expect(
          controller.filteredActivities().any(
            (activity) => activity.creatorId == 'seed_creator_mina',
          ),
          isTrue,
        );
        expect(
          controller.blockedUsers.any(
            (entry) => entry.userId == 'seed_creator_mina',
          ),
          isTrue,
        );

        final restored = await _buildController(
          sessionStore: sessionStore,
          mockStore: mockStore,
        );
        expect(restored.publicProfileForUserId('seed_creator_mina'), isNotNull);
        expect(
          restored.filteredActivities().any(
            (activity) => activity.creatorId == 'seed_creator_mina',
          ),
          isTrue,
        );
        expect(
          restored.blockedUsers.any(
            (entry) => entry.userId == 'seed_creator_mina',
          ),
          isTrue,
        );
      },
    );

    test(
      'blocking an attendee keeps them visible in attendees and unblock works',
      () async {
        final controller = await _buildLoggedInController();
        final attendeeProfile = controller.publicProfileForUserId(
          'seed_participant_soojin',
        );
        expect(attendeeProfile, isNotNull);

        final activity = controller.state.activities.firstWhere(
          (item) => item.id == 'seed_1',
        );
        expect(
          controller
              .confirmedAttendeesForActivity(activity)
              .any((target) => target.userId == 'seed_participant_soojin'),
          isTrue,
        );

        final blocked = await controller.blockUser(attendeeProfile!);
        expect(blocked, isTrue);
        expect(
          controller.publicProfileForUserId('seed_participant_soojin'),
          isNotNull,
        );
        expect(
          controller
              .confirmedAttendeesForActivity(activity)
              .any((target) => target.userId == 'seed_participant_soojin'),
          isTrue,
        );
        expect(
          controller.blockedUsers.any(
            (entry) => entry.userId == 'seed_participant_soojin',
          ),
          isTrue,
        );

        await controller.unblockUser('seed_participant_soojin');
        expect(
          controller.publicProfileForUserId('seed_participant_soojin'),
          isNotNull,
        );
        expect(
          controller
              .confirmedAttendeesForActivity(activity)
              .any((target) => target.userId == 'seed_participant_soojin'),
          isTrue,
        );
      },
    );

    test('blocked chat warning dismissal persists per activity', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final activity = firstController.state.activities.firstWhere(
        (item) => item.id == 'seed_1',
      );
      final attendeeProfile = firstController.publicProfileForUserId(
        'seed_participant_soojin',
      );
      expect(attendeeProfile, isNotNull);
      expect(await firstController.blockUser(attendeeProfile!), isTrue);
      expect(firstController.hasBlockedParticipants(activity), isTrue);

      firstController.dismissBlockedChatWarning(activity.id);
      expect(
        firstController.hasDismissedBlockedChatWarning(activity.id),
        isTrue,
      );

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(
        secondController.hasDismissedBlockedChatWarning(activity.id),
        isTrue,
      );
    });

    test('chat conduct reminder acceptance persists per activity', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final activity = firstController.state.activities.firstWhere(
        (item) => item.id == 'seed_1',
      );

      expect(
        firstController.hasAcceptedChatGuidelines(activity.id),
        isFalse,
      );

      firstController.acceptChatGuidelines(activity.id);

      expect(
        firstController.hasAcceptedChatGuidelines(activity.id),
        isTrue,
      );

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(
        secondController.hasAcceptedChatGuidelines(activity.id),
        isTrue,
      );
    });

    test(
      'login with demo code opens onboarding when profile is incomplete',
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

        expect(controller.state.stage, AppStage.onboarding);
        expect(controller.state.user, isNotNull);
        expect(store.savedClientUid, isNotNull);
        expect(store.savedPhone, '+82 10 0000 0000');

        await controller.completeOnboarding(
          nickname: 'Luna',
          avatarEmoji: '🌙',
          languages: const ['Korean'],
          vibes: const ['Calm'],
          interests: const ['Coffee'],
        );

        expect(controller.state.stage, AppStage.ready);
        expect(controller.state.user!.profileComplete, isTrue);
      },
    );

    test('activity discovery filters persist and apply to results', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore()
        ..snapshot = LocalMockSnapshot(
          user: AppUser(
            id: 'client_001',
            phoneMasked: '•••• 5678',
            nickname: 'Luna',
            avatarEmoji: '🌙',
            bio: 'Pequeños momentos, juntos.',
            languages: const ['Korean', 'English'],
            vibes: const ['Calm', 'Creative'],
            interests: const ['Coffee', 'Walks', 'Study'],
            status: UserStatus.trusted,
            profileComplete: true,
            createdActivityCount: 0,
            attendingActivityCount: 0,
          ),
          activities: const [],
          messagesByActivityId: const {},
          savedActivityIds: const [],
          blockedUsers: const [],
          activityFilters: const {},
          settings: const {},
          reports: const [],
          feedbackEntries: const [],
        );

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final now = DateTime.now();
      await firstController.createActivity(
        title: 'Morning Coffee',
        description: 'Plan perfecto para probar filtros.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        duration: const Duration(hours: 2),
        maxPeople: 4,
        realLat: 37.5563,
        realLng: 126.9228,
        visibility: ActivityVisibility.privateActivity,
      );

      firstController.clearActivityFilters();
      firstController.toggleTodayFilter();
      firstController.setTimeSlotFilter(ActivityTimeSlot.morning);
      firstController.toggleCategoryFilter('Coffee');
      firstController.setPeopleRangeFilter(ActivityPeopleRange.twoToFour);

      final filtered = firstController.filteredActivities();
      expect(filtered, isNotEmpty);

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.activityFilters.today, isTrue);
      expect(
        secondController.state.activityFilters.timeSlot,
        ActivityTimeSlot.morning,
      );
      expect(
        secondController.state.activityFilters.categories,
        contains('Coffee'),
      );
      expect(
        secondController.state.activityFilters.peopleRange,
        ActivityPeopleRange.twoToFour,
      );
      expect(secondController.filteredActivities(), isNotEmpty);
    });

    test('activity search persists and applies to results', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore()
        ..snapshot = LocalMockSnapshot(
          user: AppUser(
            id: 'client_001',
            phoneMasked: '•••• 5678',
            nickname: 'Luna',
            avatarEmoji: '🌙',
            bio: 'Pequeños momentos, juntos.',
            languages: const ['Korean', 'English'],
            vibes: const ['Calm', 'Creative'],
            interests: const ['Coffee', 'Walks', 'Study'],
            status: UserStatus.trusted,
            profileComplete: true,
            createdActivityCount: 0,
            attendingActivityCount: 0,
          ),
          activities: const [],
          messagesByActivityId: const {},
          savedActivityIds: const [],
          blockedUsers: const [],
          activityFilters: const {},
          searchQuery: '',
          settings: const {},
          reports: const [],
          feedbackEntries: const [],
        );

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final now = DateTime.now();
      await firstController.createActivity(
        title: 'Morning Coffee',
        description: 'Search helper test.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        duration: const Duration(hours: 2),
        maxPeople: 4,
        realLat: 37.5563,
        realLng: 126.9228,
        visibility: ActivityVisibility.privateActivity,
      );

      firstController.setActivitySearchQuery('helper test');
      expect(firstController.filteredActivities(), hasLength(1));

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.activitySearchQuery, 'helper test');
      expect(secondController.filteredActivities(), hasLength(1));
    });

    test('manual demo data loads and persists after restart', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
        mockSeedDisabledAfterWipe: true,
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(firstController.state.activities, isEmpty);

      final added = await firstController.loadDemoActivities();
      expect(added, greaterThanOrEqualTo(4));
      expect(added, lessThanOrEqualTo(6));
      expect(firstController.state.activities, hasLength(added));

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.activities, hasLength(added));
    });

    test('restored demo activities are sanitized on load', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();
      mockStore.snapshot = LocalMockSnapshot(
        user: AppUser(
          id: 'client_001',
          phoneMasked: '•••• 5679',
          nickname: 'Luna',
          avatarEmoji: '🌙',
          bio: 'Pequeños momentos, juntos.',
          languages: const ['Spanish'],
          vibes: const ['Calm'],
          interests: const ['Coffee'],
          status: UserStatus.trusted,
          profileComplete: true,
          createdActivityCount: 0,
          attendingActivityCount: 0,
        ),
        activities: [
          Activity(
            id: 'seed_6',
            creatorId: 'seed_creator_yura',
            creatorLabel: 'Yura',
            activityType: ActivityType.publicEvent,
            visibility: ActivityVisibility.publicActivity,
            title: '🌸 Archive Walk',
            description: 'Paseo que ya pasó y ahora vive en el historial.',
            category: 'Walks',
            vibe: 'Calm',
            zone: 'Seoul',
            status: ActivityStatus.archived,
            realLat: 37.5666,
            realLng: 126.978,
            displayLat: 37.5669,
            displayLng: 126.9776,
            locationPrivacyRadiusM: 140,
            exactLocationUnlockAt: DateTime(2026, 6, 1, 15, 0),
            startTime: DateTime(2026, 6, 1, 12, 0),
            endTime: DateTime(2026, 6, 1, 14, 0),
            maxPeople: 8,
            confirmedCount: 5,
            pendingCount: 0,
            feedbackTargets: [
              const ActivityFeedbackTarget(
                userId: 'seed_creator_yura',
                label: 'Yura',
                emoji: '🌸',
              ),
              const ActivityFeedbackTarget(
                userId: 'seed_participant_ren',
                label: 'Ren',
                emoji: '✨',
              ),
            ],
            myStatus: ParticipantStatus.attended,
            isMine: false,
            lastMessagePreview: 'Yura: Gracias por venir 💫',
          ),
        ],
        messagesByActivityId: const {},
        savedActivityIds: const [],
        blockedUsers: const [],
        activityFilters: const {},
        settings: const {},
        reports: const [],
        feedbackEntries: const [],
      );

      final controller = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(controller.state.activities, hasLength(1));
      expect(controller.state.activities.first.title, '🌸 Archive Walk');
      expect(
        controller.state.activities.first.description,
        'Paseo que ya pasó y ahora vive en el historial.',
      );
      expect(
        controller.state.activities.first.lastMessagePreview,
        'Yura: Gracias por venir 💫',
      );
      expect(
        controller.state.activities.first.feedbackTargets.first.emoji,
        '🌸',
      );
    });

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
      expect(secondController.state.moderationFlags, isEmpty);
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

      expect(controller.state.stage, AppStage.onboarding);
      expect(controller.state.activities, isEmpty);
      expect(controller.filteredActivities(), isEmpty);
      expect(controller.state.chatMessages, isEmpty);
      expect(controller.savedActivities(), isEmpty);
      expect(controller.state.moderationFlags, isEmpty);
      expect(
        controller.historyActivitiesForUser(controller.state.user!.id),
        isEmpty,
      );

      await controller.completeOnboarding(
        nickname: 'Luna',
        avatarEmoji: '🌙',
        languages: const ['Korean'],
        vibes: const ['Calm'],
        interests: const ['Coffee'],
      );

      expect(controller.state.stage, AppStage.ready);
      expect(controller.state.activities, isEmpty);
      expect(controller.filteredActivities(), isEmpty);
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
        activity
            .copyWith(myStatus: ParticipantStatus.joinedPendingConfirmation)
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
        expect(
          activity.feedbackTargets.any(
            (target) => target.userId == controller.state.user!.id,
          ),
          isTrue,
        );

        await controller.cancelAttendance(activityId);
        activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.cancelled);
        expect(activity.confirmedCount, 3);
        expect(activity.pendingCount, 1);
        expect(
          activity.feedbackTargets.any(
            (target) => target.userId == controller.state.user!.id,
          ),
          isFalse,
        );

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
        expect(
          activity.feedbackTargets.any(
            (target) => target.userId == controller.state.user!.id,
          ),
          isFalse,
        );

        await controller.joinActivity(activityId);
        activity = controller.state.activities.firstWhere(
          (item) => item.id == activityId,
        );
        expect(activity.myStatus, ParticipantStatus.joinedPendingConfirmation);
        expect(activity.pendingCount, 2);
      },
    );

    test('creator cannot leave own activity', () async {
      final controller = await _buildLoggedInController();
      await controller.createActivity(
        title: 'Own Plan',
        description: 'Plan de prueba propio.',
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

      await controller.leaveActivity(activityId);

      final activity = controller.state.activities.firstWhere(
        (item) => item.id == activityId,
      );
      expect(activity.myStatus, ParticipantStatus.confirmed);
      expect(activity.confirmedCount, 1);
      expect(
        activity.feedbackTargets.any(
          (target) => target.userId == controller.state.user!.id,
        ),
        isTrue,
      );
    });

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
        expect(controller.state.activities.first.status, ActivityStatus.open);

        expect(await controller.startActivity(activityId), isTrue);
        expect(
          controller.state.activities.first.status,
          ActivityStatus.ongoing,
        );
        expect(
          controller.state.notifications.any(
            (item) => item.type == InAppNotificationType.activityStartingSoon,
          ),
          isTrue,
        );

        expect(await controller.finishActivity(activityId), isTrue);
        expect(
          controller.state.activities.first.status,
          ActivityStatus.finished,
        );
        expect(
          controller.state.notifications.any(
            (item) => item.type == InAppNotificationType.activityFinished,
          ),
          isTrue,
        );
        expect(
          controller.state.notifications.any(
            (item) => item.type == InAppNotificationType.feedbackAvailable,
          ),
          isTrue,
        );
        expect(
          controller.filteredActivities().any((item) => item.id == activityId),
          isFalse,
        );
        expect(
          controller
              .historyActivitiesForUser(controller.state.user!.id)
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
          controller
              .historyActivitiesForUser(controller.state.user!.id)
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

    test('notifications persist locally and can be marked read', () async {
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
      await firstController.receiveChatMessage(
        activityId: activityId,
        senderId: 'seed_participant_soojin',
        senderName: 'Soojin',
        senderEmoji: '✨',
        content: 'Hola desde fuera',
      );

      expect(firstController.state.notifications, hasLength(1));
      expect(firstController.unreadNotificationCount, 1);
      expect(
        firstController.state.notifications.first.type,
        InAppNotificationType.newMessage,
      );

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.notifications, hasLength(1));
      expect(secondController.unreadNotificationCount, 1);

      final notificationId = secondController.state.notifications.first.id;
      await secondController.markNotificationRead(notificationId);

      expect(secondController.unreadNotificationCount, 0);

      final thirdController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );
      expect(thirdController.state.notifications, hasLength(1));
      expect(thirdController.unreadNotificationCount, 0);
      expect(thirdController.state.notifications.first.isRead, isTrue);
    });

    test('demo notifications generate stable mixed read states', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore()
        ..snapshot = LocalMockSnapshot(
          user: AppUser(
            id: 'client_001',
            phoneMasked: '•••• 5678',
            nickname: 'Luna',
            avatarEmoji: '🌙',
            bio: 'Pequeños momentos, juntos.',
            languages: const ['Korean', 'English'],
            vibes: const ['Calm', 'Creative'],
            interests: const ['Coffee', 'Walks', 'Study'],
            status: UserStatus.trusted,
            profileComplete: true,
            createdActivityCount: 0,
            attendingActivityCount: 0,
          ),
          activities: const [],
          messagesByActivityId: const {},
          savedActivityIds: const [],
          blockedUsers: const [],
          activityFilters: const {},
          settings: const {},
          reports: const [],
          feedbackEntries: const [],
        );

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final generated = await firstController.generateDemoNotifications();
      expect(generated, 8);
      expect(firstController.state.notifications, hasLength(8));
      expect(firstController.unreadNotificationCount, 4);
      expect(
        firstController.state.notifications.where((item) => item.isRead),
        hasLength(4),
      );
      expect(
        firstController.state.notifications
            .map((item) => item.dedupeKey)
            .toSet(),
        hasLength(8),
      );
      expect(
        firstController.state.notifications.map((item) => item.type),
        containsAll([
          InAppNotificationType.newMessage,
          InAppNotificationType.newAttendee,
          InAppNotificationType.activityStartingSoon,
          InAppNotificationType.activityFinished,
          InAppNotificationType.feedbackAvailable,
          InAppNotificationType.blockedUserPresent,
          InAppNotificationType.activitySaved,
          InAppNotificationType.activityReminder,
        ]),
      );

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );
      expect(secondController.state.notifications, hasLength(8));
      expect(secondController.unreadNotificationCount, 4);

      await secondController.generateDemoNotifications();
      expect(secondController.state.notifications, hasLength(8));
      expect(
        secondController.state.notifications
            .map((item) => item.dedupeKey)
            .toSet(),
        hasLength(8),
      );
      expect(secondController.unreadNotificationCount, 4);
    });

    test('active chats do not create chat message notifications', () async {
      final controller = await _buildLoggedInController();
      final activityId = controller.state.activities.first.id;

      await controller.loadChatMessages(activityId);
      await controller.watchChatMessages(activityId);
      await controller.receiveChatMessage(
        activityId: activityId,
        senderId: 'seed_participant_soojin',
        senderName: 'Soojin',
        senderEmoji: '✨',
        content: 'Mensaje en vivo',
      );

      expect(
        controller.state.notifications.where(
          (notification) =>
              notification.type == InAppNotificationType.newMessage,
        ),
        isEmpty,
      );
      expect(
        controller.state.activities
            .firstWhere((item) => item.id == activityId)
            .unreadMessageCount,
        0,
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

      expect(controller.state.chatMessages[activityId], isNotNull);
      expect(controller.state.chatMessages[activityId], hasLength(1));

      expect(await controller.startActivity(activityId), isTrue);
      expect(controller.state.activities.first.status, ActivityStatus.ongoing);
      expect(await controller.finishActivity(activityId), isTrue);
      await controller.sendChatMessage(activityId, 'No debería entrar');

      expect(controller.state.chatMessages[activityId], hasLength(1));
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

    test('blocked users stay visible but cannot receive feedback', () async {
      final controller = await _buildLoggedInController();
      final activity = controller.state.activities.first;
      final reviewerId = controller.state.user!.id;
      final blockedTarget = activity.feedbackTargets.firstWhere(
        (target) => target.userId != reviewerId,
      );
      final blockedProfile = controller.publicProfileForUserId(
        blockedTarget.userId,
      );

      expect(blockedProfile, isNotNull);
      await controller.blockUser(blockedProfile!);

      final allTargets = controller.feedbackTargetsForActivity(
        activity,
        reviewerId,
      );
      final availableTargets = controller.availableFeedbackTargetsForActivity(
        activity,
        reviewerId,
      );

      expect(
        allTargets.any((target) => target.userId == blockedTarget.userId),
        isTrue,
      );
      expect(
        availableTargets.any((target) => target.userId == blockedTarget.userId),
        isFalse,
      );
      expect(
        await controller.submitPrivateFeedback(
          activityId: activity.id,
          reviewerUserId: reviewerId,
          reviewedUserId: blockedTarget.userId,
          selectedFeedback: PrivateFeedbackOption.goodVibe,
        ),
        isFalse,
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
            ActivityFeedbackTarget(userId: userId, label: 'Tú', emoji: '🌙'),
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
      expect(
        controller.state.reports.first.targetType,
        ReportTargetType.activity,
      );
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

        final createdId = controller.state.activities
            .firstWhere((activity) => activity.title == 'Cafe Talk')
            .id;
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

    test(
      'editing activity updates the existing item without creating a new one',
      () async {
        final sessionStore = _TestSessionStore(
          clientUid: 'client_001',
          phone: '+82 10 1234 5678',
        );
        final mockStore = _TestMockStore()
          ..snapshot = LocalMockSnapshot(
            user: AppUser(
              id: 'client_001',
              phoneMasked: '???? 5678',
              nickname: 'Luna',
              avatarEmoji: '??',
              bio: 'Peque?os momentos, juntos.',
              languages: const ['Korean', 'English'],
              vibes: const ['Calm', 'Creative'],
              interests: const ['Coffee', 'Walks', 'Study'],
              status: UserStatus.trusted,
              profileComplete: true,
              createdActivityCount: 1,
              attendingActivityCount: 1,
            ),
            activities: [
              Activity(
                id: 'activity_edit_me',
                creatorId: 'client_001',
                creatorLabel: 'Luna',
                activityType: ActivityType.userActivity,
                visibility: ActivityVisibility.publicActivity,
                title: 'Original Plan',
                description: 'Actividad base para editar.',
                category: 'Coffee',
                vibe: 'Calm',
                zone: 'Hongdae',
                status: ActivityStatus.open,
                realLat: 37.5563,
                realLng: 126.9228,
                displayLat: 37.5563,
                displayLng: 126.9228,
                locationPrivacyRadiusM: 120,
                exactLocationUnlockAt: DateTime(2026, 6, 3, 17, 50),
                startTime: DateTime(2026, 6, 3, 18, 0),
                endTime: DateTime(2026, 6, 3, 20, 0),
                maxPeople: 5,
                confirmedCount: 1,
                pendingCount: 0,
                feedbackTargets: const [],
                myStatus: ParticipantStatus.confirmed,
                isMine: true,
                lastMessagePreview: '',
                unreadMessageCount: 0,
              ),
            ],
            messagesByActivityId: const {},
            savedActivityIds: const [],
            blockedUsers: const [],
            activityFilters: const {},
            settings: const {},
            reports: const [],
            feedbackEntries: const [],
          );
        final controller = await _buildController(
          sessionStore: sessionStore,
          mockStore: mockStore,
        );

        final createdId = controller.state.activities
            .firstWhere((activity) => activity.id == 'activity_edit_me')
            .id;
        final previousLength = controller.state.activities.length;

        final updated = await controller.updateActivity(
          activityId: createdId,
          title: 'Plan editado',
          description: 'Texto actualizado.',
          category: 'Study',
          vibe: 'Social',
          zone: 'Gangnam',
          startTime: DateTime(2026, 6, 4, 19, 0),
          duration: const Duration(hours: 3),
          maxPeople: 6,
          realLat: 37.4981,
          realLng: 127.0276,
        );

        expect(updated, isTrue);
        expect(controller.state.activities, hasLength(previousLength));

        final edited = controller.state.activities.firstWhere(
          (activity) => activity.id == createdId,
        );
        expect(edited.title, 'Plan editado');
        expect(edited.description, 'Texto actualizado.');
        expect(edited.category, 'Study');
        expect(edited.vibe, 'Social');
        expect(edited.zone, 'Gangnam');
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

    test(
      'moderation flags are created for risky activity and chat text and persist',
      () async {
        final sessionStore = _TestSessionStore(
          clientUid: 'client_001',
          phone: '+82 10 1234 5678',
        );
        final mockStore = _TestMockStore();

        final firstController = await _buildController(
          sessionStore: sessionStore,
          mockStore: mockStore,
        );

        await firstController.createActivity(
          title: 'Crypto Night',
          description: 'Weed and casino plan.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          startTime: DateTime(2026, 6, 1, 18, 0),
          duration: const Duration(hours: 2),
          maxPeople: 6,
          realLat: 37.5563,
          realLng: 126.9228,
        );

        final createdActivity = firstController.state.activities.firstWhere(
          (activity) => activity.title == 'Crypto Night',
        );
        await firstController.sendChatMessage(
          createdActivity.id,
          'Vamos a pelear y matar el tiempo con spam casino.',
        );

        expect(firstController.moderationFlags, isNotEmpty);
        expect(
          firstController.moderationFlags.map((flag) => flag.category).toSet(),
          containsAll(['spam', 'drugs', 'violence']),
        );
        expect(
          firstController.pendingModerationFlags(),
          hasLength(firstController.moderationFlags.length),
        );

        final weedFlag = firstController.moderationFlags.firstWhere(
          (flag) => flag.keyword == 'weed',
        );
        expect(
          firstController.moderationFlagById(weedFlag.flagId),
          isNotNull,
        );
        await firstController.markModerationFlagReviewed(weedFlag.flagId);
        expect(
          firstController.moderationFlags
              .firstWhere((flag) => flag.flagId == weedFlag.flagId)
              .status,
          ModerationFlagStatus.reviewed,
        );

        final secondController = await _buildController(
          sessionStore: sessionStore,
          mockStore: mockStore,
        );

        expect(secondController.moderationFlags, isNotEmpty);
        expect(
          secondController.moderationFlags
              .firstWhere((flag) => flag.flagId == weedFlag.flagId)
              .status,
          ModerationFlagStatus.reviewed,
        );
      },
    );

    test('moderation keyword detection finds risky text before publish', () {
      final controller = AppController(
        sessionStore: _TestSessionStore(
          clientUid: 'client_001',
          phone: '+82 10 1234 5678',
        ),
        mockStore: _TestMockStore(),
        autoInitialize: false,
      );

      final matches = controller.moderationMatchesForText(
        'Weed, casino y pelea suave.',
      );

      expect(matches, isNotEmpty);
      expect(
        matches.map((item) => item.keyword),
        containsAll(['weed', 'casino', 'pelea']),
      );
    });

    test(
      'reportable participants include organizer attendees blocked and chat senders',
      () async {
        final sessionStore = _TestSessionStore(
          clientUid: 'client_001',
          phone: '+82 10 1234 5678',
        );
        final activity = Activity(
          id: 'activity_report_selector',
          creatorId: 'seed_creator_mina',
          creatorLabel: 'Mina',
          activityType: ActivityType.userActivity,
          visibility: ActivityVisibility.publicActivity,
          title: 'Selector Test',
          description: 'Actividad para probar el selector.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          status: ActivityStatus.open,
          realLat: 37.5563,
          realLng: 126.9228,
          displayLat: 37.5563,
          displayLng: 126.9228,
          locationPrivacyRadiusM: 120,
          exactLocationUnlockAt: DateTime(2026, 6, 1, 18, 0),
          startTime: DateTime(2026, 6, 1, 18, 0),
          endTime: DateTime(2026, 6, 1, 20, 0),
          maxPeople: 6,
          confirmedCount: 3,
          pendingCount: 0,
          feedbackTargets: const [
            ActivityFeedbackTarget(
              userId: 'seed_creator_mina',
              label: 'Mina',
              emoji: '☕',
            ),
            ActivityFeedbackTarget(
              userId: 'seed_participant_soojin',
              label: 'Soojin',
              emoji: '✨',
            ),
          ],
          myStatus: ParticipantStatus.confirmed,
          isMine: false,
        );
        final mockStore = _TestMockStore()
          ..snapshot = LocalMockSnapshot(
            user: AppUser(
              id: 'client_001',
              phoneMasked: '•••• 5678',
              nickname: 'Luna',
              avatarEmoji: '🌙',
              bio: 'Pequeños momentos, juntos.',
              languages: const ['Korean', 'English'],
              vibes: const ['Calm', 'Creative'],
              interests: const ['Coffee', 'Walks', 'Study'],
              status: UserStatus.trusted,
              profileComplete: true,
              createdActivityCount: 0,
              attendingActivityCount: 0,
            ),
            activities: [activity],
            messagesByActivityId: {
              activity.id: [
                ChatMessage(
                  id: 'message_chat_only',
                  chatId: activity.id,
                  activityId: activity.id,
                  senderId: 'chat_only_user',
                  senderName: 'Chat Only',
                  senderEmoji: '💬',
                  content: 'Hola desde el chat',
                  createdAt: DateTime(2026, 6, 1, 18, 10),
                  isMe: false,
                ),
              ],
            },
            savedActivityIds: const [],
            blockedUsers: [
              BlockedUserEntry(
                userId: 'seed_participant_soojin',
                nickname: 'Soojin',
                avatarEmoji: '✨',
                blockedAt: DateTime(2026, 6, 1, 17, 0),
              ),
            ],
            activityFilters: const {},
            settings: const {},
            reports: const [],
            feedbackEntries: const [],
          );
        final controller = await _buildController(
          sessionStore: sessionStore,
          mockStore: mockStore,
        );

        final participants = controller.reportableParticipantsForActivity(
          activity,
          controller.state.user!.id,
        );

        expect(
          participants.map((participant) => participant.userId),
          containsAll([
            'seed_creator_mina',
            'seed_participant_soojin',
            'chat_only_user',
          ]),
        );
        expect(
          participants.any((participant) => participant.userId == 'client_001'),
          isFalse,
        );
        final blocked = participants.firstWhere(
          (participant) => participant.userId == 'seed_participant_soojin',
        );
        expect(blocked.isBlocked, isTrue);
        expect(blocked.roleLabel, 'Asistente');
      },
    );

    test('sent reports history can be cleared locally', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final controller = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final activity = controller.state.activities.first;
      final reporterId = controller.state.user!.id;

      await controller.submitReport(
        reporterUserId: reporterId,
        targetType: ReportTargetType.user,
        targetId: activity.creatorId,
        activityId: activity.id,
        reason: ReportReason.badAttitude,
        note: 'Actitud rara',
      );

      expect(controller.state.reports, hasLength(1));

      await controller.clearReportHistory();

      expect(controller.state.reports, isEmpty);

      final restarted = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );
      expect(restarted.state.reports, isEmpty);
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

    test(
      'location privacy keeps approximate markers until exact unlock',
      () async {
        final controller = await _buildLoggedInController();
        final unlockAt = DateTime(2026, 6, 1, 18, 0);
        final activity = Activity(
          id: 'location_privacy_test',
          creatorId: 'seed_creator_mina',
          creatorLabel: 'Mina',
          activityType: ActivityType.userActivity,
          visibility: ActivityVisibility.publicActivity,
          title: 'Location Privacy',
          description: 'Test de privacidad de ubicaciÃ³n.',
          category: 'Coffee',
          vibe: 'Calm',
          zone: 'Hongdae',
          status: ActivityStatus.open,
          realLat: 37.5563,
          realLng: 126.9228,
          displayLat: 37.5621,
          displayLng: 126.9298,
          locationPrivacyRadiusM: 180,
          exactLocationUnlockAt: unlockAt.subtract(const Duration(minutes: 10)),
          startTime: unlockAt,
          endTime: unlockAt.add(const Duration(hours: 2)),
          maxPeople: 6,
          confirmedCount: 2,
          pendingCount: 0,
          feedbackTargets: const [],
          myStatus: null,
          isMine: false,
        );

        final beforeUnlock = controller.activityVisibleForCurrentUser(
          activity,
          now: unlockAt.subtract(const Duration(minutes: 11)),
        );
        expect(beforeUnlock.displayLat, activity.displayLat);
        expect(beforeUnlock.displayLng, activity.displayLng);
        expect(
          controller.locationDisclosureLabel(
            activity,
            now: unlockAt.subtract(const Duration(minutes: 11)),
          ),
          'Ubicación aproximada',
        );

        final participantView = controller.activityVisibleForCurrentUser(
          activity.copyWith(myStatus: ParticipantStatus.confirmed),
          now: unlockAt.subtract(const Duration(minutes: 1)),
        );
        expect(participantView.displayLat, activity.realLat);
        expect(participantView.displayLng, activity.realLng);
        expect(
          controller.locationDisclosureLabel(
            activity.copyWith(myStatus: ParticipantStatus.confirmed),
            now: unlockAt.subtract(const Duration(minutes: 1)),
          ),
          'Ubicación exacta disponible',
        );

        final creatorView = controller.activityVisibleForCurrentUser(
          activity.copyWith(creatorId: controller.state.user!.id),
          now: unlockAt.subtract(const Duration(minutes: 30)),
        );
        expect(creatorView.displayLat, activity.realLat);
        expect(creatorView.displayLng, activity.realLng);
      },
    );



    test('pre activity checklist persists per activity and user', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      final activity = firstController.state.activities.firstWhere(
        (item) => item.id == 'seed_1',
      );
      await firstController.joinActivity(activity.id);
      await firstController.confirmAttendance(activity.id);

      final joinedActivity = firstController.state.activities.firstWhere(
        (item) => item.id == activity.id,
      );
      expect(
        firstController.shouldShowPreActivityChecklist(joinedActivity),
        isTrue,
      );

      await firstController.togglePreActivityChecklistItem(
        activityId: activity.id,
        itemId: 'location',
      );
      await firstController.togglePreActivityChecklistItem(
        activityId: activity.id,
        itemId: 'time',
      );
      await firstController.markPreActivityChecklistComplete(activity.id);

      expect(
        firstController.isPreActivityChecklistComplete(activity.id),
        isTrue,
      );
      expect(
        firstController.preActivityChecklistCheckedItemIds(activity.id),
        hasLength(5),
      );

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );
      final restored = secondController.state.activities.firstWhere(
        (item) => item.id == activity.id,
      );

      expect(secondController.shouldShowPreActivityChecklist(restored), isTrue);
      expect(
        secondController.isPreActivityChecklistComplete(activity.id),
        isTrue,
      );
      expect(
        secondController.preActivityChecklistCheckedItemIds(activity.id),
        hasLength(5),
      );
    });
    test('editable profile persists locally and survives restart', () async {
      final sessionStore = _TestSessionStore(
        clientUid: 'client_001',
        phone: '+82 10 1234 5678',
      );
      final mockStore = _TestMockStore();

      final firstController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      await firstController.updateProfile(
        nickname: 'Mina',
        avatarEmoji: '☕',
        bio: 'Café suave y charla bonita.',
        languages: const ['Spanish', 'English'],
        vibes: const ['Calm', 'Social'],
        interests: const ['Coffee', 'Walks'],
      );

      expect(firstController.state.user!.nickname, 'Mina');
      expect(firstController.state.user!.avatarEmoji, '☕');
      expect(firstController.state.user!.bio, 'Café suave y charla bonita.');

      final secondController = await _buildController(
        sessionStore: sessionStore,
        mockStore: mockStore,
      );

      expect(secondController.state.user, isNotNull);
      expect(secondController.state.user!.nickname, 'Mina');
      expect(secondController.state.user!.avatarEmoji, '☕');
      expect(secondController.state.user!.bio, 'Café suave y charla bonita.');
      expect(secondController.state.user!.languages, ['Spanish', 'English']);
      expect(secondController.state.user!.vibes, ['Calm', 'Social']);
      expect(secondController.state.user!.interests, ['Coffee', 'Walks']);
    });

    test('restored profile text is sanitized to safe defaults', () {
      final user = AppUser.fromJson({
        'id': 'client_001',
        'phoneMasked': 'â€¢â€¢â€¢â€¢ 5679',
        'nickname': 'PequeÃ±a Luna',
        'avatarEmoji': 'ðŸŒ™',
        'bio': 'PequeÃ±os momentos, juntos.',
        'languages': const ['Korean'],
        'vibes': const ['Calm'],
        'interests': const ['Coffee'],
        'status': 'trusted',
        'profileComplete': true,
      });

      expect(user.phoneMasked, 'Sesión local');
      expect(user.nickname, 'Luna');
      expect(user.avatarEmoji, '🌙');
      expect(user.bio, 'Pequeños momentos, juntos.');
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
  final mockStore = _TestMockStore();
  mockStore.snapshot = LocalMockSnapshot(
    user: AppUser(
      id: 'client_001',
      phoneMasked: '•••• 5678',
      nickname: 'Luna',
      avatarEmoji: '🌙',
      bio: 'Pequeños momentos, juntos.',
      languages: const ['Korean', 'English'],
      vibes: const ['Calm', 'Creative'],
      interests: const ['Coffee', 'Walks', 'Study'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 0,
    ),
    activities: const [],
    messagesByActivityId: const {},
    savedActivityIds: const [],
    blockedUsers: const [],
    activityFilters: const {},
    settings: const {},
    reports: const [],
    feedbackEntries: const [],
  );
  return _buildController(
    sessionStore: _TestSessionStore(
      clientUid: 'client_001',
      phone: '+82 10 1234 5678',
    ),
    mockStore: mockStore,
  );
}

class _TestSessionStore extends LocalSessionStore {
  _TestSessionStore({
    this.clientUid,
    this.phone,
    this.mockSeedDisabledAfterWipe = false,
  });

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

