import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/reading/reading_content.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings_v1': '{"voiceEnabled":false}',
    });
  });

  Future<void> pumpLearnShell(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    await tester.pumpWidget(
      const MaterialApp(
        home: AppShell(initialSection: LumoSection.learn),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LumoAkademieScreen), findsOneWidget);
  }

  Future<void> tapArea(WidgetTester tester, String title) async {
    final finder = find.byKey(ValueKey('learning-area-${title.toLowerCase()}'));
    expect(finder, findsOneWidget, reason: title);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull, reason: title);
  }

  testWidgets('Lesen leaves Akademie and opens ReadingContent', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpLearnShell(tester);
    await tapArea(tester, 'Lesen');
    expect(find.byType(LumoAkademieScreen), findsNothing);
    expect(find.byType(ReadingContent), findsOneWidget);
  });

  testWidgets('Schreiben leaves Akademie and opens LearningContent',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpLearnShell(tester);
    await tapArea(tester, 'Schreiben');
    expect(find.byType(LumoAkademieScreen), findsNothing);
    expect(find.byType(LearningContent), findsOneWidget);
  });

  testWidgets('Englisch leaves Akademie and opens LearningContent',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpLearnShell(tester);
    await tapArea(tester, 'Englisch');
    expect(find.byType(LumoAkademieScreen), findsNothing);
    expect(find.byType(LearningContent), findsOneWidget);
  });
}
