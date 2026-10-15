import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/profile_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parent switches from grade 2 to 3 without losing rewards or work',
      () async {
    final repository = ProfileRepository();
    await repository.saveProfile(UserProfile(
      id: 'child-42',
      name: 'Testkind',
      age: 8,
      grade: 2,
      createdAt: DateTime.utc(2026, 9, 1),
      lastActiveAt: DateTime.utc(2026, 10, 14),
    ));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(
      childName: 'Testkind',
      grade: 2,
      stars: 57,
      xp: 316,
      solved: {'Plus bis 100': 12},
      subject: 'Mathematik',
      unit: 'Plus bis 100',
    ));

    await app.changeEnrolledGrade(3);

    expect(app.state.grade, 3);
    expect(app.state.subject, 'Alle');
    expect(app.state.unit, 'Alle');
    expect(app.state.stars, 57);
    expect(app.state.xp, 316);
    expect(app.state.solved['Plus bis 100'], 12);
    final persisted = await repository.loadProfile();
    expect(persisted?.grade, 3);
    expect(persisted?.id, 'child-42');
    expect(persisted?.name, 'Testkind');
    expect(Curriculum.unitsForGrade('Mathematik', app.state.grade,
        currentGradeOnly: true), isNotEmpty);
    expect(Curriculum.unitsForGrade('Sachunterricht', app.state.grade,
        currentGradeOnly: true), isNotEmpty);

    await app.changeEnrolledGrade(4);
    expect((await repository.loadProfile())?.grade, 4);
    await app.changeEnrolledGrade(1);
    expect((await repository.loadProfile())?.grade, 1);
  });

  test('school grade is parent-persistent and rejects invalid values',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await expectLater(app.changeEnrolledGrade(5),
        throwsA(isA<RangeError>()));
    await expectLater(app.changeEnrolledGrade(3),
        throwsA(isA<StateError>()));
    expect(app.state.grade, 1);
  });
}
