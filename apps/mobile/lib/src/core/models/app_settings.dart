class AppSettings {
  const AppSettings({
    required this.receiveNotifications,
    required this.chatMessagesNotifications,
    required this.recommendedActivitiesNotifications,
    required this.activityStartingSoonNotifications,
    required this.searchRadiusKm,
    required this.mockCurrentLocationKey,
    required this.showRecommendations,
    required this.showSavedHighlights,
    required this.showArchivedChats,
    required this.muteAllChats,
    required this.hidePreciseLocationUntilUnlock,
    required this.personalizedRecommendations,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      receiveNotifications: true,
      chatMessagesNotifications: true,
      recommendedActivitiesNotifications: true,
      activityStartingSoonNotifications: true,
      searchRadiusKm: 25,
      mockCurrentLocationKey: 'seoul',
      showRecommendations: true,
      showSavedHighlights: true,
      showArchivedChats: true,
      muteAllChats: false,
      hidePreciseLocationUntilUnlock: true,
      personalizedRecommendations: true,
    );
  }

  final bool receiveNotifications;
  final bool chatMessagesNotifications;
  final bool recommendedActivitiesNotifications;
  final bool activityStartingSoonNotifications;
  final int searchRadiusKm;
  final String mockCurrentLocationKey;
  final bool showRecommendations;
  final bool showSavedHighlights;
  final bool showArchivedChats;
  final bool muteAllChats;
  final bool hidePreciseLocationUntilUnlock;
  final bool personalizedRecommendations;

  AppSettings copyWith({
    bool? receiveNotifications,
    bool? chatMessagesNotifications,
    bool? recommendedActivitiesNotifications,
    bool? activityStartingSoonNotifications,
    int? searchRadiusKm,
    String? mockCurrentLocationKey,
    bool? showRecommendations,
    bool? showSavedHighlights,
    bool? showArchivedChats,
    bool? muteAllChats,
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
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      mockCurrentLocationKey:
          mockCurrentLocationKey ?? this.mockCurrentLocationKey,
      showRecommendations: showRecommendations ?? this.showRecommendations,
      showSavedHighlights: showSavedHighlights ?? this.showSavedHighlights,
      showArchivedChats: showArchivedChats ?? this.showArchivedChats,
      muteAllChats: muteAllChats ?? this.muteAllChats,
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
      'searchRadiusKm': searchRadiusKm,
      'mockCurrentLocationKey': mockCurrentLocationKey,
      'showRecommendations': showRecommendations,
      'showSavedHighlights': showSavedHighlights,
      'showArchivedChats': showArchivedChats,
      'muteAllChats': muteAllChats,
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
      searchRadiusKm: ((json['searchRadiusKm'] as int? ?? 25).clamp(1, 25))
          .toInt(),
      mockCurrentLocationKey:
          json['mockCurrentLocationKey'] as String? ?? 'seoul',
      showRecommendations:
          json['showRecommendations'] as bool? ?? legacyShowRecommendations ?? true,
      showSavedHighlights: json['showSavedHighlights'] as bool? ?? true,
      showArchivedChats: json['showArchivedChats'] as bool? ?? true,
      muteAllChats: json['muteAllChats'] as bool? ?? false,
      hidePreciseLocationUntilUnlock:
          json['hidePreciseLocationUntilUnlock'] as bool? ?? true,
      personalizedRecommendations:
          json['personalizedRecommendations'] as bool? ?? true,
    );
  }
}
