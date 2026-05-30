import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/activity_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.user;
    final activities = user == null
        ? const <Activity>[]
        : ref.read(appControllerProvider).historyActivitiesForUser(user.id);

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              const SectionHeader(
                title: 'Historial',
                subtitle: 'Actividades terminadas y archivadas.',
              ),
              const SizedBox(height: 16),
              if (activities.isEmpty)
                Text(
                  'Todavía no hay actividades en tu historial.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                ...activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActivityCard(
                      activity: activity,
                      onTap: () => context.push('/activity/${activity.id}'),
                      onJoin: () => context.push('/activity/${activity.id}'),
                      onConfirm: () => context.push('/chat/${activity.id}'),
                      showActions: false,
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
