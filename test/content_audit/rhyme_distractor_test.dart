// Fachprüfung 2026-11 (D-S1): In Reimaufgaben stand ein zweites echtes
// Reimwort als "falsche" Antwort (Rose → Dose, daneben Hose). Diese Tests
// verhindern, dass ein Ablenker auf das Zielwort reimt.
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';

/// Grobe, bewusst strenge Reimendung nach der Schreibung: ab dem betonten
/// Selbstlaut, mit den üblichen Gleichklängen (d/t, ee/e, ie/i, Dehnungs-h).
String rhymeKey(String word) {
  final lower = word.toLowerCase().replaceAll('qu', 'kw');
  final groups = RegExp('[aeiouäöüy]+').allMatches(lower).toList();
  if (groups.isEmpty) return lower;
  final unstressedEnding = RegExp(r'(e|el|er|en)$').hasMatch(lower);
  final start = unstressedEnding && groups.length >= 2
      ? groups[groups.length - 2].start
      : groups.last.start;
  var tail = lower.substring(start);
  tail = tail
      .replaceAll('ie', 'i')
      .replaceAll('ee', 'e')
      .replaceAll('oo', 'o')
      .replaceAll('aa', 'a')
      .replaceAll('ai', 'ei')
      .replaceAllMapped(RegExp('([aeiouäöü])h'), (match) => match.group(1)!)
      .replaceAll(RegExp(r'ss$'), 's')
      .replaceAll(RegExp(r'd$'), 't')
      .replaceAll(RegExp(r'b$'), 'p')
      .replaceAll(RegExp(r'g$'), 'k');
  return tail;
}

void main() {
  final template = GermanTaskTemplates.templates
      .firstWhere((template) => template.id == 'g1_rhyme');

  test('die vier gemeldeten Reimwörter sind als Reimpartner hinterlegt', () {
    const reported = <String, String>{
      'Rose': 'hose',
      'See': 'schnee',
      'Fluss': 'bus',
      'Brille': 'marille',
    };
    reported.forEach((word, partner) {
      expect(PrimarySchoolWordData.rhymeBlockedFor(word), contains(partner),
          reason: '$partner reimt auf $word');
    });
  });

  test('kein Wort mit gleicher Reimendung bleibt als Ablenker möglich', () {
    final pool = <String>{
      ...PrimarySchoolWordData.nounsForGrade(4),
      for (final pair in PrimarySchoolWordData.rhymePairs) ...pair,
    };
    final missing = <String>[];
    for (final pair in PrimarySchoolWordData.rhymePairs) {
      final target = pair.first;
      final blocked = PrimarySchoolWordData.rhymeBlockedFor(target);
      for (final candidate in pool) {
        if (candidate == target) continue;
        if (rhymeKey(candidate) != rhymeKey(target)) continue;
        if (!blocked.contains(candidate.toLowerCase())) {
          missing.add('$target/$candidate');
        }
      }
    }
    expect(missing, isEmpty,
        reason: 'Diese Wörter reimen, sind aber nicht als Reimpartner oder '
            'Beinahe-Reim hinterlegt und könnten als falsche Antwort '
            'erscheinen.');
  });

  test('jedes Reimpaar reimt auch nach der Schreibung', () {
    for (final pair in PrimarySchoolWordData.rhymePairs) {
      expect(rhymeKey(pair.first), rhymeKey(pair.last), reason: '$pair');
    }
  });

  test('erzeugte Reimaufgaben bieten nie ein zweites Reimwort an', () {
    for (var grade = 1; grade <= 4; grade++) {
      final gradeTemplate = GermanTaskTemplate(
          id: template.id,
          grade: grade,
          unit: template.unit,
          kind: template.kind,
          promptPattern: template.promptPattern);
      for (var seed = 0; seed < 3000; seed++) {
        final task = gradeTemplate.concretize(seed);
        final word = RegExp(r'auf (.+)\?').firstMatch(task.prompt)!.group(1)!;
        final blocked = PrimarySchoolWordData.rhymeBlockedFor(word);
        final rhyming = task.choices
            .where((choice) =>
                blocked.contains(choice.toLowerCase()) ||
                rhymeKey(choice) == rhymeKey(word))
            .toList();
        expect(rhyming, <String>[task.answer],
            reason: 'Klasse $grade, Seed $seed: ${task.prompt}');
        expect(task.choices.toSet().length, task.choices.length);
        expect(task.choices, hasLength(4));
      }
    }
  });
}
