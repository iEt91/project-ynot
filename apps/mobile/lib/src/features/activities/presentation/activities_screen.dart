import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/geo.dart';
import '../../../shared/widgets/activity_filters_sheet.dart';
import '../../../shared/widgets/activity_search_field.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/status_pill.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final activities = ref.read(appControllerProvider).filteredActivities();

    return KawaiiScene(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Row(
                children: [
                  Text(
                    'Actividades',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const Spacer(),
                  ActivityFiltersHeaderButton(
                    onPressed: () => showActivityFiltersSheet(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: ActivitySearchField(
                value: state.activitySearchQuery,
                onChanged: (value) {
                  ref.read(appControllerProvider).setActivitySearchQuery(value);
                },
              ),
            ),
            Expanded(
              child: activities.isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        child: KawaiiEmptyState(
                          emoji: '✨',
                          title: state.activitySearchQuery.trim().isNotEmpty
                              ? 'No encontramos actividades con esa búsqueda.'
                              : 'No encontramos actividades con esos filtros.',
                          message: state.activitySearchQuery.trim().isNotEmpty
                              ? 'Prueba otra palabra clave o limpia la búsqueda para ver más momentos.'
                              : 'Prueba limpiar filtros o crea un momento nuevo para llenar el mapa.',
                          ctaLabel: 'Crear actividad',
                          onCtaPressed: () => context.push('/create-activity'),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 132),
                      itemCount: activities.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        final route = activity.isJoinedOrConfirmed
                            ? '/chat/${activity.id}'
                            : '/activity/${activity.id}';
                        return _ActivityListItem(
                          activity: activity,
                          onTap: () => context.push(route),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  const _ActivityListItem({
    required this.activity,
    required this.onTap,
  });

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distance = distanceKm(
      lat1: 37.5666,
      lng1: 126.9780,
      lat2: activity.displayLat,
      lng2: activity.displayLng,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            KawaiiAvatar(
              emoji: activity.emoji,
              size: 48,
              accentColor: _categoryColor(activity.category),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                      activity.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusPill(
                        label: _statusLabel(activity.status),
                        color: _statusColor(activity.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetaText(text: '${_formatDate(activity.startTime)} · ${_formatHour(activity.startTime)}'),
                      _MetaText(text: '${distance.toStringAsFixed(distance < 1 ? 2 : 1)} km'),
                      _MetaText(text: '${activity.confirmedCount}/${activity.maxPeople} asistentes'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 28),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime time) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${time.day} ${months[time.month - 1]}';
  }

  String _formatHour(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'Coffee' => const Color(0xFFFF5DB8),
      'Study' => const Color(0xFF8B5CF6),
      'Walks' => const Color(0xFF63E6BE),
      'Food' => const Color(0xFFFFB86B),
      'Art' => const Color(0xFFB18CFF),
      'Music' => const Color(0xFF63D2FF),
      _ => const Color(0xFFFF5DB8),
    };
  }

  Color _statusColor(ActivityStatus status) {
    return switch (status) {
      ActivityStatus.pendingModeration => const Color(0xFF8B5CF6),
      ActivityStatus.open => const Color(0xFFFF5DB8),
      ActivityStatus.active => const Color(0xFFFF5DB8),
      ActivityStatus.full => const Color(0xFFFFB86B),
      ActivityStatus.ongoing => const Color(0xFF63E6BE),
      ActivityStatus.finished => Colors.white54,
      ActivityStatus.archived => Colors.white54,
      ActivityStatus.cancelled => const Color(0xFFEF4444),
      ActivityStatus.flagged => const Color(0xFFFB7185),
      ActivityStatus.removed => Colors.white54,
      ActivityStatus.rejectedHidden => Colors.white54,
      ActivityStatus.draft => Colors.white54,
    };
  }

  String _statusLabel(ActivityStatus status) {
    return switch (status) {
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
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
