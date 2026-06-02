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
import '../../../shared/widgets/pre_activity_checklist_card.dart';
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
    final canLeave =
        isActiveMember && !isCreator && !activity.isFinishedOrArchived;
    final canOpenChat = isActiveMember;
    final isFull = activity.isFull && !isActiveMember;
    final organizerProfile = controller.publicProfileForUserId(activity.creatorId);
    final confirmedAttendees = controller.confirmedAttendeesForActivity(
      activity,
    );
    final hasBlockedParticipants = controller.hasBlockedParticipants(activity);
    final canSeeExactLocation = controller.canCurrentUserSeeExactLocation(activity);
    final locationDisclosureLabel = controller.locationDisclosureLabel(activity);
    final showStartingSoonBadge = controller.isActivityStartingSoonForCurrentUser(
      activity,
    );
    final showPreActivityChecklist = controller.shouldShowPreActivityChecklist(
      activity,
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
                    '${formatTimeRange(activity.startTime, activity.endTime)} Â· ${activity.zone}',
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
                              if (showStartingSoonBadge)
                                StatusPill(
                                  label: 'Empieza pronto',
                                  color: YnotTheme.primary,
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
                title: 'Ubicación',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: YnotTheme.surface2.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: YnotTheme.border),
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: canSeeExactLocation ? YnotTheme.mint : YnotTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.zone,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            canSeeExactLocation
                                ? 'Ubicación exacta disponible'
                                : 'Ubicación aproximada',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusPill(
                      label: locationDisclosureLabel,
                      color: canSeeExactLocation ? YnotTheme.mint : YnotTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (showPreActivityChecklist) ...[
                PreActivityChecklistCard(
                  checkedItemIds: controller.preActivityChecklistCheckedItemIds(
                    activity.id,
                  ),
                  onToggleItem: (itemId) => unawaited(
                    controller.togglePreActivityChecklistItem(
                      activityId: activity.id,
                      itemId: itemId,
                    ),
                  ),
                  onCompleteAll: () => unawaited(
                    controller.markPreActivityChecklistComplete(activity.id),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _SectionCard(
                title: 'Organizador',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: organizerProfile == null
                      ? null
                      : () => context.push('/profile/${activity.creatorId}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        KawaiiAvatar(
                          emoji: safeDisplayText(
                            organizerProfile?.avatarEmoji ?? activity.emoji,
                                fallback: '🌙',
                          ),
                          size: 54,
                          accentColor: _categoryColor(activity.category),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                safeDisplayText(
                                  organizerProfile?.nickname ??
                                      activity.creatorLabel,
                                  fallback: 'Luna',
                                ),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCreator
                                    ? 'T? organizas este plan'
                                    : 'Organizador de la actividad',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (hasBlockedParticipants) ...[
                _WarningBanner(
                  text: 'Hay usuarios bloqueados en esta actividad.',
                ),
                const SizedBox(height: 14),
              ],
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (confirmedAttendees.isEmpty)
                      Text(
                        'Todavía no hay asistentes confirmados aparte del organizador.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      )
                    else ...[
                      SizedBox(
                        height: 134,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 4),
                          itemCount: confirmedAttendees.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final attendee = confirmedAttendees[index];
                            final attendeeProfile = controller.publicProfileForUserId(
                              attendee.userId,
                            );
                            return _AttendeeChip(
                              emoji: safeDisplayText(
                                attendeeProfile?.avatarEmoji ?? attendee.emoji,
                                fallback: '🌙',
                              ),
                              label: safeDisplayText(
                                attendeeProfile?.nickname ?? attendee.label,
                                fallback: attendee.label,
                              ),
                              isBlocked: controller.isUserBlocked(attendee.userId),
                              onTap: attendeeProfile == null
                                  ? null
                                  : () => context.push('/profile/${attendee.userId}'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.isFull
                            ? 'La actividad está llena por ahora.'
                            : 'Puedes ver una vista previa de quién viene.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
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
                canSeeExactLocation: canSeeExactLocation,
                canConfirm:
                    !isCreator &&
                    activity.myStatus ==
                        ParticipantStatus.joinedPendingConfirmation,
                onEdit: isCreator
                    ? () => context.push(
                        '/create-activity',
                        extra: ActivityFormSeed(activity: activity),
                      )
                    : null,
                onJoin: () async {
                  if (hasBlockedParticipants) {
                    final proceed = await _confirmJoinDespiteBlockedUsers(
                      context,
                    );
                    if (!proceed || !context.mounted) {
                      return;
                    }
                  }
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
                onConfirm: () async {
                  await controller.confirmAttendance(activity.id);
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

  Future<bool> _confirmJoinDespiteBlockedUsers(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: YnotTheme.surface2,
          title: const Text('Hay un usuario bloqueado en esta actividad'),
          content: const Text(
            'Alguien que bloqueaste participa en esta actividad. Puedes unirte igualmente o volver atrás.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Unirme de todas formas'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
  const _AttendeeChip({
    required this.emoji,
    required this.label,
    required this.isBlocked,
    this.onTap,
  });

  final String emoji;
  final String label;
  final bool isBlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 108,
        height: 134,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: YnotTheme.surface2.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: YnotTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KawaiiAvatar(emoji: emoji, size: 42, accentColor: Colors.pinkAccent),
            const SizedBox(height: 8),
            if (isBlocked) ...[
              const _BlockedBadge(),
              const SizedBox(height: 6),
            ],
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
      ),
    );
  }
}

class _BlockedBadge extends StatelessWidget {
  const _BlockedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD166).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFD166).withValues(alpha: 0.34),
        ),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 11, color: Color(0xFFFFD166)),
            SizedBox(width: 4),
            Text(
              'Bloqueado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: const Text('⚠️', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
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
    required this.canSeeExactLocation,
    required this.canConfirm,
    required this.onEdit,
    required this.onJoin,
    required this.onConfirm,
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
  final bool canSeeExactLocation;
  final bool canConfirm;
  final VoidCallback? onEdit;
  final Future<void> Function() onJoin;
  final Future<void> Function() onConfirm;
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
            if (canOpenChat) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onOpenChat,
                  child: const Text('Abrir chat'),
                ),
              ),
            ],
          ] else if (canConfirm) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => unawaited(onConfirm()),
                    child: const Text('Confirmar asistencia'),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canOpenChat ? onOpenChat : null,
                child: const Text('Abrir chat'),
              ),
            ),
          ] else if (isActiveMember) ...[
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
            if (!canSeeExactLocation) ...[
              const SizedBox(height: 8),
              Text(
                'Verás la ubicación exacta 10 minutos antes del inicio.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ],
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
