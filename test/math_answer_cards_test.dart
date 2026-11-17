import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/game_math_tasks.dart';

/// Befund S1 der Fachprüfung Mathematik (17.11.2026): Die Antwortkarten
/// waren immer Lösung − 1, Lösung, + 1, + 2. Die richtige Antwort war damit
/// in 300 von 300 Aufgaben die zweitkleinste Karte und ohne Rechnen zu
/// erkennen. Diese Tests halten fest, dass die Lösung der Größe nach an
/// jeder Stelle vorkommt und dass die Karten eindeutig und sinnvoll sind.
void main() {
  const samples = 300;

  /// Stelle der Lösung der Größe nach: 0 = kleinste Karte.
  int rankOf(String answer, List<String> choices) {
    final value = int.parse(answer);
    return choices.where((choice) => int.parse(choice) < value).length;
  }

  bool allWholeNumbers(MathConcreteTask task) =>
      int.tryParse(task.answer) != null &&
      task.choices.every((choice) => int.tryParse(choice) != null);

  group('Antwortkarten der Mathe-Vorlagen', () {
    for (final template in MathTaskTemplates.templates) {
      if (template.kind == MathTemplateKind.shapeTrace) continue;
      // Feste Wissensfragen („Wie viele Tage hat eine Woche?“) mit drei Karten.
      if (template.kind == MathTemplateKind.dayHours) continue;
      final probe = template.concretize(1);
      if (!allWholeNumbers(probe)) continue;

      test('${template.id}: Lösung liegt an wechselnder Stelle', () {
        final ranks = List<int>.filled(4, 0);
        final positions = List<int>.filled(4, 0);
        var smallAnswers = 0;
        for (var i = 0; i < samples; i++) {
          final task = template.concretize(i * 7919 + 13);
          final reason = '${template.id}: ${task.prompt} ${task.choices}';
          expect(task.choices, hasLength(4), reason: reason);
          expect(task.choices.toSet(), hasLength(4), reason: reason);
          expect(task.choices.where((choice) => choice == task.answer),
              hasLength(1),
              reason: reason);
          for (final choice in task.choices) {
            expect(int.parse(choice), greaterThanOrEqualTo(0), reason: reason);
          }
          ranks[rankOf(task.answer, task.choices)]++;
          positions[task.choices.indexOf(task.answer)]++;
          // Unter 3 gibt es zu wenige kleinere Zahlen ohne Minus.
          if (int.parse(task.answer) < 3) smallAnswers++;
        }
        // Bei gleichmäßiger Verteilung wären es je 75 von 300.
        final strict = smallAnswers == 0;
        for (var rank = 0; rank < 4; rank++) {
          expect(ranks[rank], greaterThanOrEqualTo(strict ? 45 : 20),
              reason: '${template.id}: Größenstelle $rank, Verteilung $ranks');
          expect(ranks[rank], lessThanOrEqualTo(strict ? 110 : 150),
              reason: '${template.id}: Größenstelle $rank, Verteilung $ranks');
          expect(positions[rank], inInclusiveRange(45, 110),
              reason:
                  '${template.id}: Kartenplatz $rank, Verteilung $positions');
        }
      });
    }

    test('Klasse 1 bekommt keine Karten über 20', () {
      for (final template
          in MathTaskTemplates.templates.where((item) => item.grade == 1)) {
        if (template.kind == MathTemplateKind.shapeTrace) continue;
        if (template.kind == MathTemplateKind.dayHours) continue;
        for (var i = 0; i < samples; i++) {
          final task = template.concretize(i * 31 + 5);
          if (!allWholeNumbers(task)) continue;
          for (final choice in task.choices) {
            expect(int.parse(choice), lessThanOrEqualTo(20),
                reason: '${template.id}: ${task.prompt} ${task.choices}');
          }
        }
      }
    });

    test('Zahlenstrahl: keine Karte steht schon in der Reihe', () {
      final template = MathTaskTemplates.templates
          .singleWhere((item) => item.id == 'g1_number_line');
      for (var i = 0; i < samples; i++) {
        final task = template.concretize(i * 17 + 3);
        final shown = RegExp(r'\d+')
            .allMatches(task.prompt)
            .map((match) => match.group(0)!)
            .toSet();
        for (final choice
            in task.choices.where((choice) => choice != task.answer)) {
          expect(shown, isNot(contains(choice)),
              reason: '${task.prompt} ${task.choices}');
        }
      }
    });

    test('falsche Karten sind typische Fehler, nicht nur Nachbarzahlen', () {
      MathTaskTemplate byId(String id) =>
          MathTaskTemplates.templates.singleWhere((item) => item.id == id);

      // Einmaleins: mindestens eine Nachbaraufgabe aus der Reihe.
      var neighbours = 0;
      for (var i = 0; i < samples; i++) {
        final task = byId('g2_tables').concretize(i * 101 + 7);
        final factors = RegExp(r'\d+')
            .allMatches(task.prompt)
            .map((match) => int.parse(match.group(0)!))
            .toList();
        final a = factors[0], b = factors[1];
        final near = {a * (b - 1), a * (b + 1), (a - 1) * b, (a + 1) * b};
        if (task.choices.any((choice) => near.contains(int.parse(choice)))) {
          neighbours++;
        }
      }
      expect(neighbours, greaterThan(samples * 0.9));

      // Schriftliches Rechnen: Die Endziffer allein darf nicht reichen.
      for (final id in [
        'g3_written_add',
        'g3_written_sub',
        'g4_written_mul',
        'g4_add_10000',
        'g4_sub_10000',
      ]) {
        var sameLastDigit = 0;
        for (var i = 0; i < samples; i++) {
          final task = byId(id).concretize(i * 211 + 9);
          final last = task.answer[task.answer.length - 1];
          if (task.choices
              .where((choice) => choice != task.answer)
              .any((choice) => choice.endsWith(last))) {
            sameLastDigit++;
          }
        }
        expect(sameLastDigit, greaterThan(samples * 0.9), reason: id);
      }

      // Zehner und Einer: die andere Ziffer ist als Karte dabei.
      var otherDigit = 0, possible = 0;
      for (var i = 0; i < samples; i++) {
        final task = byId('g2_tens_ones').concretize(i * 53 + 1);
        final number =
            int.parse(RegExp(r'\d+').firstMatch(task.prompt)!.group(0)!);
        final tens = number ~/ 10, ones = number % 10;
        if (tens == ones) continue;
        possible++;
        final other = task.answer == '$tens' ? '$ones' : '$tens';
        if (task.choices.contains(other)) otherDigit++;
      }
      expect(otherDigit, greaterThan(possible * 0.6));
    });

    test('Brüche und Kommazahlen: Lösung ist nicht immer die mittlere Karte',
        () {
      for (final id in ['g4_fraction_add', 'g4_fraction_expand', 'g4_decimal']) {
        final template =
            MathTaskTemplates.templates.singleWhere((item) => item.id == id);
        final ranks = <int, int>{};
        for (var i = 0; i < samples; i++) {
          final task = template.concretize(i * 7919 + 13);
          double value(String text) {
            if (text.contains('/')) {
              final parts = text.split('/');
              return int.parse(parts[0]) / int.parse(parts[1]);
            }
            return double.parse(text.replaceAll(',', '.'));
          }

          final values = task.choices.map(value).toList();
          expect(values.toSet(), hasLength(values.length),
              reason: '$id: gleichwertige Karten ${task.choices}');
          expect(task.choices.where((choice) => choice == task.answer),
              hasLength(1));
          final answer = value(task.answer);
          final rank = values.where((other) => other < answer).length;
          ranks[rank] = (ranks[rank] ?? 0) + 1;
        }
        expect(ranks.length, greaterThanOrEqualTo(3), reason: '$id: $ranks');
        expect(ranks.values.every((count) => count < samples * 0.6), isTrue,
            reason: '$id: $ranks');
      }
    });
  });

  group('Antwortkarten in Logik und Spielen', () {
    test('Zahlenmuster und Regeln kombinieren: Lösung an jeder Größenstelle',
        () {
      for (final entry in {'Zahlenmuster': 2, 'Regeln kombinieren': 4}.entries) {
        final ranks = List<int>.filled(4, 0);
        for (var seed = 0; seed < 6; seed++) {
          final factory = ExerciseFactory(seed: seed);
          for (var i = 0; i < samples ~/ 6; i++) {
            final task = factory.nextExact(
                grade: entry.value, subject: 'Logik', unit: entry.key);
            expect(task.choices, hasLength(4), reason: task.prompt);
            expect(task.choices.toSet(), hasLength(4), reason: task.prompt);
            ranks[rankOf(task.answer, task.choices)]++;
          }
        }
        for (var rank = 0; rank < 4; rank++) {
          expect(ranks[rank], inInclusiveRange(45, 110),
              reason: '${entry.key}: Größenstelle $rank, Verteilung $ranks');
        }
      }
    });

    test('Regeln kombinieren: genau eine Karte erfüllt alle Regeln', () {
      final factory = ExerciseFactory(seed: 4);
      final answers = <int>{};
      for (var i = 0; i < samples; i++) {
        final task = factory.nextExact(
            grade: 4, subject: 'Logik', unit: 'Regeln kombinieren');
        final bounds = RegExp(r'größer als (\d+), kleiner als (\d+)')
            .firstMatch(task.prompt)!;
        final lower = int.parse(bounds[1]!), upper = int.parse(bounds[2]!);
        final fitting = task.choices.where((choice) {
          final value = int.parse(choice);
          return value > lower && value < upper && value.isEven;
        }).toList();
        expect(fitting, [task.answer], reason: '${task.prompt} ${task.choices}');
        answers.add(int.parse(task.answer) - lower);
      }
      // Früher war die Lösung immer genau die Mitte (untere Grenze + 4).
      expect(answers, {2, 4, 6});
    });

    test('Rechenpfad und Rechenhaus: Lösung an jeder Größenstelle', () {
      final pathRanks = List<int>.filled(4, 0);
      final houseRanks = List<int>.filled(4, 0);
      for (final level in GameLevelCatalog.levels) {
        for (var index = 0; index < 40; index++) {
          if (level.miniType == GameMiniType.starsPath) {
            final task = GameMathTasks.starsPath(level, index);
            if (task.choices.length != 4) continue;
            pathRanks[rankOf(task.answer, task.choices)]++;
          } else if (level.miniType == GameMiniType.numberHouse) {
            final task = GameMathTasks.numberHouse(level, index);
            expect(task.isValid, isTrue);
            if (task.choices.length != 4) continue;
            houseRanks[
                task.choices.where((value) => value < task.answer).length]++;
          }
        }
      }
      for (final ranks in [pathRanks, houseRanks]) {
        final total = ranks.reduce((a, b) => a + b);
        expect(total, greaterThan(100));
        for (var rank = 0; rank < 4; rank++) {
          expect(ranks[rank], greaterThan(total * 0.12),
              reason: 'Größenstelle $rank, Verteilung $ranks');
          expect(ranks[rank], lessThan(total * 0.40),
              reason: 'Größenstelle $rank, Verteilung $ranks');
        }
      }
    });
  });
}
