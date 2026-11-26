import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_guidance.dart';
import 'package:lumo_lernen/domain/tutoring/hilfe_folge.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/nachhilfe_lernstand.dart';
import 'package:lumo_lernen/domain/tutoring/verstaendnis.dart';
import 'package:lumo_lernen/features/report/learning_guidance_panel.dart';

/// Lumo erkennt Verständnis: nur eine selbstständig richtig gelöste
/// Vergleichsaufgabe nach einer Hilfe ist ein neues Indiz, gespeichert im
/// vorhandenen Aufgabenprotokoll; bei wenigen Daten keine Übertreibung.
const _komp = 'Addition mit Zehnerübergang';
var _n = 0;

Attempt _a(
  String prompt, {
  bool correct = true,
  bool hint = false,
  String? check,
  String reference = '',
  String? method,
  int minute = 0,
  String komp = _komp,
  String subject = 'Mathematik',
  String student = 'kind-a',
}) =>
    Attempt(
      id: 'v${_n++}',
      studentId: student,
      subject: subject,
      unit: 'Plus bis 20',
      competency: komp,
      correct: correct,
      at: DateTime(2026, 11, 24, 9).add(Duration(minutes: minute)),
      hintUsed: hint,
      prompt: prompt,
      check: check,
      reference: reference,
      method: method,
    );

Attempt _vergleich(String prompt, String reference,
        {bool correct = true, bool hint = false, int minute = 0}) =>
    _a(prompt,
        correct: correct,
        hint: hint,
        check: Attempt.vergleichNachHilfe,
        reference: reference,
        minute: minute);

void main() {
  group('Speicherung im Aufgabenprotokoll', () {
    test('Vergleichsaufgabe mit Bezug und Erklärweise: verlustfrei', () {
      final a = _a('7 + 6 = ?',
          check: Attempt.vergleichNachHilfe,
          reference: '8 + 5 = ?',
          method: 'zahlenstrahl');
      final json = a.toJson();
      expect(json['chk'], 'vergleich');
      expect(json['ref'], '8 + 5 = ?');
      expect(json['m'], 'zahlenstrahl');
      final b = Attempt.tryFromJson(json)!;
      expect(b.check, Attempt.vergleichNachHilfe);
      expect(b.reference, '8 + 5 = ?');
      expect(b.method, 'zahlenstrahl');
      expect(b.confirmsAfterHelp, isTrue);
    });

    test('ältere Einträge ohne die neuen Felder bleiben lesbar', () {
      final alt = Attempt.tryFromJson({
        'id': 'alt-1',
        'sid': 'kind-a',
        'sub': 'Mathematik',
        'unit': 'Plus bis 20',
        'comp': _komp,
        'ok': true,
        'at': '2026-10-01T08:00:00.000',
      })!;
      expect(alt.check, isNull);
      expect(alt.reference, '');
      expect(alt.method, isNull);
      expect(alt.confirmsAfterHelp, isFalse);
      expect(alt.toJson().containsKey('chk'), isFalse);
      expect(alt.toJson().containsKey('m'), isFalse);
    });
  });

  group('Verständnis-Indiz', () {
    test('ohne Vergleichsaufgabe: keine Aussage – auch nicht nach vielen '
        'richtigen Antworten', () {
      final i = VerstaendnisIndiz.aus([
        _a('8 + 5 = ?', hint: true),
        for (var m = 1; m < 6; m++) _a('${m + 5} + 7 = ?', minute: m),
      ], kompetenz: _komp);
      expect(i.stufe, VerstaendnisStufe.keineDaten);
      expect(i.hatIndiz, isFalse);
    });

    test('eine selbstständig richtige Vergleichsaufgabe: erstes Anzeichen', () {
      final i = VerstaendnisIndiz.aus([
        _a('8 + 5 = ?', hint: true),
        _vergleich('7 + 6 = ?', '8 + 5 = ?', minute: 3),
      ], kompetenz: _komp);
      expect(i.stufe, VerstaendnisStufe.erstesAnzeichen);
      expect(i.hatIndiz, isTrue);
      expect(i.spaeterBestaetigt, isFalse);
      expect(i.elternSatz, contains('erstes Anzeichen'));
      expect(i.elternSatz, contains('noch keine sichere Aussage'));
      expect(i.bezuege.single, ('8 + 5 = ?', '7 + 6 = ?'));
    });

    test('Vergleichsaufgabe mit Hilfe oder falsch: kein Indiz', () {
      final mitHilfe = VerstaendnisIndiz.aus([
        _vergleich('7 + 6 = ?', '8 + 5 = ?', hint: true),
      ], kompetenz: _komp);
      expect(mitHilfe.hatIndiz, isFalse);
      expect(mitHilfe.stufe, VerstaendnisStufe.nochUnsicher);
      expect(mitHilfe.alleinRichtig, 0);
      final falsch = VerstaendnisIndiz.aus([
        _vergleich('7 + 6 = ?', '8 + 5 = ?', correct: false),
      ], kompetenz: _komp);
      expect(falsch.hatIndiz, isFalse);
      expect(falsch.elternSatz, contains('noch nicht allein'));
    });

    test('gewöhnliche richtige Antwort nach Hilfe ist kein Vergleichsnachweis',
        () {
      final i = VerstaendnisIndiz.aus([
        _a('8 + 5 = ?', hint: true),
        _a('7 + 6 = ?', minute: 2),
      ], kompetenz: _komp);
      expect(i.stufe, VerstaendnisStufe.keineDaten);
    });

    test('Aufgaben anderer Kompetenz und ohne gültigen Bezug bestätigen nichts',
        () {
      final attempts = [
        _vergleich('7 + 6 = ?', '2 + 3 = ?'),
        _vergleich('9 + 3 = ?', '1 + 5 = ?', minute: 30),
        _vergleich('6 + 8 = ?', ''),
        _vergleich('8 + 5 = ?', '8 + 5 = ?'),
      ];
      expect(attempts.any((a) => a.confirmsAfterHelp), isFalse);
      expect(VerstaendnisIndiz.alle(attempts), isEmpty);
      final evidence = VerstaendnisIndiz.aus(attempts, kompetenz: _komp);
      expect(evidence.stufe, VerstaendnisStufe.keineDaten);
      expect(evidence.vergleiche, 0);
      expect(evidence.bezuege, isEmpty);
    });

    test('zweimal dieselbe Ausgangsaufgabe: noch nicht bestätigt', () {
      final i = VerstaendnisIndiz.aus([
        _vergleich('7 + 6 = ?', '8 + 5 = ?'),
        _vergleich('9 + 4 = ?', '8 + 5 = ?', minute: 5),
      ], kompetenz: _komp);
      expect(i.alleinRichtig, 2);
      expect(i.ausgangsaufgaben, 1);
      expect(i.stufe, VerstaendnisStufe.erstesAnzeichen);
    });

    test('dieselbe Vergleichsaufgabe zählt nur einmal (erste Antwort)', () {
      final i = VerstaendnisIndiz.aus([
        _vergleich('7 + 6 = ?', '8 + 5 = ?', correct: false),
        _vergleich('7 + 6 = ?', '8 + 5 = ?', minute: 1),
      ], kompetenz: _komp);
      expect(i.vergleiche, 1);
      expect(i.hatIndiz, isFalse);
    });

    test('zwei verschiedene Ausgangsaufgaben, zuletzt allein: später '
        'bestätigt', () {
      final i = VerstaendnisIndiz.aus([
        _vergleich('7 + 6 = ?', '8 + 5 = ?'),
        _vergleich('9 + 3 = ?', '6 + 7 = ?', minute: 30),
      ], kompetenz: _komp);
      expect(i.stufe, VerstaendnisStufe.spaeterBestaetigt);
      expect(i.elternSatz, startsWith('Später bestätigt'));
      expect(i.elternSatz, contains('2 von 2'));
    });

    test('nach Bestätigung zuletzt nicht allein: wieder unsicher', () {
      final i = VerstaendnisIndiz.aus([
        _vergleich('7 + 6 = ?', '8 + 5 = ?'),
        _vergleich('9 + 3 = ?', '6 + 7 = ?', minute: 30),
        _vergleich('8 + 7 = ?', '9 + 5 = ?', correct: false, minute: 60),
      ], kompetenz: _komp);
      expect(i.stufe, VerstaendnisStufe.nochUnsicher);
      expect(i.elternSatz, contains('2 von 3'));
    });

    test('Fachtrennung: Englisch zählt nicht für Mathematik', () {
      final i = VerstaendnisIndiz.aus([
        _a('Was bedeutet „cow“?',
            subject: 'Englisch',
            check: Attempt.vergleichNachHilfe,
            reference: 'Was bedeutet „horse“?'),
      ], kompetenz: _komp, fach: 'Mathematik');
      expect(i.stufe, VerstaendnisStufe.keineDaten);
    });
  });

  group('Methodenwechsel', () {
    test('nie zweimal hintereinander dieselbe Erklärweise', () {
      const folge = ['stangen', 'zahlenstrahl', 'alltagsbild', 'gemeinsam'];
      final gezeigt = <String>[];
      String? zuletzt;
      for (var i = 0; i < 9; i++) {
        final m = HilfeMethodenwechsel.naechste(folge,
            gezeigt: gezeigt, zuletzt: zuletzt)!;
        expect(m, isNot(zuletzt));
        if (i < folge.length) expect(m, folge[i]);
        gezeigt.add(m);
        zuletzt = m;
      }
    });

    test('Erklärweisen ohne Erfolg rücken ans Ende', () {
      expect(
          HilfeMethodenwechsel.zuerstNeue(
              ['tipp', 'stangen', 'zahlenstrahl', 'gemeinsam'], {'tipp', 'stangen'}),
          ['zahlenstrahl', 'gemeinsam', 'tipp', 'stangen']);
    });

    test('aus dem Protokoll: nicht hilfreiche Wege werden erkannt', () {
      final attempts = [
        _a('37 + 25 = ?', correct: false, hint: true, method: 'stangen'),
        _a('37 + 25 = ?', hint: true, method: 'zahlenstrahl', minute: 1),
      ];
      expect(
          VerstaendnisIndiz.wenigHilfreicheMethoden(attempts, kompetenz: _komp),
          {'stangen'});
      final stand = NachhilfeLernstand.aus(attempts, kompetenz: _komp);
      expect(stand.wenigHilfreicheWege, {NachhilfeWeg.stangen});
      // Danach allein gelöst: der Weg hat doch geholfen.
      final spaeter = [
        ...attempts,
        _a('46 + 27 = ?', method: 'stangen', minute: 9),
      ];
      expect(
          VerstaendnisIndiz.wenigHilfreicheMethoden(spaeter, kompetenz: _komp),
          isEmpty);
    });

    test('Nachhilfe beginnt nicht mit einem Weg, der nicht geholfen hat', () {
      const tutor = LumoNachhilfe();
      final aufgabe = NachhilfeAufgabe.additionBis100(37, 25)!;
      final erster = tutor.wegFuer(aufgabe);
      final anderer = tutor.wegFuer(aufgabe, schonVersucht: {erster});
      expect(anderer, isNot(erster));
    });

    test('Hilf-mir-Folge: Zehnerstangen, Zahlenstrahl, Alltagsbild, gemeinsam '
        '– ohne Ergebnis und ohne doppelte Texte', () {
      for (final aufgabe in [
        NachhilfeAufgabe.additionBis100(37, 25)!,
        NachhilfeAufgabe.subtraktionBis100(62, 25)!,
        NachhilfeAufgabe.addition(8, 5)!,
        NachhilfeAufgabe.subtraktion(13, 5)!,
        NachhilfeAufgabe.mal(6, 7)!,
      ]) {
        final folge = HilfeFolge.folge(
          stufen: HilfeFolge.stufen('Tipp eins.', 'Tipp zwei.', 'Tipp drei.'),
          wege: HilfeFolge.rechenwege(aufgabe),
          nachhilfeVerfuegbar: true,
        );
        final methoden = folge.map((v) => v.methode).toList();
        expect(methoden.toSet().length, methoden.length);
        expect(folge.map((v) => v.text).toSet().length, folge.length);
        expect(methoden.first, HilfeFolge.tipp);
        expect(methoden.last, HilfeFolge.gemeinsam);
        expect(methoden, contains(HilfeFolge.alltagsbild));
        expect(methoden.where((m) => NachhilfeWeg.values.any((w) => w.name == m)),
            hasLength(greaterThanOrEqualTo(2)),
            reason: '${aufgabe.text}: mindestens zwei Rechenwege');
        final ergebnis = RegExp('(^|\\D)${aufgabe.ergebnis}(\\D|\$)');
        for (final v in folge) {
          expect(ergebnis.hasMatch(v.text), isFalse,
              reason: '${aufgabe.text}: „${v.text}“ verrät das Ergebnis');
        }
      }
      final plus100 = HilfeFolge.rechenwege(
          NachhilfeAufgabe.additionBis100(37, 25)!);
      expect(plus100.first.methode, NachhilfeWeg.stangen.name);
      expect(plus100.first.titel, 'Anders erklärt: mit Zehnerstangen');
    });
  });

  test('Hilf-mir-Rechenwege verraten nie das Ergebnis (Zahlenraum 100, '
      'Minus bis 20, Einmaleins)', () {
    final aufgaben = <NachhilfeAufgabe>[
      for (var a = 21; a <= 95; a += 7)
        for (var b = 3; a + b <= 100; b += 9)
          NachhilfeAufgabe.additionBis100(a, b)!,
      for (var a = 21; a <= 100; a += 6)
        for (var b = 2; b <= a; b += 11)
          NachhilfeAufgabe.subtraktionBis100(a, b)!,
      for (var a = 11; a <= 20; a++)
        for (var b = 1; b <= a; b += 3) NachhilfeAufgabe.subtraktion(a, b)!,
      for (var a = 1; a <= 10; a++)
        for (var b = 1; b <= 10; b++) NachhilfeAufgabe.mal(a, b)!,
    ];
    for (final aufgabe in aufgaben) {
      final e = aufgabe.ergebnis;
      final a = aufgabe.a, b = aufgabe.b;
      // Zahlen, die schon in der Aufgabe stecken (Zehner, Einer, 10), dürfen
      // vorkommen; dann darf das Ergebnis nur nicht als „= e“ dastehen.
      final steckt = {
        a, b, a ~/ 10, a % 10, b ~/ 10, b % 10, //
        10 * (a ~/ 10), 10 * (b ~/ 10), 10, 100,
      }.contains(e);
      final ergebnis = steckt
          ? RegExp('=\\s*$e([^0-9]|\$)')
          : RegExp('(^|[^0-9])$e([^0-9]|\$)');
      for (final v in HilfeFolge.rechenwege(aufgabe)) {
        expect(ergebnis.hasMatch(v.text), isFalse,
            reason: '${aufgabe.text} (${v.methode}): „${v.text}“');
      }
    }
  });

  group('Nachhilfe-Lernstand und Eltern „Auf einen Blick“', () {
    test('zwei bestätigte Vergleichsaufgaben → Lernstand später bestätigt', () {
      final stand = NachhilfeLernstand.aus([
        _vergleich('7 + 6 = ?', '8 + 5 = ?'),
        _vergleich('9 + 3 = ?', '6 + 7 = ?', minute: 30),
      ], kompetenz: _komp);
      expect(stand.befunde, contains(NachhilfeBefund.fehlendeDaten),
          reason: 'Zwei Antworten sind für Muster noch zu wenig.');
      expect(stand.verstaendnis.spaeterBestaetigt, isTrue);
      expect(stand.kindSatz, contains('allein'));
    });

    testWidgets('„Später bestätigt“ ist sichtbar, ehrlich eingestuft',
        (tester) async {
      final now = DateTime(2026, 11, 25, 12);
      final guidance = LearningGuidance.fromAttempts([
        _a('8 + 5 = ?', hint: true),
        _vergleich('7 + 6 = ?', '8 + 5 = ?', minute: 3),
        _a('Was bedeutet „horse“?',
            subject: 'Englisch', komp: 'Englisch Tiere', hint: true, minute: 5),
        Attempt(
          id: 'en-v',
          studentId: 'kind-a',
          subject: 'Englisch',
          unit: 'Tiere',
          competency: 'Englisch Tiere',
          correct: true,
          at: DateTime(2026, 11, 24, 9, 8),
          prompt: 'Was bedeutet „cow“?',
          check: Attempt.vergleichNachHilfe,
          reference: 'Was bedeutet „horse“?',
        ),
        Attempt(
          id: 'en-v2',
          studentId: 'kind-a',
          subject: 'Englisch',
          unit: 'Tiere',
          competency: 'Englisch Tiere',
          correct: true,
          at: DateTime(2026, 11, 24, 10),
          prompt: 'Was bedeutet „sheep“?',
          check: Attempt.vergleichNachHilfe,
          reference: 'Was bedeutet „pig“?',
        ),
        // Fremdes Profil zählt nie.
        _vergleich('9 + 3 = ?', '6 + 7 = ?').copyForTest(student: 'kind-b'),
      ], studentId: 'kind-a', now: now);
      expect(guidance.laterConfirmed, hasLength(2));
      expect(guidance.laterConfirmed.first.fach, 'Englisch');
      expect(guidance.laterConfirmed.first.spaeterBestaetigt, isTrue);
      expect(guidance.laterConfirmed.last.stufe,
          VerstaendnisStufe.erstesAnzeichen);
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: LearningGuidancePanel(guidance: guidance)))));
      expect(find.byKey(const ValueKey('guidance-later-confirmed')),
          findsOneWidget);
      expect(find.text('später bestätigt'), findsOneWidget);
      expect(find.text('erstes Anzeichen'), findsOneWidget);
      expect(find.textContaining('noch keine sichere Aussage'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });
  });
}

extension on Attempt {
  Attempt copyForTest({required String student}) => Attempt(
        id: '$id-$student',
        studentId: student,
        subject: subject,
        unit: unit,
        competency: competency,
        correct: correct,
        at: at,
        hintUsed: hintUsed,
        prompt: prompt,
        check: check,
        reference: reference,
        method: method,
      );
}
