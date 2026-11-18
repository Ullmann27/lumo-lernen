// Fachprüfung 2026-11 (Englisch): Wörter und Sätze gemischt (E-M2), fast
// gleiche Antworten nebeneinander (E-M3), dasselbe Wort mit verschiedenen
// Übersetzungen (E-M4), nur eine Richtung (E-M1, teilweise), E-L1 bis E-L4.
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/english_vocabulary_extensions.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

bool _isSentence(String text) => RegExp(r'[.?!]$').hasMatch(text.trim());

String _core(String value) => value
    .toLowerCase()
    .replaceFirst(RegExp(r'^(am|im|in der|die|der|das) '), '')
    .trim();

void main() {
  final forward = <LumoTask>[];
  final reverse = <LumoTask>[];
  final meanings = <int, Map<String, String>>{};

  setUpAll(() {
    for (var grade = 1; grade <= 4; grade++) {
      meanings[grade] = <String, String>{};
      for (final unit in englishVocabularyExtensions[grade]!.keys) {
        final factory = ExerciseFactory(seed: 40 + grade);
        for (var i = 0; i < 500; i++) {
          final task =
              factory.next(grade: grade, subject: 'Englisch', unit: unit);
          if (task.subject != 'Englisch') continue;
          if (task.prompt.contains('auf Englisch')) {
            reverse.add(task);
          } else {
            forward.add(task);
            final english = RegExp('„(.+)“').firstMatch(task.prompt)!.group(1)!;
            meanings[grade]![english] = task.answer;
          }
        }
      }
    }
  });

  test('jede Englisch-Aufgabe: eindeutige Antworten, genau eine richtig', () {
    expect(forward.length, greaterThan(3000));
    for (final task in <LumoTask>[...forward, ...reverse]) {
      final reason = 'Klasse ${task.grade} ${task.unit}: ${task.prompt} '
          '${task.choices}';
      expect(task.choices.length, greaterThanOrEqualTo(3), reason: reason);
      expect(task.choices.map((choice) => choice.toLowerCase()).toSet(),
          hasLength(task.choices.length),
          reason: reason);
      expect(task.choices.where((choice) => choice == task.answer),
          hasLength(1),
          reason: reason);
    }
  });

  test('keine fast gleichen deutschen Antworten nebeneinander', () {
    for (final task in forward) {
      final answer = _core(task.answer);
      for (final choice in task.choices.where((c) => c != task.answer)) {
        final other = _core(choice);
        final reason = '„$choice“ neben „${task.answer}“ in ${task.prompt}';
        expect(other, isNot(answer), reason: reason);
        if (choice.contains(' ') || task.answer.contains(' ')) continue;
        final shorter = other.length <= answer.length ? other : answer;
        final longer = other.length <= answer.length ? answer : other;
        expect(shorter.length >= 4 && longer.endsWith(shorter), isFalse,
            reason: reason);
      }
    }
  });

  test('Wörter stehen neben Wörtern, Sätze neben Sätzen', () {
    for (final task in forward) {
      final english = RegExp('„(.+)“').firstMatch(task.prompt)!.group(1)!;
      final sentence = _isSentence(english);
      expect(task.prompt.startsWith('Was bedeutet dieser Satz?'), sentence,
          reason: task.prompt);
      expect(task.choices.every((choice) => _isSentence(choice) == sentence),
          isTrue,
          reason: '${task.prompt} ${task.choices}');
    }
  });

  test('Gegenrichtung Deutsch → Englisch ab Klasse 3, eindeutig lösbar', () {
    expect(reverse.where((task) => task.grade <= 2), isEmpty);
    for (final grade in <int>[3, 4]) {
      final tasks = reverse.where((task) => task.grade == grade).toList();
      expect(tasks.length, greaterThan(500), reason: 'Klasse $grade');
      for (final task in tasks) {
        final german = RegExp('„(.+)“').firstMatch(task.prompt)!.group(1)!;
        final known = meanings[grade]!;
        expect(known[task.answer], german, reason: task.prompt);
        for (final choice in task.choices.where((c) => c != task.answer)) {
          expect(known.containsKey(choice), isTrue, reason: choice);
          expect(_core(known[choice]!), isNot(_core(german)),
              reason: '„$choice“ wäre auch richtig für „$german“');
        }
        expect(
            task.choices.every((choice) =>
                _isSentence(choice) == _isSentence(task.answer)),
            isTrue,
            reason: '${task.prompt} ${task.choices}');
      }
    }
  });

  test('ein englisches Wort hat in allen Klassen dieselbe Übersetzung', () {
    final seen = <String, String>{};
    meanings.forEach((grade, map) {
      map.forEach((english, german) {
        final earlier = seen.putIfAbsent(english, () => german);
        // Zahlen, Körperteile usw. wiederholen sich; die Bedeutung bleibt.
        if (english == 'kite') return; // Drachen / Drachen zum Steigenlassen
        // orange (Farbe) und Orange (Frucht) unterscheiden sich nur in der
        // Großschreibung.
        expect(german.toLowerCase(), earlier.toLowerCase(),
            reason: '„$english“ in Klasse $grade');
      });
    });
    expect(seen['pen'], 'Stift');
    expect(seen['desk'], 'Schultisch');
    expect(seen['Switzerland'], 'die Schweiz');
    expect(seen.keys.any((english) => english.startsWith('Let us')), isFalse);
    expect(seen.containsKey("Let's play."), isTrue);
    expect(seen.containsKey('England'), isFalse);
  });
}
