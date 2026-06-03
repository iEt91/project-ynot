import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/activity_share.dart';
import '../../../shared/widgets/activity_card.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import 'profile_back_button.dart';

class SavedActivitiesScreen extends ConsumerWidget {
  const SavedActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final activities = controller.savedActivities();
    final user = state.user;

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
                title: 'Guardadas',
                subtitle: 'Lo que dejaste cerca para volver luego.',
              ),
              const SizedBox(height: 16),
              if (user == null)
                const KawaiiCard(
                  child: Text('No encontramos una sesión activa.'),
                )
              else if (activities.isEmpty)
                const KawaiiEmptyState(
                  emoji: '💖',
                  title: 'No tienes actividades guardadas.',
                  message:
                      'Guarda un plan para volver a encontrarlo cuando quieras.',
                )
              else
                ...activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SavedActivityRow(
                      activity: activity,
                      controller: controller,
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

class _SavedActivityRow extends StatelessWidget {
  const _SavedActivityRow({required this.activity, required this.controller});

  final Activity activity;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ActivityCard(
      activity: activity,
      onTap: () => context.push('/activity/${activity.id}'),
      onJoin: () => context.push('/activity/${activity.id}'),
      onConfirm: () => context.push('/activity/${activity.id}'),
      showActions: false,
      onShare: () => shareActivityOrCopyFallback(context, activity),
      onLongPress: () => _showSavedActions(context, controller, activity),
    );
  }
}

Future<void> _showSavedActions(
  BuildContext context,
  AppController controller,
  Activity activity,
) async {
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
                          leading: const Icon(Icons.bookmark_remove_outlined),
                          title: const Text('Quitar de guardadas'),
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

  await controller.removeSavedActivity(activity.id);
}
