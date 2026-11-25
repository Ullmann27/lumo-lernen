import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_chart_data.dart';
import 'package:lumo_lernen/features/report/learning_analytics_panel.dart';

final now = DateTime(2026, 11, 25, 12);

Attempt answer(String id, {String owner = 'a', String subject = 'Mathematik',
  bool correct = true, bool help = false, int? ms, DateTime? at}) => Attempt(
    id: id, studentId: owner, subject: subject, unit: 'Üben',
    competency: 'Zahlen', correct: correct, hintUsed: help,
    durationMs: ms, at: at ?? now.subtract(const Duration(hours: 1)),
  );

LearningChartData data(List<Attempt> attempts, {String owner = 'a'}) =>
    LearningChartData.fromAttempts(attempts, studentId: owner, now: now);

void main() {
  test('subject activity is owner-scoped, deduplicated and independent', () {
    final a = answer('same', ms: 1000);
    final result = data([
      answer('same', owner: 'b', ms: 90000),
      a, a,
      answer('wrong', correct: false, ms: 3000),
      answer('help', help: true, ms: 90000),
      answer('future', at: now.add(const Duration(seconds: 1)), ms: 90000),
      answer('assessment', subject: 'IQ-Rätsel', ms: 90000),
      answer('no-time', ms: 0),
      answer('negative', ms: -2),
      answer('missing'),
      answer('english', subject: 'Englisch', help: true, ms: 1000),
    ]);
    final math = result.subjectActivity.singleWhere((s) => s.subject == 'Mathematik');
    expect(result.total, 7);
    expect(math.total, 6);
    expect(math.assisted, 1);
    expect(math.independent, 5);
    expect(math.independentCorrect, 4);
    expect(math.independentAccuracy, .8);
    expect(math.helpRate, 1/6);
    expect(math.timedIndependent, 2);
    expect(math.medianIndependentMs, 2000);
    final english = result.subjectActivity.singleWhere((s) => s.subject == 'Englisch');
    expect(english.helpRate, 1);
    expect(english.independentAccuracy, isNull);
    expect(english.medianIndependentMs, isNull);
    expect(english.timedIndependent, 0);
    expect(() => result.subjectActivity.clear(), throwsUnsupportedError);
  });

  test('odd median, actual zero accuracy and missing times remain distinct', () {
    final result = data([
      answer('1', correct: false, ms: 9000),
      answer('2', correct: false, ms: 1000),
      answer('3', correct: false, ms: 4000),
      answer('4', correct: false),
    ]);
    final m = result.subjectActivity.single;
    expect(m.independentAccuracy, 0);
    expect(m.helpRate, 0);
    expect(m.medianIndependentMs, 4000);
    expect(m.timedIndependent, 3);
    expect(data([], owner: 'b').subjectActivity, isEmpty);
  });

  for (final width in [320.0, 840.0]) {
    testWidgets('subject filter and owner reset at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 960);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Future<void> show(LearningChartData value) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(
          child: LearningAnalyticsPanel(data: value),
        ))),
      );
      await show(data([
        answer('1', ms: 2500),
        answer('2', correct: false),
        answer('3', subject: 'Englisch', help: true),
      ]));
      final math = find.byKey(const ValueKey('live-subject-activity-Mathematik'));
      final english = find.byKey(const ValueKey('live-subject-activity-Englisch'));
      final chip = find.byKey(const ValueKey('live-subject-filter-Englisch'));
      expect(math, findsOneWidget);
      expect(english, findsOneWidget);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
      expect(math, findsNothing);
      expect(english, findsOneWidget);
      expect(find.text('Noch keine Antworten ohne Hilfe'), findsOneWidget);
      expect(find.text('Bearbeitungszeit: keine erfasste Zeit ohne Hilfe'), findsOneWidget);
      await show(data([
        answer('4', owner: 'b', subject: 'Englisch'),
        answer('5', owner: 'b', ms: 3000),
      ], owner: 'b'));
      expect(math, findsOneWidget);
      expect(english, findsOneWidget);
      expect(find.textContaining('3,0 s'), findsOneWidget);
      expect(find.textContaining('2,5 s'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
