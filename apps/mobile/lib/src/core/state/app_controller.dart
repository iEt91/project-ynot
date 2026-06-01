import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../config/app_environment.dart';
import '../data/local_mock_store.dart';
import '../data/local_session_store.dart';
import '../models/activity.dart';
import '../models/activity_filters.dart';
import '../models/blocked_user.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/moderation_report.dart';
import '../models/private_feedback.dart';
import '../utils/app_logger.dart';
import '../utils/formatters.dart';

enum AppStage { booting, phoneAuth, otpEntry, onboarding, ready }

class AppState {
  const AppState({
    required this.stage,
    required this.demoMode,
    required this.activities,
    required this.chatMessages,
    required this.savedActivityIds,
    required this.blockedUsers,
    required this.dismissedBlockedChatWarningActivityIds,
    required this.settings,
    required this.activityFilters,
    required this.activitySearchQuery,
    required this.reports,
    required this.feedbackEntries,
    this.user,
    this.phoneInput = '',
    this.verificationInput = '',
    this.filter = ActivityFilter.all,
    this.errorMessage,
  });

  factory AppState.initial() {
    return AppState(
      stage: AppStage.booting,
      demoMode: AppEnvironment.isDemoMode,
      activities: const [],
      chatMessages: const {},
      savedActivityIds: const {},
      blockedUsers: const [],
      dismissedBlockedChatWarningActivityIds: const {},
      settings: AppSettings.initial(),
      activityFilters: ActivityDiscoveryFilters.initial(),
      activitySearchQuery: '',
      reports: const [],
      feedbackEntries: const [],
    );
  }

  final AppStage stage;
  final bool demoMode;
  final AppUser? user;
  final List<Activity> activities;
  final Map<String, List<ChatMessage>> chatMessages;
  final Set<String> savedActivityIds;
  final List<BlockedUserEntry> blockedUsers;
  final Set<String> dismissedBlockedChatWarningActivityIds;
  final AppSettings settings;
  final ActivityDiscoveryFilters activityFilters;
  final String activitySearchQuery;
  final List<ModerationReport> reports;
  final List<PrivateFeedbackEntry> feedbackEntries;
  final String phoneInput;
  final String verificationInput;
  final ActivityFilter filter;
  final String? errorMessage;

  AppState copyWith({
    AppStage? stage,
    bool? demoMode,
    AppUser? user,
    List<Activity>? activities,
    Map<String, List<ChatMessage>>? chatMessages,
    Set<String>? savedActivityIds,
    List<BlockedUserEntry>? blockedUsers,
    Set<String>? dismissedBlockedChatWarningActivityIds,
    AppSettings? settings,
    ActivityDiscoveryFilters? activityFilters,
    String? activitySearchQuery,
    List<ModerationReport>? reports,
    List<PrivateFeedbackEntry>? feedbackEntries,
    String? phoneInput,
    String? verificationInput,
    ActivityFilter? filter,
    String? errorMessage,
  }) {
    return AppState(
      stage: stage ?? this.stage,
      demoMode: demoMode ?? this.demoMode,
      user: user ?? this.user,
      activities: activities ?? this.activities,
      chatMessages: chatMessages ?? this.chatMessages,
      savedActivityIds: savedActivityIds ?? this.savedActivityIds,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      dismissedBlockedChatWarningActivityIds:
          dismissedBlockedChatWarningActivityIds ??
          this.dismissedBlockedChatWarningActivityIds,
      settings: settings ?? this.settings,
      activityFilters: activityFilters ?? this.activityFilters,
      activitySearchQuery: activitySearchQuery ?? this.activitySearchQuery,
      reports: reports ?? this.reports,
      feedbackEntries: feedbackEntries ?? this.feedbackEntries,
      phoneInput: phoneInput ?? this.phoneInput,
      verificationInput: verificationInput ?? this.verificationInput,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }
}

final appControllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => AppController(),
);

final appStateProvider = Provider<AppState>(
  (ref) => ref.watch(appControllerProvider).state,
);

class AppController extends ChangeNotifier {
  AppController({
    Object? repository,
    LocalSessionStore? sessionStore,
    LocalMockStore? mockStore,
    bool? demoModeOverride,
    bool autoInitialize = true,
  }) {
    _state = AppState.initial().copyWith(
      stage: AppStage.booting,
      demoMode: demoModeOverride ?? AppEnvironment.isDemoMode,
    );
    _sessionStore = sessionStore ?? LocalSessionStore();
    _mockStore = mockStore ?? LocalMockStore();
    if (autoInitialize) {
      unawaited(initialize());
    }
  }

  static const _demoCode = '000000';
  static final Map<String, AppUser> _demoPublicProfiles = {
    'seed_creator_mina': AppUser(
      id: 'seed_creator_mina',
      phoneMasked: 'Sesión local',
      nickname: 'Mina',
      avatarEmoji: '☕',
      bio: 'Suave, curiosa y buena para empezar charlas.',
      languages: ['Korean', 'English'],
      vibes: ['Calm', 'Social'],
      interests: ['Coffee', 'Walks', 'Music'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 1,
      attendingActivityCount: 2,
    ),
    'seed_participant_soojin': AppUser(
      id: 'seed_participant_soojin',
      phoneMasked: 'Sesión local',
      nickname: 'Soojin',
      avatarEmoji: '✨',
      bio: 'Traigo calma, ideas y buena vibra.',
      languages: ['Korean', 'English'],
      vibes: ['Creative', 'Calm'],
      interests: ['Coffee', 'Art', 'Study'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 3,
    ),
    'seed_participant_hana': AppUser(
      id: 'seed_participant_hana',
      phoneMasked: 'Sesión local',
      nickname: 'Hana',
      avatarEmoji: '🌙',
      bio: 'Prefiero planes tranquilos y bonitos.',
      languages: ['Korean', 'Japanese'],
      vibes: ['Calm', 'Productive'],
      interests: ['Study', 'Walks', 'Coffee'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 2,
    ),
    'seed_creator_jisoo': AppUser(
      id: 'seed_creator_jisoo',
      phoneMasked: 'Sesión local',
      nickname: 'Jisoo',
      avatarEmoji: '📚',
      bio: 'Me gusta estudiar con compañía y foco suave.',
      languages: ['Korean', 'English'],
      vibes: ['Productive', 'Calm'],
      interests: ['Study', 'Coffee', 'Music'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 1,
      attendingActivityCount: 1,
    ),
    'seed_participant_jiyoon': AppUser(
      id: 'seed_participant_jiyoon',
      phoneMasked: 'Sesión local',
      nickname: 'Jiyoon',
      avatarEmoji: '✨',
      bio: 'Orden, apuntes y una vibe tranquila.',
      languages: ['Korean', 'English'],
      vibes: ['Productive', 'Creative'],
      interests: ['Study', 'Art', 'Coffee'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 4,
    ),
    'seed_participant_mina': AppUser(
      id: 'seed_participant_mina',
      phoneMasked: 'Sesión local',
      nickname: 'Mina',
      avatarEmoji: '🌸',
      bio: 'Me gustan los planes suaves y luminosos.',
      languages: ['Korean', 'Spanish'],
      vibes: ['Social', 'Calm'],
      interests: ['Coffee', 'Walks', 'Food'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 2,
    ),
    'seed_creator_aria': AppUser(
      id: 'seed_creator_aria',
      phoneMasked: 'Sesión local',
      nickname: 'Aria',
      avatarEmoji: '🌙',
      bio: 'Llevo planes calm, aire libre y buena compañía.',
      languages: ['Korean', 'English'],
      vibes: ['Calm', 'Social'],
      interests: ['Walks', 'Music', 'Coffee'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 1,
      attendingActivityCount: 1,
    ),
    'seed_participant_juno': AppUser(
      id: 'seed_participant_juno',
      phoneMasked: 'Sesión local',
      nickname: 'Juno',
      avatarEmoji: '✨',
      bio: 'Siempre listo para una caminata con música suave.',
      languages: ['Korean', 'English'],
      vibes: ['Calm', 'Creative'],
      interests: ['Walks', 'Music', 'Food'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 3,
    ),
    'seed_participant_minsu': AppUser(
      id: 'seed_participant_minsu',
      phoneMasked: 'Sesión local',
      nickname: 'Minsu',
      avatarEmoji: '🙂',
      bio: 'Me gustan los planes tranquilos y cercanos.',
      languages: ['Korean', 'Japanese'],
      vibes: ['Calm', 'Social'],
      interests: ['Walks', 'Coffee', 'Food'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 2,
    ),
    'seed_creator_nari': AppUser(
      id: 'seed_creator_nari',
      phoneMasked: 'Sesión local',
      nickname: 'Nari',
      avatarEmoji: '🎨',
      bio: 'Arte, color y planes suaves para compartir.',
      languages: ['Korean', 'English'],
      vibes: ['Creative', 'Calm'],
      interests: ['Art', 'Coffee', 'Music'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 1,
      attendingActivityCount: 1,
    ),
    'seed_participant_dami': AppUser(
      id: 'seed_participant_dami',
      phoneMasked: 'Sesión local',
      nickname: 'Dami',
      avatarEmoji: '🙂',
      bio: 'Me sumo a planes creativos y tranquilos.',
      languages: ['Korean', 'English'],
      vibes: ['Creative', 'Social'],
      interests: ['Art', 'Study', 'Coffee'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 2,
    ),
    'seed_creator_sora': AppUser(
      id: 'seed_creator_sora',
      phoneMasked: 'Sesión local',
      nickname: 'Sora',
      avatarEmoji: '🍜',
      bio: 'Busco comida rica, charla suave y planes útiles.',
      languages: ['Korean', 'English'],
      vibes: ['Social', 'Calm'],
      interests: ['Food', 'Coffee', 'Walks'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 1,
      attendingActivityCount: 1,
    ),
    'seed_participant_yuna': AppUser(
      id: 'seed_participant_yuna',
      phoneMasked: 'Sesión local',
      nickname: 'Yuna',
      avatarEmoji: '✨',
      bio: 'Aprecio los planes simples y bonitos.',
      languages: ['Korean', 'Spanish'],
      vibes: ['Social', 'Creative'],
      interests: ['Food', 'Music', 'Coffee'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 3,
    ),
    'seed_participant_jiho': AppUser(
      id: 'seed_participant_jiho',
      phoneMasked: 'Sesión local',
      nickname: 'Jiho',
      avatarEmoji: '🌙',
      bio: 'Me funcionan los planes sencillos y cercanos.',
      languages: ['Korean', 'English'],
      vibes: ['Calm', 'Productive'],
      interests: ['Food', 'Study', 'Walks'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 2,
    ),
    'seed_creator_yura': AppUser(
      id: 'seed_creator_yura',
      phoneMasked: 'Sesión local',
      nickname: 'Yura',
      avatarEmoji: '🌸',
      bio: 'Me gustan los planes con calma y luz suave.',
      languages: ['Korean', 'English'],
      vibes: ['Calm', 'Creative'],
      interests: ['Walks', 'Art', 'Coffee'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 1,
      attendingActivityCount: 1,
    ),
    'seed_participant_ren': AppUser(
      id: 'seed_participant_ren',
      phoneMasked: 'Sesión local',
      nickname: 'Ren',
      avatarEmoji: '✨',
      bio: 'Siempre digo sí a un plan tranquilo y bonito.',
      languages: ['Korean', 'English'],
      vibes: ['Social', 'Calm'],
      interests: ['Walks', 'Music', 'Coffee'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 2,
    ),
  };

  final _random = Random();
  late final LocalSessionStore _sessionStore;
  late final LocalMockStore _mockStore;

  late AppState _state;
  String? _clientUid;

  final Map<String, List<ChatMessage>> _messagesByActivityId = {};
  final Map<String, String> _chatIdsByActivityId = {};
  final Set<String> _joinedActivityIds = {};
  final Set<String> _confirmedAttendanceActivityIds = {};
  final Set<String> _savedActivityIds = {};
  final List<BlockedUserEntry> _blockedUsers = [];
  final Set<String> _dismissedBlockedChatWarningActivityIds = {};

  AppState get state => _state;

  set state(AppState value) {
    _state = value;
    notifyListeners();
  }

  bool isUserBlocked(String userId) {
    return _blockedUsers.any((entry) => entry.userId == userId);
  }

  List<BlockedUserEntry> get blockedUsers =>
      List<BlockedUserEntry>.unmodifiable(_blockedUsers);

  bool hasDismissedBlockedChatWarning(String activityId) {
    return _dismissedBlockedChatWarningActivityIds.contains(activityId);
  }

  void dismissBlockedChatWarning(String activityId) {
    if (activityId.isEmpty) {
      return;
    }

    if (_dismissedBlockedChatWarningActivityIds.add(activityId)) {
      state = state.copyWith(
        dismissedBlockedChatWarningActivityIds:
            Set<String>.unmodifiable(_dismissedBlockedChatWarningActivityIds),
      );
      unawaited(_persistSnapshot());
    }
  }

  Future<void> initialize() async {
    AppLogger.log('BOOT', 'mode=mock');
    final localSession = await _sessionStore.peekClientUid();
    final restoredPhone = await _sessionStore.peekPhone();
    final allowSeedData = await _shouldUseSeedData();

    if (localSession == null || localSession.isEmpty) {
      AppLogger.log('AUTH', 'session_restored=false');
      state = state.copyWith(
        stage: AppStage.phoneAuth,
        user: null,
        activities: const [],
        chatMessages: const {},
        savedActivityIds: const {},
        settings: AppSettings.initial(),
        activityFilters: ActivityDiscoveryFilters.initial(),
        reports: const [],
        feedbackEntries: const [],
        errorMessage: null,
      );
      return;
    }

    _clientUid = localSession;

    final snapshot = await _mockStore.load();
    if (snapshot != null) {
      final restoredMessages = _restoreMessagesMap(
        snapshot.messagesByActivityId,
      );
      _hydrateFromSnapshot(
        snapshot,
        restoredMessages,
        allowSeedData: allowSeedData,
        phoneMasked: restoredPhone == null
            ? 'Sesión local'
            : safePhoneDisplay(restoredPhone),
      );
      AppLogger.log('AUTH', 'session_restored=true');
      return;
    }

    _joinResetFromStoredSession(localSession);

    final user = _buildDemoUser(
      localSession,
      phoneMasked: restoredPhone == null
          ? 'Sesión local'
          : safePhoneDisplay(restoredPhone),
    );

    AppLogger.log('AUTH', 'session_restored=true');
    state = state.copyWith(
      stage: _stageForUser(user),
      user: user,
      activities: allowSeedData ? _seedActivities() : const [],
      chatMessages: const {},
      savedActivityIds: const {},
      settings: AppSettings.initial(),
      activityFilters: ActivityDiscoveryFilters.initial(),
      reports: const [],
      feedbackEntries: const [],
      errorMessage: null,
    );
    unawaited(_persistSnapshot());
  }

  void updatePhoneInput(String value) {
    state = state.copyWith(phoneInput: value, errorMessage: null);
  }

  void updateVerificationInput(String value) {
    state = state.copyWith(verificationInput: value, errorMessage: null);
  }

  Future<void> sendVerificationCode() async {
    final phone = state.phoneInput.trim();
    if (phone.isEmpty || phone.length < 6) {
      state = state.copyWith(
        errorMessage: 'Escribe un número de teléfono válido.',
      );
      return;
    }

    state = state.copyWith(
      stage: AppStage.otpEntry,
      errorMessage: 'Usa 000000 para continuar.',
    );
  }

  Future<void> verifyCode() async {
    final code = state.verificationInput.trim();
    if (code != _demoCode) {
      state = state.copyWith(errorMessage: 'Usa 000000 para entrar.');
      return;
    }

    final clientUid = await _ensureClientUid();
    await _sessionStore.saveClientSession(
      clientUid: clientUid,
      phone: state.phoneInput.trim(),
    );

    final user = _buildDemoUser(
      clientUid,
      phoneMasked: safePhoneDisplay(maskPhone(state.phoneInput)),
    );

    await _activateAuthenticatedState(
      user: user,
      phoneMasked: safePhoneDisplay(maskPhone(state.phoneInput)),
      clientUid: clientUid,
    );
    unawaited(_persistSnapshot());

    AppLogger.log('AUTH', 'login_success userId=${user.id}');
  }

  Future<void> completeOnboarding({
    required String nickname,
    required String avatarEmoji,
    required List<String> languages,
    required List<String> vibes,
    required List<String> interests,
    String bio = '',
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final sanitizedInterests = interests
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final safeInterests = sanitizedInterests.isEmpty
        ? const ['Coffee']
        : sanitizedInterests;

    state = state.copyWith(
      user: currentUser.copyWith(
        nickname: safeDisplayText(nickname, fallback: 'Luna'),
        avatarEmoji: safeDisplayText(avatarEmoji, fallback: '🌙'),
        languages: languages,
        vibes: vibes,
        interests: safeInterests,
        bio: safeDisplayText(bio, fallback: 'Pequeños momentos, juntos.'),
        profileComplete: true,
      ),
      stage: AppStage.ready,
      errorMessage: null,
    );
    unawaited(_persistSnapshot());
  }

  Future<void> updateProfile({
    required String nickname,
    required String avatarEmoji,
    required String bio,
    required List<String> languages,
    required List<String> vibes,
    required List<String> interests,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(
      user: currentUser.copyWith(
        nickname: safeDisplayText(nickname, fallback: 'Luna'),
        avatarEmoji: safeDisplayText(avatarEmoji, fallback: '🌙'),
        bio: safeDisplayText(bio, fallback: 'Pequeños momentos, juntos.'),
        languages: languages,
        vibes: vibes,
        interests: interests,
      ),
    );
    unawaited(_persistSnapshot());
  }

  void signOut() {
    AppLogger.log('AUTH', 'logout');
    unawaited(_sessionStore.clear());
    _clientUid = null;
    _messagesByActivityId.clear();
    _chatIdsByActivityId.clear();
    _joinedActivityIds.clear();
    _confirmedAttendanceActivityIds.clear();
    _savedActivityIds.clear();
    _blockedUsers.clear();
    _dismissedBlockedChatWarningActivityIds.clear();
    state = AppState.initial().copyWith(
      stage: AppStage.phoneAuth,
      demoMode: true,
      activities: const [],
      chatMessages: const {},
      savedActivityIds: const {},
      settings: AppSettings.initial(),
      activityFilters: ActivityDiscoveryFilters.initial(),
      reports: const [],
      feedbackEntries: const [],
      errorMessage: null,
    );
  }

  Future<void> clearLocalData() async {
    await _sessionStore.clear();
    await _mockStore.clear();
    await _sessionStore.setMockSeedDisabledAfterWipe(true);
    AppLogger.log('WIPE', 'local data cleared');
    _clientUid = null;
    _messagesByActivityId.clear();
    _chatIdsByActivityId.clear();
    _joinedActivityIds.clear();
    _confirmedAttendanceActivityIds.clear();
    _savedActivityIds.clear();
    state = AppState.initial().copyWith(
      stage: AppStage.phoneAuth,
      demoMode: true,
      activities: const [],
      chatMessages: const {},
      savedActivityIds: const {},
      settings: AppSettings.initial(),
      activityFilters: ActivityDiscoveryFilters.initial(),
      reports: const [],
      feedbackEntries: const [],
      errorMessage: null,
    );
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    unawaited(_persistSnapshot());
  }

  Future<void> setChatMessagesNotifications(bool value) {
    return updateSettings(
      state.settings.copyWith(chatMessagesNotifications: value),
    );
  }

  Future<void> setRecommendedActivitiesNotifications(bool value) {
    return updateSettings(
      state.settings.copyWith(recommendedActivitiesNotifications: value),
    );
  }

  Future<void> setActivityStartingSoonNotifications(bool value) {
    return updateSettings(
      state.settings.copyWith(activityStartingSoonNotifications: value),
    );
  }

  Future<void> setHidePreciseLocationUntilUnlock(bool value) {
    return updateSettings(
      state.settings.copyWith(hidePreciseLocationUntilUnlock: value),
    );
  }

  Future<void> setPersonalizedRecommendations(bool value) {
    return updateSettings(
      state.settings.copyWith(personalizedRecommendations: value),
    );
  }

  Future<void> _activateAuthenticatedState({
    required AppUser user,
    required String phoneMasked,
    required String clientUid,
  }) async {
    _joinResetFromStoredSession(clientUid);
    final allowSeedData = await _shouldUseSeedData();

    final snapshot = await _mockStore.load();
    if (snapshot != null) {
      final restoredMessages = _restoreMessagesMap(
        snapshot.messagesByActivityId,
      );
      _hydrateFromSnapshot(
        snapshot,
        restoredMessages,
        allowSeedData: allowSeedData,
        phoneMasked: phoneMasked,
      );
      return;
    }

    state = state.copyWith(
      user: user,
      stage: _stageForUser(user),
      activities: allowSeedData ? _seedActivities() : const [],
      chatMessages: const {},
      savedActivityIds: const {},
      settings: AppSettings.initial(),
      activityFilters: ActivityDiscoveryFilters.initial(),
      reports: const [],
      feedbackEntries: const [],
      errorMessage: null,
    );
  }

  void setFilter(ActivityFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> createActivity({
    required String title,
    required String description,
    required String category,
    required String vibe,
    required String zone,
    required DateTime startTime,
    required Duration duration,
    required int maxPeople,
    required double realLat,
    required double realLng,
    ActivityVisibility visibility = ActivityVisibility.publicActivity,
  }) async {
    if (!canCreateActivity()) {
      state = state.copyWith(errorMessage: creationRestrictionMessage());
      return;
    }

    final currentUser = state.user;
    if (currentUser == null) {
      state = state.copyWith(
        errorMessage: 'Inicia sesión para crear una actividad.',
      );
      return;
    }

    final created = _buildActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      creatorId: currentUser.id,
      creatorLabel: state.user?.nickname.isNotEmpty == true
          ? state.user!.nickname
          : 'Tú',
      isMine: true,
      title: title,
      description: description,
      category: category,
      vibe: vibe,
      zone: zone,
      startTime: startTime,
      duration: duration,
      maxPeople: maxPeople,
      realLat: realLat,
      realLng: realLng,
      visibility: visibility,
    ).copyWith(confirmedCount: 1, myStatus: ParticipantStatus.confirmed);

    state = state.copyWith(
      activities: [
        created,
        ...state.activities.where((activity) => activity.id != created.id),
      ],
      user: state.user?.copyWith(
        createdActivityCount: (state.user?.createdActivityCount ?? 0) + 1,
        attendingActivityCount: (state.user?.attendingActivityCount ?? 0) + 1,
      ),
    );

    _joinedActivityIds.add(created.id);
    _confirmedAttendanceActivityIds.add(created.id);

    AppLogger.log('ACTIVITY', 'created id=${created.id}');
    unawaited(_persistSnapshot());
  }

  Future<bool> updateActivity({
    required String activityId,
    required String title,
    required String description,
    required String category,
    required String vibe,
    required String zone,
    required DateTime startTime,
    required Duration duration,
    required int maxPeople,
    required double realLat,
    required double realLng,
    ActivityVisibility visibility = ActivityVisibility.publicActivity,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      state = state.copyWith(
        errorMessage: 'Inicia sesión para editar una actividad.',
      );
      return false;
    }

    final activity = _findActivity(activityId);
    if (activity == null || activity.creatorId != currentUser.id) {
      return false;
    }

    final nextMaxPeople = max(maxPeople, activity.confirmedCount);
    final updated = _updateActivity(activityId, (current) {
      final nextStatus = switch (current.status) {
        ActivityStatus.ongoing => ActivityStatus.ongoing,
        ActivityStatus.finished => ActivityStatus.finished,
        ActivityStatus.archived => ActivityStatus.archived,
        ActivityStatus.cancelled => ActivityStatus.cancelled,
        ActivityStatus.flagged => ActivityStatus.flagged,
        ActivityStatus.removed => ActivityStatus.removed,
        ActivityStatus.rejectedHidden => ActivityStatus.rejectedHidden,
        ActivityStatus.draft => ActivityStatus.draft,
        ActivityStatus.pendingModeration => ActivityStatus.pendingModeration,
        _ =>
          current.confirmedCount >= nextMaxPeople
              ? ActivityStatus.full
              : ActivityStatus.open,
      };

      final endTime = startTime.add(duration);
      final privacyRadius = current.locationPrivacyRadiusM > 0
          ? current.locationPrivacyRadiusM
          : 100 + _random.nextInt(201);
      final offset = _random.nextDouble() * privacyRadius;
      final signLat = _random.nextBool() ? 1 : -1;
      final signLng = _random.nextBool() ? 1 : -1;
      final displayLat = realLat + signLat * (offset / 111320.0);
      final displayLng =
          realLng + signLng * (offset / (111320.0 * cos(realLat * pi / 180.0)));

      return current.copyWith(
        title: title,
        description: description,
        category: category,
        vibe: vibe,
        zone: zone,
        status: nextStatus,
        realLat: realLat,
        realLng: realLng,
        displayLat: displayLat,
        displayLng: displayLng,
        locationPrivacyRadiusM: privacyRadius,
        exactLocationUnlockAt: startTime.subtract(const Duration(minutes: 10)),
        startTime: startTime,
        endTime: endTime,
        maxPeople: nextMaxPeople,
        visibility: visibility,
      );
    });

    final changed = _activityChanged(activityId, updated);
    if (!changed) return false;

    state = state.copyWith(activities: updated);
    unawaited(_persistSnapshot());
    return true;
  }

  Future<void> joinActivity(String activityId) async {
    final updated = _updateActivity(activityId, (activity) {
      final user = state.user;
      final isRestricted =
          user?.status == UserStatus.limited ||
          user?.status == UserStatus.banned;
      if (isRestricted || !activity.isJoinable) {
        return activity;
      }

      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation ||
          activity.myStatus == ParticipantStatus.confirmed) {
        return activity;
      }

      final nextPending = activity.pendingCount + 1;
      _joinedActivityIds.add(activityId);
      return activity.copyWith(
        pendingCount: nextPending,
        myStatus: ParticipantStatus.joinedPendingConfirmation,
      );
    });

    state = state.copyWith(activities: updated);
    unawaited(_persistSnapshot());
  }

  Future<void> confirmAttendance(String activityId) async {
    final currentUser = state.user;
    final updated = _updateActivity(activityId, (activity) {
      if (activity.isFinishedOrArchived ||
          activity.myStatus != ParticipantStatus.joinedPendingConfirmation) {
        return activity;
      }

      final nextTargets = _upsertFeedbackTarget(
        activity.feedbackTargets,
        target: _currentUserFeedbackTarget(currentUser),
      );
      final nextConfirmedCount = activity.confirmedCount + 1;
      _confirmedAttendanceActivityIds.add(activityId);
      return activity.copyWith(
        pendingCount: activity.pendingCount > 0 ? activity.pendingCount - 1 : 0,
        confirmedCount: nextConfirmedCount,
        myStatus: ParticipantStatus.confirmed,
        feedbackTargets: nextTargets,
        status: _nextLifecycleStatus(
          activity,
          confirmedCount: nextConfirmedCount,
        ),
      );
    });

    state = state.copyWith(
      activities: updated,
      user: state.user?.copyWith(
        attendingActivityCount: (state.user?.attendingActivityCount ?? 0) + 1,
      ),
    );
    unawaited(_persistSnapshot());
  }

  Future<void> cancelAttendance(String activityId) async {
    final currentUser = state.user;
    var shouldDecreaseAttendance = false;
    final updated = _updateActivity(activityId, (activity) {
      if (activity.isFinishedOrArchived) {
        return activity;
      }

      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation) {
        _confirmedAttendanceActivityIds.remove(activityId);
        final nextTargets = activity.feedbackTargets
            .where((target) => target.userId != currentUser?.id)
            .toList(growable: false);
        final nextPendingCount = activity.pendingCount > 0
            ? activity.pendingCount - 1
            : 0;
        return activity.copyWith(
          pendingCount: nextPendingCount,
          myStatus: ParticipantStatus.cancelled,
          feedbackTargets: nextTargets,
          status: _nextLifecycleStatus(
            activity,
            confirmedCount: activity.confirmedCount,
          ),
        );
      }

      if (activity.myStatus == ParticipantStatus.confirmed) {
        _confirmedAttendanceActivityIds.remove(activityId);
        shouldDecreaseAttendance = true;
        final nextConfirmedCount = activity.confirmedCount > 0
            ? activity.confirmedCount - 1
            : 0;
        final nextTargets = activity.feedbackTargets
            .where((target) => target.userId != currentUser?.id)
            .toList(growable: false);
        return activity.copyWith(
          confirmedCount: nextConfirmedCount,
          myStatus: ParticipantStatus.cancelled,
          feedbackTargets: nextTargets,
          status: _nextLifecycleStatus(
            activity,
            confirmedCount: nextConfirmedCount,
          ),
        );
      }

      return activity;
    });

    state = state.copyWith(
      activities: updated,
      user: shouldDecreaseAttendance
          ? state.user?.copyWith(
              attendingActivityCount:
                  (state.user?.attendingActivityCount ?? 0) > 0
                  ? (state.user?.attendingActivityCount ?? 0) - 1
                  : 0,
            )
          : state.user,
    );
    unawaited(_persistSnapshot());
  }

  Future<void> leaveActivity(String activityId) async {
    final currentUser = state.user;
    final updated = _updateActivity(activityId, (activity) {
      if (activity.isFinishedOrArchived) {
        return activity;
      }

      if (currentUser != null && activity.creatorId == currentUser.id) {
        return activity;
      }

      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation) {
        _joinedActivityIds.remove(activityId);
        final nextTargets = activity.feedbackTargets
            .where((target) => target.userId != currentUser?.id)
            .toList(growable: false);
        final nextPendingCount = activity.pendingCount > 0
            ? activity.pendingCount - 1
            : 0;
        return activity.copyWith(
          pendingCount: nextPendingCount,
          myStatus: ParticipantStatus.left,
          feedbackTargets: nextTargets,
          status: _nextLifecycleStatus(
            activity,
            confirmedCount: activity.confirmedCount,
          ),
        );
      }

      if (activity.myStatus == ParticipantStatus.confirmed) {
        _joinedActivityIds.remove(activityId);
        _confirmedAttendanceActivityIds.remove(activityId);
        final nextConfirmedCount = activity.confirmedCount > 0
            ? activity.confirmedCount - 1
            : 0;
        final nextTargets = activity.feedbackTargets
            .where((target) => target.userId != currentUser?.id)
            .toList(growable: false);
        return activity.copyWith(
          confirmedCount: nextConfirmedCount,
          myStatus: ParticipantStatus.left,
          feedbackTargets: nextTargets,
          status: _nextLifecycleStatus(
            activity,
            confirmedCount: nextConfirmedCount,
          ),
        );
      }

      return activity;
    });

    state = state.copyWith(
      activities: updated,
      user: state.user?.copyWith(
        attendingActivityCount: (state.user?.attendingActivityCount ?? 0) > 0
            ? (state.user?.attendingActivityCount ?? 0) - 1
            : 0,
      ),
    );
    unawaited(_persistSnapshot());
  }

  Future<void> loadChatMessages(String activityId) async {
    AppLogger.log('CHAT', 'open activityId=$activityId');
    final chatId = _resolveChatId(activityId);
    final messages = List<ChatMessage>.from(
      _messagesByActivityId[chatId] ?? const [],
    );
    AppLogger.log('CHAT', 'load source=mock count=${messages.length}');
    _setChatMessages(activityId, messages, chatId: chatId, source: 'mock');
  }

  Future<void> watchChatMessages(String activityId) async {
    // In-memory mock does not need a realtime subscription.
  }

  Future<void> stopWatchingChatMessages(String activityId) async {
    // In-memory mock does not need a realtime subscription.
  }

  Future<void> sendChatMessage(String activityId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final user = state.user;
    if (user == null) return;

    final activity = _findActivity(activityId);
    if (activity == null || activity.isFinishedOrArchived) {
      return;
    }

    await _ensureClientUid();
    final chatId = _resolveChatId(activityId);
    final message = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
      chatId: chatId,
      activityId: activityId,
      senderId: user.id,
      senderName: user.nickname.isNotEmpty ? user.nickname : 'Tú',
      senderEmoji: user.avatarEmoji,
      content: text,
      createdAt: DateTime.now(),
      isMe: true,
    );

    final messages = List<ChatMessage>.from(
      _messagesByActivityId[chatId] ?? const [],
    );
    messages.add(message);
    _messagesByActivityId[chatId] = messages;
    _setChatMessages(activityId, messages, chatId: chatId, source: 'mock');
    AppLogger.log('MESSAGE', 'sent activityId=$activityId');
    unawaited(_persistSnapshot());
  }

  Future<bool> submitReport({
    required String reporterUserId,
    required ReportTargetType targetType,
    required String targetId,
    required String activityId,
    required ReportReason reason,
    String? note,
  }) async {
    if (hasSubmittedReport(
      reporterUserId: reporterUserId,
      targetType: targetType,
      targetId: targetId,
    )) {
      return false;
    }

    final report = ModerationReport(
      reportId:
          'report_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
      reporterUserId: reporterUserId,
      targetType: targetType,
      targetId: targetId,
      activityId: activityId,
      reason: reason,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: DateTime.now(),
    );

    state = state.copyWith(reports: [report, ...state.reports]);
    unawaited(_persistSnapshot());
    return true;
  }

  Future<bool> reportChatMessage({
    required String messageId,
    required String chatId,
    required String activityId,
    required String senderId,
    required String reporterId,
    required String content,
    required DateTime timestamp,
  }) async {
    return submitReport(
      reporterUserId: reporterId,
      targetType: ReportTargetType.message,
      targetId: messageId,
      activityId: activityId,
      reason: ReportReason.inappropriateMessage,
      note: content,
    );
  }

  Future<void> refreshActivity(String activityId) async {
    // In-memory mock keeps the current activity list as source of truth.
  }

  Future<bool> startActivity(String activityId) async {
    final currentUser = state.user;
    final updated = _updateActivity(activityId, (activity) {
      if (currentUser == null ||
          activity.creatorId != currentUser.id ||
          !(activity.status == ActivityStatus.open ||
              activity.status == ActivityStatus.active ||
              activity.status == ActivityStatus.full)) {
        return activity;
      }

      return activity.copyWith(status: ActivityStatus.ongoing);
    });

    final changed = _activityChanged(activityId, updated);
    if (!changed) return false;

    state = state.copyWith(activities: updated);
    unawaited(_persistSnapshot());
    return true;
  }

  Future<bool> finishActivity(String activityId) async {
    final currentUser = state.user;
    final updated = _updateActivity(activityId, (activity) {
      if (currentUser == null ||
          activity.creatorId != currentUser.id ||
          activity.status != ActivityStatus.ongoing) {
        return activity;
      }

      return activity.copyWith(status: ActivityStatus.finished);
    });

    final changed = _activityChanged(activityId, updated);
    if (!changed) return false;

    _savedActivityIds.remove(activityId);
    state = state.copyWith(
      activities: updated,
      savedActivityIds: Set<String>.from(_savedActivityIds),
    );
    unawaited(_persistSnapshot());
    return true;
  }

  Future<bool> archiveActivity(String activityId) async {
    final currentUser = state.user;
    final updated = _updateActivity(activityId, (activity) {
      if (currentUser == null ||
          activity.creatorId != currentUser.id ||
          activity.status != ActivityStatus.finished) {
        return activity;
      }

      return activity.copyWith(status: ActivityStatus.archived);
    });

    final changed = _activityChanged(activityId, updated);
    if (!changed) return false;

    _savedActivityIds.remove(activityId);
    state = state.copyWith(
      activities: updated,
      savedActivityIds: Set<String>.from(_savedActivityIds),
    );
    unawaited(_persistSnapshot());
    return true;
  }

  bool hasSubmittedFeedback({
    required String activityId,
    required String reviewerUserId,
    required String reviewedUserId,
  }) {
    return state.feedbackEntries.any(
      (entry) =>
          entry.activityId == activityId &&
          entry.reviewerUserId == reviewerUserId &&
          entry.reviewedUserId == reviewedUserId,
    );
  }

  bool hasSubmittedReport({
    required String reporterUserId,
    required ReportTargetType targetType,
    required String targetId,
  }) {
    return state.reports.any(
      (report) =>
          report.reporterUserId == reporterUserId &&
          report.targetType == targetType &&
          report.targetId == targetId,
    );
  }

  List<ActivityFeedbackTarget> feedbackTargetsForActivity(
    Activity activity,
    String currentUserId,
  ) {
    final baseTargets = activity.feedbackTargets.isEmpty
        ? [
            ActivityFeedbackTarget(
              userId: activity.creatorId,
              label: activity.creatorLabel,
              emoji: activity.emoji,
            ),
          ]
        : activity.feedbackTargets;

    final targets = baseTargets
        .where((target) => target.userId != currentUserId)
        .toList(growable: true);
    final currentUserIncluded = baseTargets.any(
      (target) => target.userId == currentUserId,
    );
    final desiredCount = currentUserIncluded
        ? max(0, activity.confirmedCount - 1)
        : max(0, activity.confirmedCount);
    final totalCount = max(targets.length, desiredCount);

    for (var index = targets.length; index < totalCount; index++) {
      final number = index + 1;
      targets.add(
        ActivityFeedbackTarget(
          userId: '${activity.id}_feedback_$number',
          label: 'Asistente $number',
          emoji: _feedbackPlaceholderEmoji(index),
        ),
      );
    }

    return targets;
  }

  List<ActivityFeedbackTarget> confirmedAttendeesForActivity(
    Activity activity,
  ) {
    return activity.feedbackTargets
        .where((target) => target.userId != activity.creatorId)
        .toList(growable: false);
  }

  bool hasBlockedParticipants(Activity activity) {
    if (isUserBlocked(activity.creatorId)) {
      return true;
    }

    return activity.feedbackTargets.any(
      (target) =>
          target.userId != activity.creatorId && isUserBlocked(target.userId),
    );
  }

  Future<bool> submitPrivateFeedback({
    required String activityId,
    required String reviewerUserId,
    required String reviewedUserId,
    required PrivateFeedbackOption selectedFeedback,
  }) async {
    final currentActivity = _findActivity(activityId);
    if (currentActivity == null ||
        reviewerUserId.isEmpty ||
        reviewedUserId.isEmpty ||
        reviewerUserId == reviewedUserId) {
      return false;
    }

    if (hasSubmittedFeedback(
      activityId: activityId,
      reviewerUserId: reviewerUserId,
      reviewedUserId: reviewedUserId,
    )) {
      return false;
    }

    final entry = PrivateFeedbackEntry(
      activityId: activityId,
      reviewerUserId: reviewerUserId,
      reviewedUserId: reviewedUserId,
      selectedFeedback: selectedFeedback,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(feedbackEntries: [entry, ...state.feedbackEntries]);
    unawaited(_persistSnapshot());
    return true;
  }

  bool canCreateActivity() {
    final currentUser = state.user;
    if (currentUser == null) {
      return false;
    }

    return !_hasActiveCreatedActivity(currentUser.id);
  }

  String? creationRestrictionMessage() {
    final currentUser = state.user;
    if (currentUser == null) {
      return 'Inicia sesión para crear una actividad.';
    }

    if (_hasActiveCreatedActivity(currentUser.id)) {
      return 'Ya tienes una actividad activa. Elimínala o espera a que termine para crear otra.';
    }

    return null;
  }

  Future<bool> deleteActivity(String activityId) async {
    final currentUser = state.user;
    Activity? activity;
    for (final item in state.activities) {
      if (item.id == activityId) {
        activity = item;
        break;
      }
    }
    if (currentUser == null ||
        activity == null ||
        activity.creatorId != currentUser.id) {
      return false;
    }

    final nextActivities = state.activities
        .where((item) => item.id != activityId)
        .toList(growable: false);
    _messagesByActivityId.remove(activityId);
    _chatIdsByActivityId.remove(activityId);
    _joinedActivityIds.remove(activityId);
    _confirmedAttendanceActivityIds.remove(activityId);
    _savedActivityIds.remove(activityId);

    final nextChatMessages = Map<String, List<ChatMessage>>.from(
      state.chatMessages,
    )..remove(activityId);
    final nextReports = state.reports
        .where((report) => report.activityId != activityId)
        .toList(growable: false);
    final createdCount = currentUser.createdActivityCount > 0
        ? currentUser.createdActivityCount - 1
        : 0;
    final attendingCount = currentUser.attendingActivityCount > 0
        ? currentUser.attendingActivityCount - 1
        : 0;

    state = state.copyWith(
      activities: nextActivities,
      chatMessages: nextChatMessages,
      savedActivityIds: Set<String>.from(_savedActivityIds),
      reports: nextReports,
      feedbackEntries: state.feedbackEntries
          .where((entry) => entry.activityId != activityId)
          .toList(growable: false),
      user: currentUser.copyWith(
        createdActivityCount: createdCount,
        attendingActivityCount: attendingCount,
      ),
    );
    unawaited(_persistSnapshot());
    return true;
  }

  Future<bool> blockUser(AppUser target) async {
    final currentUser = state.user;
    if (currentUser == null ||
        target.id.isEmpty ||
        target.id == currentUser.id ||
        isUserBlocked(target.id)) {
      return false;
    }

    _blockedUsers.add(
      BlockedUserEntry(
        userId: target.id,
        nickname: safeDisplayText(target.nickname, fallback: 'Luna'),
        avatarEmoji: safeDisplayText(target.avatarEmoji, fallback: '🌙'),
        blockedAt: DateTime.now(),
      ),
    );
    state = state.copyWith(
      blockedUsers: List<BlockedUserEntry>.unmodifiable(_blockedUsers),
    );
    unawaited(_persistSnapshot());
    return true;
  }

  Future<void> unblockUser(String userId) async {
    _blockedUsers.removeWhere((entry) => entry.userId == userId);
    state = state.copyWith(
      blockedUsers: List<BlockedUserEntry>.unmodifiable(_blockedUsers),
    );
    unawaited(_persistSnapshot());
  }

  bool isActivitySaved(String activityId) {
    return _savedActivityIds.contains(activityId);
  }

  Future<bool> toggleSavedActivity(String activityId) async {
    final activity = _findActivity(activityId);
    if (activity == null || !activity.isActiveLifecycle) {
      return false;
    }

    if (_savedActivityIds.contains(activityId)) {
      _savedActivityIds.remove(activityId);
    } else {
      _savedActivityIds.add(activityId);
    }

    state = state.copyWith(
      savedActivityIds: Set<String>.from(_savedActivityIds),
    );
    unawaited(_persistSnapshot());
    return true;
  }

  List<Activity> savedActivities() {
    final savedIds = _savedActivityIds;
    return state.activities
        .where(
          (activity) =>
              savedIds.contains(activity.id) && activity.isActiveLifecycle,
        )
        .toList(growable: false)
      ..sort((left, right) => left.startTime.compareTo(right.startTime));
  }

  List<Activity> filteredActivities() {
    final visibleActivities = state.activities
        .where((activity) => activity.isActiveLifecycle)
        .toList(growable: false);

    final filters = state.activityFilters;
    final query = state.activitySearchQuery.trim().toLowerCase();
    if (filters.isEmpty) {
      return query.isEmpty
          ? visibleActivities
          : visibleActivities
                .where((activity) => _matchesSearchQuery(activity, query))
                .toList(growable: false);
    }

    return visibleActivities
        .where((activity) {
          if (filters.today) {
            final now = DateTime.now();
            final isToday =
                activity.startTime.year == now.year &&
                activity.startTime.month == now.month &&
                activity.startTime.day == now.day;
            if (!isToday) return false;
          }

          if (filters.timeSlot != null &&
              !_matchesTimeSlot(activity, filters.timeSlot!)) {
            return false;
          }

          if (filters.categories.isNotEmpty &&
              !filters.categories.contains(activity.category)) {
            return false;
          }

          if (filters.peopleRange != null &&
              !_matchesPeopleRange(activity, filters.peopleRange!)) {
            return false;
          }

          if (query.isNotEmpty && !_matchesSearchQuery(activity, query)) {
            return false;
          }

          return true;
        })
        .toList(growable: false);
  }

  void setActivitySearchQuery(String query) {
    state = state.copyWith(activitySearchQuery: query);
    unawaited(_persistSnapshot());
  }

  void toggleTodayFilter() {
    state = state.copyWith(
      activityFilters: state.activityFilters.copyWith(
        today: !state.activityFilters.today,
      ),
    );
    unawaited(_persistSnapshot());
  }

  void setTimeSlotFilter(ActivityTimeSlot? timeSlot) {
    state = state.copyWith(
      activityFilters: state.activityFilters.copyWith(timeSlot: timeSlot),
    );
    unawaited(_persistSnapshot());
  }

  void toggleCategoryFilter(String category) {
    state = state.copyWith(
      activityFilters: state.activityFilters.toggleCategory(category),
    );
    unawaited(_persistSnapshot());
  }

  void setPeopleRangeFilter(ActivityPeopleRange? range) {
    state = state.copyWith(
      activityFilters: state.activityFilters.copyWith(peopleRange: range),
    );
    unawaited(_persistSnapshot());
  }

  void clearActivityFilters() {
    state = state.copyWith(activityFilters: ActivityDiscoveryFilters.initial());
    unawaited(_persistSnapshot());
  }

  Future<String?> ensureChatId(String activityId) async {
    return _resolveChatId(activityId);
  }

  bool _matchesTimeSlot(Activity activity, ActivityTimeSlot timeSlot) {
    final hour = activity.startTime.hour;
    return switch (timeSlot) {
      ActivityTimeSlot.morning => hour >= 5 && hour < 12,
      ActivityTimeSlot.afternoon => hour >= 12 && hour < 18,
      ActivityTimeSlot.night => hour >= 18 || hour < 5,
    };
  }

  bool _matchesPeopleRange(Activity activity, ActivityPeopleRange range) {
    return switch (range) {
      ActivityPeopleRange.twoToFour =>
        activity.maxPeople >= 2 && activity.maxPeople <= 4,
      ActivityPeopleRange.fiveToEight =>
        activity.maxPeople >= 5 && activity.maxPeople <= 8,
      ActivityPeopleRange.ninePlus => activity.maxPeople >= 9,
    };
  }

  bool _matchesSearchQuery(Activity activity, String query) {
    if (query.isEmpty) {
      return true;
    }

    final haystack = <String>[
      activity.title,
      activity.description,
      activity.zone,
      activity.category,
      activity.vibe,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  List<Activity> activeActivitiesForUser(String userId) {
    return state.activities
        .where(
          (activity) =>
              !activity.isFinishedOrArchived &&
              activity.status != ActivityStatus.removed &&
              activity.status != ActivityStatus.rejectedHidden &&
              (activity.creatorId == userId ||
                  activity.myStatus ==
                      ParticipantStatus.joinedPendingConfirmation ||
                  activity.myStatus == ParticipantStatus.confirmed),
        )
        .toList(growable: false);
  }

  List<Activity> historyActivitiesForUser(String userId) {
    return state.activities
        .where(
          (activity) =>
              activity.isFinishedOrArchived &&
              (activity.creatorId == userId ||
                  activity.myStatus ==
                      ParticipantStatus.joinedPendingConfirmation ||
                  activity.myStatus == ParticipantStatus.confirmed ||
                  activity.myStatus == ParticipantStatus.attended ||
                  activity.myStatus == ParticipantStatus.noShow ||
                  activity.myStatus == ParticipantStatus.notSure),
        )
        .toList(growable: false);
  }

  Activity? _findActivity(String activityId) {
    for (final activity in state.activities) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    return null;
  }

  String _categoryEmoji(String category) {
    return switch (category) {
      'Coffee' => '☕',
      'Study' => '📚',
      'Walks' => '🌙',
      'Food' => '🍜',
      'Art' => '🎨',
      'Music' => '🎵',
      _ => '🌙',
    };
  }

  AppUser _buildDemoUser(String id, {required String phoneMasked}) {
    return AppUser(
      id: id,
      phoneMasked: safePhoneDisplay(phoneMasked),
      nickname: 'Luna',
      avatarEmoji: '🌙',
      bio: '',
      languages: const [],
      vibes: const [],
      interests: const [],
      status: UserStatus.trusted,
      profileComplete: false,
      createdActivityCount: 0,
      attendingActivityCount: 0,
    );
  }

  AppUser? publicProfileForUserId(String userId) {
    final currentUser = state.user;
    if (currentUser != null && currentUser.id == userId) {
      return currentUser.sanitizedForDisplay();
    }

    final demoUser = _demoPublicProfiles[userId];
    if (demoUser != null) {
      return demoUser.sanitizedForDisplay();
    }

    return null;
  }

  Activity _buildActivity({
    required String id,
    required String creatorId,
    required String creatorLabel,
    required bool isMine,
    required String title,
    required String description,
    required String category,
    required String vibe,
    required String zone,
    required DateTime startTime,
    required Duration duration,
    required int maxPeople,
    required double realLat,
    required double realLng,
    required ActivityVisibility visibility,
  }) {
    final privacyRadius = 100 + _random.nextInt(201);
    final offset = _random.nextDouble() * privacyRadius;
    final signLat = _random.nextBool() ? 1 : -1;
    final signLng = _random.nextBool() ? 1 : -1;
    final displayLat = realLat + signLat * (offset / 111320.0);
    final displayLng =
        realLng + signLng * (offset / (111320.0 * cos(realLat * pi / 180.0)));
    final endTime = startTime.add(duration);

    return Activity(
      id: id,
      creatorId: creatorId,
      creatorLabel: creatorLabel,
      activityType: ActivityType.userActivity,
      visibility: visibility,
      title: title,
      description: description,
      category: category,
      vibe: vibe,
      zone: zone,
      status: ActivityStatus.open,
      realLat: realLat,
      realLng: realLng,
      displayLat: displayLat,
      displayLng: displayLng,
      locationPrivacyRadiusM: privacyRadius,
      exactLocationUnlockAt: startTime.subtract(const Duration(minutes: 10)),
      startTime: startTime,
      endTime: endTime,
      maxPeople: maxPeople,
      confirmedCount: 0,
      pendingCount: 0,
      feedbackTargets: [
        ActivityFeedbackTarget(
          userId: creatorId,
          label: creatorLabel,
          emoji: _categoryEmoji(category),
        ),
      ],
      myStatus: null,
      isMine: isMine,
    );
  }

  List<Activity> _seedActivities() {
    final now = DateTime.now();
    return [
      Activity(
        id: 'seed_1',
        creatorId: 'seed_creator_mina',
        creatorLabel: 'Mina',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: '☕ Café & Talk',
        description:
            'Un rato suave para charlar sin presión y compartir una taza.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        status: ActivityStatus.open,
        realLat: 37.5563,
        realLng: 126.9228,
        displayLat: 37.5569,
        displayLng: 126.9234,
        locationPrivacyRadiusM: 180,
        exactLocationUnlockAt: now.add(const Duration(minutes: 42)),
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 3)),
        maxPeople: 6,
        confirmedCount: 3,
        pendingCount: 1,
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_mina',
            label: 'Mina',
            emoji: '☕',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_soojin',
            label: 'Soojin',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_hana',
            label: 'Hana',
            emoji: '🌙',
          ),
        ],
        myStatus: null,
        isMine: false,
        lastMessagePreview: 'Soojin: ¿Ya llegaron?',
      ),
      Activity(
        id: 'seed_2',
        creatorId: 'seed_creator_jisoo',
        creatorLabel: 'Jisoo',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: '📚 Study Together',
        description: 'Mesa tranquila, música suave y enfoque bonito.',
        category: 'Study',
        vibe: 'Productive',
        zone: 'Gangnam',
        status: ActivityStatus.open,
        realLat: 37.4981,
        realLng: 127.0276,
        displayLat: 37.4975,
        displayLng: 127.0282,
        locationPrivacyRadiusM: 150,
        exactLocationUnlockAt: now.add(const Duration(minutes: 20)),
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(const Duration(hours: 2)),
        maxPeople: 4,
        confirmedCount: 2,
        pendingCount: 0,
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_jisoo',
            label: 'Jisoo',
            emoji: '📚',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_jiyoon',
            label: 'Jiyoon',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_mina',
            label: 'Mina',
            emoji: '🌸',
          ),
        ],
        myStatus: null,
        isMine: false,
        lastMessagePreview: 'Jiyoon: Yo llevo apuntes.',
      ),
      Activity(
        id: 'seed_3',
        creatorId: 'seed_creator_aria',
        creatorLabel: 'Aria',
        activityType: ActivityType.publicEvent,
        visibility: ActivityVisibility.publicActivity,
        title: '🌙 Night Walk',
        description: 'Caminata suave junto al río con vibra calm y segura.',
        category: 'Walks',
        vibe: 'Calm',
        zone: 'Yeouido',
        status: ActivityStatus.ongoing,
        realLat: 37.5219,
        realLng: 126.9141,
        displayLat: 37.5225,
        displayLng: 126.9147,
        locationPrivacyRadiusM: 220,
        exactLocationUnlockAt: now.subtract(const Duration(minutes: 5)),
        startTime: now.subtract(const Duration(minutes: 15)),
        endTime: now.add(const Duration(hours: 1)),
        maxPeople: 12,
        confirmedCount: 8,
        pendingCount: 2,
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_aria',
            label: 'Aria',
            emoji: '🌙',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_juno',
            label: 'Juno',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_minsu',
            label: 'Minsu',
            emoji: '🙂',
          ),
        ],
        myStatus: ParticipantStatus.confirmed,
        isMine: false,
        lastMessagePreview: 'Aria: Nos vemos en la entrada.',
      ),
      Activity(
        id: 'seed_4',
        creatorId: 'seed_creator_nari',
        creatorLabel: 'Nari',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: '🎨 Tiny Art Club',
        description: 'Dibujo, stickers y charla suave cerca del centro.',
        category: 'Art',
        vibe: 'Creative',
        zone: 'Insadong',
        status: ActivityStatus.finished,
        realLat: 37.5744,
        realLng: 126.9838,
        displayLat: 37.5749,
        displayLng: 126.9832,
        locationPrivacyRadiusM: 130,
        exactLocationUnlockAt: now.add(const Duration(minutes: 58)),
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 4)),
        maxPeople: 5,
        confirmedCount: 1,
        pendingCount: 0,
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_nari',
            label: 'Nari',
            emoji: '🎨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_dami',
            label: 'Dami',
            emoji: '🙂',
          ),
        ],
        myStatus: ParticipantStatus.attended,
        isMine: false,
      ),
      Activity(
        id: 'seed_5',
        creatorId: 'seed_creator_sora',
        creatorLabel: 'Sora',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: '🍜 Late Food Run',
        description: 'Buscar algo rico y caminar un poco después.',
        category: 'Food',
        vibe: 'Social',
        zone: 'Myeongdong',
        status: ActivityStatus.full,
        realLat: 37.5636,
        realLng: 126.9826,
        displayLat: 37.5639,
        displayLng: 126.9821,
        locationPrivacyRadiusM: 160,
        exactLocationUnlockAt: now.add(const Duration(minutes: 8)),
        startTime: now.add(const Duration(minutes: 18)),
        endTime: now.add(const Duration(hours: 2)),
        maxPeople: 4,
        confirmedCount: 4,
        pendingCount: 1,
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_sora',
            label: 'Sora',
            emoji: '🍜',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_yuna',
            label: 'Yuna',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_jiho',
            label: 'Jiho',
            emoji: '🌙',
          ),
        ],
        myStatus: null,
        isMine: false,
      ),
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
        exactLocationUnlockAt: now.subtract(const Duration(hours: 3)),
        startTime: now.subtract(const Duration(hours: 4)),
        endTime: now.subtract(const Duration(hours: 2)),
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
    ];
  }

  Future<int> loadDemoActivities() async {
    final existingIds = state.activities.map((activity) => activity.id).toSet();
    final demoActivities = _seedActivities()
        .where((activity) => !existingIds.contains(activity.id))
        .toList(growable: false);

    if (demoActivities.isEmpty) {
      return 0;
    }

    final nextActivities = [...state.activities, ...demoActivities]
      ..sort((left, right) => left.startTime.compareTo(right.startTime));

    state = state.copyWith(activities: nextActivities);
    await _persistSnapshot();
    return demoActivities.length;
  }

  String _feedbackPlaceholderEmoji(int index) {
    const emojis = ['🌸', '✨', '🙂', '🫧', '🌙', '💫'];
    return emojis[index % emojis.length];
  }

  Activity _sanitizeActivityForDisplay(Activity activity) {
    final sanitizedTargets = activity.feedbackTargets
        .map(
          (target) => ActivityFeedbackTarget(
            userId: target.userId,
            label: safeDisplayText(target.label, fallback: 'Persona'),
            emoji: safeDisplayText(target.emoji, fallback: '🌙'),
          ),
        )
        .toList(growable: false);

    final sanitized = activity.copyWith(
      creatorLabel: safeDisplayText(activity.creatorLabel, fallback: 'Luna'),
      title: safeDisplayText(activity.title, fallback: 'Actividad'),
      description: safeDisplayText(
        activity.description,
        fallback: 'Un momento bonito para compartir.',
      ),
      category: _sanitizeCategory(activity.category),
      vibe: safeDisplayText(activity.vibe, fallback: 'Calm'),
      zone: safeDisplayText(activity.zone, fallback: 'Seoul'),
      lastMessagePreview: safeDisplayText(
        activity.lastMessagePreview,
        fallback: '',
      ),
      feedbackTargets: sanitizedTargets,
    );

    if (sanitized.id == 'seed_1') {
      return sanitized.copyWith(
        title: '☕ Café & Talk',
        description:
            'Un rato suave para charlar sin presión y compartir una taza.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_mina',
            label: 'Mina',
            emoji: '☕',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_soojin',
            label: 'Soojin',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_hana',
            label: 'Hana',
            emoji: '🌙',
          ),
        ],
        lastMessagePreview: 'Soojin: ¿Ya llegaron?',
      );
    }
    if (sanitized.id == 'seed_2') {
      return sanitized.copyWith(
        title: '📚 Study Together',
        description: 'Mesa tranquila, música suave y enfoque bonito.',
        category: 'Study',
        vibe: 'Productive',
        zone: 'Gangnam',
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_jisoo',
            label: 'Jisoo',
            emoji: '📚',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_jiyoon',
            label: 'Jiyoon',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_mina',
            label: 'Mina',
            emoji: '🌸',
          ),
        ],
        lastMessagePreview: 'Jiyoon: Yo llevo apuntes.',
      );
    }
    if (sanitized.id == 'seed_3') {
      return sanitized.copyWith(
        title: '🌙 Night Walk',
        description: 'Caminata suave junto al río con vibra calm y segura.',
        category: 'Walks',
        vibe: 'Calm',
        zone: 'Yeouido',
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_aria',
            label: 'Aria',
            emoji: '🌙',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_juno',
            label: 'Juno',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_minsu',
            label: 'Minsu',
            emoji: '🙂',
          ),
        ],
        lastMessagePreview: 'Aria: Nos vemos en la entrada.',
      );
    }
    if (sanitized.id == 'seed_4') {
      return sanitized.copyWith(
        title: '🎨 Tiny Art Club',
        description: 'Dibujo, stickers y charla suave cerca del centro.',
        category: 'Art',
        vibe: 'Creative',
        zone: 'Insadong',
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_nari',
            label: 'Nari',
            emoji: '🎨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_dami',
            label: 'Dami',
            emoji: '🙂',
          ),
        ],
      );
    }
    if (sanitized.id == 'seed_5') {
      return sanitized.copyWith(
        title: '🍜 Late Food Run',
        description: 'Buscar algo rico y caminar un poco después.',
        category: 'Food',
        vibe: 'Social',
        zone: 'Myeongdong',
        feedbackTargets: [
          const ActivityFeedbackTarget(
            userId: 'seed_creator_sora',
            label: 'Sora',
            emoji: '🍜',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_yuna',
            label: 'Yuna',
            emoji: '✨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_jiho',
            label: 'Jiho',
            emoji: '🌙',
          ),
        ],
      );
    }
    if (sanitized.id == 'seed_6') {
      return sanitized.copyWith(
        title: '🌸 Archive Walk',
        description: 'Paseo que ya pasó y ahora vive en el historial.',
        category: 'Walks',
        vibe: 'Calm',
        zone: 'Seoul',
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
        lastMessagePreview: 'Yura: Gracias por venir 💫',
      );
    }

    return sanitized;
  }

  String _sanitizeCategory(String category) {
    return switch (category) {
      'Coffee' => 'Coffee',
      'Study' => 'Study',
      'Walks' => 'Walks',
      'Food' => 'Food',
      'Art' => 'Art',
      'Music' => 'Music',
      _ => 'Walks',
    };
  }

  List<Activity> _updateActivity(
    String activityId,
    Activity Function(Activity activity) update,
  ) {
    return state.activities
        .map((activity) {
          if (activity.id != activityId) {
            return activity;
          }
          return update(activity);
        })
        .toList(growable: false);
  }

  void _setChatMessages(
    String activityId,
    List<ChatMessage> messages, {
    String? chatId,
    String source = 'mock',
  }) {
    final resolvedChatId = chatId ?? _resolveChatId(activityId);
    _messagesByActivityId[resolvedChatId] = messages;

    final next = Map<String, List<ChatMessage>>.from(state.chatMessages);
    next[activityId] = messages;

    final preview = messages.isNotEmpty ? messages.last.content : '';
    final lastAt = messages.isNotEmpty ? messages.last.createdAt : null;

    AppLogger.log(
      'CHAT',
      'preview source=$source chatId=$resolvedChatId lastMessage=$preview',
    );

    final activities = state.activities
        .map((activity) {
          if (activity.id != activityId) {
            return activity;
          }
          return activity.copyWith(
            lastMessagePreview: preview,
            lastMessageAt: lastAt,
            unreadMessageCount: 0,
          );
        })
        .toList(growable: false);

    state = state.copyWith(chatMessages: next, activities: activities);
  }

  String _resolveChatId(String activityId) {
    return _chatIdsByActivityId.putIfAbsent(activityId, () => activityId);
  }

  void _joinResetFromStoredSession(String clientUid) {
    _clientUid = clientUid;
    _joinedActivityIds.clear();
    _confirmedAttendanceActivityIds.clear();
  }

  Future<void> _persistSnapshot() async {
    if (_clientUid == null || _clientUid!.isEmpty) {
      return;
    }

    await _mockStore.save(
      LocalMockSnapshot(
        user: state.user,
        activities: state.activities,
        messagesByActivityId: Map<String, List<ChatMessage>>.from(
          _messagesByActivityId,
        ),
        savedActivityIds: _savedActivityIds.toList(growable: false),
        blockedUsers: List<BlockedUserEntry>.unmodifiable(_blockedUsers),
        dismissedBlockedChatWarningActivityIds:
            _dismissedBlockedChatWarningActivityIds.toList(growable: false),
        activityFilters: state.activityFilters.toJson(),
        searchQuery: state.activitySearchQuery,
        settings: state.settings.toJson(),
        reports: state.reports,
        feedbackEntries: state.feedbackEntries,
      ),
    );
  }

  void _hydrateFromSnapshot(
    LocalMockSnapshot snapshot,
    Map<String, List<ChatMessage>> restoredMessages, {
    required bool allowSeedData,
    required String phoneMasked,
  }) {
    _messagesByActivityId
      ..clear()
      ..addAll(restoredMessages);

    _chatIdsByActivityId
      ..clear()
      ..addEntries(
        snapshot.activities.map(
          (activity) => MapEntry(activity.id, activity.id),
        ),
      );

    final user =
        snapshot.user ??
        _buildDemoUser(_clientUid ?? 'user_demo', phoneMasked: phoneMasked);

    final hydratedActivities = snapshot.activities
        .map((activity) {
          final normalized = _sanitizeActivityForDisplay(activity);
          if (normalized.creatorId.isNotEmpty) {
            return normalized;
          }

          if (normalized.isMine) {
            return normalized.copyWith(creatorId: user.id);
          }

          return normalized.copyWith(creatorId: 'legacy_seed_${normalized.id}');
        })
        .toList(growable: false);

    final hydratedSavedActivityIds = snapshot.savedActivityIds
        .where(
          (activityId) => hydratedActivities.any(
            (activity) =>
                activity.id == activityId && activity.isActiveLifecycle,
          ),
        )
        .toSet();

    final hydratedSettings = snapshot.settings.isEmpty
        ? AppSettings.initial()
        : AppSettings.fromJson(snapshot.settings);
    final hydratedFilters = snapshot.activityFilters.isEmpty
        ? ActivityDiscoveryFilters.initial()
        : ActivityDiscoveryFilters.fromJson(snapshot.activityFilters);
    final hydratedSearchQuery = snapshot.searchQuery;

    _savedActivityIds
      ..clear()
      ..addAll(hydratedSavedActivityIds);

    _blockedUsers
      ..clear()
      ..addAll(
        snapshot.blockedUsers
            .where((entry) => entry.userId.isNotEmpty)
            .toList(growable: false),
      );

    _dismissedBlockedChatWarningActivityIds
      ..clear()
      ..addAll(
        snapshot.dismissedBlockedChatWarningActivityIds
            .where((activityId) => activityId.isNotEmpty)
            .toList(growable: false),
      );

    state = state.copyWith(
      stage: _stageForUser(user),
      user: user,
      activities: snapshot.activities.isEmpty && allowSeedData
          ? _seedActivities()
          : hydratedActivities,
      chatMessages: restoredMessages,
      savedActivityIds: hydratedSavedActivityIds,
      settings: hydratedSettings,
      activityFilters: hydratedFilters,
      activitySearchQuery: hydratedSearchQuery,
      reports: snapshot.reports,
      feedbackEntries: snapshot.feedbackEntries,
      blockedUsers: List<BlockedUserEntry>.unmodifiable(_blockedUsers),
      dismissedBlockedChatWarningActivityIds:
          Set<String>.unmodifiable(
            _dismissedBlockedChatWarningActivityIds,
          ),
      errorMessage: null,
    );
  }

  Map<String, List<ChatMessage>> _restoreMessagesMap(
    Map<String, List<ChatMessage>> raw,
  ) {
    return raw.map(
      (key, value) => MapEntry(
        key,
        value
            .map(
              (message) => message.copyWith(
                chatId: message.chatId.isEmpty ? key : message.chatId,
                activityId: message.activityId.isEmpty
                    ? key
                    : message.activityId,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Future<String> _ensureClientUid() async {
    if (_clientUid != null && _clientUid!.isNotEmpty) {
      return _clientUid!;
    }

    _clientUid = await _sessionStore.getOrCreateClientUid();
    return _clientUid!;
  }

  Future<bool> _shouldUseSeedData() async {
    final seedDisabled = await _sessionStore.peekMockSeedDisabledAfterWipe();
    if (seedDisabled) {
      AppLogger.log('SEED', 'skipped after wipe');
      return false;
    }

    return true;
  }

  AppStage _stageForUser(AppUser user) {
    return user.profileComplete ? AppStage.ready : AppStage.onboarding;
  }

  bool _hasActiveCreatedActivity(String userId) {
    return state.activities.any((activity) {
      return activity.creatorId == userId && activity.isActiveLifecycle;
    });
  }

  ActivityStatus _nextLifecycleStatus(
    Activity activity, {
    required int confirmedCount,
  }) {
    if (activity.status == ActivityStatus.ongoing) {
      return ActivityStatus.ongoing;
    }

    if (confirmedCount >= activity.maxPeople) {
      return ActivityStatus.full;
    }

    return ActivityStatus.open;
  }

  bool _activityChanged(String activityId, List<Activity> updated) {
    final before = state.activities.firstWhere(
      (activity) => activity.id == activityId,
      orElse: () => updated.firstWhere(
        (activity) => activity.id == activityId,
        orElse: () => Activity(
          id: '',
          creatorId: '',
          creatorLabel: '',
          activityType: ActivityType.userActivity,
          title: '',
          description: '',
          category: '',
          vibe: '',
          zone: '',
          status: ActivityStatus.open,
          realLat: 0,
          realLng: 0,
          displayLat: 0,
          displayLng: 0,
          locationPrivacyRadiusM: 0,
          exactLocationUnlockAt: DateTime.now(),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          maxPeople: 0,
          confirmedCount: 0,
          pendingCount: 0,
          myStatus: null,
          isMine: false,
        ),
      ),
    );
    final after = updated.firstWhere((activity) => activity.id == activityId);
    return before.status != after.status ||
        before.title != after.title ||
        before.description != after.description ||
        before.category != after.category ||
        before.vibe != after.vibe ||
        before.zone != after.zone ||
        before.realLat != after.realLat ||
        before.realLng != after.realLng ||
        before.startTime != after.startTime ||
        before.endTime != after.endTime ||
        before.maxPeople != after.maxPeople ||
        before.visibility != after.visibility;
  }

  ActivityFeedbackTarget _currentUserFeedbackTarget(AppUser? user) {
    return ActivityFeedbackTarget(
      userId: user?.id ?? '',
      label: safeDisplayText(user?.nickname ?? '', fallback: 'Luna'),
      emoji: safeDisplayText(user?.avatarEmoji ?? '', fallback: '🌙'),
    );
  }

  List<ActivityFeedbackTarget> _upsertFeedbackTarget(
    List<ActivityFeedbackTarget> existingTargets, {
    required ActivityFeedbackTarget target,
  }) {
    if (target.userId.isEmpty) {
      return existingTargets;
    }

    final nextTargets = <ActivityFeedbackTarget>[
      for (final item in existingTargets)
        if (item.userId != target.userId) item,
      target,
    ];
    return nextTargets;
  }
}
