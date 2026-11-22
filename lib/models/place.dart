/// Data model representing a place of interest, such as visual food stalls,
/// heritage monuments, viewpoint cafes, and vibrant bazaars.
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
  final String? placeId; // Google Places Place ID for live API syncing

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
      address: json['formattedAddress'] ?? json['vicinity'] ?? 'Jaipur, Rajasthan',
      description: 'Popular spot retrieved from Google Places.',
      mustTry: 'Local Chef Special',
      isVisualFoodStall: isFood,
      isTopVisited: userRatingsTotal > 2000,
      placeId: json['id'] ?? json['place_id'],
    );
  }
}

