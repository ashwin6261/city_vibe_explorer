/// Compile-time configuration values (injected at build time so no keys live in source control).
///
///   flutter run   --dart-define=GOOGLE_MAPS_API_KEY=KEY --dart-define=MAPTILER_KEY=KEY
///   flutter build apk --release --dart-define=MAPTILER_KEY=KEY
///
/// - [mapTilerKey]: when set, the map uses MapTiler vector-style raster tiles.
///   When empty, it falls back to the free CARTO/OpenStreetMap tiles (no key).
/// - [googleMapsApiKey]: enables the Google Places (New) live data + ratings.
class AppConfig {
  AppConfig._();

  static const String mapTilerKey = String.fromEnvironment('MAPTILER_KEY');
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Backend API base URL (e.g. https://vibecity-api.onrender.com).
  /// When set, places/cities are fetched from the backend; when empty, the app
  /// uses direct Nominatim/Overpass (works without a backend).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}