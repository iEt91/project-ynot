class ReportableParticipant {
  const ReportableParticipant({
    required this.userId,
    required this.displayName,
    required this.avatarEmoji,
    required this.isOrganizer,
    required this.isBlocked,
  });

  final String userId;
  final String displayName;
  final String avatarEmoji;
  final bool isOrganizer;
  final bool isBlocked;

  String get roleLabel => isOrganizer ? 'Organizador' : 'Asistente';

  ReportableParticipant copyWith({
    String? displayName,
    String? avatarEmoji,
    bool? isOrganizer,
    bool? isBlocked,
  }) {
    return ReportableParticipant(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
