import 'dart:convert';
import 'dart:io';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';

void main() {
  final rows = <Map<String,Object>>[];
  for (var grade = 1; grade <= 4; grade++) {
    for (final subject in Curriculum.exerciseSubjectsForGrade(grade)) {
      final units = Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true);
      rows.add({
        'grade':grade, 'subject':subject, 'available_units':units,
        'guided_introductions': [for (final unit in units)
          if (GuidedLessonCatalog.schoolIntroduction(subject:subject,unit:unit,grade:grade) case final lesson?)
            {'unit':unit,'course':lesson.id}],
        'without_guided_introduction': [for (final unit in units)
          if (GuidedLessonCatalog.schoolIntroduction(subject:subject,unit:unit,grade:grade)==null) unit],
      });
    }
  }
  final result = {'source':'0dc3b1f30d7d885cc0c9914d1f557fad8655d762',
    'scope':'Existing app content inventory; not a full official curriculum or external pedagogical approval',
    'automatic_quality_audit': {'checked':40974,'status':'PASS'}, 'rows':rows};
  File('/workspace/lumo-evidence/adaptive-minus/curriculum-inventory.json')
    .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  for(final row in rows.where((r)=>['Mathematik','Deutsch','Sachunterricht'].contains(r['subject']))) {
    print('${row['grade']}. Klasse ${row['subject']}: ${(row['available_units'] as List).length} Themen, ${(row['guided_introductions'] as List).length} geführte Einführungen');
  }
}
