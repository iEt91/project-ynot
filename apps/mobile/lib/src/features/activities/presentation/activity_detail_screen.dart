import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/moderation_report.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import 'create_activity_screen.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/status_pill.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final activity = state.activities
        .where((item) => item.id == activityId)
        .firstOrNull;

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

    final currentUser = state.user;
    final isCreator = currentUser?.id == activity.creatorId;
    final isActiveMember =
        activity.myStatus == ParticipantStatus.joinedPendingConfirmation ||
        activity.myStatus == ParticipantStatus.confirmed;
    final isRestricted =
        currentUser?.status == UserStatus.limited ||
        currentUser?.status == UserStatus.banned;
    final canJoin =
        !isRestricted &&
        !isCreator &&
        activity.isJoinable &&
        !activity.isFinishedOrArchived &&
        activity.myStatus != ParticipantStatus.removedByAdmin;
    final canLeave = isActiveMember && !activity.isFinishedOrArchived;
    final canOpenChat = isActiveMember;
    final isFull = activity.isFull && !isActiveMember;
    final currentUserId = currentUser?.id ?? '';
    final attendeePreview = controller.feedbackTargetsForActivity(
      activity,
      currentUserId,
    );

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 132),
            children: [
              _TopBar(
                title: activity.title,
                subtitle:
                    '${formatTimeRange(activity.startTime, activity.endTime)} · ${activity.zone}',
                onBack: () => context.pop(),
                isSaved:
                    state.savedActivityIds.contains(activity.id) &&
                    activity.isActiveLifecycle,
                onToggleSave: activity.isActiveLifecycle
                    ? () =>
                          unawaited(controller.toggleSavedActivity(activity.id))
                    : null,
                onMenuSelected: (value) async {
                  switch (value) {
                    case _DetailAction.edit:
                      if (isCreator) {
                        context.push(
                          '/create-activity',
                          extra: ActivityFormSeed(activity: activity),
                        );
                      }
                      break;
                    case _DetailAction.startActivity:
                      if (isCreator) {
                        await controller.startActivity(activity.id);
                      }
                      break;
                    case _DetailAction.finishActivity:
                      if (isCreator) {
                        await controller.finishActivity(activity.id);
                      }
                      break;
                    case _DetailAction.confirmAttendance:
                      if (!isCreator &&
                          activity.myStatus ==
                              ParticipantStatus.joinedPendingConfirmation) {
                        await controller.confirmAttendance(activity.id);
                      }
                      break;
                    case _DetailAction.cancelAttendance:
                      if (!isCreator &&
                          (activity.myStatus ==
                                  ParticipantStatus.joinedPendingConfirmation ||
                              activity.myStatus ==
                                  ParticipantStatus.confirmed)) {
                        await controller.cancelAttendance(activity.id);
                      }
                      break;
                    case _DetailAction.feedback:
                      context.push('/activity/${activity.id}/feedback');
                      break;
                    case _DetailAction.reportActivity:
                      context.push(
                        '/activity/${activity.id}/report',
                        extra: ReportRequest(
                          activityId: activity.id,
                          targetType: ReportTargetType.activity,
                          targetId: activity.id,
                        ),
                      );
                      break;
                    case _DetailAction.reportUser:
                      context.push(
                        '/activity/${activity.id}/report',
                        extra: ReportRequest(
                          activityId: activity.id,
                          targetType: ReportTargetType.user,
                          targetId: activity.creatorId,
                        ),
                      );
                      break;
                    case _DetailAction.deleteActivity:
                      await _confirmAndDelete(context, ref, activity);
                      break;
                  }
                },
                isCreator: isCreator,
                canStart:
                    activity.status == ActivityStatus.open ||
                    activity.status == ActivityStatus.active ||
                    activity.status == ActivityStatus.full,
                canFinish: activity.status == ActivityStatus.ongoing,
                canConfirm:
                    activity.myStatus ==
                    ParticipantStatus.joinedPendingConfirmation,
                canCancel:
                    activity.myStatus ==
                        ParticipantStatus.joinedPendingConfirmation ||
                    activity.myStatus == ParticipantStatus.confirmed,
              ),
              const SizedBox(height: 16),
              KawaiiCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KawaiiAvatar(
                      emoji: activity.emoji,
                      size: 76,
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
                              StatusPill(
                                label: _statusLabel(activity.status),
                                color: _statusColor(activity.status),
                              ),
                              StatusPill(
                                label: activity.vibe,
                                color: _categoryColor(activity.category),
                              ),
                              StatusPill(
                                label:
                                    '${activity.confirmedCount}/${activity.maxPeople}',
                                color: Colors.pinkAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            activity.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Resumen',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.event_rounded,
                      text: formatTimeRange(
                        activity.startTime,
                        activity.endTime,
                      ),
                    ),
                    _InfoChip(
                      icon: Icons.hourglass_bottom_rounded,
                      text: formatDurationLabel(
                        activity.endTime.difference(activity.startTime).abs(),
                      ),
                    ),
                    _InfoChip(icon: Icons.place_rounded, text: activity.zone),
                    _InfoChip(
                      icon: Icons.groups_rounded,
                      text:
                          '${activity.confirmedCount}/${activity.maxPeople} asistentes',
                    ),
                    _InfoChip(
                      icon: Icons.category_rounded,
                      text: activity.category,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Organizador',
                child: Row(
                  children: [
                    KawaiiAvatar(
                      emoji: currentUser != null && isCreator
                          ? currentUser.avatarEmoji
                          : '🌙',
                      size: 54,
                      accentColor: _categoryColor(activity.category),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.creatorLabel,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCreator
                                ? 'Tú organizas este plan'
                                : 'Organizador de la actividad',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Asistentes',
                trailing: Text(
                  '${activity.confirmedCount} confirmados',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: attendeePreview.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final attendee = attendeePreview[index];
                          return _AttendeeChip(
                            emoji: attendee.emoji,
                            label: attendee.label,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.isFull
                          ? 'La actividad está llena por ahora.'
                          : 'Puedes ver una vista previa de quién viene. ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ActionSection(
                isCreator: isCreator,
                isActiveMember: isActiveMember,
                isFull: isFull,
                canJoin: canJoin,
                canLeave: canLeave,
                canOpenChat: canOpenChat,
                onEdit: isCreator
                    ? () => context.push(
                        '/create-activity',
                        extra: ActivityFormSeed(activity: activity),
                      )
                    : null,
                onJoin: () async {
                  await controller.joinActivity(activity.id);
                  if (!context.mounted) return;
                  final updated = ref
                      .read(appStateProvider)
                      .activities
                      .where((item) => item.id == activity.id)
                      .firstOrNull;
                  if (updated == null) return;
                  if (updated.myStatus ==
                          ParticipantStatus.joinedPendingConfirmation ||
                      updated.myStatus == ParticipantStatus.confirmed) {
                    context.push('/chat/${activity.id}');
                  }
                },
                onLeave: () async {
                  await controller.leaveActivity(activity.id);
                },
                onOpenChat: () => context.push('/chat/${activity.id}'),
                onDelete: () => _confirmAndDelete(context, ref, activity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('¿Eliminar actividad?'),
              content: const Text(
                'Esto eliminará la actividad del mapa, la lista y los chats. Esta acción no se puede deshacer.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final deleted = await ref
        .read(appControllerProvider)
        .deleteActivity(activity.id);
    if (!deleted || !context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Actividad eliminada.')));
    if (!context.mounted) return;
    context.go('/');
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

  Color _statusColor(ActivityStatus status) {
    return switch (status) {
      ActivityStatus.pendingModeration => const Color(0xFF8B5CF6),
      ActivityStatus.open => const Color(0xFFFF5DB8),
      ActivityStatus.active => const Color(0xFFFF5DB8),
      ActivityStatus.full => const Color(0xFFFFB86B),
      ActivityStatus.ongoing => const Color(0xFF63E6BE),
      ActivityStatus.finished => Colors.white54,
      ActivityStatus.archived => Colors.white54,
      ActivityStatus.cancelled => const Color(0xFFEF4444),
      ActivityStatus.flagged => const Color(0xFFFB7185),
      ActivityStatus.removed => Colors.white54,
      ActivityStatus.rejectedHidden => Colors.white54,
      ActivityStatus.draft => Colors.white54,
    };
  }

  String _statusLabel(ActivityStatus status) {
    return switch (status) {
      ActivityStatus.pendingModeration => 'En revisión',
      ActivityStatus.open => 'Abierta',
      ActivityStatus.active => 'Abierta',
      ActivityStatus.full => 'Llena',
      ActivityStatus.ongoing => 'En curso',
      ActivityStatus.finished => 'Terminada',
      ActivityStatus.archived => 'Terminada',
      ActivityStatus.cancelled => 'Cancelada',
      ActivityStatus.flagged => 'Atenta',
      ActivityStatus.removed => 'Oculta',
      ActivityStatus.rejectedHidden => 'Oculta',
      ActivityStatus.draft => 'Borrador',
    };
  }
}

enum _DetailAction {
  edit,
  startActivity,
  finishActivity,
  confirmAttendance,
  cancelAttendance,
  feedback,
  reportActivity,
  reportUser,
  deleteActivity,
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.isSaved,
    required this.onToggleSave,
    required this.onMenuSelected,
    required this.isCreator,
    required this.canStart,
    required this.canFinish,
    required this.canConfirm,
    required this.canCancel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool isSaved;
  final VoidCallback? onToggleSave;
  final void Function(_DetailAction value) onMenuSelected;
  final bool isCreator;
  final bool canStart;
  final bool canFinish;
  final bool canConfirm;
  final bool canCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundBubble(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBubble(
              icon: isSaved
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              active: isSaved,
              onTap: onToggleSave,
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_DetailAction>(
              icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
              color: YnotTheme.surface2,
              onSelected: onMenuSelected,
              itemBuilder: (context) => [
                if (isCreator)
                  const PopupMenuItem(
                    value: _DetailAction.edit,
                    child: Text('Editar'),
                  ),
                if (canStart)
                  const PopupMenuItem(
                    value: _DetailAction.startActivity,
                    child: Text('Iniciar actividad'),
                  ),
                if (canFinish)
                  const PopupMenuItem(
                    value: _DetailAction.finishActivity,
                    child: Text('Finalizar actividad'),
                  ),
                if (!isCreator && canConfirm)
                  const PopupMenuItem(
                    value: _DetailAction.confirmAttendance,
                    child: Text('Confirmar asistencia'),
                  ),
                if (!isCreator && canCancel)
                  const PopupMenuItem(
                    value: _DetailAction.cancelAttendance,
                    child: Text('Cancelar asistencia'),
                  ),
                const PopupMenuItem(
                  value: _DetailAction.feedback,
                  child: Text('Feedback'),
                ),
                const PopupMenuItem(
                  value: _DetailAction.reportActivity,
                  child: Text('Reportar actividad'),
                ),
                if (!isCreator)
                  const PopupMenuItem(
                    value: _DetailAction.reportUser,
                    child: Text('Reportar usuario'),
                  ),
                if (isCreator)
                  const PopupMenuItem(
                    value: _DetailAction.deleteActivity,
                    child: Text('Eliminar actividad'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (trailing != null) ...[trailing!],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: YnotTheme.surface2.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YnotTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeChip extends StatelessWidget {
  const _AttendeeChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: YnotTheme.surface2.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YnotTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KawaiiAvatar(emoji: emoji, size: 38, accentColor: Colors.pinkAccent),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.isCreator,
    required this.isActiveMember,
    required this.isFull,
    required this.canJoin,
    required this.canLeave,
    required this.canOpenChat,
    required this.onEdit,
    required this.onJoin,
    required this.onLeave,
    required this.onOpenChat,
    required this.onDelete,
  });

  final bool isCreator;
  final bool isActiveMember;
  final bool isFull;
  final bool canJoin;
  final bool canLeave;
  final bool canOpenChat;
  final VoidCallback? onEdit;
  final Future<void> Function() onJoin;
  final Future<void> Function() onLeave;
  final VoidCallback onOpenChat;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Acciones',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (isCreator) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => unawaited(onDelete()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (isActiveMember) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: canOpenChat ? onOpenChat : null,
                    child: const Text('Abrir chat'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canLeave ? () => unawaited(onLeave()) : null,
                    child: const Text('Salir de actividad'),
                  ),
                ),
              ],
            ),
          ] else if (isFull) ...[
            FilledButton(onPressed: null, child: const Text('Actividad llena')),
          ] else if (canJoin) ...[
            FilledButton(
              onPressed: () => unawaited(onJoin()),
              child: const Text('Unirme'),
            ),
          ] else ...[
            FilledButton(
              onPressed: null,
              child: const Text('No puedes unirte'),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = active
        ? Colors.pinkAccent.withValues(alpha: 0.22)
        : YnotTheme.surface2.withValues(alpha: 0.96);
    final border = active
        ? Colors.pinkAccent.withValues(alpha: 0.40)
        : YnotTheme.border;
    final iconColor = active ? Colors.pinkAccent : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _RoundBubble extends StatelessWidget {
  const _RoundBubble({required this.icon, required this.onTap});

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
          color: YnotTheme.surface2.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(color: YnotTheme.border),
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
