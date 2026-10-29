import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_learning_scene_card.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('actual child requests a different scene; refusal is saved without competence', (tester) async {
    SharedPreferences.setMockInitialValues({}); LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = true);
    final app = LumoAppState(); addTearDown(app.dispose);
    await tester.runAsync(() async { await app.school.setActiveStudent('live-scene-a'); await app.loadLearningProfile(); });
    app.updateSettings(const AppSettings(voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
    app.update(app.state.copyWith(grade: 2, subject: 'Mathematik', unit: 'Zehner und Einer'));
    await tester.binding.setSurfaceSize(const Size(360, 820)); addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LearningContent(appState: app)))); await tester.pump();
    LumoCompanionRequests.instance.requestTaskHelp();
    for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 16)); await tester.runAsync(() => Future<void>.delayed(Duration.zero)); }
    expect(find.byType(LumoLearningSceneCard), findsOneWidget);
    final button = find.byKey(const ValueKey('lumo-scene-not-understood'));
    await tester.ensureVisible(button); await tester.pump(); await tester.tap(button);
    for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 16)); await tester.runAsync(() => Future<void>.delayed(Duration.zero)); }
    expect(find.byKey(const ValueKey('lumo-scene-pictorial')), findsOneWidget);
    expect(app.learningProfile.sceneMemory.records.any((r) => r.outcome == SceneOutcome.notUnderstood && r.method == ExplanationMethod.verbal), isTrue);
    expect(app.learningJourney().values.any((r) => r.transferCorrect > 0), isFalse);
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pump();
  });
}
