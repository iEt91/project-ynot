import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../config/app_environment.dart';
import '../data/local_session_store.dart';
import '../models/activity.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';

enum AppStage { booting, phoneAuth, otpEntry, onboarding, ready }

class AppState {
  const AppState({
    required this.stage,
    required this.demoMode,
    required this.activities,
    required this.chatMessages,
    required this.messageReports,
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
      messageReports: const [],
    );
  }

  final AppStage stage;
  final bool demoMode;
  final AppUser? user;
  final List<Activity> activities;
  final Map<String, List<ChatMessage>> chatMessages;
  final List<ChatMessageReport> messageReports;
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
    List<ChatMessageReport>? messageReports,
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
      messageReports: messageReports ?? this.messageReports,
      phoneInput: phoneInput ?? this.phoneInput,
      verificationInput: verificationInput ?? this.verificationInput,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }
}

class ChatMessageReport {
  const ChatMessageReport({
    required this.messageId,
    required this.chatId,
    required this.activityId,
    required this.senderId,
    required this.reporterId,
    required this.content,
    required this.timestamp,
  });

  final String messageId;
  final String chatId;
  final String activityId;
  final String senderId;
  final String reporterId;
  final String content;
  final DateTime timestamp;
}

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) => AppController());

final appStateProvider = Provider<AppState>(
  (ref) => ref.watch(appControllerProvider).state,
);

class AppController extends ChangeNotifier {
  AppController({
    Object? repository,
    LocalSessionStore? sessionStore,
    bool? demoModeOverride,
    bool autoInitialize = true,
  }) {
    _state = AppState.initial().copyWith(
      stage: AppStage.booting,
      demoMode: demoModeOverride ?? true,
    );
    _sessionStore = sessionStore ?? LocalSessionStore();
    if (autoInitialize) {
      unawaited(initialize());
    }
  }

  static const _demoCode = '000000';

  final _random = Random();
  late final LocalSessionStore _sessionStore;

  late AppState _state;
  String? _clientUid;

  final Map<String, List<ChatMessage>> _messagesByActivityId = {};
  final Map<String, String> _chatIdsByActivityId = {};
  final Set<String> _joinedActivityIds = {};
  final Set<String> _confirmedAttendanceActivityIds = {};

  AppState get state => _state;

  set state(AppState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> initialize() async {
    AppLogger.log('BOOT', 'mode=mock');
    final localSession = await _sessionStore.peekClientUid();
    final restoredPhone = await _sessionStore.peekPhone();

    if (localSession == null || localSession.isEmpty) {
      AppLogger.log('AUTH', 'session_restored=false');
      state = state.copyWith(
        stage: AppStage.phoneAuth,
        user: null,
        activities: const [],
        chatMessages: const {},
        messageReports: const [],
        errorMessage: null,
      );
      return;
    }

    _clientUid = localSession;
    _joinResetFromStoredSession(localSession);

    final user = _buildDemoUser(
      localSession,
      phoneMasked: restoredPhone == null ? 'Sesión local' : _maskPhone(restoredPhone),
    );

    AppLogger.log('AUTH', 'session_restored=true');
    state = state.copyWith(
      stage: AppStage.ready,
      user: user,
      activities: _seedActivities(),
      chatMessages: const {},
      messageReports: const [],
      errorMessage: null,
    );
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
      state = state.copyWith(errorMessage: 'Escribe un número de teléfono válido.');
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
    await _sessionStore.saveClientSession(clientUid: clientUid, phone: state.phoneInput.trim());

    final user = _buildDemoUser(
      clientUid,
      phoneMasked: _maskPhone(state.phoneInput),
    );

    _joinResetFromStoredSession(clientUid);
    state = state.copyWith(
      user: user,
      stage: AppStage.ready,
      activities: _seedActivities(),
      chatMessages: const {},
      messageReports: const [],
      errorMessage: null,
    );

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
  }

  void signOut() {
    AppLogger.log('AUTH', 'logout');
    unawaited(_sessionStore.clear());
    _clientUid = null;
    _messagesByActivityId.clear();
    _chatIdsByActivityId.clear();
    _joinedActivityIds.clear();
    _confirmedAttendanceActivityIds.clear();
    state = AppState.initial().copyWith(
      stage: AppStage.phoneAuth,
      demoMode: true,
      activities: const [],
      chatMessages: const {},
      messageReports: const [],
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
    final created = _buildActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      creatorLabel: state.user?.nickname.isNotEmpty == true ? state.user!.nickname : 'Tú',
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
    );

    state = state.copyWith(
      activities: [created, ...state.activities.where((activity) => activity.id != created.id)],
      user: state.user?.copyWith(createdActivityCount: (state.user?.createdActivityCount ?? 0) + 1),
    );

    AppLogger.log('ACTIVITY', 'created id=${created.id}');
  }

  Future<void> joinActivity(String activityId) async {
    final updated = _updateActivity(activityId, (activity) {
      final user = state.user;
      final isRestricted = user?.status == UserStatus.limited || user?.status == UserStatus.banned;
      if (isRestricted || activity.isFull) {
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
  }

  Future<void> confirmAttendance(String activityId) async {
    final updated = _updateActivity(activityId, (activity) {
      if (activity.myStatus != ParticipantStatus.joinedPendingConfirmation) {
        return activity;
      }

      _confirmedAttendanceActivityIds.add(activityId);
      return activity.copyWith(
        pendingCount: activity.pendingCount > 0 ? activity.pendingCount - 1 : 0,
        confirmedCount: activity.confirmedCount + 1,
        myStatus: ParticipantStatus.confirmed,
        status: (activity.confirmedCount + 1) >= activity.maxPeople ? ActivityStatus.full : ActivityStatus.active,
      );
    });

    state = state.copyWith(
      activities: updated,
      user: state.user?.copyWith(
        attendingActivityCount: (state.user?.attendingActivityCount ?? 0) + 1,
      ),
    );
  }

  Future<void> cancelAttendance(String activityId) async {
    var shouldDecreaseAttendance = false;
    final updated = _updateActivity(activityId, (activity) {
      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation) {
        _confirmedAttendanceActivityIds.remove(activityId);
        return activity.copyWith(
          pendingCount: activity.pendingCount > 0 ? activity.pendingCount - 1 : 0,
          myStatus: ParticipantStatus.cancelled,
          status: ActivityStatus.active,
        );
      }

      if (activity.myStatus == ParticipantStatus.confirmed) {
        _confirmedAttendanceActivityIds.remove(activityId);
        shouldDecreaseAttendance = true;
        return activity.copyWith(
          confirmedCount: activity.confirmedCount > 0 ? activity.confirmedCount - 1 : 0,
          myStatus: ParticipantStatus.cancelled,
          status: ActivityStatus.active,
        );
      }

      return activity;
    });

    state = state.copyWith(
      activities: updated,
      user: shouldDecreaseAttendance
          ? state.user?.copyWith(
              attendingActivityCount:
                  (state.user?.attendingActivityCount ?? 0) > 0 ? (state.user?.attendingActivityCount ?? 0) - 1 : 0,
            )
          : state.user,
    );
  }

  Future<void> leaveActivity(String activityId) async {
    final updated = _updateActivity(activityId, (activity) {
      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation) {
        _joinedActivityIds.remove(activityId);
        return activity.copyWith(
          pendingCount: activity.pendingCount > 0 ? activity.pendingCount - 1 : 0,
          myStatus: ParticipantStatus.left,
          status: ActivityStatus.active,
        );
      }

      if (activity.myStatus == ParticipantStatus.confirmed) {
        _joinedActivityIds.remove(activityId);
        _confirmedAttendanceActivityIds.remove(activityId);
        return activity.copyWith(
          confirmedCount: activity.confirmedCount > 0 ? activity.confirmedCount - 1 : 0,
          myStatus: ParticipantStatus.left,
          status: ActivityStatus.active,
        );
      }

      return activity;
    });

    state = state.copyWith(
      activities: updated,
      user: state.user?.copyWith(
        attendingActivityCount:
            (state.user?.attendingActivityCount ?? 0) > 0 ? (state.user?.attendingActivityCount ?? 0) - 1 : 0,
      ),
    );
  }

  Future<void> loadChatMessages(String activityId) async {
    AppLogger.log('CHAT', 'open activityId=$activityId');
    final chatId = _resolveChatId(activityId);
    final messages = List<ChatMessage>.from(_messagesByActivityId[chatId] ?? const []);
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

    final messages = List<ChatMessage>.from(_messagesByActivityId[chatId] ?? const []);
    messages.add(message);
    _messagesByActivityId[chatId] = messages;
    _setChatMessages(activityId, messages, chatId: chatId, source: 'mock');
    AppLogger.log('MESSAGE', 'sent activityId=$activityId');
  }

  Future<void> reportChatMessage({
    required String messageId,
    required String chatId,
    required String activityId,
    required String senderId,
    required String reporterId,
    required String content,
    required DateTime timestamp,
  }) async {
    final report = ChatMessageReport(
      messageId: messageId,
      chatId: chatId,
      activityId: activityId,
      senderId: senderId,
      reporterId: reporterId,
      content: content,
      timestamp: timestamp,
    );

    state = state.copyWith(
      messageReports: [report, ...state.messageReports],
    );
  }

  Future<void> refreshActivity(String activityId) async {
    // In-memory mock keeps the current activity list as source of truth.
  }

  List<Activity> filteredActivities() {
    if (state.filter == ActivityFilter.all) {
      return state.activities;
    }

    return state.activities.where((activity) {
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
    }).toList(growable: false);
  }

  Future<String?> ensureChatId(String activityId) async {
    return _resolveChatId(activityId);
  }

  AppUser _buildDemoUser(String id, {required String phoneMasked}) {
    return AppUser(
      id: id,
      phoneMasked: phoneMasked,
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
    );
  }

  Activity _buildActivity({
    required String id,
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
    final displayLng = realLng + signLng * (offset / (111320.0 * cos(realLat * pi / 180.0)));
    final endTime = startTime.add(duration);

    return Activity(
      id: id,
      creatorLabel: creatorLabel,
      activityType: ActivityType.userActivity,
      visibility: visibility,
      title: title,
      description: description,
      category: category,
      vibe: vibe,
      zone: zone,
      status: ActivityStatus.active,
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
      myStatus: null,
      isMine: isMine,
    );
  }

  List<Activity> _seedActivities() {
    final now = DateTime.now();
    return [
      Activity(
        id: 'seed_1',
        creatorLabel: 'Mina',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: '☕ Café & Talk',
        description: 'Un rato suave para charlar sin presión y compartir una taza.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae',
        status: ActivityStatus.active,
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
        myStatus: null,
        isMine: false,
        lastMessagePreview: 'Soojin: ¿Ya llegaron?',
      ),
      Activity(
        id: 'seed_2',
        creatorLabel: 'Jisoo',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: '📚 Study Together',
        description: 'Mesa tranquila, música suave y enfoque bonito.',
        category: 'Study',
        vibe: 'Productive',
        zone: 'Gangnam',
        status: ActivityStatus.active,
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
        myStatus: null,
        isMine: false,
        lastMessagePreview: 'Jiyoon: Yo llevo apuntes.',
      ),
      Activity(
        id: 'seed_3',
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
        myStatus: ParticipantStatus.confirmed,
        isMine: false,
        lastMessagePreview: 'Aria: Nos vemos en la entrada.',
      ),
      Activity(
        id: 'seed_4',
        creatorLabel: 'Nari',
        activityType: ActivityType.userActivity,
        visibility: ActivityVisibility.publicActivity,
        title: '🎨 Tiny Art Club',
        description: 'Dibujo, stickers y charla suave cerca del centro.',
        category: 'Art',
        vibe: 'Creative',
        zone: 'Insadong',
        status: ActivityStatus.active,
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
        myStatus: null,
        isMine: false,
      ),
      Activity(
        id: 'seed_5',
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
        myStatus: null,
        isMine: false,
      ),
    ];
  }

  List<Activity> _updateActivity(
    String activityId,
    Activity Function(Activity activity) update,
  ) {
    return state.activities.map((activity) {
      if (activity.id != activityId) {
        return activity;
      }
      return update(activity);
    }).toList(growable: false);
  }

  void _setChatMessages(String activityId, List<ChatMessage> messages, {String? chatId, String source = 'mock'}) {
    final resolvedChatId = chatId ?? _resolveChatId(activityId);
    _messagesByActivityId[resolvedChatId] = messages;

    final next = Map<String, List<ChatMessage>>.from(state.chatMessages);
    next[activityId] = messages;

    final preview = messages.isNotEmpty ? messages.last.content : '';
    final lastAt = messages.isNotEmpty ? messages.last.createdAt : null;

    AppLogger.log('CHAT', 'preview source=$source chatId=$resolvedChatId lastMessage=$preview');

    final activities = state.activities.map((activity) {
      if (activity.id != activityId) {
        return activity;
      }
      return activity.copyWith(
        lastMessagePreview: preview,
        lastMessageAt: lastAt,
        unreadMessageCount: 0,
      );
    }).toList(growable: false);

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

  Future<String> _ensureClientUid() async {
    if (_clientUid != null && _clientUid!.isNotEmpty) {
      return _clientUid!;
    }

    _clientUid = await _sessionStore.getOrCreateClientUid();
    return _clientUid!;
  }

  static String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length <= 4) {
      return digits;
    }

    final last4 = digits.substring(digits.length - 4);
    return '•••• $last4';
  }
}
