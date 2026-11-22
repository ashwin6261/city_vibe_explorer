import 'package:flutter_test/flutter_test.dart';
import 'package:city_vibe_explorer/services/places_service.dart';

void main() {
  final PlacesService service = PlacesService();

  group('PlacesService.getPlaces filters', () {
    test('mood filter returns only matching places', () {
      final results = service.getPlaces(selectedMood: 'heritage');
      expect(results, isNotEmpty);
      expect(results.every((p) => p.moods.contains('heritage')), isTrue);
    });

    test('onlyVisualFood returns only visual food stalls', () {
      final results = service.getPlaces(onlyVisualFood: true);
      expect(results, isNotEmpty);
      expect(results.every((p) => p.isVisualFoodStall), isTrue);
    });

    test('onlyTopVisited returns only top visited spots', () {
      final results = service.getPlaces(onlyTopVisited: true);
      expect(results, isNotEmpty);
      expect(results.every((p) => p.isTopVisited), isTrue);
    });

    test('sorts by distance ascending when user location is provided', () {
      final results = service.getPlaces(userLat: 26.9196, userLng: 75.8115);
      expect(results, isNotEmpty);
      for (int i = 1; i < results.length; i++) {
        expect(
          results[i].distanceInKm,
          greaterThanOrEqualTo(results[i - 1].distanceInKm!),
        );
      }
    });

    test('mood + toggle filters combine with AND semantics', () {
      final results = service.getPlaces(
        selectedMood: 'foodie',
        onlyVisualFood: true,
      );
      expect(results, isNotEmpty);
      expect(
        results.every((p) => p.moods.contains('foodie') && p.isVisualFoodStall),
        isTrue,
      );
    });
  });
}