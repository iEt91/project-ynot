import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/moderation_report.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/presentation/profile_back_button.dart';

class SentReportsScreen extends ConsumerWidget {
  const SentReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final currentUser = state.user;

    final reports = currentUser == null
        ? const <ModerationReport>[]
        : state.reports
            .where((report) => report.reporterUserId == currentUser.id)
            .toList(growable: false)
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(
                children: [
                  ProfileBackButton(onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Reportes enviados',
                subtitle: 'Sólo tú puedes ver este historial local.',
              ),
              const SizedBox(height: 16),
              if (reports.isEmpty)
                const KawaiiEmptyState(
                  emoji: '🔒',
                  title: 'No enviaste reportes todavía.',
                  message:
                      'Cuando envíes un reporte, aparecerá aquí para que puedas revisarlo.',
                )
              else
                Column(
                  children: [
                    for (final report in reports) ...[
                      _ReportCard(
                        report: report,
                        target: _resolveTarget(controller, state, report),
                      ),
                      const SizedBox(height: 12),
                    ],
                    KawaiiCard(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.tonal(
                        onPressed: () async {
                          final confirmed = await _confirmClearHistory(context);
                          if (!confirmed || !context.mounted) return;
                          await controller.clearReportHistory();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Historial de reportes borrado.'),
                            ),
                          );
                        },
                        child: const Text('Borrar historial local'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmClearHistory(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: YnotTheme.surface2,
          title: const Text('¿Borrar historial de reportes?'),
          content: const Text(
            'Se eliminarán sólo tus reportes locales guardados en este dispositivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  _ResolvedReportTarget _resolveTarget(
    AppController controller,
    AppState state,
    ModerationReport report,
  ) {
    final activity = _findActivity(state.activities, report.activityId);

    switch (report.targetType) {
      case ReportTargetType.user:
        final profile = controller.publicProfileForUserId(report.targetId);
        return _ResolvedReportTarget(
          name: safeDisplayText(
            profile?.nickname ?? activity?.creatorLabel ?? 'Usuario',
            fallback: 'Usuario',
          ),
          emoji: safeDisplayText(
            profile?.avatarEmoji ?? activity?.emoji ?? '🌙',
            fallback: '🌙',
          ),
          activityTitle: activity?.title,
          activityZone: activity?.zone,
          contextLabel: 'Usuario reportado',
        );
      case ReportTargetType.activity:
        final profile = controller.publicProfileForUserId(activity?.creatorId ?? '');
        return _ResolvedReportTarget(
          name: safeDisplayText(
            profile?.nickname ?? activity?.creatorLabel ?? 'Usuario',
            fallback: 'Usuario',
          ),
          emoji: safeDisplayText(
            profile?.avatarEmoji ?? activity?.emoji ?? '🌙',
            fallback: '🌙',
          ),
          activityTitle: activity?.title,
          activityZone: activity?.zone,
          contextLabel: 'Actividad reportada',
        );
      case ReportTargetType.message:
        final message = _findMessage(state.chatMessages[report.activityId] ?? const [], report.targetId);
        final senderProfile = controller.publicProfileForUserId(
          message?.senderId ?? '',
        );
        return _ResolvedReportTarget(
          name: safeDisplayText(
            senderProfile?.nickname ?? message?.senderName ?? activity?.creatorLabel ?? 'Usuario',
            fallback: 'Usuario',
          ),
          emoji: safeDisplayText(
            senderProfile?.avatarEmoji ?? message?.senderEmoji ?? '💬',
            fallback: '💬',
          ),
          activityTitle: activity?.title,
          activityZone: activity?.zone,
          contextLabel: 'Mensaje reportado',
        );
    }
  }

  Activity? _findActivity(List<Activity> activities, String activityId) {
    for (final activity in activities) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    return null;
  }

  ChatMessage? _findMessage(List<ChatMessage> messages, String messageId) {
    for (final message in messages) {
      if (message.id == messageId) {
        return message;
      }
    }
    return null;
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.target,
  });

  final ModerationReport report;
  final _ResolvedReportTarget target;

  @override
  Widget build(BuildContext context) {
    final dateLabel = formatDateLabel(report.createdAt);
    final timeLabel = formatTimeOfDay(report.createdAt);
    final hasNote = report.note != null && report.note!.trim().isNotEmpty;

    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KawaiiAvatar(
                emoji: target.emoji,
                size: 48,
                accentColor: YnotTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target.contextLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (target.activityTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        target.activityTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const StatusPill(
                label: 'Enviado localmente',
                icon: '🔒',
                color: YnotTheme.mint,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(label: report.reason.label),
              _TagPill(label: report.targetType.label),
              if (target.activityZone != null && target.activityZone!.isNotEmpty)
                _TagPill(label: target.activityZone!),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 12),
            Text(
              report.note!.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '$dateLabel · $timeLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: YnotTheme.surface2.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YnotTheme.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ResolvedReportTarget {
  const _ResolvedReportTarget({
    required this.name,
    required this.emoji,
    required this.contextLabel,
    this.activityTitle,
    this.activityZone,
  });

  final String name;
  final String emoji;
  final String contextLabel;
  final String? activityTitle;
  final String? activityZone;
}
