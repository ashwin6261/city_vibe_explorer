# City Vibe Explorer 🗺️✨

A smart city exploration mobile application (Flutter) & web preview app designed to showcase **the most visual food stalls** and **top-visited places** in a city (pre-loaded with Jaipur, Rajasthan), with real-time GPS location tracking and mood-based recommendations.

---

## 🌟 Key Features

1. **Interactive Map**:
   - Google Maps SDK on Flutter (Android & iOS).
   - Instant interactive web map preview (`web_preview/index.html`) ready to open in any web browser.
   - Dynamic custom pin markers distinguishing **Visual Food Stalls** (Orange/Fire), **Top Visited Places** (Gold/Star), and other gems.

2. **Real-Time City Exploration**:
   - Live GPS tracking (`geolocator` on Flutter, HTML5 Geolocation on Web).
   - Dynamic distance calculations (`km away`) that update continuously as you move around the city.
   - Built-in **"Simulate Walking" mode** to watch highlights pop up as you traverse scenic Jaipur routes (MI Road &rarr; Bapu Bazaar &rarr; Hawa Mahal &rarr; Masala Chowk).

3. **Mood & Vibe Filter Carousel**:
   - 🍔 **Foodie Cravings**: Sizzling kachori kadhais, clay kulhad lassis, bun maska chai.
   - 📸 **Insta-Visual**: Highest visual scores (90-100%), symmetry corridors, palace jharokhas.
   - 🏰 **Heritage & Forts**: Amer Fort, Hawa Mahal, Nahargarh sunset ramparts, Jal Mahal.
   - ☕ **Chill Cafes**: Rooftop cafes directly overlooking historic monuments.
   - 🛍️ **Bazaars & Crafts**: Bapu Bazaar, Johari Bazaar street chaat lanes.
   - 🌙 **Lively Nightlife**: Illuminated monuments and hilltop night views.

4. **Detailed Place Modal & Turn-by-Turn Navigation**:
   - Visual index score (e.g. 99% photogenic).
   - "Must-Try" signature food item & photography angle.
   - Direct **"Go Here / Navigate"** button that opens turn-by-turn routing in Google Maps.

---

## 🚀 How to Run

### 1. Instant Web Preview (No setup required!)
Since your machine might not have the Flutter SDK installed yet, you can immediately test and interact with the full experience right now:
- Double click or open in your browser:
  `c:/Users/ashwi/Downloads/test/organizer/city_vibe_explorer/web_preview/index.html`

### 2. Flutter Mobile App (Android & iOS)
Once you have the Flutter SDK installed:
```bash
cd city_vibe_explorer
flutter pub get
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY --dart-define=MAPTILER_KEY=YOUR_MAPTILER_KEY
```
> The key is optional for a first run: without it the app still works with the curated
> Jaipur data (the native map simply renders unkeyed). See the key section below.

---

## 🔑 Google Maps API Key Configuration

The key is **never** stored in source control. It is injected at build time:

```bash
flutter run   --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
```

- `lib/config/app_config.dart` reads it via `String.fromEnvironment` for the **Places (New)** API.
- `android/app/build.gradle` reads the `GOOGLE_MAPS_API_KEY` **Gradle property / env var** and
  forwards it to `AndroidManifest.xml` as the `${GOOGLE_MAPS_API_KEY}` placeholder for the
  native **Maps SDK**.
- In CI it comes from the `GOOGLE_MAPS_API_KEY` repository secret
  (`.github/workflows/build-apk.yml`).

Restrict the key by Android package name `com.example.city_vibe_explorer` and SHA-1 fingerprint.

## 🗺️ Free Map (MapTiler / OpenStreetMap)

The map works **100% free with no key** using CARTO/OpenStreetMap tiles. To use
nicer **MapTiler** tiles (free tier: 100k requests/day), grab a free key at
https://maptiler.com and pass it:

```bash
flutter run   --dart-define=MAPTILER_KEY=YOUR_MAPTILER_KEY
flutter build apk --release --dart-define=MAPTILER_KEY=YOUR_MAPTILER_KEY
```

Or add `MAPTILER_KEY` as a GitHub repository secret (used by CI) / Render env var.
When the key is empty, the app automatically falls back to CARTO tiles.

### Prototyping with Maps Demo Key
For zero-cost prototyping without a billing account, you can mint a free Maps Demo Key:
1. Visit https://mapsplatform.google.com/maps-demo-key?utm_campaign=gmp_git_agentskills_v1
2. Sign in with any Google account.
3. Paste the key into your environment or configuration.

---

## 📁 Project Structure

```
city_vibe_explorer/
├── lib/
│   ├── main.dart                          # App entrypoint & theme
│   ├── models/
│   │   └── place.dart                     # Place data model with visual score & must-try
│   ├── data/
│   │   └── curated_places.dart            # Curated Jaipur visual food stalls & landmarks
│   ├── services/
│   │   ├── location_service.dart          # GPS tracking & distance computation
│   │   └── places_service.dart            # Mood filtering & Google Places API sync
│   ├── screens/
│   │   └── map_explorer_screen.dart       # Main screen with map, chips, & bottom cards
│   └── widgets/
│       ├── mood_selector.dart             # Mood chips & quick highlight toggles
│       ├── place_card.dart                # Carousel cards with visual badges
│       └── place_detail_modal.dart        # Swipe-up sheet with photos & navigation
├── android/
│   └── app/src/main/AndroidManifest.xml   # Android location permissions & Maps API key
├── ios/
│   └── Runner/Info.plist                  # iOS location descriptions & Maps setting
├── web_preview/
│   └── index.html                         # Instant browser-runnable preview with walking simulation
├── pubspec.yaml                           # Flutter dependencies
└── README.md
```

