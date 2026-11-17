import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _backs() => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith('memory-back-'));

Future<void> _open(
  WidgetTester tester, {
  required Size size,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState();
  addTearDown(app.dispose);
  await tester.pumpWidget(MaterialApp(
    home: LumoMemoryScreen(
      key: UniqueKey(),
      appState: app,
      seed: 4,
      difficulty: MemoryDifficulty.schwer,
    ),
  ));
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

Future<void> _expectTappable(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  final center = tester.getCenter(finder);
  final hit = tester.hitTestOnBinding(center);
  expect(hit.path, isNotEmpty,
      reason: '$finder has no hit-test target at $center');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in const [
    ('phone', Size(412, 915)),
    ('fold', Size(690, 829)),
  ]) {
    testWidgets('Memory controls stay hit-testable on ${entry.$1}',
        (tester) async {
      await _open(tester, size: entry.$2);

      await _expectTappable(tester, find.byKey(const ValueKey('memory-close')));
      await tester.tap(find.byKey(const ValueKey('memory-close')));
      await tester.pump();
      expect(find.byKey(const ValueKey('lumo-pause-panel')), findsOneWidget);
      expect(find.text('Spiel pausiert'), findsOneWidget);
      await tester.tap(find.text('Fortsetzen'));
      await tester.pump();
      expect(find.byKey(const ValueKey('lumo-pause-panel')), findsNothing);

      await _expectTappable(
          tester, find.byKey(const ValueKey('memory-restart')));
      await tester.tap(find.byKey(const ValueKey('memory-restart')));
      await tester.pump();
      expect(find.byKey(const ValueKey('lumo-pause-panel')), findsOneWidget);
      await tester.tap(find.text('Fortsetzen'));
      await tester.pump();

      final leicht = find.byKey(const ValueKey('memory-diff-leicht'));
      final profi = find.byKey(const ValueKey('memory-diff-profi'));
      await _expectTappable(tester, leicht);
      await _expectTappable(tester, profi);

      expect(_backs(), findsNWidgets(MemoryDifficulty.schwer.cards));
      await tester.tap(leicht);
      await tester.pump();
      expect(_backs(), findsNWidgets(MemoryDifficulty.leicht.cards));

      await tester.tap(profi);
      await tester.pump();
      expect(_backs(), findsNWidgets(MemoryDifficulty.profi.cards));

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
