import 'dart:async';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parent_insight_fixtures.dart';

/// Sichert die Semantik, die die Android-Probe
/// `.github/probes/lumo_parent_insight_android_probe.py` liest: je Kachel
/// Bezeichner `insight-stat-<kachel>` (Android: resource-id) und Beschriftung
/// „<Name>: <Wert>, <Hinweis>“ (Android: content-desc), dazu die
/// Grundlage-Zeile `insight-stats-basis`.
///
/// Mit A6_HIERARCHY=<Ordner> schreibt der Test die Flutter-Semantik zusätzlich
/// als uiautomator-ähnliche XML-Datei. Diese Dateien sind SYNTHETISCH (kein
/// Android-Nachweis) und dienen nur als Eingabe der Python-Unit-Tests unter
/// tools/android_qa/tests/.
final _hierarchyDir = Platform.environment['A6_HIERARCHY'];
const _package = 'dev.ullmann.lumo.lumo_lernen.coachpreview';
// pixel_5 des CI-Emulators: 1080 × 2340 px bei 440 dpi.
const _physical = Size(1080, 2340);
const _dpr = 2.75;

class _GatedLog extends AttemptLogRepository {
  final gate = Completer<void>();

  @override
  Future<List<Attempt>> load({String? studentId}) async {
    await gate.future;
    return super.load(studentId: studentId);
  }
}

Future<void> _frames(WidgetTester tester, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<LumoAppState> _app(WidgetTester tester, String kind,
    {AttemptLogRepository? log}) async {
  final app = (await tester.runAsync(
      () async => LumoAppState(attemptLog: log ?? AttemptLogRepository())))!;
  await tester.runAsync(() async {
    app.updateSettings(AppSettings(
      voiceEnabled: false,
      aiProxyEnabled: false,
      reduceAnimations: true,
      calmMode: true,
    ));
    app.update(app.state.copyWith(grade: 1, childName: 'LumoTest'));
    await app.school.setActiveStudent(kind);
    await app.loadLearningProfile();
  });
  return app;
}

Future<void> _zeige(WidgetTester tester, LumoAppState app) async {
  tester.view.physicalSize = _physical;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Nunito', useMaterial3: true),
    home: LumoInsightDashboard(appState: app),
  ));
  await _frames(tester);
}

SemanticsNode _kachel(WidgetTester tester, String key) =>
    tester.getSemantics(find.byKey(ValueKey('insight-stat-$key')));

String _xml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('\n', '&#10;');

void _node(SemanticsNode node, Matrix4 parent, StringBuffer out, int index) {
  final transform =
      node.transform == null ? parent : (parent.clone()..multiply(node.transform!));
  final rect = MatrixUtils.transformRect(transform, node.rect);
  final data = node.getSemanticsData();
  final flags = data.flagsCollection;
  final scroll = data.hasAction(SemanticsAction.scrollUp) ||
      data.hasAction(SemanticsAction.scrollDown);
  out.write('<node index="$index" text="" '
      'resource-id="${_xml(data.identifier)}" '
      'class="${flags.isButton ? 'android.widget.Button' : scroll ? 'android.widget.ScrollView' : 'android.view.View'}" '
      'package="$_package" content-desc="${_xml(data.label)}" '
      'checkable="false" checked="false" '
      'clickable="${data.hasAction(SemanticsAction.tap)}" '
      'enabled="${flags.isEnabled != Tristate.isFalse}" '
      'focusable="false" focused="false" scrollable="$scroll" '
      'long-clickable="false" password="false" selected="false" '
      'visible-to-user="${!flags.isHidden}" '
      'bounds="[${rect.left.round()},${rect.top.round()}]'
      '[${rect.right.round()},${rect.bottom.round()}]">');
  var child = 0;
  node.visitChildren((c) {
    _node(c, transform, out, child++);
    return true;
  });
  out.write('</node>');
}

/// Flutter-Semantik als uiautomator-ähnliche Hierarchie (synthetisch).
Future<void> _hierarchie(WidgetTester tester, String name) async {
  final dir = _hierarchyDir;
  if (dir == null) return;
  var root = tester.getSemantics(find.byType(LumoInsightDashboard));
  while (root.parent != null) {
    root = root.parent!;
  }
  final out = StringBuffer()
    ..write("<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>")
    ..write('<!-- SYNTHETISCH: aus dem Flutter-Widget-Test '
        'test/parents/lumo_insight_semantics_test.dart abgeleitet '
        '(Flutter-Semantik, pixel_5-Maße). Kein Android-Nachweis. -->')
    ..write('<hierarchy rotation="0">');
  _node(root, Matrix4.identity(), out, 0);
  out.write('</hierarchy>\n');
  final file = File('$dir/$name.xml');
  await tester.runAsync(() async {
    await file.parent.create(recursive: true);
    await file.writeAsString(out.toString());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Kacheln und Grundlage tragen stabile Bezeichner', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() =>
        AttemptLogRepository().appendAll(sechsunddreissigAntworten('kind-mia')));
    final app = await _app(tester, 'kind-mia');
    addTearDown(app.dispose);
    await _zeige(tester, app);

    final erwartet = {
      'answers': 'Antworten: 36, 33 ohne Hilfe',
      'streak': 'Lerntage in Folge: 0, zuletzt gestern',
      'strengths': 'Stärken: 1, ab 85 % ohne Hilfe',
      'needs': 'Förderbedarf: 3, unter 85 % ohne Hilfe',
    };
    for (final e in erwartet.entries) {
      final node = _kachel(tester, e.key);
      expect(node.identifier, 'insight-stat-${e.key}');
      expect(node.label, e.value);
    }
    final basis = tester.getSemantics(find.byKey(const ValueKey('insight-stats-basis')));
    expect(basis.identifier, 'insight-stats-basis');
    expect(
        basis.label,
        'Grundlage wie „Auf einen Blick“: 36 Antworten im Aufgabenprotokoll '
        'dieses Profils, davon 33 ohne Hilfe.');
    // Die Zeile aus „Auf einen Blick“, die die Probe vergleicht.
    expect(
        find.bySemanticsLabel(RegExp(
            r'Grundlage: 36 Antworten auf diesem Gerät, davon 33 ohne Hilfe\.')),
        findsOneWidget);
    await _hierarchie(tester, 'insight_36_antworten');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    semantics.dispose();
  });

  testWidgets('Leeres Profil: Bezeichner mit echter Null', (tester) async {
    final semantics = tester.ensureSemantics();
    final app = await _app(tester, 'kind-leer');
    addTearDown(app.dispose);
    await _zeige(tester, app);
    expect(_kachel(tester, 'answers').label, 'Antworten: 0, noch keine');
    expect(_kachel(tester, 'strengths').label, 'Stärken: –, noch offen');
    expect(
        tester
            .getSemantics(find.byKey(const ValueKey('insight-stats-basis')))
            .label,
        'Noch keine Antworten in diesem Profil.');
    await _hierarchie(tester, 'insight_leer');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    semantics.dispose();
  });

  testWidgets('Ladezustand: Bezeichner mit „…“ statt 0', (tester) async {
    final semantics = tester.ensureSemantics();
    final log = _GatedLog();
    addTearDown(() {
      if (!log.gate.isCompleted) log.gate.complete();
    });
    final app = await _app(tester, 'kind-l', log: log);
    addTearDown(app.dispose);
    await _zeige(tester, app);
    for (final key in ['answers', 'streak', 'strengths', 'needs']) {
      expect(_kachel(tester, key).label, endsWith(': …, wird geladen'));
    }
    await _hierarchie(tester, 'insight_laedt');
    log.gate.complete();
    await _frames(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    semantics.dispose();
  });
}
