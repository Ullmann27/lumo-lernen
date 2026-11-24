import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_class_data.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_homework.dart';
import 'package:lumo_lernen/features/teacher_demo/homework_runner_screen.dart';
import 'package:lumo_lernen/features/teacher_demo/teacher_demo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 24, 12);

Widget _host(Widget child) => MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: app!,
      ),
      home: child,
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Demo-Daten', () {
    test('sind deterministisch, einen Monat lang und nur für Demo-Kinder', () {
      const gen = DemoClassDataGenerator();
      final a = gen.attemptsFor(demoChildren.first, now: _now);
      final b = gen.attemptsFor(demoChildren.first, now: _now);
      expect(a.length, b.length);
      expect([for (final x in a) x.toJson()], [for (final x in b) x.toJson()]);
      expect(a.length, greaterThan(200));
      expect(a.every((x) => isDemoStudentId(x.studentId)), isTrue);
      final span = a.last.at.difference(a.first.at).inDays;
      expect(span, inInclusiveRange(20, 27));
    });

    test('erkennen den unsicheren Zehnerübergang bei Demo-Kind 1', () {
      final report = DemoChildReport.build(demoChildren.first, now: _now);
      expect(
          report.weaknesses.any((w) => w.startsWith('Zehnerübergang bei Minus bis')),
          isTrue,
          reason: report.weaknesses.join(' | '));
      expect(report.strengths, isNotEmpty);
      expect(report.recommendations, isNotEmpty);
      expect(report.weeklyAccuracy['Mathematik'], hasLength(4));
    });

    testWidgets('Klassenübersicht und Auswertung zeigen DEMO-DATEN und lokalen Hinweis',
        (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_host(TeacherDemoScreen(now: _now)));
      await tester.pumpAndSettle();
      expect(find.text(demoDataLabel), findsWidgets);
      expect(find.textContaining('Demo: lokal auf diesem Gerät'), findsOneWidget);
      expect(find.text('Demo-Kind 1'), findsOneWidget);
      expect(find.textContaining('synchron', findRichText: true), findsNothing);

      await tester.tap(find.byKey(ValueKey('demo-child-${demoChildren.first.id}')));
      await tester.pumpAndSettle();
      expect(find.text(demoDataLabel), findsWidgets);
      expect(find.text('Kompetenz-Radar'), findsOneWidget);
      await tester.ensureVisible(find.text('Automatisch erkannte Schwächen'));
      expect(find.textContaining('Zehnerübergang bei Minus bis'), findsWidgets);
    });

    test('Speicher berührt keine echten Profildaten', () async {
      SharedPreferences.setMockInitialValues({'lumo_profile_x': 'echt'});
      final store = DemoHomeworkStore();
      await store.add(DemoHomework(
        id: 'hw-1',
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        count: 3,
        due: _now,
        note: '',
        studentIds: ['${demoStudentPrefix}1', 'echtes-kind'],
        createdAt: _now,
      ));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lumo_profile_x'), 'echt');
      expect(prefs.getKeys(), {'lumo_profile_x', DemoHomeworkStore.storageKey});
      final loaded = await store.load();
      expect(loaded.single.studentIds, ['${demoStudentPrefix}1']);
    });
  });

  group('Hausaufgaben', () {
    test('automatische Prüfung bewertet richtig, falsch, Zeit und Hilfen', () {
      final hw = DemoHomework(
        id: 'hw-eval',
        subject: 'Mathematik',
        unit: 'Minus bis 100',
        count: 3,
        due: _now,
        note: '',
        studentIds: ['${demoStudentPrefix}1'],
        createdAt: _now,
      );
      final items = [
        const HomeworkItemResult(
            prompt: '52 - 18 = ?', expected: '34', given: '34', durationMs: 4000, hintUsed: false),
        const HomeworkItemResult(
            prompt: '61 - 27 = ?', expected: '34', given: '44', durationMs: 9000, hintUsed: true),
        const HomeworkItemResult(
            prompt: '75 - 20 = ?', expected: '55', given: ' 55 ', durationMs: 2000, hintUsed: false),
      ];
      final e = HomeworkEvaluation(hw, '${demoStudentPrefix}1', items);
      expect(e.correct, 2);
      expect(e.wrong, 1);
      expect(e.hints, 1);
      expect(e.percent, 67);
      expect(e.averageSeconds, 5);
      expect(e.analysis.stats.map((s) => s.competency),
          contains('Subtraktion mit Zehnerübergang'));
    });

    testWidgets('Kind löst Hausaufgabe, Lehrerin sieht die Auswertung', (tester) async {
      final store = DemoHomeworkStore();
      final hw = DemoHomework(
        id: 'hw-flow',
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        count: 3,
        due: _now.add(const Duration(days: 2)),
        note: 'Rechne in Ruhe.',
        studentIds: ['${demoStudentPrefix}1'],
        createdAt: _now,
      );
      await store.add(hw);
      final child = demoChildren.first;
      final tasks = hw.tasksFor(child.id, grade: child.grade);
      for (final t in tasks) {
        expect(t.choices, contains(t.answer));
      }

      _tallView(tester);
      await tester.pumpWidget(_host(
          HomeworkRunnerScreen(homework: hw, child: child, store: store)));
      await tester.pump();
      expect(find.text('Hausaufgabe'), findsOneWidget);
      expect(find.textContaining('Rechne in Ruhe.'), findsOneWidget);

      // Aufgabe 1 mit Hilfe richtig, Aufgabe 2 falsch, Aufgabe 3 richtig.
      await tester.tap(find.byKey(const ValueKey('homework-hint')));
      await tester.pump();
      for (var i = 0; i < tasks.length; i++) {
        final t = tasks[i];
        final pick = i == 1 ? t.choices.firstWhere((c) => c != t.answer) : t.answer;
        await tester.tap(find.byKey(ValueKey('homework-choice-$pick')));
        await tester.pump(const Duration(milliseconds: 1000));
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(find.textContaining('2 von 3 richtig'), findsOneWidget);

      final saved = (await store.load()).single;
      expect(saved.isDoneBy(child.id), isTrue);
      final e = HomeworkEvaluation(saved, child.id, saved.results[child.id]!);
      expect(e.correct, 2);
      expect(e.hints, 1);

      await tester.pumpWidget(_host(TeacherDemoScreen(now: _now, store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hausaufgaben'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('evaluation-hw-flow-${child.id}')));
      expect(find.textContaining('2 von 3 richtig (67 %)'), findsOneWidget);
      expect(find.textContaining('1× Hilfe'), findsOneWidget);
    });
  });
}
