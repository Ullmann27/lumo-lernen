import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clock/clock.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/lumo_companion_host.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void _timedTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(
      name, (tester) => withClock(tester.binding.clock, () => body(tester)));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(() => LumoCompanionRequests.instance.clearLearningScope());

  testWidgets(
      'an invisible inline helper closes without creating a late ticker',
      (tester) async {
    final state = LumoAppState();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LumoCompanionHost(
                appState: state, onSection: (_) {}, offerOnly: true))));
    expect(find.byKey(const ValueKey('lumo-inline-help-accept')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  Future<void> mount(WidgetTester tester, LumoAppState state,
      ValueChanged<LumoSection> onSection) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    state.updateSettings(const AppSettings(
      voiceEnabled: false,
      autoReadEnabled: false,
      microphoneEnabled: false,
      reduceAnimations: true,
    ));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      const Expanded(child: Center(child: Text('Aktuelle Aufgabe'))),
      LumoCompanionHost(appState: state, onSection: onSection),
    ]))));
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester, LumoAppState state) async {
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.binding.setSurfaceSize(null);
  }

  _timedTest('automatic error help needs acceptance and never leaves the task',
      (tester) async {
    final state = LumoAppState();
    state.setSection(LumoSection.learn);
    final requests = LumoCompanionRequests.instance;
    requests.publishTask(LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      prompt: '4 + 3 = ?',
      taskId: 'active-error-task',
      ownerSection: 'learn',
      profileGeneration: state.profileGeneration,
      attempts: 2,
      lastCorrect: false,
    ));
    final sections = <LumoSection>[];
    final before = requests.helpRequested.value;
    await mount(tester, state, sections.add);
    await tester.pump(const Duration(seconds: 18));
    expect(
        find.text(
            'Sollen wir die Aufgabe gemeinsam in kleine Schritte teilen?'),
        findsOneWidget);
    expect(requests.helpRequested.value, before);
    expect(sections, isEmpty);
    await tester.tap(find.byKey(const ValueKey('lumo-fox-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zeig mir wie'));
    await tester.pumpAndSettle();
    expect(requests.helpRequested.value, before + 1);
    expect(requests.taskContext.value!.taskId, 'active-error-task');
    expect(sections, isEmpty);
    await unmount(tester, state);
  });

  testWidgets('accepting the fox idea starts the concrete recommended topic',
      (tester) async {
    final state = LumoAppState();
    final sections = <LumoSection>[];
    await mount(tester, state, sections.add);
    await tester.tap(find.text('Idee'));
    await tester.pumpAndSettle();
    expect(sections, isEmpty);
    expect(state.state.subject, 'Alle');
    await tester.tap(find.text('Übung starten'));
    await tester.pumpAndSettle();
    expect(sections, [LumoSection.exercises]);
    expect(state.state.subject, 'Mathematik');
    expect(state.state.unit, 'Plus bis 10');
    expect(state.state.sessionKind, LumoSessionKind.quickPractice);
    expect(tester.takeException(), isNull);
    await unmount(tester, state);
  });

  _timedTest('a stale help menu cannot act on the next task', (tester) async {
    final state = LumoAppState();
    state.setSection(LumoSection.learn);
    final requests = LumoCompanionRequests.instance;
    LumoCompanionTaskContext task(String id) => LumoCompanionTaskContext(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        prompt: '4 + 3 = ?',
        taskId: id,
        ownerSection: 'learn',
        profileGeneration: state.profileGeneration,
        attempts: 2,
        lastCorrect: false);
    requests.publishTask(task('a'));
    final before = requests.helpRequested.value;
    await mount(tester, state, (_) {});
    await tester.pump(const Duration(seconds: 18));
    await tester.tap(find.byKey(const ValueKey('lumo-fox-button')));
    await tester.pumpAndSettle();
    expect(find.text('Zeig mir wie'), findsOneWidget);
    requests.publishTask(task('b'));
    await tester.pumpAndSettle();
    expect(find.text('Zeig mir wie'), findsNothing);
    expect(requests.helpRequested.value, before);
    expect(requests.taskContext.value!.taskId, 'b');
    await unmount(tester, state);
  });

  _timedTest(
      'a profile switch closes the old menu and starts a quiet new scope',
      (tester) async {
    final state = LumoAppState();
    await tester.runAsync(() async {
      await state.school.setActiveStudent('offer-profile-a');
      await state.loadLearningProfile();
    });
    state.setSection(LumoSection.learn);
    final requests = LumoCompanionRequests.instance;
    void publish() => requests.publishTask(LumoCompanionTaskContext(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        prompt: '4 + 3 = ?',
        taskId: 'same-task-id',
        ownerSection: 'learn',
        profileGeneration: state.profileGeneration,
        attempts: 2,
        lastCorrect: false));
    publish();
    final before = requests.helpRequested.value;
    await mount(tester, state, (_) {});
    await tester.pump(const Duration(seconds: 18));
    await tester.tap(find.byKey(const ValueKey('lumo-fox-button')));
    await tester.pumpAndSettle();
    expect(find.text('Zeig mir wie'), findsOneWidget);
    await tester.runAsync(() async {
      await state.school.setActiveStudent('offer-profile-b');
      await state.loadLearningProfile();
    });
    publish();
    await tester.pumpAndSettle();
    expect(find.text('Zeig mir wie'), findsNothing);
    expect(requests.helpRequested.value, before);
    await tester.pump(const Duration(seconds: 18));
    expect(
        find.text(
            'Sollen wir die Aufgabe gemeinsam in kleine Schritte teilen?'),
        findsOneWidget);
    await unmount(tester, state);
  });

  testWidgets('a reading explanation closes when its task is left',
      (tester) async {
    final state = LumoAppState();
    state.setSection(LumoSection.home);
    await mount(tester, state, (_) {});
    await tester.tap(find.byKey(const ValueKey('lumo-fox-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diese Seite erklären'));
    await tester.pumpAndSettle();
    expect(find.text('So funktioniert diese Seite'), findsOneWidget);
    state.setSection(LumoSection.learn);
    await tester.pumpAndSettle();
    expect(find.text('So funktioniert diese Seite'), findsNothing);
    await unmount(tester, state);
  });

  testWidgets('task explanation requests help without navigating away',
      (tester) async {
    final state = LumoAppState();
    state.update(state.state.copyWith(
        section: LumoSection.exercises, subject: 'Deutsch', unit: 'Silben'));
    final sections = <LumoSection>[];
    final before = LumoCompanionRequests.instance.helpRequested.value;
    await mount(tester, state, sections.add);
    await tester.tap(find.text('Erklären'));
    await tester.pump();
    expect(LumoCompanionRequests.instance.helpRequested.value, before + 1);
    expect(sections, isEmpty);
    expect(state.state.unit, 'Silben');
    expect(tester.takeException(), isNull);
    await unmount(tester, state);
  });

  testWidgets(
      'a genuine learning-module task enables help without changing topic',
      (tester) async {
    final state = LumoAppState();
    state.setSection(LumoSection.learn);
    LumoCompanionRequests.instance.publishTask(LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      prompt: '4 + 3 = ?',
      taskId: 'plus10-actual-module',
      ownerSection: 'learn',
      profileGeneration: state.profileGeneration,
    ));
    final sections = <LumoSection>[];
    final before = LumoCompanionRequests.instance.helpRequested.value;
    await mount(tester, state, sections.add);
    await tester.tap(find.text('Erklären'));
    await tester.pump();
    expect(LumoCompanionRequests.instance.helpRequested.value, before + 1);
    expect(sections, isEmpty);
    expect(state.state.section, LumoSection.learn);
    expect(tester.takeException(), isNull);
    await unmount(tester, state);
  });

  testWidgets(
      'chat stays over the lesson and a local reply preserves its topic',
      (tester) async {
    final state = LumoAppState();
    state.update(state.state.copyWith(
        section: LumoSection.exercises,
        subject: 'Mathematik',
        unit: 'Plus bis 10'));
    final sections = <LumoSection>[];
    await mount(tester, state, sections.add);
    await tester.tap(find.text('Fragen'));
    await tester.pumpAndSettle();
    expect(find.byType(LumoAgentContent), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Hilf mir mit Silben');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(state.state.subject, 'Mathematik');
    expect(state.state.unit, 'Plus bis 10');
    expect(sections, isEmpty);
    expect(find.text('Die letzte Antwort kam erfolgreich von der Online-KI.'),
        findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester, state);
  });

  testWidgets('the generic chat entry remains closed during a schoolwork',
      (tester) async {
    final state = LumoAppState();
    state.update(state.state.copyWith(section: LumoSection.schoolwork));
    await mount(tester, state, (_) {});
    await tester.tap(find.text('Fragen'));
    await tester.pumpAndSettle();
    expect(find.byType(LumoAgentContent), findsNothing);
    expect(find.textContaining('Während der Schularbeit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester, state);
  });
}
