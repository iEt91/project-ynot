import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref
        .watch(appStateProvider)
        .activities
        .where((item) => item.id == activityId)
        .firstOrNull;

    if (activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity')),
        body: const Center(child: Text('Activity not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Activity details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionHeader(
            title: activity.title,
            subtitle: '${activity.zone} · ${formatTimeRange(activity.startTime, activity.endTime)}',
          ),
          const SizedBox(height: 14),
          KawaiiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(label: activity.vibe),
                    StatusPill(label: '${activity.confirmedCount}/${activity.maxPeople}'),
                    StatusPill(label: activity.status.name),
                  ],
                ),
                const SizedBox(height: 14),
                Text(activity.description),
                const SizedBox(height: 14),
                Text('Created by ${activity.creatorLabel}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          KawaiiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: activity.isJoinable
                      ? () => ref.read(appControllerProvider).joinActivity(activity.id)
                      : null,
                  child: const Text('Join activity'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: activity.myStatus == ParticipantStatus.joinedPendingConfirmation
                      ? () => ref.read(appControllerProvider).confirmAttendance(activity.id)
                      : null,
                  child: const Text('Confirm attendance'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Location exact unlocks at ${formatTimeOfDay(activity.exactLocationUnlockAt)}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
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
