import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/sections/section_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deutsch-Schularbeit (offener Punkt 7 des Prüfberichts): Die Karte
/// versprach „Lesen, Sprache, Rechtschreibung und Schreiben“, gezogen wurden
/// nur Deutsch-Einheiten. Laut Lehrplan VS 2023 gehören Lesen und
/// Rechtschreiben zum Fach Deutsch. Tests und Schularbeiten in Deutsch ziehen
/// jetzt aus Sprache, Lesen und Rechtschreibung. Texte verfassen wird nicht
/// automatisch bewertet; das sagt die Karte jetzt ehrlich.
void main() {
  const areas = {'Deutsch', 'Lesen', 'Rechtschreibung'};

  for (var grade = 1; grade <= 4; grade++) {
    test('Klasse $grade: Deutsch-Schularbeit prüft Sprache, Lesen und '
        'Rechtschreibung', () {
      final counts = <String, int>{};
      for (var seed = 0; seed < 60; seed++) {
        final tasks = ExerciseFactory(seed: seed * 13 + grade).buildSession(
            grade: grade, count: 30, subject: 'Deutsch', gradedOnly: true);
        for (final task in tasks) {
          expect(areas, contains(task.subject), reason: task.prompt);
          expect(task.handwriting, isFalse, reason: task.prompt);
          counts[task.subject] = (counts[task.subject] ?? 0) + 1;
        }
      }
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      for (final area in areas) {
        expect((counts[area] ?? 0) / total, greaterThan(.15),
            reason: '$area: $counts');
      }
      expect(counts['Deutsch']! / total, greaterThan(.35), reason: '$counts');
    });
  }

  test('freies Üben und gewählte Themen bleiben im gewählten Fach', () {
    for (var seed = 0; seed < 300; seed++) {
      final free = ExerciseFactory(seed: seed)
          .next(grade: 2, subject: 'Deutsch', unit: 'Alle');
      expect(free.subject, 'Deutsch');
      final chosen = ExerciseFactory(seed: seed).next(
          grade: 3, subject: 'Deutsch', unit: 'Wortarten', gradedOnly: true);
      expect(chosen.subject, 'Deutsch');
      expect(chosen.unit, 'Wortarten');
      final math = ExerciseFactory(seed: seed)
          .next(grade: 3, subject: 'Mathematik', gradedOnly: true);
      expect(math.subject, 'Mathematik');
    }
  });

  group('Oberfläche', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
    });
    tearDown(() => LumoVoice.instance.isEnabled = true);

    testWidgets('die Karte beschreibt, was die Schularbeit wirklich prüft',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      app.update(app.state.copyWith(grade: 3, childName: 'Mia'));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SectionContent(
                  appState: app,
                  section: LumoSection.schoolwork,
                  onSection: (_) {}))));
      await tester.pump();
      expect(
          find.text('30 Aufgaben: Lesen, Sprache und Rechtschreibung. '
              'Texte schreibst du im Schreibtrainer.'),
          findsOneWidget);
      expect(find.textContaining('Rechtschreibung und Schreiben'), findsNothing);
    });

    testWidgets('echter Lernbildschirm: Deutsch-Schularbeit zeigt auch Lesen '
        'und Rechtschreibung, nie Schreibtraining', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final shown = <String>{};
      for (var seed = 0; seed < 24; seed++) {
        final state = LumoAppState(walletRepository: RewardWalletRepository());
        state.update(state.state.copyWith(
          childName: 'Mia',
          grade: 1 + seed % 4,
          subject: 'Deutsch',
          unit: 'Alle',
          sessionKind: LumoSessionKind.schoolwork,
        ));
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: LearningContent(appState: state, taskSeed: seed))));
        await tester.pump();
        final skill = tester
            .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
            .task
            .skillId
            .value;
        shown.add(skill.split('.')[1]);
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      }
      expect(shown, isNot(contains('schreiben')));
      expect(shown.difference({'deutsch', 'lesen', 'rechtschreibung'}), isEmpty,
          reason: '$shown');
      expect(shown.length, greaterThanOrEqualTo(2), reason: '$shown');
    });
  });
}
