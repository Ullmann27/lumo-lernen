/// Sprint 7 - Wochen-Challenge-Scaffold fuer Lumo Spielewelt.
///
/// Jede Woche bekommt das Kind ein kleines neues Set von Levels.
/// Vorgeneriert, offline-faehig, kein Server-Zwang.
///
/// Konzept:
///   - 4 vorgenerierte WeeklyChallengeSet (kann spaeter erweitert werden)
///   - jedes Set hat 5-10 Level-IDs aus dem Hauptkatalog
///   - aktive Woche wird per ISO-Wochenzahl ausgewaehlt
///   - kein Cloud-Sync; pure Offline-Logik

import 'package:flutter/foundation.dart';

@immutable
class WeeklyChallengeLevel {
  const WeeklyChallengeLevel({
    required this.catalogLevelId,
    required this.bonusStars,
  });

  /// Verweis auf eine Level-ID aus GameLevelCatalog (1-50).
  final int catalogLevelId;

  /// Zusatz-Sterne wenn das Level im Wochen-Kontext geschafft wird.
  final int bonusStars;
}

@immutable
class WeeklyChallengeSet {
  const WeeklyChallengeSet({
    required this.id,
    required this.title,
    required this.theme,
    required this.weekModulo,
    required this.levels,
    this.targetGrade = 1,
  });

  /// 'week_addition_focus' etc.
  final String id;

  final String title;

  /// Kurze Beschreibung des Themas.
  final String theme;

  /// Dieses Set ist aktiv wenn (isoWeekOfYear % availableSetCount) == weekModulo.
  /// Mit 4 Sets rotiert dadurch alle 4 Wochen.
  final int weekModulo;

  final List<WeeklyChallengeLevel> levels;

  final int targetGrade;

  int get totalLevels => levels.length;
}

/// Statischer Katalog der vorgenerierten Wochen-Challenge-Sets.
abstract class WeeklyChallengeCatalog {
  WeeklyChallengeCatalog._();

  /// 4 Sets, rotieren wochenweise.
  static const List<WeeklyChallengeSet> sets = <WeeklyChallengeSet>[
    WeeklyChallengeSet(
      id: 'week_addition_focus',
      title: 'Plus-Woche',
      theme: 'Diese Woche ueben wir Plus bis 20',
      weekModulo: 0,
      targetGrade: 1,
      levels: <WeeklyChallengeLevel>[
        WeeklyChallengeLevel(catalogLevelId: 1, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 3, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 5, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 9, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 16, bonusStars: 2),
      ],
    ),
    WeeklyChallengeSet(
      id: 'week_subtraction_focus',
      title: 'Minus-Woche',
      theme: 'Diese Woche kommt Minus dran',
      weekModulo: 1,
      targetGrade: 1,
      levels: <WeeklyChallengeLevel>[
        WeeklyChallengeLevel(catalogLevelId: 11, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 12, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 14, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 17, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 20, bonusStars: 2),
      ],
    ),
    WeeklyChallengeSet(
      id: 'week_reading_focus',
      title: 'Lese-Woche',
      theme: 'Buchstaben, Silben und erste Woerter',
      weekModulo: 2,
      targetGrade: 1,
      levels: <WeeklyChallengeLevel>[
        WeeklyChallengeLevel(catalogLevelId: 21, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 22, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 23, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 26, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 30, bonusStars: 2),
      ],
    ),
    WeeklyChallengeSet(
      id: 'week_mix_focus',
      title: 'Misch-Woche',
      theme: 'Alles ist erlaubt - bunter Mix aus Mathe und Deutsch',
      weekModulo: 3,
      targetGrade: 2,
      levels: <WeeklyChallengeLevel>[
        WeeklyChallengeLevel(catalogLevelId: 10, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 25, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 31, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 34, bonusStars: 1),
        WeeklyChallengeLevel(catalogLevelId: 40, bonusStars: 2),
      ],
    ),
  ];

  /// ISO-Wochenzahl fuer ein Datum berechnen.
  /// Vereinfachte Implementation: Tage seit 1.1. / 7 (genau genug fuer
  /// rotierende Wochen-Sets, kein offizielles ISO 8601).
  static int isoWeekOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(start).inDays;
    return (dayOfYear / 7).floor() + 1;
  }

  /// Aktives Set fuer ein gegebenes Datum.
  static WeeklyChallengeSet activeFor(DateTime date) {
    final week = isoWeekOfYear(date);
    final modulo = week % sets.length;
    return sets.firstWhere((s) => s.weekModulo == modulo, orElse: () => sets.first);
  }
}
