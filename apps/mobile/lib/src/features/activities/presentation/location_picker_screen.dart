import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/google_activity_map.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../profile/presentation/profile_back_button.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initialLocation,
  });

  final LatLng initialLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedLocation = widget.initialLocation;

  @override
  Widget build(BuildContext context) {
    final locationLabel = _zoneFromLocation(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );

    return Scaffold(
      backgroundColor: YnotTheme.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleActivityMap(
              activities: const [],
              interactive: true,
              selectedLocation: null,
              initialCameraPosition: CameraPosition(
                target: widget.initialLocation,
                zoom: 14.5,
                bearing: 0,
                tilt: 0,
              ),
              onCameraIdlePositionChanged: (position) {
                if (!mounted) return;
                setState(() {
                  _selectedLocation = position;
                });
              },
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 52,
                    color: YnotTheme.primary,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: YnotTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: YnotTheme.primary.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  ProfileBackButton(onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Elegir ubicación',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: KawaiiCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mueve el mapa para elegir el punto.',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Zona aproximada: $locationLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            context.pop(_selectedLocation);
                          },
                          child: const Text('Usar esta ubicación'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _zoneFromLocation(double lat, double lng) {
    if (lat >= 37.56 && lng < 126.95) {
      return 'Hongdae';
    }
    if (lat >= 37.54 && lng >= 126.95 && lng < 126.99) {
      return 'Yeouido';
    }
    if (lng >= 126.99) {
      return 'Gangnam';
    }
    if (lat >= 37.56) {
      return 'Seoul';
    }
    return 'Seoul';
  }
}
