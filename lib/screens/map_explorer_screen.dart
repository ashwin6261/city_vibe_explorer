import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../models/place.dart';
import '../services/places_service.dart';
import '../services/location_service.dart';
import '../widgets/mood_selector.dart';
import '../widgets/place_card.dart';
import '../widgets/place_detail_modal.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  final MapController _mapController = MapController();
  final PlacesService _placesService = PlacesService(
    googleMapsApiKey: AppConfig.googleMapsApiKey,
  );

  // Active filters
  String _selectedMood = 'all';
  bool _onlyVisualFood = false;
  bool _onlyTopVisited = false;

  // State data
  List<Place> _filteredPlaces = [];
  List<Place> _livePlaces = [];
  List<Marker> _markers = [];
  Position? _currentPosition;
  bool _hasLocationPermission = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFetchingLive = false;
  late final PageController _pageController;

  // Default map target: Jaipur center
  static const LatLng _initialCenter = LatLng(26.9196, 75.8115);

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

  /// Initialize real-time location tracking as the user moves around the city.
  ///
  /// Permission is resolved first; the position stream is only subscribed when
  /// permission is actually granted (and carries an explicit error handler), so
  /// a denied/unavailable sensor can never throw an unhandled exception.
  Future<void> _initLocationTracking() async {
    final granted = await LocationService.handlePermission();
    if (!mounted) return;
    setState(() => _hasLocationPermission = granted);

    if (!granted) return;

    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _currentPosition = pos);
      _loadPlaces();
      unawaited(_fetchLivePlaces(pos));
    }

    _positionStreamSubscription = LocationService.getPositionStream().listen(
      (Position newPos) {
        if (mounted) {
          setState(() => _currentPosition = newPos);
          _loadPlaces();
        }
      },
      onError: (Object error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  /// Fetch live Google Places once a location is available and merge them in.
  Future<void> _fetchLivePlaces(Position pos) async {
    if (AppConfig.googleMapsApiKey.isEmpty || _isFetchingLive) return;
    setState(() => _isFetchingLive = true);
    final live = await _placesService.fetchLiveNearbyPlaces(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!mounted) return;
    setState(() {
      _livePlaces = live;
      _isFetchingLive = false;
    });
    _loadPlaces();
  }

  void _loadPlaces() {
    final places = _placesService.getPlaces(
      selectedMood: _selectedMood,
      onlyVisualFood: _onlyVisualFood,
      onlyTopVisited: _onlyTopVisited,
      userLat: _currentPosition?.latitude ?? LocationService.defaultLat,
      userLng: _currentPosition?.longitude ?? LocationService.defaultLng,
      extraPlaces: _livePlaces,
    );

    if (!mounted) return;
    setState(() {
      _filteredPlaces = places;
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    final markers = <Marker>[];

    // User location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 26,
          height: 26,
          child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 26),
        ),
      );
    }

    // Place markers
    for (int i = 0; i < _filteredPlaces.length; i++) {
      final place = _filteredPlaces[i];
      // Colour code: Orange = Visual Food Stall, Amber = Top Visited, Purple = other.
      final Color color = place.isVisualFoodStall
          ? Colors.deepOrange
          : (place.isTopVisited ? Colors.amber : Colors.deepPurple);

      markers.add(
        Marker(
          point: LatLng(place.latitude, place.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              PlaceDetailModal.show(context, place);
              _moveTo(LatLng(place.latitude, place.longitude), 15.5);
            },
            child: Icon(Icons.location_on, color: color, size: 38),
          ),
        ),
      );
    }

    _markers = markers;
  }

  /// Safely move the map camera (no-op if the controller is not attached yet).
  void _moveTo(LatLng target, double zoom) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {
      // Map not laid out yet; ignore.
    }
  }

  Future<void> _recenterOnUser() async {
    final lat = _currentPosition?.latitude ?? LocationService.defaultLat;
    final lng = _currentPosition?.longitude ?? LocationService.defaultLng;
    _moveTo(LatLng(lat, lng), 14.5);
    if (_currentPosition != null) {
      unawaited(_fetchLivePlaces(_currentPosition!));
    }
  }

  Future<void> _navigateToPlace(Place place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showMessage('Could not open Google Maps on this device.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Navigation failed: $error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Interactive OpenStreetMap (no API key required)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.city_vibe_explorer',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // 2. Top Header with City Vibe branding and Mood Filter Carousel
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search & City Title Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(31),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore, color: Colors.deepOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Exploring Jaipur',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _isFetchingLive
                                  ? 'Finding live spots nearby...'
                                  : 'Visual food stalls & top visited spots',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.blueAccent),
                        onPressed: _recenterOnUser,
                        tooltip: 'Recenter on my location',
                      ),
                    ],
                  ),
                ),

                // Mood Filters Bar
                MoodSelectorBar(
                  selectedMood: _selectedMood,
                  onlyVisualFood: _onlyVisualFood,
                  onlyTopVisited: _onlyTopVisited,
                  onSelectMood: (mood) {
                    setState(() {
                      _selectedMood = mood;
                    });
                    _loadPlaces();
                  },
                  onToggleVisualFood: (val) {
                    setState(() {
                      _onlyVisualFood = val;
                    });
                    _loadPlaces();
                  },
                  onToggleTopVisited: (val) {
                    setState(() {
                      _onlyTopVisited = val;
                    });
                    _loadPlaces();
                  },
                ),
              ],
            ),
          ),

          // 3. Floating Bottom Place Cards Carousel (or empty state)
          if (_filteredPlaces.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              height: 230,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _filteredPlaces.length,
                onPageChanged: (index) {
                  final place = _filteredPlaces[index];
                  _moveTo(LatLng(place.latitude, place.longitude), 15.5);
                },
                itemBuilder: (context, index) {
                  final place = _filteredPlaces[index];
                  return PlaceCard(
                    place: place,
                    onTap: () => PlaceDetailModal.show(context, place),
                    onNavigate: () => _navigateToPlace(place),
                  );
                },
              ),
            )
          else
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(31),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_off_rounded, color: Colors.deepOrange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No spots match these filters. Try another vibe or clear the toggles.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}