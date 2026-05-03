import 'progress_repository.dart';

enum ScannedWorkType { homework, test, schoolwork, worksheet, unknown }

class ScannedWorkAnalysis {
  const ScannedWorkAnalysis({
    required this.rawText,
    required this.workType,
    required this.subject,
    required this.primaryUnit,
    required this.strengthUnits,
    required this.weakUnits,
    required this.signals,
    required this.childSummary,
    required this.parentSummary,
    required this.practiceTip,
    required this.calmTip,
  });

  final String rawText;
  final ScannedWorkType workType;
  final String subject;
  final String primaryUnit;
  final List<String> strengthUnits;
  final List<String> weakUnits;
  final List<String> signals;
  final String childSummary;
  final String parentSummary;
  final String practiceTip;
  final String calmTip;

  bool get hasWeaknesses => weakUnits.isNotEmpty;
  String get nextPracticeSubject => subject == 'Unklar' ? 'Alle' : subject;
  String get nextPracticeUnit => weakUnits.isNotEmpty ? weakUnits.first : primaryUnit;

  String get workTypeLabel {
    switch (workType) {
      case ScannedWorkType.test:
        return 'Test';
      case ScannedWorkType.schoolwork:
        return 'Schularbeit';
      case ScannedWorkType.homework:
        return 'Hausaufgabe';
      case ScannedWorkType.worksheet:
        return 'Arbeitsblatt';
      case ScannedWorkType.unknown:
        return 'Aufgabe';
    }
  }
}

/// Verbindet OCR-Text aus dem Scanner mit der Lernlogik.
///
/// Wichtig: Die Analyse ist bewusst heuristisch und offline. Sie ersetzt keine
/// Lehrkraft-Korrektur. Sie erkennt aber Fach, Thema, mögliche Fehlerstellen,
/// Teststress-Signale und sinnvolle Anschlussübungen.
class ScannedWorkAnalysisEngine {
  const ScannedWorkAnalysisEngine();

  ScannedWorkAnalysis analyze({
    required String rawText,
    required int grade,
    required Map<String, SkillRecord> existingSkills,
  }) {
    final text = rawText.trim();
    final lower = text.toLowerCase();
    final workType = _workType(lower);
    final subject = _subject(lower);
    final units = _units(lower, subject: subject, grade: grade);
    final signals = _signals(lower);
    final weakUnits = _weakUnits(
      lower,
      subject: subject,
      units: units,
      signals: signals,
      existingSkills: existingSkills,
    );
    final strengthUnits = _strengthUnits(
      lower,
      subject: subject,
      units: units,
      weakUnits: weakUnits,
      existingSkills: existingSkills,
    );
    final primaryUnit = units.isNotEmpty ? units.first : _defaultUnitFor(subject);
    final calmTip = _calmTip(workType, signals);
    final practiceTip = _practiceTip(subject, weakUnits.isNotEmpty ? weakUnits.first : primaryUnit, workType);
    final childSummary = _childSummary(
      workType: workType,
      subject: subject,
      primaryUnit: primaryUnit,
      weakUnits: weakUnits,
      strengthUnits: strengthUnits,
      calmTip: calmTip,
    );
    final parentSummary = _parentSummary(
      workType: workType,
      subject: subject,
      primaryUnit: primaryUnit,
      weakUnits: weakUnits,
      strengthUnits: strengthUnits,
      signals: signals,
      existingSkills: existingSkills,
      practiceTip: practiceTip,
      calmTip: calmTip,
    );

    return ScannedWorkAnalysis(
      rawText: text,
      workType: workType,
      subject: subject,
      primaryUnit: primaryUnit,
      strengthUnits: strengthUnits,
      weakUnits: weakUnits,
      signals: signals,
      childSummary: childSummary,
      parentSummary: parentSummary,
      practiceTip: practiceTip,
      calmTip: calmTip,
    );
  }

  ScannedWorkType _workType(String lower) {
    if (_any(lower, const ['schularbeit', 'schulübung', 'schuluebung'])) return ScannedWorkType.schoolwork;
    if (_any(lower, const ['test', 'probe', 'lernzielkontrolle', 'kontrolle', 'punkte', 'note'])) return ScannedWorkType.test;
    if (_any(lower, const ['hausaufgabe', 'hausübung', 'hausuebung', 'hü', 'hue'])) return ScannedWorkType.homework;
    if (_any(lower, const ['arbeitsblatt', 'blatt', 'übungsblatt', 'uebungsblatt'])) return ScannedWorkType.worksheet;
    return ScannedWorkType.unknown;
  }

  String _subject(String lower) {
    final mathScore = _score(lower, const ['+', '-', 'mal', 'geteilt', 'rechne', 'rechnung', 'zahl', 'zahlen', 'ergebnis', 'summe', 'differenz', 'zehner', 'einer', 'uhr', 'euro', 'cent']);
    final germanScore = _score(lower, const ['satz', 'sätze', 'saetze', 'nomen', 'namenwort', 'hauptwort', 'tunwort', 'verb', 'wiewort', 'artikel', 'silbe', 'reim', 'schreibweise', 'rechtschreibung', 'lesen']);
    final englishScore = _score(lower, const ['english', 'englisch', 'translate', 'übersetze', 'uebersetze', 'colour', 'color', 'red', 'blue', 'green', 'yellow', 'cat', 'dog', 'schoolbag', 'book']);
    final scienceScore = _score(lower, const ['sachunterricht', 'tier', 'tiere', 'pflanze', 'wetter', 'jahreszeit', 'körper', 'koerper', 'verkehr', 'ampel', 'kalender', 'wasser', 'luft']);

    final scores = <String, int>{
      'Mathematik': mathScore,
      'Deutsch': germanScore,
      'Englisch': englishScore,
      'Sachunterricht': scienceScore,
    };
    final best = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return best.first.value <= 0 ? 'Unklar' : best.first.key;
  }

  List<String> _units(String lower, {required String subject, required int grade}) {
    final units = <String>[];
    void addIf(bool condition, String unit) {
      if (condition && !units.contains(unit)) units.add(unit);
    }

    if (subject == 'Mathematik') {
      addIf(lower.contains('+') || lower.contains('plus') || lower.contains('summe'), grade <= 2 ? 'Plus bis 20' : 'Addition');
      addIf(lower.contains('-') || lower.contains('minus') || lower.contains('differenz'), grade <= 2 ? 'Minus bis 20' : 'Subtraktion');
      addIf(_any(lower, const ['mal', '×', '*', 'einmaleins']), 'Einmaleins');
      addIf(_any(lower, const ['geteilt', ':', 'division']), 'Division');
      addIf(_any(lower, const ['zehner', 'einer', 'stellenwert']), 'Zehner und Einer');
      addIf(_any(lower, const ['uhr', 'minute', 'stunde']), 'Uhrzeit');
      addIf(_any(lower, const ['euro', 'cent', 'geld']), 'Geld');
    } else if (subject == 'Deutsch') {
      addIf(_any(lower, const ['schreibweise', 'rechtschreibung', 'fehlerwort', 'verbessere']), 'Rechtschreibung');
      addIf(_any(lower, const ['satz', 'sätze', 'saetze', 'satzzeichen']), 'Satzbau');
      addIf(_any(lower, const ['nomen', 'namenwort', 'hauptwort']), 'Namenwörter');
      addIf(_any(lower, const ['tunwort', 'verb']), 'Tunwörter');
      addIf(_any(lower, const ['wiewort', 'eigenschaft']), 'Wiewörter');
      addIf(_any(lower, const ['silbe', 'silben']), 'Silben');
      addIf(_any(lower, const ['reim', 'reimt']), 'Reime');
      addIf(_any(lower, const ['lesen', 'text', 'geschichte']), 'Lesen');
    } else if (subject == 'Englisch') {
      addIf(_any(lower, const ['red', 'blue', 'green', 'yellow', 'colour', 'color', 'farbe']), 'Farben');
      addIf(_any(lower, const ['one', 'two', 'three', 'four', 'five', 'zahl']), 'Zahlen');
      addIf(_any(lower, const ['cat', 'dog', 'bird', 'fish', 'tier']), 'Tiere');
      addIf(_any(lower, const ['book', 'schoolbag', 'pen', 'pencil', 'school']), 'Schulsachen');
      addIf(_any(lower, const ['hello', 'goodbye', 'thank you']), 'Begrüßung');
    } else if (subject == 'Sachunterricht') {
      addIf(_any(lower, const ['tier', 'tiere', 'biene', 'hund', 'katze', 'fisch']), 'Tiere');
      addIf(_any(lower, const ['pflanze', 'blatt', 'wurzel', 'wasser', 'licht']), 'Pflanzen');
      addIf(_any(lower, const ['wetter', 'regen', 'schnee', 'sonne', 'thermometer']), 'Wetter');
      addIf(_any(lower, const ['verkehr', 'ampel', 'helm', 'straße', 'strasse']), 'Verkehr');
      addIf(_any(lower, const ['körper', 'koerper', 'auge', 'ohr', 'hand', 'kopf']), 'Körper');
      addIf(_any(lower, const ['jahreszeit', 'frühling', 'fruehling', 'sommer', 'herbst', 'winter']), 'Jahreszeiten');
    }

    return units;
  }

  List<String> _signals(String lower) {
    final signals = <String>[];
    void addIf(bool condition, String signal) {
      if (condition && !signals.contains(signal)) signals.add(signal);
    }

    addIf(_any(lower, const ['falsch', 'fehler', 'verbessere', 'korrektur', 'nicht richtig']), 'Fehler/Korrektur erkannt');
    addIf(RegExp(r'\b0\s*/\s*\d+|\b1\s*/\s*\d+|\b2\s*/\s*\d+').hasMatch(lower), 'niedrige Punktezahl möglich');
    addIf(_any(lower, const ['punkte', 'pkt', 'note']), 'Testbewertung erkannt');
    addIf(_any(lower, const ['zeit', 'schnell', 'zu langsam', 'fertig werden']), 'Zeitdruck möglich');
    addIf(_any(lower, const ['angst', 'nervös', 'nervoes', 'aufgeregt', 'blackout']), 'Testnervosität möglich');
    addIf(_any(lower, const ['flüchtig', 'fluechtig', 'übersehen', 'uebersehen']), 'Flüchtigkeitsfehler möglich');

    return signals;
  }

  List<String> _weakUnits(
    String lower, {
    required String subject,
    required List<String> units,
    required List<String> signals,
    required Map<String, SkillRecord> existingSkills,
  }) {
    final weak = <String>[];
    final hasMistakeSignal = signals.any((s) => s.contains('Fehler') || s.contains('niedrige') || s.contains('Flüchtigkeit'));
    if (hasMistakeSignal) weak.addAll(units);

    for (final unit in units) {
      final record = existingSkills[SkillRecord.makeId(subject, unit)];
      if (record != null && record.currentMisses >= 2 && !weak.contains(unit)) weak.add(unit);
      if (record != null && record.weaknessScore >= 0.45 && !weak.contains(unit)) weak.add(unit);
    }

    if (weak.isEmpty && hasMistakeSignal) weak.add(_defaultUnitFor(subject));
    return weak.take(3).toList(growable: false);
  }

  List<String> _strengthUnits(
    String lower, {
    required String subject,
    required List<String> units,
    required List<String> weakUnits,
    required Map<String, SkillRecord> existingSkills,
  }) {
    final strengths = <String>[];
    final positiveSignal = _any(lower, const ['richtig', 'sehr gut', 'bravo', 'gut gemacht', 'punkte']) && !_any(lower, const ['falsch', 'fehler']);
    for (final unit in units) {
      final record = existingSkills[SkillRecord.makeId(subject, unit)];
      if (record != null && record.currentStreak >= 3 && !weakUnits.contains(unit)) strengths.add(unit);
      if (positiveSignal && !weakUnits.contains(unit)) strengths.add(unit);
    }
    return strengths.toSet().take(3).toList(growable: false);
  }

  String _childSummary({
    required ScannedWorkType workType,
    required String subject,
    required String primaryUnit,
    required List<String> weakUnits,
    required List<String> strengthUnits,
    required String calmTip,
  }) {
    final type = _workTypeLabel(workType);
    if (weakUnits.isEmpty) {
      return 'Ich habe deine $type angeschaut. Ich erkenne vor allem $subject – $primaryUnit. Das sieht nach einem guten nächsten Übungsstart aus. $calmTip';
    }
    return 'Ich habe deine $type angeschaut. Wir üben jetzt zuerst ${weakUnits.first}. Das ist kein Problem: Fehler zeigen nur, wo Lumo dir helfen kann. $calmTip';
  }

  String _parentSummary({
    required ScannedWorkType workType,
    required String subject,
    required String primaryUnit,
    required List<String> weakUnits,
    required List<String> strengthUnits,
    required List<String> signals,
    required Map<String, SkillRecord> existingSkills,
    required String practiceTip,
    required String calmTip,
  }) {
    final buffer = StringBuffer()
      ..writeln('${_workTypeLabel(workType)} erkannt: $subject / $primaryUnit.')
      ..writeln('Anschlussübung: $practiceTip');

    if (weakUnits.isNotEmpty) {
      buffer.writeln('Mögliche Schwächen: ${weakUnits.join(', ')}.');
      for (final unit in weakUnits) {
        final record = existingSkills[SkillRecord.makeId(subject, unit)];
        if (record != null && record.mastery >= 70) {
          buffer.writeln('Auffällig: $unit klappt im Übungsmodus bereits recht gut (${record.mastery} % Mastery), taucht aber im Scan als Fehlerbereich auf. Das spricht eher für Testdruck, Tempo oder Flüchtigkeit als für fehlendes Grundverständnis.');
        }
      }
    } else {
      buffer.writeln('Keine klare Schwäche im OCR-Text erkannt. Lumo startet mit einer passenden Wiederholung.');
    }
    if (strengthUnits.isNotEmpty) {
      buffer.writeln('Stärken laut Profil/Scan: ${strengthUnits.join(', ')}.');
    }
    if (signals.isNotEmpty) {
      buffer.writeln('Erkannte Hinweise: ${signals.join(', ')}.');
    }
    buffer.writeln('Soziale Lernhilfe: $calmTip');
    return buffer.toString().trim();
  }

  String _practiceTip(String subject, String unit, ScannedWorkType workType) {
    final prefix = workType == ScannedWorkType.test || workType == ScannedWorkType.schoolwork
        ? 'Nach Test/Schularbeit zuerst langsam und ohne Zeitdruck üben:'
        : 'Nächste Übung:';
    return '$prefix $subject – $unit. Erst 3 leichte Aufgaben, dann 2 ähnliche Testaufgaben.';
  }

  String _calmTip(ScannedWorkType workType, List<String> signals) {
    if (signals.any((s) => s.contains('Nervosität')) || workType == ScannedWorkType.test || workType == ScannedWorkType.schoolwork) {
      return 'Test-Trick: erst tief einatmen, die leichteste Aufgabe suchen, markieren, dann Schritt für Schritt lösen. Nicht raten, sondern lautlos erklären: Was ist gefragt? Was weiß ich schon?';
    }
    if (signals.any((s) => s.contains('Zeitdruck'))) {
      return 'Tempo-Trick: erst sauber, dann schneller. Eine richtige langsame Aufgabe ist besser als drei hastige Fehler.';
    }
    if (signals.any((s) => s.contains('Flüchtigkeit'))) {
      return 'Kontroll-Trick: am Ende jede Antwort einmal mit dem Finger nachfahren und prüfen: Habe ich wirklich die Frage beantwortet?';
    }
    return 'Lumo bleibt ruhig: kleine Schritte, kurze Pause, dann weiter.';
  }

  String _defaultUnitFor(String subject) {
    switch (subject) {
      case 'Mathematik':
        return 'Gemischtes Rechnen';
      case 'Deutsch':
        return 'Lesen und Schreiben';
      case 'Englisch':
        return 'Grundwortschatz';
      case 'Sachunterricht':
        return 'Forschen und Verstehen';
      default:
        return 'Alle Themen';
    }
  }

  String _workTypeLabel(ScannedWorkType workType) {
    switch (workType) {
      case ScannedWorkType.test:
        return 'Test';
      case ScannedWorkType.schoolwork:
        return 'Schularbeit';
      case ScannedWorkType.homework:
        return 'Hausaufgabe';
      case ScannedWorkType.worksheet:
        return 'Arbeitsblatt';
      case ScannedWorkType.unknown:
        return 'Aufgabe';
    }
  }

  bool _any(String lower, List<String> terms) => terms.any(lower.contains);

  int _score(String lower, List<String> terms) => terms.where(lower.contains).length;
}
