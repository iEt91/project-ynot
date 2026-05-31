import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
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
              Row(
                children: [
                  ProfileBackButton(onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Guardadas',
                subtitle: 'Lo que dejaste cerca para volver luego.',
              ),
              const SizedBox(height: 16),
              if (user == null)
                const KawaiiCard(child: Text('No encontramos una sesión activa.'))
              else if (activities.isEmpty)
                const KawaiiEmptyState(
                  emoji: '??',
                  title: 'Todavía no guardaste actividades',
                  message: 'Guarda un plan para volver a encontrarlo cuando quieras.',
                )
              else
                ...activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SavedActivityRow(activity: activity),
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
  const _SavedActivityRow({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return ActivityCard(
      activity: activity,
      onTap: () => context.push('/activity/${activity.id}'),
      onJoin: () => context.push('/activity/${activity.id}'),
      onConfirm: () => context.push('/activity/${activity.id}'),
      showActions: false,
    );
  }
}

