import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/teacher_mode/topic_curriculum.dart';

class _ControlledWallet extends RewardWalletRepository {
  bool reject = false;
  Completer<void>? gate;
  final transactions = <(int, int)>[];

  @override
  Future<RewardWallet> applyRewardDelta({
    int starsDelta = 0,
    int xpDelta = 0,
  }) async {
    transactions.add((starsDelta, xpDelta));
    if (reject) throw StateError('Wallet storage unavailable');
    await gate?.future;
    return super.applyRewardDelta(
      starsDelta: starsDelta,
      xpDelta: xpDelta,
    );
  }
}

class _ControlledProgress extends ProgressRepository {
  bool reject = false;
  Completer<void>? gate;

  @override
  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    if (reject) throw StateError('Learning storage unavailable');
    await gate?.future;
    await super.saveSkills(skills);
  }
}

class _ModuleCase {
  const _ModuleCase(this.topicId, this.subject, this.unit, this.correctXp);

  final String topicId;
  final String subject;
  final String unit;
  final int correctXp;
}

const _modules = [
  _ModuleCase('d2_artikel', 'Deutsch', 'Der/Die/Das', 6),
  _ModuleCase('d2_mehrzahl', 'Deutsch', 'Mehrzahl', 7),
  _ModuleCase('d3_wortarten', 'Deutsch', 'Wortarten', 7),
  _ModuleCase('d3_zeitformen', 'Deutsch', 'Zeitformen', 7),
  _ModuleCase('d1_woerter', 'Deutsch', 'Erste Wörter', 8),
  _ModuleCase('s1_tiere', 'Sachunterricht', 'Tiere', 7),
  _ModuleCase('s1_farben', 'Sachunterricht', 'Farben', 7),
  _ModuleCase('s2_jahreszeiten', 'Sachunterricht', 'Jahreszeiten', 7),
  _ModuleCase('s2_wetter', 'Sachunterricht', 'Wetter', 7),
  _ModuleCase('s2_verkehr', 'Sachunterricht', 'Verkehr', 8),
];

// Grammar expectations come from the visible noun, independently of the
// screen's answer closures, private state, and persisted correctness flag.
const _articles = {
  'Hund': 'der',
  'Apfel': 'der',
  'Ball': 'der',
  'Baum': 'der',
  'Tisch': 'der',
  'Vogel': 'der',
  'Schuh': 'der',
  'Bus': 'der',
  'Mond': 'der',
  'Katze': 'die',
  'Blume': 'die',
  'Sonne': 'die',
  'Banane': 'die',
  'Maus': 'die',
  'Tasche': 'die',
  'Uhr': 'die',
  'Lampe': 'die',
  'Tür': 'die',
  'Auto': 'das',
  'Haus': 'das',
  'Kind': 'das',
  'Buch': 'das',
  'Brot': 'das',
  'Pferd': 'das',
  'Wasser': 'das',
  'Bett': 'das',
  'Fahrrad': 'das',
};

Future<void> _frames(WidgetTester tester, [int count = 200]) async {
  // UI/feedback use the fake clock, while _open loads cached storage Futures
  // in runAsync. Give that real event loop a turn between frames so an awaited
  // profile selection/save can finish before advancing the feedback clock.
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(microseconds: 16667));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<Type> _open(
  WidgetTester tester,
  LumoAppState app,
  String topicId,
) async {
  await tester.binding.setSurfaceSize(const Size(840, 1000));
  app.updateSettings(const AppSettings(
    soundEnabled: false,
    voiceEnabled: false,
    autoReadEnabled: false,
  ));
  await tester.runAsync(() async {
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: navigator,
    home: const Scaffold(body: Text('Modulauswahl')),
  ));
  final module = LearningModuleRegistry.builderFor(topicId, app);
  expect(module, isNotNull);
  unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => module!,
  )));
  await _frames(tester, 50);
  expect(find.byType(module!.runtimeType), findsOneWidget);
  expect(_taskLabel(tester), matches(RegExp(r'^(Aufgabe|Wort) 1 / \d+$')));
  return module.runtimeType;
}

String _taskLabel(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .singleWhere(
        (text) => RegExp(r'^(Aufgabe|Wort) \d+ / \d+$').hasMatch(text));

void _expectTask(WidgetTester tester, String initialLabel, int task) {
  expect(
      _taskLabel(tester), initialLabel.replaceFirst(RegExp(r'\d+'), '$task'));
}

String _visibleNoun(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .singleWhere(_articles.containsKey);

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  int frames = 200,
}) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _frames(tester, frames);
}

Finder _firstVisibleAnswer() => find
    .byWidgetPredicate((widget) =>
        widget is GestureDetector &&
        widget.onTap != null &&
        widget.child is AnimatedContainer)
    .first;

Future<void> _revealWrittenWord(WidgetTester tester) async {
  expect(find.text('Das richtige Wort war:'), findsNothing);
  final canvas = find
      .byWidgetPredicate((widget) =>
          widget is GestureDetector &&
          widget.onPanStart != null &&
          widget.onPanUpdate != null)
      .first;
  await tester.drag(canvas, const Offset(70, 20));
  await tester.pump();
  await _tapText(tester, 'Fertig ✓', frames: 40);
  expect(find.text('Das richtige Wort war:'), findsOneWidget);
  expect(find.text('Wie war dein Wort?'), findsOneWidget);
}

String _revealedWord(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .singleWhere((text) => RegExp(r'^[A-ZÄÖÜ]{2,}$').hasMatch(text));

Future<void> _assertStored(
  WidgetTester tester, {
  required _ModuleCase module,
  required int correct,
  required int wrong,
  required int stars,
  required int xp,
}) async {
  await tester.runAsync(() async {
    final restored = LumoAppState(walletRepository: RewardWalletRepository());
    try {
      await restored.hydrateFromWallet();
      await restored.loadLearningProfile();
      final id = SkillRecord.makeId(module.subject, module.unit);
      expect(restored.learningSkills().keys, [id]);
      final skill = restored.learningSkills()[id]!;
      expect(skill.subject, module.subject);
      expect(skill.unit, module.unit);
      expect(skill.correct, correct);
      expect(skill.wrong, wrong);
      expect(skill.attempts, correct + wrong);
      expect(skill.hintCount, 0);
      expect(
          restored.learningProfile.lastTopics, {module.subject: module.unit});
      expect(restored.learningDailyDone(), correct);
      expect(
          restored
              .learningProfileDailyMap()
              .values
              .fold<int>(0, (total, daily) => total + daily),
          correct);
      expect(restored.state.stars, stars);
      expect(restored.state.xp, xp);
    } finally {
      restored.dispose();
    }
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
      'MaterialIcons': 'MaterialIcons-Regular.otf',
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
    LumoSound.instance.muted = true;
  });

  for (final module in _modules) {
    testWidgets(
        '${module.topicId} real registry answer persists its exact subject and topic',
        (tester) async {
      expect(TopicCurriculum.of(module.topicId)!.title, module.unit);
      final wallet = _ControlledWallet();
      final app = LumoAppState(walletRepository: wallet);
      await _open(tester, app, module.topicId);
      final initialTask = _taskLabel(tester);
      if (module.topicId == 'd1_woerter') {
        await _revealWrittenWord(tester);
        await _tapText(tester, 'Nochmal\nüben');
      } else {
        final answer = _firstVisibleAnswer();
        await tester.ensureVisible(answer);
        await tester.pump();
        await tester.tap(answer);
        await _frames(tester);
      }
      _expectTask(tester, initialTask, 2);
      // This matrix checks persistence and topic routing. Correctness for a
      // random first option is inferred from the module's actual star award.
      // The dedicated article test below checks answer quality independently.
      expect(app.state.stars, anyOf(0, 1));
      final correct = app.state.stars;
      expect(wallet.transactions,
          correct == 1 ? [(1, module.correctXp)] : isEmpty);
      await _assertStored(tester,
          module: module,
          correct: correct,
          wrong: 1 - correct,
          stars: correct,
          xp: correct * module.correctXp);
      await _dispose(tester, app);
    });
  }

  testWidgets(
      'visible noun determines right and wrong articles and only right advances Daily',
      (tester) async {
    final wallet = _ControlledWallet();
    final app = LumoAppState(walletRepository: wallet);
    await _open(tester, app, 'd2_artikel');
    final initialTask = _taskLabel(tester);
    final firstWord = _visibleNoun(tester);
    await _tapText(tester, _articles[firstWord]!);
    _expectTask(tester, initialTask, 2);
    await _assertStored(tester,
        module: _modules.first, correct: 1, wrong: 0, stars: 1, xp: 6);
    final nextWord = _visibleNoun(tester);
    final wrong = ['der', 'die', 'das']
        .firstWhere((article) => article != _articles[nextWord]);
    await _tapText(tester, wrong);
    _expectTask(tester, initialTask, 3);
    expect(wallet.transactions, [(1, 6)]);
    await _assertStored(tester,
        module: _modules.first, correct: 1, wrong: 1, stars: 1, xp: 6);
    await _dispose(tester, app);
  });

  testWidgets(
      'article wallet rejection blocks Back and task change; duplicate retries save one answer',
      (tester) async {
    final wallet = _ControlledWallet();
    final app = LumoAppState(walletRepository: wallet);
    final screen = await _open(tester, app, 'd2_artikel');
    final initialTask = _taskLabel(tester);
    final word = _visibleNoun(tester);
    wallet.reject = true;
    final answer = tester.getCenter(find.text(_articles[word]!));
    await tester.tapAt(answer);
    await tester.tapAt(answer);
    await _frames(tester);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(_taskLabel(tester), initialTask);
    expect(_visibleNoun(tester), word);
    expect(wallet.transactions, [(1, 6)]);
    await tester.binding.handlePopRoute();
    await _frames(tester, 20);
    expect(find.byType(screen), findsOneWidget);
    // The pending scope intentionally absorbs the toolbar's pointer event.
    await tester
        .tapAt(tester.getCenter(find.byIcon(Icons.arrow_back_ios_new_rounded)));
    await _frames(tester, 20);
    expect(find.byType(screen), findsOneWidget);
    wallet.reject = false;
    wallet.gate = Completer<void>();
    final retry = tester.getCenter(find.text('Erneut versuchen'));
    await tester.tapAt(retry);
    await tester.tapAt(retry);
    await _frames(tester);
    expect(_taskLabel(tester), initialTask);
    expect(_visibleNoun(tester), word);
    wallet.gate!.complete();
    await _frames(tester);
    _expectTask(tester, initialTask, 2);
    expect(wallet.transactions, [(1, 6), (1, 6)]);
    await _assertStored(tester,
        module: _modules.first, correct: 1, wrong: 0, stars: 1, xp: 6);
    await tester.binding.handlePopRoute();
    await _frames(tester, 40);
    expect(find.byType(screen), findsNothing);
    await _dispose(tester, app);
  });

  testWidgets(
      'article learning-save rejection retries existing counters without another reward',
      (tester) async {
    final progress = _ControlledProgress();
    final wallet = _ControlledWallet();
    final app = LumoAppState(
        walletRepository: wallet,
        learningProfile: LearningProfileEngine(repository: progress));
    final screen = await _open(tester, app, 'd2_artikel');
    final initialTask = _taskLabel(tester);
    final word = _visibleNoun(tester);
    progress.reject = true;
    await _tapText(tester, _articles[word]!);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(_taskLabel(tester), initialTask);
    expect(_visibleNoun(tester), word);
    expect(app.learningDailyDone(), 1);
    expect(app.learningSkills().values.single.correct, 1);
    expect(wallet.transactions, [(1, 6)]);
    final storedDaily =
        await tester.runAsync(() => ProgressRepository().loadDaily());
    expect(storedDaily!.values.fold<int>(0, (a, b) => a + b), 0);
    await tester.binding.handlePopRoute();
    await _frames(tester, 20);
    expect(find.byType(screen), findsOneWidget);
    progress.reject = false;
    progress.gate = Completer<void>();
    final retry = tester.getCenter(find.text('Erneut versuchen'));
    await tester.tapAt(retry);
    await tester.tapAt(retry);
    await _frames(tester);
    expect(_taskLabel(tester), initialTask);
    expect(app.learningSkills().values.single.correct, 1);
    progress.gate!.complete();
    await _frames(tester);
    _expectTask(tester, initialTask, 2);
    expect(wallet.transactions, [(1, 6)]);
    await _assertStored(tester,
        module: _modules.first, correct: 1, wrong: 0, stars: 1, xp: 6);
    await _dispose(tester, app);
  });

  testWidgets(
      'pending wrong article rejects a second answer until learning storage finishes',
      (tester) async {
    final progress = _ControlledProgress();
    final wallet = _ControlledWallet();
    final app = LumoAppState(
        walletRepository: wallet,
        learningProfile: LearningProfileEngine(repository: progress));
    await _open(tester, app, 'd2_artikel');
    final initialTask = _taskLabel(tester);
    final word = _visibleNoun(tester);
    final correct = _articles[word]!;
    final wrong = ['der', 'die', 'das'].firstWhere((value) => value != correct);
    progress.gate = Completer<void>();
    await _tapText(tester, wrong, frames: 2);
    // This is intentionally aimed at an answer behind the pending save scope.
    await tester.tapAt(tester.getCenter(find.text(correct)));
    await _frames(tester);
    expect(_taskLabel(tester), initialTask);
    expect(_visibleNoun(tester), word);
    expect(wallet.transactions, isEmpty);
    progress.gate!.complete();
    await _frames(tester);
    _expectTask(tester, initialTask, 2);
    await _assertStored(tester,
        module: _modules.first, correct: 0, wrong: 1, stars: 0, xp: 0);
    await _tapText(tester, _articles[_visibleNoun(tester)]!);
    await _assertStored(tester,
        module: _modules.first, correct: 1, wrong: 1, stars: 1, xp: 6);
    await _dispose(tester, app);
  });

  testWidgets(
      'saved article feedback waits for foreground before showing the next word',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await _open(tester, app, 'd2_artikel');
    final initialTask = _taskLabel(tester);
    final word = _visibleNoun(tester);
    await _tapText(tester, _articles[word]!, frames: 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    try {
      await _frames(tester);
      expect(_taskLabel(tester), initialTask);
      expect(_visibleNoun(tester), word);
      await _assertStored(tester,
          module: _modules.first, correct: 1, wrong: 0, stars: 1, xp: 6);
    } finally {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    await _frames(tester);
    _expectTask(tester, initialTask, 2);
    await _dispose(tester, app);
  });

  testWidgets(
      'actual Diktat canvas and duplicate self-ratings persist one correct and one wrong word',
      (tester) async {
    final wallet = _ControlledWallet();
    final app = LumoAppState(walletRepository: wallet);
    final screen = await _open(tester, app, 'd1_woerter');
    final initialTask = _taskLabel(tester);
    await _revealWrittenWord(tester);
    final word = _revealedWord(tester);
    wallet.gate = Completer<void>();
    final right = tester.getCenter(find.text('Ich hatte\nes richtig!'));
    await tester.tapAt(right);
    await tester.tapAt(right);
    await _frames(tester);
    expect(_taskLabel(tester), initialTask);
    expect(_revealedWord(tester), word);
    expect(wallet.transactions, [(1, 8)]);
    await tester.binding.handlePopRoute();
    await _frames(tester, 20);
    expect(find.byType(screen), findsOneWidget);
    wallet.gate!.complete();
    await _frames(tester);
    _expectTask(tester, initialTask, 2);
    expect(find.text('Das richtige Wort war:'), findsNothing);
    await _revealWrittenWord(tester);
    final wrong = tester.getCenter(find.text('Nochmal\nüben'));
    await tester.tapAt(wrong);
    await tester.tapAt(wrong);
    await _frames(tester);
    _expectTask(tester, initialTask, 3);
    expect(wallet.transactions, [(1, 8)]);
    await _assertStored(tester,
        module: _modules[4], correct: 1, wrong: 1, stars: 1, xp: 8);
    await _dispose(tester, app);
  });

  testWidgets(
      'two complete actual Diktat sessions show twenty words and award each earned bonus without extra Daily',
      (tester) async {
    final wallet = _ControlledWallet();
    final app = LumoAppState(walletRepository: wallet);
    for (var session = 1; session <= 2; session++) {
      final screen = await _open(tester, app, 'd1_woerter');
      for (var word = 1; word <= 20; word++) {
        expect(find.text('Wort $word / 20'), findsOneWidget);
        await _revealWrittenWord(tester);
        await _tapText(tester, 'Ich hatte\nes richtig!', frames: 70);
      }
      expect(find.text('🎉 Diktat fertig!'), findsOneWidget);
      expect(find.text('20 / 20 richtig geschrieben!'), findsOneWidget);
      expect(wallet.transactions.where((reward) => reward == (1, 8)),
          hasLength(session * 20));
      expect(wallet.transactions.where((reward) => reward == (5, 240)),
          hasLength(session));
      await _assertStored(tester,
          module: _modules[4],
          correct: session * 20,
          wrong: 0,
          stars: session * 25,
          xp: session * 400);
      await _tapText(tester, 'Fertig', frames: 40);
      expect(find.byType(screen), findsNothing);
      expect(find.text('Modulauswahl'), findsOneWidget);
    }
    await _dispose(tester, app);
  });
}
