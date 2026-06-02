class AppSettings {
  const AppSettings({
    required this.receiveNotifications,
    required this.chatMessagesNotifications,
    required this.recommendedActivitiesNotifications,
    required this.activityStartingSoonNotifications,
    required this.showRecommendations,
    required this.showSavedHighlights,
    required this.showArchivedChats,
    required this.hidePreciseLocationUntilUnlock,
    required this.personalizedRecommendations,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      receiveNotifications: true,
      chatMessagesNotifications: true,
      recommendedActivitiesNotifications: true,
      activityStartingSoonNotifications: true,
      showRecommendations: true,
      showSavedHighlights: true,
      showArchivedChats: true,
      hidePreciseLocationUntilUnlock: true,
      personalizedRecommendations: true,
    );
  }

  final bool receiveNotifications;
  final bool chatMessagesNotifications;
  final bool recommendedActivitiesNotifications;
  final bool activityStartingSoonNotifications;
  final bool showRecommendations;
  final bool showSavedHighlights;
  final bool showArchivedChats;
  final bool hidePreciseLocationUntilUnlock;
  final bool personalizedRecommendations;

  AppSettings copyWith({
    bool? receiveNotifications,
    bool? chatMessagesNotifications,
    bool? recommendedActivitiesNotifications,
    bool? activityStartingSoonNotifications,
    bool? showRecommendations,
    bool? showSavedHighlights,
    bool? showArchivedChats,
    bool? hidePreciseLocationUntilUnlock,
    bool? personalizedRecommendations,
  }) {
    return AppSettings(
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      chatMessagesNotifications:
          chatMessagesNotifications ?? this.chatMessagesNotifications,
      recommendedActivitiesNotifications:
          recommendedActivitiesNotifications ??
          this.recommendedActivitiesNotifications,
      activityStartingSoonNotifications:
          activityStartingSoonNotifications ??
          this.activityStartingSoonNotifications,
      showRecommendations: showRecommendations ?? this.showRecommendations,
      showSavedHighlights: showSavedHighlights ?? this.showSavedHighlights,
      showArchivedChats: showArchivedChats ?? this.showArchivedChats,
      hidePreciseLocationUntilUnlock:
          hidePreciseLocationUntilUnlock ?? this.hidePreciseLocationUntilUnlock,
      personalizedRecommendations:
          personalizedRecommendations ?? this.personalizedRecommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiveNotifications': receiveNotifications,
      'chatMessagesNotifications': chatMessagesNotifications,
      'recommendedActivitiesNotifications':
          recommendedActivitiesNotifications,
      'activityStartingSoonNotifications': activityStartingSoonNotifications,
      'showRecommendations': showRecommendations,
      'showSavedHighlights': showSavedHighlights,
      'showArchivedChats': showArchivedChats,
      'hidePreciseLocationUntilUnlock': hidePreciseLocationUntilUnlock,
      'personalizedRecommendations': personalizedRecommendations,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final legacyShowRecommendations =
        json['recommendedActivitiesNotifications'] as bool?;
    return AppSettings(
      receiveNotifications: json['receiveNotifications'] as bool? ?? true,
      chatMessagesNotifications:
          json['chatMessagesNotifications'] as bool? ?? true,
      recommendedActivitiesNotifications: legacyShowRecommendations ?? true,
      activityStartingSoonNotifications:
          json['activityStartingSoonNotifications'] as bool? ?? true,
      showRecommendations:
          json['showRecommendations'] as bool? ?? legacyShowRecommendations ?? true,
      showSavedHighlights: json['showSavedHighlights'] as bool? ?? true,
      showArchivedChats: json['showArchivedChats'] as bool? ?? true,
      hidePreciseLocationUntilUnlock:
          json['hidePreciseLocationUntilUnlock'] as bool? ?? true,
      personalizedRecommendations:
          json['personalizedRecommendations'] as bool? ?? true,
    );
  }
}
