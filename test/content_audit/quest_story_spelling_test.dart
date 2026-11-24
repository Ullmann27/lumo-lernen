// Fachprüfung 2026-11 (D-S4): Die Quest-Geschichten standen ohne Umlaute und
// ß im Leser ("im grossen Apfelgarten", "Aepfel", "Baeckerei").
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_quest_library.dart';

import 'ersatz_spelling.dart';

void main() {
  test('die Prüfhilfe erkennt Ersatzschreibungen und lässt echte Wörter zu',
      () {
    expect(
        ersatzSpellingsIn('Im grossen Garten haengen Aepfel fuer die '
            'Baeckerei. Das macht Spass.'),
        containsAll(
            <String>['grossen', 'haengen', 'Aepfel', 'fuer', 'Baeckerei', 'Spass']));
    expect(
        ersatzSpellingsIn('Zuerst schauen wir die neue Mauer an der Quelle '
            'an. Dass das Feuer teuer ist, weiß der Bauer. Er isst und '
            'fasst das Wasser.'),
        isEmpty);
  });

  test('Quest-Geschichten zeigen echte Umlaute und ß', () {
    final quests = LumoQuestLibrary.all();
    expect(quests, hasLength(4));
    for (final quest in quests) {
      final story = quest.story;
      final visible = <String>[
        quest.title,
        quest.summary,
        story.title,
        story.location,
        story.theme,
        ...story.keyPoints,
        ...story.newWords,
        for (final page in story.pages) ...<String>[
          page.text,
          page.newWord ?? '',
          page.exercise?.prompt ?? '',
          page.exercise?.correctAnswer ?? '',
          ...?page.exercise?.options,
        ],
      ];
      for (final text in visible) {
        expect(ersatzSpellingsIn(text), isEmpty,
            reason: '${quest.id}: „$text“');
        expect(text.contains('"'), isFalse,
            reason: '${quest.id}: gerade Anführungszeichen in „$text“');
      }
    }
  });

  test('Quest-Schlüssel und Lösungen bleiben unverändert', () {
    expect(LumoQuestLibrary.all().map((quest) => quest.id), <String>[
      'q1_apfelgarten',
      'q2_baeckerei',
      'q3_schatzhoehle',
      'q4_sternenflug',
    ]);
    for (final quest in LumoQuestLibrary.all()) {
      for (final page in quest.story.pages) {
        final exercise = page.exercise;
        if (exercise == null) continue;
        final options = exercise.options ?? const <String>[];
        expect(options.where((option) => option == exercise.correctAnswer),
            hasLength(1),
            reason: '${quest.id} Seite ${page.pageNum}');
        expect(options.toSet().length, options.length);
      }
    }
  });
}
