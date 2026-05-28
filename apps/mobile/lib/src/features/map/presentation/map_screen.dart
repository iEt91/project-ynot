import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final activities = ref.read(appControllerProvider).filteredActivities();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        SectionHeader(
          title: 'Dark city map',
          subtitle: 'Small moments near you, with low-pressure coordination.',
          trailing: StatusPill(
            label: '${activities.length} live',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 14),
        _FilterRow(
          selected: state.filter,
          onSelected: (filter) => ref.read(appControllerProvider).setFilter(filter),
        ),
        const SizedBox(height: 14),
        KawaiiCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 330,
            child: _MapSurface(activities: activities),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nearby activity cards',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ...activities.take(3).map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MapActivityChip(activity: activity),
              ),
            ),
      ],
    );
  }
}

class _MapSurface extends StatelessWidget {
  const _MapSurface({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final useNaver = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    if (useNaver) {
      return const _NaverMapSurface();
    }

    return _StaticMapSurface(activities: activities);
  }
}

class _NaverMapSurface extends ConsumerStatefulWidget {
  const _NaverMapSurface();

  @override
  ConsumerState<_NaverMapSurface> createState() => _NaverMapSurfaceState();
}

class _NaverMapSurfaceState extends ConsumerState<_NaverMapSurface> {
  NaverMapController? _controller;
  final Set<String> _renderedMarkerIds = {};

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(appStateProvider).activities;

    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5666, 126.9780),
          zoom: 13,
        ),
        mapType: NMapType.navi,
      ),
      onMapReady: (controller) {
        _controller = controller;
        _syncMarkers(activities);
      },
      onMapLoaded: () => _syncMarkers(activities),
    );
  }

  void _syncMarkers(List<Activity> activities) {
    final controller = _controller;
    if (controller == null) return;

    for (final activity in activities) {
      if (_renderedMarkerIds.contains(activity.id)) continue;

      _renderedMarkerIds.add(activity.id);
      controller.addOverlay(
        NMarker(
          id: activity.id,
          position: NLatLng(activity.displayLat, activity.displayLng),
          caption: NOverlayCaption(text: activity.title),
        ),
      );
    }
  }
}

class _StaticMapSurface extends StatelessWidget {
  const _StaticMapSurface({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0E1628), Color(0xFF050816)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CityGridPainter(),
            ),
          ),
          ...activities.take(5).map((activity) {
            final normalizedX = _normalize(activity.displayLng, 126.91, 127.05);
            final normalizedY = _normalize(activity.displayLat, 37.47, 37.60);
            return Positioned(
              left: 28 + normalizedX * 220,
              top: 40 + (1 - normalizedY) * 220,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.location_on_rounded, color: Colors.pinkAccent, size: 30),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: KawaiiCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Naver Map ready on mobile',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This fallback keeps the product previewable on desktop while the native map runs on Android/iOS.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _normalize(double value, double min, double max) {
    final clamped = (value - min) / (max - min);
    return clamped.clamp(0.0, 1.0);
  }
}

class _CityGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (var i = 0; i < 6; i++) {
      final y = size.height / 6 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (var i = 0; i < 6; i++) {
      final x = size.width / 6 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapActivityChip extends StatelessWidget {
  const _MapActivityChip({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final distance = distanceKm(
      lat1: 37.5666,
      lng1: 126.9780,
      lat2: activity.displayLat,
      lng2: activity.displayLng,
    );

    return KawaiiCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '${activity.zone} · ${formatTimeRange(activity.startTime, activity.endTime)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusPill(
            label: '${distance.toStringAsFixed(1)} km',
            color: Colors.pinkAccent,
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = {
      ActivityFilter.all: 'Hoy',
      ActivityFilter.coffee: 'Coffee',
      ActivityFilter.study: 'Study',
      ActivityFilter.walks: 'Walks',
      ActivityFilter.food: 'Food',
      ActivityFilter.art: 'Art',
      ActivityFilter.music: 'Music',
      ActivityFilter.calm: 'Calm',
      ActivityFilter.social: 'Social',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries
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
