import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/error_patterns.dart';

Attempt _w(String prompt, String given, String expected,
        {String subject = 'Mathematik', bool correct = false}) =>
    Attempt(
      id: prompt + given,
      studentId: 's',
      subject: subject,
      unit: 'u',
      competency: 'c',
      correct: correct,
      at: DateTime(2026),
      prompt: prompt,
      given: given,
      expected: expected,
    );

void main() {
  const d = ErrorPatternDetector();

  test('Addition: Zehner vergessen, Rechenart, Ziffern, verzählt', () {
    expect(d.detect(_w('8 + 5 = ?', '3', '13')), 'Zehner beim Übergang vergessen');
    expect(d.detect(_w('9 + 4 = ?', '5', '13')), 'Minus statt Plus gerechnet');
    expect(d.detect(_w('17 + 14 = ?', '13', '31')), 'Ziffern vertauscht');
    expect(d.detect(_w('6 + 7 = ?', '12', '13')), 'um eins verzählt');
  });

  test('Subtraktion: typische Fehler beim Zehnerübergang', () {
    expect(d.detect(_w('13 − 5 = ?', '18', '8')), 'Plus statt Minus gerechnet');
    expect(d.detect(_w('52 - 27 = ?', '35', '25')),
        'kleinere Einerziffer von der größeren abgezogen');
    expect(d.detect(_w('42 - 8 = ?', '44', '34')),
        'Zehner beim Übergang nicht abgezogen');
  });

  test('Einmaleins und Division', () {
    expect(d.detect(_w('6 × 7 = ?', '13', '42')), 'Plus statt Mal gerechnet');
    expect(d.detect(_w('6 × 7 = ?', '48', '42')),
        'in der Malreihe um einen Schritt verrutscht');
    expect(d.detect(_w('12 : 3 = ?', '36', '4')), 'Mal statt Geteilt gerechnet');
  });

  test('Lesen: das schwierige Wort ist das Muster', () {
    expect(d.detect(_w('Der Igel schläft.', 'schläft', '', subject: 'Lesen')),
        'schwieriges Wort „schläft“');
  });

  test('Richtige Antworten und unklare Daten liefern kein Muster', () {
    expect(d.detect(_w('8 + 5 = ?', '13', '13', correct: true)), isNull);
    expect(d.detect(_w('Welches Wort reimt sich?', 'Haus', 'Maus')), isNull);
    expect(d.detect(_w('8 + 5 = ?', 'dreizehn', '13')), isNull);
    expect(d.detect(_w('8 + 5 = ?', '20', '13')), isNull);
  });
}
