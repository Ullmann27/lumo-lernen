// Fachprüfung 2026-11 (D-M22, D-M20, D-M21, D-L7): kindersichtbare
// Oberflächentexte standen ohne Umlaute ("Lumo hoert dir zu").
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'ersatz_spelling.dart';

/// Text in einfachen Anführungszeichen aus Code-Zeilen (ohne Kommentare,
/// Schlüssel und Pfade).
Iterable<String> _visibleLiterals(String path) sync* {
  for (final line in File(path).readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('//')) continue;
    for (final match
        in RegExp(r"'((?:[^'\\]|\\.)*)'").allMatches(line)) {
      final literal = match.group(1)!;
      if (literal.contains('/') || literal.startsWith('package:')) continue;
      if (!literal.contains(' ')) continue;
      yield literal;
    }
  }
}

void main() {
  const screens = <String>[
    'lib/features/reading/lumo_reading_buddy_screen.dart',
    'lib/features/journal/lumo_journal_screen.dart',
    'lib/features/photo_lesson/lumo_photo_lesson_screen.dart',
    'lib/features/shared/widgets/lumo_tagestipp_card.dart',
    'lib/features/learning_modules/mehrzahl/mehrzahl_screen.dart',
    'lib/features/learning_modules/artikel_lernen/artikel_lernen_screen.dart',
    'lib/features/deutsch/deutsch_gap_sentences.dart',
    'lib/core/lumo_quest_library.dart',
    // Zweite Runde: Spiele, Schreibvorlagen, Erfolge, Lumo-Welt.
    'lib/domain/games/game_level_catalog.dart',
    'lib/features/games/lumo_cards/lumo_cards_rules.dart',
    'lib/features/games/lumo_cards/lumo_cards_game_controller.dart',
    'lib/features/lumo_welt/lumo_welt_screen.dart',
    'lib/features/story/lumo_story_library_screen.dart',
    'lib/features/story/lumo_quest_hub_screen.dart',
    'lib/widgets/premium/lumo_empty_error_state.dart',
    'lib/features/games/dice_race/lumo_dice_race_game.dart',
    'lib/core/achievements/lumo_achievement.dart',
    'lib/features/writing/writing_engine.dart',
  ];

  for (final path in screens) {
    test('keine Ersatzschreibung in ${path.split('/').last}', () {
      final literals = _visibleLiterals(path).toList();
      expect(literals, isNotEmpty);
      final source = File(path).readAsStringSync();
      for (final literal in literals) {
        // Bildbeschreibungen der Quests sind keine Kindertexte.
        if (source.contains("imagePrompt: '$literal'")) continue;
        expect(ersatzSpellingsIn(literal), isEmpty,
            reason: '$path: „$literal“');
      }
    });
  }

  test('Mehrzahl-Modul wertet keine Ersatzschreibung als falsche Antwort', () {
    final source = File(
            'lib/features/learning_modules/mehrzahl/mehrzahl_screen.dart')
        .readAsStringSync();
    expect(source.contains('Maenner'), isFalse);
    expect(source.contains('Voegels'), isFalse);
  });

  test('Quiz Deutsch: einheitliche Begriffe und richtige Großschreibung', () {
    final source =
        File('lib/domain/quiz/quiz_question_bank.dart').readAsStringSync();
    for (final gone in <String>[
      'Tu-Wort',
      'Name-Wort',
      "'Laufen', 'Hund', 'Schnell'",
      'Fischname',
      'Himmel wenn es',
      'längste Fluss',
    ]) {
      expect(source.contains(gone), isFalse, reason: gone);
    }
    expect(source, contains("'laufen', 'Hund', 'schnell', 'Tisch'"));
  });
}
