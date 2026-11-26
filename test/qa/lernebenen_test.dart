import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/curriculum/learning_level.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drei pädagogische Ebenen (Entscheidung Heinz, 26.11.2026): Schulwissen,
/// Vertiefung und „Lumo Expertenwelt“. Keine Aufgabe wird gelöscht, aber
/// Stoff über den Lehrplan der Volksschule hinaus (BGBl. II Nr. 1/2023:
/// Dezimalzahlen nur als Geldbetrag, kein Mittelwert, kein formales
/// Erweitern, Brüche erst in der 4. Schulstufe) erscheint nur nach
/// ausdrücklicher Auswahl – nie in einem regulären Test, einer Schularbeit
/// oder einer gemischten Runde.
void main() {
  bool expert(LumoTask task, int grade) =>
      LearningLevels.isExpert(task.subject, task.unit, grade);

  group('Zuordnung', () {
    test('Expertenwelt, Vertiefung und Schulwissen nach Lehrplan', () {
      for (final unit in ['Dezimalzahlen', 'Mittelwert', 'Brüche erweitern']) {
        expect(LearningLevels.levelOf('Mathematik', unit, 4),
            LumoLearningLevel.expertenwelt, reason: unit);
      }
      expect(LearningLevels.levelOf('Mathematik', 'Brüche Vorbereitung', 3),
          LumoLearningLevel.expertenwelt);
      // Bruchteile ermitteln ist Stoff der 4. Schulstufe.
      expect(LearningLevels.levelOf('Mathematik', 'Brüche Vorbereitung', 4),
          LumoLearningLevel.schulwissen);
      expect(LearningLevels.levelOf('Mathematik', 'Bruchrechnen einfach', 4),
          LumoLearningLevel.schulwissen);
      expect(LearningLevels.levelOf('Mathematik', 'Sachaufgaben drei Schritte', 4),
          LumoLearningLevel.vertiefung);
      expect(LearningLevels.levelOf('Mathematik', 'Plus bis 10', 1),
          LumoLearningLevel.schulwissen);
      expect(LearningLevels.levelOf('Sachunterricht', 'Ökosysteme', 4),
          LumoLearningLevel.schulwissen);
    });

    test('keine Aufgabe gelöscht: Expertenwelt bleibt frei wählbar', () {
      const offered = <int, List<String>>{
        3: ['Brüche Vorbereitung'],
        4: ['Dezimalzahlen', 'Mittelwert', 'Brüche erweitern'],
      };
      for (final MapEntry(key: grade, value: units) in offered.entries) {
        final listed = Curriculum.unitsForGrade('Mathematik', grade,
            currentGradeOnly: true);
        for (final unit in units) {
          expect(listed, contains(unit), reason: '$grade/$unit');
          for (var seed = 0; seed < 40; seed++) {
            final task = ExerciseFactory(seed: seed).nextExact(
                grade: grade, subject: 'Mathematik', unit: unit);
            expect(task.unit, unit);
          }
        }
      }
    });
  });

  group('Tests und Schularbeiten ohne Expertenwelt', () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final level in const [-1, 0, 1]) {
        final taskGrade = (grade + level).clamp(1, 4).toInt();
        test('Klasse $grade, Stufe $level (Aufgaben Kl. $taskGrade)', () {
          var math = 0;
          for (var seed = 0; seed < 150; seed++) {
            for (final subject in const ['Alle', 'Mathematik']) {
              final session = ExerciseFactory(seed: seed * 37 + grade).buildSession(
                  grade: taskGrade,
                  count: subject == 'Alle' ? 10 : 30,
                  subject: subject,
                  gradedOnly: true,
                  // Auch eine frühere freiwillige Übung zieht nicht in den Test.
                  weakSkills: const {'Dezimalzahlen': 6, 'Mittelwert': 4});
              for (final task in session) {
                if (task.subject == 'Mathematik') math++;
                expect(expert(task, taskGrade), isFalse,
                    reason: '$taskGrade/$subject/${task.unit}: ${task.prompt}');
              }
            }
          }
          expect(math, greaterThan(1000));
        });
      }
    }

    test('gemischtes Üben ohne Auswahl zieht keine Expertenwelt', () {
      for (var grade = 3; grade <= 4; grade++) {
        for (var seed = 0; seed < 400; seed++) {
          final task = ExerciseFactory(seed: seed).next(
              grade: grade, subject: 'Mathematik', unit: 'Alle');
          expect(expert(task, grade), isFalse, reason: task.unit);
        }
      }
    });
  });

  group('Echter Lernbildschirm', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
    });
    tearDown(() => LumoVoice.instance.isEnabled = true);

    Future<String> shownSkill(WidgetTester tester,
        {required int grade,
        required int testLevel,
        required LumoSessionKind kind,
        required String subject,
        required String unit,
        required int seed}) async {
      final state = LumoAppState(walletRepository: RewardWalletRepository());
      state.update(state.state.copyWith(
        childName: 'Mia',
        grade: grade,
        subject: subject,
        unit: unit,
        sessionKind: kind,
        testLevel: testLevel,
      ));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: LearningContent(appState: state, taskSeed: seed))));
      await tester.pump();
      final skill = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task
          .skillId
          .value;
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      return skill;
    }

    const expertSkills = [
      'mathematik.dezimalzahlen',
      'mathematik.mittelwert',
      'mathematik.brüche_erweitern',
    ];

    for (final kind in [LumoSessionKind.test, LumoSessionKind.schoolwork]) {
      testWidgets('${kind.name}: Mathematik Kl. 3 und 4 ohne Expertenwelt',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (var seed = 0; seed < 24; seed++) {
          final grade = 3 + seed % 2;
          final skill = await shownSkill(tester,
              grade: grade,
              testLevel: kind == LumoSessionKind.test ? seed % 3 - 1 : 0,
              kind: kind,
              subject: seed.isEven ? 'Mathematik' : 'Alle',
              unit: 'Alle',
              seed: seed);
          for (final id in expertSkills) {
            expect(skill, isNot(endsWith(id)), reason: 'seed $seed');
          }
          if (grade == 3) {
            expect(skill, isNot(endsWith('brüche_vorbereitung')));
          }
        }
      });
    }

    testWidgets('ausdrücklich gewählte Expertenwelt startet genau diese Übung',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final skill = await shownSkill(tester,
          grade: 4,
          testLevel: 0,
          kind: LumoSessionKind.quickPractice,
          subject: 'Mathematik',
          unit: 'Dezimalzahlen',
          seed: 3);
      expect(skill, endsWith('mathematik.dezimalzahlen'));
    });
  });
}
