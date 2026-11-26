import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:lumo_lernen/features/teacher/teacher_student_screen.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_class_data.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_homework.dart';
import 'package:lumo_lernen/features/teacher_demo/homework_runner_screen.dart';
import 'package:lumo_lernen/features/teacher_demo/teacher_demo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abnahmebilder Eltern- und Lehrkräftebereich (Fold7 außen 1080×2340, innen
/// 2176×1812). Dateien entstehen nur mit A3_CAPTURES=<Ordner>; ohne die
/// Variable prüft der Test nur fehlerfreies Rendern. Alle Antworten sind
/// Testdaten eines Testkindes, keine Beispielzahlen in der App.
final _ziel = Platform.environment['A3_CAPTURES'];
const _rahmen = ValueKey('a3-capture');

class _Log extends AttemptLogRepository {
  _Log(this.attempts);
  final List<Attempt> attempts;
  @override
  Future<List<Attempt>> load({String? studentId}) async => [
        for (final a in attempts)
          if (studentId == null || a.studentId == studentId) a,
      ];
}

List<Attempt> _antworten(String kind) {
  final jetzt = DateTime.now();
  Attempt a(String id, String subject, String unit, String comp, bool ok,
          int tage, {bool hilfe = false}) =>
      Attempt(
        id: '$kind-$id',
        studentId: kind,
        subject: subject,
        unit: unit,
        competency: comp,
        correct: ok,
        hintUsed: hilfe,
        durationMs: 9000 + id.hashCode % 9000,
        at: jetzt.subtract(Duration(days: tage, minutes: id.hashCode % 300)),
      );
  return [
    for (var i = 0; i < 12; i++)
      a('p$i', 'Mathematik', 'Plus bis 20', 'Addition ohne Zehnerübergang',
          i != 3, 1 + i % 5),
    for (var i = 0; i < 7; i++)
      a('m$i', 'Mathematik', 'Minus bis 100', 'Subtraktion mit Zehnerübergang',
          i == 2 || i == 5, 1 + i % 3),
    for (var i = 0; i < 3; i++)
      a('mh$i', 'Mathematik', 'Minus bis 100', 'Subtraktion mit Zehnerübergang',
          true, 2, hilfe: true),
    for (var i = 0; i < 8; i++)
      a('e$i', 'Mathematik', 'Einmaleins', 'Einmaleins', i >= 3, 20 - i * 2),
    for (var i = 0; i < 6; i++)
      a('s$i', 'Deutsch', 'Silben', 'Silben', i != 1, 3 + i),
  ];
}

Future<void> _frames(WidgetTester tester, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _foto(WidgetTester tester, String name, double dpr) async {
  expect(tester.takeException(), isNull, reason: name);
  if (_ziel == null) return;
  await tester.runAsync(() async {
    await Future.wait(find.byType(Image).evaluate().map(
        (e) => precacheImage((e.widget as Image).image, e)));
  });
  await tester.pump(const Duration(milliseconds: 50));
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_rahmen));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final datei = File('$_ziel/$name.png');
    await datei.parent.create(recursive: true);
    await datei.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _scrolleZu(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  // Abschnitt oben ausrichten.
  final y = tester.getTopLeft(finder).dy;
  await tester.drag(find.byType(Scrollable).first, Offset(0, -(y - 90)));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (geraet, physisch) in [
    ('fold_aussen_1080x2340', const Size(1080, 2340)),
    ('fold_innen_2176x1812', const Size(2176, 1812)),
  ]) {
    Future<LumoAppState> app(WidgetTester tester, String kind) async {
      final state = (await tester.runAsync(
          () async => LumoAppState(attemptLog: _Log(_antworten(kind)))))!;
      await tester.runAsync(() async {
        state.updateSettings(AppSettings(
          voiceEnabled: false,
          aiProxyEnabled: false,
          reduceAnimations: true,
          calmMode: true,
        ));
        state.update(state.state.copyWith(grade: 2, childName: 'Mia'));
        await state.school.setActiveStudent(kind);
        await state.loadLearningProfile();
      });
      return state;
    }

    Future<void> zeige(WidgetTester tester, Widget seite) async {
      const dpr = 2.625;
      tester.view.physicalSize = physisch;
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Nunito', useMaterial3: true),
        home: RepaintBoundary(key: _rahmen, child: seite),
      ));
      await _frames(tester);
    }

    testWidgets('Eltern · $geraet', (tester) async {
      final state = await app(tester, 'kind-mia');
      addTearDown(state.dispose);
      await zeige(tester, LumoInsightDashboard(appState: state));
      await _foto(tester, 'eltern_1_oben__$geraet', 2.625);
      for (final (name, key) in [
        ('eltern_2_ueberblick', 'learning-guidance'),
        ('eltern_3_lernplan', 'guidance-plan'),
        ('eltern_4_entwicklung', 'guidance-development'),
      ]) {
        if (find.byKey(ValueKey(key)).evaluate().isEmpty &&
            key != 'learning-guidance') {
          continue;
        }
        if (key == 'learning-guidance' &&
            find.byKey(ValueKey(key)).evaluate().isEmpty) {
          await _scrolleZu(tester, const ValueKey('live-learning-analytics'));
        } else {
          await _scrolleZu(tester, ValueKey(key));
        }
        if (key == 'guidance-plan') {
          await tester.tap(
              find.byKey(const ValueKey('guidance-help-toggle-0')));
          await _frames(tester, 20);
        }
        await _foto(tester, '${name}__$geraet', 2.625);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Hausaufgaben · $geraet', (tester) async {
      final store = DemoHomeworkStore();
      await zeige(tester, TeacherDemoScreen(store: store));
      await tester.tap(find.text('Hausaufgaben'));
      await _frames(tester);
      final deutsch = find.byKey(const ValueKey('homework-subject-Deutsch'));
      if (deutsch.evaluate().isNotEmpty) {
        await tester.tap(deutsch);
        await _frames(tester, 20);
        await tester.tap(find.byKey(const ValueKey('homework-grade-3')));
        await _frames(tester, 20);
      }
      await _foto(tester, 'hausaufgabe_1_gestalten__$geraet', 2.625);
      final child = demoChildren.first;
      final hw = DemoHomework(
        id: 'hw-bild',
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        count: 2,
        due: DateTime.now().add(const Duration(days: 2)),
        note: 'Rechne in Ruhe.',
        studentIds: [child.id],
        createdAt: DateTime.now(),
      );
      await zeige(tester,
          HomeworkRunnerScreen(homework: hw, child: child, store: store));
      final hilfe = find.byKey(const ValueKey('homework-hint'));
      if (hilfe.evaluate().isNotEmpty) {
        await tester.tap(hilfe);
        await _frames(tester, 20);
      }
      await _foto(tester, 'hausaufgabe_2_kind_hilfe__$geraet', 2.625);
      for (final t in hw.tasksFor(child.id, grade: child.grade)) {
        final c = find.byKey(ValueKey('homework-choice-${t.answer}'));
        if (c.evaluate().isEmpty) break;
        await tester.tap(c.first);
        await _frames(tester, 70);
      }
      await _frames(tester, 40);
      await _foto(tester, 'hausaufgabe_3_geschafft__$geraet', 2.625);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Lehrkraft · $geraet', (tester) async {
      final state = (await tester.runAsync(
          () async => LumoAppState(attemptLog: _Log(const []))))!;
      addTearDown(state.dispose);
      final ids = (await tester.runAsync(() async {
        final mitKlasse = await state.school.addClass('2a', 2);
        final klasse = mitKlasse.classes.last.id;
        final mitKind = await state.school.addStudent(klasse, 'Mia');
        return (klasse, mitKind.students.last.id);
      }))!;
      final mitDaten = (await tester.runAsync(() async =>
          LumoAppState(attemptLog: _Log(_antworten(ids.$2)))))!;
      addTearDown(mitDaten.dispose);
      await zeige(
          tester,
          TeacherStudentScreen(
              appState: mitDaten, studentId: ids.$2, classId: ids.$1));
      await _frames(tester);
      await _foto(tester, 'lehrkraft_1_oben__$geraet', 2.625);
      if (find.byKey(const ValueKey('guidance-plan')).evaluate().isNotEmpty) {
        await _scrolleZu(tester, const ValueKey('guidance-plan'));
        await _foto(tester, 'lehrkraft_2_lernplan__$geraet', 2.625);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
