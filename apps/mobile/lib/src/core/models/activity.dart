enum ActivityStatus {
  draft,
  pendingModeration,
  active,
  full,
  ongoing,
  finished,
  cancelled,
  flagged,
  removed,
  rejectedHidden,
}

enum ActivityType { userActivity, publicEvent }

enum ParticipantStatus {
  joinedPendingConfirmation,
  confirmed,
  left,
  cancelled,
  attended,
  noShow,
  notSure,
  removedByAdmin,
}

enum ActivityFilter { all, coffee, study, walks, food, art, music, calm, social }

class Activity {
  const Activity({
    required this.id,
    required this.creatorLabel,
    required this.activityType,
    required this.title,
    required this.description,
    required this.category,
    required this.vibe,
    required this.zone,
    required this.status,
    required this.realLat,
    required this.realLng,
    required this.displayLat,
    required this.displayLng,
    required this.locationPrivacyRadiusM,
    required this.exactLocationUnlockAt,
    required this.startTime,
    required this.endTime,
    required this.maxPeople,
    required this.confirmedCount,
    required this.pendingCount,
    required this.myStatus,
    required this.isMine,
  });

  final String id;
  final String creatorLabel;
  final ActivityType activityType;
  final String title;
  final String description;
  final String category;
  final String vibe;
  final String zone;
  final ActivityStatus status;
  final double realLat;
  final double realLng;
  final double displayLat;
  final double displayLng;
  final int locationPrivacyRadiusM;
  final DateTime exactLocationUnlockAt;
  final DateTime startTime;
  final DateTime endTime;
  final int maxPeople;
  final int confirmedCount;
  final int pendingCount;
  final ParticipantStatus? myStatus;
  final bool isMine;

  bool get isJoinable => status == ActivityStatus.active && confirmedCount < maxPeople;
  bool get isFull => confirmedCount >= maxPeople;

  Activity copyWith({
    String? creatorLabel,
    ActivityType? activityType,
    String? title,
    String? description,
    String? category,
    String? vibe,
    String? zone,
    ActivityStatus? status,
    double? realLat,
    double? realLng,
    double? displayLat,
    double? displayLng,
    int? locationPrivacyRadiusM,
    DateTime? exactLocationUnlockAt,
    DateTime? startTime,
    DateTime? endTime,
    int? maxPeople,
    int? confirmedCount,
    int? pendingCount,
    ParticipantStatus? myStatus,
    bool? isMine,
  }) {
    return Activity(
      id: id,
      creatorLabel: creatorLabel ?? this.creatorLabel,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      vibe: vibe ?? this.vibe,
      zone: zone ?? this.zone,
      status: status ?? this.status,
      realLat: realLat ?? this.realLat,
      realLng: realLng ?? this.realLng,
      displayLat: displayLat ?? this.displayLat,
      displayLng: displayLng ?? this.displayLng,
      locationPrivacyRadiusM: locationPrivacyRadiusM ?? this.locationPrivacyRadiusM,
      exactLocationUnlockAt: exactLocationUnlockAt ?? this.exactLocationUnlockAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxPeople: maxPeople ?? this.maxPeople,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      myStatus: myStatus ?? this.myStatus,
      isMine: isMine ?? this.isMine,
    );
  }
}
