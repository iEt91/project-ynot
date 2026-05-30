import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';

class LocalMockSnapshot {
  const LocalMockSnapshot({
    required this.user,
    required this.activities,
    required this.messagesByActivityId,
  });

  final AppUser? user;
  final List<Activity> activities;
  final Map<String, List<ChatMessage>> messagesByActivityId;

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'activities': activities.map((activity) => activity.toJson()).toList(growable: false),
      'messagesByActivityId': messagesByActivityId.map(
        (key, value) => MapEntry(key, value.map((message) => message.toJson()).toList(growable: false)),
      ),
    };
  }

  factory LocalMockSnapshot.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return LocalMockSnapshot(
      user: userJson is Map<String, dynamic> ? AppUser.fromJson(userJson) : null,
      activities: (json['activities'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Activity.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      messagesByActivityId: (json['messagesByActivityId'] as Map<String, dynamic>? ?? const {})
          .map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>? ?? const [])
                  .whereType<Map>()
                  .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
                  .toList(growable: false),
            ),
          ),
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
