import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/activity_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import 'profile_back_button.dart';

class MyActivitiesScreen extends ConsumerWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.user;
    final controller = ref.read(appControllerProvider);

    final createdActive = user == null
        ? const <Activity>[]
        : state.activities
            .where(
              (activity) =>
                  activity.creatorId == user.id &&
                  activity.isActiveLifecycle,
            )
            .toList(growable: false);
    final participatingActive = user == null
        ? const <Activity>[]
        : controller
            .activeActivitiesForUser(user.id)
            .where((activity) => activity.creatorId != user.id)
            .toList(growable: false);

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
                title: 'Mis actividades',
                subtitle: 'Lo que estás creando o viviendo ahora.',
              ),
              const SizedBox(height: 16),
              _ActivitySection(
                title: 'Creadas activas',
                emptyText: 'Aún no tienes actividades activas creadas.',
                activities: createdActive,
              ),
              const SizedBox(height: 14),
              _ActivitySection(
                title: 'Participando activamente',
                emptyText:
                    'Todavía no estás participando en ninguna actividad.',
                activities: participatingActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.emptyText,
    required this.activities,
  });

  final String title;
  final String emptyText;
  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
        ),
        if (activities.isEmpty)
          Text(
            emptyText,
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
    );
  }
}
