enum PrivateFeedbackOption {
  veryNice,
  goodVibe,
  normal,
  notConnected,
  noParticipated,
}

extension PrivateFeedbackOptionX on PrivateFeedbackOption {
  String get label => switch (this) {
    PrivateFeedbackOption.veryNice => '🌸 Muy agradable',
    PrivateFeedbackOption.goodVibe => '✨ Buena vibe',
    PrivateFeedbackOption.normal => '🙂 Normal',
    PrivateFeedbackOption.notConnected => '🫠 No conectamos',
    PrivateFeedbackOption.noParticipated => '🚫 No participó',
  };

  String get shortLabel => switch (this) {
    PrivateFeedbackOption.veryNice => 'Muy agradable',
    PrivateFeedbackOption.goodVibe => 'Buena vibe',
    PrivateFeedbackOption.normal => 'Normal',
    PrivateFeedbackOption.notConnected => 'No conectamos',
    PrivateFeedbackOption.noParticipated => 'No participó',
  };
}

class PrivateFeedbackEntry {
  const PrivateFeedbackEntry({
    required this.activityId,
    required this.reviewerUserId,
    required this.reviewedUserId,
    required this.selectedFeedback,
    required this.createdAt,
  });

  final String activityId;
  final String reviewerUserId;
  final String reviewedUserId;
  final PrivateFeedbackOption selectedFeedback;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'reviewerUserId': reviewerUserId,
      'reviewedUserId': reviewedUserId,
      'selectedFeedback': selectedFeedback.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PrivateFeedbackEntry.fromJson(Map<String, dynamic> json) {
    return PrivateFeedbackEntry(
      activityId: json['activityId'] as String? ?? '',
      reviewerUserId: json['reviewerUserId'] as String? ?? '',
      reviewedUserId: json['reviewedUserId'] as String? ?? '',
      selectedFeedback: PrivateFeedbackOption.values.byName(
        json['selectedFeedback'] as String? ??
            PrivateFeedbackOption.normal.name,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
