import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_tutor_contracts.dart';
import 'package:lumo_lernen/core/lumo_tutor_engine.dart';

void main() {
  const tutor = LumoTutorEngine();

  LumoTutorRequest request(String prompt, LumoTutorHelpLevel level,
          {String unit = 'Zehner und Einer', bool testMode = false}) =>
      LumoTutorRequest(
        mode: testMode ? LumoTutorMode.testReview : LumoTutorMode.miniLesson,
        subject: LumoTutorSubject.mathematik,
        grade: 2,
        unit: unit,
        helpLevel: level,
        currentPrompt: prompt,
        correctAnswer: '8',
        attemptCount: level.index + 1,
      );

  test('84 receives three genuinely different explanations and an active check', () {
    final prompt = 'Wie viele Zehner stecken in 84?';
    final first = tutor.buildLocalFallback(request(prompt, LumoTutorHelpLevel.hintOnly));
    final second = tutor.buildLocalFallback(request(prompt, LumoTutorHelpLevel.guidedStep));
    final third = tutor.buildLocalFallback(request(prompt, LumoTutorHelpLevel.visualExplanation));
    expect(first.speech, contains('Bündeln zu je zehn'));
    expect(first.speech, isNot(contains('8 volle')));
    expect(second.speech, contains('80 und 4'));
    expect(third.speech, contains('8 Zehnerstangen'));
    expect(third.speech, contains('85'));
    expect({first.speech, second.speech, third.speech}, hasLength(3));
    expect(third.source, 'local_tutor_engine_v1');
  });

  test('a number with zero ones still gives valid full tens', () {
    final answer = tutor.buildLocalFallback(request(
      'Wie viele Zehner stecken in 70?', LumoTutorHelpLevel.visualExplanation,
    ));
    expect(answer.speech, contains('7 Zehnerstangen'));
    expect(answer.speech, contains('0 einzelne Würfel'));
  });

  test('ones question teaches the remainder, not the tens count', () {
    final answer = tutor.buildLocalFallback(request(
      'Wie viele Einer hat 84?', LumoTutorHelpLevel.visualExplanation,
    ));
    expect(answer.speech, contains('4 Würfel'));
    expect(answer.speech, contains('Einer'));
    expect(answer.speech, contains('85'));
  });

  test('larger three-digit place values are not misclassified', () {
    final help = tutor.buildLocalFallback(request(
      'Wie viele Zehner stecken in 184?', LumoTutorHelpLevel.visualExplanation,
    ));
    expect(help.speech, isNot(contains('8 Zehnerstangen')));
    expect(help.speech, isNot(contains('18 Zehnerstangen')));
  });

  test('live test mode never reveals the decomposition or answer', () {
    final response = tutor.buildLocalFallback(request(
      'Wie viele Zehner stecken in 84?', LumoTutorHelpLevel.visualExplanation,
      testMode: true,
    ));
    expect(response.speech, contains('nach dem Test'));
    expect(response.speech, isNot(contains('8 Zehnerstangen')));
  });
}
