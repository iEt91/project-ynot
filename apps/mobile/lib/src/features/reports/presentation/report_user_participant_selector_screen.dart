import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/moderation_report.dart';
import '../../../core/models/reportable_participant.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../features/profile/presentation/profile_back_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class ReportUserParticipantSelectorScreen extends ConsumerWidget {
  const ReportUserParticipantSelectorScreen({
    super.key,
    required this.activityId,
  });

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final currentUser = state.user;
    final activity = _findActivity(state.activities, activityId);

    if (currentUser == null || activity == null) {
      return Scaffold(
        body: KawaiiScene(
          child: SafeArea(
            child: Center(
              child: KawaiiCard(
                child: const Text('No encontramos participantes para reportar.'),
              ),
            ),
          ),
        ),
      );
    }

    final participants = controller.reportableParticipantsForActivity(
      activity,
      currentUser.id,
    );

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
                title: 'Reportar usuario',
                subtitle: 'Elige a quién quieres reportar en este chat.',
              ),
              const SizedBox(height: 16),
              if (participants.isEmpty)
                const KawaiiEmptyState(
                  emoji: '💬',
                  title: 'No hay usuarios disponibles para reportar.',
                  message:
                      'En este momento no hay participantes visibles para enviar un reporte.',
                )
              else
                Column(
                  children: [
                    for (final participant in participants) ...[
                      _ParticipantCard(
                        participant: participant,
                        onTap: () {
                          context.push(
                            '/activity/${activity.id}/report',
                            extra: ReportRequest(
                              activityId: activity.id,
                              targetType: ReportTargetType.user,
                              targetId: participant.userId,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Activity? _findActivity(List<Activity> activities, String activityId) {
    for (final activity in activities) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    return null;
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.onTap,
  });

  final ReportableParticipant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: KawaiiCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              KawaiiAvatar(
                emoji: participant.avatarEmoji,
                size: 52,
                accentColor: participant.isBlocked ? YnotTheme.purple : YnotTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill(
                          label: participant.roleLabel,
                          icon: participant.isOrganizer ? '👑' : '✨',
                          color: YnotTheme.primary,
                        ),
                        if (participant.isBlocked)
                          const StatusPill(
                            label: 'Bloqueado',
                            icon: '🔒',
                            color: YnotTheme.mint,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
