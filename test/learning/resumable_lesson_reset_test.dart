import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final fullReset in [false, true]) {
    test('lesson views reset only for their owner (full reset: $fullReset)',
        () async {
      final owner = LearningDataNamespace(studentId: 'view-reset-a');
      final other = LearningDataNamespace(studentId: 'view-reset-b');
      const photo = 'lumo_photo_lesson_session_v1';
      const lab = 'lumo_learning_lab_session_v1';
      const photoBytes = '{"fixture":"pending photo lesson"}';
      const labBytes = '{"version":1,"sessions":{"fixture":{}}}';
      for (final namespace in [owner, other]) {
        await namespace.write(photo, photoBytes);
        await namespace.write(lab, labBytes);
        await namespace.write('unrelated_fixture', 'keep exactly');
      }
      final repository = ProgressRepository(studentId: 'view-reset-a');
      if (fullReset) {
        await repository.resetAll();
      } else {
        await repository.resetTutorObservations();
      }
      expect(await owner.read(photo), 'null');
      expect(jsonDecode((await owner.read(lab))!), {
        'version': 1,
        'sessions': <String, Object?>{},
      });
      expect(await owner.read('unrelated_fixture'), 'keep exactly');
      expect(await other.read(photo), photoBytes);
      expect(await other.read(lab), labBytes);
      expect(await other.read('unrelated_fixture'), 'keep exactly');
    });
  }
}
