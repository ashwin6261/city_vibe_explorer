/// Compile-time configuration values.
///
/// The Google Maps / Places API key is injected at build time so it never
/// lives in source control:
///
///   flutter run   --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
///   flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
///
/// When empty, the app falls back to the curated places only and the native
/// Google map renders in lite/unkeyed mode.
class AppConfig {
  AppConfig._();

  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
}