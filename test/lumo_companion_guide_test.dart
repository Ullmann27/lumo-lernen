import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_companion_guide.dart';

void main() {
  final start = DateTime(2026, 10, 2);
  test('two wrong attempts allow a calm in-place offer during an active task',
      () {
    final guide = LumoCompanionGuide(now: start);
    const scene = LumoCompanionScene(
        section: 'learn',
        hasTask: true,
        taskInProgress: true,
        consecutiveWrong: 2,
        taskId: 'task-a');
    expect(
        guide.maybeSuggest(scene, now: start.add(const Duration(seconds: 14))),
        isNull);
    final offer =
        guide.maybeSuggest(scene, now: start.add(const Duration(seconds: 16)));
    expect(offer, isNotNull);
    expect(offer!.action, LumoCompanionAction.explainTask);
    expect(offer.acceptLabel, 'Zeig mir wie');
    expect(
        guide.maybeSuggest(scene, now: start.add(const Duration(minutes: 3))),
        isNull);
  });
  test('error help still respects exams, hidden routes and dismissal', () {
    const active = LumoCompanionScene(
        hasTask: true, taskInProgress: true, consecutiveWrong: 2);
    final guide = LumoCompanionGuide(now: start);
    expect(
        guide.maybeSuggest(active,
            routeVisible: false, now: start.add(const Duration(seconds: 16))),
        isNull);
    expect(
        guide.maybeSuggest(
            const LumoCompanionScene(
                hasTask: true,
                taskInProgress: true,
                consecutiveWrong: 2,
                schoolwork: true),
            now: start.add(const Duration(seconds: 16))),
        isNull);
    guide.dismiss(start);
    expect(
        guide.maybeSuggest(active, now: start.add(const Duration(minutes: 9))),
        isNull);
  });
  test('proactive help is bound to the current task and never a finished task',
      () {
    final guide = LumoCompanionGuide(now: start);
    const a = LumoCompanionScene(
        taskId: 'a',
        profileGeneration: 3,
        hasTask: true,
        taskInProgress: true,
        consecutiveWrong: 2);
    final offer =
        guide.maybeSuggest(a, now: start.add(const Duration(seconds: 16)));
    expect(offer!.taskId, 'a');
    expect(offer.profileGeneration, 3);
    expect(
        guide.maybeSuggest(
            const LumoCompanionScene(
                taskId: 'b',
                profileGeneration: 3,
                hasTask: true,
                taskInProgress: true,
                consecutiveWrong: 2),
            now: start.add(const Duration(seconds: 50))),
        isNull);
    expect(
        guide.maybeSuggest(
            const LumoCompanionScene(
                taskId: 'b',
                profileGeneration: 3,
                hasTask: true,
                taskInProgress: true,
                consecutiveWrong: 2),
            now: start.add(const Duration(seconds: 110))),
        isNotNull);
    expect(
        guide.maybeSuggest(
            const LumoCompanionScene(
                taskId: 'done', hasTask: true, consecutiveWrong: 2),
            now: start.add(const Duration(minutes: 4))),
        isNull);
  });
  test(
      'initiative waits for a quiet moment and never interrupts tasks or exams',
      () {
    final guide = LumoCompanionGuide(now: start);
    const scene = LumoCompanionScene(recommendedUnit: 'Zehnerübergang');
    expect(
        guide.maybeSuggest(scene, now: start.add(const Duration(seconds: 10))),
        isNull);
    expect(
        guide.maybeSuggest(const LumoCompanionScene(taskInProgress: true),
            now: start.add(const Duration(seconds: 20))),
        isNull);
    expect(
        guide.maybeSuggest(const LumoCompanionScene(schoolwork: true),
            now: start.add(const Duration(seconds: 20))),
        isNull);
    expect(
        guide.maybeSuggest(scene,
            now: start.add(const Duration(seconds: 20)), routeVisible: false),
        isNull);
    final idea =
        guide.maybeSuggest(scene, now: start.add(const Duration(seconds: 20)));
    expect(idea!.text, contains('Zehnerübergang'));
    expect(idea.action, LumoCompanionAction.suggestTask);
  });
  test('dismissal snoozes new topics and cooldown prevents repeated proposals',
      () {
    final guide = LumoCompanionGuide(now: start);
    const a = LumoCompanionScene(recommendedUnit: 'Plus');
    const b = LumoCompanionScene(recommendedUnit: 'Silben');
    expect(guide.maybeSuggest(a, now: start.add(const Duration(seconds: 20))),
        isNotNull);
    expect(guide.maybeSuggest(b, now: start.add(const Duration(seconds: 30))),
        isNull);
    guide.dismiss(start.add(const Duration(seconds: 30)));
    expect(guide.maybeSuggest(b, now: start.add(const Duration(minutes: 9))),
        isNull);
    expect(guide.maybeSuggest(b, now: start.add(const Duration(minutes: 11))),
        isNotNull);
    expect(guide.maybeSuggest(a, now: start.add(const Duration(minutes: 13))),
        isNull);
  });
  test('errors offer an in-place explanation and new progress a break', () {
    final guide = LumoCompanionGuide(now: start);
    guide.maybeSuggest(const LumoCompanionScene(solvedTasks: 40), now: start);
    expect(
        guide
            .choose(
                const LumoCompanionScene(hasTask: true, consecutiveWrong: 2))
            .action,
        LumoCompanionAction.explainTask);
    expect(guide.choose(const LumoCompanionScene(solvedTasks: 45)).action,
        LumoCompanionAction.takeBreak);
    expect(guide.choose(const LumoCompanionScene(solvedTasks: 42)).action,
        LumoCompanionAction.suggestTask);
  });
}
