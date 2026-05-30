class AppSettings {
  const AppSettings({
    required this.chatMessagesNotifications,
    required this.recommendedActivitiesNotifications,
    required this.activityStartingSoonNotifications,
    required this.hidePreciseLocationUntilUnlock,
    required this.personalizedRecommendations,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      chatMessagesNotifications: true,
      recommendedActivitiesNotifications: true,
      activityStartingSoonNotifications: true,
      hidePreciseLocationUntilUnlock: true,
      personalizedRecommendations: true,
    );
  }

  final bool chatMessagesNotifications;
  final bool recommendedActivitiesNotifications;
  final bool activityStartingSoonNotifications;
  final bool hidePreciseLocationUntilUnlock;
  final bool personalizedRecommendations;

  AppSettings copyWith({
    bool? chatMessagesNotifications,
    bool? recommendedActivitiesNotifications,
    bool? activityStartingSoonNotifications,
    bool? hidePreciseLocationUntilUnlock,
    bool? personalizedRecommendations,
  }) {
    return AppSettings(
      chatMessagesNotifications:
          chatMessagesNotifications ?? this.chatMessagesNotifications,
      recommendedActivitiesNotifications:
          recommendedActivitiesNotifications ??
          this.recommendedActivitiesNotifications,
      activityStartingSoonNotifications:
          activityStartingSoonNotifications ??
          this.activityStartingSoonNotifications,
      hidePreciseLocationUntilUnlock:
          hidePreciseLocationUntilUnlock ??
          this.hidePreciseLocationUntilUnlock,
      personalizedRecommendations:
          personalizedRecommendations ?? this.personalizedRecommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatMessagesNotifications': chatMessagesNotifications,
      'recommendedActivitiesNotifications':
          recommendedActivitiesNotifications,
      'activityStartingSoonNotifications': activityStartingSoonNotifications,
      'hidePreciseLocationUntilUnlock': hidePreciseLocationUntilUnlock,
      'personalizedRecommendations': personalizedRecommendations,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      chatMessagesNotifications:
          json['chatMessagesNotifications'] as bool? ?? true,
      recommendedActivitiesNotifications:
          json['recommendedActivitiesNotifications'] as bool? ?? true,
      activityStartingSoonNotifications:
          json['activityStartingSoonNotifications'] as bool? ?? true,
      hidePreciseLocationUntilUnlock:
          json['hidePreciseLocationUntilUnlock'] as bool? ?? true,
      personalizedRecommendations:
          json['personalizedRecommendations'] as bool? ?? true,
    );
  }
}
