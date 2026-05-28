import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/activity_card.dart';
import '../../../shared/widgets/section_header.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final activities = ref.read(appControllerProvider).filteredActivities();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        SectionHeader(
          title: 'Activities',
          subtitle: 'The same city signals, now in list form.',
          trailing: TextButton(
            onPressed: () => context.push('/create-activity'),
            child: const Text('Create'),
          ),
        ),
        const SizedBox(height: 14),
        _FilterRow(
          selected: state.filter,
          onSelected: (filter) => ref.read(appControllerProvider).setFilter(filter),
        ),
        const SizedBox(height: 14),
        if (activities.isEmpty)
          const _EmptyActivities()
        else
          ...activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActivityCard(
                activity: activity,
                showActions: true,
                onTap: () => context.push('/activity/${activity.id}'),
                onJoin: () => ref.read(appControllerProvider).joinActivity(activity.id),
                onConfirm: () => ref.read(appControllerProvider).confirmAttendance(activity.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = {
      ActivityFilter.all: 'All',
      ActivityFilter.coffee: 'Coffee',
      ActivityFilter.study: 'Study',
      ActivityFilter.walks: 'Walks',
      ActivityFilter.food: 'Food',
      ActivityFilter.calm: 'Calm',
      ActivityFilter.social: 'Social',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(entry.value),
                  selected: selected == entry.key,
                  onSelected: (_) => onSelected(entry.key),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(
        child: Text('No activities in this filter yet.'),
      ),
    );
  }
}
