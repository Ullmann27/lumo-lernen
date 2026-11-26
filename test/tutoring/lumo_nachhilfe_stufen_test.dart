import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';

/// Fünf Hilfestufen je Thema (Auftrag Heinz, Abschnitt 5): Plus/Minus mit
/// Zehnerübergang, Kopfrechnen bis 100, Einmaleins.
TaskInstance _task(String prompt, Object answer, Map<String, Object?> data) =>
    TaskInstance(
      taskInstanceId: 't',
      templateId: 'legacy.Mathematik.Test',
      childId: 'c',
      seedHash: 's',
      subject: LearningSubject.mathematik,
      skillId: const SkillId('legacy.mathematik.test'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const {},
      prompt: prompt,
      options: const [],
      correctAnswer: answer,
      visualPayload: VisualPayload(type: VisualType.dots, data: data),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 11, 26),
    );

const _tutor = LumoNachhilfe();

Iterable<NachhilfeAufgabe> _alle(NachhilfeTyp typ) sync* {
  switch (typ) {
    case NachhilfeTyp.additionBis20:
      for (var a = 1; a <= 19; a++) {
        for (var b = 1; a + b <= 20; b++) {
          yield NachhilfeAufgabe.addition(a, b)!;
        }
      }
    case NachhilfeTyp.subtraktionBis20:
      for (var a = 1; a <= 20; a++) {
        for (var b = 1; b <= a; b++) {
          yield NachhilfeAufgabe.subtraktion(a, b)!;
        }
      }
    case NachhilfeTyp.additionBis100:
      for (var a = 1; a <= 99; a++) {
        for (var b = 1; a + b <= 100; b++) {
          final x = NachhilfeAufgabe.additionBis100(a, b);
          if (x != null) yield x;
        }
      }
    case NachhilfeTyp.subtraktionBis100:
      for (var a = 21; a <= 100; a++) {
        for (var b = 1; b <= a; b++) {
          yield NachhilfeAufgabe.subtraktionBis100(a, b)!;
        }
      }
    case NachhilfeTyp.einmaleins:
      for (var a = 1; a <= 10; a++) {
        for (var b = 1; b <= 10; b++) {
          yield NachhilfeAufgabe.mal(a, b)!;
        }
      }
  }
}

/// Prüft einen Plan: an der Originalaufgabe nie das Ergebnis, Material bleibt
/// stimmig (nichts geht verloren), Zwillingspläne enden beim Zwillingsergebnis.
void _pruefePlan(NachhilfeAufgabe original, NachhilfePlan plan, String label) {
  final x = plan.aufgabe;
  final e = x.ergebnis;
  expect(plan.schritte, isNotEmpty, reason: label);
  expect(x.typ, original.typ, reason: label);
  final verrat = RegExp('= ${original.ergebnis}(?!\\d)');
  if (plan.stufe.anOriginal) {
    expect(x, original, reason: label);
    for (final s in plan.schritte) {
      expect(s.aktion.art, isNot('ergebnis'), reason: '$label ${s.id}');
      expect(s.frage, isNot(original.ergebnis), reason: '$label ${s.id}');
      expect(verrat.hasMatch(s.text), isFalse, reason: '$label ${s.text}');
    }
    expect(verrat.hasMatch(plan.einleitung), isFalse, reason: label);
    expect(verrat.hasMatch(plan.abschluss), isFalse, reason: label);
  } else {
    expect(e, isNot(original.ergebnis), reason: label);
  }
  if (plan.stufe == NachhilfeStufe.teilschritt) {
    expect(plan.schritte.first.akteur, NachhilfeAkteur.lumo, reason: label);
  }
  if (plan.stufe == NachhilfeStufe.vorzeigen) {
    expect(plan.schritte.every((s) => s.akteur == NachhilfeAkteur.lumo),
        isTrue,
        reason: label);
  }
  NachhilfeAktion? letzteStangen, letztePunkte, letzterSprung, letztePerlen;
  for (final s in plan.schritte) {
    expect(s.text.length, lessThanOrEqualTo(240), reason: label);
    expect(s.text.trim(), isNotEmpty, reason: label);
    if (s.frage != null) {
      expect(s.akteur, NachhilfeAkteur.kind, reason: label);
      expect(s.frage, greaterThanOrEqualTo(0), reason: label);
    }
    final w = s.aktion;
    switch (w.art) {
      case 'stangen':
        for (final v in w.werte.values) {
          expect(v, greaterThanOrEqualTo(0), reason: '$label ${s.id}');
        }
        final liegend = 10 * w.wert('zehner') + w.wert('einer');
        if (x.typ.istPlus) {
          expect(liegend + 10 * w.wert('dazuZehner') + w.wert('dazuEiner'),
              x.a + x.b,
              reason: '$label ${s.id}: nichts geht verloren');
          expect(w.wert('wegZehner') + w.wert('wegEiner'), 0, reason: label);
        } else {
          expect(liegend + 10 * w.wert('wegZehner') + w.wert('wegEiner'), x.a,
              reason: '$label ${s.id}: nichts geht verloren');
        }
        expect(w.wert('einer'), lessThanOrEqualTo(10), reason: label);
        letzteStangen = w;
      case 'punkte':
        final zeilen = w.wert('gedreht') == 1 ? w.wert('spalten') : w.wert('zeilen');
        expect(w.wert('zeilen'), x.a, reason: label);
        expect(w.wert('spalten'), x.b, reason: label);
        expect(w.wert('sichtbar'), inInclusiveRange(1, zeilen), reason: label);
        expect(w.wert('markiert'), inInclusiveRange(0, w.wert('sichtbar')),
            reason: label);
        expect(zeilen + w.wert('geister'), lessThanOrEqualTo(10), reason: label);
        letztePunkte = w;
      case 'huepfen':
        expect(w.wert('von'), inInclusiveRange(0, 100), reason: label);
        expect(w.wert('nach'), inInclusiveRange(0, 100), reason: label);
        letzterSprung = w;
      case 'perlen':
        expect(w.wert('reihe1'), inInclusiveRange(0, 10), reason: label);
        expect(w.wert('reihe2'), inInclusiveRange(0, 10), reason: label);
        letztePerlen = w;
      case 'zerlegen':
        expect(w.wert('teil1') + w.wert('teil2'), w.wert('ganz'), reason: label);
      case 'ergebnis':
        expect(w.wert('richtig'), e, reason: label);
        expect(w.optionen, contains(e), reason: label);
      case 'zeigen':
      case 'bild':
        break;
      default:
        fail('unbekannte Aktion ${w.art} bei $label');
    }
  }
  if (plan.stufe == NachhilfeStufe.vorzeigen ||
      plan.stufe == NachhilfeStufe.ueben) {
    expect(plan.schritte.last.aktion.art, 'ergebnis', reason: label);
    if (letzteStangen != null) {
      expect(10 * letzteStangen.wert('zehner') + letzteStangen.wert('einer'), e,
          reason: '$label: am Ende liegt das Ergebnis');
    }
    if (letztePunkte != null) {
      final zeilen = letztePunkte.wert('gedreht') == 1
          ? letztePunkte.wert('spalten')
          : letztePunkte.wert('zeilen');
      expect(letztePunkte.wert('markiert'), zeilen, reason: label);
      expect(letztePunkte.wert('geister'), 0, reason: label);
    }
    if (letzterSprung != null && x.typ.bis100) {
      expect(letzterSprung.wert('nach'), e, reason: label);
    }
    if (letztePerlen != null && x.typ == NachhilfeTyp.subtraktionBis20) {
      expect(letztePerlen.wert('reihe1') + letztePerlen.wert('reihe2'), e,
          reason: label);
    }
  }
}

void main() {
  group('Aufgaben erkennen', () {
    test('Minus, Kopfrechnen bis 100 und Einmaleins aus geprüften Daten', () {
      expect(
          NachhilfeAufgabe.ausTask(_task('13 − 5 = ?', 8,
              {'operation': 'subtraction', 'left': 13, 'right': 5})),
          NachhilfeAufgabe.subtraktion(13, 5));
      expect(
          NachhilfeAufgabe.ausTask(_task('37 + 25 = ?', 62,
              {'operation': 'addition', 'left': 37, 'right': 25})),
          NachhilfeAufgabe.additionBis100(37, 25));
      expect(
          NachhilfeAufgabe.ausTask(_task('62 - 25 = ?', '37',
              {'operation': 'subtraction', 'left': 62, 'right': 25})),
          NachhilfeAufgabe.subtraktionBis100(62, 25));
      expect(
          NachhilfeAufgabe.ausTask(_task('6 · 7 = ?', 42,
              {'operation': 'multiplication', 'left': 6, 'right': 7})),
          NachhilfeAufgabe.mal(6, 7));
      expect(
          NachhilfeAufgabe.ausTask(_task('6 × 7 = ?', 42,
              {'operation': 'multiplication', 'left': 6, 'right': 7})),
          NachhilfeAufgabe.mal(6, 7));
      // Falsche Lösung, falscher Text oder zu große Zahlen: keine Nachhilfe.
      expect(
          NachhilfeAufgabe.ausTask(_task('6 · 7 = ?', 43,
              {'operation': 'multiplication', 'left': 6, 'right': 7})),
          isNull);
      expect(
          NachhilfeAufgabe.ausTask(_task('Wie viele Kekse?', 42,
              {'operation': 'multiplication', 'left': 6, 'right': 7})),
          isNull);
      expect(
          NachhilfeAufgabe.ausTask(_task('467 + 258 = ?', 725,
              {'operation': 'addition', 'left': 467, 'right': 258})),
          isNull);
      expect(NachhilfeAufgabe.mal(11, 3), isNull);
      expect(NachhilfeAufgabe.subtraktion(5, 6), isNull);
      expect(NachhilfeAufgabe.additionBis100(10, 5), isNull,
          reason: 'bis 20 bleibt Plus bis 20');
      expect(NachhilfeAufgabe.mal(6, 7)!.text, '6 · 7');
      expect(NachhilfeAufgabe.subtraktion(13, 5)!.text, '13 − 5');
    });

    test('Zehnerübergang je Typ', () {
      expect(NachhilfeAufgabe.subtraktion(13, 5)!.zehnerUebergang, isTrue);
      expect(NachhilfeAufgabe.subtraktion(17, 3)!.zehnerUebergang, isFalse);
      expect(NachhilfeAufgabe.additionBis100(37, 25)!.zehnerUebergang, isTrue);
      expect(NachhilfeAufgabe.additionBis100(45, 32)!.zehnerUebergang, isFalse);
      expect(
          NachhilfeAufgabe.subtraktionBis100(62, 25)!.zehnerUebergang, isTrue);
      expect(NachhilfeAufgabe.mal(6, 7)!.zehnerUebergang, isFalse);
    });
  });

  group('Wege', () {
    test('Wege passen zum Thema', () {
      expect(_tutor.wegeFuer(NachhilfeAufgabe.subtraktion(13, 5)!), [
        NachhilfeWeg.rechenrahmen,
        NachhilfeWeg.zahlenstrahl,
        NachhilfeWeg.zerlegen,
      ]);
      expect(_tutor.wegeFuer(NachhilfeAufgabe.additionBis100(37, 25)!),
          [NachhilfeWeg.stangen, NachhilfeWeg.zahlenstrahl]);
      expect(_tutor.wegeFuer(NachhilfeAufgabe.additionBis100(7, 45)!).first,
          NachhilfeWeg.tauschen);
      expect(_tutor.wegeFuer(NachhilfeAufgabe.mal(6, 7)!),
          [NachhilfeWeg.kernaufgabe, NachhilfeWeg.tauschen]);
      expect(_tutor.wegeFuer(NachhilfeAufgabe.mal(7, 5)!).first,
          NachhilfeWeg.tauschen,
          reason: '7 · 5 wird durch Drehen zur Kernaufgabe 5 · 7');
      expect(_tutor.wegeFuer(NachhilfeAufgabe.mal(4, 6)!),
          contains(NachhilfeWeg.punktefeld));
      expect(_tutor.wegeFuer(NachhilfeAufgabe.mal(7, 7)!),
          isNot(contains(NachhilfeWeg.tauschen)));
    });
  });

  group('Fehlermuster', () {
    test('Minus, Kopfrechnen und Einmaleins', () {
      final m = NachhilfeAufgabe.subtraktionBis100(62, 25)!;
      expect(_tutor.erkenneFehler(m, 43), NachhilfeFehlermuster.einerUmgedreht);
      expect(_tutor.erkenneFehler(m, 47), NachhilfeFehlermuster.zehnerVergessen);
      expect(_tutor.erkenneFehler(m, 87), NachhilfeFehlermuster.rechenzeichen);
      expect(_tutor.erkenneFehler(m, 73), NachhilfeFehlermuster.zifferndreher);
      expect(_tutor.erkenneFehler(m, 37), NachhilfeFehlermuster.keines);
      final p = NachhilfeAufgabe.additionBis100(37, 25)!;
      expect(_tutor.erkenneFehler(p, 52), NachhilfeFehlermuster.zehnerVergessen);
      expect(_tutor.erkenneFehler(p, 61), NachhilfeFehlermuster.einsDaneben);
      expect(_tutor.erkenneFehler(NachhilfeAufgabe.subtraktion(13, 5)!, 12),
          NachhilfeFehlermuster.einerUmgedreht);
      final mal = NachhilfeAufgabe.mal(6, 7)!;
      expect(_tutor.erkenneFehler(mal, 13), NachhilfeFehlermuster.plusStattMal);
      expect(_tutor.erkenneFehler(mal, 35), NachhilfeFehlermuster.reiheVerrutscht);
      expect(_tutor.erkenneFehler(mal, 49), NachhilfeFehlermuster.reiheVerrutscht);
      expect(_tutor.erkenneFehler(mal, '−'), NachhilfeFehlermuster.keines);
      expect(NachhilfeFehlermuster.einerUmgedreht.rueckmeldung, isNotEmpty);
    });

    test('Fehlermuster wählt den passenden Weg', () {
      expect(
          _tutor.wegFuer(NachhilfeAufgabe.mal(4, 6)!,
              fehler: NachhilfeFehlermuster.plusStattMal),
          NachhilfeWeg.punktefeld);
      expect(
          _tutor.wegFuer(NachhilfeAufgabe.subtraktionBis100(62, 25)!,
              fehler: NachhilfeFehlermuster.einsDaneben),
          NachhilfeWeg.zahlenstrahl);
      expect(
          _tutor.wegFuer(NachhilfeAufgabe.subtraktion(13, 5)!,
              fehler: NachhilfeFehlermuster.zehnerVergessen),
          NachhilfeWeg.zerlegen);
    });
  });

  group('Stufe 1 – kleiner Hinweis', () {
    test('37 + 25 genau wie im Auftrag', () {
      final plan = _tutor.plan(NachhilfeAufgabe.additionBis100(37, 25)!,
          NachhilfeWeg.stangen, NachhilfeStufe.hinweis);
      expect(plan.schritte.last.text,
          'Zerlegen wir 25 in 20 und 5. Was passiert, wenn wir zu 37 zwei Zehner dazulegen?');
      expect(plan.schritte.first.aktion.art, 'stangen');
    });

    test('Einmaleins: Kernaufgaben als Anker', () {
      String tipp(int a, int b) => _tutor
          .plan(NachhilfeAufgabe.mal(a, b)!, NachhilfeWeg.kernaufgabe,
              NachhilfeStufe.hinweis)
          .schritte
          .last
          .text;
      expect(tipp(6, 7), contains('5 · 7'));
      expect(tipp(9, 4), contains('10 · 4'));
      expect(tipp(5, 8), contains('Hälfte von 10 · 8'));
      expect(tipp(3, 6), contains('2 · 6'));
    });

    test('Minus bis 20: erst bis zur 10 zurück', () {
      final plan = _tutor.plan(NachhilfeAufgabe.subtraktion(13, 5)!,
          NachhilfeWeg.zahlenstrahl, NachhilfeStufe.hinweis);
      expect(plan.schritte.last.text, contains('zurück bis zur 10'));
    });
  });

  group('Stufe 2 – andere Erklärung mit Alltagsbeispiel', () {
    test('Eierkarton, Münzen, Teller – mit einer Zwischenfrage', () {
      NachhilfePlan p(NachhilfeAufgabe x) =>
          _tutor.plan(x, _tutor.wegeFuer(x).first, NachhilfeStufe.andereErklaerung);
      final eier = p(NachhilfeAufgabe.addition(8, 5)!);
      expect(eier.schritte.first.text, contains('Eierkarton'));
      expect(eier.schritte.last.frage, 2);
      final geld = p(NachhilfeAufgabe.additionBis100(37, 25)!);
      expect(geld.schritte.first.text, contains('Zehn-Cent-Münzen'));
      expect(geld.schritte.last.frage, 5);
      final teller = p(NachhilfeAufgabe.mal(6, 7)!);
      expect(teller.schritte.first.text, contains('Teller'));
      expect(teller.schritte.last.frage, 35);
      final doppel = p(NachhilfeAufgabe.mal(2, 7)!);
      expect(doppel.schritte.where((s) => s.frage != null), isEmpty,
          reason: 'Die Frage nach 2 Tellern wäre schon das Ergebnis.');
      expect(eier.schritte.first.aktion.art, 'bild');
    });
  });

  group('Stufe 3 – Lumo zeigt am Material', () {
    test('Zehnerstangen bewegen sich Schritt für Schritt, an einem Zwilling', () {
      final original = NachhilfeAufgabe.additionBis100(37, 25)!;
      final plan =
          _tutor.plan(original, NachhilfeWeg.stangen, NachhilfeStufe.vorzeigen);
      expect(plan.anZwilling, isTrue);
      expect(plan.einleitung, contains('37 + 25'));
      final zustaende = plan.schritte
          .where((s) => s.aktion.art == 'stangen')
          .map((s) => '${s.aktion.wert('zehner')}|${s.aktion.wert('einer')}')
          .toList();
      expect(zustaende.toSet().length, zustaende.length,
          reason: 'Jeder Schritt verändert das Material sichtbar.');
      expect(plan.schritte.map((s) => s.id),
          containsAllInOrder(['start', 'zehner', 'bisZehn', 'buendeln']));
    });

    test('Punktefeld 6 · 7: fünf Reihen markiert, dann eine dazu', () {
      final plan = _tutor.plan(NachhilfeAufgabe.mal(6, 7)!,
          NachhilfeWeg.kernaufgabe, NachhilfeStufe.vorzeigen);
      expect(plan.aufgabe.a, 6, reason: 'gleiche Reihenzahl, gleicher Weg');
      final markiert = plan.schritte
          .where((s) => s.aktion.art == 'punkte')
          .map((s) => s.aktion.wert('markiert'))
          .toList();
      expect(markiert, [0, 5, 6]);
    });

    test('Tauschaufgabe: das Feld dreht sich', () {
      final plan = _tutor.plan(NachhilfeAufgabe.mal(7, 5)!,
          NachhilfeWeg.tauschen, NachhilfeStufe.vorzeigen);
      final drehen = plan.schritte.firstWhere((s) => s.id == 'drehen');
      expect(drehen.aktion.wert('gedreht'), 1);
      expect(drehen.text, contains('dasselbe wie'));
    });
  });

  group('Stufe 4 – gemeinsam, das Kind rechnet jeden Schritt', () {
    test('37 + 25: 57, dann fehlende Einer; der Rest bleibt beim Kind', () {
      final plan = _tutor.plan(NachhilfeAufgabe.additionBis100(37, 25)!,
          NachhilfeWeg.stangen, NachhilfeStufe.teilschritt);
      final fragen = [
        for (final s in plan.schritte)
          if (s.frage != null) s.frage
      ];
      expect(fragen, [57, 3]);
      expect(plan.schritte.where((s) => s.frage != null).first.text,
          'Leg 2 Zehnerstangen dazu. Wie viel ist 37 + 20?');
      expect(plan.abschluss, contains('noch 2 übrig'));
      expect(plan.abschluss, contains('37 + 25'));
    });

    test('6 · 7: das Kind rechnet 5 · 7, die letzte Reihe in der Aufgabe', () {
      final plan = _tutor.plan(NachhilfeAufgabe.mal(6, 7)!,
          NachhilfeWeg.kernaufgabe, NachhilfeStufe.teilschritt);
      expect([for (final s in plan.schritte) s.frage].whereType<int>(), [35]);
      expect(plan.abschluss, contains('35 + 7'));
    });

    test('kurze Aufgaben bekommen eine kleine Teilaufgabe statt der Lösung', () {
      final plan = _tutor.plan(NachhilfeAufgabe.additionBis100(45, 30)!,
          NachhilfeWeg.stangen, NachhilfeStufe.teilschritt);
      expect(plan.schritte.last.id, 'klein');
      expect(plan.schritte.last.frage, 7);
    });
  });

  group('Stufe 5 – Verständnisprüfung', () {
    test('eigene ähnliche Aufgabe, anders als die Vorführung', () {
      for (final x in [
        NachhilfeAufgabe.additionBis100(37, 25)!,
        NachhilfeAufgabe.subtraktionBis100(62, 25)!,
        NachhilfeAufgabe.mal(6, 7)!,
        NachhilfeAufgabe.subtraktion(13, 5)!,
        NachhilfeAufgabe.addition(8, 5)!,
      ]) {
        final weg = _tutor.wegeFuer(x).first;
        final zeigen = _tutor.plan(x, weg, NachhilfeStufe.vorzeigen);
        final pruefen = _tutor.plan(x, weg, NachhilfeStufe.ueben);
        expect(pruefen.aufgabe, isNot(x), reason: x.text);
        expect(pruefen.aufgabe, isNot(zeigen.aufgabe), reason: x.text);
        expect(pruefen.aufgabe.zehnerUebergang, x.zehnerUebergang,
            reason: x.text);
      }
    });
  });

  test('Startstufe: Tipp, dann andere Worte, dann zeigt Lumo', () {
    expect(_tutor.startStufe(versuche: 1), NachhilfeStufe.hinweis);
    expect(_tutor.startStufe(versuche: 2), NachhilfeStufe.andereErklaerung);
    expect(_tutor.startStufe(versuche: 3), NachhilfeStufe.vorzeigen);
    expect(_tutor.startStufe(versuche: 0, wiederholteSchwaeche: true),
        NachhilfeStufe.vorzeigen);
  });

  test('3D bleibt beim geprüften Vertrag: nur Plus bis 20, vier Stufen', () {
    expect(
        NativeLearningActivity.fromNachhilfe(NachhilfeAufgabe.mal(6, 7)!,
            startWeg: NachhilfeWeg.kernaufgabe,
            startStufe: NachhilfeStufe.hinweis),
        isNull);
    final activity = NativeLearningActivity.fromNachhilfe(
        NachhilfeAufgabe.addition(8, 5)!,
        startWeg: NachhilfeWeg.rechenrahmen,
        startStufe: NachhilfeStufe.andereErklaerung)!;
    final options = activity.toLaunchOptions();
    expect(options['startStufe'], 'hinweis');
    final stufen = {
      for (final p in options['plaene'] as List) (p as Map)['stufe']
    };
    expect(stufen, {'hinweis', 'teilschritt', 'vorzeigen', 'ueben'});
  });

  for (final typ in [
    NachhilfeTyp.additionBis20,
    NachhilfeTyp.subtraktionBis20,
    NachhilfeTyp.additionBis100,
    NachhilfeTyp.subtraktionBis100,
    NachhilfeTyp.einmaleins,
  ]) {
    test('${typ.name}: alle Aufgaben, alle Wege, alle fünf Stufen', () {
      var plaene = 0;
      for (final original in _alle(typ)) {
        for (final weg in _tutor.wegeFuer(original)) {
          for (final stufe in NachhilfeStufe.values) {
            final plan = _tutor.plan(original, weg, stufe);
            _pruefePlan(
                original, plan, '${original.text} ${weg.name} ${stufe.name}');
            plaene++;
          }
        }
      }
      expect(plaene, greaterThan(100));
    });
  }
}
