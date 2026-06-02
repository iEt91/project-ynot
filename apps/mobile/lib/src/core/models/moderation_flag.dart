import '../utils/formatters.dart';

enum ModerationFlagSourceType { activity, message }

enum ModerationFlagStatus { pending, reviewed, dismissed }

class ModerationFlag {
  const ModerationFlag({
    required this.flagId,
    required this.sourceType,
    required this.sourceId,
    required this.activityId,
    required this.userId,
    required this.keyword,
    required this.category,
    required this.textSnippet,
    required this.createdAt,
    required this.status,
    required this.dedupeKey,
    this.aiRiskScore,
    this.aiRiskLabel,
    this.aiSummary,
    this.manuallyReviewedBy,
    this.reviewedAt,
  });

  final String flagId;
  final ModerationFlagSourceType sourceType;
  final String sourceId;
  final String activityId;
  final String userId;
  final String keyword;
  final String category;
  final String textSnippet;
  final DateTime createdAt;
  final ModerationFlagStatus status;
  final String dedupeKey;
  final double? aiRiskScore;
  final String? aiRiskLabel;
  final String? aiSummary;
  final String? manuallyReviewedBy;
  final DateTime? reviewedAt;

  bool get isPending => status == ModerationFlagStatus.pending;

  String get statusLabel => switch (status) {
    ModerationFlagStatus.pending => 'Pendiente',
    ModerationFlagStatus.reviewed => 'Revisada',
    ModerationFlagStatus.dismissed => 'Descartada',
  };

  ModerationFlag copyWith({
    ModerationFlagStatus? status,
    double? aiRiskScore,
    String? aiRiskLabel,
    String? aiSummary,
    String? manuallyReviewedBy,
    DateTime? reviewedAt,
  }) {
    return ModerationFlag(
      flagId: flagId,
      sourceType: sourceType,
      sourceId: sourceId,
      activityId: activityId,
      userId: userId,
      keyword: keyword,
      category: category,
      textSnippet: textSnippet,
      createdAt: createdAt,
      status: status ?? this.status,
      dedupeKey: dedupeKey,
      aiRiskScore: aiRiskScore ?? this.aiRiskScore,
      aiRiskLabel: aiRiskLabel ?? this.aiRiskLabel,
      aiSummary: aiSummary ?? this.aiSummary,
      manuallyReviewedBy: manuallyReviewedBy ?? this.manuallyReviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flagId': flagId,
      'sourceType': sourceType.name,
      'sourceId': sourceId,
      'activityId': activityId,
      'userId': userId,
      'keyword': keyword,
      'category': category,
      'textSnippet': textSnippet,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'dedupeKey': dedupeKey,
      if (aiRiskScore != null) 'aiRiskScore': aiRiskScore,
      if (aiRiskLabel != null) 'aiRiskLabel': aiRiskLabel,
      if (aiSummary != null) 'aiSummary': aiSummary,
      if (manuallyReviewedBy != null) 'manuallyReviewedBy': manuallyReviewedBy,
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
    };
  }

  factory ModerationFlag.fromJson(Map<String, dynamic> json) {
    final sourceTypeName =
        json['sourceType'] as String? ?? ModerationFlagSourceType.activity.name;
    final sourceType = ModerationFlagSourceType.values.firstWhere(
      (candidate) => candidate.name == sourceTypeName,
      orElse: () => ModerationFlagSourceType.activity,
    );
    final statusName =
        json['status'] as String? ?? ModerationFlagStatus.pending.name;
    final status = ModerationFlagStatus.values.firstWhere(
      (candidate) => candidate.name == statusName,
      orElse: () => ModerationFlagStatus.pending,
    );

    return ModerationFlag(
      flagId: safeDisplayText(json['flagId'] as String? ?? '', fallback: ''),
      sourceType: sourceType,
      sourceId: safeDisplayText(
        json['sourceId'] as String? ?? '',
        fallback: '',
      ),
      activityId: safeDisplayText(
        json['activityId'] as String? ?? '',
        fallback: '',
      ),
      userId: safeDisplayText(json['userId'] as String? ?? '', fallback: ''),
      keyword: safeDisplayText(json['keyword'] as String? ?? '', fallback: ''),
      category: safeDisplayText(
        json['category'] as String? ?? '',
        fallback: '',
      ),
      textSnippet: safeDisplayText(
        json['textSnippet'] as String? ?? '',
        fallback: '',
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: status,
      dedupeKey: safeDisplayText(
        json['dedupeKey'] as String? ?? '',
        fallback: '',
      ),
      aiRiskScore: (json['aiRiskScore'] as num?)?.toDouble(),
      aiRiskLabel:
          safeDisplayText(
            json['aiRiskLabel'] as String? ?? '',
            fallback: '',
          ).trim().isEmpty
          ? null
          : safeDisplayText(json['aiRiskLabel'] as String? ?? '', fallback: ''),
      aiSummary:
          safeDisplayText(
            json['aiSummary'] as String? ?? '',
            fallback: '',
          ).trim().isEmpty
          ? null
          : safeDisplayText(json['aiSummary'] as String? ?? '', fallback: ''),
      manuallyReviewedBy:
          safeDisplayText(
            json['manuallyReviewedBy'] as String? ?? '',
            fallback: '',
          ).trim().isEmpty
          ? null
          : safeDisplayText(
              json['manuallyReviewedBy'] as String? ?? '',
              fallback: '',
            ),
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
    );
  }
}
