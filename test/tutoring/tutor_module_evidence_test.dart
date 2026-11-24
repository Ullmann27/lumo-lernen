import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('shared real module answer records its actual help and stable problem',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('module-tutor-a');
    final progress = LearningModuleProgress(
        appState: app, subject: 'Mathematik', unit: 'Uhr');
    addTearDown(progress.dispose);
    expect(
        await progress.saveAnswer(
            correct: true,
            hintUsed: true,
            prompt: 'Wie spät ist es?',
            given: '8',
            expected: '8'),
        isTrue);
    final journey =
        await ProgressRepository(studentId: 'module-tutor-a').loadJourney();
    expect(journey.records.values.single.assistedCorrect, 1);
    expect(journey.records.values.single.independentCorrect, 0);
    expect(journey.records.values.single.transferCorrect, 0);
  });
}
