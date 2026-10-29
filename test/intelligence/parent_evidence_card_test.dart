import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/features/parents/widgets/lumo_tutor_evidence_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('parents see recorded method reason, not an invented competence', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = LumoAppState(); addTearDown(app.dispose);
    await tester.runAsync(() async {
      await app.school.setActiveStudent('parent-scene-a'); await app.loadLearningProfile();
      await app.saveLearningScene(observation: SceneObservation.methodFeedback(id: 'method-a',
        conceptId: 'math.tens_ones', problemId: 'source-a', method: ExplanationMethod.verbal,
        understood: false, at: DateTime.utc(2026,10,29)));
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LumoTutorEvidenceCard(appState: app)))));
    expect(find.textContaining('anderem Erklärweg'), findsOneWidget);
    expect(find.textContaining('noch keine geprüfte Beobachtung'), findsOneWidget);
    expect(find.textContaining('bestätigt beherrscht'), findsNothing);
    await tester.runAsync(() async { await app.school.setActiveStudent('parent-scene-b'); await app.loadLearningProfile(); });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LumoTutorEvidenceCard(appState: app))));
    expect(find.textContaining('anderem Erklärweg'), findsNothing);
  });
}
