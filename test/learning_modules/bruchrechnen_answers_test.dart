import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/bruchrechnen/bruchrechnen_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

class _RejectWallet extends RewardWalletRepository {
  bool reject = true;
  int attempts = 0;

  @override
  Future<RewardWallet> applyRewardDelta({int starsDelta = 0, int xpDelta = 0}) {
    attempts++;
    if (reject) return Future.error(StateError('Disk unavailable'));
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }
}

class _RejectProgress extends ProgressRepository {
  bool reject = false;

  @override
  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    if (reject) throw StateError('Learning disk unavailable');
    await super.saveSkills(skills);
  }
}

bool _sameValue(String first, String second) {
  final a = first.split('/').map(int.parse).toList();
  final b = second.split('/').map(int.parse).toList();
  return a[0] * b[1] == b[0] * a[1];
}

List<String> _options(WidgetTester tester) => tester
    .widgetList<Text>(
        find.descendant(of: find.byType(GridView), matching: find.byType(Text)))
    .map((text) => text.data ?? '')
    .where((text) => RegExp(r'^\d+/\d+$').hasMatch(text))
    .toList();

String _pizzaFraction(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .singleWhere((text) => text.startsWith('Von '));
  final match =
      RegExp(r'^Von (\d+) Stücken wurden? (\d+) gegessen\.$').firstMatch(text)!;
  return '${match[2]}/${match[1]}';
}

Future<void> _frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

Future<void> _stored(WidgetTester tester,
        {required int correct,
        required int wrong,
        required int stars,
        required int xp}) =>
    tester.runAsync(() async {
      final restored = LumoAppState(walletRepository: RewardWalletRepository());
      await restored.hydrateFromWallet();
      await restored.loadLearningProfile();
      expect(restored.learningDailyDone(), correct);
      final skill = restored.learningSkills()[
          SkillRecord.makeId('Mathematik', 'Bruchrechnen einfach')]!;
      expect(skill.correct, correct);
      expect(skill.wrong, wrong);
      expect(restored.state.stars, stars);
      expect(restored.state.xp, xp);
      restored.dispose();
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf'
    }.entries) {
      final file = File('$fonts/${entry.value}');
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key);
      loader.addFont(
          Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  test(
      'equivalent fractions are accepted; malformed or zero denominators are rejected',
      () {
    for (var denominator = 2; denominator <= 8; denominator++) {
      for (var numerator = 1; numerator < denominator; numerator++) {
        final expected = '$numerator/$denominator';
        expect(
            areEquivalentFractionAnswers(
                '${numerator * 3}/${denominator * 3}', expected),
            isTrue);
        for (var otherDenominator = 2;
            otherDenominator <= 8;
            otherDenominator++) {
          for (var otherNumerator = 1;
              otherNumerator < otherDenominator;
              otherNumerator++) {
            final other = '$otherNumerator/$otherDenominator';
            expect(areEquivalentFractionAnswers(other, expected),
                _sameValue(other, expected));
          }
        }
      }
    }
    expect(areEquivalentFractionAnswers(' +2 / 4 ', '1/2'), isTrue);
    expect(areEquivalentFractionAnswers('-2/-4', '1/2'), isTrue);
    expect(areEquivalentFractionAnswers('0/3', '0/7'), isTrue);
    for (final invalid in ['1/0', '0/0', '1/', '/2', '1/2/3', '0.5', 'text']) {
      expect(areEquivalentFractionAnswers(invalid, '1/2'), isFalse);
    }
  });

  testWidgets(
      'actual grade4 module keeps four distinct fraction values and scores one full session',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(grade: 4));
    app.updateSettings(const AppSettings(voiceEnabled: false));
    await tester.runAsync(() => app.hydrateFromWallet());
    await tester
        .pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
    await _frames(tester);
    await tester.ensureVisible(find.text('Mathe'));
  await tester.pump();
    await tester.tap(find.text('Mathe'));
    await _frames(tester);
    // Themen weit unterhalb der Falz werden im Lazy-Sliver später gebaut.
    // scrollUntilVisible findet auch noch nicht erzeugte Listenelemente.
    await tester.scrollUntilVisible(
      find.text('Bruchrechnen'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
  await tester.pump();
    await tester.tap(find.text('Bruchrechnen'));
    await _frames(tester);
    expect(find.byType(BruchrechnenScreen), findsOneWidget);

    for (var task = 0; task < 8; task++) {
      expect(find.text('Bruch ${task + 1} / 8'), findsOneWidget);
      final expected = _pizzaFraction(tester);
      final options = _options(tester);
      expect(options, hasLength(4));
      expect(options.where((option) => _sameValue(option, expected)),
          hasLength(1));
      for (var i = 0; i < options.length; i++) {
        for (var j = i + 1; j < options.length; j++) {
          expect(_sameValue(options[i], options[j]), isFalse);
        }
      }
      final chosen = options.firstWhere((option) => task == 0
          ? !_sameValue(option, expected)
          : _sameValue(option, expected));
      final answer = find.descendant(
          of: find.byType(GridView), matching: find.text(chosen));
      await tester.ensureVisible(answer);
  await tester.pump();
      await tester.tap(answer);
      await tester.pump();
      if (task == 0) {
        expect(app.state.stars, 0);
        expect(app.state.xp, 0);
      }
      await _frames(tester, 190);
    }
    expect(find.text('7 / 8 Brüche richtig!'), findsOneWidget);
    expect(app.state.stars, 11);
    expect(app.state.xp, 154);
    await tester.runAsync(() => app.flushRewards());
    await _stored(tester, correct: 7, wrong: 1, stars: 11, xp: 154);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'fraction answer waits for wallet and profile retry without duplicate credit',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final wallet = _RejectWallet();
    final progress = _RejectProgress();
    final app = LumoAppState(
      walletRepository: wallet,
      learningProfile: LearningProfileEngine(repository: progress),
    );
    app.updateSettings(const AppSettings(voiceEnabled: false));
    await tester.runAsync(() async {
      await app.hydrateFromWallet();
      await app.loadLearningProfile();
    });
    await tester
        .pumpWidget(MaterialApp(home: BruchrechnenScreen(appState: app)));
    await _frames(tester);
    final answer =
        find.descendant(of: find.byType(GridView), matching: find.text('1/2'));
    await tester.tap(answer);
    await _frames(tester, 190);
    expect(find.text('Bruch 1 / 8'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(wallet.snapshot.stars, 0);
    expect(app.learningDailyDone(), 0);
    await tester.tap(answer, warnIfMissed: false);
    await tester.pump();
    expect(wallet.attempts, 1);

    wallet.reject = false;
    progress.reject = true;
    await tester.tap(find.text('Erneut versuchen'));
    await _frames(tester, 190);
    expect(find.text('Bruch 1 / 8'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(wallet.snapshot.stars, 1);
    expect(wallet.snapshot.xp, 10);
    expect(app.learningDailyDone(), 1);

    progress.reject = false;
    await tester.tap(find.text('Erneut versuchen'));
    await _frames(tester, 190);
    expect(find.text('Bruch 2 / 8'), findsOneWidget);
    await _stored(tester, correct: 1, wrong: 0, stars: 1, xp: 10);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });
}
