import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/features/report/lumo_coach_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _card = ValueKey('lumo-coach-card');
const _start = ValueKey('lumo-coach-start');

class _LogRead {
  _LogRead(this.studentId);
  final String? studentId;
  final result = Completer<List<Attempt>>();
}

class _DelayedLog extends AttemptLogRepository {
  final reads = <_LogRead>[];

  @override
  Future<List<Attempt>> load({String? studentId}) {
    final read = _LogRead(studentId);
    reads.add(read);
    return read.result.future;
  }

  void completeFor(String studentId, List<Attempt> attempts) {
    for (final read in reads) {
      if (read.studentId == studentId && !read.result.isCompleted) {
        read.result.complete(attempts);
      }
    }
  }

  void finish() {
    for (final read in reads) {
      if (!read.result.isCompleted) read.result.complete(const []);
    }
  }
}

class _CoachApp extends LumoAppState {
  _CoachApp(AttemptLogRepository log) : super(attemptLog: log);

  Completer<void>? nextCaptureGate;

  @override
  Future<LearningProfileLease> captureLearningProfile() {
    final gate = nextCaptureGate;
    nextCaptureGate = null;
    final owner = super.captureLearningProfile();
    if (gate == null) return owner;
    return owner.then((value) async {
      await gate.future;
      return value;
    });
  }

  void refresh() => notifyListeners();
}

List<Attempt> _weak(
  String studentId, {
  String subject = 'Mathematik',
  String unit = 'Plus bis 20',
  String competency = 'Addition',
}) =>
    [
      for (var i = 0; i < 6; i++)
        Attempt(
          id: '$studentId-$subject-$unit-$i',
          studentId: studentId,
          subject: subject,
          unit: unit,
          competency: competency,
          correct: false,
          at: DateTime.now().subtract(Duration(minutes: i)),
        ),
    ];

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<_CoachApp> _ready(
  WidgetTester tester,
  _DelayedLog log, {
  String studentId = 'child-a',
}) async {
  late final _CoachApp app;
  await tester.runAsync(() async {
    app = _CoachApp(log);
    app.updateSettings(AppSettings(
      voiceEnabled: false,
      aiProxyEnabled: false,
      reduceAnimations: true,
      calmMode: true,
    ));
    await app.school.setActiveStudent(studentId);
    await app.loadLearningProfile();
  });
  return app;
}

Future<void> _select(
    WidgetTester tester, _CoachApp app, String studentId) async {
  await tester.runAsync(() async {
    await app.school.setActiveStudent(studentId);
    await app.loadLearningProfile();
  });
  await _frames(tester);
}

Future<void> _show(WidgetTester tester, _CoachApp app,
    List<(String, String)> routes) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: LumoCoachCard(
        appState: app,
        onStart: (subject, unit) => routes.add((subject, unit)),
      ),
    ),
  ));
  await _frames(tester);
}

Future<void> _close(WidgetTester tester, List<_CoachApp> apps,
    List<_DelayedLog> logs) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (final log in logs) {
    log.finish();
  }
  await _frames(tester);
  for (final app in apps) {
    app.dispose();
  }
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('late answers from the previous child cannot replace the coach',
      (tester) async {
    final log = _DelayedLog();
    final app = await _ready(tester, log);
    final routes = <(String, String)>[];
    await _show(tester, app, routes);
    expect(log.reads.last.studentId, 'child-a');

    await _select(tester, app, 'child-b');
    log.completeFor(
      'child-b',
      _weak('child-b', subject: 'Deutsch', unit: 'Wörter', competency: 'Silben'),
    );
    await _frames(tester);
    expect(find.textContaining('Silben'), findsOneWidget);

    log.completeFor('child-a', _weak('child-a'));
    await _frames(tester);
    expect(find.textContaining('Addition'), findsNothing);
    expect(find.textContaining('Silben'), findsOneWidget);
    await tester.tap(find.byKey(_start));
    expect(routes, [('Deutsch', 'Wörter')]);
    await _close(tester, [app], [log]);
  });

  testWidgets('profile switch hides cached advice and rejects an old tap',
      (tester) async {
    final log = _DelayedLog();
    final app = await _ready(tester, log);
    final routes = <(String, String)>[];
    await _show(tester, app, routes);
    log.completeFor('child-a', _weak('child-a'));
    await _frames(tester);
    final oldTap = tester.widget<InkWell>(find.byKey(_start)).onTap!;

    await _select(tester, app, 'child-b');
    expect(find.byKey(_card), findsNothing);
    oldTap();
    expect(routes, isEmpty);

    log.completeFor(
      'child-b',
      _weak('child-b', subject: 'Deutsch', unit: 'Wörter', competency: 'Silben'),
    );
    await _frames(tester);
    oldTap();
    expect(routes, isEmpty);
    await tester.tap(find.byKey(_start));
    expect(routes, [('Deutsch', 'Wörter')]);
    await _close(tester, [app], [log]);
  });

  testWidgets('a delayed profile lease never starts an obsolete log read',
      (tester) async {
    final log = _DelayedLog();
    final app = await _ready(tester, log);
    final gate = Completer<void>();
    app.nextCaptureGate = gate;
    final routes = <(String, String)>[];
    await _show(tester, app, routes);
    expect(log.reads, isEmpty);

    await _select(tester, app, 'child-b');
    log.completeFor(
      'child-b',
      _weak('child-b', subject: 'Deutsch', unit: 'Wörter', competency: 'Silben'),
    );
    await _frames(tester);
    gate.complete();
    await _frames(tester);

    expect(log.reads.every((read) => read.studentId == 'child-b'), isTrue);
    expect(find.textContaining('Silben'), findsOneWidget);
    await tester.tap(find.byKey(_start));
    expect(routes, [('Deutsch', 'Wörter')]);
    await _close(tester, [app], [log]);
  });

  testWidgets('app replacement rebinds the listener even at equal generation',
      (tester) async {
    final firstLog = _DelayedLog();
    final first = await _ready(tester, firstLog);
    final secondLog = _DelayedLog();
    final second = await _ready(tester, secondLog, studentId: 'child-b');
    expect(first.profileGeneration, second.profileGeneration);
    final routes = <(String, String)>[];

    await _show(tester, first, routes);
    firstLog.completeFor('child-a', _weak('child-a'));
    await _frames(tester);
    final oldTap = tester.widget<InkWell>(find.byKey(_start)).onTap!;
    first.refresh();
    await _frames(tester);
    final oldReadCount = firstLog.reads.length;

    await _show(tester, second, routes);
    expect(find.byKey(_card), findsNothing);
    oldTap();
    expect(routes, isEmpty);
    secondLog.completeFor(
      'child-b',
      _weak('child-b', subject: 'Deutsch', unit: 'Wörter', competency: 'Silben'),
    );
    await _frames(tester);
    firstLog.completeFor('child-a', _weak('child-a'));
    first.refresh();
    await _frames(tester);

    expect(firstLog.reads.length, oldReadCount);
    expect(find.textContaining('Addition'), findsNothing);
    expect(find.textContaining('Silben'), findsOneWidget);
    oldTap();
    expect(routes, isEmpty);
    await tester.tap(find.byKey(_start));
    expect(routes, [('Deutsch', 'Wörter')]);
    await _close(tester, [first, second], [firstLog, secondLog]);
  });

  testWidgets('only the latest request may update the same profile',
      (tester) async {
    final log = _DelayedLog();
    final app = await _ready(tester, log);
    final routes = <(String, String)>[];
    await _show(tester, app, routes);
    final older = log.reads.last;
    app.refresh();
    await _frames(tester);
    final newer = log.reads.last;
    expect(identical(older, newer), isFalse);

    newer.result.complete(_weak('child-a', unit: 'Minus bis 20'));
    await _frames(tester);
    older.result.complete(_weak('child-a', unit: 'Plus bis 20'));
    await _frames(tester);
    await tester.tap(find.byKey(_start));
    expect(routes, [('Mathematik', 'Minus bis 20')]);
    await _close(tester, [app], [log]);
  });

  for (final target in [('Mathematik', 'Minus bis 20'), ('Deutsch', 'Plus bis 20')]) {
    testWidgets('identical message text refreshes route to $target',
        (tester) async {
      final log = _DelayedLog();
      final app = await _ready(tester, log);
      final routes = <(String, String)>[];
      await _show(tester, app, routes);
      log.completeFor('child-a', _weak('child-a', competency: 'Schrittfolge'));
      await _frames(tester);
      final before = tester.widget<Text>(find.textContaining('Schrittfolge')).data;
      final oldTap = tester.widget<InkWell>(find.byKey(_start)).onTap!;

      app.refresh();
      await _frames(tester);
      log.completeFor(
        'child-a',
        _weak('child-a',
            subject: target.$1, unit: target.$2, competency: 'Schrittfolge'),
      );
      await _frames(tester);
      expect(tester.widget<Text>(find.textContaining('Schrittfolge')).data, before);
      oldTap();
      expect(routes, isEmpty);
      await tester.tap(find.byKey(_start));
      expect(routes, [target]);
      await _close(tester, [app], [log]);
    });
  }

  testWidgets('an old failure is ignored and a latest failure clears the route',
      (tester) async {
    final log = _DelayedLog();
    final app = await _ready(tester, log);
    final routes = <(String, String)>[];
    await _show(tester, app, routes);
    final older = log.reads.last;
    app.refresh();
    await _frames(tester);
    log.reads.last.result.complete(_weak('child-a', unit: 'Minus bis 20'));
    await _frames(tester);
    final lastTap = tester.widget<InkWell>(find.byKey(_start)).onTap!;

    older.result.completeError(StateError('obsolete read failed'));
    await _frames(tester);
    expect(find.byKey(_card), findsOneWidget);
    await tester.tap(find.byKey(_start));
    expect(routes, [('Mathematik', 'Minus bis 20')]);

    app.refresh();
    await _frames(tester);
    log.reads.last.result.completeError(StateError('current read failed'));
    await _frames(tester);
    expect(find.byKey(_card), findsNothing);
    lastTap();
    expect(routes, [('Mathematik', 'Minus bis 20')]);
    await _close(tester, [app], [log]);
  });

  testWidgets('completion after disposal does not update a detached coach',
      (tester) async {
    final log = _DelayedLog();
    final app = await _ready(tester, log);
    final routes = <(String, String)>[];
    await _show(tester, app, routes);
    await tester.pumpWidget(const SizedBox.shrink());
    log.completeFor('child-a', _weak('child-a'));
    await _frames(tester);
    expect(find.byKey(_card), findsNothing);
    expect(routes, isEmpty);
    await _close(tester, [app], [log]);
  });
}
