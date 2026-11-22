import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import '../data/curated_places.dart';
import 'location_service.dart';

/// PlacesService handles fetching, filtering, and live enrichment from multiple
/// keyless/ keyed sources:
///  - Curated local gems (visual food stalls, top visited)
///  - Google Places API (New) Nearby Search (when a key is provided)
///  - OpenStreetMap Overpass API (works anywhere, no key)
///  - Nominatim geocoding (search any city / place)
class PlacesService {
  final String? googleMapsApiKey;

  PlacesService({this.googleMapsApiKey});

  bool get _hasGoogleKey =>
      googleMapsApiKey != null && googleMapsApiKey!.isNotEmpty;

  /// Retrieve places matching the active filters, sorted by star rating
  /// (descending) then by distance. Distance is computed without mutating the
  /// shared place objects.
  List<Place> getPlaces({
    String? selectedMood,
    bool onlyVisualFood = false,
    bool onlyTopVisited = false,
    double? userLat,
    double? userLng,
    List<Place> extraPlaces = const [],
    bool includeCurated = true,
  }) {
    List<Place> results = [
      ...(includeCurated ? jaipurCuratedPlaces : <Place>[]),
      ...extraPlaces,
    ];

    if (selectedMood != null && selectedMood.isNotEmpty && selectedMood != 'all') {
      results = results.where((p) => p.moods.contains(selectedMood)).toList();
    }
    if (onlyVisualFood) {
      results = results.where((p) => p.isVisualFoodStall).toList();
    }
    if (onlyTopVisited) {
      results = results.where((p) => p.isTopVisited).toList();
    }

    if (userLat != null && userLng != null) {
      results = results.map((p) {
        final km = LocationService.calculateDistanceInKm(
          userLat,
          userLng,
          p.latitude,
          p.longitude,
        );
        return p.copyWith(distanceInKm: km);
      }).toList();
    }

    // Sort by star rating (desc), then distance (asc) as a tie-breaker.
    results.sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) return byRating;
      return (a.distanceInKm ?? double.infinity)
          .compareTo(b.distanceInKm ?? double.infinity);
    });

    return results;
  }

  /// Fetch places near a coordinate, using Google Places when a key is set,
  /// otherwise OpenStreetMap Overpass. Always sorted by rating.
  Future<List<Place>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 2500,
  }) async {
    if (_hasGoogleKey) {
      final places = await fetchLiveNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
      places.sort((a, b) => b.rating.compareTo(a.rating));
      return places;
    }
    return fetchOverpassNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }

  /// Geocode a free-text query (city, address, or place) via Nominatim.
  /// Returns a [Place] carrying the resolved coordinates + display name.
  Future<Place?> searchLocation(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(q)}&format=json&limit=1',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'CityVibeExplorer/1.0 (city vibe explorer)'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as List;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '') ?? 0.0;
      final lng = double.tryParse(first['lon']?.toString() ?? '') ?? 0.0;
      final displayName = (first['display_name'] ?? q).toString();
      final shortName = displayName.split(',').first.trim();

      return Place(
        id: 'search_${first['place_id'] ?? q}',
        name: shortName.isEmpty ? q : shortName,
        category: 'Searched Place',
        moods: const ['visual'],
        latitude: lat,
        longitude: lng,
        rating: 0,
        userRatingsTotal: 0,
        visualScore: 0,
        imageUrl:
            'https://placehold.co/800x600.png?text=${Uri.encodeQueryComponent(shortName.isEmpty ? q : shortName)}',
        address: displayName,
        description: 'Search result for "$q".',
        mustTry: 'Explore nearby',
        openingHours: '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Live multi-result location search (city / town / village) via Nominatim.
  /// Powers the city dropdown; works anywhere in India (and the world).
  Future<List<Place>> searchLocations(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(q)}&format=json&limit=$limit&addressdetails=1',
      );
      final response = await http
          .get(url,
              headers: {'User-Agent': 'CityVibeExplorer/1.0 (city vibe explorer)'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as List;
      return data.map((d) {
        final name = String(d['display_name'] ?? q).split(',').first.trim();
        return Place(
          id: 'search_${d['place_id'] ?? d['lat']}',
          name: name.isEmpty ? q : name,
          category: 'City / Place',
          moods: const ['visual'],
          latitude: double.tryParse(d['lat']?.toString() ?? '') ?? 0.0,
          longitude: double.tryParse(d['lon']?.toString() ?? '') ?? 0.0,
          rating: 0,
          userRatingsTotal: 0,
          visualScore: 0,
          imageUrl:
              'https://placehold.co/800x600.png?text=${Uri.encodeQueryComponent(name.isEmpty ? q : name)}',
          address: String(d['display_name'] ?? q),
          description: 'Search result for "$q".',
          mustTry: 'Explore nearby',
          openingHours: '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Google Places API (New) Nearby Search (keyed). Returns [] without a key.
  Future<List<Place>> fetchLiveNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000.0,
    List<String> includedTypes = const [
      'restaurant',
      'tourist_attraction',
      'bakery',
      'cafe',
      'museum',
      'art_gallery',
    ],
  }) async {
    if (!_hasGoogleKey) return [];

    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': googleMapsApiKey!,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.website,places.internationalPhoneNumber,places.nationalPhoneNumber',
        },
        body: jsonEncode({
          'includedTypes': includedTypes,
          'maxResultCount': 20,
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
        return placesJson
            .whereType<Map<String, dynamic>>()
            .map((p) => Place.fromGooglePlace(p))
            .toList();
      }
    } catch (_) {
      // Graceful fallback: caller keeps other results.
    }

    return [];
  }

  /// OpenStreetMap Overpass API nearby search (keyless, works anywhere).
  Future<List<Place>> fetchOverpassNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 2500,
  }) async {
    try {
      final r = radiusMeters.round();
      final query = '[out:json][timeout:25];('
          'nwr["amenity"~"^(restaurant|cafe|fast_food|bar|pub|food_court|biergarten|ice_cream)\$"]'
          '(around:$r,$latitude,$longitude);'
          'nwr["tourism"~"^(attraction|museum|gallery|viewpoint|artwork|theme_park|zoo|aquarium)\$"]'
          '(around:$r,$latitude,$longitude);'
          'nwr["historic"](around:$r,$latitude,$longitude);'
          'nwr["leisure"~"^(park|garden)\$"](around:$r,$latitude,$longitude);'
          'nwr["shop"~"^(mall|marketplace|department_store)\$"](around:$r,$latitude,$longitude);'
          ');out center 80;';

      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = (data['elements'] as List?) ?? [];
        final places = elements
            .whereType<Map<String, dynamic>>()
            .map((e) => Place.fromOverpass(e))
            .toList();
        places.sort((a, b) => b.rating.compareTo(a.rating));
        return places;
      }
    } catch (_) {
      // Network/parse errors -> caller falls back gracefully.
    }

    return [];
  }
}