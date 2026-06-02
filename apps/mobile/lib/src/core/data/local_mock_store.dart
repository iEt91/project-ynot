import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../models/attendance_response.dart';
import '../models/blocked_user.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/in_app_notification.dart';
import '../models/moderation_flag.dart';
import '../models/moderation_report.dart';
import '../models/private_feedback.dart';

class LocalMockSnapshot {
  const LocalMockSnapshot({
    required this.user,
    required this.activities,
    required this.messagesByActivityId,
    required this.savedActivityIds,
    required this.blockedUsers,
    this.notifications = const [],
    this.moderationFlags = const [],
    this.dismissedBlockedChatWarningActivityIds = const [],
    this.acceptedChatGuidelinesActivityIds = const [],
    this.preActivityChecklistByActivityId = const {},
    this.startingSoonReminderSentActivityKeys = const [],
    this.attendanceResponsesByActivityId = const {},
    required this.activityFilters,
    this.searchQuery = '',
    required this.settings,
    required this.reports,
    required this.feedbackEntries,
  });

  final AppUser? user;
  final List<Activity> activities;
  final Map<String, List<ChatMessage>> messagesByActivityId;
  final List<String> savedActivityIds;
  final List<BlockedUserEntry> blockedUsers;
  final List<InAppNotification> notifications;
  final List<ModerationFlag> moderationFlags;
  final List<String> dismissedBlockedChatWarningActivityIds;
  final List<String> acceptedChatGuidelinesActivityIds;
  final Map<String, List<String>> preActivityChecklistByActivityId;
  final List<String> startingSoonReminderSentActivityKeys;
  final Map<String, String> attendanceResponsesByActivityId;
  final Map<String, dynamic> activityFilters;
  final String searchQuery;
  final Map<String, dynamic> settings;
  final List<ModerationReport> reports;
  final List<PrivateFeedbackEntry> feedbackEntries;

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'activities': activities
          .map((activity) => activity.toJson())
          .toList(growable: false),
      'messagesByActivityId': messagesByActivityId.map(
        (key, value) => MapEntry(
          key,
          value.map((message) => message.toJson()).toList(growable: false),
        ),
      ),
      'savedActivityIds': List<String>.from(savedActivityIds),
      'blockedUsers': blockedUsers
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'notifications': notifications
          .map((item) => item.toJson())
          .toList(growable: false),
      'moderationFlags': moderationFlags
          .map((item) => item.toJson())
          .toList(growable: false),
      'dismissedBlockedChatWarningActivityIds': List<String>.from(
        dismissedBlockedChatWarningActivityIds,
      ),
      'acceptedChatGuidelinesActivityIds': List<String>.from(
        acceptedChatGuidelinesActivityIds,
      ),
      'preActivityChecklistByActivityId': preActivityChecklistByActivityId.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      'startingSoonReminderSentActivityKeys':
          List<String>.from(startingSoonReminderSentActivityKeys),
      'attendanceResponsesByActivityId': attendanceResponsesByActivityId,
      'activityFilters': activityFilters,
      'searchQuery': searchQuery,
      'settings': settings,
      'reports': reports
          .map((report) => report.toJson())
          .toList(growable: false),
      'feedbackEntries': feedbackEntries
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }

  factory LocalMockSnapshot.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return LocalMockSnapshot(
      user: userJson is Map<String, dynamic>
          ? AppUser.fromJson(userJson)
          : null,
      activities: (json['activities'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Activity.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      messagesByActivityId:
          (json['messagesByActivityId'] as Map<String, dynamic>? ?? const {})
              .map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>? ?? const [])
                      .whereType<Map>()
                      .map(
                        (item) => ChatMessage.fromJson(
                          Map<String, dynamic>.from(item),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
      savedActivityIds: (json['savedActivityIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      blockedUsers: (json['blockedUsers'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BlockedUserEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      notifications: (json['notifications'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                InAppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      moderationFlags: (json['moderationFlags'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ModerationFlag.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      dismissedBlockedChatWarningActivityIds:
          (json['dismissedBlockedChatWarningActivityIds'] as List<dynamic>? ??
                  const [])
              .whereType<String>()
              .toList(growable: false),
      acceptedChatGuidelinesActivityIds:
          (json['acceptedChatGuidelinesActivityIds'] as List<dynamic>? ??
                  const [])
              .whereType<String>()
              .toList(growable: false),
      preActivityChecklistByActivityId:
          (json['preActivityChecklistByActivityId'] as Map<String, dynamic>? ??
                  const {})
              .map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>? ?? const [])
                      .whereType<String>()
                      .toList(growable: false),
                ),
              ),
      startingSoonReminderSentActivityKeys:
          (json['startingSoonReminderSentActivityKeys'] as List<dynamic>? ??
                  const [])
              .whereType<String>()
              .toList(growable: false),
      attendanceResponsesByActivityId:
          (json['attendanceResponsesByActivityId'] as Map<String, dynamic>? ??
                  const {})
              .map(
                (key, value) => MapEntry(
                  key,
                  value is String &&
                          AttendanceResponse.values.any(
                            (response) => response.name == value,
                          )
                      ? value
                      : AttendanceResponse.unknown.name,
                ),
              ),
      activityFilters: Map<String, dynamic>.from(
        json['activityFilters'] as Map<String, dynamic>? ?? const {},
      ),
      searchQuery: json['searchQuery'] as String? ?? '',
      settings: Map<String, dynamic>.from(
        json['settings'] as Map<String, dynamic>? ?? const {},
      ),
      reports: (json['reports'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ModerationReport.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      feedbackEntries: (json['feedbackEntries'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                PrivateFeedbackEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}

class LocalMockStore {
  static const _snapshotKey = 'ynot_mock_snapshot';

  Future<void> save(LocalMockSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
  }

  Future<LocalMockSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return LocalMockSnapshot.fromJson(decoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey);
  }
}
