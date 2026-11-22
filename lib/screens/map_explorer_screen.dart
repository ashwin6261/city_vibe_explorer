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
  final TextEditingController _searchController = TextEditingController();

  // Active filters
  String _selectedMood = 'all';
  bool _onlyVisualFood = false;
  bool _onlyTopVisited = false;

  // State data
  List<Place> _filteredPlaces = [];
  List<Place> _livePlaces = [];
  List<Marker> _markers = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFetching = false;
  late final PageController _pageController;

  // Current map center (updated on search / location / recenter).
  // Starts on the curated Jaipur demo; search jumps anywhere in the world.
  static const LatLng _jaipurCenter = LatLng(26.9196, 75.8115);
  LatLng _mapCenter = _jaipurCenter;

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
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    final granted = await LocationService.handlePermission();
    if (!mounted) return;
    if (!granted) return;

    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _currentPosition = pos);
      _mapCenter = LatLng(pos.latitude, pos.longitude);
      _moveTo(_mapCenter, 13.5);
      _loadPlaces();
      unawaited(_fetchNearby(pos.latitude, pos.longitude));
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

  /// Fetch places near a coordinate (Google if keyed, else OpenStreetMap).
  Future<void> _fetchNearby(double lat, double lng) async {
    if (_isFetching) return;
    setState(() => _isFetching = true);
    final places = await _placesService.fetchNearby(latitude: lat, longitude: lng);
    if (!mounted) return;
    setState(() {
      _livePlaces = places;
      _isFetching = false;
    });
    _loadPlaces();
  }

  /// Geocode a search query and jump the map + place list to that area.
  Future<void> _onSearch(String query) async {
    FocusScope.of(context).unfocus();
    final result = await _placesService.searchLocation(query);
    if (!mounted) return;
    if (result == null) {
      _showMessage('No place found for "$query".');
      return;
    }
    setState(() => _mapCenter = LatLng(result.latitude, result.longitude));
    _moveTo(_mapCenter, 13.5);
    await _fetchNearby(result.latitude, result.longitude);
    if (mounted) _showMessage('Showing places near ${result.name}');
  }

  bool _isNearJaipur() {
    final d = LocationService.calculateDistanceInKm(
      _mapCenter.latitude,
      _mapCenter.longitude,
      LocationService.defaultLat,
      LocationService.defaultLng,
    );
    return d < 40;
  }

  void _loadPlaces() {
    final places = _placesService.getPlaces(
      selectedMood: _selectedMood,
      onlyVisualFood: _onlyVisualFood,
      onlyTopVisited: _onlyTopVisited,
      userLat: _mapCenter.latitude,
      userLng: _mapCenter.longitude,
      extraPlaces: _livePlaces,
      includeCurated: _isNearJaipur(),
    );

    if (!mounted) return;
    setState(() {
      _filteredPlaces = places;
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    final markers = <Marker>[];

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

    for (int i = 0; i < _filteredPlaces.length; i++) {
      final place = _filteredPlaces[i];
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

  void _moveTo(LatLng target, double zoom) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {
      // Map not laid out yet.
    }
  }

  Future<void> _recenterOnUser() async {
    final lat = _currentPosition?.latitude ?? LocationService.defaultLat;
    final lng = _currentPosition?.longitude ?? LocationService.defaultLng;
    setState(() => _mapCenter = LatLng(lat, lng));
    _moveTo(_mapCenter, 14.5);
    await _fetchNearby(lat, lng);
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
      if (mounted) _showMessage('Navigation failed: $error');
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
          // 1. Interactive OpenStreetMap (works anywhere, no API key)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.city_vibe_explorer',
              ),
              MarkerLayer(markers: _markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors © CARTO'),
                ],
              ),
            ],
          ),

          // Loading bar
          if (_isFetching)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),

          // 2. Top search + mood filters
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      const Icon(Icons.search, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _onSearch,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search any city or place...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
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
              ],
            ),
          ),

          // 3. Bottom place cards (sorted by rating) or empty state
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
                    const Icon(Icons.search, color: Colors.deepOrange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Search for a city or place above, or enable location to discover spots near you.',
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