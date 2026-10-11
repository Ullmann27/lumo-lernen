import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/lumo_companion_state.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/school_repository.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('names belong to the captured student and unknown IDs stay unnamed',
      () async {
    const directory = SchoolDirectory(students: [
      SchoolStudent(id: 'a', name: 'Ada', classId: 'c'),
      SchoolStudent(id: 'b', name: 'Ben', classId: 'c'),
    ]);
    SharedPreferences.setMockInitialValues(
        {'lumo_school_v1': jsonEncode(directory.toJson())});
    final school = SchoolRepository();
    await school.setActiveStudent('b');
    expect(await school.studentName('a'), 'Ada');
    expect(await school.studentName('b'), 'Ben');
    expect(await school.studentName('unknown'), isNull);
    school.dispose();
  });
  test('name lookup never deletes damaged school data or guesses its owner',
      () async {
    const broken = '{saved-but-incomplete';
    SharedPreferences.setMockInitialValues({'lumo_school_v1': broken});
    final school = SchoolRepository();
    expect(await school.studentName('a'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_school_v1'), broken);
    school.dispose();
  });
  test('companion summaries reuse canonical A/B progress after restart',
      () async {
    final legacy = jsonEncode({'name': 'Unknown', 'tc': 700});
    SharedPreferences.setMockInitialValues({'lumo_companion_v1': legacy});
    final a =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await a.recordAnswer(subject: 'Deutsch', unit: 'Silben', isCorrect: true);
    await a.recordAnswer(subject: 'Deutsch', unit: 'Silben', isCorrect: false);
    final b =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'b'));
    await b.load();
    final aMemory =
        LumoCompanionState.fromProfile(profile: a, childName: 'Ada');
    final bMemory =
        LumoCompanionState.fromProfile(profile: b, childName: 'Ben');
    expect(aMemory.totalCorrect, 1);
    expect(aMemory.totalWrong, 1);
    expect(aMemory.correctToday, 1);
    expect(aMemory.childName, 'Ada');
    expect(bMemory.totalInteractions, 0);
    expect(bMemory.childName, 'Ben');
    final restored =
        LearningProfileEngine(repository: ProgressRepository(studentId: 'a'));
    await restored.load();
    expect(
        LumoCompanionState.fromProfile(profile: restored, childName: 'Ada')
            .totalCorrect,
        1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_companion_v1'), legacy);
  });
}
