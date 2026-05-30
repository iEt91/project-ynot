import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/moderation_report.dart';
import '../models/private_feedback.dart';

class LocalMockSnapshot {
  const LocalMockSnapshot({
    required this.user,
    required this.activities,
    required this.messagesByActivityId,
    required this.savedActivityIds,
    required this.reports,
    required this.feedbackEntries,
  });

  final AppUser? user;
  final List<Activity> activities;
  final Map<String, List<ChatMessage>> messagesByActivityId;
  final List<String> savedActivityIds;
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
      'reports': reports.map((report) => report.toJson()).toList(growable: false),
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
      savedActivityIds:
          (json['savedActivityIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(growable: false),
      reports: (json['reports'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ModerationReport.fromJson(
              Map<String, dynamic>.from(item),
            ),
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
