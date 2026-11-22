import 'package:flutter_test/flutter_test.dart';
import 'package:city_vibe_explorer/models/place.dart';

void main() {
  group('Place.fromGooglePlace', () {
    test('cafe is tagged foodie/chill and is a visual food stall', () {
      final Place p = Place.fromGooglePlace({
        'id': 'abc',
        'displayName': {'text': 'Cafe Coffee Day'},
        'formattedAddress': 'Somewhere, Jaipur',
        'location': {'latitude': 26.9, 'longitude': 75.8},
        'rating': 4.2,
        'userRatingCount': 500,
        'types': ['cafe', 'food'],
      });
      expect(p.isVisualFoodStall, isTrue);
      expect(p.moods, contains('foodie'));
      expect(p.moods, contains('chill'));
      expect(p.isTopVisited, isFalse);
    });

    test('tourist attraction is heritage, not a food stall', () {
      final Place p = Place.fromGooglePlace({
        'id': 'xyz',
        'displayName': {'text': 'Some Fort'},
        'location': {'latitude': 26.9, 'longitude': 75.8},
        'rating': 4.7,
        'userRatingCount': 5000,
        'types': ['tourist_attraction'],
      });
      expect(p.isVisualFoodStall, isFalse);
      expect(p.moods, contains('heritage'));
      expect(p.moods, contains('visual'));
      expect(p.isTopVisited, isTrue);
    });

    test('parses location from geometry.location (legacy shape)', () {
      final Place p = Place.fromGooglePlace({
        'place_id': 'legacy',
        'name': 'Legacy Spot',
        'geometry': {
          'location': {'lat': 26.91, 'lng': 75.81},
        },
        'rating': 4.0,
        'types': ['restaurant'],
      });
      expect(p.latitude, 26.91);
      expect(p.longitude, 75.81);
      expect(p.isVisualFoodStall, isTrue);
    });
  });

  group('Place.fromOverpass', () {
    test('derives category, moods, rating from tags', () {
      final Place p = Place.fromOverpass({
        'type': 'node',
        'id': 123,
        'lat': 26.9,
        'lon': 75.8,
        'tags': {'name': 'Some Museum', 'tourism': 'museum', 'wikidata': 'Q1'},
      });
      expect(p.name, 'Some Museum');
      expect(p.category.toLowerCase(), contains('museum'));
      expect(p.moods, contains('heritage'));
      expect(p.rating, greaterThan(0));
      expect(p.visualScore, greaterThan(0));
    });

    test('restaurant is a foodie visual food stall', () {
      final Place p = Place.fromOverpass({
        'type': 'way',
        'id': 9,
        'center': {'lat': 26.9, 'lon': 75.8},
        'tags': {'name': 'Dhaba', 'amenity': 'restaurant', 'cuisine': 'indian'},
      });
      expect(p.latitude, 26.9);
      expect(p.moods, contains('foodie'));
      expect(p.isVisualFoodStall, isTrue);
    });
  });
}