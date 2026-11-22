import 'package:flutter_test/flutter_test.dart';
import 'package:city_vibe_explorer/widgets/mood_selector.dart';

void main() {
  // Smoke test that intentionally does NOT pump the GoogleMap widget, so it
  // runs in CI without a Maps API key or platform channels. It also prevents
  // `flutter create` from generating the template's default MyApp widget test.
  test('mood categories include All Vibes and Foodie Cravings', () {
    expect(moodCategories, isNotEmpty);
    expect(moodCategories.first.id, 'all');
    expect(moodCategories.any((m) => m.id == 'foodie'), isTrue);
    expect(moodCategories.any((m) => m.id == 'heritage'), isTrue);
  });
}