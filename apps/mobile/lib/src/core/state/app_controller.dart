import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../config/app_environment.dart';
import '../data/local_mock_store.dart';
import '../data/local_session_store.dart';
import '../models/activity.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/moderation_report.dart';
import '../models/private_feedback.dart';
import '../utils/app_logger.dart';

enum AppStage { booting, phoneAuth, otpEntry, onboarding, ready }

class AppState {
  const AppState({
    required this.stage,
    required this.demoMode,
    required this.activities,
    required this.chatMessages,
    required this.savedActivityIds,
    required this.settings,
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
      settings: AppSettings.initial(),
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
  final AppSettings settings;
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
    AppSettings? settings,
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
      settings: settings ?? this.settings,
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
      demoMode: demoModeOverride ?? true,
    );
    _sessionStore = sessionStore ?? LocalSessionStore();
    _mockStore = mockStore ?? LocalMockStore();
    if (autoInitialize) {
      unawaited(initialize());
    }
  }

  static const _demoCode = '000000';

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

  AppState get state => _state;

  set state(AppState value) {
    _state = value;
    notifyListeners();
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
            ? 'SesiÃ³n local'
            : _maskPhone(restoredPhone),
      );
      AppLogger.log('AUTH', 'session_restored=true');
      return;
    }

    _joinResetFromStoredSession(localSession);

    final user = _buildDemoUser(
      localSession,
      phoneMasked: restoredPhone == null
          ? 'SesiÃ³n local'
          : _maskPhone(restoredPhone),
    );

    AppLogger.log('AUTH', 'session_restored=true');
    state = state.copyWith(
      stage: AppStage.ready,
      user: user,
      activities: allowSeedData ? _seedActivities() : const [],
      chatMessages: const {},
      savedActivityIds: const {},
      settings: AppSettings.initial(),
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
        errorMessage: 'Escribe un nÃºmero de telÃ©fono vÃ¡lido.',
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
      phoneMasked: _maskPhone(state.phoneInput),
    );

    await _activateAuthenticatedState(
      user: user,
      phoneMasked: _maskPhone(state.phoneInput),
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

    state = state.copyWith(
      user: currentUser.copyWith(
        nickname: nickname,
        avatarEmoji: avatarEmoji,
        languages: languages,
        vibes: vibes,
        interests: interests,
        bio: bio,
        profileComplete: true,
      ),
      stage: AppStage.ready,
      errorMessage: null,
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
    state = AppState.initial().copyWith(
      stage: AppStage.phoneAuth,
      demoMode: true,
      activities: const [],
      chatMessages: const {},
      savedActivityIds: const {},
      settings: AppSettings.initial(),
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
      stage: AppStage.ready,
      activities: allowSeedData ? _seedActivities() : const [],
      chatMessages: const {},
      savedActivityIds: const {},
      settings: AppSettings.initial(),
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
        errorMessage: 'Inicia sesiÃ³n para crear una actividad.',
      );
      return;
    }

    final created = _buildActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      creatorId: currentUser.id,
      creatorLabel: state.user?.nickname.isNotEmpty == true
          ? state.user!.nickname
          : 'TÃº',
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
    ).copyWith(
      confirmedCount: 1,
      myStatus: ParticipantStatus.confirmed,
    );

    state = state.copyWith(
      activities: [
        created,
        ...state.activities.where((activity) => activity.id != created.id),
      ],
      user: state.user?.copyWith(
        createdActivityCount: (state.user?.createdActivityCount ?? 0) + 1,
        attendingActivityCount:
            (state.user?.attendingActivityCount ?? 0) + 1,
      ),
    );

    _joinedActivityIds.add(created.id);
    _confirmedAttendanceActivityIds.add(created.id);

    AppLogger.log('ACTIVITY', 'created id=${created.id}');
    unawaited(_persistSnapshot());
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
    final updated = _updateActivity(activityId, (activity) {
      if (activity.isFinishedOrArchived ||
          activity.myStatus != ParticipantStatus.joinedPendingConfirmation) {
        return activity;
      }

      final nextConfirmedCount = activity.confirmedCount + 1;
      _confirmedAttendanceActivityIds.add(activityId);
      return activity.copyWith(
        pendingCount: activity.pendingCount > 0 ? activity.pendingCount - 1 : 0,
        confirmedCount: nextConfirmedCount,
        myStatus: ParticipantStatus.confirmed,
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
    var shouldDecreaseAttendance = false;
    final updated = _updateActivity(activityId, (activity) {
      if (activity.isFinishedOrArchived) {
        return activity;
      }

      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation) {
        _confirmedAttendanceActivityIds.remove(activityId);
        final nextPendingCount = activity.pendingCount > 0
            ? activity.pendingCount - 1
            : 0;
        return activity.copyWith(
          pendingCount: nextPendingCount,
          myStatus: ParticipantStatus.cancelled,
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
        return activity.copyWith(
          confirmedCount: nextConfirmedCount,
          myStatus: ParticipantStatus.cancelled,
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
    final updated = _updateActivity(activityId, (activity) {
      if (activity.isFinishedOrArchived) {
        return activity;
      }

      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation) {
        _joinedActivityIds.remove(activityId);
        final nextPendingCount = activity.pendingCount > 0
            ? activity.pendingCount - 1
            : 0;
        return activity.copyWith(
          pendingCount: nextPendingCount,
          myStatus: ParticipantStatus.left,
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
        return activity.copyWith(
          confirmedCount: nextConfirmedCount,
          myStatus: ParticipantStatus.left,
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
      senderName: user.nickname.isNotEmpty ? user.nickname : 'TÃº',
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

    state = state.copyWith(
      activities: updated,
    );
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
      return 'Inicia sesiÃ³n para crear una actividad.';
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

    state = state.copyWith(savedActivityIds: Set<String>.from(_savedActivityIds));
    unawaited(_persistSnapshot());
    return true;
  }

  List<Activity> savedActivities() {
    final savedIds = _savedActivityIds;
    return state.activities
        .where(
          (activity) => savedIds.contains(activity.id) && activity.isActiveLifecycle,
        )
        .toList(growable: false)
      ..sort((left, right) => left.startTime.compareTo(right.startTime));
  }

  List<Activity> filteredActivities() {
    final visibleActivities = state.activities
        .where((activity) => activity.isActiveLifecycle)
        .toList(growable: false);

    if (state.filter == ActivityFilter.all) {
      return visibleActivities;
    }

    return visibleActivities
        .where((activity) {
          final query = state.filter;
          return switch (query) {
            ActivityFilter.coffee => activity.category == 'Coffee',
            ActivityFilter.study => activity.category == 'Study',
            ActivityFilter.walks => activity.category == 'Walks',
            ActivityFilter.food => activity.category == 'Food',
            ActivityFilter.art => activity.category == 'Art',
            ActivityFilter.music => activity.category == 'Music',
            ActivityFilter.calm => activity.vibe == 'Calm',
            ActivityFilter.social => activity.vibe == 'Social',
            ActivityFilter.all => true,
          };
        })
        .toList(growable: false);
  }

  Future<String?> ensureChatId(String activityId) async {
    return _resolveChatId(activityId);
  }

  List<Activity> activeActivitiesForUser(String userId) {
    return state.activities
        .where(
          (activity) =>
              !activity.isFinishedOrArchived &&
              activity.status != ActivityStatus.removed &&
              activity.status != ActivityStatus.rejectedHidden &&
              (activity.creatorId == userId ||
                  activity.myStatus == ParticipantStatus.joinedPendingConfirmation ||
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
                  activity.myStatus == ParticipantStatus.joinedPendingConfirmation ||
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
      'Coffee' => 'â˜•',
      'Study' => 'ðŸ“š',
      'Walks' => 'ðŸŒ™',
      'Food' => 'ðŸœ',
      'Art' => 'ðŸŽ¨',
      'Music' => 'ðŸŽµ',
      _ => 'ðŸŒ™',
    };
  }

  AppUser _buildDemoUser(String id, {required String phoneMasked}) {
    return AppUser(
      id: id,
      phoneMasked: phoneMasked,
      nickname: 'Luna',
      avatarEmoji: 'ðŸŒ™',
      bio: 'PequeÃ±os momentos, juntos.',
      languages: const ['Korean', 'English'],
      vibes: const ['Calm', 'Creative'],
      interests: const ['Coffee', 'Walks', 'Study'],
      status: UserStatus.trusted,
      profileComplete: true,
      createdActivityCount: 0,
      attendingActivityCount: 0,
    );
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
        title: 'â˜• CafÃ© & Talk',
        description:
            'Un rato suave para charlar sin presiÃ³n y compartir una taza.',
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
            emoji: 'â˜•',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_soojin',
            label: 'Soojin',
            emoji: 'âœ¨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_hana',
            label: 'Hana',
            emoji: 'ðŸŒ™',
          ),
        ],
        myStatus: null,
        isMine: false,
        lastMessagePreview: 'Soojin: Â¿Ya llegaron?',
      ),
      Activity(
        id: 'seed_2',
        creatorId: 'seed_creator_jisoo',
        creatorLabel: 'Jisoo',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: 'ðŸ“š Study Together',
        description: 'Mesa tranquila, mÃºsica suave y enfoque bonito.',
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
            emoji: 'ðŸ“š',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_jiyoon',
            label: 'Jiyoon',
            emoji: 'âœ¨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_mina',
            label: 'Mina',
            emoji: 'ðŸŒ¸',
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
        title: 'ðŸŒ™ Night Walk',
        description: 'Caminata suave junto al rÃ­o con vibra calm y segura.',
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
            emoji: 'ðŸŒ™',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_juno',
            label: 'Juno',
            emoji: 'âœ¨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_minsu',
            label: 'Minsu',
            emoji: 'ðŸ™‚',
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
        title: 'ðŸŽ¨ Tiny Art Club',
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
            emoji: 'ðŸŽ¨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_dami',
            label: 'Dami',
            emoji: 'ðŸ™‚',
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
        title: 'ðŸœ Late Food Run',
        description: 'Buscar algo rico y caminar un poco despuÃ©s.',
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
            emoji: 'ðŸœ',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_yuna',
            label: 'Yuna',
            emoji: 'âœ¨',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_jiho',
            label: 'Jiho',
            emoji: 'ðŸŒ™',
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
        title: 'ðŸŒ¸ Archive Walk',
        description: 'Paseo que ya pasÃ³ y ahora vive en el historial.',
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
            emoji: 'ðŸŒ¸',
          ),
          const ActivityFeedbackTarget(
            userId: 'seed_participant_ren',
            label: 'Ren',
            emoji: 'âœ¨',
          ),
        ],
        myStatus: ParticipantStatus.attended,
        isMine: false,
        lastMessagePreview: 'Yura: Gracias por venir ðŸ’«',
      ),
    ];
  }

  String _feedbackPlaceholderEmoji(int index) {
    const emojis = ['ðŸŒ¸', 'âœ¨', 'ðŸ™‚', 'ðŸ«§', 'ðŸŒ™', 'ðŸ’«'];
    return emojis[index % emojis.length];
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
          if (activity.creatorId.isNotEmpty) {
            return activity;
          }

          if (activity.isMine) {
            return activity.copyWith(creatorId: user.id);
          }

          return activity.copyWith(creatorId: 'legacy_seed_${activity.id}');
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

    _savedActivityIds
      ..clear()
      ..addAll(hydratedSavedActivityIds);

    state = state.copyWith(
      stage: AppStage.ready,
      user: user,
      activities: snapshot.activities.isEmpty && allowSeedData
          ? _seedActivities()
          : hydratedActivities,
      chatMessages: restoredMessages,
      savedActivityIds: hydratedSavedActivityIds,
      settings: hydratedSettings,
      reports: snapshot.reports,
      feedbackEntries: snapshot.feedbackEntries,
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

  static String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length <= 4) {
      return digits;
    }

    final last4 = digits.substring(digits.length - 4);
    return 'â€¢â€¢â€¢â€¢ $last4';
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
    return before.status != after.status;
  }
}

