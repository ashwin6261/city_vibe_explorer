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

    test('sorts by star rating descending', () {
      final results = service.getPlaces();
      expect(results, isNotEmpty);
      for (int i = 1; i < results.length; i++) {
        expect(results[i].rating, lessThanOrEqualTo(results[i - 1].rating));
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

    test('includeCurated false drops the curated set', () {
      expect(service.getPlaces(includeCurated: false), isEmpty);
      expect(service.getPlaces().isNotEmpty, isTrue);
    });
  });
}