import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';

class _BlockedWallet extends RewardWalletRepository {
  bool reject = false;
  Completer<void>? gate;
  final transactions = <(int, int)>[];

  @override
  Future<RewardWallet> applyRewardDelta(
      {int starsDelta = 0, int xpDelta = 0}) async {
    transactions.add((starsDelta, xpDelta));
    if (reject) throw StateError('Storage unavailable');
    await gate?.future;
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }
}

class _BlockedProgress extends ProgressRepository {
  bool reject = false;
  Completer<void>? gate;
  int skillWrites = 0;

  @override
  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    skillWrites++;
    if (reject) throw StateError('Learning storage unavailable');
    await gate?.future;
    await super.saveSkills(skills);
  }
}

Future<void> _frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

Future<void> _open(WidgetTester tester, LumoAppState app) async {
  await tester.binding.setSurfaceSize(const Size(480, 800));
  await tester.runAsync(() async {
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  await tester.pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
  await _frames(tester);
  expect(find.text('LUMO AKADEMIE'), findsOneWidget);
  await tester.ensureVisible(find.text('1. Klasse'));
  await tester.tap(find.text('1. Klasse'));
  await tester.ensureVisible(find.text('Plus bis 10'));
  await tester.pump();
  await tester.tap(find.text('Plus bis 10'));
  await _frames(tester);
  expect(find.byType(PlusBis10Screen), findsOneWidget);
  expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
}

String _prompt(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .singleWhere((text) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(text));

int _answer(WidgetTester tester) => RegExp(r'\d+')
    .allMatches(_prompt(tester))
    .map((match) => int.parse(match[0]!))
    .reduce((a, b) => a + b);

Finder _button(int value) =>
    find.descendant(of: find.byType(GridView), matching: find.text('$value'));

Future<void> _tap(WidgetTester tester, int answer, {int frames = 120}) async {
  await tester.ensureVisible(_button(answer));
  await tester.tap(_button(answer));
  await _frames(tester, frames);
}

Future<void> _assertStored(WidgetTester tester,
    {required int correct,
    int wrong = 0,
    int hints = 0,
    int? stars,
    int? xp}) async {
  await tester.runAsync(() async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    expect(app.learningDailyDone(), correct);
    final skill =
        app.learningSkills()[SkillRecord.makeId('Mathematik', 'Plus bis 10')]!;
    expect(skill.correct, correct);
    expect(skill.wrong, wrong);
    expect(skill.hintCount, hints);
    if (stars != null) expect(app.state.stars, stars);
    if (xp != null) expect(app.state.xp, xp);
    app.dispose();
  });
}

Future<void> _dispose(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  app.dispose();
  await tester.binding.setSurfaceSize(null);
  expect(tester.takeException(), isNull);
}

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

  testWidgets(
      'actual Akademie grade1 topic gives local help then saves a single answer and reward',
      (tester) async {
    final wallet = _BlockedWallet();
    final app = LumoAppState(walletRepository: wallet);
    await _open(tester, app);
    final prompt = _prompt(tester);
    final correct = _answer(tester);
    final wrong = tester
        .widgetList<Text>(find.descendant(
            of: find.byType(GridView), matching: find.byType(Text)))
        .map((text) => int.parse(text.data!))
        .firstWhere((value) => value != correct);
    await _tap(tester, wrong);
    expect(_prompt(tester), prompt);
    expect(app.learningDailyDone(), 0);
    await _tap(tester, wrong);
    expect(_prompt(tester), prompt);
    expect(find.textContaining('Zähle alle Äpfel zusammen:'), findsOneWidget);
    await _tap(tester, correct);
    expect(find.text('Aufgabe 2 / 30'), findsOneWidget);
    expect(wallet.transactions, [(1, 5)]);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.byType(PlusBis10Screen), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 650));
    await _frames(tester);
    expect(find.text('LUMO AKADEMIE'), findsOneWidget);
    await _assertStored(tester,
        correct: 1, wrong: 2, hints: 1, stars: 1, xp: 5);
    await _dispose(tester, app);
  });

  testWidgets(
      'wallet failure blocks next task and Back then retries one atomic reward',
      (tester) async {
    final wallet = _BlockedWallet();
    final app = LumoAppState(walletRepository: wallet);
    await _open(tester, app);
    wallet.reject = true;
    final correct = _answer(tester);
    final point = tester.getCenter(_button(correct));
    await tester.tapAt(point);
    await tester.tapAt(point);
    await _frames(tester);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.byType(PlusBis10Screen), findsOneWidget);
    expect(wallet.transactions, [(1, 5)]);
    wallet.reject = false;
    wallet.gate = Completer<void>();
    final retry = tester.getCenter(find.text('Erneut versuchen'));
    await tester.tapAt(retry);
    await tester.tapAt(retry);
    await _frames(tester);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    wallet.gate!.complete();
    await _frames(tester, 180);
    expect(find.text('Aufgabe 2 / 30'), findsOneWidget);
    expect(wallet.transactions, [(1, 5), (1, 5)]);
    await _assertStored(tester, correct: 1, stars: 1, xp: 5);
    await _dispose(tester, app);
  });

  testWidgets(
      'profile failure retries existing counters without double-counting answer or reward',
      (tester) async {
    final repository = _BlockedProgress();
    final wallet = _BlockedWallet();
    final app = LumoAppState(
        walletRepository: wallet,
        learningProfile: LearningProfileEngine(repository: repository));
    await _open(tester, app);
    repository.reject = true;
    await _tap(tester, _answer(tester));
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    expect(app.learningDailyDone(), 1);
    expect(
        (await tester.runAsync(() => ProgressRepository().loadDaily()))!
            .values
            .fold(0, (a, b) => a + b),
        0);
    repository.reject = false;
    await tester.tap(find.text('Erneut versuchen'));
    await _frames(tester, 180);
    expect(find.text('Aufgabe 2 / 30'), findsOneWidget);
    expect(wallet.transactions, [(1, 5)]);
    await _assertStored(tester, correct: 1, stars: 1, xp: 5);
    await _dispose(tester, app);
  });

  testWidgets(
      'accepted answer continues durable saving after external unmount and background',
      (tester) async {
    final wallet = _BlockedWallet();
    final app = LumoAppState(walletRepository: wallet);
    await _open(tester, app);
    wallet.gate = Completer<void>();
    await _tap(tester, _answer(tester), frames: 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester, 120);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.byType(PlusBis10Screen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    wallet.gate!.complete();
    await _frames(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _assertStored(tester, correct: 1, stars: 1, xp: 5);
    await _dispose(tester, app);
  });

  testWidgets(
      'a pending wrong answer cannot accept a new answer before profile saving',
      (tester) async {
    final repository = _BlockedProgress();
    final wallet = _BlockedWallet();
    final app = LumoAppState(
        walletRepository: wallet,
        learningProfile: LearningProfileEngine(repository: repository));
    await _open(tester, app);
    repository.gate = Completer<void>();
    final correct = _answer(tester);
    final wrong = tester
        .widgetList<Text>(find.descendant(
            of: find.byType(GridView), matching: find.byType(Text)))
        .map((text) => int.parse(text.data!))
        .firstWhere((value) => value != correct);
    await _tap(tester, wrong, frames: 2);
    await _tap(tester, correct, frames: 90);
    expect(wallet.transactions, isEmpty);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    repository.gate!.complete();
    await _frames(tester);
    await _tap(tester, correct);
    await _assertStored(tester, correct: 1, wrong: 1, stars: 1, xp: 5);
    await _dispose(tester, app);
  });

  testWidgets(
      'saved correct feedback waits for foreground before advancing the real task',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await _open(tester, app);
    await _tap(tester, _answer(tester), frames: 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester, 180);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    await _assertStored(tester, correct: 1, stars: 1, xp: 5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester, 120);
    expect(find.text('Aufgabe 2 / 30'), findsOneWidget);
    await _dispose(tester, app);
  });

  test(
      'concurrent learning writes serialize and a failed write does not poison flush',
      () async {
    final repository = _BlockedProgress();
    final engine = LearningProfileEngine(repository: repository);
    await engine.load();
    repository.skillWrites = 0;
    repository.gate = Completer<void>();
    final first = engine.recordAnswer(
        subject: 'Mathematik', unit: 'Plus bis 10', isCorrect: true);
    await Future<void>.delayed(Duration.zero);
    final second = engine.recordAnswer(
        subject: 'Mathematik', unit: 'Plus bis 10', isCorrect: true);
    await Future<void>.delayed(Duration.zero);
    expect(repository.skillWrites, 1,
        reason: 'The second answer must wait for the first write batch');
    repository.gate!.complete();
    await Future.wait([first, second]);
    repository.reject = true;
    await expectLater(
        engine.recordAnswer(
            subject: 'Mathematik', unit: 'Plus bis 10', isCorrect: false),
        throwsStateError);
    repository.reject = false;
    await engine.flush();
    final restored = LearningProfileEngine();
    await restored.load();
    final skill =
        restored.skills[SkillRecord.makeId('Mathematik', 'Plus bis 10')]!;
    expect(skill.correct, 2);
    expect(skill.wrong, 1);
    expect(restored.dailyDone(), 2);
  });

  testWidgets(
      'thirty real visible sums complete the module and restart without farming saved bonus',
      (tester) async {
    final wallet = _BlockedWallet();
    final app = LumoAppState(walletRepository: wallet);
    await _open(tester, app);
    for (var task = 1; task <= 30; task++) {
      expect(find.text('Aufgabe $task / 30'), findsOneWidget);
      await _tap(tester, _answer(tester));
    }
    expect(find.text('Du hast 30 von 30 Aufgaben richtig!'), findsOneWidget);
    expect(
        wallet.transactions.where((entry) => entry == (5, 300)), hasLength(1));
    await _assertStored(tester, correct: 30, stars: 35, xp: 450);
    await tester.tap(find.text('Nochmal'));
    await _frames(tester);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    await _tap(tester, _answer(tester));
    await _assertStored(tester, correct: 31, stars: 36, xp: 455);
    await _dispose(tester, app);
  });
}
