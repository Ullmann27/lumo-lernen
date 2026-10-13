import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/deutsch/lumo_deutsch_screen.dart';
import 'package:lumo_lernen/features/learning/curriculum_activities_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LumoAppState> pumpAcademy(
    WidgetTester tester, {
    int grade = 2,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    final appState = LumoAppState();
    appState.update(appState.state.copyWith(grade: grade));
    await tester.pumpWidget(
      MaterialApp(home: LumoAkademieScreen(appState: appState)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    return appState;
  }

  Future<void> tapArea(WidgetTester tester, String title) async {
    final finder = find.byKey(ValueKey('learning-area-${title.toLowerCase()}'));
    expect(finder, findsOneWidget, reason: 'Lernkachel $title fehlt');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(tester.takeException(), isNull);
  }

  testWidgets('Mathe und Sachkunde zeigen echte Themen statt leer zu bleiben',
      (tester) async {
    final appState = await pumpAcademy(tester);
    addTearDown(appState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tapArea(tester, 'Mathe');
    expect(find.text('Zahlen bis 100'), findsOneWidget);
    expect(find.text('Kleines 1×1'), findsOneWidget);
    expect(find.text('Die Uhr'), findsOneWidget);
    expect(find.text('Geld'), findsOneWidget);

    await tapArea(tester, 'Sachkunde');
    expect(find.text('Jahreszeiten'), findsOneWidget);
    expect(find.text('Wetter'), findsOneWidget);
    expect(find.text('Verkehr'), findsOneWidget);
  });

  testWidgets('Deutsch öffnet seinen echten Bereich', (tester) async {
    final appState = await pumpAcademy(tester);
    addTearDown(appState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tapArea(tester, 'Deutsch');
    expect(find.byType(LumoDeutschScreen), findsOneWidget);
  });

  testWidgets('Lesen Schreiben und Englisch wechseln in echten Lernmodus',
      (tester) async {
    for (final entry in <(String, LumoSection, String)>[
      ('Lesen', LumoSection.reading, 'Lesen'),
      ('Schreiben', LumoSection.exercises, 'Schreiben'),
      ('Englisch', LumoSection.exercises, 'Englisch'),
    ]) {
      final appState = await pumpAcademy(tester);
      await tapArea(tester, entry.$1);
      expect(appState.state.section, entry.$2, reason: entry.$1);
      expect(appState.state.subject, entry.$3, reason: entry.$1);
      appState.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('praktische Fächer öffnen eine gefüllte Aktivitäten-Seite',
      (tester) async {
    for (final title in <String>[
      'Musik',
      'Kunst',
      'Technik',
      'Bewegung',
      'Mobilität',
    ]) {
      final appState = await pumpAcademy(tester);
      await tapArea(tester, title);
      expect(find.byType(CurriculumActivitiesScreen), findsOneWidget,
          reason: title);
      appState.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    await tester.binding.setSurfaceSize(null);
  });
}
