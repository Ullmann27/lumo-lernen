import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';
import 'package:lumo_lernen/features/lumo3d/native_method_table_transport.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_repository.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_round.dart';
import 'package:lumo_lernen/features/quiz/quiz_table_session.dart';

const _tableChannel = MethodChannel('lumo_lernen/table_games');
const _launchChannel = MethodChannel('lumo_lernen/bridge');
const _seed = 17;

// Platform boundary only. All round decisions, persistence and UI below use
// production Dart classes. This is not an Android IPC or device execution.
class _Mailbox {
  final states = <String, Map<String, dynamic>>{};
  final opened = <String>[];
  final closed = <String>[];
  Map<String, dynamic>? request;
  bool loseNextOpenReply = false;
  Completer<String>? holdPoll;
  Completer<void>? pollEntered;

  Future<Object?> handle(MethodCall call) async {
    final arguments = Map<String, dynamic>.from(call.arguments as Map);
    final token = arguments['token'] as String;
    switch (call.method) {
      case 'open':
        if (states.isNotEmpty) {
          throw PlatformException(code: 'another_table_session_is_open');
        }
        states[token] =
            jsonDecode(arguments['state'] as String) as Map<String, dynamic>;
        opened.add(token);
        if (loseNextOpenReply) {
          loseNextOpenReply = false;
          throw PlatformException(code: 'accepted_open_reply_lost');
        }
        return true;
      case 'publish':
        states[token] =
            jsonDecode(arguments['state'] as String) as Map<String, dynamic>;
        final sequence = request?['sequence'];
        if (sequence is int &&
            ((states[token]!['ack'] as int) >= sequence ||
                (states[token]!['rejected'] as int) >= sequence)) {
          request = null;
        }
        return true;
      case 'poll':
        if (holdPoll != null) {
          if (pollEntered != null && !pollEntered!.isCompleted) {
            pollEntered!.complete();
          }
          return holdPoll!.future;
        }
        return jsonEncode({
          'lifecycle': {
            'active': true,
            'pauseEpoch': 0,
            'stamp': DateTime.now().millisecondsSinceEpoch,
          },
          'request': request,
        });
      case 'close':
        states.remove(token);
        closed.add(token);
        return true;
      default:
        throw MissingPluginException(call.method);
    }
  }
}

Future<QuizRoundController> _controller(bool Function() current) async {
  final owner = sha256.convert(utf8.encode('quiz-channel-contract')).toString();
  final controller = await QuizRoundController.open(
    owner: owner,
    grade: 1,
    store: QuizRoundRepository(),
    canUseProfile: current,
    seed: _seed,
    makeQuestions: (subject, seed) =>
        const QuizQuestionBank().generateGameQuestions(
          grade: 1,
          random: math.Random(seed),
          preferSubject: subject == 'alle' ? null : subject,
        ),
    award: (_, __) async => fail('An unanswered quiz cannot award a reward.'),
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _until(WidgetTester tester, bool Function() predicate) async {
  for (var step = 0; step < 150; step++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (predicate()) return;
  }
  fail('Quiz did not reach the required state within 150 × 20 ms.');
}

Finder _nativeButton() => find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == '3D-Quizstudio öffnen',
);

Future<LumoAppState> _mountQuiz(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(720, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  addTearDown(app.dispose);
  await app.school.setActiveStudent('quiz-native-child');
  await app.ensureSettingsLoaded();
  app.updateSettings(
    app.state.settings.copyWith(
      soundEnabled: false,
      voiceEnabled: false,
      reduceAnimations: true,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: QuizShowContent(appState: app, previewQuestionSeed: _seed),
    ),
  );
  return app;
}

Future<Map<String, dynamic>> _savedRound(LumoAppState app) async {
  final lease = await app.captureLearningProfile();
  final owner = sha256.convert(utf8.encode(lease.studentId)).toString();
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(QuizRoundRepository.key(owner));
  expect(raw, isNotNull);
  return jsonDecode(raw!) as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _Mailbox mailbox;
  final launchCalls = <MethodCall>[];
  final returns = <Completer<Map<String, Object?>>>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_reward_wallet_v1': jsonEncode(const RewardWallet().toJson()),
      'lumo_3d_save_salt_v1': 'quiz-roundtrip-regression-salt',
    });
    mailbox = _Mailbox();
    launchCalls.clear();
    returns.clear();
    messenger.setMockMethodCallHandler(_tableChannel, mailbox.handle);
    messenger.setMockMethodCallHandler(_launchChannel, (call) {
      if (call.method != 'launch3D') throw MissingPluginException(call.method);
      launchCalls.add(call);
      final result = Completer<Map<String, Object?>>();
      returns.add(result);
      return result.future;
    });
  });
  tearDown(() {
    for (final result in returns) {
      if (!result.isCompleted) result.complete({'destination': 'games'});
    }
    final poll = mailbox.holdPoll;
    if (poll != null && !poll.isCompleted) poll.complete('{}');
    messenger.setMockMethodCallHandler(_tableChannel, null);
    messenger.setMockMethodCallHandler(_launchChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'A partially accepted Open is closed using its actual MethodChannel token',
    () async {
      final controller = await _controller(() => true);
      final session = QuizTableSession(
        controller: controller,
        transport: const NativeMethodTableTransport(),
      );
      mailbox.loseNextOpenReply = true;
      await expectLater(
        session.open(automaticPolling: false),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'original error',
            'accepted_open_reply_lost',
          ),
        ),
      );
      expect(session.isOpen, isFalse);
      expect(mailbox.opened, [session.token]);
      expect(mailbox.closed, [session.token]);
      expect(mailbox.states, isEmpty);
      final next = QuizTableSession(
        controller: controller,
        transport: const NativeMethodTableTransport(),
      );
      await next.open(automaticPolling: false);
      expect(next.isOpen, isTrue);
      expect(next.token, isNot(session.token));
      await next.close();
      expect(mailbox.states, isEmpty);
    },
  );

  test(
    'A profile lost while polling cannot apply the queued old quiz answer',
    () async {
      var current = true;
      final controller = await _controller(() => current);
      final session = QuizTableSession(
        controller: controller,
        transport: const NativeMethodTableTransport(),
      );
      await session.open(automaticPolling: false);
      mailbox.holdPoll = Completer<String>();
      mailbox.pollEntered = Completer<void>();
      final pumping = session.pump();
      await mailbox.pollEntered!.future.timeout(const Duration(seconds: 2));
      current = false;
      mailbox.holdPoll!.complete(
        jsonEncode({
          'lifecycle': {
            'active': true,
            'pauseEpoch': 0,
            'stamp': DateTime.now().millisecondsSinceEpoch,
          },
          'request': {
            'token': session.token,
            'roundId': controller.round.id,
            'revision': session.view['revision'],
            'sequence': 1,
            'action': 'select',
            'option': 2,
          },
        }),
      );
      await pumping;
      expect(session.isOpen, isFalse);
      expect(mailbox.closed, [session.token]);
      expect(controller.round.actions, isEmpty);
      expect(controller.state.selectedOption, isNull);
      final prefs = await SharedPreferences.getInstance();
      final saved = QuizRound.decode(
        prefs.getString(QuizRoundRepository.key(controller.round.owner))!,
        controller.round.owner,
      );
      expect(saved.actions, isEmpty);
      expect(mailbox.states, isEmpty);
    },
  );

  testWidgets(
    'Native selection, Flutter return and reopen keep one saved round',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final app = await _mountQuiz(tester);
        await _until(tester, () => launchCalls.length == 1);
        final token = mailbox.opened.single;
        final initial = Map<String, dynamic>.from(mailbox.states[token]!);
        final arguments = Map<String, Object?>.from(
          launchCalls.single.arguments as Map,
        );
        expect(arguments['scene'], 'quiz');
        expect(arguments['tableToken'], token);
        expect(initial['correctIndex'], isNull);
        expect(initial['explanation'], isNull);
        final savedBefore = await _savedRound(app);
        expect(savedBefore['id'], initial['roundId']);

        final latest = mailbox.states[token]!;
        mailbox.request = {
          'token': token,
          'roundId': latest['roundId'],
          'revision': latest['revision'],
          'sequence': 1,
          'action': 'select',
          'option': 2,
        };
        await _until(tester, () => mailbox.states[token]?['ack'] == 1);
        expect(mailbox.states[token]!['selected'], 2);
        expect(mailbox.states[token]!['revealed'], isFalse);
        final savedSelected = await _savedRound(app);
        expect(savedSelected['id'], savedBefore['id']);
        expect(savedSelected['questions'], savedBefore['questions']);
        expect(savedSelected['actions'], [
          {'action': 'select', 'option': 2},
        ]);
        expect(app.state.stars, 0);

        returns.single.complete({'destination': 'games'});
        await _until(
          tester,
          () =>
              mailbox.closed.contains(token) &&
              _nativeButton().evaluate().length == 1 &&
              tester.widget<IconButton>(_nativeButton()).onPressed != null,
        );
        expect(
          find.byKey(const ValueKey('lumo-meister-answer-2')),
          findsOneWidget,
        );
        expect(find.text('Frage 1 / 20'), findsOneWidget);
        expect(await _savedRound(app), savedSelected);

        await tester.tap(_nativeButton());
        await _until(tester, () => launchCalls.length == 2);
        final secondToken = mailbox.opened.last;
        expect(secondToken, isNot(token));
        expect(mailbox.states[secondToken]!['roundId'], initial['roundId']);
        expect(mailbox.states[secondToken]!['selected'], 2);
        expect(await _savedRound(app), savedSelected);
        returns.last.complete({'destination': 'games'});
        await _until(tester, () => mailbox.closed.contains(secondToken));
        expect(app.state.stars, 0);
        expect(tester.takeException(), isNull);
      } finally {
        for (final result in returns) {
          if (!result.isCompleted) result.complete({'destination': 'games'});
        }
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        debugDefaultTargetPlatformOverride = null;
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'App pause cancels the Flutter answer lock without resolving it',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final app = await _mountQuiz(tester);
        await _until(
          tester,
          () => find
              .byKey(const ValueKey('lumo-meister-answer-0'))
              .evaluate()
              .isNotEmpty,
        );
        final answer = find.byKey(const ValueKey('lumo-meister-answer-0'));
        await tester.ensureVisible(answer);
        await tester.tap(answer);
        await tester.pump();
        final confirm = find.text('Antwort einloggen');
        await tester.ensureVisible(confirm);
        await tester.pump();
        await tester.tap(confirm);
        await tester.pump();
        expect(find.text('Lumo prüft deine Antwort …'), findsOneWidget);
        final beforePause = await _savedRound(app);
        expect(beforePause['actions'], [
          {'action': 'select', 'option': 0},
        ]);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Lumo prüft deine Antwort …'), findsNothing);
        expect(find.text('Nächste Frage'), findsNothing);
        expect(find.text('Neue Quizrunde starten'), findsNothing);
        expect(await _savedRound(app), beforePause);
        expect(app.state.stars, 0);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(find.text('Antwort einloggen'), findsOneWidget);
        expect(await _savedRound(app), beforePause);
        expect(mailbox.opened, isEmpty);
        expect(launchCalls, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
