import 'dart:async';
import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/places_service.dart';

/// City picker bottom sheet: bundled popular Indian cities (instant, offline)
/// plus live Nominatim search for any city / town / village.
class CityPicker extends StatefulWidget {
  final PlacesService placesService;

  const CityPicker({super.key, required this.placesService});

  static Future<Place?> show(BuildContext context, PlacesService placesService) {
    return showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPicker(placesService: placesService),
    );
  }

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Place> _results = _popularCities;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _results = _popularCities;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    final results = await widget.placesService.searchLocations(q, limit: 15);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose your city',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search any city, town or village...',
                  prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _results[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.deepOrange),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      p.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Popular Indian cities shown instantly (offline) in the picker.
final List<Place> _popularCities = [
  _city('Jaipur', 'Rajasthan', 26.9124, 75.7873),
  _city('Delhi', 'Delhi', 28.6139, 77.2090),
  _city('Mumbai', 'Maharashtra', 19.0760, 72.8777),
  _city('Bengaluru', 'Karnataka', 12.9716, 77.5946),
  _city('Hyderabad', 'Telangana', 17.3850, 78.4867),
  _city('Chennai', 'Tamil Nadu', 13.0827, 80.2707),
  _city('Kolkata', 'West Bengal', 22.5726, 88.3639),
  _city('Pune', 'Maharashtra', 18.5204, 73.8567),
  _city('Ahmedabad', 'Gujarat', 23.0225, 72.5714),
  _city('Surat', 'Gujarat', 21.1702, 72.8311),
  _city('Agra', 'Uttar Pradesh', 27.1767, 78.0081),
  _city('Varanasi', 'Uttar Pradesh', 25.3176, 82.9739),
  _city('Lucknow', 'Uttar Pradesh', 26.8467, 80.9462),
  _city('Amritsar', 'Punjab', 31.6340, 74.8723),
  _city('Chandigarh', 'Chandigarh', 30.7333, 76.7794),
  _city('Dehradun', 'Uttarakhand', 30.3165, 78.0322),
  _city('Rishikesh', 'Uttarakhand', 30.0869, 78.2676),
  _city('Shimla', 'Himachal Pradesh', 31.1048, 77.1734),
  _city('Manali', 'Himachal Pradesh', 32.2396, 77.1887),
  _city('Srinagar', 'Jammu and Kashmir', 34.0837, 74.7973),
  _city('Leh', 'Ladakh', 34.1526, 77.5771),
  _city('Bhopal', 'Madhya Pradesh', 23.2599, 77.4126),
  _city('Indore', 'Madhya Pradesh', 22.7196, 75.8577),
  _city('Raipur', 'Chhattisgarh', 21.2514, 81.6296),
  _city('Bhubaneswar', 'Odisha', 20.2961, 85.8245),
  _city('Kolkata', 'West Bengal', 22.5726, 88.3639),
  _city('Guwahati', 'Assam', 26.1445, 91.7362),
  _city('Patna', 'Bihar', 25.5941, 85.1376),
  _city('Ranchi', 'Jharkhand', 23.3441, 85.3096),
  _city('Kochi', 'Kerala', 9.9312, 76.2673),
  _city('Thiruvananthapuram', 'Kerala', 8.5241, 76.9366),
  _city('Mysuru', 'Karnataka', 12.2958, 76.6394),
  _city('Madurai', 'Tamil Nadu', 9.9252, 78.1198),
  _city('Tirupati', 'Andhra Pradesh', 13.6288, 79.4192),
  _city('Visakhapatnam', 'Andhra Pradesh', 17.6868, 83.2185),
  _city('Vijayawada', 'Andhra Pradesh', 16.5062, 80.6480),
  _city('Panaji', 'Goa', 15.4909, 73.8278),
  _city('Udaipur', 'Rajasthan', 24.5854, 73.7125),
  _city('Jodhpur', 'Rajasthan', 26.2389, 73.0243),
  _city('Kota', 'Rajasthan', 25.2138, 75.8648),
  _city('Pushkar', 'Rajasthan', 26.4890, 74.5511),
  _city('Mount Abu', 'Rajasthan', 24.5924, 72.7086),
  _city('Darjeeling', 'West Bengal', 27.0410, 88.2663),
  _city('Ooty', 'Tamil Nadu', 11.4102, 76.6950),
  _city('Munnar', 'Kerala', 10.0889, 77.0419),
  _city('Goa', 'Goa', 15.2993, 74.1240),
];

Place _city(String name, String state, double lat, double lng) {
  return Place(
    id: 'city_$name',
    name: name,
    category: 'City',
    moods: const ['visual'],
    latitude: lat,
    longitude: lng,
    rating: 0,
    userRatingsTotal: 0,
    visualScore: 0,
    imageUrl: 'https://placehold.co/800x600.png?text=${Uri.encodeQueryComponent(name)}',
    address: state,
    description: 'Explore $name',
    mustTry: 'Explore nearby',
    openingHours: '',
  );
}