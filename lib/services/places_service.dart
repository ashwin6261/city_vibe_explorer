import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import '../data/curated_places.dart';
import 'location_service.dart';

/// PlacesService handles fetching, filtering, and live API enrichment.
/// Integrates both curated local gems (visual street food, top visited)
/// and live Google Places API (New) Nearby Search.
class PlacesService {
  final String? googleMapsApiKey;

  PlacesService({this.googleMapsApiKey});

  /// Retrieve places matching the active mood filter and sorted by proximity or popularity
  List<Place> getPlaces({
    String? selectedMood,
    bool onlyVisualFood = false,
    bool onlyTopVisited = false,
    double? userLat,
    double? userLng,
  }) {
    List<Place> results = List.from(jaipurCuratedPlaces);

    // Filter by mood if specified
    if (selectedMood != null && selectedMood.isNotEmpty && selectedMood != 'all') {
      results = results.where((place) => place.moods.contains(selectedMood)).toList();
    }

    // Filter by visual food stall toggle
    if (onlyVisualFood) {
      results = results.where((place) => place.isVisualFoodStall).toList();
    }

    // Filter by top visited spots toggle
    if (onlyTopVisited) {
      results = results.where((place) => place.isTopVisited).toList();
    }

    // Update distance from user if user location is available
    if (userLat != null && userLng != null) {
      for (var place in results) {
        place.distanceInKm = LocationService.calculateDistanceInKm(
          userLat,
          userLng,
          place.latitude,
          place.longitude,
        );
      }
      // Sort primarily by proximity when moving around
      results.sort((a, b) => (a.distanceInKm ?? 999).compareTo(b.distanceInKm ?? 999));
    }

    return results;
  }

  /// Live Google Places API (New) - Search Nearby for live street food and attractions
  Future<List<Place>> fetchLiveNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000.0,
    List<String> includedTypes = const ['restaurant', 'tourist_attraction', 'bakery', 'cafe'],
  }) async {
    if (googleMapsApiKey == null || googleMapsApiKey!.isEmpty) {
      // Returns curated spots when API key is not yet configured
      return getPlaces(userLat: latitude, userLng: longitude);
    }

    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': googleMapsApiKey!,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types',
        },
        body: jsonEncode({
          'includedTypes': includedTypes,
          'maxResultCount': 10,
          'locationRestriction': {
            'circle': {
              'center': {'latitude': latitude, 'longitude': longitude},
              'radius': radiusMeters,
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List placesJson = data['places'] ?? [];
        final livePlaces = placesJson.map((p) => Place.fromGooglePlace(p)).toList();

        // Merge with curated places
        final curated = getPlaces(userLat: latitude, userLng: longitude);
        return [...curated, ...livePlaces];
      }
    } catch (_) {
      // Graceful fallback to curated places
    }

    return getPlaces(userLat: latitude, userLng: longitude);
  }
}

