import 'dart:async';
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
import 'package:lumo_lernen/core/writing_progress_repository.dart';
import 'package:lumo_lernen/domain/writing/writing_word_bank.dart';
import 'package:lumo_lernen/domain/writing/writing_progress.dart';
import 'package:lumo_lernen/features/writing/lumo_writing_word_coach_screen.dart';
import 'package:lumo_lernen/features/writing/writing_engine.dart';

class _BlockedWallet extends RewardWalletRepository {
  bool reject = false;
  Completer<void>? gate;
  int attempts = 0;

  @override
  Future<RewardWallet> applyRewardDelta({
    int starsDelta = 0,
    int xpDelta = 0,
  }) async {
    attempts++;
    if (reject) throw StateError('Test disk unavailable');
    await gate?.future;
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }
}

class _BlockedProfile extends ProgressRepository {
  bool reject = false;

  @override
  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    if (reject) throw StateError('Test profile disk unavailable');
    await super.saveSkills(skills);
  }
}

late Zone _storageZone;

// This is the real repository, not a fake writer. Its process-wide queue must
// live outside the per-test FakeAsync zones, which are discarded between tests.
class _WritingStorage extends WritingProgressRepository {
  @override
  Future<WritingProgress> recordAttempt({
    required String letter,
    required bool correct,
  }) =>
      _storageZone
          .run(() => super.recordAttempt(letter: letter, correct: correct));

  @override
  Future<WritingProgress> recordCompletedWord(String word) =>
      _storageZone.run(() => super.recordCompletedWord(word));
}

const _hi = WritingWordTask(
  id: 'greeting',
  word: 'Hi',
  spokenPrompt: 'Schreib Hi!',
  hint: 'Hi beginnt mit H.',
);

Future<LumoAppState> _app({
  RewardWalletRepository? wallet,
  ProgressRepository? profile,
}) async {
  final app = LumoAppState(
    walletRepository: wallet ?? RewardWalletRepository(),
    learningProfile: LearningProfileEngine(repository: profile),
  );
  app.updateSettings(const AppSettings(voiceEnabled: false));
  await app.hydrateFromWallet();
  await app.loadLearningProfile();
  return app;
}

Future<void> _frames(WidgetTester tester, [int count = 15]) async {
  for (var i = 0; i < count; i++) {
    // SharedPreferences was hydrated in the real async zone. Give its queued
    // profile/log writes a turn each frame before _stored opens another reader
    // in runAsync; otherwise that reader can wait on unpumped fake-zone work.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _open(
  WidgetTester tester,
  LumoAppState app,
  List<WritingWordTask> tasks,
) async {
  await tester.binding.setSurfaceSize(const Size(480, 950));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      return Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => LumoWritingWordCoachScreen(
              appState: app,
              sessionTasks: tasks,
              progressRepository: _WritingStorage(),
            ),
          )),
          child: const Text('Coach öffnen'),
        ),
      );
    }),
  ));
  await tester.tap(find.text('Coach öffnen'));
  await _frames(tester, 25);
}

Finder _canvas() =>
    find.byKey(const ValueKey('lumo-word-ink-surface'));

Future<void> _draw(
  WidgetTester tester,
  List<List<Offset>> strokes,
) async {
  await tester.ensureVisible(_canvas());
  await tester.pump();
  final rect = tester.getRect(_canvas());
  final scale = rect.shortestSide * .8 / 100;
  final origin = rect.center - Offset(50 * scale, 50 * scale);
  for (final points in strokes) {
    final gesture = await tester.startGesture(origin + points.first * scale);
    for (var segment = 1; segment < points.length; segment++) {
      final from = points[segment - 1];
      final to = points[segment];
      for (var step = 1; step <= 10; step++) {
        await gesture
            .moveTo(origin + Offset.lerp(from, to, step / 10)! * scale);
        await tester.pump(const Duration(milliseconds: 5));
      }
    }
    await gesture.up();
    await tester.pump();
  }
}

Future<void> _letter(WidgetTester tester, String symbol) => _draw(
      tester,
      symbol == 'M'
          ? const [
              [Offset(15, 90), Offset(15, 10)],
              [Offset(15, 10), Offset(50, 60)],
              [Offset(50, 60), Offset(85, 10)],
              [Offset(85, 10), Offset(85, 90)],
            ]
          : LetterTemplates.all[symbol]!.demoStrokes,
    );

Future<void> _submit(WidgetTester tester, {bool doubleTap = false}) async {
  final button = find.widgetWithText(ElevatedButton, 'Fertig');
  await tester.ensureVisible(button);
  await tester.tap(button);
  if (doubleTap) await tester.tap(button);
  await _frames(tester);
}

Future<void> _stored(
  WidgetTester tester, {
  required int correct,
  int wrong = 0,
  int hints = 0,
  required int stars,
  required int xp,
}) async {
  await tester.runAsync(() async {
    final reopened = await _app();
    expect(reopened.learningDailyDone(), correct);
    final record = reopened
        .learningSkills()[SkillRecord.makeId('Deutsch', 'Wörter schreiben')];
    if (correct + wrong == 0) {
      expect(record, isNull);
    } else {
      expect(record!.correct, correct);
      expect(record.wrong, wrong);
      expect(record.hintCount, hints);
    }
    expect(reopened.state.stars, stars);
    expect(reopened.state.xp, xp);
    reopened.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _storageZone = Zone.current;
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
  });

  testWidgets(
      'mute shows the target word without TTS, voice keeps the dictation',
      (tester) async {
    final app = await tester.runAsync(_app);
    const channel = MethodChannel('flutter_tts');
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getVoices') {
        return [
          {'name': 'de-at-local', 'locale': 'de-AT'}
        ];
      }
      return 1;
    });
    addTearDown(() async {
      await LumoVoice.instance.configure(enabled: false);
      messenger.setMockMethodCallHandler(channel, null);
    });
    // Keep the engine enabled so this proves the screen honours its setting.
    LumoVoice.instance.isEnabled = true;
    await _open(tester, app!, [WritingWordBank.byId('w1_mama')!]);
    expect(find.text('Schreib das Wort: Mama'), findsOneWidget);
    expect(find.text('Stimme aus · Du kannst das Wort abschreiben.'),
        findsOneWidget);
    expect(find.text('Schreibe Buchstabe 1 von 4 nach Gehör.'), findsOneWidget);
    expect(find.byTooltip('Nochmal hören'), findsNothing);
    expect(calls.where((call) => call.method == 'speak'), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    app.updateSettings(const AppSettings(voiceEnabled: true));
    await _open(tester, app, [WritingWordBank.byId('w1_mama')!]);
    expect(find.textContaining('Mama'), findsNothing);
    expect(find.text('Hör gut zu!'), findsOneWidget);
    expect(find.text('Schreibe Buchstabe 1 von 4 nach Gehör.'), findsOneWidget);
    expect(find.byTooltip('Nochmal hören'), findsOneWidget);
    expect(calls.where((call) => call.method == 'speak'), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'traced letters persist XP, one whole word counts one Daily, double tap pays once',
      (tester) async {
    final app = await tester.runAsync(_app);
    await _open(tester, app!, [WritingWordBank.byId('w1_mama')!]);
    for (var index = 0; index < 4; index++) {
      expect(
          find.text('Schreibe Buchstabe ${index + 1} von 4 nach Gehör.'), findsOneWidget);
      await _letter(tester, 'MAMA'[index]);
      await _submit(tester, doubleTap: true);
      if (index < 3) {
        await _stored(tester, correct: 0, stars: 0, xp: (index + 1) * 4);
        await _frames(tester, 45);
      }
    }
    await _frames(tester, 100);
    expect(find.text('Wortdiktat fertig!'), findsOneWidget);
    expect(find.text('1 / 1 Woerter geschafft!'), findsOneWidget);
    await _stored(tester, correct: 1, stars: 8, xp: 31);
    await tester.runAsync(() async {
      final writing = await WritingProgressRepository().load();
      expect(writing.totalAttempts, 4);
      expect(writing.totalCorrect, 4);
      expect(writing.completedWords, contains('MAMA'));
    });
    await tester.tap(find.widgetWithText(TextButton, 'Fertig'));
    await _frames(tester, 25);
    expect(find.byType(LumoWritingWordCoachScreen), findsNothing);
    await _stored(tester, correct: 1, stars: 8, xp: 31);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'wrong traced letter records false with help, corrected word keeps accuracy bonus',
      (tester) async {
    final app = await tester.runAsync(_app);
    await _open(tester, app!, [_hi]);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lumo zeigt'));
    await _draw(tester, const [
      [Offset(20, 50), Offset(80, 50)]
    ]);
    await _submit(tester);
    expect(find.widgetWithText(ElevatedButton, 'Nochmal'), findsOneWidget);
    await _stored(tester, correct: 0, wrong: 1, hints: 1, stars: 0, xp: 0);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Nochmal'));
    await _letter(tester, 'H');
    await _submit(tester);
    await _frames(tester, 45);
    await _letter(tester, 'I');
    await _submit(tester);
    await _frames(tester, 100);
    expect(find.text('Wortdiktat fertig!'), findsOneWidget);
    // One of two letters needed a retry: the original accuracy bonus is 3/5.
    await _stored(tester, correct: 1, wrong: 1, hints: 2, stars: 6, xp: 23);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failed letter wallet write blocks touch and back, Retry saves original XP once',
      (tester) async {
    final wallet = _BlockedWallet();
    final app = await tester.runAsync(() => _app(wallet: wallet));
    await _open(tester, app!, [_hi]);
    wallet.reject = true;
    await _letter(tester, 'H');
    await _submit(tester);
    expect(find.text('Deine Belohnung wartet noch aufs Speichern.'),
        findsOneWidget);
    expect(find.text('Schreibe Buchstabe 1 von 2 nach Gehör.'), findsOneWidget);
    final context = tester.element(find.byType(LumoWritingWordCoachScreen));
    expect(await Navigator.of(context).maybePop(), isTrue);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded),
        warnIfMissed: false);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Loeschen'),
        warnIfMissed: false);
    await _frames(tester, 45);
    expect(find.byType(LumoWritingWordCoachScreen), findsOneWidget);
    expect(find.text('Schreibe Buchstabe 1 von 2 nach Gehör.'), findsOneWidget);
    await _stored(tester, correct: 0, stars: 0, xp: 0);
    wallet.reject = false;
    await tester.tap(find.text('Erneut versuchen'));
    await _frames(tester, 60);
    expect(find.text('Schreibe Buchstabe 2 von 2 nach Gehör.'), findsOneWidget);
    expect(wallet.attempts, 2);
    await _stored(tester, correct: 0, stars: 0, xp: 4);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'word profile failure waits for Retry before finish without double Daily or wallet',
      (tester) async {
    final profile = _BlockedProfile();
    final app = await tester.runAsync(() => _app(profile: profile));
    await _open(tester, app!, [_hi]);
    await _letter(tester, 'H');
    await _submit(tester);
    await _frames(tester, 45);
    profile.reject = true;
    await _letter(tester, 'I');
    await _submit(tester);
    await _frames(tester, 100);
    expect(
        find.text('Deine Antwort wartet noch aufs Speichern.'), findsOneWidget);
    expect(find.text('Wortdiktat fertig!'), findsNothing);
    await _stored(tester, correct: 0, stars: 3, xp: 23);
    profile.reject = false;
    await tester.tap(find.text('Erneut versuchen'));
    await _frames(tester, 110);
    expect(find.text('Wortdiktat fertig!'), findsOneWidget);
    await _stored(tester, correct: 1, stars: 8, xp: 23);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unmount during final reward completes accepted word storage without session bonus',
      (tester) async {
    final wallet = _BlockedWallet();
    final app = await tester.runAsync(() => _app(wallet: wallet));
    await _open(tester, app!, [_hi]);
    await _letter(tester, 'H');
    await _submit(tester);
    await _frames(tester, 45);
    wallet.gate = Completer<void>();
    await _letter(tester, 'I');
    await _submit(tester);
    expect(find.text('Wir speichern deine Antwort…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    wallet.gate!.complete();
    await _frames(tester, 25);
    await _stored(tester, correct: 1, stars: 3, xp: 23);
    app.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'background pauses feedback and never advances the next letter offscreen',
      (tester) async {
    final app = await tester.runAsync(_app);
    await _open(tester, app!, [_hi]);
    await _letter(tester, 'H');
    await _submit(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester, 150);
    expect(find.text('Schreibe Buchstabe 1 von 2 nach Gehör.'), findsOneWidget);
    await _stored(tester, correct: 0, stars: 0, xp: 4);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester, 60);
    expect(find.text('Schreibe Buchstabe 2 von 2 nach Gehör.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });
}
