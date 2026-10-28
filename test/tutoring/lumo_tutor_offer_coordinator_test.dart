import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_tutor_offer_coordinator.dart';

void main() {
  test('Lumo offers only after two mistakes in same task', () {
    final tutor = LumoTutorOfferCoordinator();
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
        correct: false, canOfferHelp: true), isFalse);
    expect(tutor.mistakesInTask, 1);
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
        correct: false, canOfferHelp: true), isTrue);
    expect(tutor.shouldOffer, isTrue);
  });

  test('accepted or declined invitation cannot nag again for this task', () {
    final tutor = LumoTutorOfferCoordinator();
    for (var i = 0; i < 2; i++) {
      tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
          correct: false, canOfferHelp: true);
    }
    tutor.decline();
    expect(tutor.shouldOffer, isFalse);
    for (var i = 0; i < 5; i++) {
      expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
          correct: false, canOfferHelp: true), isFalse);
    }
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-85',
        correct: false, canOfferHelp: true), isFalse);
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-85',
        correct: false, canOfferHelp: true), isTrue);
    tutor.accept();
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-85',
        correct: false, canOfferHelp: true), isFalse);
  });

  test('child profiles and task IDs never share unfinished invitations', () {
    final tutor = LumoTutorOfferCoordinator();
    for (var i = 0; i < 2; i++) {
      tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
          correct: false, canOfferHelp: true);
    }
    expect(tutor.shouldOffer, isTrue);
    expect(tutor.recordAnswer(childId: 'kind-b', taskId: 'math-84',
        correct: false, canOfferHelp: true), isFalse);
    expect(tutor.mistakesInTask, 1);
    expect(tutor.recordAnswer(childId: 'kind-b', taskId: 'math-84',
        correct: false, canOfferHelp: true), isTrue);
    expect(tutor.recordAnswer(childId: 'kind-b', taskId: 'math-85',
        correct: false, canOfferHelp: true), isFalse);
  });

  test('tests, schoolwork and correct answers never invite unsolicited help', () {
    final tutor = LumoTutorOfferCoordinator();
    for (var i = 0; i < 6; i++) {
      expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'exam-1',
          correct: false, canOfferHelp: false), isFalse);
    }
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
        correct: false, canOfferHelp: true), isFalse);
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
        correct: true, canOfferHelp: true), isFalse);
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: 'math-84',
        correct: false, canOfferHelp: true), isFalse);
  });

  test('missing child or task cannot produce a cross-profile offer', () {
    final tutor = LumoTutorOfferCoordinator();
    expect(tutor.recordAnswer(childId: '', taskId: 'math-84',
        correct: false, canOfferHelp: true), isFalse);
    expect(tutor.recordAnswer(childId: 'kind-a', taskId: '',
        correct: false, canOfferHelp: true), isFalse);
    expect(tutor.shouldOffer, isFalse);
  });
}
