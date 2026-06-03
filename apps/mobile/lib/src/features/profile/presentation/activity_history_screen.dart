import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
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
              Row(children: [ProfileBackButton(onTap: () => context.pop())]),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Historial',
                subtitle: 'Actividades terminadas y archivadas.',
              ),
              const SizedBox(height: 16),
              if (activities.isEmpty)
                const KawaiiEmptyState(
                  emoji: '🕯️',
                  title: 'No tienes actividades en tu historial.',
                  message:
                      'Aquí verás tus actividades terminadas y archivadas.',
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
                          onJoin: () =>
                              context.push('/activity/${activity.id}'),
                          onConfirm: () => context.push('/chat/${activity.id}'),
                          showActions: false,
                          onLongPress: () => _showHistoryActions(
                            context,
                            controller,
                            activity,
                          ),
                        ),
                        if (controller.shouldShowAttendancePrompt(
                          activity,
                        )) ...[
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
                        ] else if (controller.shouldShowAttendanceClosedNotice(
                          activity,
                        )) ...[
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

Future<void> _showHistoryActions(
  BuildContext context,
  AppController controller,
  Activity activity,
) async {
  if (!activity.isFinishedOrArchived) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solo puedes eliminar actividades finalizadas de tu historial.',
        ),
      ),
    );
    return;
  }

  final shouldRemove =
      await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.92,
                  child: KawaiiCard(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.delete_outline_rounded),
                          title: const Text('Eliminar de mi historial'),
                          onTap: () => Navigator.of(sheetContext).pop(true),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.close_rounded),
                          title: const Text('Cancelar'),
                          onTap: () => Navigator.of(sheetContext).pop(false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ) ??
      false;

  if (!shouldRemove || !context.mounted) {
    return;
  }

  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: YnotTheme.surface2,
            title: const Text('Eliminar actividad del historial'),
            content: const Text(
              'Esta actividad desaparecerá de tu historial personal. No afectará a otras personas.',
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

  await controller.hideActivityFromHistory(activity.id);
}
