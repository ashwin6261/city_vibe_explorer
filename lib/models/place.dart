/// Data model representing a place of interest, such as visual food stalls,
/// heritage monuments, viewpoint cafes, vibrant bazaars, or any nearby POI.
class Place {
  final String id;
  final String name;
  final String category; // e.g. "Visual Food Stall", "Heritage Landmark", "Cafe", "Market"
  final List<String> moods; // ['foodie', 'visual', 'heritage', 'chill', 'shopping', 'nightlife']
  final double latitude;
  final double longitude;
  final double rating;
  final int userRatingsTotal;
  final int visualScore; // 1 to 100 photogenic index
  final String imageUrl;
  final String address;
  final String description;
  final String mustTry;
  final bool isVisualFoodStall;
  final bool isTopVisited;
  final String openingHours;
  final String? placeId; // Google Places Place ID / OSM id for live API syncing
  final String? videoUrl; // optional direct video (YouTube) link
  final String? website;
  final String? phone;

  double? distanceInKm;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.moods,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.userRatingsTotal,
    required this.visualScore,
    required this.imageUrl,
    required this.address,
    required this.description,
    required this.mustTry,
    this.isVisualFoodStall = false,
    this.isTopVisited = false,
    this.openingHours = 'Open today: 9:00 AM – 9:00 PM',
    this.placeId,
    this.videoUrl,
    this.website,
    this.phone,
    this.distanceInKm,
  });

  /// Creates a copy of this place with an updated (computed) distance.
  /// Used so per-frame distance recalculation never mutates the shared,
  /// globally cached curated place objects.
  Place copyWith({double? distanceInKm}) {
    return Place(
      id: id,
      name: name,
      category: category,
      moods: moods,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      visualScore: visualScore,
      imageUrl: imageUrl,
      address: address,
      description: description,
      mustTry: mustTry,
      isVisualFoodStall: isVisualFoodStall,
      isTopVisited: isTopVisited,
      openingHours: openingHours,
      placeId: placeId,
      videoUrl: videoUrl,
      website: website,
      phone: phone,
      distanceInKm: distanceInKm ?? this.distanceInKm,
    );
  }

  factory Place.fromGooglePlace(Map<String, dynamic> json) {
    final location = json['location'] ?? json['geometry']?['location'] ?? {};
    final lat = (location['latitude'] ?? location['lat'] ?? 0.0).toDouble();
    final lng = (location['longitude'] ?? location['lng'] ?? 0.0).toDouble();
    final displayName = json['displayName']?['text'] ?? json['name'] ?? 'Local Spot';
    final rating = (json['rating'] ?? 4.5).toDouble();
    final userRatingsTotal = json['userRatingCount'] ?? 100;
    final types = (json['types'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    // Derive flags/moods from the Google Places `types` instead of hardcoding,
    // so live cafes/restaurants are "foodie" and attractions are "heritage"
    // rather than everything being tagged as a visual food stall.
    final bool isFood = types.any(
      (t) => t == 'restaurant' || t == 'cafe' || t == 'bakery' || t == 'food',
    );

    final List<String> moods = ['visual'];
    if (isFood) moods.add('foodie');
    if (types.any(
        (t) => t == 'tourist_attraction' || t == 'museum' || t == 'historical_site')) {
      moods.add('heritage');
    }
    if (types.contains('cafe')) moods.add('chill');
    if (types.any((t) => t == 'shopping_mall' || t == 'market')) {
      moods.add('shopping');
    }
    if (types.any((t) => t == 'bar' || t == 'night_club')) {
      moods.add('nightlife');
    }
    if (types.any((t) => t == 'museum' || t == 'art_gallery')) {
      moods.add('museums');
    }
    if (types.contains('park')) moods.add('parks');

    return Place(
      id: json['id'] ?? json['place_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: displayName,
      category: 'Discovered Spot',
      moods: moods,
      latitude: lat,
      longitude: lng,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      visualScore: (rating * 18).clamp(60, 99).toInt(),
      imageUrl: 'https://images.unsplash.com/photo-1599661046827-dacff0c0f09a?w=800&q=80',
      address: json['formattedAddress'] ?? json['vicinity'] ?? 'Nearby',
      description: 'Popular spot retrieved from Google Places.',
      mustTry: 'Local Chef Special',
      isVisualFoodStall: isFood,
      isTopVisited: userRatingsTotal > 2000,
      placeId: json['id'] ?? json['place_id'],
      website: json['website']?.toString(),
      phone: (json['internationalPhoneNumber'] ?? json['nationalPhoneNumber'])?.toString(),
    );
  }

  /// Builds a [Place] from an OpenStreetMap Overpass element.
  ///
  /// OSM has no star ratings, so a deterministic visual/quality score is
  /// derived from tags (wikidata/wikipedia/image/tourism/historic/cuisine) and
  /// surfaced as both `visualScore` and a derived `rating` (score / 20).
  factory Place.fromOverpass(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final type = element['type']?.toString() ?? 'node';
    final osmId = element['id'];
    final lat = (element['lat'] ?? element['center']?['lat'] ?? 0.0).toDouble();
    final lng = (element['lon'] ?? element['center']?['lon'] ?? 0.0).toDouble();

    final name = (tags['name:en'] ?? tags['name'] ?? 'Local Spot').toString();
    final amenity = (tags['amenity'] ?? '').toString();
    final tourism = (tags['tourism'] ?? '').toString();
    final leisure = (tags['leisure'] ?? '').toString();
    final historic = (tags['historic'] ?? '').toString();
    final cuisine = (tags['cuisine'] ?? '').toString();
    final shop = (tags['shop'] ?? '').toString();

    String category;
    if (tourism.isNotEmpty) {
      category = tourism;
    } else if (amenity.isNotEmpty) {
      category = amenity;
    } else if (historic.isNotEmpty) {
      category = 'Historic Site';
    } else if (leisure.isNotEmpty) {
      category = leisure;
    } else if (shop.isNotEmpty) {
      category = shop;
    } else {
      category = 'Place';
    }
    category = category.replaceAll('_', ' ');
    category = category[0].toUpperCase() + category.substring(1);

    final moods = <String>['visual'];
    if (amenity.isNotEmpty || cuisine.isNotEmpty) moods.add('foodie');
    if (tourism == 'museum' || tourism == 'gallery' || historic.isNotEmpty) {
      moods.add('heritage');
    }
    if (leisure == 'park' || tourism == 'viewpoint') moods.add('chill');
    if (shop.isNotEmpty || tourism == 'gallery' || tourism == 'artwork') {
      moods.add('shopping');
    }
    if (amenity == 'bar' || amenity == 'pub') moods.add('nightlife');
    if (tourism == 'museum' || tourism == 'gallery') moods.add('museums');
    if (leisure == 'park' || leisure == 'garden') moods.add('parks');

    final score = _visualScoreFromTags(tags);
    final rating = double.parse((score / 20.0).clamp(1.0, 5.0).toStringAsFixed(1));

    final addressParts = <String>[
      tags['addr:street']?.toString() ?? '',
      tags['addr:city']?.toString() ?? '',
      tags['addr:country']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    return Place(
      id: 'osm_${type}_$osmId',
      name: name,
      category: category,
      moods: moods,
      latitude: lat,
      longitude: lng,
      rating: rating,
      userRatingsTotal: 0,
      visualScore: score,
      imageUrl:
          'https://placehold.co/800x600.png?text=${Uri.encodeQueryComponent(name)}',
      address: addressParts.isEmpty ? 'Nearby' : addressParts.join(', '),
      description: (tags['description'] ?? 'A notable place near you.').toString(),
      mustTry: cuisine.isNotEmpty ? 'Try the local $cuisine' : 'Explore & discover',
      isVisualFoodStall: amenity == 'fast_food' ||
          amenity == 'cafe' ||
          amenity == 'food_court' ||
          amenity == 'restaurant' ||
          amenity == 'bar' ||
          amenity == 'pub' ||
          amenity == 'ice_cream',
      isTopVisited: score >= 75,
      openingHours: (tags['opening_hours'] ?? 'See on map').toString(),
      placeId: osmId?.toString(),
      website: (tags['website'] ?? tags['contact:website'])?.toString(),
      phone: (tags['phone'] ?? tags['contact:phone'])?.toString(),
    );
  }

  static int _visualScoreFromTags(Map<String, dynamic> tags) {
    int score = 55;
    if (tags['wikidata'] != null) score += 15;
    if (tags['wikipedia'] != null) score += 10;
    if (tags['image'] != null) score += 10;
    if (tags['tourism'] == 'attraction' || tags['tourism'] == 'museum') score += 10;
    if (tags['historic'] != null) score += 8;
    if (tags['cuisine'] != null) score += 5;
    return score.clamp(40, 99);
  }
}