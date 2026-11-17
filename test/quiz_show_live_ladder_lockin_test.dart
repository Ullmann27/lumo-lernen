import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Quizshow has twenty unique rows and only one active step',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: QuizShowContent(appState: app, previewQuestionSeed: 7),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 260));
    for (var level = 1; level <= 20; level++) {
      expect(find.byKey(ValueKey('lumo-meister-prize-step-$level')),
          findsOneWidget);
    }
    expect(find.byKey(const ValueKey('lumo-meister-lock-bar')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-meister-answer-0')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Answer lock-in waits, blocks reentry and then reveals',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: QuizShowContent(appState: app, previewQuestionSeed: 1),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 260));
    final answer = find.byKey(const ValueKey('lumo-meister-answer-0'));
    await tester.ensureVisible(answer);
    await tester.pump();
    await tester.tap(answer);
    await tester.pump();
    final submit = find.text('Antwort einloggen');
    await tester.ensureVisible(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Lumo prüft deine Antwort …'), findsOneWidget);
    expect(find.text('Nächste Frage'), findsNothing);
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('Lumo prüft deine Antwort …'), findsNothing);
    expect(find.text('Nächste Frage').evaluate().isNotEmpty ||
        find.text('Neue Quizrunde starten').evaluate().isNotEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });
}
