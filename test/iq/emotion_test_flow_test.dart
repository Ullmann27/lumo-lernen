import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/tests/emotion_scenarios.dart';
import 'package:lumo_lernen/features/tests/emotion_test_screen.dart';
import 'package:lumo_lernen/features/tests/lumo_tests_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Both age bands have four different stories and specific responses', () {
    expect(emotionScenesFor(1), equals(emotionScenesFor(2)));
    expect(emotionScenesFor(3), equals(emotionScenesFor(4)));
    final titles = <String>{};
    for (final grade in [1, 4]) {
      final scenes = emotionScenesFor(grade);
      expect(scenes, hasLength(4));
      for (final scene in scenes) {
        expect(titles.add(scene.title), isTrue);
        expect(scene.choices.map((c) => c.feedback).toSet(), hasLength(3));
      }
    }
  });

  testWidgets('Narrow tests menu, choices, skip, honest review and return',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 730));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    app.update(app.state.copyWith(grade: 2));
    await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: LumoTestsScreen(appState: app, onSection: (_) {}))));
    await tester.pump();
    final entry = find.byKey(const ValueKey('emotion-test-start'));
    await tester.scrollUntilVisible(entry.hitTestable(), 155,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(entry);
    await tester.pump();
    await tester.tap(entry.hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final scenes = emotionScenesFor(2);
    Future<void> press(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await tester.pump();
    }

    for (int i = 0; i < scenes.length; i++) {
      expect(find.text(scenes[i].title), findsOneWidget);
      if (i == 1) {
        await press(find.text('Diese Geschichte überspringen'));
        continue;
      }
      final chosen = i % 3;
      final button = find.byKey(ValueKey('emotion-choice-$chosen'));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await press(button);
      expect(find.text(scenes[i].choices[chosen].feedback), findsOneWidget);
      await press(
          find.text(i == 3 ? 'Rückblick öffnen' : 'Nächste Geschichte'));
    }
    expect(find.text('Du hast bei 3 von 4 Geschichten eine Antwort gewählt.'),
        findsOneWidget);
    expect(find.text('Übersprungen'), findsOneWidget);
    await press(find.text('Zurück zu den Tests'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EmotionTestScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('A profile switch retires answers immediately', (tester) async {
    final app = LumoAppState();
    app.update(app.state.copyWith(childName: 'Ada', grade: 4));
    await tester
        .pumpWidget(MaterialApp(home: EmotionTestScreen(appState: app)));
    expect(find.text('Nach dem Staffellauf'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('emotion-choice-0')));
    await tester.pump();
    app.update(app.state.copyWith(childName: 'Leo'));
    await tester.pump();
    expect(find.textContaining('Profil wurde gewechselt'), findsOneWidget);
    expect(find.text(emotionScenesFor(4).first.choices.first.feedback),
        findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
