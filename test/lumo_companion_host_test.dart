import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/lumo_companion_host.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
