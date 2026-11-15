import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;

  void publish({Set<LumoLearningAction>? actions, bool exam = true}) {
    bus.taskContext.value = LumoCompanionTaskContext(
      taskId: 'assessment-visible-instruction',
      subject: 'Logik',
      unit: 'Muster',
      prompt: 'Welche Form kommt als Nächstes?',
      isExam: exam,
      allowedActions: actions,
      objectIds: const ['visible_instruction'],
    );
  }

  bool request(LumoLearningAction action) => bus.requestLearningAction(
        action,
        identity: bus.learningIdentity.value!,
        objectId: action == LumoLearningAction.look ||
                action == LumoLearningAction.point ||
                action == LumoLearningAction.highlight
            ? 'visible_instruction'
            : null,
        candidate: action == LumoLearningAction.proposeAnswer ? 'Kreis' : null,
      );

  setUp(bus.clearLearningScope);
  tearDown(bus.clearLearningScope);

  test('assessment defaults do not authorize instruction reading', () {
    publish();
    expect(request(LumoLearningAction.repeat), isFalse);
    expect(request(LumoLearningAction.slower), isFalse);
    expect(bus.learningAction.value, isNull);
  });

  test('assessment reads only the explicitly permitted instruction action', () {
    publish(actions: const {LumoLearningAction.repeat});
    expect(request(LumoLearningAction.repeat), isTrue);
    expect(bus.learningAction.value!.action, LumoLearningAction.repeat);
    expect(request(LumoLearningAction.slower), isFalse);
  });

  test('assessment may explicitly allow slower instruction reading', () {
    publish(actions: const {LumoLearningAction.slower});
    expect(request(LumoLearningAction.slower), isTrue);
    expect(bus.learningAction.value!.candidate, isNull);
  });

  test('even an overbroad assessment allowlist cannot permit content help', () {
    publish(actions: LumoLearningAction.values.toSet());
    for (final action in const [
      LumoLearningAction.explain,
      LumoLearningAction.hint,
      LumoLearningAction.highlight,
      LumoLearningAction.point,
      LumoLearningAction.look,
      LumoLearningAction.proposeAnswer,
    ]) {
      expect(request(action), isFalse, reason: action.name);
    }
    expect(bus.learningAction.value, isNull);
  });

  test('stop invalidates a delayed assessment reading request', () {
    publish(actions: const {LumoLearningAction.repeat});
    final old = bus.learningIdentity.value!;
    expect(request(LumoLearningAction.stop), isTrue);
    expect(
      bus.requestLearningAction(LumoLearningAction.repeat, identity: old),
      isFalse,
    );
    expect(bus.learningAction.value!.action, LumoLearningAction.stop);
  });

  test('explicit reading consent changes the semantic identity', () {
    publish();
    final old = bus.learningIdentity.value!;
    publish(actions: lumoDefaultLearningActions);
    expect(bus.learningIdentity.value!.matches(old), isFalse);
    expect(
      bus.requestLearningAction(LumoLearningAction.repeat, identity: old),
      isFalse,
    );
    expect(request(LumoLearningAction.repeat), isTrue);
  });

  test('ordinary lessons retain their existing default actions', () {
    publish(exam: false);
    expect(request(LumoLearningAction.repeat), isTrue);
    expect(request(LumoLearningAction.hint), isTrue);
  });
}
