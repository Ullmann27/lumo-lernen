import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/teacher_mode/letter_writing_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/writing/lumo_writing_word_coach_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Eine Themenkachel öffnet, was ihr Titel verspricht. Früher öffnete die
/// Kachel „Buchstaben-Lautierung“ (Laut → Buchstabe) das Buchstaben-
/// Nachspuren und „Wort-Bild-Zuordnung“ das Wortdiktat, weil beide
/// Schreibthemen der Akademie diese Einheiten als Synonym tragen. Die echten
/// Lautierungs- und Wort-Bild-Aufgaben waren über die Kachel nicht erreichbar.
/// Die Schreibmodule bleiben über die Lernwerkzeuge erreichbar.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  Future<LumoAppState> openGerman(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    app.update(app.state.copyWith(grade: 1, childName: 'Mia'));
    await tester.pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.tap(find.byKey(const ValueKey('grade-pill-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('learning-subject-Deutsch')));
    await tester.pump(const Duration(milliseconds: 450));
    return app;
  }

  for (final unit in ['Buchstaben-Lautierung', 'Wort-Bild-Zuordnung']) {
    testWidgets('Klasse 1 Deutsch: „$unit“ startet genau diese Übung',
        (tester) async {
      final app = await openGerman(tester);
      addTearDown(app.dispose);
      final tile = find.byKey(ValueKey('learning-unit-Deutsch-$unit'));
      await tester.scrollUntilVisible(tile, 250,
          scrollable: find.byType(Scrollable).first, maxScrolls: 40);
      await tester.pump();
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(LetterWritingScreen), findsNothing);
      expect(find.byType(LumoWritingWordCoachScreen), findsNothing);
      expect(app.state.section, LumoSection.exercises);
      expect(app.state.subject, 'Deutsch');
      expect(app.state.unit, unit);
    });
  }

  testWidgets('die Schreibmodule bleiben in den Lernwerkzeugen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(grade: 1, childName: 'Mia'));
    await tester.pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.tap(find.byKey(const ValueKey('learning-advanced-entry')));
    await tester.pump();
    for (final key in ['academy-tool-d1_buchstaben_alle', 'academy-tool-d1_woerter']) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
  });
}
