import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final PlacesService _placesService = PlacesService();

  // Active filters
  String _selectedMood = 'all';
  bool _onlyVisualFood = false;
  bool _onlyTopVisited = false;

  // State data
  List<Place> _filteredPlaces = [];
  Set<Marker> _markers = {};
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  Place? _selectedPlace;
  late final PageController _pageController;

  // Default camera target: Jaipur center
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(26.9196, 75.8115),
    zoom: 13.5,
  );

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

  /// Initialize real-time location tracking as user moves around the city
  Future<void> _initLocationTracking() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _currentPosition = pos;
      });
      _loadPlaces();
    }

    _positionStreamSubscription = LocationService.getPositionStream().listen((Position newPos) {
      if (mounted) {
        setState(() {
          _currentPosition = newPos;
        });
        // Recalculate distances as user moves
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
      _updateMapMarkers();
    });
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // User location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You are here', snippet: 'Exploring Jaipur'),
        ),
      );
    }

    // Place markers
    for (int i = 0; i < _filteredPlaces.length; i++) {
      final place = _filteredPlaces[i];
      // Color code: Orange for Visual Food Stalls, Amber/Red for Top Visited, Violet for others
      double markerHue = BitmapDescriptor.hueViolet;
      if (place.isVisualFoodStall) {
        markerHue = BitmapDescriptor.hueOrange;
      } else if (place.isTopVisited) {
        markerHue = BitmapDescriptor.hueRose;
      }

      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: 'Visual ${place.visualScore}% • ${place.mustTry}',
            onTap: () => PlaceDetailModal.show(context, place),
          ),
          onTap: () {
            setState(() {
              _selectedPlace = place;
            });
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          },
        ),
      );
    }

    _markers = markers;
  }

  Future<void> _animateToPlace(Place place) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(place.latitude, place.longitude),
          zoom: 15.5,
        ),
      ),
    );
  }

  Future<void> _recenterOnUser() async {
    final GoogleMapController controller = await _controller.future;
    final lat = _currentPosition?.latitude ?? LocationService.defaultLat;
    final lng = _currentPosition?.longitude ?? LocationService.defaultLng;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 14.5),
      ),
    );
  }

  void _navigateToPlace(Place place) async {
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
      body: Stack(
        children: [
          // 1. Interactive Google Map
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
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
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore, color: Colors.deepOrange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exploring Jaipur',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Visual food stalls & top visited spots',
                              style: TextStyle(
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

          // 3. Floating Bottom Place Cards Carousel
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
                  _animateToPlace(place);
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
            ),
        ],
      ),
    );
  }
}

