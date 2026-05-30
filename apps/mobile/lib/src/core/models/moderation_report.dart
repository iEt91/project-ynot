enum ReportTargetType { activity, user, message }

enum ReportReason {
  noShow,
  badAttitude,
  wrongLocation,
  inappropriateMessage,
  other,
}

extension ReportTargetTypeX on ReportTargetType {
  String get label => switch (this) {
        ReportTargetType.activity => 'Actividad',
        ReportTargetType.user => 'Usuario',
        ReportTargetType.message => 'Mensaje',
      };
}

extension ReportReasonX on ReportReason {
  String get label => switch (this) {
        ReportReason.noShow => '🚫 No apareció',
        ReportReason.badAttitude => '😐 Mala actitud',
        ReportReason.wrongLocation => '🧭 Ubicación incorrecta',
        ReportReason.inappropriateMessage => '💬 Mensaje inapropiado',
        ReportReason.other => '⚠️ Otro',
      };
}

class ModerationReport {
  const ModerationReport({
    required this.reportId,
    required this.reporterUserId,
    required this.targetType,
    required this.targetId,
    required this.activityId,
    required this.reason,
    required this.createdAt,
    this.note,
  });

  final String reportId;
  final String reporterUserId;
  final ReportTargetType targetType;
  final String targetId;
  final String activityId;
  final ReportReason reason;
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reporterUserId': reporterUserId,
      'targetType': targetType.name,
      'targetId': targetId,
      'activityId': activityId,
      'reason': reason.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ModerationReport.fromJson(Map<String, dynamic> json) {
    return ModerationReport(
      reportId: json['reportId'] as String? ?? '',
      reporterUserId: json['reporterUserId'] as String? ?? '',
      targetType: ReportTargetType.values.byName(
        json['targetType'] as String? ?? ReportTargetType.activity.name,
      ),
      targetId: json['targetId'] as String? ?? '',
      activityId: json['activityId'] as String? ?? '',
      reason: ReportReason.values.byName(
        json['reason'] as String? ?? ReportReason.other.name,
      ),
      note: json['note'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ReportRequest {
  const ReportRequest({
    required this.activityId,
    required this.targetType,
    required this.targetId,
  });

  final String activityId;
  final ReportTargetType targetType;
  final String targetId;
}
