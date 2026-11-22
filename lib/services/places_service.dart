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

  /// Retrieve places matching the active mood filter and sorted by proximity.
  ///
  /// [extraPlaces] lets callers merge live API results with the curated set
  /// before filtering, so both sources respect the same mood/flag filters.
  List<Place> getPlaces({
    String? selectedMood,
    bool onlyVisualFood = false,
    bool onlyTopVisited = false,
    double? userLat,
    double? userLng,
    List<Place> extraPlaces = const [],
  }) {
    List<Place> results = [...jaipurCuratedPlaces, ...extraPlaces];

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

    // Compute distance from user without mutating the shared place objects,
    // then sort primarily by proximity when a location is available.
    if (userLat != null && userLng != null) {
      final List<Place> withDistance = results.map((place) {
        final double km = LocationService.calculateDistanceInKm(
          userLat,
          userLng,
          place.latitude,
          place.longitude,
        );
        return place.copyWith(distanceInKm: km);
      }).toList();

      withDistance.sort(
        (a, b) => (a.distanceInKm ?? double.infinity)
            .compareTo(b.distanceInKm ?? double.infinity),
      );
      return withDistance;
    }

    return results;
  }

  /// Live Google Places API (New) - Search Nearby for live street food and attractions.
  ///
  /// Returns only the freshly fetched live places (empty when no API key is
  /// configured or on any error) so the caller can merge + filter them with
  /// the curated data through a single [getPlaces] call.
  Future<List<Place>> fetchLiveNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000.0,
    List<String> includedTypes = const ['restaurant', 'tourist_attraction', 'bakery', 'cafe'],
  }) async {
    if (googleMapsApiKey == null || googleMapsApiKey!.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': googleMapsApiKey!,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount',
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
        return placesJson.map((p) => Place.fromGooglePlace(p)).toList();
      }
    } catch (_) {
      // Graceful fallback: caller keeps curated-only results.
    }

    return [];
  }
}