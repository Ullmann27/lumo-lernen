import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/agent/lumo_task_conversation_panel.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.taskContext.value = null;
  });

  tearDown(() {
    LumoCompanionRequests.instance.taskContext.value = null;
  });

  testWidgets('microphone denied preserves text task conversation', (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(
      section: LumoSection.exercises,
      subject: 'Mathematik',
      unit: 'Zehnerübergang',
    ));
    LumoCompanionRequests.instance.taskContext.value =
        const LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Zehnerübergang',
      prompt: 'Rechne 8 + 5.',
      taskId: 'chat4-widget-test',
      helpLevel: 1,
      localHelp: 'Das Zehnerfeld zeigt acht belegte Plätze.',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 700,
          child: LumoTaskConversationPanel(appState: app),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byKey(const ValueKey('lumo-task-conversation-panel')), findsOneWidget);
    expect(find.textContaining('Mikrofon im Elternbereich deaktiviert'), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-task-text-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-task-stop')), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('lumo-task-text-input')),
        'Warum zuerst zwei?');
    await tester.ensureVisible(find.byKey(const ValueKey('lumo-task-text-send')));
    await tester.tap(find.byKey(const ValueKey('lumo-task-text-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('zwei Plätze frei'), findsWidgets);
    expect(app.state.solved, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stop and repeat controls remain reachable without microphone',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(section: LumoSection.exercises));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: LumoTaskConversationPanel(appState: app),
          ),
        )));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('lumo-task-stop')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-task-repeat')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-task-slower')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-task-text-send')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('lumo-task-stop')));
    await tester.tap(find.byKey(const ValueKey('lumo-task-stop')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
