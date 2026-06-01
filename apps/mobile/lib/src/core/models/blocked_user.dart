import '../utils/formatters.dart';

class BlockedUserEntry {
  const BlockedUserEntry({
    required this.userId,
    required this.nickname,
    required this.avatarEmoji,
    required this.blockedAt,
  });

  final String userId;
  final String nickname;
  final String avatarEmoji;
  final DateTime blockedAt;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatarEmoji': avatarEmoji,
      'blockedAt': blockedAt.toIso8601String(),
    };
  }

  factory BlockedUserEntry.fromJson(Map<String, dynamic> json) {
    return BlockedUserEntry(
      userId: json['userId'] as String? ?? '',
      nickname: safeDisplayText(
        json['nickname'] as String? ?? '',
        fallback: 'Luna',
      ),
      avatarEmoji: safeDisplayText(
        json['avatarEmoji'] as String? ?? '',
        fallback: '🌙',
      ),
      blockedAt:
          DateTime.tryParse(json['blockedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
