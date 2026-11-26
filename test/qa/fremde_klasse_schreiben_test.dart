import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/renderers/writing_task_renderer.dart';
import 'package:lumo_lernen/features/teacher_mode/letter_writing_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/writing/lumo_writing_word_coach_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Pushes extends NavigatorObserver {
  final routes = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.add(route);
}

/// Prüfbericht Punkt 5: Ein Kind der 3. Klasse öffnet in den Lernwerkzeugen
/// der 1. Klasse „Alle Buchstaben A-Z“ oder „Erste Wörter“. Früher startete
/// dann ein Lautierungs- bzw. Wort-Bild-Quiz. Jetzt startet eine echte
/// Schreibübung der gewählten Klasse; ihr Fortschritt bleibt wie jede Übung
/// einer anderen Klasse getrennt (CrossGradePracticeScreen).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final (tool, unit) in const [
    ('academy-tool-d1_buchstaben_alle', 'Buchstaben nachspuren'),
    ('academy-tool-d1_woerter', 'Wort schreiben'),
  ]) {
    testWidgets('Klasse 3 sieht Klasse 1: $tool öffnet „$unit“',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      app.update(app.state.copyWith(grade: 3, childName: 'Mia'));
      final pushes = _Pushes();
      await tester.pumpWidget(MaterialApp(
          navigatorObservers: [pushes],
          home: LumoAkademieScreen(appState: app)));
      await tester.pump(const Duration(milliseconds: 650));
      await tester.tap(find.byKey(const ValueKey('grade-pill-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('learning-advanced-entry')));
      await tester.pump();
      final entry = find.byKey(ValueKey(tool));
      await tester.scrollUntilVisible(entry, 250,
          scrollable: find.byType(Scrollable).first, maxScrolls: 40);
      await tester.pump();
      await tester.tap(entry);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(LetterWritingScreen), findsNothing);
      expect(find.byType(LumoWritingWordCoachScreen), findsNothing);
      final screen = tester.widget<CrossGradePracticeScreen>(
          find.byType(CrossGradePracticeScreen));
      expect(screen.subject, 'Schreiben');
      expect(screen.unit, unit);
      expect(screen.lessonGrade, 1);
      expect(screen.enrolledGrade, 3);
      // Eine echte Schreibfläche, kein Auswahl-Quiz.
      final task = tester
          .widget<WritingTaskRenderer>(find.byType(WritingTaskRenderer))
          .task;
      expect(task.taskType, TaskType.writingCanvas, reason: task.prompt);
      expect(find.byType(AdaptiveTaskRenderer), findsNothing);
      // Die Profilklasse bleibt unverändert.
      expect(app.state.grade, 3);
      expect(pushes.routes, isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
