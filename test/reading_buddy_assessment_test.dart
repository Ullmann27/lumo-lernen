import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reading_v2_pronunciation_analyzer.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/reading/lumo_reading_buddy_screen.dart';
import 'package:lumo_lernen/features/reading/reading_comprehension.dart';
import 'package:lumo_lernen/features/reading/reading_text_library.dart';
import 'package:lumo_lernen/features/reading/reading_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

class _Speech extends LumoSpeechListener {
  ValueChanged<String>? result;
  ValueChanged<String>? finalResult;
  int starts = 0;
  bool active = false;
  @override
  bool get listening => active;
  @override
  bool get available => true;
  @override
  bool get initialized => true;
  @override
  Future<void> startListening(
      {ValueChanged<String>? onResult,
      ValueChanged<String>? onFinalResult,
      VoidCallback? onNoMatch}) async {
    starts++;
    active = true;
    result = onResult;
    finalResult = onFinalResult;
    notifyListeners();
  }

  void emit(String text) {
    result?.call(text);
    notifyListeners();
  }

  void finish(String text) {
    active = false;
    finalResult?.call(text);
    notifyListeners();
  }

  @override
  Future<void> cancel() async {
    active = false;
  }

  @override
  Future<void> stopListening() => cancel();
}

class _ReadingState extends LumoAppState {
  _ReadingState() : super(walletRepository: RewardWalletRepository());
  @override
  Future<void> ensureSettingsLoaded() async {}
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<_ReadingState> _mount(WidgetTester tester, _Speech speech,
    {bool microphone = true}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late final _ReadingState app;
  await tester.runAsync(() async {
    app = _ReadingState();
    await app.school.setActiveStudent('reader-a');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  app.state.settings = AppSettings(
      voiceEnabled: false,
      autoReadEnabled: false,
      reduceAnimations: true,
      microphoneEnabled: microphone);
  addTearDown(app.dispose);
  await tester.pumpWidget(MaterialApp(
      home: LumoReadingBuddyScreen(appState: app, speechListener: speech)));
  await tester.tap(find.text('Mama und Tom'));
  await _frames(tester);
  return app;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _frames(tester);
}

SkillRecord? _record(LumoAppState app) =>
    app.learningSkills()[SkillRecord.makeId('Lesen', 'Leseverständnis')];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('all 24 actual stories have a bounded question tied to their exact text',
      () {
    expect(ReadingTextLibrary.all, hasLength(24));
    final positions = <int>{};
    for (final text in ReadingTextLibrary.all) {
      final question = ReadingComprehension.forText(text);
      expect(question, isNotNull, reason: text.id);
      expect(question!.answers.toSet(), hasLength(3));
      expect(question.correctIndex, inInclusiveRange(0, 2));
      expect(text.lines, contains(question.evidenceLine));
      positions.add(question.correctIndex);
      final changed = ReadingText(
          id: text.id,
          grade: text.grade,
          title: text.title,
          lines: const ['Eine andere Geschichte.'],
          emoji: text.emoji);
      expect(ReadingComprehension.forText(changed), isNull);
    }
    expect(positions, {0, 1, 2});
  });

  for (final transcript in [
    '',
    'falsches Geräusch ohne Bezug zum Text',
    ReadingTextLibrary.all.first.lines.join(' ')
  ]) {
    testWidgets(
        'recognition never grades: ${transcript.isEmpty ? "empty" : transcript}',
        (tester) async {
      final speech = _Speech();
      final app = await _mount(tester, speech);
      await _tap(tester, find.byIcon(Icons.mic_rounded));
      expect(speech.starts, 1);
      speech.emit(transcript);
      await _frames(tester);
      expect(_record(app), isNull);
      expect(app.learningDailyDone(), 0);
      expect(app.state.stars, 0);
      if (find.byKey(const ValueKey('reading-finish')).evaluate().isNotEmpty) {
        await _tap(tester, find.byKey(const ValueKey('reading-finish')));
      }
      expect(find.text('Was backt Mama?'), findsOneWidget);
      expect(_record(app), isNull);
      expect(find.textContaining('% richtig'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final correct in [true, false]) {
    testWidgets(
        'explicit ${correct ? "correct" : "wrong"} comprehension persists exactly once without microphone',
        (tester) async {
      final speech = _Speech();
      final app = await _mount(tester, speech, microphone: false);
      await _tap(tester, find.byKey(const ValueKey('reading-finish')));
      final choice = find.byKey(ValueKey('reading-answer-${correct ? 0 : 1}'));
      expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
      await _tap(tester, choice);
      await _tap(tester, choice);
      expect(speech.starts, 0);
      expect(_record(app)!.correct, correct ? 1 : 0);
      expect(_record(app)!.wrong, correct ? 0 : 1);
      expect(app.state.stars, 0);
      expect(find.textContaining('Mama backt einen Kuchen.'), findsWidgets);
      await tester.runAsync(() async {
        final reopened = _ReadingState();
        await reopened.school.setActiveStudent('reader-a');
        await reopened.loadLearningProfile();
        expect(_record(reopened)!.correct, correct ? 1 : 0);
        expect(_record(reopened)!.wrong, correct ? 0 : 1);
        reopened.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile switch cancels old reading and rejects late recognition',
      (tester) async {
    final speech = _Speech();
    final app = await _mount(tester, speech);
    await _tap(tester, find.byIcon(Icons.mic_rounded));
    final stale = speech.result!;
    await tester.runAsync(() async {
      await app.school.setActiveStudent('reader-b');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    expect(find.text('Reading Buddy'), findsOneWidget);
    await _tap(tester, find.text('Mama und Tom'));
    stale(ReadingTextLibrary.all.first.lines.join(' '));
    speech.notifyListeners();
    await _frames(tester);
    expect(find.text('Was backt Mama?'), findsNothing);
    expect(_record(app), isNull);
    expect(app.learningDailyDone(), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sentence coach treats confident mismatches as hints, never negative evidence',
      (tester) async {
    final speech = _Speech();
    final app = await _mount(tester, _Speech());
    LumoVoice.instance.isEnabled = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ReadingContent(
                appState: app, onBack: () {}, speechListener: speech))));
    await _frames(tester);
    final sentence = LumoCompanionRequests.instance.taskContext.value!.prompt;
    final words = sentence.split(RegExp(r'\s+'));
    expect(words.length, greaterThanOrEqualTo(3));
    for (var index = 1; index <= (words.length / 2).floor(); index++) {
      words[index] = index.isEven ? 'Zitrone' : 'Rakete';
    }
    final mismatch = words.join(' ');
    final analysis = const ReadingV2PronunciationAnalyzer()
        .analyze(expectedSentence: sentence, spokenTranscript: mismatch);
    expect(analysis.correctEnough, isFalse,
        reason:
            'Exercise must reach the former confidently-wrong assessment branch.');
    expect(analysis.alignmentScore, greaterThanOrEqualTo(.28));
    expect(analysis.problemWord, isNotNull);
    final id = SkillRecord.makeId('Lesen', 'Sätze vorlesen');
    for (var attempt = 0; attempt < 2; attempt++) {
      await _tap(tester, find.byIcon(Icons.mic_rounded));
      speech.finish(mismatch);
      await _frames(tester);
      expect(app.learningSkills()[id], isNull);
      expect(app.learningDailyDone(), 0);
    }
    await _tap(tester, find.byIcon(Icons.mic_rounded));
    speech.finish(sentence);
    await _frames(tester);
    expect(app.learningSkills()[id]!.correct, 1);
    expect(app.learningSkills()[id]!.wrong, 0);
    expect(tester.takeException(), isNull);
  });
}
