import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('local helper fits phone, small cover and Fold with parents access',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);
    state.updateSettings(const AppSettings(
      microphoneEnabled: false,
      voiceEnabled: false,
      autoReadEnabled: false,
      reduceAnimations: true,
    ));
    final visited = <LumoSection>[];

    for (final target in [
      (const Size(280, 700), 1.6),
      (const Size(360, 800), 1.0),
      (const Size(967, 805), 1.0),
    ]) {
      await tester.binding.setSurfaceSize(target.$1);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: target.$1,
            textScaler: TextScaler.linear(target.$2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: LumoAgentContent(
              key: ValueKey(target.$1.width),
              appState: state,
              onSection: visited.add,
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('lumo-agent-hologlass-hero')),
          findsOneWidget);
      expect(find.byType(LumoCharacter), findsWidgets);
      expect(find.text('Lumo hilft lokal'), findsOneWidget);
      expect(find.byKey(const ValueKey('lumo-agent-question-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('lumo-agent-send')),
          findsOneWidget);
      expect(find.textContaining('Mikrofon ist im Elternbereich ausgeschaltet'),
          findsOneWidget);
      expect(tester.takeException(), isNull, reason: target.$1.toString());
      final parent = find.byKey(const ValueKey('lumo-agent-parents'));
      await tester.ensureVisible(parent);
      await tester.pump();
      await tester.tap(parent);
      await tester.pump();
      expect(visited.last, LumoSection.settings);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
