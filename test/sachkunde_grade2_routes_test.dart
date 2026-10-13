import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/learning_modules/jahreszeiten/jahreszeiten_screen.dart';
import 'package:lumo_lernen/features/learning_modules/verkehr/verkehr_screen.dart';
import 'package:lumo_lernen/features/learning_modules/wetter/wetter_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LumoAppState> openAcademy(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final app = LumoAppState();
    app.update(app.state.copyWith(grade: 2));
    await tester.pumpWidget(
      MaterialApp(home: LumoAkademieScreen(appState: app)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    final area = find.byKey(const ValueKey('learning-area-sachkunde'));
    expect(area, findsOneWidget);
    await tester.ensureVisible(area);
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
    final topic = find.text(label);
    expect(topic, findsOneWidget, reason: label);
    await tester.dragUntilVisible(
      topic,
      find.byType(Scrollable).first,
      const Offset(0, -240),
    );
    await tester.pump();
    await tester.tap(topic);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(T), findsOneWidget, reason: label);
    expect(tester.takeException(), isNull, reason: label);
  }

  testWidgets('Klasse 2 Sachkunde Jahreszeiten opens real module',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await openAcademy(tester);
    addTearDown(app.dispose);
    await assertTopicOpens<JahreszeitenScreen>(tester, 'Jahreszeiten');
  });

  testWidgets('Klasse 2 Sachkunde Wetter opens real module', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await openAcademy(tester);
    addTearDown(app.dispose);
    await assertTopicOpens<WetterScreen>(tester, 'Wetter');
  });

  testWidgets('Klasse 2 Sachkunde Verkehr opens real module', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await openAcademy(tester);
    addTearDown(app.dispose);
    await assertTopicOpens<VerkehrScreen>(tester, 'Verkehr');
  });
}
