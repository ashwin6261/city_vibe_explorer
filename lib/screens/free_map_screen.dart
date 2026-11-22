import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart';
import '../services/places_service.dart';
import '../services/location_service.dart';
import '../widgets/mood_selector.dart';
import '../widgets/place_card.dart';
import '../widgets/place_detail_modal.dart';

/// 100% FREE Mobile Map Screen
/// Uses OpenStreetMap & self-contained curated gems:
/// - NO Google Cloud Project required
/// - NO Credit Card / Billing required
/// - Zero API costs forever
class FreeMapScreen extends StatefulWidget {
  const FreeMapScreen({super.key});

  @override
  State<FreeMapScreen> createState() => _FreeMapScreenState();
}

class _FreeMapScreenState extends State<FreeMapScreen> {
  final PlacesService _placesService = PlacesService();

  String _selectedMood = 'all';
  bool _onlyVisualFood = false;
  bool _onlyTopVisited = false;

  List<Place> _filteredPlaces = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _loadPlaces();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _currentPosition = pos);
      _loadPlaces();
    }

    _positionStreamSubscription = LocationService.getPositionStream().listen((Position newPos) {
      if (mounted) {
        setState(() => _currentPosition = newPos);
        _loadPlaces();
      }
    });
  }

  void _loadPlaces() {
    final places = _placesService.getPlaces(
      selectedMood: _selectedMood,
      onlyVisualFood: _onlyVisualFood,
      onlyTopVisited: _onlyTopVisited,
      userLat: _currentPosition?.latitude ?? LocationService.defaultLat,
      userLng: _currentPosition?.longitude ?? LocationService.defaultLng,
    );

    setState(() {
      _filteredPlaces = places;
    });
  }

  void _navigateToPlace(Place place) async {
    // Free deep-link directly into user's installed Google Maps app
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'City Vibe Explorer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            Text(
              '100% Free Forever • OpenStreetMap + Curated Gems',
              style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mood Selector Bar
          MoodSelectorBar(
            selectedMood: _selectedMood,
            onlyVisualFood: _onlyVisualFood,
            onlyTopVisited: _onlyTopVisited,
            onSelectMood: (mood) {
              setState(() => _selectedMood = mood);
              _loadPlaces();
            },
            onToggleVisualFood: (val) {
              setState(() => _onlyVisualFood = val);
              _loadPlaces();
            },
            onToggleTopVisited: (val) {
              setState(() => _onlyTopVisited = val);
              _loadPlaces();
            },
          ),
          const SizedBox(height: 10),

          // Feed list of spots
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredPlaces.length,
              itemBuilder: (context, index) {
                final place = _filteredPlaces[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: PlaceCard(
                    place: place,
                    onTap: () => PlaceDetailModal.show(context, place),
                    onNavigate: () => _navigateToPlace(place),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

