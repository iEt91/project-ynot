import 'package:flutter/material.dart';

import '../../core/models/activity.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import 'kawaii_card.dart';
import 'status_pill.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onJoin,
    required this.onConfirm,
    required this.showActions,
  });

  final Activity activity;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final VoidCallback onConfirm;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final distance = distanceKm(
      lat1: 37.5666,
      lng1: 126.9780,
      lat2: activity.displayLat,
      lng2: activity.displayLng,
    );

    final statusLabel = switch (activity.status) {
      ActivityStatus.pendingModeration => 'Pending',
      ActivityStatus.active => 'Open',
      ActivityStatus.full => 'Full',
      ActivityStatus.ongoing => 'Ongoing',
      ActivityStatus.finished => 'Finished',
      ActivityStatus.cancelled => 'Cancelled',
      ActivityStatus.flagged => 'Flagged',
      ActivityStatus.removed => 'Removed',
      ActivityStatus.rejectedHidden => 'Hidden',
      ActivityStatus.draft => 'Draft',
    };

    return GestureDetector(
      onTap: onTap,
      child: KawaiiCard(
        gradient: LinearGradient(
          colors: [
            colors.surface,
            colors.surface.withValues(alpha: 0.86),
            colors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activity.zone} · ${formatTimeRange(activity.startTime, activity.endTime)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusPill(label: statusLabel),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: '${activity.confirmedCount}/${activity.maxPeople}',
                  color: colors.secondary,
                ),
                StatusPill(
                  label: activity.vibe,
                  color: colors.tertiary,
                ),
                StatusPill(
                  label: '${distance.toStringAsFixed(1)} km',
                  color: Colors.pinkAccent,
                ),
              ],
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                activity.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: activity.isJoinable ? onJoin : null,
                      child: const Text('Join'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: activity.myStatus == ParticipantStatus.joinedPendingConfirmation
                          ? onConfirm
                          : onTap,
                      child: Text(
                        activity.myStatus == ParticipantStatus.joinedPendingConfirmation
                            ? 'Confirm'
                            : 'Details',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
