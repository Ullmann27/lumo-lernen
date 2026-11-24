import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() {
    LumoVoice.instance.isEnabled = true;
    LumoCompanionRequests.instance.clearLearningScope();
  });

  testWidgets(
      'real wrong answers invite without revealing; help stays assisted in journal',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(880, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('live-tutor-a');
    await app.loadLearningProfile();
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
    app.update(app.state.copyWith(subject: 'Mathematik', unit: 'Plus bis 10'));
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LearningContent(appState: app))));
    await tester.pump();
    AdaptiveTaskRenderer renderer() =>
        tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
    for (var i = 0; i < 2; i++) {
      final r = renderer();
      final wrong = r.task.options.firstWhere(
          (o) => '${o.payload ?? o.label}' != '${r.task.correctAnswer}');
      r.onAnswered!(AdaptiveTaskAnswer(
          task: r.task, correct: false, answer: wrong.payload ?? wrong.label));
      await tester.pump();
      expect(find.text('Lumo erklärt'), findsNothing);
    }
    expect(LumoCompanionRequests.instance.tutor.shouldOffer, isTrue);
    LumoCompanionRequests.instance.requestTaskHelp();
    await tester.pump();
    expect(find.text('Lumo erklärt'), findsOneWidget);
    final r = renderer();
    r.onAnswered!(AdaptiveTaskAnswer(
        task: r.task, correct: true, answer: r.task.correctAnswer));
    await tester.pump();
    await tester.runAsync(() => app.flushTutorEvidence());
    expect(app.learningJourney().values.single.assistedCorrect, 1);
    expect(app.learningJourney().values.single.independentCorrect, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
