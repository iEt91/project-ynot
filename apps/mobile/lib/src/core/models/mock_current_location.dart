import 'package:google_maps_flutter/google_maps_flutter.dart';

class MockCurrentLocationOption {
  const MockCurrentLocationOption({
    required this.key,
    required this.label,
    this.latitude,
    this.longitude,
    this.useMapCenter = false,
  });

  final String key;
  final String label;
  final double? latitude;
  final double? longitude;
  final bool useMapCenter;

  bool get isMapCenter => useMapCenter;

  LatLng resolve(LatLng fallback) {
    if (useMapCenter) {
      return fallback;
    }
    return LatLng(latitude ?? fallback.latitude, longitude ?? fallback.longitude);
  }
}

const String kMockCurrentLocationKeySeoul = 'seoul';
const String kMockCurrentLocationKeyHongdae = 'hongdae';
const String kMockCurrentLocationKeyGangnam = 'gangnam';
const String kMockCurrentLocationKeyMadrid = 'madrid';
const String kMockCurrentLocationKeyBarcelona = 'barcelona';
const String kMockCurrentLocationKeyMapCenter = 'map_center';

const List<MockCurrentLocationOption> kMockCurrentLocationOptions = [
  MockCurrentLocationOption(
    key: kMockCurrentLocationKeySeoul,
    label: 'Seoul',
    latitude: 37.5666,
    longitude: 126.978,
  ),
  MockCurrentLocationOption(
    key: kMockCurrentLocationKeyHongdae,
    label: 'Hongdae',
    latitude: 37.5563,
    longitude: 126.9236,
  ),
  MockCurrentLocationOption(
    key: kMockCurrentLocationKeyGangnam,
    label: 'Gangnam',
    latitude: 37.4981,
    longitude: 127.0276,
  ),
  MockCurrentLocationOption(
    key: kMockCurrentLocationKeyMadrid,
    label: 'Madrid',
    latitude: 40.4168,
    longitude: -3.7038,
  ),
  MockCurrentLocationOption(
    key: kMockCurrentLocationKeyBarcelona,
    label: 'Barcelona',
    latitude: 41.3851,
    longitude: 2.1734,
  ),
  MockCurrentLocationOption(
    key: kMockCurrentLocationKeyMapCenter,
    label: 'Usar centro actual del mapa',
    useMapCenter: true,
  ),
];

MockCurrentLocationOption mockCurrentLocationOptionFromKey(String? key) {
  return kMockCurrentLocationOptions.firstWhere(
    (option) => option.key == key,
    orElse: () => kMockCurrentLocationOptions.first,
  );
}
