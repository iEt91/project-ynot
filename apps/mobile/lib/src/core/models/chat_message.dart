class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.activityId,
    required this.senderId,
    required this.senderName,
    required this.senderEmoji,
    required this.content,
    required this.createdAt,
    this.isMe = false,
  });

  final String id;
  final String chatId;
  final String activityId;
  final String senderId;
  final String senderName;
  final String senderEmoji;
  final String content;
  final DateTime createdAt;
  final bool isMe;

  String get timeLabel {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
