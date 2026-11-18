import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math/lumo_rechentricks.dart';
import 'package:lumo_lernen/domain/learning/error_detective.dart';
import 'package:lumo_lernen/features/learning/widgets/rechentricks_mentor_card.dart';

void main() {
  const detective = ErrorDetective();

  ErrorDetection math(String prompt, int correct, int given) =>
      detective.analyze(
        subject: 'Mathematik',
        prompt: prompt,
        correctAnswer: '$correct',
        givenAnswer: '$given',
      );

  group('plus/minus mix-up', () {
    test('is named only when the answer is the opposite operation', () {
      final swapped = math('8 + 3 = ?', 11, 5);
      expect(swapped.pattern, ErrorPattern.plusMinusSwap);
      expect(swapped.isRecognised, isTrue);
      expect(swapped.childFriendlyMessage,
          'Ich glaube, du hast Plus und Minus verwechselt. '
          'Plus heißt: Es kommt etwas dazu.');

      final minus = math('9 − 4 = ?', 5, 13);
      expect(minus.pattern, ErrorPattern.plusMinusSwap);
      expect(minus.childFriendlyMessage, contains('Minus heißt'));
    });

    test('any other wrong plus or minus answer is not a sign mix-up', () {
      for (final given in [4, 7, 9, 12, 14, 20]) {
        final detection = math('8 + 3 = ?', 11, given);
        expect(detection.pattern, isNot(ErrorPattern.plusMinusSwap),
            reason: 'given $given');
      }
      expect(math('8 + 3 = ?', 11, 20).isRecognised, isFalse);
    });
  });

  test('messages are correct German and never start a lottery', () {
    final messages = <String>[
      math('4 + 3 = ?', 7, 8).childFriendlyMessage,
      math('4 + 3 = ?', 7, 9).childFriendlyMessage,
      math('34 + 12 = ?', 46, 64).childFriendlyMessage,
      math('34 + 12 = ?', 46, 56).childFriendlyMessage,
      math('7 × 8 = ?', 56, 54).childFriendlyMessage,
      detective
          .analyze(
              subject: 'Deutsch',
              prompt: 'Welcher Artikel passt? ___ Hund',
              correctAnswer: 'der',
              givenAnswer: 'das')
          .childFriendlyMessage,
      detective
          .analyze(
              subject: 'Deutsch',
              prompt: 'Was reimt sich auf Haus?',
              correctAnswer: 'Maus',
              givenAnswer: 'Hand')
          .childFriendlyMessage,
    ];
    for (final message in messages) {
      expect(message, isNot(matches(RegExp(r'ae|oe|ue(?!r)|heisst'))),
          reason: message);
      expect(message.toLowerCase(), isNot(contains('fast')), reason: message);
      expect(message.toLowerCase(), isNot(contains('leider')),
          reason: message);
    }
    expect(math('4 + 3 = ?', 7, 8).childFriendlyMessage,
        'Du warst nur um 1 daneben. Zähl noch einmal genau nach.');
  });

  test('a small distance in a times table is not called a counting error',
      () {
    final detection = math('7 × 8 = ?', 56, 54);
    expect(detection.pattern, ErrorPattern.unknown);
    expect(detection.isRecognised, isFalse);
  });

  test('a long right answer alone is not a word-order error', () {
    final reading = detective.analyze(
      subject: 'Lesen',
      prompt: 'Wo wohnt der Fuchs?',
      correctAnswer: 'im Wald hinter dem Haus',
      givenAnswer: 'am See',
    );
    expect(reading.pattern, isNot(ErrorPattern.sentenceStructureError));

    final order = detective.analyze(
      subject: 'Deutsch',
      prompt: 'Baue den Satz.',
      correctAnswer: 'Der Hund läuft schnell',
      givenAnswer: 'Läuft der Hund schnell',
    );
    expect(order.pattern, ErrorPattern.sentenceStructureError);
  });

  group('Rechentricks while the child is still solving', () {
    const tricks = LumoRechentricks();

    void expectHidden(String prompt, int answer, {int grade = 1}) {
      final shown = tricks.explain(
          prompt: prompt,
          correctAnswer: '$answer',
          grade: grade,
          revealResult: false);
      expect(shown, isNotNull, reason: prompt);
      expect(shown!.resultHidden, isTrue);
      final visible = [...shown.steps, shown.resultText].join(' | ');
      expect(visible, isNot(matches(RegExp('(?<![0-9])$answer(?![0-9])'))),
          reason: '$prompt -> $visible');
      expect(shown.steps, isNotEmpty, reason: 'the strategy stays visible');
    }

    test('no trick shows the final number', () {
      expectHidden('8 + 7 = ?', 15); // bridge the ten
      expectHidden('3 + 9 = ?', 12); // swap
      expectHidden('14 + 5 = ?', 19); // small task first
      expectHidden('9 - 4 = ?', 5); // inverse check
      expectHidden('7 × 8 = ?', 56, grade: 3); // five-trick
      expectHidden('4 × 6 = ?', 24, grade: 3); // doubling
      expectHidden('234 + 382 = ?', 616, grade: 3);
      expectHidden('540 - 230 = ?', 310, grade: 3);
    });

    test('the strategy stops before the last step', () {
      final shown = tricks.explain(
          prompt: '8 + 7 = ?',
          correctAnswer: '15',
          grade: 1,
          revealResult: false)!;
      expect(shown.steps, ['8 + 2 = 10', '10 + 5 = ?']);
      expect(shown.resultText, 'Den letzten Schritt schaffst du selbst.');
    });

    test('the poster keeps its complete worked examples', () {
      final worked =
          tricks.explain(prompt: '8 + 7 = ?', correctAnswer: '15', grade: 1)!;
      expect(worked.resultHidden, isFalse);
      expect(worked.steps.last, '10 + 5 = 15');
    });

    testWidgets('the mentor card shows no result and fits a narrow phone',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final shown = tricks.explain(
          prompt: '8 + 7 = ?',
          correctAnswer: '15',
          grade: 1,
          revealResult: false)!;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
              size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: SingleChildScrollView(
                child: RechentricksMentorCard(explanation: shown)),
          ),
        ),
      ));
      expect(find.textContaining('15'), findsNothing);
      expect(find.text('Den letzten Schritt schaffst du selbst.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
