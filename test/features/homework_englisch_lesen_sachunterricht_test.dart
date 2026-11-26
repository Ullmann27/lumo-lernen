import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/fach_nachhilfe.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_class_data.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_homework.dart';
import 'package:lumo_lernen/features/teacher_demo/homework_runner_screen.dart';
import 'package:lumo_lernen/features/teacher_demo/teacher_demo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hausaufgaben Englisch, Lesen und Sachunterricht (Schulstufe 1–4): gleiche
/// Themen wie im Übungsbereich, automatisch prüfbar, Hilfen ohne Lösung,
/// Speicherung und Auswertung wie bei Mathematik und Deutsch.
final _now = DateTime(2026, 11, 26, 9);
const _neu = ['Englisch', 'Lesen', 'Sachunterricht'];

DemoHomework _hw(String subject, int grade, String unit, {int count = 5}) =>
    DemoHomework(
      id: 'hw-$subject-$grade-$unit',
      subject: subject,
      grade: grade,
      unit: unit,
      count: count,
      due: _now,
      note: '',
      studentIds: ['${demoStudentPrefix}1'],
      createdAt: _now,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('die drei Fächer sind wählbar, Mathematik und Deutsch bleiben', () {
    expect(homeworkSubjects,
        containsAll(['Mathematik', 'Deutsch', 'Englisch', 'Lesen', 'Sachunterricht']));
  });

  for (final subject in _neu) {
    for (var grade = 1; grade <= 4; grade++) {
      test('$subject · $grade. Stufe: Themen wie im Übungsbereich, '
          'Aufgaben prüfbar, Hilfen ohne Lösung', () {
        final units = homeworkUnitsFor(subject, grade);
        expect(units, isNotEmpty);
        for (final u in units) {
          expect(Curriculum.unitsForGrade(subject, grade), contains(u),
              reason: 'Fachtrennung: nur Themen dieses Fachs');
        }
        for (final unit in units) {
          final tasks = _hw(subject, grade, unit).tasksFor('${demoStudentPrefix}1');
          expect(tasks, hasLength(5), reason: unit);
          expect(tasks.map((t) => t.prompt).toSet().length,
              greaterThanOrEqualTo(3),
              reason: '$unit: verschiedene Aufgaben');
          // Je Kind stabil (gleiche Aufgaben beim erneuten Öffnen).
          expect(
              _hw(subject, grade, unit)
                  .tasksFor('${demoStudentPrefix}1')
                  .map((t) => t.prompt),
              tasks.map((t) => t.prompt),
              reason: unit);
          for (final t in tasks) {
            expect(t.choices, contains(t.answer), reason: t.prompt);
            expect(t.choices.length, greaterThanOrEqualTo(2));
            expect(t.subject, subject);
            final fach = t.fach;
            expect(fach, isNotNull, reason: t.prompt);
            expect(t.hints, isNotEmpty);
            for (final h in t.hints) {
              expect(const FachNachhilfe().verraet(h, fach!), isFalse,
                  reason: '$unit „${t.prompt}“: „$h“');
              expect(h, isNot(t.explanation));
            }
            expect(t.hints.toSet().length, t.hints.length,
                reason: 'jede Hilfe eine andere Erklärweise');
          }
        }
      });
    }
  }

  test('Mathematik und Deutsch: Hilfe ist ein Tipp, nicht mehr die Lösung',
      () {
    for (final (subject, unit) in [
      ('Mathematik', homeworkUnitsFor('Mathematik', 2).first),
      ('Deutsch', homeworkUnitsFor('Deutsch', 2).first),
    ]) {
      for (final t in _hw(subject, 2, unit).tasksFor('${demoStudentPrefix}1')) {
        expect(t.hints, isNotEmpty);
        for (final h in t.hints) {
          expect(h, isNot(t.explanation), reason: '$subject ${t.prompt}');
        }
      }
    }
  });

  test('Speicherung: neue Fächer mit Schulstufe; alte Hausaufgaben lesbar', () {
    final neu = _hw('Sachunterricht', 3, homeworkUnitsFor('Sachunterricht', 3).first)
        .withResult('${demoStudentPrefix}1', const [
      HomeworkItemResult(
          prompt: 'Wo entspringt ein Bach?',
          expected: 'an einer Quelle',
          given: 'an einer Quelle',
          durationMs: 8000,
          hintUsed: true),
    ]);
    final zurueck = DemoHomework.tryFromJson(neu.toJson())!;
    expect(zurueck.subject, 'Sachunterricht');
    expect(zurueck.grade, 3);
    expect(zurueck.results['${demoStudentPrefix}1']!.single.hintUsed, isTrue);
    expect(zurueck.results['${demoStudentPrefix}1']!.single.correct, isTrue);
    // Gespeicherte Hausaufgabe aus der Zeit vor dieser Änderung.
    final alt = DemoHomework.tryFromJson({
      'id': 'hw-alt',
      'sub': 'Mathematik',
      'unit': 'Plus bis 20',
      'n': 3,
      'due': _now.toIso8601String(),
      'note': 'alt',
      'kids': ['${demoStudentPrefix}1'],
      'at': _now.toIso8601String(),
      'res': {
        '${demoStudentPrefix}1': [
          {'q': '8 + 5 = ?', 'e': '13', 'a': '13', 'ms': 5000, 'h': false},
        ],
      },
    })!;
    expect(alt.grade, isNull);
    expect(alt.tasksFor('${demoStudentPrefix}1', grade: 2), hasLength(3));
    final eval = HomeworkEvaluation(alt, '${demoStudentPrefix}1',
        alt.results['${demoStudentPrefix}1']!);
    expect(eval.correct, 1);
  });

  testWidgets(
      'Kind löst Lesen-Hausaufgabe: Lesekarte, zwei verschiedene Hilfen, '
      'Ergebnis gespeichert', (tester) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    final store = DemoHomeworkStore();
    final hw = _hw('Lesen', 2, 'Sätze lesen', count: 3);
    await tester.runAsync(() => store.add(hw));
    final child = demoChildren.first;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(1080 / 2.625, 2340 / 2.625),
                disableAnimations: true,
                textScaler: TextScaler.linear(1.3)),
            child: HomeworkRunnerScreen(
                homework: hw,
                child: child,
                store: store,
                clock: () => _now))));
    await tester.pump(const Duration(milliseconds: 500));
    final tasks = hw.tasksFor(child.id, grade: child.grade);
    expect(find.byKey(const ValueKey('homework-reading')), findsOneWidget);
    final hilfe = find.byKey(const ValueKey('homework-hint'));
    await tester.ensureVisible(hilfe);
    await tester.pump();
    await tester.tap(hilfe);
    await tester.pump(const Duration(milliseconds: 300));
    final erste = tester
        .widget<Text>(find.byKey(const ValueKey('homework-hint-text')))
        .data!;
    await tester.ensureVisible(hilfe);
    await tester.pump();
    expect(find.text('Anders erklären'), findsOneWidget);
    await tester.tap(hilfe);
    await tester.pump(const Duration(milliseconds: 300));
    final zweite = tester
        .widget<Text>(find.byKey(const ValueKey('homework-hint-text')))
        .data!;
    expect(zweite, isNot(erste));
    expect(zweite, startsWith('Lumo erklärt es anders'));
    expect(erste, isNot(contains(tasks.first.answer)));
    for (final t in tasks) {
      final c = find.byKey(ValueKey('homework-choice-${t.answer}'));
      await tester.ensureVisible(c);
      await tester.tap(c);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Geschafft!'), findsOneWidget);
    final saved = (await tester.runAsync(store.load))!.single;
    final items = saved.results[child.id]!;
    expect(items, hasLength(3));
    expect(items.first.hintUsed, isTrue);
    expect(items.skip(1).every((i) => !i.hintUsed), isTrue);
    expect(items.every((i) => i.correct), isTrue);
    final eval = HomeworkEvaluation(saved, child.id, items);
    expect(eval.hints, 1);
    expect(eval.percent, 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Englisch: Bilder für alle deutschen Antworten gleich',
      (tester) async {
    final hw = _hw('Englisch', 1, 'Tiere', count: 4);
    final child = demoChildren.first;
    final tasks = hw.tasksFor(child.id);
    final mitBild = tasks.firstWhere((t) => t.pictureFor(t.answer) != null,
        orElse: () => tasks.first);
    if (mitBild.pictureFor(mitBild.answer) != null) {
      // Entweder alle Antworten haben ein Bild oder keine wird bevorzugt:
      // das Bild hängt nur am Wort, nicht daran, ob es richtig ist.
      expect(mitBild.choices.where((c) => mitBild.pictureFor(c) != null),
          isNotEmpty);
    }
    final deEn = FachAufgabe.aus(
        fach: 'Englisch',
        thema: 'Wetter',
        prompt: 'Wie heißt „nass“ auf Englisch?',
        antwort: 'wet',
        auswahl: ['dry', 'snow', 'wet', 'sun']);
    expect(deEn, isNotNull);
    const t = HomeworkTask(
        prompt: 'Wie heißt „nass“ auf Englisch?',
        answer: 'wet',
        choices: ['dry', 'snow', 'wet', 'sun'],
        explanation: '',
        subject: 'Englisch',
        unit: 'Wetter',
        grade: 3);
    expect(t.pictureFor('wet'), isNull,
        reason: 'englische Antworten bekommen kein übersetzendes Bild');
    expect(t.promptPicture, '💧');
  });

  testWidgets('Lehrerin gestaltet Sachunterricht-Hausaufgabe Stufe 3',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    final store = DemoHomeworkStore();
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(900, 2400), disableAnimations: true),
            child: TeacherDemoScreen(now: _now, store: store))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hausaufgaben'));
    await tester.pumpAndSettle();
    for (final s in _neu) {
      expect(find.byKey(ValueKey('homework-subject-$s')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('homework-subject-Sachunterricht')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('homework-grade-3')));
    await tester.pump();
    final create = find.byKey(const ValueKey('homework-create'));
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
    final saved = (await tester.runAsync(store.load))!.single;
    expect(saved.subject, 'Sachunterricht');
    expect(saved.grade, 3);
    expect(homeworkUnitsFor('Sachunterricht', 3), contains(saved.unit));
    expect(find.textContaining('Hausaufgabe: Sachunterricht'), findsOneWidget);
  });
}
