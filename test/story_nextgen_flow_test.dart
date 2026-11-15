import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/core/lumo_story_summary_scoring.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import 'helpers/lumo_capture.dart';

class _Speech extends LumoSpeechListener {
  ValueChanged<String>? partial;
  ValueChanged<String>? finalResult;
  VoidCallback? noMatch;
  bool active = false;
  int starts = 0;
  @override
  bool get listening => active;
  @override
  bool get available => true;
  @override
  bool get initialized => true;
  @override
  Future<void> startListening({
    ValueChanged<String>? onResult,
    ValueChanged<String>? onFinalResult,
    VoidCallback? onNoMatch,
  }) async {
    starts++;
    active = true;
    partial = onResult;
    finalResult = onFinalResult;
    noMatch = onNoMatch;
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

class _StoryState extends LumoAppState {
  _StoryState() : super(walletRepository: RewardWalletRepository());
  Completer<void>? pendingFlush;
  int generation = 0;
  @override
  int get profileGeneration => generation;
  void changeProfile() {
    generation++;
    notifyListeners();
  }

  @override
  Future<void> ensureSettingsLoaded() async {}
  @override
  Future<void> flushRewards() => pendingFlush?.future ?? super.flushRewards();
}

const _summaryStory = LumoStory(
  title: 'Lumo und das Buch',
  heroName: 'Lumo',
  location: 'Wald',
  theme: 'Lesen',
  gradeLevel: 2,
  newWords: [],
  pages: [
    LumoStoryPage(
        pageNum: 1, text: 'Lumo findet ein Buch im Wald.', imagePrompt: '')
  ],
  keyPoints: ['Lumo', 'Buch', 'Wald'],
);

const _mathStory = LumoStory(
  title: 'Lumos Äpfel',
  heroName: 'Lumo',
  location: 'Garten',
  theme: 'Teilen',
  gradeLevel: 1,
  newWords: [],
  pages: [
    LumoStoryPage(
        pageNum: 1,
        text: 'Lumo hat zwei und drei Äpfel.',
        imagePrompt: '',
        exercise: StoryExercise(
            type: StoryExerciseType.mathPlus,
            prompt: '2 + 3 = ?',
            correctAnswer: '5',
            options: ['4', '5', '6'])),
    LumoStoryPage(pageNum: 2, text: 'Lumo teilt die Äpfel.', imagePrompt: ''),
  ],
);

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _frames(tester);
}

Future<_StoryState> _mount(
  WidgetTester tester,
  LumoStory story, {
  _Speech? speech,
  Size size = const Size(412, 1000),
  double textScale = 1,
  bool microphone = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = _StoryState();
  app.state.settings = AppSettings(
      microphoneEnabled: microphone,
      voiceEnabled: false,
      calmMode: true,
      reduceAnimations: true);
  addTearDown(app.dispose);
  if (speech != null) addTearDown(speech.dispose);
  await tester.pumpWidget(RepaintBoundary(
    key: const ValueKey('story-nextgen-capture'),
    child: MaterialApp(
      theme: ThemeData(fontFamily: 'Nunito'),
      home: MediaQuery(
        data: MediaQueryData(
            size: size,
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale)),
        child: LumoStoryReaderScreen(
            story: story, appState: app, speechListener: speech),
      ),
    ),
  ));
  await _frames(tester);
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoCompanionRequests.instance.clearLearningScope();
    final enabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = enabled);
  });

  test('mentions and negated mentions never claim comprehension', () {
    final score = LumoStorySummaryScorer.evaluate(
        summary: 'Lumo war nicht im Wald. Ein Buch gab es auch nicht.',
        keyPoints: const ['Lumo', 'Wald', 'Buch']);
    expect(score.hits, 3);
    expect(score.stars, 5);
    expect(score.assessesComprehension, isFalse);
    expect(score.matchedKeyPoints, ['Lumo', 'Wald', 'Buch']);
    final repeated = LumoStorySummaryScorer.evaluate(
        summary: 'Ein Buch im Wald.',
        keyPoints: const ['Buch', 'buch', '', 'Wald']);
    expect(repeated.keyPointCount, 2);
    expect(repeated.hits, 2);
    expect(
        LumoStorySummaryScorer.evaluate(
            summary: '...', keyPoints: const ['Buch']).stars,
        0);
  });

  testWidgets('five stars describe words, allow revision and reward only once',
      (tester) async {
    final app = await _mount(tester, _summaryStory);
    await _tap(tester, 'lumo-story-continue');
    await tester.enterText(
        find.byKey(const ValueKey('story-summary-text')), 'Lumo Buch Wald');
    await _tap(tester, 'lumo-summary-evaluate');
    expect(app.state.stars, 5);
    expect(find.textContaining('fast komplett'), findsNothing);
    expect(find.textContaining('Ich erkenne 3 von 3 Stichwörtern'),
        findsOneWidget);
    expect(
        LumoCompanionRequests.instance.taskContext.value!.lastCorrect, isNull);
    await _tap(tester, 'lumo-summary-revise');
    await tester.enterText(find.byKey(const ValueKey('story-summary-text')),
        'Lumo hat etwas entdeckt.');
    final callback = tester
        .widget<ElevatedButton>(
            find.byKey(const ValueKey('lumo-summary-evaluate')))
        .onPressed!;
    callback();
    callback();
    await _frames(tester);
    expect(app.state.stars, 5);
    expect(app.state.xp, 50);
    expect(
        find.textContaining('5 Sterne für deinen Rückblick'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'speech preserves a draft and requires explicit transcript approval',
      (tester) async {
    final speech = _Speech();
    final app = await _mount(tester, _summaryStory, speech: speech);
    await _tap(tester, 'lumo-story-continue');
    await tester.enterText(find.byKey(const ValueKey('story-summary-text')),
        'Lumo fand ein Buch.');
    await _tap(tester, 'lumo-summary-speech');
    expect(speech.starts, 1);
    speech.partial?.call('im Walt');
    speech.finish('im Walt');
    await _frames(tester);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('story-summary-text')))
            .controller!
            .text,
        'Lumo fand ein Buch.\nim Walt');
    expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const ValueKey('lumo-summary-evaluate')))
            .onPressed,
        isNull);
    expect(app.state.stars, 0);
    final context = LumoCompanionRequests.instance.taskContext.value!;
    expect(context.lastCorrect, isNull);
    expect(context.attempts, 0);
    expect(context.errorType, 'unconfirmed_transcription');
    await tester.enterText(find.byKey(const ValueKey('story-summary-text')),
        'Lumo fand ein Buch im Wald.');
    await _tap(tester, 'lumo-summary-confirm-transcript');
    await _tap(tester, 'lumo-summary-evaluate');
    expect(app.state.stars, 5);
    speech.finish('verspätetes falsches Ergebnis');
    await _frames(tester);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('story-summary-text')))
            .controller!
            .text,
        'Lumo fand ein Buch im Wald.');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('no-match recognition does not penalize or erase typed words',
      (tester) async {
    final speech = _Speech();
    final app = await _mount(tester, _summaryStory, speech: speech);
    await _tap(tester, 'lumo-story-continue');
    await tester.enterText(find.byKey(const ValueKey('story-summary-text')),
        'Ich erinnere mich an Lumo.');
    await _tap(tester, 'lumo-summary-speech');
    speech.active = false;
    speech.noMatch?.call();
    speech.notifyListeners();
    await _frames(tester);
    expect(
        find.textContaining('kein Fehler in deiner Erzählung'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('story-summary-text')))
            .controller!
            .text,
        'Ich erinnere mich an Lumo.');
    expect(app.state.stars, 0);
    expect(
        LumoCompanionRequests.instance.taskContext.value!.lastCorrect, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disabled microphone leaves the existing written draft usable',
      (tester) async {
    final speech = _Speech();
    final app =
        await _mount(tester, _summaryStory, speech: speech, microphone: false);
    await _tap(tester, 'lumo-story-continue');
    await tester.enterText(
        find.byKey(const ValueKey('story-summary-text')), 'Lumo hat ein Buch.');
    await _tap(tester, 'lumo-summary-speech');
    expect(speech.starts, 0);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('story-summary-text')))
            .controller!
            .text,
        'Lumo hat ein Buch.');
    expect(app.state.stars, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('voice answer proposals need a matching confirmed choice',
      (tester) async {
    final app = await _mount(tester, _mathStory);
    final requests = LumoCompanionRequests.instance;
    final identity = requests.learningIdentity.value!;
    expect(
        requests.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: 'unverständliches Wort'),
        isTrue);
    await _frames(tester);
    await _tap(tester, 'story-confirm-answer-proposal');
    expect(app.state.stars, 0);
    expect(requests.taskContext.value!.lastCorrect, isNull);
    expect(requests.taskContext.value!.attempts, 0);
    await tester.enterText(
        find.byKey(const ValueKey('story-answer-proposal-text')), '5');
    await _tap(tester, 'story-confirm-answer-proposal');
    expect(app.state.stars, 1);
    expect(requests.taskContext.value!.lastCorrect, isTrue);
    expect(requests.taskContext.value!.answering, isFalse);
    expect(
        requests.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: '4'),
        isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(requests.taskContext.value, isNull);
  });

  testWidgets('rapid next taps cannot skip the next learning stop',
      (tester) async {
    final story = LumoStory(
        title: 'Drei Seiten',
        heroName: 'Lumo',
        location: 'Garten',
        theme: 'Lesen',
        gradeLevel: 1,
        newWords: const [],
        pages: [
          const LumoStoryPage(
              pageNum: 1,
              text: 'Hier beginnt die Geschichte.',
              imagePrompt: ''),
          _mathStory.pages.first,
          const LumoStoryPage(
              pageNum: 3,
              text: 'Diese Seite kommt erst später.',
              imagePrompt: ''),
        ]);
    await _mount(tester, story);
    final next = tester
        .widget<ElevatedButton>(
            find.byKey(const ValueKey('lumo-story-continue')))
        .onPressed!;
    next();
    next();
    next();
    await _frames(tester);
    expect(find.text(_mathStory.pages.first.text), findsOneWidget);
    expect(find.text('Diese Seite kommt erst später.'), findsNothing);
    expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const ValueKey('lumo-story-continue')))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('profile change rejects delayed speech and old answer actions',
      (tester) async {
    final speech = _Speech();
    final app = await _mount(tester, _summaryStory, speech: speech);
    await _tap(tester, 'lumo-story-continue');
    await tester.enterText(find.byKey(const ValueKey('story-summary-text')),
        'Meine eigenen Worte.');
    await _tap(tester, 'lumo-summary-speech');
    final oldIdentity = LumoCompanionRequests.instance.learningIdentity.value!;
    app.changeProfile();
    speech.finish('Lumo Buch Wald');
    await _frames(tester);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('story-summary-text')))
            .controller!
            .text,
        'Meine eigenen Worte.');
    expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const ValueKey('lumo-summary-evaluate')))
            .onPressed,
        isNull);
    expect(app.state.stars, 0);
    expect(
        LumoCompanionRequests.instance.requestLearningAction(
            LumoLearningAction.proposeAnswer,
            identity: oldIdentity,
            candidate: 'Lumo'),
        isFalse);
    expect(LumoCompanionRequests.instance.taskContext.value, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('notebook excerpts belong to the actual visited story pages',
      (tester) async {
    const story = LumoStory(
        title: 'Ein anderes Buch',
        heroName: 'Lumo',
        location: 'Garten',
        theme: 'Lesen',
        gradeLevel: 2,
        newWords: [],
        pages: [
          LumoStoryPage(
              pageNum: 1,
              text: 'Lumo findet einen gelben Ball. Er sucht dessen Besitzer.',
              imagePrompt: ''),
          LumoStoryPage(
              pageNum: 2, text: 'Der Ball gehört Mara.', imagePrompt: ''),
        ],
        bookQuestions: [
          StoryBookQuestion('Wem gehört der Ball?', 'Mara', ['Mara', 'Lumo'], 2)
        ]);
    await _mount(tester, story);
    await _tap(tester, 'lumo-story-clue-notebook-toggle');
    final notebook = find.byKey(const ValueKey('lumo-story-clue-notebook'));
    expect(
        find.descendant(
            of: notebook,
            matching: find.text('Lumo findet einen gelben Ball.')),
        findsOneWidget);
    expect(
        find.descendant(
            of: notebook, matching: find.text('Der Ball gehört Mara.')),
        findsNothing);
    expect(find.text('Der erste Brief'), findsNothing);
    expect(LumoCompanionRequests.instance.taskContext.value, isNull);
    await tester.tap(find.byTooltip('Notizbuch schließen'));
    await _frames(tester);
    expect(LumoCompanionRequests.instance.taskContext.value!.prompt,
        contains('gelben Ball'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('completion waits for the wallet and records one completed read',
      (tester) async {
    const story = LumoStory(
        title: 'Ein fertig gelesenes Heft',
        heroName: 'Lumo',
        location: 'Wald',
        theme: 'Lesen',
        gradeLevel: 1,
        newWords: [],
        pages: [
          LumoStoryPage(pageNum: 1, text: 'Lumo kommt an.', imagePrompt: '')
        ]);
    final app = await _mount(tester, story);
    app.pendingFlush = Completer<void>();
    await _tap(tester, 'lumo-story-continue');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsNothing);
    final saved = LumoStoryLibrary.instance.all
        .where((book) => book.story.title == story.title)
        .single;
    expect(saved.timesRead, 0);
    app.pendingFlush!.complete();
    await _frames(tester);
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsOneWidget);
    expect(
        LumoStoryLibrary.instance.all
            .where((book) => book.id == saved.id)
            .single
            .timesRead,
        1);
    expect(
        LumoStoryLibrary.instance.all
            .where((book) => book.story.title == story.title),
        hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opening twice or cancelling never counts as a completed read',
      (tester) async {
    const story = LumoStory(
        title: 'Das Heft zum Wiederlesen',
        heroName: 'Lumo',
        location: 'Wald',
        theme: 'Lesen',
        gradeLevel: 1,
        newWords: [],
        pages: [
          LumoStoryPage(
              pageNum: 1, text: 'Lumo liest noch einmal.', imagePrompt: '')
        ]);
    late final StoredStory saved;
    await tester.runAsync(() async {
      saved = await LumoStoryLibrary.instance.addStory(story);
    });
    final app = _StoryState();
    app.state.settings = const AppSettings(
        calmMode: true, reduceAnimations: true, voiceEnabled: false);
    addTearDown(app.dispose);
    await tester.binding.setSurfaceSize(const Size(412, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: LumoStoryLibraryScreen(appState: app),
    )));
    await _frames(tester);
    await tester.ensureVisible(find.text(story.title));
    final open = tester
        .widget<InkWell>(find
            .ancestor(
                of: find.text(story.title), matching: find.byType(InkWell))
            .first)
        .onTap!;
    // Already queued callbacks must be safe even before the next route frame.
    open();
    open();
    await _frames(tester);
    expect(find.byType(LumoStoryReaderScreen), findsOneWidget);
    expect(
        LumoStoryLibrary.instance.all
            .where((book) => book.id == saved.id)
            .single
            .timesRead,
        0);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await _frames(tester);
    expect(find.byType(LumoStoryReaderScreen), findsNothing);
    expect(
        LumoStoryLibrary.instance.all
            .where((book) => book.id == saved.id)
            .single
            .timesRead,
        0);
    await tester.ensureVisible(find.text(story.title));
    await tester.tap(find.text(story.title));
    await _frames(tester);
    await _tap(tester, 'lumo-story-continue');
    await tester.tap(find.text('Fertig'));
    await _frames(tester);
    expect(find.byType(LumoStoryReaderScreen), findsNothing);
    expect(
        LumoStoryLibrary.instance.all
            .where((book) => book.id == saved.id)
            .single
            .timesRead,
        1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final config in [
    ('phone-320', const Size(320, 800), 1.0),
    ('fold-cover', const Size(344, 882), 1.4),
    ('fold-open', const Size(840, 900), 1.0),
  ]) {
    testWidgets(
        'real generated story fits ${config.$1} with accessible support',
        (tester) async {
      final story = LumoStoryGenerator.instance.generateReadingAdventure(
          hero: 'Drache',
          location: 'Zauberwald',
          theme: 'Freundschaft',
          gradeLevel: 2);
      await _mount(tester, story, size: config.$2, textScale: config.$3);
      expect(find.text(story.pages.first.text), findsOneWidget);
      for (final key in [
        'story-help',
        'story-repeat',
        'story-slower',
        'story-stop'
      ]) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
      final directory = Platform.environment['LUMO_STORY_CAPTURES'];
      if (directory != null) {
        await captureLumoBoundary(
            tester,
            const ValueKey('story-nextgen-capture'),
            '$directory/${config.$1}-reader.png');
      }
      await _tap(tester, 'story-help');
      final requests = LumoCompanionRequests.instance;
      expect(requests.taskContext.value!.isExplanation, isTrue);
      expect(
          requests.taskContext.value!.objectIds, contains('story-page-text'));
      expect(
          requests.learningPresentation.value!.gazeObjectId, 'story-page-text');
      expect(find.byKey(const ValueKey('story-help-text')), findsOneWidget);
      if (directory != null) {
        await captureLumoBoundary(
            tester,
            const ValueKey('story-nextgen-capture'),
            '$directory/${config.$1}-help.png');
      }
      final beforeStop = requests.learningIdentity.value!;
      await _tap(tester, 'story-stop');
      expect(requests.isCurrentLearningIdentity(beforeStop), isFalse);
      expect(find.byKey(const ValueKey('story-help-text')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
