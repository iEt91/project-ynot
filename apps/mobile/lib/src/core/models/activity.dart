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

enum ActivityVisibility { publicActivity, privateActivity }

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

enum ActivityFilter {
  all,
  coffee,
  study,
  walks,
  food,
  art,
  music,
  calm,
  social,
}

class ActivityFeedbackTarget {
  const ActivityFeedbackTarget({
    required this.userId,
    required this.label,
    required this.emoji,
  });

  final String userId;
  final String label;
  final String emoji;

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'label': label, 'emoji': emoji};
  }

  factory ActivityFeedbackTarget.fromJson(Map<String, dynamic> json) {
    return ActivityFeedbackTarget(
      userId: json['userId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🌙',
    );
  }
}

class Activity {
  const Activity({
    required this.id,
    required this.creatorId,
    required this.creatorLabel,
    required this.activityType,
    this.visibility = ActivityVisibility.publicActivity,
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
    this.feedbackTargets = const [],
    required this.myStatus,
    required this.isMine,
    this.lastMessagePreview = '',
    this.lastMessageAt,
    this.unreadMessageCount = 0,
  });

  final String id;
  final String creatorId;
  final String creatorLabel;
  final ActivityType activityType;
  final ActivityVisibility visibility;
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
  final List<ActivityFeedbackTarget> feedbackTargets;
  final ParticipantStatus? myStatus;
  final bool isMine;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadMessageCount;

  bool get isJoinable =>
      status == ActivityStatus.active && confirmedCount < maxPeople;
  bool get isFull => confirmedCount >= maxPeople;
  String get emoji => switch (category) {
    'Coffee' => '☕',
    'Study' => '📚',
    'Walks' => '🌙',
    'Food' => '🍜',
    'Art' => '🎨',
    'Music' => '🎵',
    _ => '✨',
  };

  Activity copyWith({
    String? creatorId,
    String? creatorLabel,
    ActivityType? activityType,
    ActivityVisibility? visibility,
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
    List<ActivityFeedbackTarget>? feedbackTargets,
    ParticipantStatus? myStatus,
    bool? isMine,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadMessageCount,
  }) {
    return Activity(
      id: id,
      creatorId: creatorId ?? this.creatorId,
      creatorLabel: creatorLabel ?? this.creatorLabel,
      activityType: activityType ?? this.activityType,
      visibility: visibility ?? this.visibility,
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
      locationPrivacyRadiusM:
          locationPrivacyRadiusM ?? this.locationPrivacyRadiusM,
      exactLocationUnlockAt:
          exactLocationUnlockAt ?? this.exactLocationUnlockAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxPeople: maxPeople ?? this.maxPeople,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      feedbackTargets: feedbackTargets ?? this.feedbackTargets,
      myStatus: myStatus ?? this.myStatus,
      isMine: isMine ?? this.isMine,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'creatorLabel': creatorLabel,
      'activityType': activityType.name,
      'visibility': visibility.name,
      'title': title,
      'description': description,
      'category': category,
      'vibe': vibe,
      'zone': zone,
      'status': status.name,
      'realLat': realLat,
      'realLng': realLng,
      'displayLat': displayLat,
      'displayLng': displayLng,
      'locationPrivacyRadiusM': locationPrivacyRadiusM,
      'exactLocationUnlockAt': exactLocationUnlockAt.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'maxPeople': maxPeople,
      'confirmedCount': confirmedCount,
      'pendingCount': pendingCount,
      'feedbackTargets': feedbackTargets
          .map((target) => target.toJson())
          .toList(growable: false),
      'myStatus': myStatus?.name,
      'isMine': isMine,
      'lastMessagePreview': lastMessagePreview,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadMessageCount': unreadMessageCount,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String? ?? '',
      creatorId:
          json['creatorId'] as String? ?? json['creator_id'] as String? ?? '',
      creatorLabel: json['creatorLabel'] as String? ?? '',
      activityType: ActivityType.values.byName(
        json['activityType'] as String? ?? ActivityType.userActivity.name,
      ),
      visibility: ActivityVisibility.values.byName(
        json['visibility'] as String? ?? ActivityVisibility.publicActivity.name,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      vibe: json['vibe'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      status: ActivityStatus.values.byName(
        json['status'] as String? ?? ActivityStatus.active.name,
      ),
      realLat: (json['realLat'] as num?)?.toDouble() ?? 0,
      realLng: (json['realLng'] as num?)?.toDouble() ?? 0,
      displayLat: (json['displayLat'] as num?)?.toDouble() ?? 0,
      displayLng: (json['displayLng'] as num?)?.toDouble() ?? 0,
      locationPrivacyRadiusM: json['locationPrivacyRadiusM'] as int? ?? 0,
      exactLocationUnlockAt:
          DateTime.tryParse(json['exactLocationUnlockAt'] as String? ?? '') ??
          DateTime.now(),
      startTime:
          DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
      maxPeople: json['maxPeople'] as int? ?? 0,
      confirmedCount: json['confirmedCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      feedbackTargets: (json['feedbackTargets'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ActivityFeedbackTarget.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      myStatus: json['myStatus'] == null
          ? null
          : ParticipantStatus.values.byName(json['myStatus'] as String),
      isMine: json['isMine'] as bool? ?? false,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.tryParse(json['lastMessageAt'] as String),
      unreadMessageCount: json['unreadMessageCount'] as int? ?? 0,
    );
  }
}
