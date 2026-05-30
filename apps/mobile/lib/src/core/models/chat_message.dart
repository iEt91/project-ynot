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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'activityId': activityId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmoji': senderEmoji,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isMe': isMe,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      activityId: json['activityId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderEmoji: json['senderEmoji'] as String? ?? '💬',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isMe: json['isMe'] as bool? ?? false,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? activityId,
    String? senderId,
    String? senderName,
    String? senderEmoji,
    String? content,
    DateTime? createdAt,
    bool? isMe,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      activityId: activityId ?? this.activityId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmoji: senderEmoji ?? this.senderEmoji,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isMe: isMe ?? this.isMe,
    );
  }
}
