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

  factory Place.fromGooglePlace(Map<String, dynamic> json) {
    final location = json['location'] ?? json['geometry']?['location'] ?? {};
    final lat = (location['latitude'] ?? location['lat'] ?? 0.0).toDouble();
    final lng = (location['longitude'] ?? location['lng'] ?? 0.0).toDouble();
    final displayName = json['displayName']?['text'] ?? json['name'] ?? 'Local Spot';
    final rating = (json['rating'] ?? 4.5).toDouble();
    final userRatingsTotal = json['userRatingCount'] ?? 100;

    return Place(
      id: json['id'] ?? json['place_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: displayName,
      category: 'Discovered Spot',
      moods: ['foodie', 'visual'],
      latitude: lat,
      longitude: lng,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      visualScore: (rating * 18).clamp(60, 99).toInt(),
      imageUrl: 'https://images.unsplash.com/photo-1599661046827-dacff0c0f09a?w=800&q=80',
      address: json['formattedAddress'] ?? json['vicinity'] ?? 'Jaipur, Rajasthan',
      description: 'Popular spot retrieved from Google Places.',
      mustTry: 'Local Chef Special',
      isVisualFoodStall: true,
      isTopVisited: userRatingsTotal > 2000,
      placeId: json['id'] ?? json['place_id'],
    );
  }
}

