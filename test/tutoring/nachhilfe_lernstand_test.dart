import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/nachhilfe_lernstand.dart';

const _komp = 'Addition mit Zehnerübergang';
var _n = 0;

Attempt _a(String prompt, String given, String expected,
        {bool hint = false, int minute = 0, int? ms, String komp = _komp}) =>
    Attempt(
      id: 'a${_n++}',
      studentId: 'kind',
      subject: 'Mathematik',
      unit: 'Plus bis 100',
      competency: komp,
      correct: given == expected,
      at: DateTime(2026, 11, 20, 8).add(Duration(minutes: minute)),
      hintUsed: hint,
      prompt: prompt,
      given: given,
      expected: expected,
      durationMs: ms,
    );

void main() {
  const tutor = LumoNachhilfe();

  test('einzelne Antworten: allein richtig, mit Hilfe richtig, falsch', () {
    expect(einordnen(_a('8 + 5 = ?', '13', '13')),
        NachhilfeBefund.selbststaendigRichtig);
    expect(einordnen(_a('8 + 5 = ?', '13', '13', hint: true)),
        NachhilfeBefund.richtigMitHilfe);
    expect(einordnen(_a('8 + 5 = ?', '3', '13')), NachhilfeBefund.falsch);
  });

  test('wenige Antworten: nichts behaupten', () {
    final stand = NachhilfeLernstand.aus([
      _a('37 + 25 = ?', '52', '62'),
      _a('38 + 24 = ?', '52', '62', minute: 1),
    ], kompetenz: _komp);
    expect(stand.befunde, {NachhilfeBefund.fehlendeDaten});
    expect(stand.aussagekraeftig, isFalse);
    expect(stand.muster, isEmpty,
        reason:
            'Zwei gleiche Fehler bei zwei Antworten sind noch kein Muster.');
    expect(stand.kindSatz, isNull);
    expect(stand.startStufe(tutor, versuche: 1), NachhilfeStufe.hinweis);
    expect(NachhilfeLernstand.aus(const [], kompetenz: _komp).befunde,
        {NachhilfeBefund.fehlendeDaten});
  });

  test('wiederkehrendes mögliches Fehlermuster → Lumo zeigt gleich vor', () {
    final stand = NachhilfeLernstand.aus([
      _a('37 + 25 = ?', '52', '62'),
      _a('46 + 27 = ?', '73', '73', minute: 1),
      _a('48 + 35 = ?', '73', '83', minute: 2),
    ], kompetenz: _komp);
    expect(stand.befunde, contains(NachhilfeBefund.moeglichesFehlermuster));
    expect(stand.muster.first, ('Zehner beim Übergang vergessen', 2));
    expect(stand.haeufigstesMuster, NachhilfeFehlermuster.zehnerVergessen);
    expect(stand.startStufe(tutor, versuche: 1), NachhilfeStufe.vorzeigen);
    expect(stand.kindSatz, isNot(contains('%')));
  });

  test('später bestätigtes Verständnis nach Hilfe', () {
    final stand = NachhilfeLernstand.aus([
      _a('37 + 25 = ?', '52', '62'),
      _a('36 + 27 = ?', '63', '63', hint: true, minute: 1),
      _a('48 + 35 = ?', '83', '83', minute: 60),
      _a('29 + 44 = ?', '73', '73', minute: 120),
    ], kompetenz: _komp);
    expect(
        stand.befunde,
        containsAll([
          NachhilfeBefund.falsch,
          NachhilfeBefund.richtigMitHilfe,
          NachhilfeBefund.selbststaendigRichtig,
          NachhilfeBefund.spaeterBestaetigt,
        ]));
    expect(stand.befunde, isNot(contains(NachhilfeBefund.wiederholungNoetig)));
    expect(stand.startStufe(tutor, versuche: 2), NachhilfeStufe.hinweis);
    expect(stand.kindSatz, contains('allein geschafft'));
  });

  test('richtig mit Hilfe zählt nicht als Bestätigung', () {
    final stand = NachhilfeLernstand.aus([
      _a('37 + 25 = ?', '52', '62'),
      _a('36 + 27 = ?', '63', '63', hint: true, minute: 1),
      _a('48 + 35 = ?', '83', '83', hint: true, minute: 2),
    ], kompetenz: _komp);
    expect(stand.befunde, isNot(contains(NachhilfeBefund.spaeterBestaetigt)));
    expect(stand.selbststaendigRichtig, 0);
    expect(stand.richtigMitHilfe, 2);
  });

  test('Wiederholung nötig: zwei der letzten drei Antworten ohne Hilfe falsch',
      () {
    final stand = NachhilfeLernstand.aus([
      _a('37 + 25 = ?', '62', '62'),
      _a('46 + 27 = ?', '70', '73', minute: 1),
      _a('48 + 35 = ?', '80', '83', minute: 2),
    ], kompetenz: _komp);
    expect(stand.befunde, contains(NachhilfeBefund.wiederholungNoetig));
    expect(stand.wiederholteSchwaeche, isTrue);
    expect(stand.startStufe(tutor, versuche: 0), NachhilfeStufe.vorzeigen);
  });

  test('Geschwindigkeit entscheidet nicht über Verständnis', () {
    List<Attempt> mit(int? ms) => [
          _a('37 + 25 = ?', '52', '62', ms: ms),
          _a('36 + 27 = ?', '63', '63', minute: 1, ms: ms),
          _a('48 + 35 = ?', '83', '83', minute: 2, ms: ms),
          _a('29 + 44 = ?', '73', '73', minute: 3, ms: ms),
        ];
    final langsam = NachhilfeLernstand.aus(mit(95000), kompetenz: _komp);
    final schnell = NachhilfeLernstand.aus(mit(900), kompetenz: _komp);
    final ohne = NachhilfeLernstand.aus(mit(null), kompetenz: _komp);
    expect(langsam.befunde, schnell.befunde);
    expect(langsam.befunde, ohne.befunde);
    expect(langsam.startStufe(tutor, versuche: 1),
        schnell.startStufe(tutor, versuche: 1));
  });

  test('nur dieselbe Kompetenz zählt', () {
    final stand = NachhilfeLernstand.aus([
      _a('6 · 7 = ?', '13', '42', komp: 'Einmaleins'),
      _a('6 · 8 = ?', '14', '48', komp: 'Einmaleins', minute: 1),
      _a('6 · 9 = ?', '15', '54', komp: 'Einmaleins', minute: 2),
      _a('37 + 25 = ?', '62', '62', minute: 3),
    ], kompetenz: 'Einmaleins');
    expect(stand.antworten, 3);
    expect(stand.haeufigstesMuster, NachhilfeFehlermuster.plusStattMal);
    expect(stand.befunde, contains(NachhilfeBefund.wiederholungNoetig));
  });
}
