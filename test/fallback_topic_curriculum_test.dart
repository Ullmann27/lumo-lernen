import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/teacher_mode/topic_curriculum.dart';

void main() {
  const fallbackIds = <String>{
    's1_koerper',
    'd2_saetze',
    'm3_zahlen1000',
    'm3_geometrie',
    's3_oesterreich',
    's3_natur',
    'm4_million',
    'm4_textaufgaben',
    'd4_grammatik',
    'd4_aufsatz',
    's4_europa',
    's4_geschichte',
  };

  test('fallback topics have concrete grade-specific curriculum content', () {
    for (final id in fallbackIds) {
      final ctx = TopicCurriculum.of(id);
      expect(ctx, isNotNull, reason: id);
      expect(ctx!.grade, inInclusiveRange(1, 4), reason: id);
      expect(ctx.subject.trim(), isNotEmpty, reason: id);
      expect(ctx.title.trim(), isNotEmpty, reason: id);
      expect(ctx.detailedScope.trim().length, greaterThan(20), reason: id);
      expect(ctx.exampleTask.trim().length, greaterThan(10), reason: id);
      expect(ctx.vocabulary, isNotEmpty, reason: id);
      expect(ctx.forbidden.trim(), isNotEmpty, reason: id);
      expect(ctx.complexityHint.trim(), isNotEmpty, reason: id);
      expect(ctx.quickQuestions.length, greaterThanOrEqualTo(2), reason: id);
      for (final q in ctx.quickQuestions) {
        expect(q.trim(), isNotEmpty, reason: id);
      }
      final header = ctx.buildPromptHeader();
      expect(header, contains('${ctx.grade}. Klasse'));
      expect(header, contains(ctx.subject));
      expect(header, contains(ctx.title));
    }
  });
}
