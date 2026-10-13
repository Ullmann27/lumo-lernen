import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('registry IDs and builders stay in lockstep', () {
    final appState = LumoAppState();
    addTearDown(appState.dispose);

    for (final id in LearningModuleRegistry.registeredTopicIds) {
      expect(
        LearningModuleRegistry.builderFor(id, appState),
        isNotNull,
        reason: 'Kein Builder für registriertes Modul $id',
      );
    }
  });

  testWidgets('all registered learning modules mount without immediate crash',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final id in LearningModuleRegistry.registeredTopicIds) {
      final appState = LumoAppState();
      final screen = LearningModuleRegistry.builderFor(id, appState);
      expect(screen, isNotNull, reason: id);

      await tester.pumpWidget(MaterialApp(home: screen!));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(tester.takeException(), isNull, reason: id);
      appState.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
