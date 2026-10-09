// Widget-Tests des Lumo Knobel-Tests: alle sechs Rätselarten, kompletter
// Durchlauf durch Antippen, Speichern, Protokoll, Belohnung, Rückblick,
// Zurück-Dialog, Bedienbarkeit und reduzierte Bewegung. Feste Seeds, feste Uhr.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/iq/iq_puzzle_generator.dart';
import 'package:lumo_lernen/core/iq/iq_test_repository.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';
import 'package:lumo_lernen/features/tests/iq/iq_puzzle_view.dart';
import 'package:lumo_lernen/features/tests/iq/iq_result_view.dart';
import 'package:lumo_lernen/features/tests/iq/iq_review_view.dart';
import 'package:lumo_lernen/features/tests/iq/iq_reward.dart';
import 'package:lumo_lernen/features/tests/iq/iq_start_view.dart';
import 'package:lumo_lernen/features/tests/iq/iq_style.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/tests/iq/iq_tests_card.dart';
import 'package:lumo_lernen/features/tests/iq_test_screen.dart';
import 'package:lumo_lernen/features/tests/lumo_tests_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_motion.dart';

import 'iq_test_support.dart';

const _repository = IqTestRepository();

const _phone = Size(412, 915);
const _fold = Size(690, 829);
const _landscape = Size(915, 412);
const _foldLandscape = Size(829, 690);
const _small = Size(360, 640);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadIqFonts);
  setUp(() async {
    LumoMotion.appReduced = false;
    await resetIqEnvironment();
  });

  Future<void> useSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  /// Wörter, die ein „richtig/falsch“ verraten würden.
  void expectNoVerdict() {
    for (final word in ['Richtig', 'Falsch', 'Leider', 'Super gemacht', 'Stimmt']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  }

  // ------------------------------------------------------------ Rätselbilder

  group('Rätselseiten', () {
    Widget host(IqPuzzle puzzle, {double textScale = 1}) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SafeArea(
              child: IqPuzzleView(
                puzzle: puzzle,
                index: 6,
                total: 24,
                areaNumber: 2,
                itemsPerArea: 4,
                onSubmit: (_, __) {},
                onBack: () {},
              ),
            ),
          ),
        );

    final combos = <(Size, double)>[
      (_phone, 1),
      (_phone, 1.3),
      (_fold, 1),
      (_fold, 1.3),
      (_landscape, 1),
      (_landscape, 1.3),
      (_foldLandscape, 1.3),
      (_small, 1.3),
    ];

    for (final area in IqArea.values) {
      testWidgets('${area.title}: jede Stufe ohne Überlauf auf Telefon und Fold',
          (tester) async {
        for (var level = 1; level <= IqPuzzleGenerator.maxLevel; level++) {
          final puzzle = IqPuzzleGenerator(Random(100 + level))
              .generate(area, level, 'galerie-$level');
          for (final (size, scale) in [(_phone, 1.0), (_fold, 1.3)]) {
            await tester.binding.setSurfaceSize(size);
            await tester.pumpWidget(host(puzzle, textScale: scale));
            await tester.pump(const Duration(milliseconds: 50));
            expect(tester.takeException(), isNull,
                reason: '${area.name} Stufe $level $size × $scale');
            expect(find.text(puzzle.question), findsOneWidget);
            // Dispose, damit der Merk-Blitz keine Zeitgeber hinterlässt.
            await tester.pumpWidget(const SizedBox());
          }
        }
        addTearDown(() => tester.binding.setSurfaceSize(null));
      });

      testWidgets('${area.title}: Querformat, Fold quer und kleines Telefon mit Schrift 1,3',
          (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final level in [1, 5, 8]) {
          final puzzle = IqPuzzleGenerator(Random(7 * level))
              .generate(area, level, 'quer-$level');
          for (final (size, scale) in combos) {
            await tester.binding.setSurfaceSize(size);
            await tester.pumpWidget(host(puzzle, textScale: scale));
            await tester.pump(const Duration(milliseconds: 50));
            expect(tester.takeException(), isNull,
                reason: '${area.name} Stufe $level $size × $scale');
            await tester.pumpWidget(const SizedBox());
          }
        }
      });
    }
  });

  // ------------------------------------------------------- Start und Anleitung

  group('Start und Anleitung', () {
    testWidgets('Startseite: Titel, sechs Bereiche, Hinweis für Eltern, großer Knopf',
        (tester) async {
      await useSize(tester, _phone);
      await tester.pumpWidget(iqScreenApp(iqTestApp(), session: IqTestSession(grade: 2, seed: 3)));
      await settleIq(tester);
      expect(find.text('Lumo Knobel-Test'), findsOneWidget);
      expect(find.text('Der IQ-Test für Kinder'), findsOneWidget);
      for (final area in IqArea.values) {
        expect(find.text(area.title), findsOneWidget, reason: area.title);
      }
      expect(find.text('24 Rätsel · ca. 10 Minuten · ohne Zeitdruck'), findsOneWidget);
      expect(find.text(iqParentNote), findsOneWidget);
      expect(find.textContaining('kein klinisch normierter Intelligenztest'), findsOneWidget);
      expect(find.textContaining('keine erfundene IQ-Zahl'), findsOneWidget);
      expect(find.textContaining('Letztes Mal'), findsNothing);
      final start = find.byKey(const ValueKey('iq-start-button'));
      expect(tester.getSize(start).height, greaterThanOrEqualTo(56));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Startseite zeigt das letzte echte Ergebnis', (tester) async {
      await useSize(tester, _phone);
      final earlier = earlierIqResult();
      await tester.runAsync(() => _repository.save(earlier));
      await tester.pumpWidget(iqScreenApp(iqTestApp(), session: IqTestSession(grade: 2, seed: 3)));
      await settleIq(tester);
      expect(find.text('Letztes Mal: ${earlier.thinkingPoints} Denkpunkte'), findsOneWidget);
    });

    testWidgets('Start führt zur Anleitung des ersten Bereichs, dann zum ersten Rätsel',
        (tester) async {
      await useSize(tester, _phone);
      final session = IqTestSession(grade: 2, seed: 3);
      await tester.pumpWidget(iqScreenApp(iqTestApp(), session: session));
      await settleIq(tester);
      await startIqTest(tester);
      expect(find.text(IqArea.matrix.title), findsOneWidget);
      expect(find.text(IqArea.matrix.instruction), findsOneWidget);
      expect(find.text('So sieht das aus'), findsOneWidget);
      expect(find.text('Bereich 1 von 6'), findsWidgets);
      final go = find.byKey(const ValueKey('iq-area-go'));
      expect(tester.getSize(go).height, greaterThanOrEqualTo(56));
      await leaveAreaIntro(tester);
      expect(find.text('Rätsel 1 von 24'), findsOneWidget);
      expect(find.text(session.current.question), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final area in IqArea.values) {
      testWidgets('Anleitung ${area.title} mit Beispiel auf Telefon und Fold', (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final (size, scale) in [(_phone, 1.0), (_fold, 1.3), (_landscape, 1.3)]) {
          await tester.binding.setSurfaceSize(size);
          // Zum Bereich spielen, indem die Rätsel davor ohne Oberfläche beantwortet werden.
          final session = IqTestSession(grade: 2, seed: 9);
          for (var i = 0; i < IqArea.values.indexOf(area) * 4; i++) {
            final puzzle = session.current;
            session.answer(
              switch (puzzle) {
                IqChoicePuzzle p => [p.answer],
                IqMemoryPuzzle p => p.sequence,
              },
              durationMs: 1000,
            );
          }
          expect(session.area, area);
          await tester.pumpWidget(iqScreenApp(iqTestApp(), session: session, textScale: scale));
          await settleIq(tester);
          await startIqTest(tester);
          expect(find.text(area.title), findsOneWidget);
          expect(find.text(area.instruction), findsOneWidget);
          expect(find.text(iqExampleCaption(area)), findsOneWidget);
          expect(tester.takeException(), isNull, reason: '${area.name} $size × $scale');
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  });

  // --------------------------------------------------------- Durchlauf (Taps)

  group('Kompletter Durchlauf', () {
    testWidgets(
        'alle 24 Rätsel durch Antippen: Ergebnis, Speicherung, Protokoll, Belohnung, Rückblick, Fertig',
        (tester) async {
      await useSize(tester, _phone);
      final app = iqTestApp();
      final session = IqTestSession(grade: 2, seed: 21);
      await tester.pumpWidget(iqLauncherApp(app, session: session));
      await tester.tap(find.byKey(const ValueKey('open-iq')));
      await settleIq(tester);

      await startIqTest(tester);
      var index = 0;
      final wrong = <int>{};
      for (var area = 0; area < IqArea.values.length; area++) {
        expect(find.text(IqArea.values[area].title), findsOneWidget);
        await leaveAreaIntro(tester);
        for (var item = 0; item < session.itemsPerArea; item++) {
          expect(find.text('Rätsel ${index + 1} von 24'), findsOneWidget);
          expect(find.text('Bereich ${area + 1} von 6'), findsOneWidget);
          expect(find.text(session.current.question), findsOneWidget);
          // „Weiter“ ist erst nach einer Antwort bedienbar.
          expect(tester.getSize(find.byKey(const ValueKey('iq-next'))).height,
              greaterThanOrEqualTo(56));
          final isCorrect = index % 5 != 2; // Rätsel 3, 8, 13, 18, 23 falsch
          if (!isCorrect) wrong.add(index);
          await answerCurrent(tester, session, correct: isCorrect);
          // Direkt nach „Weiter“ keine Richtig-/Falsch-Anzeige.
          expectNoVerdict();
          index++;
          if (index < 24 && item < session.itemsPerArea - 1) {
            expect(find.text('Rätsel ${index + 1} von 24'), findsOneWidget);
          }
        }
      }
      expect(index, 24);
      expect(session.finished, isTrue);
      expect(tester.takeException(), isNull);

      // Ergebnisseite.
      expect(find.text('Dein Denk-Profil'), findsOneWidget);
      expect(find.text('Denkpunkte'), findsOneWidget);
      expect(find.text('Rückblick'), findsOneWidget);
      expect(find.text('Fertig'), findsWidgets);
      expect(find.text(iqParentNote), findsOneWidget);
      expect(find.textContaining('Hier hilft Üben'), findsOneWidget);
      expect(find.text('Stufe je Bereich'), findsOneWidget);
      // Keine erfundene IQ-Zahl, nirgends („IQ 110“, „IQ: 98“ …).
      final iqNumber = RegExp(r'IQ\s*[:=\-–]?\s*\d');
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final plain = text.data ?? text.textSpan?.toPlainText() ?? '';
        expect(iqNumber.hasMatch(plain), isFalse, reason: plain);
      }
      final shown = tester.widget<Text>(find.byKey(const ValueKey('iq-points')));

      // Gespeichert.
      final saved = await tester.runAsync(() => _repository.latest(iqTestStudentId));
      expect(saved, isNotNull);
      expect(saved!.total, 24);
      expect(saved.solved, 24 - wrong.length);
      expect(saved.studentId, iqTestStudentId);
      expect(saved.finishedAt, iqTestNow());
      expect(shown.data, '${saved.thinkingPoints}');
      expect(saved.items.where((i) => !i.correct).length, wrong.length);
      expect(await tester.runAsync(() => _repository.loadAll(iqTestStudentId)), hasLength(1));

      // 24 Versuche im Protokoll.
      final attempts = await tester.runAsync(() => app.attemptLog.load(studentId: iqTestStudentId));
      expect(attempts, hasLength(24));
      expect(attempts!.every((a) => a.subject == 'IQ-Rätsel'), isTrue);
      expect(attempts.map((a) => a.unit).toSet(), IqArea.values.map((a) => a.title).toSet());
      expect(attempts.map((a) => a.competency).toSet(), IqArea.values.map((a) => a.skill).toSet());
      expect(attempts.where((a) => a.correct).length, saved.solved);
      expect(attempts.map((a) => a.id).toSet(), hasLength(24));
      expect(attempts.every((a) => a.durationMs != null && a.prompt.isNotEmpty), isTrue);

      // Belohnung: 1 Stern je 4 gelöste Rätsel, XP = Denkpunkte.
      expect(app.state.stars, saved.solved ~/ 4);
      expect(app.state.xp, saved.thinkingPoints);
      expect(find.text('+${saved.solved ~/ 4} Sterne'), findsOneWidget);
      expect(find.text('+${saved.thinkingPoints} XP'), findsOneWidget);

      // Rückblick zeigt die Lösung der falschen Rätsel.
      await tapKey(tester, 'iq-result-review');
      expect(find.text('Rückblick'), findsOneWidget);
      expect(find.text('${24 - wrong.length} von 24 Rätseln gelöst'), findsOneWidget);
      for (var i = 0; i < 24; i++) {
        expect(find.byKey(ValueKey('iq-review-row-$i')), findsOneWidget, reason: 'Reihe $i');
        expect(find.byKey(ValueKey('iq-review-solution-$i')),
            wrong.contains(i) ? findsOneWidget : findsNothing,
            reason: 'Lösung $i');
      }
      expect(find.text('Die richtige Lösung'), findsNWidgets(wrong.length));
      for (final i in wrong) {
        expect(find.text(session.answered[i].$1.explanation), findsWidgets,
            reason: 'Regel zu Rätsel ${i + 1}');
      }
      expect(find.text('Gelöst'), findsNWidgets(24 - wrong.length));
      expect(tester.takeException(), isNull);

      // Zurück zum Ergebnis, dann „Fertig“ schließt den Test.
      await tapKey(tester, 'iq-back');
      expect(find.text('Dein Denk-Profil'), findsOneWidget);
      await tapKey(tester, 'iq-result-done');
      expect(find.byType(IqTestScreen), findsNothing);
      expect(find.byKey(const ValueKey('open-iq')), findsOneWidget);
    });

    testWidgets('Fold und Schrift 1,3: Durchlauf endet auf der Ergebnisseite ohne Fehler',
        (tester) async {
      await useSize(tester, _fold);
      final app = iqTestApp();
      final session = IqTestSession(grade: 3, seed: 5);
      await tester.pumpWidget(iqScreenApp(app, session: session, textScale: 1.3));
      await settleIq(tester);
      await startIqTest(tester);
      for (var area = 0; area < IqArea.values.length; area++) {
        await leaveAreaIntro(tester);
        for (var item = 0; item < session.itemsPerArea; item++) {
          await answerCurrent(tester, session, correct: (area + item).isEven);
        }
      }
      expect(find.text('Dein Denk-Profil'), findsOneWidget);
      await tapKey(tester, 'iq-result-review');
      expect(find.text('Rückblick'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ----------------------------------------------------- Ergebnis und Rückblick

  group('Ergebnis und Rückblick', () {
    Widget resultHost(
      IqTestResult result, {
      IqTestResult? previous,
      IqReward reward = IqReward.none,
      bool already = false,
      bool failed = false,
      double textScale = 1,
    }) =>
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SafeArea(
              child: IqResultView(
                result: result,
                previous: previous,
                reward: reward,
                alreadyRewardedToday: already,
                saveFailed: failed,
                onReview: () {},
                onDone: () {},
              ),
            ),
          ),
        );

    testWidgets('Ohne früheres Ergebnis keine Vergleichspfeile', (tester) async {
      await useSize(tester, _phone);
      final result = earlierIqResult(finishedAt: iqTestNow());
      await tester.pumpWidget(resultHost(result, reward: const IqReward(stars: 3, xp: 99)));
      await tester.pump();
      for (final area in IqArea.values) {
        expect(find.byKey(ValueKey('iq-trend-${area.name}')), findsNothing);
      }
      expect(find.byKey(const ValueKey('iq-points-diff')), findsNothing);
      expect(find.text(result.strongest.area.badge), findsOneWidget);
      expect(find.text('Stärkster Bereich: ${result.strongest.area.title}'), findsOneWidget);
      expect(find.textContaining('Hier hilft Üben'), findsOneWidget);
      expect(find.text(iqPracticeTip(result.practice.area)), findsOneWidget);
      expect(find.text('+3 Sterne'), findsOneWidget);
      expect(find.text('${result.thinkingPoints}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mit früherem Ergebnis: ein Pfeil je Bereich und Punkte-Vergleich',
        (tester) async {
      await useSize(tester, _phone);
      final handle = tester.ensureSemantics();
      final earlier = earlierIqResult(good: false, seed: 4);
      final result = earlierIqResult(finishedAt: iqTestNow(), seed: 8);
      await tester.pumpWidget(resultHost(result, previous: earlier));
      await tester.pump();
      for (final area in IqArea.values) {
        expect(find.byKey(ValueKey('iq-trend-${area.name}')), findsOneWidget, reason: area.name);
      }
      expect(find.byKey(const ValueKey('iq-points-diff')), findsOneWidget);
      // Pfeil nach oben, wenn die Stufe gestiegen ist; nach unten, wenn gesunken.
      final scoresNow = result.areaScores;
      final scoresBefore = earlier.areaScores;
      for (var i = 0; i < IqArea.values.length; i++) {
        final delta = scoresNow[i].bestLevel - scoresBefore[i].bestLevel;
        final label = iqTrendLabel(delta);
        final area = IqArea.values[i];
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(area.title)}: .*$label\$')),
          findsOneWidget,
          reason: '${area.name}: $label',
        );
      }
      handle.dispose();
    });

    testWidgets('Belohnung nur einmal pro Tag: Hinweis statt Sterne', (tester) async {
      await useSize(tester, _phone);
      final result = earlierIqResult(finishedAt: iqTestNow());
      await tester.pumpWidget(resultHost(result, already: true));
      await tester.pump();
      expect(find.textContaining('Für heute hast du die Sterne fürs Knobeln schon bekommen'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('iq-reward-stars')), findsNothing);
    });

    testWidgets('Speicherfehler: ehrlicher Hinweis, keine Sterne', (tester) async {
      await useSize(tester, _phone);
      await tester.pumpWidget(resultHost(earlierIqResult(), failed: true));
      await tester.pump();
      expect(find.textContaining('konnte nicht gespeichert werden'), findsOneWidget);
    });

    for (final (size, scale) in [
      (_phone, 1.0),
      (_phone, 1.3),
      (_fold, 1.3),
      (_landscape, 1.3),
      (_foldLandscape, 1.0),
      (_small, 1.3),
    ]) {
      testWidgets('Ergebnis und Rückblick ohne Überlauf: $size, Schrift $scale', (tester) async {
        await useSize(tester, size);
        final session = finishedIqSession(seed: 12);
        final result = session.result(
          id: 'x',
          studentId: iqTestStudentId,
          finishedAt: iqTestNow(),
          durationMs: 500000,
        );
        await tester.pumpWidget(
          resultHost(result, previous: earlierIqResult(), reward: const IqReward(stars: 2, xp: 70), textScale: scale),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SafeArea(
              child: IqReviewView(answered: session.answered, onBack: () {}),
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Sechseck-Diagramm hat eine Beschreibung für Screenreader', (tester) async {
      await useSize(tester, _phone);
      final handle = tester.ensureSemantics();
      final result = earlierIqResult(finishedAt: iqTestNow());
      await tester.pumpWidget(resultHost(result));
      await tester.pump();
      final label = [
        for (final s in result.areaScores) '${s.area.title} Stufe ${s.bestLevel}',
      ].join(', ');
      expect(find.bySemanticsLabel('Denk-Profil als Sechseck von 0 bis 8: $label'), findsOneWidget);
      handle.dispose();
    });
  });

  // ------------------------------------------------------------ Zurück-Dialog

  group('Zurück', () {
    testWidgets('„Test wirklich beenden?“: Weitermachen bleibt, Beenden schließt ohne Speichern',
        (tester) async {
      await useSize(tester, _phone);
      final app = iqTestApp();
      final session = IqTestSession(grade: 2, seed: 2);
      await tester.pumpWidget(iqLauncherApp(app, session: session));
      await tester.tap(find.byKey(const ValueKey('open-iq')));
      await settleIq(tester);
      await startIqTest(tester);
      await leaveAreaIntro(tester);
      await answerCurrent(tester, session, correct: true);
      expect(find.text('Rätsel 2 von 24'), findsOneWidget);

      // Zurück-Pfeil fragt nach; Weitermachen bleibt im Test.
      await tapKey(tester, 'iq-back');
      expect(find.text('Test wirklich beenden?'), findsOneWidget);
      expect(find.text('Dein Fortschritt geht dabei verloren. Es wird nichts gespeichert.'),
          findsOneWidget);
      await tapKey(tester, 'iq-exit-stay');
      expect(find.text('Test wirklich beenden?'), findsNothing);
      expect(find.text('Rätsel 2 von 24'), findsOneWidget);

      // Die System-Zurück-Taste fragt genauso.
      await tester.binding.handlePopRoute();
      await settleIq(tester);
      expect(find.text('Test wirklich beenden?'), findsOneWidget);
      await tapKey(tester, 'iq-exit-confirm');
      expect(find.byType(IqTestScreen), findsNothing);

      // Nichts gespeichert, nichts protokolliert, nichts belohnt.
      expect(await tester.runAsync(() => _repository.loadAll(iqTestStudentId)), isEmpty);
      expect(await tester.runAsync(() => app.attemptLog.load()), isEmpty);
      expect(app.state.stars, 0);
      expect(app.state.xp, 0);
    });

    testWidgets('Auf der Anleitung fragt Zurück ebenfalls, auf der Startseite nicht',
        (tester) async {
      await useSize(tester, _phone);
      final app = iqTestApp();
      await tester.pumpWidget(iqLauncherApp(app, session: IqTestSession(grade: 2, seed: 2)));
      await tester.tap(find.byKey(const ValueKey('open-iq')));
      await settleIq(tester);
      await startIqTest(tester);
      await tapKey(tester, 'iq-back');
      expect(find.text('Test wirklich beenden?'), findsOneWidget);
      await tapKey(tester, 'iq-exit-stay');
      expect(find.byKey(const ValueKey('iq-area-go')), findsOneWidget);
      await tapKey(tester, 'iq-back');
      await tapKey(tester, 'iq-exit-confirm');
      expect(find.byType(IqTestScreen), findsNothing);

      // Startseite: Zurück schließt sofort.
      await tester.tap(find.byKey(const ValueKey('open-iq')));
      await settleIq(tester);
      await tapKey(tester, 'iq-back');
      expect(find.text('Test wirklich beenden?'), findsNothing);
      expect(find.byType(IqTestScreen), findsNothing);
    });
  });

  // ------------------------------------------------------------ Belohnung

  group('Belohnung', () {
    test('ein Stern je vier gelöste Rätsel, XP sind die Denkpunkte', () {
      const policy = IqRewardPolicy();
      final result = finishedIqSession(seed: 1).result(
        id: 'r',
        studentId: 's',
        finishedAt: DateTime(2026, 10, 8),
        durationMs: 1,
      );
      final reward = policy.forResult(result);
      expect(reward.stars, result.solved ~/ 4);
      expect(reward.xp, result.thinkingPoints);
    });

    test('derselbe Kalendertag zählt, auch kurz vor Mitternacht', () {
      const policy = IqRewardPolicy();
      final today = earlierIqResult(finishedAt: DateTime(2026, 10, 8, 0, 5));
      final lateYesterday = earlierIqResult(finishedAt: DateTime(2026, 10, 7, 23, 59));
      expect(policy.alreadyDoneOn([today], DateTime(2026, 10, 8, 23, 59)), isTrue);
      expect(policy.alreadyDoneOn([lateYesterday], DateTime(2026, 10, 8, 0, 1)), isFalse);
      expect(policy.alreadyDoneOn(const [], DateTime(2026, 10, 8)), isFalse);
    });

    /// Spielt einen schnellen, fehlerfreien Test und liefert die Sterne danach.
    Future<LumoAppState> playQuickTest(WidgetTester tester, {required DateTime now}) async {
      final app = iqTestApp();
      final session = IqTestSession(grade: 2, seed: 33);
      await tester.pumpWidget(iqScreenApp(app, session: session, now: () => now));
      await settleIq(tester);
      await startIqTest(tester);
      for (var area = 0; area < IqArea.values.length; area++) {
        await leaveAreaIntro(tester);
        for (var item = 0; item < session.itemsPerArea; item++) {
          await answerCurrent(tester, session, correct: true);
        }
      }
      expect(find.text('Dein Denk-Profil'), findsOneWidget);
      return app;
    }

    testWidgets('heute schon ein Test gespeichert: keine Sterne und XP', (tester) async {
      await useSize(tester, _phone);
      await tester.runAsync(() => _repository.save(
          earlierIqResult(finishedAt: DateTime(2026, 10, 8, 7, 30), seed: 6)));
      final app = await playQuickTest(tester, now: DateTime(2026, 10, 8, 16));
      expect(app.state.stars, 0);
      expect(app.state.xp, 0);
      expect(find.textContaining('Für heute hast du die Sterne fürs Knobeln schon bekommen'),
          findsOneWidget);
      // Das Ergebnis selbst wird trotzdem gespeichert (zwei Einträge) und der
      // Vergleich zeigt das frühere.
      final all = await tester.runAsync(() => _repository.loadAll(iqTestStudentId));
      expect(all, hasLength(2));
      expect(find.byKey(const ValueKey('iq-trend-matrix')), findsOneWidget);
    });

    testWidgets('gestern ein Test: heute gibt es Sterne und XP', (tester) async {
      await useSize(tester, _phone);
      await tester.runAsync(() => _repository.save(
          earlierIqResult(finishedAt: DateTime(2026, 10, 7, 18), seed: 6)));
      final app = await playQuickTest(tester, now: DateTime(2026, 10, 8, 16));
      final saved = await tester.runAsync(() => _repository.latest(iqTestStudentId));
      expect(saved!.finishedAt, DateTime(2026, 10, 8, 16));
      expect(saved.solved, 24);
      expect(app.state.stars, 6);
      expect(app.state.xp, saved.thinkingPoints);
      expect(find.text('+6 Sterne'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------ Merk-Blitz

  group('Merk-Blitz', () {
    Future<IqTestSession> sessionAtMemory(WidgetTester tester) async {
      await useSize(tester, _phone);
      final session = IqTestSession(grade: 2, seed: 17);
      for (var i = 0; i < 20; i++) {
        final puzzle = session.current;
        session.answer(
          switch (puzzle) {
            IqChoicePuzzle p => [p.answer],
            IqMemoryPuzzle p => p.sequence,
          },
          durationMs: 1000,
        );
      }
      expect(session.area, IqArea.memory);
      await tester.pumpWidget(iqScreenApp(iqTestApp(), session: session));
      await settleIq(tester);
      await startIqTest(tester);
      await leaveAreaIntro(tester);
      return session;
    }

    testWidgets('Felder leuchten nacheinander auf, danach tippt das Kind sie an', (tester) async {
      final session = await sessionAtMemory(tester);
      final puzzle = session.current as IqMemoryPuzzle;
      expect(find.text('Schau genau hin!'), findsOneWidget);
      // Während der Vorführung kann man noch nicht tippen und nicht weiter.
      await tester.tap(find.byKey(ValueKey('iq-memory-tile-${puzzle.sequence.first}')));
      await tester.pump();
      var next = tester.widget<GestureDetector>(
          find.descendant(of: find.byKey(const ValueKey('iq-next')), matching: find.byType(GestureDetector)));
      expect(next.onTap, isNull);

      // Zum ersten Aufleuchten: Lead-in 650 ms, dann leuchtet das erste Feld.
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(ValueKey('iq-memory-tile-${puzzle.sequence.first}')), findsOneWidget);
      await waitForMemoryShow(tester, puzzle);
      expect(find.text('Jetzt du!'), findsOneWidget);

      // Nach nur einem Feld ist „Weiter“ noch nicht frei.
      await tapKey(tester, 'iq-memory-tile-${puzzle.sequence.first}');
      next = tester.widget<GestureDetector>(
          find.descendant(of: find.byKey(const ValueKey('iq-next')), matching: find.byType(GestureDetector)));
      expect(next.onTap, isNull);
      // Rückgängig nimmt das Feld zurück.
      await tapKey(tester, 'iq-undo');
      expect(find.text('1'), findsNothing);
      for (final cell in puzzle.sequence) {
        await tapKey(tester, 'iq-memory-tile-$cell');
      }
      // Die angetippte Reihenfolge ist nummeriert.
      for (var i = 1; i <= puzzle.sequence.length; i++) {
        expect(find.text('$i'), findsWidgets);
      }
      next = tester.widget<GestureDetector>(
          find.descendant(of: find.byKey(const ValueKey('iq-next')), matching: find.byType(GestureDetector)));
      expect(next.onTap, isNotNull);
      await tapKey(tester, 'iq-next');
      expect(session.records.last.correct, isTrue);
      expect(session.records.last.given, puzzle.describeExpected());
    });

    testWidgets('„Nochmal zeigen“ spielt neu ab und leert die Eingabe', (tester) async {
      final session = await sessionAtMemory(tester);
      final puzzle = session.current as IqMemoryPuzzle;
      await waitForMemoryShow(tester, puzzle);
      await tapKey(tester, 'iq-memory-tile-${puzzle.sequence.first}');
      expect(find.text('1'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('iq-replay')));
      await tester.pump();
      expect(find.text('Schau genau hin!'), findsOneWidget);
      expect(find.text('Jetzt du!'), findsNothing);
      await waitForMemoryShow(tester, puzzle);
      expect(find.text('Jetzt du!'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      // Falsche Reihenfolge gilt als nicht gelöst – ohne Anzeige.
      for (final cell in puzzle.sequence.reversed) {
        await tapKey(tester, 'iq-memory-tile-$cell');
      }
      await tapKey(tester, 'iq-next');
      expect(session.records.last.correct, isFalse);
      expectNoVerdict();
    });
  });

  // ------------------------------------------------------ Bedienung, Semantik

  group('Bedienung', () {
    testWidgets('Antwortkarten: Markieren, Wechseln, ≥ 48 dp, Beschriftung aus describeOption',
        (tester) async {
      await useSize(tester, _phone);
      final handle = tester.ensureSemantics();
      final session = IqTestSession(grade: 2, seed: 4);
      await tester.pumpWidget(iqScreenApp(iqTestApp(), session: session));
      await settleIq(tester);
      await startIqTest(tester);
      await leaveAreaIntro(tester);
      final puzzle = session.current as IqChoicePuzzle;
      for (var i = 0; i < puzzle.optionCount; i++) {
        final card = find.byKey(ValueKey('iq-option-$i'));
        expect(card, findsOneWidget);
        final size = tester.getSize(card);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        final label = 'Antwort ${i + 1} von ${puzzle.optionCount}: ${puzzle.describeOption(i)}';
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      // „Weiter“ ist ohne Auswahl nicht bedienbar, mit Auswahl schon.
      ui.SemanticsFlags flagsOf(Finder finder) =>
          tester.getSemantics(finder).getSemanticsData().flagsCollection;
      Finder card(int i) => find.bySemanticsLabel(
          'Antwort ${i + 1} von ${puzzle.optionCount}: ${puzzle.describeOption(i)}');
      ui.Tristate enabled() => flagsOf(find.byKey(const ValueKey('iq-next'))).isEnabled;

      expect(enabled(), ui.Tristate.isFalse);
      await tapKey(tester, 'iq-option-1');
      expect(enabled(), ui.Tristate.isTrue);
      expect(flagsOf(card(1)).isSelected, ui.Tristate.isTrue);
      await tapKey(tester, 'iq-option-2');
      expect(flagsOf(card(1)).isSelected, ui.Tristate.isFalse);
      expect(flagsOf(card(2)).isSelected, ui.Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('Drehrätsel: die Beschriftung verrät die Lösung nicht', (tester) async {
      await useSize(tester, _phone);
      final handle = tester.ensureSemantics();
      final puzzle = IqPuzzleGenerator(Random(5)).generate(IqArea.rotation, 4, 'r') as IqRotationPuzzle;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IqPuzzleView(
            puzzle: puzzle,
            index: 12,
            total: 24,
            areaNumber: 4,
            itemsPerArea: 4,
            onSubmit: (_, __) {},
            onBack: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 0; i < puzzle.optionCount; i++) {
        final label = 'Antwort ${i + 1} von ${puzzle.optionCount}: Bauteil ${i + 1}';
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      expect(find.bySemanticsLabel(RegExp(r'^Antwort .*(gedreht|umgeklappt|andere Form)')),
          findsNothing);
      handle.dispose();
    });

    testWidgets('Zahlenrätsel: Karte nennt die Zahl, markierte Zahl rückt in die Lücke',
        (tester) async {
      await useSize(tester, _phone);
      final handle = tester.ensureSemantics();
      final puzzle = IqPuzzleGenerator(Random(8)).generate(IqArea.numbers, 3, 'n') as IqNumberPuzzle;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IqPuzzleView(
            puzzle: puzzle,
            index: 16,
            total: 24,
            areaNumber: 5,
            itemsPerArea: 4,
            onSubmit: (_, __) {},
            onBack: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('Antwort 1 von 4: ${puzzle.options[0]}'), findsOneWidget);
      expect(find.text('?'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('iq-option-0')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('${puzzle.options[0]}'), findsNWidgets(2));
      handle.dispose();
    });

    testWidgets('Antwort wird nur einmal abgegeben', (tester) async {
      await useSize(tester, _phone);
      final answers = <List<int>>[];
      final puzzle = IqPuzzleGenerator(Random(3)).generate(IqArea.series, 2, 's');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IqPuzzleView(
            puzzle: puzzle,
            index: 5,
            total: 24,
            areaNumber: 2,
            itemsPerArea: 4,
            onSubmit: (response, ms) => answers.add(response),
            onBack: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('iq-option-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('iq-next')));
      await tester.tap(find.byKey(const ValueKey('iq-next')));
      await tester.pump();
      expect(answers, [
        [0]
      ]);
    });
  });

  // ------------------------------------------------- Karte auf der Tests-Seite

  group('Tests-Seite', () {
    Future<LumoAppState> pumpTests(WidgetTester tester) async {
      // Hohe Fläche, damit die ganze Liste gebaut ist.
      await useSize(tester, const Size(412, 2200));
      final app = iqTestApp();
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: Scaffold(
          body: LumoTestsScreen(appState: app, onSection: (_) {}),
        ),
      ));
      await settleIq(tester);
      return app;
    }

    testWidgets('Karte steht über dem Denkprofil; ohne Ergebnis „Noch nicht gemacht“',
        (tester) async {
      await pumpTests(tester);
      final card = find.byKey(const ValueKey('iq-test-start'));
      expect(card, findsOneWidget);
      expect(find.text('Lumo Knobel-Test'), findsOneWidget);
      expect(find.text('IQ-Test für Kinder'), findsOneWidget);
      expect(find.text('Noch nicht gemacht'), findsOneWidget);
      // Über der bestehenden Denkprofil-Karte, die unverändert bleibt.
      expect(tester.getTopLeft(card).dy,
          lessThan(tester.getTopLeft(find.text('Lumo Denkprofil · 50')).dy));
      expect(find.byKey(const ValueKey('cognitive-profile-start')), findsOneWidget);
      expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Karte zeigt das letzte echte Ergebnis mit Datum', (tester) async {
      final earlier = earlierIqResult(finishedAt: DateTime(2026, 10, 1, 16));
      await tester.runAsync(() => _repository.save(earlier));
      await pumpTests(tester);
      expect(find.text('Zuletzt: ${earlier.thinkingPoints} Denkpunkte'), findsOneWidget);
      expect(find.text('1. Oktober 2026'), findsOneWidget);
      expect(find.text('Noch nicht gemacht'), findsNothing);
    });

    testWidgets('Tippen öffnet den Knobel-Test', (tester) async {
      await pumpTests(tester);
      await tester.tap(find.byKey(const ValueKey('iq-test-start')));
      await settleIq(tester);
      expect(find.byType(IqTestScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('iq-start-button')), findsOneWidget);
      expect(find.text('Der IQ-Test für Kinder'), findsOneWidget);
      // Zurück führt zur Tests-Seite, die Karte ist wieder da.
      await tapKey(tester, 'iq-back');
      expect(find.byType(IqTestScreen), findsNothing);
      expect(find.byKey(const ValueKey('iq-test-start')), findsOneWidget);
    });

    test('Datum der Karte nutzt österreichische Monatsnamen', () {
      expect(IqTestsCard.dateLabel(DateTime(2026, 1, 5)), '5. Jänner 2026');
      expect(IqTestsCard.dateLabel(DateTime(2026, 10, 8)), '8. Oktober 2026');
    });
  });

  // ---------------------------------------------------- Reduzierte Bewegung

  group('Bewegung', () {
    testWidgets('mit „Animationen reduzieren“ läuft nichts dauerhaft', (tester) async {
      await useSize(tester, _phone);
      final session = IqTestSession(grade: 2, seed: 4);
      await tester.pumpWidget(iqScreenApp(iqTestApp(reduceAnimations: true), session: session));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'Startseite');
      await startIqTest(tester);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'Anleitung');
      await leaveAreaIntro(tester);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'Rätselseite (pulsierendes ?)');
    });

    testWidgets('ohne Reduzierung pulsiert das gesuchte Feld', (tester) async {
      await useSize(tester, _phone);
      final session = IqTestSession(grade: 2, seed: 4);
      await tester.pumpWidget(iqScreenApp(iqTestApp(reduceAnimations: false), session: session));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('iq-start-button')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('iq-area-go')));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('?'), findsWidgets);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('System-Einstellung „Animationen entfernen“ wirkt ebenso', (tester) async {
      await useSize(tester, _phone);
      final session = IqTestSession(grade: 2, seed: 4);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: IqTestScreen(
          appState: iqTestApp(reduceAnimations: false),
          session: session,
          now: iqTestNow,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('iq-start-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('iq-area-go')));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
