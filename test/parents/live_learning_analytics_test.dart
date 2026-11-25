import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_chart_data.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:lumo_lernen/features/report/learning_analytics_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 25, 12);

Attempt _answer(int n, {
  String student = 'child-a',
  bool correct = true,
  DateTime? reference,
}) =>
    Attempt(
      id: '$student-$n',
      studentId: student,
      subject: n.isEven ? 'Mathematik' : 'Deutsch',
      unit: 'Üben',
      competency: 'Kompetenz ${n % 3}',
      correct: correct,
      at: (reference ?? _now).subtract(Duration(days: n)),
    );

Future<void> _frames(WidgetTester tester) async {
  for (var index = 0; index < 20; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Empty live charts never fall back to example percentages',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LearningAnalyticsPanel(
          data: LearningChartData.fromAttempts(
              [], studentId: 'child-a', now: _now),
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('live-learning-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('live-learning-summary')), findsNothing);
    expect(find.text('Kompetenz-Radar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 840.0]) {
    testWidgets('Live charts fit width $width with large text', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 960);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final data = LearningChartData.fromAttempts(
        [for (var i = 0; i < 12; i++) _answer(i, correct: i < 3)],
        studentId: 'child-a',
        now: _now,
      );
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 960),
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LearningAnalyticsPanel(data: data),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('12 protokollierte Antworten · 3 richtig · 25 %'),
          findsOneWidget);
      expect(find.text('Kompetenz-Radar'), findsOneWidget);
      expect(find.textContaining('keine Antworten'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Delayed live data from a previous child cannot enter the dashboard',
      (tester) async {
    final log = _DelayedLog();
    addTearDown(() {
      if (!log.firstGate.isCompleted) log.firstGate.complete();
    });
    final app = (await tester.runAsync(
        () async => LumoAppState(attemptLog: log)))!;
    addTearDown(app.dispose);
    await tester.runAsync(() async {
      app.updateSettings(AppSettings(
        voiceEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
        calmMode: true,
      ));
      await app.school.setActiveStudent('child-a');
      await app.loadLearningProfile();
    });
    await tester.pumpWidget(MaterialApp(
        home: LumoInsightDashboard(appState: app)));
    await _frames(tester);
    expect(find.byKey(const ValueKey('live-learning-summary')), findsNothing);

    await tester.runAsync(() async {
      await app.school.setActiveStudent('child-b');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    expect(find.text('1 protokollierte Antworten · 0 richtig · 0 %'),
        findsOneWidget);

    await tester.runAsync(() async => log.firstGate.complete());
    await _frames(tester);
    expect(find.text('1 protokollierte Antworten · 0 richtig · 0 %'),
        findsOneWidget);
    expect(find.text('7 protokollierte Antworten · 7 richtig · 100 %'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _DelayedLog extends AttemptLogRepository {
  final firstGate = Completer<void>();

  @override
  Future<List<Attempt>> load({String? studentId}) async {
    if (studentId == 'child-a') {
      await firstGate.future;
      return [for (var i = 0; i < 7; i++)
        _answer(i, reference: DateTime.now().subtract(const Duration(days: 1)))];
    }
    return [_answer(0, student: 'child-b', correct: false,
        reference: DateTime.now().subtract(const Duration(days: 1)))];
  }
}
