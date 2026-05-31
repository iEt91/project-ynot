import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme.dart';
import '../../core/models/activity.dart';

class GoogleActivityMap extends StatefulWidget {
  const GoogleActivityMap({
    super.key,
    required this.activities,
    this.interactive = false,
    this.selectedLocation,
    this.onLocationSelected,
    this.onActivityTap,
    this.onMapInteraction,
    this.onMapLongPress,
    this.onCameraPositionChanged,
    this.animateToSelectedLocation = true,
    this.previewDismissGuardUntil,
    this.initialCameraPosition,
  });

  final List<Activity> activities;
  final bool interactive;
  final LatLng? selectedLocation;
  final ValueChanged<LatLng>? onLocationSelected;
  final ValueChanged<Activity>? onActivityTap;
  final VoidCallback? onMapInteraction;
  final ValueChanged<LatLng>? onMapLongPress;
  final ValueChanged<LatLng>? onCameraPositionChanged;
  final bool animateToSelectedLocation;
  final DateTime? previewDismissGuardUntil;
  final CameraPosition? initialCameraPosition;

  @override
  State<GoogleActivityMap> createState() => _GoogleActivityMapState();
}

class _GoogleActivityMapState extends State<GoogleActivityMap> {
  GoogleMapController? _controller;
  double _currentZoom = 12.5;
  LatLngBounds _visibleBounds = _defaultKoreaBounds;
  final Map<String, BitmapDescriptor> _activityIconCache = {};
  final Map<String, BitmapDescriptor> _clusterIconCache = {};
  BitmapDescriptor? _selectedMarker;
  bool _refreshQueued = false;
  bool _cameraGestureActive = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _queueRefresh());
  }

  @override
  void didUpdateWidget(covariant GoogleActivityMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_needsMarkerRefresh(oldWidget)) {
      _queueRefresh();
    }
    if (widget.selectedLocation != oldWidget.selectedLocation) {
      final controller = _controller;
      final selectedLocation = widget.selectedLocation;
      if (controller != null && selectedLocation != null && widget.animateToSelectedLocation) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: selectedLocation,
              zoom: 15,
              bearing: 0,
              tilt: 0,
            ),
          ),
        );
      }
      _queueRefresh();
    }
  }

  bool _needsMarkerRefresh(GoogleActivityMap oldWidget) {
    if (oldWidget.activities.length != widget.activities.length) return true;
    if (oldWidget.selectedLocation != widget.selectedLocation) return true;
    for (var i = 0; i < widget.activities.length; i++) {
      final oldActivity = oldWidget.activities[i];
      final newActivity = widget.activities[i];
      if (oldActivity.id != newActivity.id ||
          oldActivity.status != newActivity.status ||
          oldActivity.category != newActivity.category ||
          oldActivity.displayLat != newActivity.displayLat ||
          oldActivity.displayLng != newActivity.displayLng) {
        return true;
      }
    }
    return false;
  }

  void _queueRefresh() {
    if (_refreshQueued || !mounted) return;
    _refreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _refreshQueued = false;
      if (!mounted) return;
      await _refreshMarkers();
    });
  }

  Future<void> _refreshMarkers() async {
    final controller = _controller;
    if (controller != null) {
      try {
        _visibleBounds = await controller.getVisibleRegion();
      } catch (_) {
        _visibleBounds = _defaultKoreaBounds;
      }
    }

    final clusters = _clusterActivities(widget.activities, _currentZoom, _visibleBounds);
    final nextActivityIcons = Map<String, BitmapDescriptor>.from(_activityIconCache);
    final nextClusterIcons = Map<String, BitmapDescriptor>.from(_clusterIconCache);

    for (final activity in widget.activities) {
      if (!nextActivityIcons.containsKey(activity.id)) {
        nextActivityIcons[activity.id] = await _buildActivityMarker(activity);
      }
    }

    for (final cluster in clusters.where((item) => item.activities.length > 1)) {
      if (!nextClusterIcons.containsKey(cluster.cacheKey)) {
        nextClusterIcons[cluster.cacheKey] = await _buildClusterMarker(cluster);
      }
    }

    final nextSelectedMarker = widget.selectedLocation == null ? null : await _buildSelectedMarker();

    if (!mounted) return;
    setState(() {
      _activityIconCache
        ..clear()
        ..addAll(nextActivityIcons);
      _clusterIconCache
        ..clear()
        ..addAll(nextClusterIcons);
      _selectedMarker = nextSelectedMarker;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clusters = _clusterActivities(widget.activities, _currentZoom, _visibleBounds);
    final markers = <Marker>{
      for (final cluster in clusters)
        if (cluster.activities.length == 1)
          _buildActivityMarkerWidget(cluster.activities.first)
        else
          _buildClusterMarkerWidget(cluster),
      if (widget.interactive && widget.selectedLocation != null)
        Marker(
          markerId: const MarkerId('selected_location'),
          position: widget.selectedLocation!,
          icon: _selectedMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 999,
        ),
    };

    return GoogleMap(
      initialCameraPosition: widget.initialCameraPosition ??
          const CameraPosition(
            target: LatLng(37.5666, 126.9780),
            zoom: 12.5,
          ),
      onMapCreated: (controller) {
        _controller = controller;
        _queueRefresh();
      },
      onCameraMoveStarted: () {
        _cameraGestureActive = DateTime.now().isAfter(widget.previewDismissGuardUntil ?? DateTime.fromMillisecondsSinceEpoch(0));
      },
      onCameraMove: (position) {
        widget.onCameraPositionChanged?.call(position.target);
        if ((position.zoom - _currentZoom).abs() > 0.05) {
          setState(() {
            _currentZoom = position.zoom;
          });
        }
      },
      onCameraIdle: () {
        final dismissGuardActive = DateTime.now().isBefore(widget.previewDismissGuardUntil ?? DateTime.fromMillisecondsSinceEpoch(0));
        if (_cameraGestureActive && !dismissGuardActive) {
          widget.onMapInteraction?.call();
        }
        _cameraGestureActive = false;
        _queueRefresh();
      },
      style: _darkMapStyle,
      markers: markers,
      onTap: widget.onMapInteraction == null ? null : (_) => widget.onMapInteraction!.call(),
      onLongPress: widget.interactive && widget.onLocationSelected != null
          ? (position) => widget.onLocationSelected!(position)
          : widget.onMapLongPress != null
              ? (position) => widget.onMapLongPress!(position)
              : null,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      padding: const EdgeInsets.all(22),
    );
  }

  Marker _buildActivityMarkerWidget(Activity activity) {
    final icon = _activityIconCache[activity.id] ?? BitmapDescriptor.defaultMarkerWithHue(_fallbackHue(activity));
    return Marker(
      markerId: MarkerId(activity.id),
      position: LatLng(activity.displayLat, activity.displayLng),
      onTap: widget.onActivityTap == null
          ? null
          : () {
              widget.onActivityTap!(activity);
            },
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      zIndexInt: activity.status == ActivityStatus.ongoing ? 3 : 1,
    );
  }

  Marker _buildClusterMarkerWidget(_ClusterGroup cluster) {
    final icon = _clusterIconCache[cluster.cacheKey] ??
        BitmapDescriptor.defaultMarkerWithHue(_fallbackHue(cluster.activities.first));
    return Marker(
      markerId: MarkerId('cluster_${cluster.cacheKey}'),
      position: cluster.position,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 1000 + cluster.activities.length,
      onTap: () {
        final nextZoom = _clusterZoomTarget(_currentZoom);
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: cluster.position,
              zoom: nextZoom,
              bearing: 0,
              tilt: 0,
            ),
          ),
        );
      },
    );
  }

  Future<BitmapDescriptor> _buildActivityMarker(Activity activity) async {
    final accent = _categoryColor(activity.category);
    return _buildBubbleMarker(
      emoji: activity.emoji,
      accent: accent,
      showPulse: activity.status == ActivityStatus.ongoing,
      solid: true,
    );
  }

  Future<BitmapDescriptor> _buildSelectedMarker() async {
    return _buildBubbleMarker(
      emoji: '\u{1F4CD}',
      accent: YnotTheme.primary,
      showPulse: true,
      selected: true,
      solid: true,
    );
  }

  Future<BitmapDescriptor> _buildClusterMarker(_ClusterGroup cluster) async {
    final accent = _clusterAccent(cluster.activities.first);
    return _buildClusterBubbleMarker(
      count: cluster.activities.length,
      accent: accent,
    );
  }

  Future<BitmapDescriptor> _buildBubbleMarker({
    required String emoji,
    required Color accent,
    bool showPulse = false,
    bool selected = false,
    bool solid = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 150.0;
    final center = Offset(size / 2, size / 2);

    if (showPulse) {
      canvas.drawCircle(
        center,
        54,
        Paint()
          ..color = accent.withValues(alpha: 0.26)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
      canvas.drawCircle(
        center,
        68,
        Paint()
          ..color = accent.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    } else {
      canvas.drawCircle(
        center,
        50,
        Paint()
          ..color = accent.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    final bubbleRadius = 48.0;
    final bubblePaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        bubbleRadius,
        [
          accent.withValues(alpha: selected || solid ? 1.0 : 0.95),
          const Color(0xFF141B2D),
        ],
      );
    canvas.drawCircle(center, bubbleRadius, bubblePaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = accent.withValues(alpha: 0.95);
    canvas.drawCircle(center, bubbleRadius, borderPaint);

    final innerGlowPaint = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 28, innerGlowPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: selected ? 48 : 42,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 1,
      ),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    // ignore: deprecated_member_use
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _buildClusterBubbleMarker({
    required int count,
    required Color accent,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 150.0;
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      54,
      Paint()
        ..color = accent.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
      center,
      42,
      Paint()
        ..color = accent.withValues(alpha: 1.0),
    );

    canvas.drawCircle(
      center,
      42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = accent.withValues(alpha: 0.34),
    );

    final label = count > 99 ? '99+' : '$count';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 34,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 1),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    // ignore: deprecated_member_use
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  double _fallbackHue(Activity activity) {
    if (activity.status == ActivityStatus.ongoing) {
      return BitmapDescriptor.hueGreen;
    }
    if (activity.status == ActivityStatus.full) {
      return BitmapDescriptor.hueAzure;
    }
    if (activity.status == ActivityStatus.pendingModeration) {
      return BitmapDescriptor.hueYellow;
    }
    return switch (activity.category) {
      'Coffee' => BitmapDescriptor.hueRose,
      'Study' => BitmapDescriptor.hueAzure,
      'Walks' => BitmapDescriptor.hueGreen,
      'Food' => BitmapDescriptor.hueOrange,
      'Art' => BitmapDescriptor.hueViolet,
      'Music' => BitmapDescriptor.hueYellow,
      _ => BitmapDescriptor.hueRose,
    };
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

  Color _clusterAccent(Activity activity) {
    return _categoryColor(activity.category);
  }

  List<_ClusterGroup> _clusterActivities(List<Activity> activities, double zoom, LatLngBounds bounds) {
    if (activities.isEmpty) {
      return const [];
    }

    final visibleActivities = activities.where((activity) => _isWithinBounds(activity, bounds)).toList();
    if (visibleActivities.isEmpty) {
      return const [];
    }
    final source = visibleActivities;
    final divisions = _clusterDivisionsForZoom(zoom);
    final latSpan = (bounds.northeast.latitude - bounds.southwest.latitude).abs().clamp(0.01, 180.0);
    final buckets = <String, List<Activity>>{};
    for (final activity in source) {
      final latRatio = ((activity.displayLat - bounds.southwest.latitude) / latSpan).clamp(0.0, 0.999999);
      final lngRatio = _normalizedLongitudeRatio(activity.displayLng, bounds).clamp(0.0, 0.999999);
      final latBucket = (latRatio * divisions).floor();
      final lngBucket = (lngRatio * divisions).floor();
      final key = '$latBucket:$lngBucket';
      buckets.putIfAbsent(key, () => []).add(activity);
    }

    return buckets.entries.map((entry) {
      final groupActivities = entry.value;
      final avgLat = groupActivities.map((a) => a.displayLat).reduce((a, b) => a + b) / groupActivities.length;
      final avgLng = groupActivities.map((a) => a.displayLng).reduce((a, b) => a + b) / groupActivities.length;
      return _ClusterGroup(
        cacheKey: '${divisions}_${entry.key}',
        position: LatLng(avgLat, avgLng),
        activities: groupActivities,
      );
    }).toList();
  }

  bool _isWithinBounds(Activity activity, LatLngBounds bounds) {
    final south = bounds.southwest.latitude <= bounds.northeast.latitude ? bounds.southwest.latitude : bounds.northeast.latitude;
    final north = bounds.southwest.latitude <= bounds.northeast.latitude ? bounds.northeast.latitude : bounds.southwest.latitude;
    final west = bounds.southwest.longitude <= bounds.northeast.longitude ? bounds.southwest.longitude : bounds.northeast.longitude;
    final east = bounds.southwest.longitude <= bounds.northeast.longitude ? bounds.northeast.longitude : bounds.southwest.longitude;
    return activity.displayLat >= south &&
        activity.displayLat <= north &&
        activity.displayLng >= west &&
        activity.displayLng <= east;
  }

  double _normalizedLongitudeRatio(double lng, LatLngBounds bounds) {
    final west = bounds.southwest.longitude;
    final span = _longitudeSpan(bounds);
    if (span <= 0) {
      return 0.5;
    }
    return (lng - west) / span;
  }

  double _longitudeSpan(LatLngBounds bounds) {
    final west = bounds.southwest.longitude;
    final east = bounds.northeast.longitude;
    final span = (east - west).abs();
    return span < 0.01 ? 0.01 : span;
  }

  int _clusterDivisionsForZoom(double zoom) {
    if (zoom <= 7) return 2;
    if (zoom <= 10) return 4;
    if (zoom <= 13) return 8;
    return 16;
  }

  double _clusterZoomTarget(double zoom) {
    if (zoom <= 7) return 9.0;
    if (zoom <= 10) return 11.5;
    if (zoom <= 13) return 14.5;
    return (zoom + 1.5).clamp(0.0, 20.0);
  }
}

final LatLngBounds _defaultKoreaBounds = LatLngBounds(
  southwest: LatLng(33.0, 124.0),
  northeast: LatLng(39.8, 132.5),
);

class _ClusterGroup {
  const _ClusterGroup({
    required this.cacheKey,
    required this.position,
    required this.activities,
  });

  final String cacheKey;
  final LatLng position;
  final List<Activity> activities;
}

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#07101F"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#B8C4D6"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#07101F"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#23314A"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#D6DEEA"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#C6D0DF"}]},
  {"featureType":"administrative.neighborhood","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#081224"}]},
  {"featureType":"landscape.man_made","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#081224"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.attraction","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.government","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.medical","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.school","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.sports_complex","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1E4D38"},{"visibility":"on"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1D2A42"}]},
  {"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#263A5A"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#22314D"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#102D4F"}]}
]
''';
