import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/world/world_school_mission.dart';

void main() {
  test('world school request accepts only the versioned local contract', () {
    final request = WorldSchoolMissionRequest(
      requestId: 'world-school-0001',
      grade: 2,
    );
    final raw = request.toJson();
    expect(
      WorldSchoolMissionRequest.tryParse(raw)?.requestId,
      request.requestId,
    );
    expect(WorldSchoolMissionRequest.tryParse(null), isNull);
    expect(WorldSchoolMissionRequest.tryParse('school_numbers'), isNull);
    for (final change in <Map<String, Object>>[
      {'version': 2},
      {'id': 'unrelated_mission'},
      {'subject': 'Deutsch'},
      {'returnGame': 'kart'},
      {'grade': 0},
      {'grade': 5},
      {'grade': '2'},
      {'requestId': ''},
      {'requestId': 'bad request with spaces'},
      {'requestId': 'x' * 161},
    ]) {
      expect(
        WorldSchoolMissionRequest.tryParse({...raw, ...change}),
        isNull,
        reason: change.toString(),
      );
    }
  });

  for (var grade = 1; grade <= 4; grade++) {
    test(
      'grade $grade uses three real checked tasks and a stable pending request',
      () {
        final request = WorldSchoolMissionRequest(
          requestId: 'school-grade-$grade-001',
          grade: grade,
        );
        final lesson = WorldSchoolLesson.start(
          request: request,
          ownerId: 'child-a',
        );
        final reopened = WorldSchoolLesson.start(
          request: request,
          ownerId: 'child-a',
        );
        expect(lesson.tasks, hasLength(3));
        expect(lesson.tasks.map((task) => task.unit).toSet(), hasLength(3));
        for (var i = 0; i < lesson.tasks.length; i++) {
          final task = lesson.tasks[i];
          expect(task.grade, grade);
          expect(task.subject, 'Mathematik');
          expect(const TaskQualityGuard().validate(task), isTrue);
          expect(task.prompt, reopened.tasks[i].prompt);
          expect(task.answer, reopened.tasks[i].answer);
          expect(lesson.problemIdentity(i), reopened.problemIdentity(i));
        }
        expect(() => lesson.tasks.clear(), throwsUnsupportedError);
      },
    );
  }

  test(
    'wrong, duplicate and out-of-order answers cannot complete a mission',
    () {
      final lesson = WorldSchoolLesson.start(
        request: WorldSchoolMissionRequest(
          requestId: 'school-guard-001',
          grade: 1,
        ),
        ownerId: 'child-a',
      );
      expect(lesson.receiptForOwner('child-a'), isNull);
      expect(
        lesson.acceptSavedAnswer(
          index: 0,
          answer: 'wrong',
          currentOwnerId: 'child-a',
        ),
        isFalse,
      );
      expect(
        lesson.acceptSavedAnswer(
          index: 1,
          answer: lesson.tasks[1].answer,
          currentOwnerId: 'child-a',
        ),
        isFalse,
      );
      expect(
        lesson.acceptSavedAnswer(
          index: 0,
          answer: lesson.tasks[0].answer,
          currentOwnerId: 'child-a',
        ),
        isTrue,
      );
      expect(
        lesson.acceptSavedAnswer(
          index: 0,
          answer: lesson.tasks[0].answer,
          currentOwnerId: 'child-a',
        ),
        isFalse,
      );
      expect(lesson.solved, 1);
      expect(lesson.receiptForOwner('child-a'), isNull);
    },
  );

  test(
    'all three saved correct answers create the matching immutable receipt',
    () {
      final request = WorldSchoolMissionRequest(
        requestId: 'school-finish-001',
        grade: 3,
      );
      final lesson = WorldSchoolLesson.start(
        request: request,
        ownerId: 'child-a',
      );
      for (var i = 0; i < 3; i++) {
        expect(
          lesson.acceptSavedAnswer(
            index: i,
            answer: lesson.tasks[i].answer,
            currentOwnerId: 'child-a',
          ),
          isTrue,
        );
        if (i < 2) expect(lesson.receiptForOwner('child-a'), isNull);
      }
      expect(lesson.complete, isTrue);
      expect(lesson.receiptForOwner('child-a')!.toJson(), {
        'version': 1,
        'requestId': request.requestId,
        'missionId': 'school_numbers',
        'completed': true,
        'subject': 'Mathematik',
        'grade': 3,
        'returnGame': 'world',
      });
      expect(lesson.receiptForOwner('child-b'), isNull);
    },
  );

  test('changing owner or cancelling never produces success', () {
    final lesson = WorldSchoolLesson.start(
      request: WorldSchoolMissionRequest(
        requestId: 'school-owner-001',
        grade: 1,
      ),
      ownerId: 'child-a',
    );
    expect(
      lesson.acceptSavedAnswer(
        index: 0,
        answer: lesson.tasks[0].answer,
        currentOwnerId: 'child-b',
      ),
      isFalse,
    );
    expect(lesson.solved, 0);
    lesson.cancel();
    expect(lesson.cancelled, isTrue);
    expect(
      lesson.acceptSavedAnswer(
        index: 0,
        answer: lesson.tasks[0].answer,
        currentOwnerId: 'child-a',
      ),
      isFalse,
    );
    expect(lesson.receiptForOwner('child-a'), isNull);
  });
}
