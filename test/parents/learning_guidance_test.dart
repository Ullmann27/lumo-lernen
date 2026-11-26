import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/school/adaptive_practice_plan.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_guidance.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:lumo_lernen/features/report/learning_guidance_panel.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_class_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 25, 12);

Attempt _a(
  String id, {
  String student = 'child-a',
  String subject = 'Mathematik',
  String unit = 'Plus bis 20',
  String competency = 'Addition ohne Zehnerübergang',
  bool correct = true,
  bool hint = false,
  int daysAgo = 1,
  int minutes = 0,
  DateTime? reference,
}) =>
    Attempt(
      id: id,
      studentId: student,
      subject: subject,
      unit: unit,
      competency: competency,
      correct: correct,
      hintUsed: hint,
      at: (reference ?? _now)
          .subtract(Duration(days: daysAgo, minutes: minutes)),
    );

/// Ein sicheres Thema (Stärke) und ein schwaches Thema (Förderbedarf).
List<Attempt> _child(String student, {DateTime? reference}) => [
      for (var i = 0; i < 10; i++)
        _a('$student-plus-$i',
            student: student, daysAgo: 1 + i % 3, minutes: i,
            reference: reference),
      for (var i = 0; i < 6; i++)
        _a('$student-minus-$i',
            student: student,
            unit: 'Minus bis 100',
            competency: 'Subtraktion mit Zehnerübergang',
            correct: i == 0,
            daysAgo: 2,
            minutes: i,
            reference: reference),
      _a('$student-minus-hilfe',
          student: student,
          unit: 'Minus bis 100',
          competency: 'Subtraktion mit Zehnerübergang',
          hint: true,
          reference: reference),
    ];

Future<void> _frames(WidgetTester tester) async {
  for (var index = 0; index < 20; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

class _Log extends AttemptLogRepository {
  _Log(this.attempts);
  final List<Attempt> attempts;

  @override
  Future<List<Attempt>> load({String? studentId}) async => [
        for (final a in attempts)
          if (studentId == null || a.studentId == studentId) a,
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Datentrennung echt / Demo', () {
    test('Nur das genannte Kind zählt; Demo, Duplikate, Zukunft, Knobel-Test nie',
        () {
      final demoReport = DemoChildReport.build(demoChildren.first, now: _now);
      final mixed = <Attempt>[
        ..._child('child-a'),
        ..._child('child-b'),
        ...demoReport.attempts,
        _a('child-a-plus-0'), // Duplikat
        _a('child-a-zukunft', daysAgo: -2),
        _a('child-a-iq',
            subject: 'IQ-Rätsel', unit: 'Muster', competency: 'Logik'),
      ];
      final g = LearningGuidance.fromAttempts(mixed,
          studentId: 'child-a', now: _now);
      expect(g.total, 17);
      expect(g.independentTotal, 16);
      final alleFaecher = {
        for (final t in g.current) t.subject,
        for (final c in [...g.strengths, ...g.needs]) c.subject,
        for (final r in g.recommendations) r.subject,
      };
      expect(alleFaecher, {'Mathematik'});
      // Demo-Kinder gehören nie in eine echte Auswertung.
      for (final child in demoChildren) {
        expect(LearningGuidance.isDemoStudent(child.id), isTrue);
        final demo = LearningGuidance.fromAttempts(
            DemoChildReport.build(child, now: _now).attempts,
            studentId: child.id,
            now: _now);
        expect(demo.total, 0, reason: child.id);
        expect(demo.hasReliableEvidence, isFalse);
      }
      expect(demoStudentPrefix, LearningGuidance.demoStudentPrefix);
    });

    testWidgets('Echte Übersicht zeigt kein Demo-Schild und keine Demo-Namen',
        (tester) async {
      final g = LearningGuidance.fromAttempts(
          [
            ..._child('child-a'),
            ...DemoChildReport.build(demoChildren.first, now: _now).attempts,
          ],
          studentId: 'child-a',
          now: _now);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: LearningGuidancePanel(guidance: g)))));
      expect(find.textContaining(demoDataLabel), findsNothing);
      for (final child in demoChildren) {
        expect(find.textContaining(child.name), findsNothing);
      }
      expect(find.textContaining('Grundlage: 17 Antworten'), findsOneWidget);
    });
  });

  group('Wenige Daten: nichts behaupten', () {
    test('Vier Antworten ohne Hilfe ergeben weder Stärke noch Förderbedarf', () {
      final g = LearningGuidance.fromAttempts(
          [for (var i = 0; i < 4; i++) _a('x$i', correct: i.isEven)],
          studentId: 'child-a',
          now: _now);
      expect(g.current, hasLength(1));
      expect(g.hasReliableEvidence, isFalse);
      expect(g.strengths, isEmpty);
      expect(g.needs, isEmpty);
      expect(g.recommendations, isEmpty);
      expect(g.development, isEmpty);
    });

    testWidgets('Panel nennt nur Aktivität und erklärt die Schwelle',
        (tester) async {
      final g = LearningGuidance.fromAttempts(
          [for (var i = 0; i < 4; i++) _a('x$i')],
          studentId: 'child-a',
          now: _now);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: LearningGuidancePanel(guidance: g)))));
      expect(find.byKey(const ValueKey('guidance-few-data')), findsOneWidget);
      expect(find.byKey(const ValueKey('guidance-current')), findsOneWidget);
      expect(find.byKey(const ValueKey('guidance-strengths')), findsNothing);
      expect(find.byKey(const ValueKey('guidance-needs')), findsNothing);
      expect(find.byKey(const ValueKey('guidance-plan')), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('Ohne Antworten: nur der Leerhinweis', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: LearningGuidancePanel(
                  guidance: LearningGuidance.fromAttempts(const [],
                      studentId: 'child-a', now: _now)))));
      expect(find.byKey(const ValueKey('guidance-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('guidance-current')), findsNothing);
    });
  });

  test('Stärken, Förderbedarf, Lernplan und Lernentwicklung aus echten Antworten',
      () {
    final g = LearningGuidance.fromAttempts([
      ..._child('child-a'),
      // Entwicklung: erst vier falsch, dann vier richtig (Einmaleins).
      for (var i = 0; i < 8; i++)
        _a('mal-$i',
            unit: 'Einmaleins',
            competency: 'Einmaleins',
            correct: i >= 4,
            daysAgo: 20 - i),
    ], studentId: 'child-a', now: _now);
    expect(g.strengths.map((c) => c.competency),
        contains('Addition ohne Zehnerübergang'));
    expect(g.needs.first.competency, 'Subtraktion mit Zehnerübergang');
    expect(g.needs.first.independentCorrect, 1);
    expect(g.needs.first.independentAttempts, 6);
    final first = g.recommendations.first;
    expect(first.focus, PracticeFocus.guidedPractice);
    expect((first.subject, first.unit), ('Mathematik', 'Minus bis 100'));
    expect(first.guided, isTrue);
    expect(first.supportTip, contains('Zehner'));
    final mal = g.development.singleWhere((d) => d.competency == 'Einmaleins');
    expect((mal.earlierCorrect, mal.earlierTotal), (0, 4));
    expect((mal.recentCorrect, mal.recentTotal), (4, 4));
    expect(mal.changePoints, 100);
  });

  testWidgets(
      'Echter Navigationstest: „Mit Lumo gemeinsam üben“ öffnet genau das '
      'Lernmodul der Empfehlung', (tester) async {
    final app = (await tester.runAsync(() async =>
        LumoAppState(attemptLog: _Log(_child('child-a',
            reference: DateTime.now())))))!;
    addTearDown(app.dispose);
    await tester.runAsync(() async {
      app.updateSettings(AppSettings(
        voiceEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
        calmMode: true,
      ));
      app.update(app.state.copyWith(grade: 2, section: LumoSection.home));
      await app.school.setActiveStudent('child-a');
      await app.loadLearningProfile();
    });
    // Wurzel wie die App-Oberfläche: zeigt den Bereich aus dem App-Zustand.
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => AnimatedBuilder(
          animation: app,
          builder: (context, _) => Scaffold(
            body: Column(children: [
              Text('Bereich: ${app.state.section.name} · '
                  '${app.state.subject} · ${app.state.unit}'),
              TextButton(
                key: const ValueKey('open-parents'),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => LumoInsightDashboard(appState: app))),
                child: const Text('Elternbereich'),
              ),
            ]),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('open-parents')));
    await _frames(tester);
    final practice = find.byKey(const ValueKey('guidance-practice-0'));
    await tester.scrollUntilVisible(practice, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(find.byKey(const ValueKey('guidance-target-0')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('guidance-target-0'))).data,
        'Mathematik · Minus bis 100');
    await tester.tap(practice);
    await _frames(tester);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LumoInsightDashboard), findsNothing,
        reason: 'Elternbereich schließt, die App zeigt das Lernmodul');
    expect(app.state.section, LumoSection.exercises);
    expect(app.state.subject, 'Mathematik');
    expect(app.state.unit, 'Minus bis 100');
    expect(app.state.sessionKind, LumoSessionKind.tutoring);
    expect(find.text('Bereich: exercises · Mathematik · Minus bis 100'),
        findsOneWidget);
    // Das Modul existiert für die Schulstufe und liefert genau dieses Thema.
    final task = ExerciseFactory(seed: 7).nextExact(
        grade: app.state.grade, subject: 'Mathematik', unit: 'Minus bis 100');
    expect((task.subject, task.unit), ('Mathematik', 'Minus bis 100'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Thema ohne Übungsmodul in der Schulstufe: kein Start-Knopf',
      (tester) async {
    final g = LearningGuidance.fromAttempts(_child('child-a'),
        studentId: 'child-a', now: _now);
    var started = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LearningGuidancePanel(
                    guidance: g,
                    canPractice: (_) => false,
                    onPractice: (_) => started++)))));
    expect(find.byKey(const ValueKey('guidance-practice-0')), findsNothing);
    expect(find.textContaining('nicht im Übungsbereich'), findsWidgets);
    expect(started, 0);
  });

  testWidgets('Lehrkraft: Empfehlung wird mit Fach und Thema zugewiesen',
      (tester) async {
    final g = LearningGuidance.fromAttempts(_child('child-a'),
        studentId: 'child-a', now: _now);
    GuidanceRecommendation? assigned;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LearningGuidancePanel(
                    guidance: g, onAssign: (r) => assigned = r)))));
    expect(find.byKey(const ValueKey('guidance-practice-0')), findsNothing);
    final assign = find.byKey(const ValueKey('guidance-assign-0'));
    await tester.ensureVisible(assign);
    await tester.tap(assign);
    expect((assigned?.subject, assigned?.unit), ('Mathematik', 'Minus bis 100'));
  });

  testWidgets('Hilfestellung klappt auf und wieder zu', (tester) async {
    final g = LearningGuidance.fromAttempts(_child('child-a'),
        studentId: 'child-a', now: _now);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LearningGuidancePanel(guidance: g)))));
    expect(find.byKey(const ValueKey('guidance-help-0')), findsNothing);
    final toggle = find.byKey(const ValueKey('guidance-help-toggle-0'));
    await tester.ensureVisible(toggle);
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guidance-help-0')), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guidance-help-0')), findsNothing);
  });

  for (final (name, size) in [
    ('Fold außen', const Size(412, 892)),
    ('Fold innen', const Size(829, 690)),
    ('Fold innen quer', const Size(690, 829)),
    ('Tablet quer', const Size(1280, 800)),
  ]) {
    testWidgets('$name: große Schrift ohne Überlauf, Knöpfe ≥ 48 dp',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final g = LearningGuidance.fromAttempts([
        ..._child('child-a'),
        for (var i = 0; i < 8; i++)
          _a('mal-$i',
              unit: 'Einmaleins',
              competency: 'Einmaleins',
              correct: i >= 4,
              daysAgo: 20 - i),
      ], studentId: 'child-a', now: _now);
      for (final scale in [1.3, 2.0]) {
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                size: size,
                disableAnimations: true,
                textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LearningGuidancePanel(
                  guidance: g,
                  onPractice: (_) {},
                  onAssign: (_) {},
                ),
              ),
            ),
          ),
        ));
        await tester.tap(find.byKey(const ValueKey('guidance-help-toggle-0')));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$name ×$scale');
        for (final key in [
          'guidance-practice-0',
          'guidance-assign-0',
          'guidance-help-toggle-0',
        ]) {
          final s = tester.getSize(find.byKey(ValueKey(key)));
          expect(s.height, greaterThanOrEqualTo(48), reason: '$key $name');
          expect(s.width, greaterThanOrEqualTo(48), reason: '$key $name');
        }
      }
    });
  }
}
