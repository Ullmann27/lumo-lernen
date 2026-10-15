import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/teacher_mode/widgets/academy_subject_art.dart';

void main() {
  testWidgets('four school subjects use original distinct illustrated art',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AcademySubjectArt(
                subjectName: 'Mathematik',
                subjectId: 'mathe4',
                accent: Color(0xFFFFB848),
              ),
              AcademySubjectArt(
                subjectName: 'Deutsch',
                subjectId: 'deutsch4',
                accent: Color(0xFFBB86FC),
              ),
              AcademySubjectArt(
                subjectName: 'Englisch',
                subjectId: 'englisch4',
                accent: Color(0xFF4DBBF6),
              ),
              AcademySubjectArt(
                subjectName: 'Sachunterricht',
                subjectId: 'sach4',
                accent: Color(0xFF55D8AE),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    for (final id in ['mathe4', 'deutsch4', 'englisch4', 'sach4']) {
      expect(find.byKey(ValueKey('academy-grade-icon-$id')), findsOneWidget);
    }
    expect(find.text('8'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('Hi!'), findsOneWidget);
    expect(find.text('🔢'), findsNothing);
    expect(find.text('🇬🇧'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
