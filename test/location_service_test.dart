import 'package:flutter_test/flutter_test.dart';
import 'package:city_vibe_explorer/services/location_service.dart';

void main() {
  group('LocationService.calculateDistanceInKm', () {
    test('identical coordinates are zero km apart', () {
      final d = LocationService.calculateDistanceInKm(26.9196, 75.8115, 26.9196, 75.8115);
      expect(d, closeTo(0.0, 1e-6));
    });

    test('Jaipur center to Hawa Mahal is a plausible ~1-2.5 km', () {
      final d = LocationService.calculateDistanceInKm(26.9196, 75.8115, 26.9239, 75.8267);
      expect(d, greaterThan(1.0));
      expect(d, lessThan(2.5));
    });
  });
}