import '../school/attempt.dart';
import 'game_level_catalog.dart';

/// Nachweis, dass ein Kind den Inhalt einer Lernspiel-Stufe beim Üben schon
/// sicher kann: genug eigene Antworten ohne Hilfe, fast alle richtig.
class GameLevelEvidence {
  const GameLevelEvidence(
      {required this.levelId,
      required this.topic,
      required this.considered,
      required this.correct});

  final int levelId;

  /// Was geübt wurde, z. B. „Plus bis 100“ oder die 3er-Reihe.
  final String topic;

  /// Gewertete letzte Antworten ohne Hilfe und davon richtige.
  final int considered;
  final int correct;

  /// Kurzer Satz für Kind und Eltern; nennt nur tatsächlich Gemessenes.
  String get note =>
      'Freigeschaltet, weil du $topic beim Üben schon sicher kannst: '
      '$correct von $considered Aufgaben ohne Hilfe richtig.';
}

/// Adaptive Freischaltung der Lernspiel-Stufen aus dem vorhandenen
/// Übungsprotokoll. Wenige Daten schalten nichts frei: Es zählen nur eigene
/// Antworten ohne Hilfe aus genau dem passenden Übungsthema, mindestens
/// [minIndependent], und von den letzten [window] davon mindestens
/// [minAccuracy] richtig. Freigaben ändern nie Sterne oder gespeicherte
/// Spielstände; sie werden bei jedem Laden neu aus den Lerndaten bestimmt.
abstract class GameLevelReadiness {
  GameLevelReadiness._();

  static const int minIndependent = 8;
  static const int window = 10;
  static const double minAccuracy = 0.85;

  /// Stufe → passende Übungsthemen und (beim Einmaleins) die geübten Reihen.
  /// „Kleines/Großes 1×1“ sind die Schlüssel des Einmaleins-Lernmoduls.
  static const Map<int, (Set<String>, Set<int>)> evidenceFor = {
    16: ({'Plus bis 20'}, <int>{}),
    17: ({'Minus bis 20'}, <int>{}),
    39: ({'Plus bis 100'}, <int>{}),
    45: ({'Minus bis 100'}, <int>{}),
    41: (_timesUnits, <int>{2, 5}),
    42: (_timesUnits, <int>{3}),
    46: (_timesUnits, <int>{10, 4}),
    48: ({'Schriftliche Addition'}, <int>{}),
    49: ({'Schriftliche Subtraktion'}, <int>{}),
  };

  static const Set<String> _timesUnits = {
    'Einmaleins',
    'Kleines 1×1',
    'Großes 1×1',
  };

  static final RegExp _times = RegExp(r'(\d+)\s*[×x·*]\s*(\d+)');

  static bool _matches(Attempt attempt, Set<String> units, Set<int> rows) {
    if (attempt.subject != 'Mathematik' ||
        !units.contains(attempt.unit.trim())) {
      return false;
    }
    if (rows.isEmpty) return true;
    final match = _times.firstMatch(attempt.prompt);
    if (match == null) return false;
    final a = int.parse(match.group(1)!), b = int.parse(match.group(2)!);
    return rows.contains(a) || rows.contains(b);
  }

  static String _rowsTitle(Set<int> rows) {
    final sorted = rows.toList()..sort();
    return sorted.length == 1
        ? 'die ${sorted.first}er-Reihe'
        : 'die ${sorted.join('er- und ')}er-Reihe';
  }

  /// Stufen mit belastbarem Nachweis, ohne die bereits gespielten.
  static Map<int, GameLevelEvidence> proven(Iterable<Attempt> attempts,
      {Map<int, int> stars = const {}}) {
    final result = <int, GameLevelEvidence>{};
    final independent = [
      for (final attempt in attempts)
        if (!attempt.hintUsed) attempt
    ]..sort((x, y) => x.at.compareTo(y.at));
    for (final entry in evidenceFor.entries) {
      final level = GameLevelCatalog.byId(entry.key);
      if (level == null || (stars[entry.key] ?? 0) > 0) continue;
      final (units, rows) = entry.value;
      final matching = [
        for (final attempt in independent)
          if (_matches(attempt, units, rows)) attempt
      ];
      if (matching.length < minIndependent) continue;
      final recent = matching.sublist(
          matching.length > window ? matching.length - window : 0);
      final correct = recent.where((attempt) => attempt.correct).length;
      if (correct / recent.length < minAccuracy) continue;
      result[entry.key] = GameLevelEvidence(
          levelId: entry.key,
          topic: rows.isEmpty ? '„${units.first}“' : _rowsTitle(rows),
          considered: recent.length,
          correct: correct);
    }
    return result;
  }
}
