import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart';
import 'package:lumo_lernen/features/learning_modules/zahlen_bis_10/zahlen_bis_10_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/widgets/design/lumo_answer_crystal.dart';
import 'package:lumo_lernen/widgets/design/lumo_learning_module_frame.dart';
import 'package:lumo_lernen/widgets/design/lumo_quantity_art.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';

class _GatedWallet extends RewardWalletRepository {
  final gate = Completer<void>();
  @override
  Future<RewardWallet> applyRewardDelta(
      {int starsDelta = 0, int xpDelta = 0}) async {
    await gate.future;
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }
}

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<LumoAppState> _open(
  WidgetTester tester,
  String topic, {
  double textScale = 1,
  RewardWalletRepository? wallet,
  int? minusSeed,
  int? numberSeed,
}) async {
  final app = LumoAppState(walletRepository: wallet);
  addTearDown(app.dispose);
  await tester.runAsync(() async {
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  await tester.pumpWidget(MaterialApp(
    theme: LumoAppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: topic == 'm1_minus10' && minusSeed != null
        ? MinusBis10Screen(appState: app, taskRandom: math.Random(minusSeed))
        : topic == 'm1_zahlen10' && numberSeed != null
            ? ZahlenBis10Screen(
                appState: app, taskRandom: math.Random(numberSeed))
            : LearningModuleRegistry.builderFor(topic, app),
  ));
  await _frames(tester);
  return app;
}

Finder _answers(String topic) => find.descendant(
    of: find.byType(GridView),
    // The actual SOL maths route now uses pressable crystal answer widgets.
    // Preserve the original accessibility, visible-bounds and 48dp assertions
    // against the REAL answer controls, rather than counting inner gestures
    // (or the removed legacy wrapper).
    matching: {'m1_plus10', 'm1_minus10', 'm1_zahlen10'}.contains(topic)
        ? find.byType(LumoAnswerCrystal)
        : find.byType(LumoLessonAnswerTap));

int _choiceCount(String topic) => topic == 'm1_zahlen10' &&
        find.text('Welche Zahl ist größer?').evaluate().isNotEmpty
    ? 2
    : 4;

int _minusSeedForAmount(int amount) {
  for (var seed = 0; seed < 1000; seed++) {
    if (3 + math.Random(seed).nextInt(8) == amount) return seed;
  }
  throw StateError('No reproducible seed for amount $amount');
}

int _numberSeedFor(int kind, int first, {int? second}) {
  for (var seed = 0; seed < 10000; seed++) {
    final random = math.Random(seed);
    if (random.nextInt(3) != kind) continue;
    final number = kind == 1 ? random.nextInt(10) : 1 + random.nextInt(10);
    if (number != first) continue;
    if (second != null) {
      var other = 1 + random.nextInt(10);
      while (other == number) {
        other = 1 + random.nextInt(10);
      }
      if (other != second) continue;
    }
    return seed;
  }
  throw StateError('No reproducible number task: $kind, $first, $second');
}

void _expectVisibleAnswers(WidgetTester tester, String topic) {
  final choices = _answers(topic);
  if ({'m1_plus10', 'm1_minus10', 'm1_zahlen10'}.contains(topic)) {
    expect(choices, findsWidgets,
        reason: 'Real arithmetic answers must use interactive Lumo crystals');
  }
  expect(choices, findsNWidgets(_choiceCount(topic)));
  final navigation = tester.getRect(find.byType(LumoBottomNavigation));
  for (final element in choices.evaluate()) {
    final choice = find.byWidget(element.widget);
    expect(choice.hitTestable(), findsOneWidget);
    expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
    expect(tester.getRect(choice).bottom, lessThanOrEqualTo(navigation.top));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _viewport(WidgetTester tester, Size size,
    {double density = 1, bool systemBars = false}) async {
  tester.view.devicePixelRatio = density;
  tester.view.physicalSize = size * density;
  tester.view.padding = FakeViewPadding(
      top: systemBars ? 24 * density : 0,
      bottom: systemBars ? 24 * density : 0);
  await tester.binding.setSurfaceSize(size);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetPadding);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);
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

  for (final topic in [
    'm1_plus10',
    'm1_minus10',
    'm1_zahlen10',
    'm1_formen',
    'm2_uhr'
  ]) {
    testWidgets('$topic short landscape shows the task and every answer',
        (tester) async {
      await _viewport(tester, const Size(640, 360), systemBars: true);
      await _open(tester, topic,
          minusSeed: _minusSeedForAmount(10),
          numberSeed: _numberSeedFor(0, 10));
      final choices = _answers(topic);
      expect(choices, findsNWidgets(_choiceCount(topic)));
      for (final element in choices.evaluate()) {
        final choice = find.byWidget(element.widget);
        expect(choice.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(choice);
        expect(bounds.top, greaterThanOrEqualTo(24));
        expect(bounds.bottom, lessThanOrEqualTo(336));
        expect(bounds.height, greaterThanOrEqualTo(48));
        expect(bounds.width, greaterThanOrEqualTo(48));
      }
      expect(find.byTooltip('Zur Lernübersicht').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets('$topic large text landscape keeps answers reachable',
        (tester) async {
      await _viewport(tester, const Size(640, 360), systemBars: true);
      await _open(tester, topic, textScale: 2);
      for (final element in _answers(topic).evaluate()) {
        final choice = find.byWidget(element.widget);
        await tester.ensureVisible(choice);
        await tester.pump();
        expect(choice.hitTestable(), findsOneWidget);
      }
      expect(find.byTooltip('Zur Lernübersicht').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    for (final layout in [
      ('phone', const Size(360, 800), 1.0, false),
      ('phone-safe', const Size(360, 800), 1.0, true),
      ('fold', const Size(2176 / 2.25, 1812 / 2.25), 2.25, true),
      ('wide', const Size(1280, 720), 1.0, true),
    ]) {
      testWidgets('$topic ${layout.$1} visible answers and complete Lumo',
          (tester) async {
        await _viewport(tester, layout.$2,
            density: layout.$3, systemBars: layout.$4);
        await _open(tester, topic);
        final choices = _answers(topic);
        expect(choices, findsNWidgets(_choiceCount(topic)));
        final navigation = tester.getRect(find.byType(LumoBottomNavigation));
        for (final choice in choices.evaluate()) {
          final target = find.byWidget(choice.widget);
          if (topic == 'm1_minus10') {
            // The faceted 108dp answers need actual scroll on compact phones.
            // Do not weaken the visible-area or 48dp safety requirements.
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
          }
          final rect = tester.getRect(target);
          expect(rect.height, greaterThanOrEqualTo(
              topic == 'm1_minus10' ? 100 : 48));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.top, greaterThan(24));
          expect(rect.bottom, lessThanOrEqualTo(navigation.top),
              reason: 'An answer must not be covered by bottom navigation');
          expect(target.hitTestable(), findsOneWidget);
        }
        if (topic != 'm1_plus10' || layout.$2.width >= 760) {
          final fox = tester
              .getRect(find.byKey(const ValueKey('learning-module-lumo')));
          expect(
              fox.top,
              greaterThanOrEqualTo(
                  tester.getRect(find.byType(LumoTopBar)).bottom));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
    testWidgets('$topic large text keeps all generated controls reachable',
        (tester) async {
      await _viewport(tester, const Size(360, 800), systemBars: true);
      await _open(tester, topic, textScale: 2);
      final choices = _answers(topic);
      expect(choices, findsNWidgets(_choiceCount(topic)));
      for (final choice in choices.evaluate()) {
        final target = find.byWidget(choice.widget);
        await tester.ensureVisible(target);
        await tester.pump();
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('visible Plus quantities equal the actual sum, without emoji',
      (tester) async {
    await _viewport(tester, const Size(360, 800));
    await _open(tester, 'm1_plus10');
    final task = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .singleWhere((text) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(text));
    final amount = RegExp(r'\d+')
        .allMatches(task)
        .map((match) => int.parse(match[0]!))
        .reduce((a, b) => a + b);
    expect(find.byType(LumoQuantityArt), findsNWidgets(amount));
    expect(find.text('🍎'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (var amount = 3; amount <= 10; amount++) {
    for (final layout in [
      ('phone-safe', const Size(360, 800), 1.0),
      ('fold-safe', const Size(2176 / 2.25, 1812 / 2.25), 2.25),
    ]) {
      testWidgets('Minus all $amount objects fit ${layout.$1}', (tester) async {
        await _viewport(tester, layout.$2,
            density: layout.$3, systemBars: true);
        await _open(tester, 'm1_minus10',
            minusSeed: _minusSeedForAmount(amount));
        final prompt = tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data ?? '')
            .singleWhere((text) => RegExp(r'^\d+ − \d+ = \?$').hasMatch(text));
        expect(prompt, startsWith('$amount − '));
        expect(find.byType(LumoQuantityArt), findsNWidgets(amount));
        final navigation = tester.getRect(find.byType(LumoBottomNavigation));
        for (final element in _answers('m1_minus10').evaluate()) {
          final choice = find.byWidget(element.widget);
          await tester.ensureVisible(choice);
          await tester.pumpAndSettle();
          expect(choice.hitTestable(), findsOneWidget);
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(100));
          final rect = tester.getRect(choice);
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(rect.bottom, lessThanOrEqualTo(navigation.top),
              reason: 'Scroll-revealed pedestal must clear bottom navigation');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final layout in [
    ('phone-safe', const Size(360, 800), 1.0),
    ('fold-safe', const Size(2176 / 2.25, 1812 / 2.25), 2.25),
  ]) {
    for (var amount = 1; amount <= 10; amount++) {
      testWidgets('Zahlen counts all $amount points in ${layout.$1}',
          (tester) async {
        await _viewport(tester, layout.$2,
            density: layout.$3, systemBars: true);
        await _open(tester, 'm1_zahlen10',
            numberSeed: _numberSeedFor(0, amount));
        expect(find.text('Wie viele Punkte siehst du?'), findsOneWidget);
        for (var i = 0; i < amount; i++) {
          expect(find.byKey(ValueKey('zahlen-dot-$i')), findsOneWidget);
        }
        expect(find.byKey(ValueKey('zahlen-dot-$amount')), findsNothing);
        _expectVisibleAnswers(tester, 'm1_zahlen10');
        await tester.pumpWidget(const SizedBox());
      });
    }
    for (final number in [0, 8, 9]) {
      testWidgets('Zahlen successor of $number in ${layout.$1}',
          (tester) async {
        await _viewport(tester, layout.$2,
            density: layout.$3, systemBars: true);
        await _open(tester, 'm1_zahlen10',
            numberSeed: _numberSeedFor(1, number));
        expect(find.text('Welche Zahl kommt nach $number?'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
        _expectVisibleAnswers(tester, 'm1_zahlen10');
        await tester.pumpWidget(const SizedBox());
      });
    }
    testWidgets('Zahlen compares only 1 and 10 in ${layout.$1}',
        (tester) async {
      await _viewport(tester, layout.$2, density: layout.$3, systemBars: true);
      await _open(tester, 'm1_zahlen10',
          numberSeed: _numberSeedFor(2, 1, second: 10));
      expect(find.text('Welche Zahl ist größer?'), findsOneWidget);
      expect(_answers('m1_zahlen10'), findsNWidgets(2));
      _expectVisibleAnswers(tester, 'm1_zahlen10');
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Minus preserves every object and precisely the removed amount',
      (tester) async {
    await _viewport(tester, const Size(360, 800));
    await _open(tester, 'm1_minus10');
    final task = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .singleWhere((text) => RegExp(r'^\d+ − \d+ = \?$').hasMatch(text));
    final amounts = RegExp(r'\d+')
        .allMatches(task)
        .map((match) => int.parse(match[0]!))
        .toList();
    expect(find.byType(LumoQuantityArt), findsNWidgets(amounts[0]));
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(amounts[1]));
    expect(
        tester
            .widgetList<Opacity>(find.byType(Opacity))
            .where((widget) => widget.opacity == .28),
        hasLength(amounts[1]));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('real success reacts only after durable saving completes',
      (tester) async {
    await _viewport(tester, const Size(360, 800));
    final wallet = _GatedWallet();
    final app = await _open(tester, 'm1_minus10', wallet: wallet);
    final fox = tester.widget<LumoCharacter>(
        find.byKey(const ValueKey('learning-module-lumo')));
    final controller = fox.controller!;
    final serial = controller.serial;
    final task = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .singleWhere((text) => RegExp(r'^\d+ − \d+ = \?$').hasMatch(text));
    final numbers = RegExp(r'\d+')
        .allMatches(task)
        .map((match) => int.parse(match[0]!))
        .toList();
    final answer = find.descendant(
        of: find.byType(GridView),
        matching: find.text('${numbers[0] - numbers[1]}'));
    await tester.tap(answer);
    await _frames(tester);
    expect(controller.serial, serial);
    expect(controller.pending, isNot(LumoCharacterAction.cheer));
    expect(find.text('0 richtig'), findsOneWidget);
    expect(find.byKey(const ValueKey('learning-module-back')).hitTestable(),
        findsNothing);
    wallet.gate.complete();
    await _frames(tester);
    expect(controller.pending, LumoCharacterAction.cheer);
    expect(find.text('1 richtig'), findsOneWidget);
    expect(app.learningDailyDone(), 1);
    await tester.pumpWidget(const SizedBox());
  });
}
