import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_hint_service.dart';

/// Befunde S7, S8 und M19 der Fachprüfung Mathematik: Tipps wurden nach
/// Zeichen und Stichwörtern im Text gewählt. Ein Bindestrich („Kart-Rennen“,
/// „4-mal“) löste den Minus-Tipp aus, das Wort „einer“ („In einer Kiste“)
/// die Zehner-Einer-Hilfe, die Einheit „Zeit“ den Minuten-Tipp.
void main() {
  const hints = TaskHintService();

  LumoTask task(String prompt,
          {required String unit,
          String subject = 'Mathematik',
          int grade = 2}) =>
      LumoTask(
        id: 'hint-structure',
        grade: grade,
        subject: subject,
        unit: unit,
        prompt: prompt,
        answer: 'nicht verwenden',
        choices: const [],
        explanation: 'nicht verwenden',
      );

  List<String> stages(LumoTask value) =>
      [for (var level = 1; level <= 3; level++) hints.explain(value, level: level)];

  const minusTip = 'nimm die zweite Menge weg';
  const plusTip = 'lege die zweite dazu';

  group('S7: kein Minus-Tipp wegen eines Bindestrichs', () {
    test('Plus-Geschichte mit „Kart-Rennen“ bekommt einen Plus-Tipp', () {
      final all = stages(task(
          'Bei Lumos Kart-Rennen fährt Ola 1 Runden und Pip 1 Runden. '
          'Wie viele Runden fahren beide zusammen?',
          unit: 'Rechengeschichten'));
      expect(all.first, contains('Plusaufgabe'));
      for (final text in all) {
        expect(text, isNot(contains(minusTip)));
        expect(text, isNot(contains('Minus')));
      }
    });

    test('Uhr-Abenteuer zählt Stunden weiter', () {
      final all = stages(task(
          'Lumos Kart-Turnier beginnt um 7 Uhr und dauert 1 Stunde. '
          'Um wie viel Uhr ist es aus?',
          unit: 'Uhr-Abenteuer'));
      expect(all.first, 'Zähle die Stunden von der Startzeit weiter.');
      for (final text in all) {
        expect(text, isNot(contains(minusTip)));
        expect(text, isNot(contains('Wandle zuerst die ganzen Stunden um')));
      }
    });

    test('Zahlenrätsel „4-mal“ führt zum Teilen', () {
      final all = stages(task(
          'Ola denkt sich eine Zahl und nimmt sie 4-mal. Das ergibt 12. '
          'Welche Zahl ist es?',
          unit: 'Zahlenrätsel'));
      expect(all[0], contains('Teilen'));
      expect(all[1], contains('4er-Schritten bis 12'));
      for (final text in all) {
        expect(text, isNot(contains(minusTip)));
      }
    });

    test('Platzhalter „★ − 8 = 7“ rechnet zurück statt wegzunehmen', () {
      final all = stages(task(
          'Lumo hat eine Zahl mit einem Stern verdeckt: ★ − 8 = 7. '
          'Welche Zahl versteckt sich unter dem Stern?',
          unit: 'Platzhalter-Rätsel'));
      expect(all[0], contains('Rechne zurück'));
      expect(all[1], 'Lege zu 7 wieder 8 dazu. So findest du die Zahl unter dem Stern.');
      for (final text in all) {
        expect(text, isNot(contains(minusTip)));
        expect(RegExp(r'\b15\b').hasMatch(text), isFalse, reason: text);
      }
    });

    test('Platzhalter „7 + ★ = 13“ ergänzt statt zusammenzulegen', () {
      final all = stages(task(
          'Lumo hat eine Zahl mit einem Stern verdeckt: 7 + ★ = 13. '
          'Welche Zahl versteckt sich unter dem Stern?',
          unit: 'Platzhalter-Rätsel'));
      expect(all[0], contains('Zähle von 7 weiter bis 13'));
      for (final text in all) {
        expect(text, isNot(contains(plusTip)));
        expect(RegExp(r'\b6\b').hasMatch(text), isFalse, reason: text);
      }
    });

    test('reine Rechnungen behalten ihren Plus- und Minus-Tipp', () {
      expect(hints.explain(task('9 - 4 = ?', unit: 'Minus bis 10')),
          contains(minusTip));
      expect(hints.explain(task('62 − 24 = ?', unit: 'Minus bis 100')),
          contains(minusTip));
      expect(hints.explain(task('5 + 3 = ?', unit: 'Plus bis 10')),
          contains(plusTip));
    });

    test('alle Abenteuer-Aufgaben: drei eigene Stufen, passende Rechenart', () {
      const units = <String>[
        'Rechengeschichten',
        'Zahlenmauer',
        'Zahlenrätsel',
        'Marktstand',
        'Platzhalter-Rätsel',
        'Größer, kleiner, gleich',
        'Uhr-Abenteuer',
      ];
      for (var grade = 1; grade <= 4; grade++) {
        for (final unit in units) {
          if (unit == 'Uhr-Abenteuer' && grade == 1) continue;
          final factory = ExerciseFactory(seed: grade * 100 + unit.length);
          for (var i = 0; i < 150; i++) {
            final value = factory.nextExact(
                grade: grade, subject: 'Mathematik', unit: unit);
            final all = stages(value);
            final reason = '$unit Klasse $grade: ${value.prompt}';
            expect(all.toSet(), hasLength(3), reason: reason);
            for (final text in all) {
              expect(text.trim(), isNotEmpty, reason: reason);
              expect(text, isNot(contains(minusTip)), reason: reason);
              expect(text, isNot(contains(plusTip)), reason: reason);
              expect(text, isNot(contains('Prüfe Zahlen, Form oder Reihenfolge')),
                  reason: reason);
              // Die Lösung darf nur vorkommen, wenn sie schon in der
              // Aufgabe steht.
              final answer = RegExp(r'^\d+').firstMatch(value.answer)?.group(0);
              if (answer != null &&
                  int.parse(answer) > 3 &&
                  answer != '60' &&
                  !RegExp('\\b$answer\\b').hasMatch(value.prompt)) {
                expect(RegExp('(?<![\\d,:])$answer(?![\\d,:])').hasMatch(text),
                    isFalse,
                    reason: '$reason → $text');
              }
            }
            if (unit == 'Rechengeschichten') {
              final why = value.explanation;
              final plus = why.contains(' + ');
              final minus = why.contains(' − ');
              final times = why.contains(' · ');
              final shared = why.contains(' : ');
              if (plus && !minus && !times && !shared) {
                expect(all.first, contains('Plusaufgabe'), reason: reason);
              }
              if (minus && !plus && !times && !shared) {
                expect(all.first, contains('Minusaufgabe'), reason: reason);
              }
              if (shared) expect(all.first, contains('teilen'), reason: reason);
              if (times && !plus && !minus && !shared) {
                expect(all.first, contains('Malaufgabe'), reason: reason);
              }
            }
          }
        }
      }
    });
  });

  group('S8: keine Zehner-Einer-Hilfe wegen des Wortes „einer“', () {
    test('Sachaufgabe „In einer Kiste …“ bekommt einen Sachaufgaben-Tipp', () {
      final all = stages(task(
          'In einer Kiste liegen 32 Äpfel und 6 Birnen. Eine zweite Kiste '
          'enthält genau gleich viele Früchte. 4 Früchte werden gegessen. '
          'Wie viele bleiben insgesamt?',
          unit: 'Sachaufgaben drei Schritte',
          grade: 4));
      expect(all.first, contains('Was weißt du schon'));
      for (final text in all) {
        expect(text, isNot(contains('Zehner')));
        expect(text, isNot(contains('Bündel')));
        expect(text, isNot(contains('Würfel')));
        expect(text, isNot(contains('Probiere danach')));
      }
    });

    test('erzeugte Sachaufgaben bekommen nie die Stellenwerthilfe', () {
      for (final entry in {
        'Textaufgaben': 2,
        'Sachaufgaben zwei Schritte': 3,
        'Sachaufgaben drei Schritte': 4,
      }.entries) {
        final factory = ExerciseFactory(seed: 21);
        for (var i = 0; i < 200; i++) {
          final value = factory.nextExact(
              grade: entry.value, subject: 'Mathematik', unit: entry.key);
          for (final text in stages(value)) {
            expect(text, isNot(contains('Zehnerstangen')), reason: value.prompt);
            expect(text, isNot(contains('Zehnerbündel')), reason: value.prompt);
          }
        }
      }
    });

    test('echte Stellenwertfragen behalten die Hilfe', () {
      final ones = stages(task('Wie viele Einer hat 27?', unit: 'Zehner und Einer'));
      expect(ones[0], contains('Einer'));
      expect(ones[2], contains('2 Zehnerstangen und 7 einzelne Würfel'));
      final tens = stages(task('Wie viele Zehner hat 56?', unit: 'Zehner und Einer'));
      expect(tens[0], contains('Zehnerbündel'));
      expect(tens[1], contains('Zerlege 56 in 50 und 6'));
      // Auch ohne passende Einheit, wenn ausdrücklich danach gefragt wird.
      expect(
          hints.explain(task('Wie viele Zehner hat 47?', unit: 'Üben')),
          contains('Zehnerbündel'));
    });
  });

  group('M19: Tipps passen zur Einheit', () {
    test('Tageszeiten bekommen keinen Minuten-Tipp', () {
      for (final text in stages(task(
          'Welche Tageszeit folgt auf den Nachmittag?',
          unit: 'Zeit',
          grade: 1))) {
        expect(text, isNot(contains('60 Minuten')));
        expect(text, isNot(contains('Wandle')));
      }
      expect(
          hints.explain(task('Wie viele Minuten sind 3 Stunden?',
              unit: 'Zeit Minuten und Stunden', grade: 4)),
          contains('60 Minuten'));
    });

    test('schriftliches Malrechnen: niemand legt 390 Gruppen', () {
      final all = stages(task('Schriftlich: 390 × 9 = ?',
          unit: 'Schriftliche Multiplikation', grade: 4));
      expect(all[1], isNot(contains('Lege 390 gleich große Gruppen')));
      expect(all[2], isNot(contains('Mache genau 390 Schritte')));
      expect(all[1], contains('Zerlege 390'));
      expect(all[2], contains('merke dir die Zehner'));
      // Das kleine Einmaleins darf weiter gelegt und gezählt werden.
      expect(
          hints.explain(task('3 × 7 = ?', unit: 'Einmaleins'), level: 2),
          contains('Lege 3 gleich große Gruppen'));
    });

    test('Mengenvergleich zählt, statt Stellen zu vergleichen', () {
      final text = hints.explain(task('🍎🍎🍎 oder 🍎🍎🍎🍎🍎 – wo ist mehr?',
          unit: 'Mengenvergleich', grade: 1));
      expect(text, contains('Zähle'));
      expect(text, isNot(contains('Stelle')));
      expect(text, isNot(contains('Vergleichszeichens')));
    });

    test('große Zahlen vergleichen: zuerst die Stellen zählen', () {
      final text = hints.explain(task('Welches Zeichen passt? 27441 ? 173684',
          unit: 'Zahlenraum bis 1 Million', grade: 4));
      expect(text, contains('Zähle zuerst die Stellen'));
    });

    test('Logik: Was passt nicht? und Geheimcode haben eigene Tipps', () {
      final odd = stages(task(
          'Lumo hat vier Dinge gefunden. Was passt nicht dazu? Banane, Zug, Bus, Auto',
          unit: 'Was passt nicht?',
          subject: 'Logik'));
      expect(odd[0], contains('Gemeinsame'));
      final code = stages(task(
          'Geheimbotschaft von Lumo! Im Code ist A = 1, B = 2, C = 3 und so '
          'weiter bis Z = 26. Welches Wort heißt 8-21-14-4?',
          unit: 'Geheimcode',
          subject: 'Logik'));
      expect(code[0], contains('Alphabet'));
      for (final text in [...odd, ...code]) {
        expect(text, isNot(contains('geraden Zahlen')));
        expect(text, isNot(contains('Figur')));
      }
      expect(odd.toSet(), hasLength(3));
      expect(code.toSet(), hasLength(3));
    });

    test('Reihenfolgen bekommen keinen Tipp über gerade Zahlen', () {
      final value = task(
          'Von links nach rechts stehen Ben, Ali und Mia. Wer steht ganz links?',
          unit: 'Reihenfolgen',
          subject: 'Logik');
      for (var level = 2; level <= 3; level++) {
        expect(hints.explain(value, level: level), isNot(contains('geraden Zahlen')));
      }
      expect(
          hints.explain(
              task('Welche Zahl erfüllt alle drei Regeln: größer als 20, kleiner als 28 und gerade?',
                  unit: 'Regeln kombinieren', subject: 'Logik'),
              level: 3),
          contains('geraden Zahlen'));
    });
  });
}
