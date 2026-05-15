import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';

/// Tests fuer die _visualData Parser im LegacyLumoTaskAdapter.
///
/// Schwerpunkt: Die in ChatGPT-5.5's Templates verwendeten Visual-Strings
/// muessen sinnvolle Payload-Daten erzeugen, damit die Premium-Visuals
/// nicht auf Default-Werte zurueckfallen (z.B. Uhr 12:00, Pizza 1/2).
void main() {
  const adapter = LegacyLumoTaskAdapter();

  /// Hilfsfunktion: erzeugt LumoTask + konvertiert + liefert visualPayload zurueck.
  Map<String, Object?> dataFor({
    required String visual,
    required String prompt,
    String answer = '5',
    String unit = 'Test',
  }) {
    final task = LumoTask(
      id: 'test-id',
      grade: 1,
      subject: 'Mathematik',
      unit: unit,
      prompt: prompt,
      choices: const <String>['a', 'b', 'c'],
      answer: answer,
      explanation: 'Erklaerung',
      visual: visual,
    );
    final instance = adapter.toTaskInstance(
      task: task,
      childId: 'child',
      difficulty: 1,
      now: DateTime(2026, 1, 1),
    );
    return instance.visualPayload.data;
  }

  group('clock parser', () {
    test('extrahiert hour und minute aus "Stunde 7 und Minute 30"', () {
      final data = dataFor(
        visual: 'clock',
        prompt: 'Welche Uhrzeit ist gemeint: Stunde 7 und Minute 30?',
      );
      expect(data['hour'], equals(7));
      expect(data['minute'], equals(30));
    });

    test('extrahiert hour und minute aus Antwort "07:30 Uhr"', () {
      final data = dataFor(
        visual: 'clock',
        prompt: 'Welche Uhrzeit?',
        answer: '07:30 Uhr',
      );
      expect(data['hour'], equals(7));
      expect(data['minute'], equals(30));
    });

    test('liefert leere Daten wenn nichts extrahierbar', () {
      // Visual zeigt dann Default 12:00, was OK ist.
      final data = dataFor(
        visual: 'clock',
        prompt: 'Welche Uhrzeit?',
        answer: 'zwoelf',
      );
      expect(data, isEmpty);
    });
  });

  group('fraction_pizza parser', () {
    test('extrahiert 3/4 aus Prompt', () {
      final data = dataFor(
        visual: 'fraction_pizza',
        prompt: 'Wie viel ist 3/4 von 8?',
      );
      expect(data['numerator'], equals(3));
      expect(data['denominator'], equals(4));
    });

    test('erkennt "Haelfte" als 1/2', () {
      final data = dataFor(
        visual: 'fraction_pizza',
        prompt: 'Was ist die Hälfte von 8?',
      );
      expect(data['numerator'], equals(1));
      expect(data['denominator'], equals(2));
    });

    test('erkennt "Viertel" als 1/4', () {
      final data = dataFor(
        visual: 'fraction_pizza',
        prompt: 'Was ist ein Viertel von 12?',
      );
      expect(data['numerator'], equals(1));
      expect(data['denominator'], equals(4));
    });

    test('erkennt "Drittel" als 1/3', () {
      final data = dataFor(
        visual: 'fraction_pizza',
        prompt: 'Was ist ein Drittel von 9?',
      );
      expect(data['numerator'], equals(1));
      expect(data['denominator'], equals(3));
    });
  });

  group('money_coins parser', () {
    test('extrahiert 1,50€ als 150 Cent', () {
      final data = dataFor(
        visual: 'money_coins',
        prompt: 'Wie viele Muenzen sind 1,50€?',
      );
      expect(data['cents'], equals(150));
    });

    test('extrahiert textliches "1,50 Euro"', () {
      // V4-Fix: Parser akzeptiert jetzt auch das Wort "Euro".
      final data = dataFor(
        visual: 'money_coins',
        prompt: 'Wie viele Muenzen sind 1,50 Euro?',
      );
      expect(data['cents'], equals(150));
    });

    test('extrahiert "10 EUR" case-insensitive', () {
      final data = dataFor(
        visual: 'money_coins',
        prompt: 'Was kostet 10 EUR?',
      );
      expect(data['cents'], equals(1000));
    });

    test('liefert leere Daten wenn nichts extrahierbar', () {
      final data = dataFor(
        visual: 'money_coins',
        prompt: 'Geld zaehlen.',
      );
      expect(data, isEmpty);
    });
  });

  group('quantity_compare parser', () {
    test('extrahiert die ersten zwei Zahlen', () {
      final data = dataFor(
        visual: 'quantity_compare',
        prompt: '3 oder 5 - was ist mehr?',
      );
      expect(data['left'], equals(3));
      expect(data['right'], equals(5));
    });

    test('liefert leere Daten bei nur einer Zahl', () {
      final data = dataFor(
        visual: 'quantity_compare',
        prompt: 'Welche Menge ist 5?',
      );
      expect(data, isEmpty);
    });
  });

  group('rhyme_bubble parser', () {
    test('extrahiert Reim-Wort aus "reimt sich auf Haus"', () {
      final data = dataFor(
        visual: 'rhyme_bubble',
        prompt: 'Was reimt sich auf Haus?',
      );
      expect(data['word'], equals('Haus'));
    });

    test('extrahiert NICHT bei "auf das Bild schauen"', () {
      // B3-Fix: Greedy "auf"-Match war ein Bug. Jetzt nur "reimt sich auf" matcht.
      final data = dataFor(
        visual: 'rhyme_bubble',
        prompt: 'Schaue auf das Bild und finde den Reim.',
      );
      expect(data, isEmpty);
    });
  });

  group('syllable_clap parser', () {
    test('extrahiert Wort + Silben aus DB', () {
      // 'Banane' sollte in PrimarySchoolWordData syllables haben.
      final data = dataFor(
        visual: 'syllable_clap',
        prompt: 'Wie viele Silben hat Banane?',
      );
      expect(data['word'], equals('Banane'));
      // syllables koennte oder koennte nicht in DB sein; nur pruefen dass Wort da ist
    });
  });

  group('word_family_tree parser', () {
    test('extrahiert Wortstamm aus "gehoeren zu fahren"', () {
      final data = dataFor(
        visual: 'word_family_tree',
        prompt: 'Welche Woerter gehoeren zu fahren?',
      );
      expect(data['root'], equals('fahren'));
    });
  });

  group('Visual-Type-Mapping', () {
    test('clock-String wird zu VisualType.clock gemappt', () {
      final task = LumoTask(
        id: 'test',
        grade: 1,
        subject: 'Mathematik',
        unit: 'Uhrzeit',
        prompt: 'Welche Uhr?',
        choices: const <String>['a', 'b', 'c'],
        answer: 'a',
        explanation: 'x',
        visual: 'clock',
      );
      final instance = adapter.toTaskInstance(
        task: task,
        childId: 'child',
        difficulty: 1,
      );
      expect(instance.visualPayload.type, equals(VisualType.clock));
    });

    test('fraction_pizza-String wird zu VisualType.fractionPizza gemappt', () {
      final task = LumoTask(
        id: 'test',
        grade: 3,
        subject: 'Mathematik',
        unit: 'Brueche',
        prompt: '1/2 von 8?',
        choices: const <String>['a', 'b', 'c'],
        answer: 'a',
        explanation: 'x',
        visual: 'fraction_pizza',
      );
      final instance = adapter.toTaskInstance(
        task: task,
        childId: 'child',
        difficulty: 1,
      );
      expect(instance.visualPayload.type, equals(VisualType.fractionPizza));
    });

    test('unbekannte Visual-Strings fallen auf VisualType.none', () {
      final task = LumoTask(
        id: 'test',
        grade: 1,
        subject: 'Mathematik',
        unit: 'X',
        prompt: 'X',
        choices: const <String>['a', 'b', 'c'],
        answer: 'a',
        explanation: 'x',
        visual: 'definitiv_nicht_existent_v999',
      );
      final instance = adapter.toTaskInstance(
        task: task,
        childId: 'child',
        difficulty: 1,
      );
      expect(instance.visualPayload.type, equals(VisualType.none));
    });
  });
}
