import 'dart:convert';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning_modules/uhr_lernen/uhr_lernen_screen.dart';
import 'package:lumo_lernen/features/learning_modules/zahlen_bis_10/zahlen_bis_10_screen.dart';

// Select the successor exercise and the upper endpoint of its number range.
class _LastSuccessorRandom implements math.Random {
  final _fallback = math.Random(24);
  var _calls = 0;
  @override
  int nextInt(int max) {
    _calls++;
    if (_calls == 1) return 1;
    if (_calls == 2) return max - 1;
    return _fallback.nextInt(max);
  }

  @override
  bool nextBool() => _fallback.nextBool();
  @override
  double nextDouble() => _fallback.nextDouble();
}

class _ClockRandom implements math.Random {
  final _fallback = math.Random(261);
  List<int> nextTime = [11, 0];

  @override
  int nextInt(int max) =>
      nextTime.isEmpty ? _fallback.nextInt(max) : nextTime.removeAt(0);
  @override
  bool nextBool() => _fallback.nextBool();
  @override
  double nextDouble() => _fallback.nextDouble();
}

Future<void> _open(
    WidgetTester tester, Widget Function(LumoAppState) screen) async {
  await tester.binding.setSurfaceSize(const Size(480, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  addTearDown(app.dispose);
  await tester.runAsync(() async {
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  await tester.pumpWidget(MaterialApp(home: screen(app)));
  await tester.pump(const Duration(milliseconds: 700));
}

List<String> _choices(WidgetTester tester) => tester
    .widgetList<Text>(
        find.descendant(of: find.byType(GridView), matching: find.byType(Text)))
    .map((text) => text.data!)
    .toList();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        soundEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets('first clock task cannot be solved by answer wording alone',
      (tester) async {
    await _open(tester,
        (app) => UhrLernenScreen(appState: app, taskRandom: math.Random(261)));
    final choices = _choices(tester);
    expect(choices.toSet(), hasLength(4));
    expect(choices, everyElement(matches(RegExp(r'^\d+ Uhr$'))),
        reason: 'Full-hour practice must offer four full-hour alternatives.');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('clock stages include twelve and wrap half/quarter hours to one',
      (tester) async {
    final random = _ClockRandom();
    await _open(
        tester, (app) => UhrLernenScreen(appState: app, taskRandom: random));
    const expectedTimes = [
      '12 Uhr',
      '12 Uhr',
      'halb 1',
      'halb 1',
      'halb 1',
      'Viertel vor 1',
      'Viertel nach 12',
      'Viertel vor 1',
    ];
    for (var task = 0; task < expectedTimes.length; task++) {
      expect(find.text('Uhrzeit ${task + 1} / 8'), findsOneWidget);
      final choices = _choices(tester);
      expect(choices.toSet(), hasLength(4));
      expect(choices, contains(expectedTimes[task]));
      expect(choices, everyElement(isNot(contains('13'))));
      if (task < 2) {
        expect(choices, everyElement(matches(RegExp(r'^\d+ Uhr$'))));
      } else if (task < 5) {
        expect(choices, everyElement(isNot(contains('Viertel'))));
      }
      final painter = tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .map((paint) => paint.painter)
              .singleWhere((p) => p.runtimeType.toString() == '_ClockPainter')
          as dynamic;
      expect(painter.hour, 12);
      expect(
          painter.minute,
          task < 2
              ? 0
              : task < 5
                  ? 30
                  : task == 6
                      ? 15
                      : 45);
      if (task == expectedTimes.length - 1) break;
      final next = task + 1;
      random.nextTime = [
        11,
        next < 2
            ? 0
            : next < 5
                ? 1
                : next == 6
                    ? 1
                    : 3
      ];
      final choice = find.descendant(
          of: find.byType(GridView), matching: find.text(expectedTimes[task]));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      for (var frame = 0; frame < 170; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('numbers through ten include the successor of nine',
      (tester) async {
    await _open(
        tester,
        (app) => ZahlenBis10Screen(
            appState: app, taskRandom: _LastSuccessorRandom()));
    expect(find.text('Welche Zahl kommt nach 9?'), findsOneWidget);
    final choices = _choices(tester);
    expect(choices, contains('10'));
    expect(choices.toSet(), hasLength(4));
    expect(choices.map(int.parse), everyElement(inInclusiveRange(1, 10)));
    await tester.pumpWidget(const SizedBox());
  });
}
