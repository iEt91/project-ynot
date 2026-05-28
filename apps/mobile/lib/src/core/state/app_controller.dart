import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../config/app_environment.dart';
import '../models/activity.dart';
import '../models/app_user.dart';

enum AppStage { booting, phoneAuth, otpEntry, onboarding, ready }

class AppState {
  const AppState({
    required this.stage,
    required this.demoMode,
    required this.activities,
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
    );
  }

  final AppStage stage;
  final bool demoMode;
  final AppUser? user;
  final List<Activity> activities;
  final String phoneInput;
  final String verificationInput;
  final ActivityFilter filter;
  final String? errorMessage;

  AppState copyWith({
    AppStage? stage,
    bool? demoMode,
    AppUser? user,
    List<Activity>? activities,
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
      phoneInput: phoneInput ?? this.phoneInput,
      verificationInput: verificationInput ?? this.verificationInput,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }
}

final appControllerProvider =
    ChangeNotifierProvider<AppController>((ref) => AppController());

final appStateProvider = Provider<AppState>(
  (ref) => ref.watch(appControllerProvider).state,
);

class AppController extends ChangeNotifier {
  AppController() {
    _state = AppState.initial().copyWith(
      stage: AppStage.phoneAuth,
      activities: _seedActivities(),
    );
  }

  final _random = Random();
  late AppState _state;

  AppState get state => _state;
  set state(AppState value) {
    _state = value;
    notifyListeners();
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
      errorMessage: state.demoMode
          ? 'Modo demo activo. Usa cualquier código de 6 dígitos.'
          : 'Código enviado por Firebase Phone Auth.',
    );
  }

  Future<void> verifyCode() async {
    final code = state.verificationInput.trim();
    if (code.length < 4) {
      state = state.copyWith(errorMessage: 'Escribe el código recibido.');
      return;
    }

    final user = AppUser(
      id: 'user_demo_001',
      phoneMasked: _maskPhone(state.phoneInput),
      nickname: '',
      avatarEmoji: '🌙',
      languages: const [],
      vibes: const [],
      interests: const [],
      status: UserStatus.newUser,
      profileComplete: false,
    );

    state = state.copyWith(
      user: user,
      stage: AppStage.onboarding,
      errorMessage: null,
    );
  }

  void completeOnboarding({
    required String nickname,
    required String avatarEmoji,
    required List<String> languages,
    required List<String> vibes,
    required List<String> interests,
  }) {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(
      user: currentUser.copyWith(
        nickname: nickname,
        avatarEmoji: avatarEmoji,
        languages: languages,
        vibes: vibes,
        interests: interests,
        status: UserStatus.trusted,
        profileComplete: true,
      ),
      stage: AppStage.ready,
      errorMessage: null,
    );
  }

  void signOut() {
    state = AppState.initial().copyWith(
      stage: AppStage.phoneAuth,
      activities: state.activities,
    );
  }

  void setFilter(ActivityFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void createActivity({
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
  }) {
    final privacyRadius = 100 + _random.nextInt(201);
    final offset = _random.nextDouble() * privacyRadius;
    final signLat = _random.nextBool() ? 1 : -1;
    final signLng = _random.nextBool() ? 1 : -1;
    final displayLat = realLat + signLat * (offset / 111320.0);
    final displayLng = realLng + signLng * (offset / (111320.0 * cos(realLat * pi / 180.0)));
    final endTime = startTime.add(duration);

    final created = Activity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      creatorLabel: state.user?.nickname.isNotEmpty == true
          ? state.user!.nickname
          : 'You',
      activityType: ActivityType.userActivity,
      title: title,
      description: description,
      category: category,
      vibe: vibe,
      zone: zone,
      status: ActivityStatus.pendingModeration,
      realLat: realLat,
      realLng: realLng,
      displayLat: displayLat,
      displayLng: displayLng,
      locationPrivacyRadiusM: privacyRadius,
      exactLocationUnlockAt: startTime.subtract(const Duration(minutes: 10)),
      startTime: startTime,
      endTime: endTime,
      maxPeople: maxPeople,
      confirmedCount: 1,
      pendingCount: 0,
      myStatus: ParticipantStatus.confirmed,
      isMine: true,
    );

    state = state.copyWith(
      activities: [created, ...state.activities],
    );
  }

  void joinActivity(String activityId) {
    final updated = <Activity>[];
    for (final activity in state.activities) {
      if (activity.id != activityId) {
        updated.add(activity);
        continue;
      }

      if (!activity.isJoinable || activity.myStatus != null) {
        updated.add(activity);
        continue;
      }

      updated.add(
        activity.copyWith(
          pendingCount: activity.pendingCount + 1,
          myStatus: ParticipantStatus.joinedPendingConfirmation,
        ),
      );
    }

    state = state.copyWith(activities: updated);
  }

  void confirmAttendance(String activityId) {
    final updated = <Activity>[];
    for (final activity in state.activities) {
      if (activity.id != activityId) {
        updated.add(activity);
        continue;
      }

      if (activity.myStatus != ParticipantStatus.joinedPendingConfirmation) {
        updated.add(activity);
        continue;
      }

      final nextPending = activity.pendingCount > 0 ? activity.pendingCount - 1 : 0;
      final nextConfirmed = activity.confirmedCount < activity.maxPeople
          ? activity.confirmedCount + 1
          : activity.confirmedCount;

      updated.add(
        activity.copyWith(
          pendingCount: nextPending,
          confirmedCount: nextConfirmed,
          myStatus: ParticipantStatus.confirmed,
          status: nextConfirmed >= activity.maxPeople
              ? ActivityStatus.full
              : ActivityStatus.active,
        ),
      );
    }

    state = state.copyWith(activities: updated);
  }

  void leaveActivity(String activityId) {
    final updated = <Activity>[];
    for (final activity in state.activities) {
      if (activity.id != activityId) {
        updated.add(activity);
        continue;
      }

      if (activity.myStatus == ParticipantStatus.joinedPendingConfirmation) {
        updated.add(
          activity.copyWith(
            pendingCount: activity.pendingCount > 0 ? activity.pendingCount - 1 : 0,
            myStatus: ParticipantStatus.left,
          ),
        );
        continue;
      }

      if (activity.myStatus == ParticipantStatus.confirmed) {
        updated.add(
          activity.copyWith(
            confirmedCount: activity.confirmedCount > 0 ? activity.confirmedCount - 1 : 0,
            myStatus: ParticipantStatus.left,
            status: ActivityStatus.active,
          ),
        );
        continue;
      }

      updated.add(activity);
    }

    state = state.copyWith(activities: updated);
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

  static String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length <= 4) {
      return digits;
    }

    final last4 = digits.substring(digits.length - 4);
    return '•••• $last4';
  }

  List<Activity> _seedActivities() {
    final now = DateTime.now();
    return [
      Activity(
        id: 'seed_1',
        creatorLabel: 'Mina',
        activityType: ActivityType.userActivity,
        title: '☕ Café & Talk',
        description: 'Un rato tranquilo para conversar sin presión.',
        category: 'Coffee',
        vibe: 'Calm',
        zone: 'Hongdae area',
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
      ),
      Activity(
        id: 'seed_2',
        creatorLabel: 'Jisoo',
        activityType: ActivityType.userActivity,
        title: '📚 Study Session',
        description: 'Co-working silencioso en un study cafe.',
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
      ),
      Activity(
        id: 'seed_3',
        creatorLabel: 'Aria',
        activityType: ActivityType.publicEvent,
        title: '🌙 Night Walk',
        description: 'Caminar suave por el río con vibra calm.',
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
      ),
      Activity(
        id: 'seed_4',
        creatorLabel: 'Nari',
        activityType: ActivityType.userActivity,
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
}
