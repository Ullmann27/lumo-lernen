import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning_modules/uhr_lernen/uhr_lernen_screen.dart';

/// Befund L11 der Fachprüfung Mathematik (17.11.2026).
void main() {
  test('Hilfe nennt auch die ostösterreichische Sprechweise', () {
    expect(uhrViertelSprechweise(3, 15), 'Manche sagen auch „viertel 4“.');
    expect(uhrViertelSprechweise(3, 45), 'Manche sagen auch „dreiviertel 4“.');
    expect(uhrViertelSprechweise(12, 15), 'Manche sagen auch „viertel 1“.');
    expect(uhrViertelSprechweise(3, 30), isEmpty);
  });
}
