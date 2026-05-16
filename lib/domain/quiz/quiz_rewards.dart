/// Coupon-Katalog fuer den Quiz-Modus.
///
/// 3 Schwellen wie bei "Wer wird Millionaer":
///   Milestone 1 (Frage 5):  kleine Belohnungen (Eis, Schoki, Bildschirmzeit)
///   Milestone 2 (Frage 10): mittlere Belohnungen (Kino, Family Park)
///   Milestone 3 (Frage 15): grosse Belohnungen (Spielzeug, Lego, Erlebnisbad)
///
/// Bei Erreichen einer Schwelle wird ZUFAELLIG ein Coupon aus dem Pool gezogen.

import 'package:flutter/foundation.dart';

@immutable
class QuizCoupon {
  const QuizCoupon({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.milestoneLevel,
  });

  final String id;
  final String title;
  final String emoji;
  final String description;
  /// 1 = klein, 2 = mittel, 3 = gross.
  final int milestoneLevel;

  /// Eindeutige Coupon-Code-Generierung (fuer Win-Screen).
  /// Format: LUMO-YYYYMMDD-XXXX
  static String generateCode(QuizCoupon c, DateTime now) {
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final shortId = c.id.toUpperCase().substring(0, c.id.length.clamp(0, 4));
    return 'LUMO-$dateStr-$shortId';
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'emoji': emoji,
        'description': description,
        'milestoneLevel': milestoneLevel,
      };

  factory QuizCoupon.fromJson(Map<String, Object?> json) => QuizCoupon(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        emoji: json['emoji']?.toString() ?? '🎁',
        description: json['description']?.toString() ?? '',
        milestoneLevel: (json['milestoneLevel'] as num?)?.toInt() ?? 1,
      );
}

abstract class QuizRewardCatalog {
  /// Milestone 1 (nach Frage 5) - kleine Belohnungen.
  static const List<QuizCoupon> milestone1 = <QuizCoupon>[
    QuizCoupon(
      id: 'eis_1kugel',
      title: 'Eis – 1 Kugel',
      emoji: '🍦',
      description: 'Beim nächsten Eissalon eine Kugel deiner Wahl.',
      milestoneLevel: 1,
    ),
    QuizCoupon(
      id: 'schoki_klein',
      title: 'Lieblings-Schoki',
      emoji: '🍫',
      description: 'Eine kleine Schoki nach dem Mittagessen.',
      milestoneLevel: 1,
    ),
    QuizCoupon(
      id: 'fernseh_15min',
      title: '15 Min extra Bildschirm',
      emoji: '📺',
      description: '15 Minuten extra Fernseh- oder Tablet-Zeit.',
      milestoneLevel: 1,
    ),
    QuizCoupon(
      id: 'aufbleiben_15min',
      title: '15 Min später ins Bett',
      emoji: '🌙',
      description: 'Heute Abend 15 Minuten länger aufbleiben.',
      milestoneLevel: 1,
    ),
    QuizCoupon(
      id: 'essen_aussuchen',
      title: 'Abendessen aussuchen',
      emoji: '🍝',
      description: 'Du darfst heute das Abendessen bestimmen.',
      milestoneLevel: 1,
    ),
    QuizCoupon(
      id: 'einkaufs_wunsch',
      title: 'Kleinigkeit beim Einkauf',
      emoji: '🛒',
      description: 'Beim nächsten Einkauf eine Kleinigkeit (bis 3 €) aussuchen.',
      milestoneLevel: 1,
    ),
    QuizCoupon(
      id: 'spielplatz_extra',
      title: 'Extra Spielplatz-Zeit',
      emoji: '🎠',
      description: '30 Minuten extra am Spielplatz.',
      milestoneLevel: 1,
    ),
  ];

  /// Milestone 2 (nach Frage 10) - mittlere Belohnungen.
  static const List<QuizCoupon> milestone2 = <QuizCoupon>[
    QuizCoupon(
      id: 'kino_eintritt',
      title: 'Kino-Ausflug',
      emoji: '🎬',
      description: 'Ein Kinderfilm im Kino mit Popcorn.',
      milestoneLevel: 2,
    ),
    QuizCoupon(
      id: 'family_park',
      title: 'Family Park Halbtag',
      emoji: '🎢',
      description: 'Ein halber Tag im Family Park.',
      milestoneLevel: 2,
    ),
    QuizCoupon(
      id: 'eis_3kugel',
      title: 'Großer Eisbecher',
      emoji: '🍨',
      description: 'Ein großer Eisbecher mit 3 Kugeln und Sauce.',
      milestoneLevel: 2,
    ),
    QuizCoupon(
      id: 'pizza_freunde',
      title: 'Pizza-Abend mit Freund:in',
      emoji: '🍕',
      description: 'Du darfst eine Freundin oder einen Freund zum Pizza-Abend einladen.',
      milestoneLevel: 2,
    ),
    QuizCoupon(
      id: 'buch_aussuchen',
      title: 'Buch aussuchen',
      emoji: '📚',
      description: 'Ein Buch aus der Bücherei oder Buchhandlung aussuchen.',
      milestoneLevel: 2,
    ),
    QuizCoupon(
      id: 'eislaufen',
      title: 'Eislaufen-Nachmittag',
      emoji: '⛸️',
      description: 'Eislaufen mit heißem Kakao danach.',
      milestoneLevel: 2,
    ),
  ];

  /// Milestone 3 (nach Frage 15) - grosse Geschenke.
  static const List<QuizCoupon> milestone3 = <QuizCoupon>[
    QuizCoupon(
      id: 'spielzeug_30',
      title: 'Spielzeug bis 30 €',
      emoji: '🧸',
      description: 'Ein Spielzeug deiner Wahl aus dem Spielzeugladen (bis 30 €).',
      milestoneLevel: 3,
    ),
    QuizCoupon(
      id: 'lego_set',
      title: 'Lego-Set',
      emoji: '🧱',
      description: 'Ein eigenes Lego-Set zum Bauen.',
      milestoneLevel: 3,
    ),
    QuizCoupon(
      id: 'erlebnisbad',
      title: 'Erlebnisbad-Tag',
      emoji: '🏊‍♀️',
      description: 'Ein ganzer Tag im Erlebnisbad mit Rutschen.',
      milestoneLevel: 3,
    ),
    QuizCoupon(
      id: 'tiergarten',
      title: 'Tiergarten Schönbrunn',
      emoji: '🦓',
      description: 'Ein voller Tag im Tiergarten mit Mama und Papa.',
      milestoneLevel: 3,
    ),
    QuizCoupon(
      id: 'uebernachtung_oma',
      title: 'Übernachtung bei Oma',
      emoji: '🏡',
      description: 'Eine Nacht bei Oma und Opa schlafen mit Frühstück.',
      milestoneLevel: 3,
    ),
  ];

  /// Liefert den passenden Pool fuer einen Milestone-Level.
  static List<QuizCoupon> poolForLevel(int level) {
    switch (level) {
      case 1:
        return milestone1;
      case 2:
        return milestone2;
      case 3:
        return milestone3;
      default:
        return const <QuizCoupon>[];
    }
  }
}
