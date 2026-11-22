import '../models/place.dart';

/// Curated database of Jaipur's most visual food stalls and top-visited places.
/// Combines rich cultural context, must-try food delicacies, and visual ratings.
final List<Place> jaipurCuratedPlaces = [
  // 1. Rawat Mishthan Bhandar
  Place(
    id: 'rawat_01',
    name: 'Rawat Mishthan Bhandar',
    category: 'Visual Food Stall & Sweet Shop',
    moods: ['foodie', 'visual'],
    latitude: 26.9204,
    longitude: 75.7956,
    rating: 4.6,
    userRatingsTotal: 48500,
    visualScore: 94,
    imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800&q=80',
    address: 'Station Road, Sindhi Camp, Jaipur',
    description:
        'World famous for its piping hot, flaky Pyaaz Kachoris. Watch the master fryers handling gigantic sizzling kadhais in an electric street-food spectacle.',
    mustTry: 'Pyaaz Kachori & Mawa Kachori',
    isVisualFoodStall: true,
    isTopVisited: true,
    openingHours: '6:00 AM – 10:30 PM',
  ),

  // 2. Lassiwala (Since 1944)
  Place(
    id: 'lassiwala_02',
    name: 'Original Lassiwala (Shop 312)',
    category: 'Legendary Drink Stall',
    moods: ['foodie', 'visual', 'chill'],
    latitude: 26.9176,
    longitude: 75.8115,
    rating: 4.7,
    userRatingsTotal: 24300,
    visualScore: 96,
    imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
    address: '312, MI Road, Jayanti Market, Jaipur',
    description:
        'Serving Jaipur since 1944. Thick, velvety curd lassi served in authentic red terracotta clay kulhads, topped with a thick dollop of clotted cream (malai). Highly photogenic pour!',
    mustTry: 'Special Sweet Clay Kulhad Lassi (Large)',
    isVisualFoodStall: true,
    isTopVisited: true,
    openingHours: '7:00 AM – 4:00 PM (Until stocks last)',
  ),

  // 3. Hawa Mahal (Palace of Winds)
  Place(
    id: 'hawa_mahal_03',
    name: 'Hawa Mahal (Palace of Winds)',
    category: 'Heritage Landmark',
    moods: ['visual', 'heritage'],
    latitude: 26.9239,
    longitude: 75.8267,
    rating: 4.8,
    userRatingsTotal: 82000,
    visualScore: 99,
    imageUrl: 'https://images.unsplash.com/photo-1599661046827-dacff0c0f09a?w=800&q=80',
    address: 'Hawa Mahal Rd, Badi Choupad, Pink City, Jaipur',
    description:
        'Iconic five-story pink sandstone palace with 953 intricately carved jharokhas (small casements). The definitive visual emblem of Jaipur.',
    mustTry: 'Rooftop photography from opposite Wind View / Tattoo Cafe',
    isVisualFoodStall: false,
    isTopVisited: true,
    openingHours: '9:00 AM – 5:00 PM',
  ),

  // 4. Tattoo Cafe & Lounge (Hawa Mahal View)
  Place(
    id: 'tattoo_cafe_04',
    name: 'Tattoo Cafe & Lounge',
    category: 'Rooftop Cafe & Food',
    moods: ['foodie', 'visual', 'chill', 'nightlife'],
    latitude: 26.9242,
    longitude: 75.8271,
    rating: 4.5,
    userRatingsTotal: 4900,
    visualScore: 98,
    imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80',
    address: 'Opposite Hawa Mahal, 3rd Floor, Badi Choupad, Jaipur',
    description:
        'Unmatched direct eye-level panorama of Hawa Mahal. Sip artisan coffee or spiced mocktails as the sunset paints the sandstone golden.',
    mustTry: 'Wood-fired Pizza & Pink City Masala Cooler',
    isVisualFoodStall: false,
    isTopVisited: true,
    openingHours: '8:00 AM – 11:00 PM',
  ),

  // 5. Masala Chowk (Open Air Food Court)
  Place(
    id: 'masala_chowk_05',
    name: 'Masala Chowk',
    category: 'Open-Air Street Food Hub',
    moods: ['foodie', 'visual', 'chill'],
    latitude: 26.9115,
    longitude: 75.8202,
    rating: 4.6,
    userRatingsTotal: 17200,
    visualScore: 95,
    imageUrl: 'https://images.unsplash.com/photo-1505253758473-96b46deae6f9?w=800&q=80',
    address: 'Ram Niwas Garden, Near Albert Hall, Jaipur',
    description:
        'Curated open-air garden square housing 21 of Jaipur’s most iconic heritage street food stalls in one vibrant spot surrounded by lush lawns.',
    mustTry: 'Gulab Halwa, Dal Baati Churma & Falooda',
    isVisualFoodStall: true,
    isTopVisited: true,
    openingHours: '10:00 AM – 10:00 PM',
  ),

  // 6. Patrika Gate (Jawahar Circle)
  Place(
    id: 'patrika_gate_06',
    name: 'Patrika Gate',
    category: 'Photogenic Architecture',
    moods: ['visual', 'heritage', 'chill'],
    latitude: 26.8289,
    longitude: 75.8056,
    rating: 4.8,
    userRatingsTotal: 31000,
    visualScore: 100,
    imageUrl: 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800&q=80',
    address: 'Jawahar Circle Garden, Malviya Nagar, Jaipur',
    description:
        'Vividly hand-painted royal arches illustrating Rajasthan’s rich princely heritage, wars, crafts, and royal portraits. Ranked among India’s top Instagram visual hotspots.',
    mustTry: 'Walking through the colorful corridor for symmetry photos',
    isVisualFoodStall: false,
    isTopVisited: true,
    openingHours: 'Open 24 Hours',
  ),

  // 7. Amer Fort (Amber Palace)
  Place(
    id: 'amer_fort_07',
    name: 'Amer Fort (Amber Palace)',
    category: 'Royal Fortress & Sights',
    moods: ['heritage', 'visual'],
    latitude: 26.9855,
    longitude: 75.8513,
    rating: 4.8,
    userRatingsTotal: 115000,
    visualScore: 98,
    imageUrl: 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800&q=80',
    address: 'Devisinghpura, Amer, Jaipur',
    description:
        'Magnificent hilltop palace fortress overlooking Maota Lake. Famous for the glittering Sheesh Mahal (Mirror Palace) and royal ramparts.',
    mustTry: 'Sheesh Mahal mirror reflections & Maota lake view',
    isVisualFoodStall: false,
    isTopVisited: true,
    openingHours: '8:00 AM – 5:30 PM, 6:30 PM – 9:15 PM (Night light show)',
  ),

  // 8. Gulab Ji Chai Wale
  Place(
    id: 'gulab_ji_08',
    name: 'Gulab Ji Chai Wale',
    category: 'Iconic Tea Stall',
    moods: ['foodie', 'visual', 'chill'],
    latitude: 26.9189,
    longitude: 75.8118,
    rating: 4.5,
    userRatingsTotal: 11200,
    visualScore: 91,
    imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=800&q=80',
    address: 'Opposite Ganpati Plaza, MI Road, Jaipur',
    description:
        'Famous tea stall brewing fragrant saffron and ginger masala chai served in hot clay cups with butter-slathered bun maska.',
    mustTry: 'Masala Kadak Chai with Maska Bun & Samosa Bun',
    isVisualFoodStall: true,
    isTopVisited: false,
    openingHours: '5:30 AM – 9:00 PM',
  ),

  // 9. Nahargarh Fort (Padao Sunset Point)
  Place(
    id: 'nahargarh_09',
    name: 'Nahargarh Fort & Padao Sunset Point',
    category: 'Hilltop Fortress & Night Vibe',
    moods: ['visual', 'chill', 'nightlife', 'heritage'],
    latitude: 26.9373,
    longitude: 75.8156,
    rating: 4.7,
    userRatingsTotal: 65000,
    visualScore: 97,
    imageUrl: 'https://images.unsplash.com/photo-1608759458999-7389178ee9d4?w=800&q=80',
    address: 'Krishna Nagar, Brahampuri, Jaipur',
    description:
        'Perched atop the Aravalli hills, offering the ultimate breathtaking sunset panoramic view of the entire lit-up Pink City.',
    mustTry: 'Sunset drinks at Padao restaurant on the ramparts',
    isVisualFoodStall: false,
    isTopVisited: true,
    openingHours: '10:00 AM – 10:00 PM',
  ),

  // 10. Bapu Bazaar & Johari Bazaar
  Place(
    id: 'bapu_bazaar_10',
    name: 'Bapu Bazaar & Street Food Lane',
    category: 'Bazaar & Chaat Hub',
    moods: ['shopping', 'foodie', 'visual'],
    latitude: 26.9188,
    longitude: 75.8234,
    rating: 4.6,
    userRatingsTotal: 28000,
    visualScore: 93,
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
    address: 'Bapu Bazaar, Pink City, Jaipur',
    description:
        'Vibrant pink market lanes lined with handcrafted Mojaris, block-printed textiles, and buzzing street carts serving spicy Gol Gappas, Dahi Puri, and Kulfi.',
    mustTry: 'Pani Puri shot stalls & Falooda Kulfi',
    isVisualFoodStall: true,
    isTopVisited: true,
    openingHours: '11:00 AM – 9:30 PM',
  ),

  // 11. Jal Mahal (Water Palace)
  Place(
    id: 'jal_mahal_11',
    name: 'Jal Mahal (Water Palace)',
    category: 'Water Palace & Promenade',
    moods: ['visual', 'chill', 'heritage'],
    latitude: 26.9535,
    longitude: 75.8462,
    rating: 4.6,
    userRatingsTotal: 54000,
    visualScore: 97,
    imageUrl: 'https://images.unsplash.com/photo-1599661046827-dacff0c0f09a?w=800&q=80',
    address: 'Amer Road, Man Sagar Lake, Jaipur',
    description:
        'Enchanting palace appearing to float in the middle of Man Sagar Lake. The lakeside promenade is lively with street musicians and roasted corn stalls.',
    mustTry: 'Lakeside roasted bhutta (corn) while watching the sunset reflection',
    isVisualFoodStall: false,
    isTopVisited: true,
    openingHours: 'Open 24 Hours (Viewing from Promenade)',
  ),

  // 12. Pandit Kulfi & Falooda
  Place(
    id: 'pandit_kulfi_12',
    name: 'Pandit Kulfi Bhandar',
    category: 'Visual Dessert Stall',
    moods: ['foodie', 'visual'],
    latitude: 26.9248,
    longitude: 75.8260,
    rating: 4.6,
    userRatingsTotal: 8400,
    visualScore: 92,
    imageUrl: 'https://images.unsplash.com/photo-1505253758473-96b46deae6f9?w=800&q=80',
    address: 'Near Hawa Mahal, Sireh Deori Bazaar, Jaipur',
    description:
        'Famous heritage kulfi cart serving rich Rabdi, Kesar Pista, and Paan kulfi freshly cut from earthen moulds onto green leaves.',
    mustTry: 'Kesar Pista Matka Kulfi with Rose Falooda',
    isVisualFoodStall: true,
    isTopVisited: false,
    openingHours: '11:00 AM – 11:30 PM',
  ),
];

