import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/renderers/lumo_premium_visuals.dart';

/// Befund L3 der Fachprüfung Mathematik (17.11.2026): Das Themenbild
/// suchte Wortteile („Paradeiser“ enthält „rad“ → Auto).
void main() {
  test('Themenbild nach ganzen Wörtern', () {
    expect(storyThemeEmoji('Oma erntet 12 Paradeiser.'), isNot('🚗'));
    expect(storyThemeEmoji('Der Preis ist 8 €.'), '💶');
    expect(storyThemeEmoji('Im Aquarium schwimmen 7 Goldfische.'), '🐟');
    expect(storyThemeEmoji('Am Kreis stehen 6 Kinder.'), '📖');
    expect(storyThemeEmoji('Tom fährt mit dem Fahrrad 3 Runden.'), '🚗');
    expect(storyThemeEmoji('Im Schwimmbad sind 15 Kinder.'), '🏊');
    expect(storyThemeEmoji('Lisa kauft 3 Kugeln Eis.'), '🍦');
    expect(storyThemeEmoji('Der Zug hat 4 Wagen.'), '🚆');
    expect(storyThemeEmoji('Lisa hat 4 Äpfel.'), '🍎');
  });
}
