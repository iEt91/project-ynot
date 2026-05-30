import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/google_maps_support.dart';
import '../../../shared/widgets/google_activity_map.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_bottom_nav.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Activity? _selectedActivity;
  DateTime _previewDismissGuardUntil = DateTime.fromMillisecondsSinceEpoch(0);
  LatLng _cameraTarget = const LatLng(37.5666, 126.9780);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activities = ref.read(appControllerProvider).filteredActivities();
    final bottomPadding = MediaQuery.of(context).padding.bottom + KawaiiBottomNav.dockHeight + 12.0;
    final fabBottom = MediaQuery.of(context).padding.bottom + KawaiiBottomNav.dockHeight + 24.0;

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
                    'Mapa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Text(
                      kAppVisibleVersion,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _FilterRow(
                selected: state.filter,
                onSelected: (filter) {
                  ref.read(appControllerProvider).setFilter(filter);
                  _dismissSelectedActivity();
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: canUseGoogleMaps()
                        ? GoogleActivityMap(
                            activities: activities,
                            onActivityTap: _selectActivity,
                            onMapInteraction: _dismissSelectedActivity,
                            onMapLongPress: (position) {
                              context.push(
                                '/create-activity',
                                extra: position,
                              );
                            },
                            onCameraPositionChanged: (position) {
                              setState(() => _cameraTarget = position);
                            },
                            previewDismissGuardUntil: _previewDismissGuardUntil,
                          )
                        : _FallbackMap(
                            activities: activities,
                            onActivityTap: _selectActivity,
                          ),
                  ),
                  if (_selectedActivity != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: bottomPadding,
                      child: _SelectedActivityCard(
                        activity: _selectedActivity!,
                        onTap: () => context.push('/activity/${_selectedActivity!.id}'),
                      ),
                    ),
                  Positioned(
                    right: 18,
                    bottom: fabBottom,
                    child: FloatingActionButton(
                      heroTag: 'create_activity_fab',
                      onPressed: () => context.push(
                        '/create-activity',
                        extra: _cameraTarget,
                      ),
                      backgroundColor: YnotTheme.primary,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectActivity(Activity activity) {
    setState(() {
      _selectedActivity = activity;
      _previewDismissGuardUntil = DateTime.now().add(const Duration(milliseconds: 450));
    });
  }

  void _dismissSelectedActivity() {
    if (_selectedActivity == null) return;
    setState(() => _selectedActivity = null);
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
  });

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = {
      ActivityFilter.all: 'Todas',
      ActivityFilter.coffee: 'Café',
      ActivityFilter.study: 'Estudio',
      ActivityFilter.walks: 'Paseos',
      ActivityFilter.food: 'Comida',
      ActivityFilter.art: 'Arte',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
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

class _SelectedActivityCard extends StatelessWidget {
  const _SelectedActivityCard({
    required this.activity,
    required this.onTap,
  });

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(12),
      gradient: LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.52),
          YnotTheme.surface.withValues(alpha: 0.80),
        ],
      ),
      child: Row(
        children: [
          KawaiiAvatar(
            emoji: activity.emoji,
            size: 56,
            accentColor: _categoryColor(activity.category),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatHour(activity.startTime)} · ${activity.zone}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniMeta(text: '${activity.confirmedCount}/${activity.maxPeople} asistentes'),
                    _MiniMeta(text: activity.vibe),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onTap,
            child: const Text('Ver detalle'),
          ),
        ],
      ),
    );
  }

  String _formatHour(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'Coffee' => YnotTheme.primary,
      'Study' => YnotTheme.purple,
      'Walks' => YnotTheme.mint,
      'Food' => const Color(0xFFFFB86B),
      'Art' => const Color(0xFFB18CFF),
      'Music' => const Color(0xFF63D2FF),
      _ => YnotTheme.primary,
    };
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _FallbackMap extends StatelessWidget {
  const _FallbackMap({
    required this.activities,
    required this.onActivityTap,
  });

  final List<Activity> activities;
  final ValueChanged<Activity> onActivityTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF050812), Color(0xFF0B1326)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NightCityPainter(),
            ),
          ),
          ...activities.take(5).map((activity) {
            final normalizedX = _normalize(activity.displayLng, 126.91, 127.05);
            final normalizedY = _normalize(activity.displayLat, 37.47, 37.60);
            return Positioned(
              left: 28 + normalizedX * 220,
              top: 42 + (1 - normalizedY) * 220,
              child: GestureDetector(
                onTap: () => onActivityTap(activity),
                child: Column(
                  children: [
                    KawaiiAvatar(
                      emoji: activity.emoji,
                      size: 52,
                      accentColor: _categoryColor(activity.category),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.title,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  double _normalize(double value, double min, double max) {
    final clamped = (value - min) / (max - min);
    return clamped.clamp(0.0, 1.0);
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'Coffee' => YnotTheme.primary,
      'Study' => YnotTheme.purple,
      'Walks' => YnotTheme.mint,
      'Food' => const Color(0xFFFFB86B),
      'Art' => const Color(0xFFB18CFF),
      'Music' => const Color(0xFF63D2FF),
      _ => YnotTheme.primary,
    };
  }
}

class _NightCityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.33),
      120,
      Paint()
        ..color = YnotTheme.primary.withValues(alpha: 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.62),
      100,
      Paint()
        ..color = YnotTheme.purple.withValues(alpha: 0.025)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final blocksPaint = Paint()..color = Colors.white.withValues(alpha: 0.015);
    final blocks = <Rect>[
      Rect.fromLTWH(24, 26, 72, 54),
      Rect.fromLTWH(122, 18, 92, 72),
      Rect.fromLTWH(246, 38, 82, 58),
      Rect.fromLTWH(66, 126, 68, 50),
      Rect.fromLTWH(174, 122, 116, 82),
      Rect.fromLTWH(18, 232, 86, 70),
      Rect.fromLTWH(140, 226, 92, 58),
      Rect.fromLTWH(258, 216, 74, 60),
      Rect.fromLTWH(74, 318, 118, 64),
      Rect.fromLTWH(222, 318, 100, 56),
    ];
    for (final rect in blocks) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)), blocksPaint);
    }

    roadPaint.color = Colors.white.withValues(alpha: 0.09);
    roadPaint.strokeWidth = 18;
    canvas.drawPath(
      Path()
        ..moveTo(12, 74)
        ..quadraticBezierTo(size.width * 0.25, 58, size.width * 0.48, 84)
        ..quadraticBezierTo(size.width * 0.68, 106, size.width - 18, 92),
      roadPaint,
    );

    roadPaint.color = Colors.white.withValues(alpha: 0.065);
    roadPaint.strokeWidth = 14;
    canvas.drawPath(
      Path()
        ..moveTo(30, size.height * 0.42)
        ..quadraticBezierTo(size.width * 0.28, size.height * 0.36, size.width * 0.52, size.height * 0.45)
        ..quadraticBezierTo(size.width * 0.75, size.height * 0.55, size.width - 24, size.height * 0.5),
      roadPaint,
    );

    roadPaint.color = Colors.white.withValues(alpha: 0.05);
    roadPaint.strokeWidth = 12;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.12, size.height - 18)
        ..quadraticBezierTo(size.width * 0.24, size.height * 0.74, size.width * 0.38, size.height * 0.64)
        ..quadraticBezierTo(size.width * 0.55, size.height * 0.52, size.width * 0.76, size.height * 0.38)
        ..quadraticBezierTo(size.width * 0.88, size.height * 0.30, size.width - 18, size.height * 0.2),
      roadPaint,
    );

    final minorRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      final y = 42.0 + i * 68;
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), minorRoadPaint);
    }
    for (var i = 0; i < 4; i++) {
      final x = 44.0 + i * 78;
      canvas.drawLine(Offset(x, 18), Offset(x, size.height - 18), minorRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
