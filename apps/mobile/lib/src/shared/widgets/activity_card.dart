import 'package:flutter/material.dart';

import '../../core/models/activity.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import 'kawaii_avatar.dart';
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
    this.onShare,
  });

  final Activity activity;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final VoidCallback onConfirm;
  final bool showActions;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final distance = distanceKm(
      lat1: 37.5666,
      lng1: 126.9780,
      lat2: activity.displayLat,
      lng2: activity.displayLng,
    );

    final statusLabel = switch (activity.status) {
      ActivityStatus.pendingModeration => 'En revisión',
      ActivityStatus.open => 'Abierta',
      ActivityStatus.active => 'Abierta',
      ActivityStatus.full => 'Llena',
      ActivityStatus.ongoing => 'En curso',
      ActivityStatus.finished => 'Terminada',
      ActivityStatus.archived => 'Terminada',
      ActivityStatus.cancelled => 'Cancelada',
      ActivityStatus.flagged => 'Atenta',
      ActivityStatus.removed => 'Oculta',
      ActivityStatus.rejectedHidden => 'Oculta',
      ActivityStatus.draft => 'Borrador',
    };

    return GestureDetector(
      onTap: onTap,
      child: KawaiiCard(
        gradient: LinearGradient(
          colors: [
            colors.surface.withValues(alpha: 0.96),
            colors.surface.withValues(alpha: 0.84),
            colors.primary.withValues(alpha: 0.07),
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
                KawaiiAvatar(
                  emoji: activity.emoji,
                  size: 58,
                  accentColor: _categoryColor(colors, activity.category),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          StatusPill(
                            label: statusLabel,
                            color: _categoryColor(colors, activity.category),
                          ),
                          if (onShare != null) ...[
                            const SizedBox(width: 8),
                            _IconChipButton(
                              icon: Icons.ios_share_rounded,
                              onTap: () {
                                onShare!.call();
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${activity.zone} · ${formatTimeRange(activity.startTime, activity.endTime)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: '${activity.confirmedCount}/${activity.maxPeople} asistentes',
                  color: colors.secondary,
                ),
                StatusPill(
                  label: activity.vibe,
                  color: colors.tertiary,
                ),
                StatusPill(
                  label: '${distance.toStringAsFixed(1)} km',
                  color: colors.primary,
                ),
              ],
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                activity.description,
                style: theme.textTheme.bodyMedium?.copyWith(
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
                      child: Text(activity.isJoinable ? 'Me apunto' : 'Llena'),
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
                            ? 'Confirmar'
                            : 'Ver detalle',
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

  Color _categoryColor(ColorScheme colors, String category) {
    return switch (category) {
      'Coffee' => colors.primary,
      'Study' => colors.secondary,
      'Walks' => colors.tertiary,
      'Food' => const Color(0xFFFFB86B),
      'Art' => const Color(0xFFB18CFF),
      'Music' => const Color(0xFF63D2FF),
      _ => colors.primary,
    };
  }
}

class _IconChipButton extends StatelessWidget {
  const _IconChipButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
