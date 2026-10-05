import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/features/deutsch/deutsch_gap_sentences.dart';
import 'package:lumo_lernen/features/deutsch/lumo_deutsch_screen.dart';

/// Deutsch nach Bild 04: Lückensätze mit echter Antwortprüfung.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  test('jeder Lückensatz hat vier verschiedene Wörter mit der Lösung', () {
    for (final sentence in DeutschGapSentences.all) {
      expect(sentence.options.toSet(), hasLength(4), reason: sentence.before);
      expect(sentence.options, contains(sentence.answer));
    }
    for (var grade = 1; grade <= 4; grade++) {
      expect(
          DeutschGapSentences.forGrade(grade).length, greaterThanOrEqualTo(5),
          reason: 'genug Sätze für eine Runde in Klasse $grade');
    }
  });

  GapSentence shown(WidgetTester tester, int grade) =>
      DeutschGapSentences.forGrade(grade).firstWhere((sentence) => find
          .textContaining('${sentence.before} ', findRichText: true)
          .evaluate()
          .isNotEmpty);

  testWidgets('falsches Wort bleibt offen, richtiges zählt und belohnt',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    await tester.pumpWidget(MaterialApp(
        home: LumoDeutschScreen(appState: app, random: math.Random(4))));
    await tester.pump();

    final first = shown(tester, 1);
    final wrong = first.options.firstWhere((word) => word != first.answer);
    await tester.tap(find.byKey(ValueKey('deutsch-word-$wrong')));
    await tester.pump();
    expect(find.text('Satz 1 von 5'), findsOneWidget);
    expect(find.textContaining('passt hier nicht'), findsOneWidget);
    expect(app.state.stars, 0);

    await tester.tap(find.byKey(ValueKey('deutsch-word-${first.answer}')));
    await tester.pump();
    expect(app.state.stars, 1);
    expect(app.state.xp, 5);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Satz 2 von 5'), findsOneWidget);

    for (var i = 1; i < 5; i++) {
      final sentence = shown(tester, 1);
      await tester.tap(find.byKey(ValueKey('deutsch-word-${sentence.answer}')));
      await tester.pump(const Duration(milliseconds: 1500));
    }
    expect(find.text('Runde geschafft!'), findsOneWidget);
    expect(find.text('4 von 5 Sätzen beim ersten Versuch richtig.'),
        findsOneWidget);

    final skill =
        app.learningSkills()[SkillRecord.makeId('Deutsch', 'Lückensätze')];
    expect(skill?.correct, 5);
    expect(skill?.wrong, 1);
    await tester.runAsync(app.flushRewards);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
