import '../utils/formatters.dart';

enum InAppNotificationType {
  newMessage,
  activityStartingSoon,
  newAttendee,
  activityFinished,
  feedbackAvailable,
  blockedUserPresent,
  activitySaved,
  activityReminder,
}

class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.type,
    required this.activityId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    required this.dedupeKey,
  });

  final String id;
  final InAppNotificationType type;
  final String activityId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String dedupeKey;

  bool get isRead => readAt != null;

  String get emoji => switch (type) {
    InAppNotificationType.newMessage => '💬',
    InAppNotificationType.activityStartingSoon => '⏰',
    InAppNotificationType.newAttendee => '👋',
    InAppNotificationType.activityFinished => '🕯️',
    InAppNotificationType.feedbackAvailable => '✨',
    InAppNotificationType.blockedUserPresent => '🔒',
    InAppNotificationType.activitySaved => '🔖',
    InAppNotificationType.activityReminder => '⏳',
  };

  InAppNotification copyWith({
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return InAppNotification(
      id: id,
      type: type,
      activityId: activityId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      dedupeKey: dedupeKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'activityId': activityId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'dedupeKey': dedupeKey,
    };
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    final typeName =
        json['type'] as String? ?? InAppNotificationType.newMessage.name;
    final type = InAppNotificationType.values.firstWhere(
      (candidate) => candidate.name == typeName,
      orElse: () => InAppNotificationType.newMessage,
    );

    return InAppNotification(
      id: safeDisplayText(json['id'] as String? ?? '', fallback: ''),
      type: type,
      activityId: safeDisplayText(
        json['activityId'] as String? ?? '',
        fallback: '',
      ),
      title: safeDisplayText(
        json['title'] as String? ?? '',
        fallback: 'Notificación',
      ),
      body: safeDisplayText(json['body'] as String? ?? '', fallback: ''),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] == null
          ? null
          : DateTime.tryParse(json['readAt'] as String),
      dedupeKey: safeDisplayText(
        json['dedupeKey'] as String? ?? '',
        fallback: '',
      ),
    );
  }
}
