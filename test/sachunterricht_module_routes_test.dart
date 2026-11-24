import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/learning_modules/jahreszeiten/jahreszeiten_screen.dart';
import 'package:lumo_lernen/features/learning_modules/tiere/tiere_screen.dart';
import 'package:lumo_lernen/features/learning_modules/verkehr/verkehr_screen.dart';
import 'package:lumo_lernen/features/learning_modules/wetter/wetter_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Aus sol/lumo-app-audit (0c1254d7, 99ac9d91), an die Benennung ab Build 1943
/// angepasst („Sachunterricht“). Die Kacheln mit eigenem Fachmodul müssen das
/// Modul öffnen; vorher fing der Aufgabengenerator sie ab.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LumoAppState> openAcademy(WidgetTester tester, {int grade = 2}) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final app = LumoAppState();
    app.update(app.state.copyWith(grade: grade));
    await tester.pumpWidget(
      MaterialApp(home: LumoAkademieScreen(appState: app)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.tap(find.byKey(ValueKey('grade-pill-$grade')));
    await tester.pump();
    final area = find.byKey(const ValueKey('learning-subject-Sachunterricht'));
    await tester.ensureVisible(area);
    await tester.pump();
    expect(area, findsOneWidget);
    await tester.tap(area);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.takeException(), isNull);
    return app;
  }

  Future<void> assertTopicOpens<T extends Widget>(
    WidgetTester tester,
    String label,
  ) async {
    final topic = find.byKey(ValueKey('learning-unit-Sachunterricht-$label'));
    await tester.scrollUntilVisible(topic, 220,
        scrollable: find.byType(Scrollable).first, maxScrolls: 35);
    await tester.pump();
    expect(topic, findsOneWidget, reason: label);
    await tester.tap(topic);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(T), findsOneWidget, reason: label);
    expect(tester.takeException(), isNull, reason: label);
  }

  testWidgets('Klasse 2 Sachunterricht Jahreszeiten opens real module',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await openAcademy(tester);
    addTearDown(app.dispose);
    await assertTopicOpens<JahreszeitenScreen>(tester, 'Jahreszeiten');
  });

  testWidgets('Klasse 2 Sachunterricht Wetter opens real module',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await openAcademy(tester);
    addTearDown(app.dispose);
    await assertTopicOpens<WetterScreen>(tester, 'Wetter');
  });

  testWidgets('Klasse 2 Sachunterricht Verkehr opens real module',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await openAcademy(tester);
    addTearDown(app.dispose);
    await assertTopicOpens<VerkehrScreen>(tester, 'Verkehr');
  });

  testWidgets('Klasse 1 Sachunterricht Tiere opens real module',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await openAcademy(tester, grade: 1);
    addTearDown(app.dispose);
    await assertTopicOpens<TiereScreen>(tester, 'Tiere');
  });
}
