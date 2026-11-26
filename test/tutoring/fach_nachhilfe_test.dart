import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/fach_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/hilfe_folge.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';

/// Fach-Nachhilfe Englisch, Lesen, Sachunterricht: mehrstufig, aufgabenbezogen,
/// ohne die Lösung der Originalaufgabe zu verraten.
const _faecher = ['Englisch', 'Lesen', 'Sachunterricht'];
const _stufen14 = [
  NachhilfeStufe.hinweis,
  NachhilfeStufe.andereErklaerung,
  NachhilfeStufe.vorzeigen,
  NachhilfeStufe.teilschritt,
];

/// Alle Aufgaben je Fach, Schulstufe und Thema (mehrere Seeds).
Map<(String, int, String), List<FachAufgabe>> _aufgaben() {
  final out = <(String, int, String), List<FachAufgabe>>{};
  for (final fach in _faecher) {
    for (var stufe = 1; stufe <= 4; stufe++) {
      for (final thema
          in Curriculum.unitsForGrade(fach, stufe, currentGradeOnly: true)) {
        final f = ExerciseFactory(seed: stufe * 97 + thema.length);
        final liste = <FachAufgabe>[];
        for (var i = 0; i < 6; i++) {
          final t = f.nextExact(grade: stufe, subject: fach, unit: thema);
          final a = FachAufgabe.ausTask(t);
          if (a != null && !liste.contains(a)) liste.add(a);
        }
        out[(fach, stufe, thema)] = liste;
      }
    }
  }
  return out;
}

bool _enthaeltAntwort(String text, FachAufgabe a) {
  String n(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß0-9]+'), ' ').trim();
  return ' ${n(text)} '.contains(' ${n(a.antwort)} ');
}

void main() {
  const tutor = FachNachhilfe();
  final alle = _aufgaben();

  test('jedes Thema der drei Fächer hat eine Fach-Nachhilfe', () {
    for (final e in alle.entries) {
      expect(e.value, isNotEmpty, reason: '${e.key}');
    }
  });

  test('Stufen 1–4 verraten nie die Lösung der Originalaufgabe', () {
    var geprueft = 0;
    for (final e in alle.entries) {
      final liste = e.value;
      for (var i = 0; i < liste.length; i++) {
        final a = liste[i];
        final beispiel = liste.length > 1 ? liste[(i + 1) % liste.length] : null;
        for (final stufe in _stufen14) {
          final p = tutor.plan(a, stufe, beispiel: beispiel);
          expect(p.stufe, stufe);
          if (p.anBeispiel) {
            // An einem anderen Beispiel darf Lumo es ganz zeigen – aber die
            // Lösung der eigenen Aufgabe kommt darin nicht vor.
            expect(tutor.verraet(p.text, a), isFalse,
                reason: '${e.key} ${a.prompt} → Beispiel ${p.aufgabe.prompt}');
            expect(p.aufgabe.antwort, isNot(a.antwort));
            continue;
          }
          expect(tutor.verraet(p.text, a), isFalse,
              reason: '${e.key} ${stufe.name}: „${p.text}“ (${a.antwort})');
          expect(_enthaeltAntwort(p.text, a), isFalse,
              reason: '${e.key} ${stufe.name}: „${p.text}“ (${a.antwort})');
          for (final k in p.material.schaubild?.knoten ?? const <FachSchaubildKnoten>[]) {
            if (p.material.art == FachMaterialArt.schaubild &&
                k.bild == '❔') {
              continue; // Denk-Karte: Antworten stehen gleichberechtigt da.
            }
            expect(tutor.verraet('${k.titel} ${k.text}', a), isFalse,
                reason: '${e.key} Schaubild „${k.titel}: ${k.text}“ (${a.antwort})');
          }
          geprueft++;
        }
      }
    }
    expect(geprueft, greaterThan(400));
  });

  test('Methodenwechsel: jede Stufe ist eine andere Erklärweise', () {
    for (final e in alle.entries) {
      final a = e.value.first;
      final methoden = {
        for (final s in NachhilfeStufe.values) FachNachhilfe.methodeFuer(a, s),
      };
      expect(methoden, hasLength(5), reason: '${e.key}');
      final varianten = tutor.hilfeVarianten(a,
          beispiel: e.value.length > 1 ? e.value[1] : null);
      final folge = HilfeFolge.folge(
          stufen: HilfeFolge.stufen('Tipp 1.', 'Tipp 2.', 'Tipp 3.'),
          wege: varianten,
          nachhilfeVerfuegbar: true);
      expect(folge.map((v) => v.methode).toSet().length, folge.length);
      expect(folge.length, greaterThanOrEqualTo(6), reason: '${e.key}');
      for (final v in varianten) {
        expect(_enthaeltAntwort(v.text, a) && !v.text.contains('Beispiel'),
            isFalse,
            reason: '${e.key} ${v.methode}: „${v.text}“');
      }
    }
  });

  group('Englisch', () {
    test('Bilder zu den Antworten, Rätsel ohne das Wort, keine Aussprache', () {
      final a = FachAufgabe.aus(
          fach: 'Englisch',
          thema: 'Tiere',
          prompt: 'Was bedeutet „horse“?',
          antwort: 'Pferd',
          auswahl: ['Küken', 'Esel', 'Pferd', 'Fisch'])!;
      final bild = tutor.plan(a, NachhilfeStufe.andereErklaerung);
      expect(bild.material.art, FachMaterialArt.bildkarten);
      expect(bild.material.karten.map((k) => k.wort),
          ['Küken', 'Esel', 'Pferd', 'Fisch'],
          reason: 'alle Antworten gleich behandelt, keine hervorgehoben');
      expect(bild.text, contains('reiten'));
      expect(bild.text, isNot(contains('Pferd')));
      // Die deutsche Stimme spricht kein englisches Wort.
      for (final s in NachhilfeStufe.values.take(3)) {
        final p = tutor.plan(a, s);
        expect(p.sprechText, isNot(contains('horse')), reason: s.name);
      }
      final b = FachAufgabe.aus(
          fach: 'Englisch',
          thema: 'Tiere',
          prompt: 'Was heißt „horse“ hier?',
          antwort: 'Pferd',
          auswahl: ['Kuh', 'Hund', 'Pferd', 'Maus'])!;
      // Dieselbe Lösung wäre kein Beispiel, sondern die Lösung selbst.
      expect(tutor.passtAlsBeispiel(a, b), isFalse);
      final c = FachAufgabe.aus(
          fach: 'Englisch',
          thema: 'Tiere',
          prompt: 'Was bedeutet „cow“?',
          antwort: 'Kuh',
          auswahl: ['Kuh', 'Hund', 'Schaf', 'Maus'],
          erklaerung: 'Das englische Wort „cow“ bedeutet Kuh.')!;
      final zeigt = tutor.plan(a, NachhilfeStufe.vorzeigen, beispiel: c);
      expect(zeigt.anBeispiel, isTrue);
      expect(zeigt.material.sprechblase, 'cow');
      expect(zeigt.material.szeneBild?.bild, '🐄');
      expect(zeigt.text, contains('heißt Kuh'));
      expect(zeigt.sprechText, isNot(contains('cow')));
    });

    test('Deutsch → Englisch: nur das gegebene Wort als Bild', () {
      final a = FachAufgabe.aus(
          fach: 'Englisch',
          thema: 'Wetter',
          prompt: 'Wie heißt „nass“ auf Englisch?',
          antwort: 'wet',
          auswahl: ['dry', 'snow', 'wet', 'sun'])!;
      final p = tutor.plan(a, NachhilfeStufe.andereErklaerung);
      expect(p.material.karten.single.wort, 'nass',
          reason: 'Bilder der englischen Antworten würden sie übersetzen');
      expect(p.sprechText, contains('nass'));
      expect(p.sprechText, isNot(contains('wet')));
    });
  });

  group('Lesen', () {
    test('Frage genau lesen, schwierige Laute, langsam vorlesen, Satz finden',
        () {
      final a = FachAufgabe.aus(
          fach: 'Lesen',
          thema: 'Sätze lesen',
          prompt: 'Lea will draußen malen. Der Wind weht das Papier weg. Lea '
              'malt deshalb in der Küche weiter.\nWarum wechselt Lea den Ort?',
          antwort: 'Der Wind weht das Papier weg.',
          auswahl: [
            'Die Farben sind leer.',
            'Die Sonne ist zu hell.',
            'Der Wind weht das Papier weg.'
          ])!;
      final tipp = tutor.plan(a, NachhilfeStufe.hinweis);
      expect(tipp.text, contains('Warum'));
      expect(tipp.text, contains('weil'));
      final laute = tutor.plan(a, NachhilfeStufe.andereErklaerung);
      expect(laute.material.art, FachMaterialArt.laute);
      expect(laute.material.markiert, contains('ch'));
      final vor = tutor.plan(a, NachhilfeStufe.vorzeigen);
      expect(vor.langsam, isTrue, reason: 'vorhandener Langsamer-Weg');
      expect(vor.material.saetze, hasLength(3));
      expect(vor.sprechText, contains('Küche'));
      final gemeinsam = tutor.plan(a, NachhilfeStufe.teilschritt);
      expect(gemeinsam.material.art, FachMaterialArt.satzWahl);
      expect(gemeinsam.material.richtigerSatz, 1);
    });

    test('Reihenfolge: Lumo fragt nie nach dem gefragten Satz', () {
      final a = FachAufgabe.aus(
        fach: 'Lesen',
        thema: 'Reihenfolge',
        prompt: 'Die Sätze sind durcheinander: Lea malt ein Bild. Lea hängt '
            'das Bild auf. Lea holt Papier.\nWas passiert zuletzt?',
        antwort: 'Lea hängt das Bild auf.',
        auswahl: ['Lea holt Papier.', 'Lea hängt das Bild auf.', 'Lea malt ein Bild.'],
        erklaerung: 'Richtige Reihenfolge: Lea holt Papier. → Lea malt ein '
            'Bild. → Lea hängt das Bild auf.',
      )!;
      final p = tutor.plan(a, NachhilfeStufe.teilschritt);
      expect(p.material.art, FachMaterialArt.satzWahl);
      expect(p.material.saetze[p.material.richtigerSatz!], 'Lea holt Papier.');
    });
  });

  group('Sachunterricht', () {
    test('Schaubild verdeckt, was die Lösung verraten würde', () {
      final a = FachAufgabe.aus(
          fach: 'Sachunterricht',
          thema: 'Wasserkreislauf',
          prompt: 'Was passiert mit Wasser, wenn die Sonne es stark erwärmt?',
          antwort: 'Es verdunstet.',
          auswahl: ['Es gefriert.', 'Es wird zu Stein.', 'Es wird schwerer.', 'Es verdunstet.'])!;
      final p = tutor.plan(a, NachhilfeStufe.vorzeigen);
      expect(p.material.art, FachMaterialArt.schaubild);
      final sb = p.material.schaubild!;
      expect(sb.kreis, isTrue);
      expect(sb.knoten.where((k) => k.verdeckt), isNotEmpty);
      for (final k in sb.knoten) {
        expect('${k.titel} ${k.text}'.toLowerCase(), isNot(contains('verdunst')));
      }
      final alltag = tutor.plan(a, NachhilfeStufe.andereErklaerung);
      expect(alltag.text, contains('Pfütze'));
      final tipp = tutor.plan(a, NachhilfeStufe.hinweis);
      expect(tipp.text, contains('„Sonne“'));
    });

    test('Ampel: „Gelb“ wird verdeckt, wenn danach gefragt wird', () {
      final a = FachAufgabe.aus(
          fach: 'Sachunterricht',
          thema: 'Verkehr',
          prompt: 'Was bedeutet ein gelbes Licht an der Ampel?',
          antwort: 'Achtung, gleich wechselt die Ampel.',
          auswahl: [
            'Nur Fußgänger dürfen gehen.',
            'Schnell losfahren!',
            'Die Ampel ist kaputt.',
            'Achtung, gleich wechselt die Ampel.'
          ])!;
      final sb = tutor.plan(a, NachhilfeStufe.vorzeigen).material.schaubild!;
      final gelb = sb.knoten.singleWhere((k) => k.titel == 'Gelb');
      expect(gelb.verdeckt, isTrue);
      expect(gelb.text, '?');
    });
  });

  test('Prüfaufgabe: ähnlich, eigenständig, andere Lösung', () {
    for (final e in alle.entries) {
      final liste = e.value;
      if (liste.length < 2) continue;
      final p = tutor.plan(liste[0], NachhilfeStufe.ueben, pruefung: liste[1]);
      expect(p.material.art, FachMaterialArt.pruefen);
      if (liste[1].antwort != liste[0].antwort) {
        expect(p.aufgabe, liste[1], reason: '${e.key}');
        expect(p.material.auswahl, liste[1].auswahl);
      }
      final pr = FachPruefung(
          aufgabe: liste[1], antwort: liste[1].antwort, versuche: 1, methode: 'x');
      expect(pr.selbststaendig, isTrue);
      expect(
          FachPruefung(
                  aufgabe: liste[1],
                  antwort: liste[1].antwort,
                  versuche: 2,
                  methode: 'x')
              .selbststaendig,
          isFalse);
    }
  });

  test('Mathe und Deutsch bekommen keine Fach-Nachhilfe (Fachtrennung)', () {
    expect(
        FachAufgabe.aus(
            fach: 'Mathematik',
            thema: 'Plus bis 10',
            prompt: '3 + 4 = ?',
            antwort: '7',
            auswahl: ['6', '7', '8']),
        isNull);
    expect(
        FachAufgabe.aus(
            fach: 'Deutsch',
            thema: 'Silben',
            prompt: 'Wie viele Silben hat „Banane“?',
            antwort: '3',
            auswahl: ['2', '3', '4']),
        isNull);
  });
}
