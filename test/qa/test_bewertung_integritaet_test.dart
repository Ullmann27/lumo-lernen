import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bewertung entspricht der Leistung: Ein Test (10 Fragen) und eine
/// Schularbeit (30 Fragen) zählen jede geplante Frage. Das Schreibtraining
/// ist bewusst unbewertet (ein echter Versuch führt immer weiter) und darf
/// deshalb keine dieser Fragen belegen. Früher kam im Mini-Test etwa jede
/// siebte Aufgabe aus „Schreiben“; ein fehlerfreies Kind bekam dann z. B.
/// 8 von 10 Punkten.
void main() {
  group('Generator: bewertete Sitzungen ohne Schreibtraining', () {
    for (var grade = 1; grade <= 4; grade++) {
      test('Klasse $grade: gemischte Tests enthalten nur bewertbare Aufgaben',
          () {
        var handwritingDefault = 0;
        for (var seed = 0; seed < 120; seed++) {
          final graded = ExerciseFactory(seed: seed * 31 + grade)
              .buildSession(grade: grade, count: 10, gradedOnly: true);
          for (final task in graded) {
            expect(task.handwriting, isFalse,
                reason: '$grade/${task.subject}/${task.unit}: ${task.prompt}');
            expect(task.subject, isNot('Schreiben'));
          }
          // Auch mit einer Schreib-Schwäche bleibt der Test bewertbar.
          final weak = ExerciseFactory(seed: seed * 17 + grade).next(
            grade: grade,
            weakSkills: const {'Wort schreiben': 6},
            gradedOnly: true,
          );
          expect(weak.handwriting, isFalse, reason: weak.prompt);
          handwritingDefault += ExerciseFactory(seed: seed * 31 + grade)
              .buildSession(grade: grade, count: 10)
              .where((task) => task.handwriting)
              .length;
        }
        // Gemischtes freies Üben behält das Schreibtraining.
        expect(handwritingDefault, greaterThan(0));
      });
    }
  });

  group('Echter Lernbildschirm: Mini-Test und Schularbeit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
    });
    tearDown(() => LumoVoice.instance.isEnabled = true);

    for (final kind in [LumoSessionKind.test, LumoSessionKind.schoolwork]) {
      testWidgets('${kind.name}: Fach Alle zeigt kein Schreibtraining',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var shown = 0;
        for (var seed = 0; seed < 28; seed++) {
          final state =
              LumoAppState(walletRepository: RewardWalletRepository());
          state.update(state.state.copyWith(
            childName: 'Mia',
            grade: 1 + seed % 4,
            subject: 'Alle',
            unit: 'Alle',
            sessionKind: kind,
          ));
          await tester.pumpWidget(MaterialApp(
              home: Scaffold(
                  body: LearningContent(appState: state, taskSeed: seed))));
          await tester.pump();
          final task = tester
              .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
              .task;
          expect(task.taskType, isNot(TaskType.writingCanvas),
              reason: 'seed $seed: ${task.prompt}');
          shown++;
          await tester.pumpWidget(const SizedBox.shrink());
          state.dispose();
        }
        expect(shown, 28);
      });
    }
  });
}
