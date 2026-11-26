import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_tutor_contracts.dart';
import 'package:lumo_lernen/core/lumo_tutor_engine.dart';
import 'package:lumo_lernen/core/math/lumo_rechentricks.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';

TaskInstance _task(String prompt, Object answer,
    {Map<String, Object?> data = const {},
    LearningSubject subject = LearningSubject.mathematik}) {
  return TaskInstance(
    taskInstanceId: 't',
    templateId: 'legacy.Mathematik.Plus bis 20',
    childId: 'c',
    seedHash: 's',
    subject: subject,
    skillId: const SkillId('legacy.mathematik.plus_bis_20'),
    taskType: TaskType.multipleChoice,
    difficulty: 1,
    parameters: const {},
    prompt: prompt,
    options: const [],
    correctAnswer: answer,
    visualPayload: VisualPayload(type: VisualType.dots, data: data),
    helpPayload: const HelpPayload(),
    generatedAt: DateTime(2026, 11, 17),
  );
}

void main() {
  const tutor = LumoNachhilfe();
  final achtPlusFuenf = NachhilfeAufgabe.addition(8, 5)!;

  group('Aufgabe erkennen', () {
    test('nur geprüfte Additionsdaten mit passender Lösung', () {
      final data = {'operation': 'addition', 'left': 8, 'right': 5};
      expect(NachhilfeAufgabe.ausTask(_task('8 + 5 = ?', 13, data: data)),
          achtPlusFuenf);
      expect(NachhilfeAufgabe.ausTask(_task('8 + 5 = ?', '13', data: data)),
          achtPlusFuenf);
      expect(
          NachhilfeAufgabe.ausTask(_task('8 + 5 = ?', 12, data: data)), isNull,
          reason:
              'Widerspricht die Lösung den Daten, gibt es keine Nachhilfe.');
      expect(
          NachhilfeAufgabe.ausTask(_task('Wie viele Äpfel?', 13, data: data)),
          isNull);
      // Seit dem Fünf-Stufen-Auftrag (Abschnitt 5) gibt es auch für Minus eine
      // Nachhilfe; die Prüfung von Daten, Lösung und Text bleibt gleich streng.
      expect(
          NachhilfeAufgabe.ausTask(_task('9 - 4 = ?', 5,
              data: {'operation': 'subtraction', 'left': 9, 'right': 4})),
          NachhilfeAufgabe.subtraktion(9, 4));
      expect(
          NachhilfeAufgabe.ausTask(_task('9 - 4 = ?', 6,
              data: {'operation': 'subtraction', 'left': 9, 'right': 4})),
          isNull);
      expect(
          NachhilfeAufgabe.ausTask(_task('8 + 5 = ?', 13,
              data: data, subject: LearningSubject.deutsch)),
          isNull);
      expect(NachhilfeAufgabe.addition(15, 9), isNull);
      expect(NachhilfeAufgabe.addition(0, 4), isNull);
    });

    test('Zehnerübergang, Abstand zur 10 und Rest', () {
      expect(achtPlusFuenf.zehnerUebergang, isTrue);
      expect(achtPlusFuenf.bisZehn, 2);
      expect(achtPlusFuenf.rest, 3);
      expect(NachhilfeAufgabe.addition(4, 3)!.zehnerUebergang, isFalse);
      expect(NachhilfeAufgabe.addition(12, 4)!.zehnerUebergang, isFalse);
    });
  });

  group('Wege', () {
    test('mehrere Wege je nach Aufgabenstruktur', () {
      expect(tutor.wegeFuer(achtPlusFuenf), [
        NachhilfeWeg.rechenrahmen,
        NachhilfeWeg.zahlenstrahl,
        NachhilfeWeg.zerlegen
      ]);
      expect(tutor.wegeFuer(NachhilfeAufgabe.addition(6, 7)!),
          contains(NachhilfeWeg.verdoppeln));
      expect(tutor.wegeFuer(NachhilfeAufgabe.addition(3, 9)!).first,
          NachhilfeWeg.tauschen);
      expect(tutor.wegeFuer(NachhilfeAufgabe.addition(4, 3)!),
          isNot(contains(NachhilfeWeg.zerlegen)));
    });

    test('jeder Weg ist mit Rechentrick und Visual-Vertrag verknüpft', () {
      expect(NachhilfeWeg.rechenrahmen.rechentrick, RechentricksKind.bridgeTen);
      expect(
          NachhilfeWeg.verdoppeln.rechentrick, RechentricksKind.neighborTask);
      expect(NachhilfeWeg.tauschen.rechentrick, RechentricksKind.swapNumbers);
      expect(NachhilfeWeg.zahlenstrahl.visual, LumoTutorVisualType.numberLine);
    });

    test('Fehlermuster wählt den passenden Weg', () {
      expect(
          tutor.wegFuer(achtPlusFuenf,
              fehler: NachhilfeFehlermuster.einsDaneben),
          NachhilfeWeg.zahlenstrahl);
      expect(
          tutor.wegFuer(achtPlusFuenf,
              fehler: NachhilfeFehlermuster.zehnerVergessen),
          NachhilfeWeg.zerlegen);
      expect(
          tutor.wegFuer(achtPlusFuenf,
              fehler: NachhilfeFehlermuster.rechenzeichen),
          NachhilfeWeg.rechenrahmen);
      expect(
          tutor.wegFuer(achtPlusFuenf,
              fehler: NachhilfeFehlermuster.einsDaneben,
              schonVersucht: {NachhilfeWeg.zahlenstrahl}),
          NachhilfeWeg.rechenrahmen,
          reason: 'Schon gesehene Wege werden übersprungen.');
      expect(tutor.naechsterWeg(achtPlusFuenf, NachhilfeWeg.zerlegen),
          NachhilfeWeg.rechenrahmen);
    });
  });

  group('Fehlermuster', () {
    test('typische Fehlvorstellungen bei 8 + 5 und 7 + 6', () {
      expect(tutor.erkenneFehler(achtPlusFuenf, 12),
          NachhilfeFehlermuster.einsDaneben);
      expect(tutor.erkenneFehler(achtPlusFuenf, '14'),
          NachhilfeFehlermuster.einsDaneben);
      expect(tutor.erkenneFehler(achtPlusFuenf, 3),
          NachhilfeFehlermuster.rechenzeichen);
      expect(tutor.erkenneFehler(achtPlusFuenf, 31),
          NachhilfeFehlermuster.zifferndreher);
      expect(tutor.erkenneFehler(achtPlusFuenf, 23),
          NachhilfeFehlermuster.zehnerVergessen);
      expect(tutor.erkenneFehler(NachhilfeAufgabe.addition(7, 6)!, 3),
          NachhilfeFehlermuster.zehnerVergessen);
      expect(
          tutor.erkenneFehler(achtPlusFuenf, 13), NachhilfeFehlermuster.keines);
      expect(tutor.erkenneFehler(achtPlusFuenf, null),
          NachhilfeFehlermuster.keines);
      expect(tutor.erkenneFehler(achtPlusFuenf, 'Banane'),
          NachhilfeFehlermuster.keines);
      expect(
          NachhilfeFehlermuster.einsDaneben.fehlerart, ErrorType.countingError);
      expect(NachhilfeFehlermuster.zehnerVergessen.fehlerart,
          ErrorType.tenTransitionWeak);
    });
  });

  group('Hilfestufen', () {
    // Neue Hilfeleiter laut Auftrag (Abschnitt 5): Tipp → andere Erklärung →
    // Lumo zeigt → gemeinsam → Verständnisprüfung. Die 3D-Szene behält ihre
    // vier Stufen (siehe fuer3D).
    test('Leiter Tipp → Anders erklärt → Lumo zeigt → Gemeinsam → Prüfen', () {
      expect(tutor.naechsteStufe(NachhilfeStufe.hinweis),
          NachhilfeStufe.andereErklaerung);
      expect(tutor.naechsteStufe(NachhilfeStufe.andereErklaerung),
          NachhilfeStufe.vorzeigen);
      expect(tutor.naechsteStufe(NachhilfeStufe.vorzeigen),
          NachhilfeStufe.teilschritt);
      expect(
          tutor.naechsteStufe(NachhilfeStufe.teilschritt), NachhilfeStufe.ueben);
      expect(tutor.naechsteStufe(NachhilfeStufe.ueben), isNull);
      expect(NachhilfeStufeInfo.fuer3D.map((s) => s.name),
          ['hinweis', 'teilschritt', 'vorzeigen', 'ueben']);
    });

    test('Startstufe folgt der bestehenden Tutor-Engine', () {
      const engine = LumoTutorEngine();
      NachhilfeStufe aus(int versuche) =>
          NachhilfeStufeInfo.ausHilfeStufe(engine.decideHelpLevel(
              attemptCount: versuche,
              hasRepeatedWeakness: false,
              premiumEnabled: true));
      expect(aus(0), NachhilfeStufe.hinweis);
      expect(aus(1), NachhilfeStufe.hinweis);
      expect(aus(2), NachhilfeStufe.teilschritt);
      expect(aus(3), NachhilfeStufe.vorzeigen);
      for (final stufe in NachhilfeStufeInfo.fuer3D) {
        expect(NachhilfeStufeInfo.ausHilfeStufe(stufe.hilfeStufe), stufe);
      }
      expect(NachhilfeStufe.andereErklaerung.hilfeStufe,
          LumoTutorHelpLevel.hintOnly);
    });

    test(
        'Hinweis und Teilschritt arbeiten an der Originalaufgabe ohne Ergebnis',
        () {
      final hinweis = tutor.plan(
          achtPlusFuenf, NachhilfeWeg.rechenrahmen, NachhilfeStufe.hinweis);
      expect(hinweis.aufgabe, achtPlusFuenf);
      expect(hinweis.schritte.every((s) => s.akteur == NachhilfeAkteur.lumo),
          isTrue);
      final teil = tutor.plan(
          achtPlusFuenf, NachhilfeWeg.rechenrahmen, NachhilfeStufe.teilschritt);
      expect(teil.schritte.first.akteur, NachhilfeAkteur.lumo);
      expect(teil.schritte.last.akteur, NachhilfeAkteur.kind);
      expect(teil.schritte.map((s) => s.id), ['erste', 'zehn'],
          reason:
              'Das Kind macht die Reihe voll, den Rest rechnet es in der Aufgabe.');
    });

    test(
        'Vorzeigen und Üben nutzen verschiedene Zwillingsaufgaben gleicher Struktur',
        () {
      final vor = tutor.plan(
          achtPlusFuenf, NachhilfeWeg.rechenrahmen, NachhilfeStufe.vorzeigen);
      final ueb = tutor.plan(
          achtPlusFuenf, NachhilfeWeg.rechenrahmen, NachhilfeStufe.ueben);
      expect(vor.anZwilling, isTrue);
      expect(ueb.anZwilling, isTrue);
      expect(vor.aufgabe, isNot(ueb.aufgabe));
      expect(vor.aufgabe.zehnerUebergang, isTrue);
      expect(ueb.aufgabe.zehnerUebergang, isTrue);
      expect(
          vor.schritte.every((s) => s.akteur == NachhilfeAkteur.lumo), isTrue);
      expect(
          ueb.schritte.every((s) => s.akteur == NachhilfeAkteur.kind), isTrue);
      expect(vor.schritte.last.aktion.art, 'ergebnis');
      expect(vor.schritte.first.text, startsWith('Ich '));
    });

    test('Lob benennt die Strategie, nicht die Begabung', () {
      final lobe = {for (final w in NachhilfeWeg.values) tutor.lobFuer(w)};
      expect(lobe, hasLength(NachhilfeWeg.values.length));
      for (final lob in lobe) {
        expect(lob.toLowerCase(), isNot(contains('du bist so schlau')));
        expect(lob.toLowerCase(), isNot(contains('talent')));
      }
      expect(tutor.lobFuer(NachhilfeWeg.zahlenstrahl), contains('bis zur 10'));
    });
  });

  test(
      'alle Aufgaben bis 20: Pläne sind konsistent und verraten die Originallösung nie',
      () {
    for (var a = 1; a <= 19; a++) {
      for (var b = 1; a + b <= 20; b++) {
        final original = NachhilfeAufgabe.addition(a, b)!;
        for (final weg in tutor.wegeFuer(original)) {
          for (final stufe in NachhilfeStufe.values) {
            final plan = tutor.plan(original, weg, stufe);
            final label = '$a+$b ${weg.name} ${stufe.name}';
            expect(plan.schritte, isNotEmpty, reason: label);
            if (stufe.anOriginal) {
              expect(plan.aufgabe, original, reason: label);
              expect(
                  plan.schritte.any((s) => s.aktion.art == 'ergebnis'), isFalse,
                  reason: label);
            } else {
              expect(plan.aufgabe.ergebnis, isNot(original.ergebnis),
                  reason: label);
            }
            for (final s in plan.schritte) {
              expect(s.text.length, lessThanOrEqualTo(240), reason: label);
              final x = s.aktion;
              switch (x.art) {
                case 'perlen':
                  expect(x.wert('reihe1'), inInclusiveRange(0, 10),
                      reason: label);
                  expect(x.wert('reihe2'), inInclusiveRange(0, 10),
                      reason: label);
                  expect(x.wert('reihe1') + x.wert('reihe2'),
                      lessThanOrEqualTo(plan.aufgabe.ergebnis),
                      reason: label);
                case 'huepfen':
                  expect(x.wert('nach'), inInclusiveRange(0, 20),
                      reason: label);
                  expect(x.wert('nach'), greaterThan(x.wert('von')),
                      reason: label);
                case 'zerlegen':
                  expect(x.wert('teil1') + x.wert('teil2'), x.wert('ganz'),
                      reason: label);
                  expect(
                      x.zerlegungen.any((z) =>
                          z[0] == x.wert('teil1') && z[1] == x.wert('teil2')),
                      isTrue,
                      reason: label);
                case 'ergebnis':
                  expect(x.wert('richtig'), plan.aufgabe.ergebnis,
                      reason: label);
                  expect(x.optionen, contains(plan.aufgabe.ergebnis),
                      reason: label);
                case 'zeigen':
                case 'bild':
                  break;
                default:
                  fail('unbekannte Aktion ${x.art} bei $label');
              }
            }
            // Der letzte Material-Zustand stellt das Ergebnis dar.
            final perlen =
                plan.schritte.where((s) => s.aktion.art == 'perlen').toList();
            if ((stufe == NachhilfeStufe.vorzeigen ||
                    stufe == NachhilfeStufe.ueben) &&
                perlen.isNotEmpty) {
              final letzte = perlen.last.aktion;
              expect(letzte.wert('reihe1') + letzte.wert('reihe2'),
                  plan.aufgabe.ergebnis,
                  reason: label);
            }
          }
        }
      }
    }
  });

  test('3D-Beschreibung trägt alle Wege und Stufen als JSON-taugliche Daten',
      () {
    final activity = NativeLearningActivity.fromNachhilfe(achtPlusFuenf,
        startWeg: NachhilfeWeg.zerlegen,
        startStufe: NachhilfeStufe.teilschritt,
        fehler: NachhilfeFehlermuster.zehnerVergessen)!;
    final options = activity.toLaunchOptions();
    expect(activity.kind, 'tutor');
    expect(options['a'], 8);
    expect(options['b'], 5);
    expect(options['wege'], ['rechenrahmen', 'zahlenstrahl', 'zerlegen']);
    expect(options['plaene'], hasLength(3 * NachhilfeStufeInfo.fuer3D.length));
    expect(options['fehler'], 'zehnerVergessen');
    final roundTrip = jsonDecode(jsonEncode(options)) as Map<String, dynamic>;
    expect(roundTrip['startStufe'], 'teilschritt');
    expect(
        NativeLearningActivity.fromNachhilfe(achtPlusFuenf,
            startWeg: NachhilfeWeg.verdoppeln,
            startStufe: NachhilfeStufe.hinweis),
        isNull);
    expect(jsonEncode(options).length, lessThan(32000));
  });
}
