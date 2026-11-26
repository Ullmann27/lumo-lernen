import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/backup/local_backup.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:lumo_lernen/features/settings/parent_report_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parent_insight_fixtures.dart';

/// Regression zu Heinz' Befund: Oben im Elternbereich standen vier Nullen,
/// während „Auf einen Blick“ 36 Antworten zeigte. Bilder entstehen nur mit
/// A6_CAPTURES=<Ordner>.
final _ziel = Platform.environment['A6_CAPTURES'];
const _rahmen = ValueKey('a6-capture');

class _GatedLog extends AttemptLogRepository {
  _GatedLog([this.gated = const {}]);
  final Set<String> gated;
  final gate = Completer<void>();
  bool fail = false;

  @override
  Future<List<Attempt>> load({String? studentId}) async {
    if (fail) throw StateError('Speicher gerade nicht lesbar');
    if (gated.contains(studentId)) await gate.future;
    return super.load(studentId: studentId);
  }
}

Future<void> _frames(WidgetTester tester, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

String _wert(WidgetTester tester, String kachel) => tester
    .widget<Text>(find.byKey(ValueKey('insight-stat-$kachel-value')))
    .data!;
String _hinweis(WidgetTester tester, String kachel) => tester
    .widget<Text>(find.byKey(ValueKey('insight-stat-$kachel-hint')))
    .data!;
String _grundlage(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('insight-stats-basis')))
    .data!;
List<String> _werte(WidgetTester tester) => [
      for (final k in ['answers', 'streak', 'strengths', 'needs'])
        _wert(tester, k),
    ];

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
    app.update(app.state.copyWith(grade: 2, childName: 'Mia'));
    await app.school.setActiveStudent(kind);
    await app.loadLearningProfile();
  });
  return app;
}

Future<void> _zeige(WidgetTester tester, LumoAppState app,
    {Size physisch = const Size(1080, 2340), bool warten = true}) async {
  tester.view.physicalSize = physisch;
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Nunito', useMaterial3: true),
    home: RepaintBoundary(
        key: _rahmen, child: LumoInsightDashboard(appState: app)),
  ));
  if (warten) await _frames(tester);
}

Future<void> _foto(WidgetTester tester, String name) async {
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
    final image = await boundary.toImage(pixelRatio: 2.625);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final datei = File('$_ziel/$name.png');
    await datei.parent.create(recursive: true);
    await datei.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _scrolleZu(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump(const Duration(milliseconds: 50));
  final y = tester.getTopLeft(find.byKey(key)).dy;
  await tester.drag(find.byType(Scrollable).first, Offset(0, -(y - 90)));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _aufnehmen(LumoAppState app, int anzahl,
    {int mitHilfe = 0}) async {
  for (var i = 0; i < anzahl; i++) {
    await app.recordLearningAnswer(
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      correct: i % 4 != 3,
      hintUsed: i < mitHilfe,
      prompt: '${8 + i % 5} + ${5 + i % 3}',
      requireSaved: true,
    );
  }
}

Future<void> _ende(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
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

  testWidgets('Leeres Profil: echte Null und „noch offen“', (tester) async {
    final app = await _app(tester, 'kind-leer');
    addTearDown(app.dispose);
    await _zeige(tester, app);
    expect(_werte(tester), ['0', '0', '–', '–']);
    expect(_hinweis(tester, 'answers'), 'noch keine');
    expect(_hinweis(tester, 'strengths'), 'noch offen');
    expect(_grundlage(tester), 'Noch keine Antworten in diesem Profil.');
    expect(find.byKey(const ValueKey('guidance-empty')), findsOneWidget);
    await _ende(tester);
  });

  for (final (geraet, physisch) in [
    ('fold_aussen_1080x2340', const Size(1080, 2340)),
    ('fold_innen_2176x1812', const Size(2176, 1812)),
  ]) {
    testWidgets('Befund 36 Antworten: Kacheln wie „Auf einen Blick“ · $geraet',
        (tester) async {
      await tester.runAsync(() =>
          AttemptLogRepository().appendAll(sechsunddreissigAntworten('kind-mia')));
      final app = await _app(tester, 'kind-mia');
      addTearDown(app.dispose);
      await _zeige(tester, app, physisch: physisch);
      // Vorher 0 · 0 T. · 0 · 0.
      expect(_werte(tester), ['36', '0', '1', '3']);
      expect(_hinweis(tester, 'answers'), '33 ohne Hilfe');
      expect(_hinweis(tester, 'streak'), 'zuletzt gestern');
      expect(_grundlage(tester),
          startsWith('Grundlage wie „Auf einen Blick“: 36 Antworten'));
      expect(
          find.text('Grundlage: 36 Antworten auf diesem Gerät, davon 33 ohne '
              'Hilfe.'),
          findsOneWidget);
      expect(
          find.textContaining(
              'Von 33 Antworten ohne Hilfe waren 23 richtig (70 %).'),
          findsOneWidget);
      expect(find.textContaining('Noch keine Antwortdaten'), findsNothing);
      final ki = tester.getSize(find.widgetWithText(FilledButton, 'KI fragen'));
      expect(ki.height, greaterThanOrEqualTo(48));
      expect(ki.width, greaterThanOrEqualTo(48));
      // Keine leere Themenübersicht neben 36 protokollierten Antworten.
      expect(find.text('Noch keine Daten'), findsNothing);
      await _foto(tester, 'eltern_kennzahlen_36__$geraet');
      if (geraet.startsWith('fold_aussen')) {
        await _scrolleZu(tester, const ValueKey('insight-lumo-says'));
        await _foto(tester, 'eltern_kennzahlen_36_lumo__$geraet');
      }
      await _ende(tester);
    });
  }

  testWidgets('Über die App aufgenommen: Zähler und Protokoll nie doppelt',
      (tester) async {
    final app = await _app(tester, 'kind-zaehler');
    addTearDown(app.dispose);
    await tester.runAsync(() => _aufnehmen(app, 36, mitHilfe: 3));
    expect(app.learningSkills().values.single.attempts, 36);
    await _zeige(tester, app);
    expect(_wert(tester, 'answers'), '36');
    expect(_hinweis(tester, 'answers'), '33 ohne Hilfe');
    expect(_wert(tester, 'streak'), '1');
    expect(_hinweis(tester, 'streak'), 'zuletzt heute');
    await _foto(tester, 'eltern_kennzahlen_app__fold_aussen_1080x2340');
    await _scrolleZu(tester, const ValueKey('insight-lumo-says'));
    await _foto(tester, 'eltern_kennzahlen_app_lumo__fold_aussen_1080x2340');
    await _ende(tester);
  });

  testWidgets('Hilfenutzung zählt als Antwort, nicht als Nachweis',
      (tester) async {
    final app = await _app(tester, 'kind-hilfe');
    addTearDown(app.dispose);
    await tester.runAsync(() => _aufnehmen(app, 6, mitHilfe: 4));
    await _zeige(tester, app);
    expect(_werte(tester), ['6', '1', '–', '–']);
    expect(_hinweis(tester, 'answers'), '2 ohne Hilfe');
    expect(find.textContaining('4 mit Hilfe zählen nicht als Nachweis.'),
        findsOneWidget);
    expect(_grundlage(tester), contains('ab 5 Antworten ohne Hilfe'));
    await _ende(tester);
  });

  testWidgets('Profilwechsel: keine Vermischung, auch nicht beim Laden',
      (tester) async {
    final log = _GatedLog({'kind-b'});
    addTearDown(() {
      if (!log.gate.isCompleted) log.gate.complete();
    });
    await tester.runAsync(() => log.appendAll([
          ...sechsunddreissigAntworten('kind-a'),
          antwort('kind-b', 'b1', 'Deutsch', 'Silben', 'Silben', true, 1),
          antwort('kind-b', 'b2', 'Deutsch', 'Silben', 'Silben', false, 1,
              hilfe: true),
        ]));
    final app = await _app(tester, 'kind-a', log: log);
    addTearDown(app.dispose);
    await _zeige(tester, app);
    expect(_wert(tester, 'answers'), '36');

    await tester.runAsync(() async {
      await app.school.setActiveStudent('kind-b');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    // B lädt noch: weder A's Zahlen noch eine falsche Null.
    expect(_werte(tester), ['…', '…', '…', '…']);
    expect(find.text('36'), findsNothing);
    expect(_grundlage(tester), 'Kennzahlen werden geladen …');

    await tester.runAsync(() async => log.gate.complete());
    await _frames(tester);
    expect(_werte(tester), ['2', '0', '–', '–']);
    expect(_hinweis(tester, 'answers'), '1 ohne Hilfe');
    expect(find.text('36'), findsNothing);

    await tester.runAsync(() async {
      await app.school.setActiveStudent('kind-a');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    expect(_werte(tester), ['36', '0', '1', '3']);
    await _ende(tester);
  });

  testWidgets('App-Neustart: Kennzahlen bleiben erhalten', (tester) async {
    final erste = await _app(tester, 'kind-neu');
    await tester.runAsync(() => _aufnehmen(erste, 5, mitHilfe: 2));
    erste.dispose();

    // Neue App-Instanz über demselben Speicher, ohne erneute Profilwahl.
    final zweite =
        (await tester.runAsync(() async => LumoAppState()))!;
    addTearDown(zweite.dispose);
    await tester.runAsync(() => zweite.loadLearningProfile());
    await _zeige(tester, zweite);
    expect(_wert(tester, 'answers'), '5');
    expect(_hinweis(tester, 'answers'), '3 ohne Hilfe');
    expect(_wert(tester, 'streak'), '1');
    await _ende(tester);
  });

  testWidgets(
      'Datensicherung: Wiederherstellung zählt gleich, alte Sicherung ohne '
      'Protokoll bleibt gültig', (tester) async {
    final app = await _app(tester, 'kind-sicher');
    await tester.runAsync(() => _aufnehmen(app, 5, mitHilfe: 1));
    final backup = (await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      return LocalBackup.create(preferences: {
        for (final key in prefs.getKeys())
          if (prefs.get(key) != null) key: prefs.get(key)!,
      }, nativeFiles: const []);
    }))!;
    app.dispose();
    expect(backup.preferences.containsKey('lumo_attempt_log_v1'), isTrue);

    // Wiederhergestellt: dieselben Zahlen.
    SharedPreferences.setMockInitialValues(backup.preferences);
    final neu = (await tester.runAsync(() async => LumoAppState()))!;
    await tester.runAsync(() => neu.loadLearningProfile());
    await _zeige(tester, neu);
    expect(_wert(tester, 'answers'), '5');
    expect(_hinweis(tester, 'answers'), '4 ohne Hilfe');
    await _ende(tester);
    neu.dispose();

    // Sicherung aus der Zeit vor dem Aufgabenprotokoll: nur Zähler.
    SharedPreferences.setMockInitialValues({
      for (final e in backup.preferences.entries)
        if (e.key != 'lumo_attempt_log_v1') e.key: e.value,
    });
    final alt = (await tester.runAsync(() async => LumoAppState()))!;
    addTearDown(alt.dispose);
    await tester.runAsync(() => alt.loadLearningProfile());
    await _zeige(tester, alt);
    expect(_werte(tester), ['5', '1', '–', '–']);
    expect(_hinweis(tester, 'answers'), 'ältere, ohne Datum');
    expect(_grundlage(tester), contains('5 ältere Antworten ohne Datum'));
    expect(find.text('Noch keine protokollierten Antworten. Sobald geübt '
        'wurde, steht hier, was gerade geübt wird und wobei Unterstützung '
        'hilft.'), findsOneWidget);
    await _foto(tester, 'eltern_kennzahlen_alte_sicherung__fold_aussen_1080x2340');
    await _ende(tester);
  });

  testWidgets('Elternbericht: geladener Lernstand ohne Unvollständig-Hinweis',
      (tester) async {
    final app = await _app(tester, 'kind-bericht');
    addTearDown(app.dispose);
    await tester.runAsync(() => _aufnehmen(app, 3));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ParentReportCard(appState: app)))));
    await _frames(tester);
    expect(app.learningProfileLoaded, isTrue);
    expect(find.text('Elternbericht'), findsOneWidget);
    expect(find.byKey(const ValueKey('parent-report-not-loaded')), findsNothing);
    await _ende(tester);
  });

  testWidgets('Daten noch nicht geladen: „…“ statt 0, Lesefehler mit Erneut',
      (tester) async {
    final log = _GatedLog({'kind-l'});
    addTearDown(() {
      if (!log.gate.isCompleted) log.gate.complete();
    });
    await tester.runAsync(
        () => log.appendAll(sechsunddreissigAntworten('kind-l')));
    final app = await _app(tester, 'kind-l', log: log);
    addTearDown(app.dispose);
    await _zeige(tester, app);
    expect(_werte(tester), ['…', '…', '…', '…']);
    expect(_hinweis(tester, 'answers'), 'wird geladen');
    expect(_grundlage(tester), 'Kennzahlen werden geladen …');
    await _foto(tester, 'eltern_kennzahlen_laedt__fold_aussen_1080x2340');
    await tester.runAsync(() async => log.gate.complete());
    await _frames(tester);
    expect(_werte(tester), ['36', '0', '1', '3']);

    // Speicher nicht lesbar: kein leeres Profil vortäuschen.
    log.fail = true;
    await tester.runAsync(() async => app.loadLearningProfile());
    await _frames(tester);
    expect(_werte(tester), ['–', '–', '–', '–']);
    expect(_hinweis(tester, 'answers'), 'nicht geladen');
    expect(_grundlage(tester),
        'Die Kennzahlen konnten nicht sicher geladen werden.');
    final retry = find.byKey(const ValueKey('insight-retry'));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    log.fail = false;
    await tester.tap(retry);
    await _frames(tester);
    expect(_werte(tester), ['36', '0', '1', '3']);
    await _ende(tester);
  });
}
