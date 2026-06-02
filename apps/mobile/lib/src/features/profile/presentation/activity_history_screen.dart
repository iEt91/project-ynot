import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/attendance_prompt_card.dart';
import '../../../shared/widgets/activity_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import 'profile_back_button.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.user;
    final controller = ref.read(appControllerProvider);
    final activities = user == null
        ? const <Activity>[]
        : controller.historyActivitiesForUser(user.id);

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(
                children: [
                  ProfileBackButton(
                    onTap: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Historial',
                subtitle: 'Actividades terminadas y archivadas.',
              ),
              const SizedBox(height: 16),
              if (activities.isEmpty)
                const KawaiiEmptyState(
                  emoji: '??',
                  title: 'Todavía no hay historial',
                  message: 'Cuando termines actividades, aparecerán aquí para revisarlas después.',
                )
              else
                ...activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ActivityCard(
                          activity: activity,
                          onTap: () => context.push('/activity/${activity.id}'),
                          onJoin: () => context.push('/activity/${activity.id}'),
                          onConfirm: () => context.push('/chat/${activity.id}'),
                          showActions: false,
                        ),
                        if (controller.shouldShowAttendancePrompt(activity)) ...[
                          const SizedBox(height: 12),
                          AttendancePromptCard(
                            compact: true,
                            onSelected: (response) async {
                              await controller.submitAttendanceResponse(
                                activityId: activity.id,
                                response: response,
                              );
                            },
                          ),
                        ] else if (
                          controller.shouldShowAttendanceClosedNotice(activity)
                        ) ...[
                          const SizedBox(height: 12),
                          KawaiiCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Asistencia cerrada',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'La actividad ya finalizó y no es posible registrar asistencia.',
                                  style: Theme.of(context).textTheme.bodyMedium
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
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

