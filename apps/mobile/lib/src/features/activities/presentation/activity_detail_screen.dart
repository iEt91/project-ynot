import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/app_user.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/status_pill.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(appStateProvider).activities.where((item) => item.id == activityId).firstOrNull;

    if (activity == null) {
      return Scaffold(
        body: KawaiiScene(
          child: Center(
            child: KawaiiCard(
              child: const Text('No encontramos esta actividad.'),
            ),
          ),
        ),
      );
    }

    final status = activity.myStatus;
    final isActiveMember = status == ParticipantStatus.joinedPendingConfirmation || status == ParticipantStatus.confirmed;
    final userStatus = ref.watch(appStateProvider).user?.status;
    final isRestricted = userStatus == UserStatus.limited || userStatus == UserStatus.banned;
    final canJoin = !isRestricted &&
        !activity.isFull &&
        activity.status != ActivityStatus.finished &&
        activity.status != ActivityStatus.cancelled &&
        activity.status != ActivityStatus.removed &&
        activity.status != ActivityStatus.rejectedHidden &&
        status != ParticipantStatus.removedByAdmin;
    final canConfirm = status == ParticipantStatus.joinedPendingConfirmation;
    final canCancel = isActiveMember;
    final canLeave = isActiveMember;

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 132),
            children: [
              Row(
                children: [
                  _RoundBubble(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatTimeOfDay(activity.startTime)} · ${activity.zone}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_DetailAction>(
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                    color: YnotTheme.surface2,
                    onSelected: (value) async {
                      switch (value) {
                        case _DetailAction.confirmAttendance:
                          if (canConfirm) {
                            await ref.read(appControllerProvider).confirmAttendance(activity.id);
                          }
                          break;
                        case _DetailAction.cancelAttendance:
                          if (canCancel) {
                            await ref.read(appControllerProvider).cancelAttendance(activity.id);
                          }
                          break;
                        case _DetailAction.feedback:
                          context.push('/activity/${activity.id}/feedback');
                          break;
                        case _DetailAction.report:
                          context.push('/activity/${activity.id}/report');
                          break;
                        case _DetailAction.leaveEvent:
                          if (canLeave) {
                            await ref.read(appControllerProvider).leaveActivity(activity.id);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _DetailAction.confirmAttendance,
                        enabled: canConfirm,
                        child: Text(canConfirm ? 'Confirmar asistencia' : 'Asistencia confirmada'),
                      ),
                      PopupMenuItem(
                        value: _DetailAction.cancelAttendance,
                        enabled: canCancel,
                        child: const Text('Cancelar asistencia'),
                      ),
                      const PopupMenuItem(
                        value: _DetailAction.feedback,
                        child: Text('Feedback'),
                      ),
                      const PopupMenuItem(
                        value: _DetailAction.report,
                        child: Text('Reportar'),
                      ),
                      PopupMenuItem(
                        value: _DetailAction.leaveEvent,
                        enabled: canLeave,
                        child: const Text('Salir del evento'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KawaiiCard(
                padding: const EdgeInsets.all(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    YnotTheme.surface.withValues(alpha: 0.88),
                  ],
                ),
                child: Row(
                  children: [
                    KawaiiAvatar(
                      emoji: activity.emoji,
                      size: 74,
                      accentColor: _categoryColor(activity.category),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusPill(label: activity.vibe, color: _categoryColor(activity.category)),
                              StatusPill(
                                label: '${activity.confirmedCount}/${activity.maxPeople}',
                                color: Colors.pinkAccent,
                              ),
                              StatusPill(
                                label: _statusLabel(activity.status),
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            activity.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isActiveMember) ...[
                const SizedBox(height: 14),
                KawaiiCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                      onPressed: canJoin
                          ? () async {
                              await ref.read(appControllerProvider).joinActivity(activity.id);
                              if (!context.mounted) return;
                              final updated = ref.read(appStateProvider).activities
                                  .where((item) => item.id == activity.id)
                                  .firstOrNull;
                              if (updated == null) return;
                              if (updated.myStatus == ParticipantStatus.joinedPendingConfirmation ||
                                  updated.myStatus == ParticipantStatus.confirmed) {
                                context.push('/chat/${activity.id}');
                              }
                            }
                          : null,
                        child: Text(canJoin ? 'Me apunto' : 'No puedes unirte'),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'Coffee' => YnotTheme.primary,
      'Study' => YnotTheme.purple,
      'Walks' => YnotTheme.mint,
      'Food' => const Color(0xFFFFB86B),
      'Art' => const Color(0xFFB18CFF),
      'Music' => const Color(0xFF63D2FF),
      _ => YnotTheme.primary,
    };
  }

  String _statusLabel(ActivityStatus status) {
    return switch (status) {
      ActivityStatus.pendingModeration => 'En revisión',
      ActivityStatus.active => 'Abierta',
      ActivityStatus.full => 'Llena',
      ActivityStatus.ongoing => 'En curso',
      ActivityStatus.finished => 'Terminada',
      ActivityStatus.cancelled => 'Cancelada',
      ActivityStatus.flagged => 'Atenta',
      ActivityStatus.removed => 'Oculta',
      ActivityStatus.rejectedHidden => 'Oculta',
      ActivityStatus.draft => 'Borrador',
    };
  }
}

enum _DetailAction { confirmAttendance, cancelAttendance, feedback, report, leaveEvent }

class _RoundBubble extends StatelessWidget {
  const _RoundBubble({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
