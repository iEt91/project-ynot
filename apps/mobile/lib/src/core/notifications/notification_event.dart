enum NotificationEventType {
  newMessage,
  newAttendee,
  activityStarting,
}

class NotificationEvent {
  const NotificationEvent({
    required this.type,
    required this.activityId,
    required this.createdAt,
    this.userId,
    this.messageId,
    this.payload = const {},
  });

  final NotificationEventType type;
  final String activityId;
  final DateTime createdAt;
  final String? userId;
  final String? messageId;
  final Map<String, dynamic> payload;
}
