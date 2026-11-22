import 'package:flutter_test/flutter_test.dart';
import 'package:city_vibe_explorer/models/place.dart';

Place _buildPlace() {
  return Place(
    id: 'test_1',
    name: 'Test Spot',
    category: 'Cafe',
    moods: const ['foodie', 'chill'],
    latitude: 26.9196,
    longitude: 75.8115,
    rating: 4.5,
    userRatingsTotal: 100,
    visualScore: 90,
    imageUrl: 'https://example.com/image.jpg',
    address: 'Somewhere, Jaipur',
    description: 'A test place.',
    mustTry: 'Chai',
  );
}

void main() {
  group('Place.copyWith', () {
    test('overrides distance without mutating the original', () {
      final original = _buildPlace();
      expect(original.distanceInKm, isNull);

      final copy = original.copyWith(distanceInKm: 3.5);
      expect(copy.distanceInKm, 3.5);
      expect(original.distanceInKm, isNull,
          reason: 'copyWith must not mutate the shared curated object');
      expect(copy.name, original.name);
    });

    test('keeps existing distance when none is provided', () {
      final copy = _buildPlace().copyWith(distanceInKm: 1.2).copyWith();
      expect(copy.distanceInKm, 1.2);
    });
  });
}