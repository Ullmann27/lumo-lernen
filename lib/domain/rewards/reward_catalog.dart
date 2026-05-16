/// Katalog aller Belohnungen die Heinz' Toechter Alina und Zoe einloesen koennen.
/// Aufgeteilt nach Jahreszeit und Groessen-Klasse.
///
/// Heinz' Wuensche:
///   - kleine: Eis, Schwimmen, Einkauf-Wunsch
///   - mittel: kleine Ausfluege
///   - gross: Spielzeug aus dem Spielzeugladen (z.B. bei guten Noten)
///
/// Saisonale Verfuegbarkeit:
///   - Eis nur Fruehling/Sommer
///   - Schwimmen Sommer
///   - Christkindlmarkt nur Winter
///   - Schlitten fahren Winter
///   - Kuerbis schnitzen Herbst
///   - etc.

import 'reward_shop.dart';

abstract class RewardCatalog {
  RewardCatalog._();

  static const List<RewardItem> all = <RewardItem>[
    // ─────────────────── KLEINE BELOHNUNGEN (Sterne) ───────────────────

    // Ganzjaehrig verfuegbar
    RewardItem(
      id: 'small_extra_screen_time',
      title: 'Extra Bildschirm-Zeit',
      emoji: '📺',
      description: '15 Minuten extra fernsehen oder Tablet.',
      cost: 20,
      currency: RewardCurrency.stars,
      seasons: <Season>[],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_late_bedtime',
      title: '15 Minuten länger aufbleiben',
      emoji: '🌙',
      description: 'Heute 15 Minuten später ins Bett.',
      cost: 25,
      currency: RewardCurrency.stars,
      seasons: <Season>[],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_choose_dinner',
      title: 'Essen aussuchen',
      emoji: '🍝',
      description: 'Du darfst heute aussuchen, was es zum Abendessen gibt.',
      cost: 30,
      currency: RewardCurrency.stars,
      seasons: <Season>[],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_chocolate',
      title: 'Lieblingsschoki',
      emoji: '🍫',
      description: 'Eine kleine Schoki nach dem Mittagessen.',
      cost: 30,
      currency: RewardCurrency.stars,
      seasons: <Season>[],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_shopping_wish',
      title: 'Einkaufs-Wunsch',
      emoji: '🛒',
      description: 'Beim nächsten Einkauf eine Kleinigkeit aussuchen (bis 3 €).',
      cost: 40,
      currency: RewardCurrency.stars,
      seasons: <Season>[],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_movie_night',
      title: 'Filmabend',
      emoji: '🎬',
      description: 'Du darfst einen Film aussuchen für den Familienabend.',
      cost: 50,
      currency: RewardCurrency.stars,
      seasons: <Season>[],
      tier: RewardTier.small,
    ),

    // Fruehling/Sommer
    RewardItem(
      id: 'small_ice_cream',
      title: 'Eis essen gehen',
      emoji: '🍦',
      description: 'Ein Eis vom Eissalon (1 Kugel).',
      cost: 50,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.spring, Season.summer],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_playground',
      title: 'Lange Spielplatz-Zeit',
      emoji: '🎠',
      description: '1 Stunde extra am Spielplatz.',
      cost: 30,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.spring, Season.summer, Season.autumn],
      tier: RewardTier.small,
    ),

    // Sommer
    RewardItem(
      id: 'small_swimming',
      title: 'Schwimmen gehen',
      emoji: '🏊',
      description: 'Ausflug zum Badesee oder Schwimmbad.',
      cost: 80,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.summer],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_water_balloons',
      title: 'Wasserbomben-Spiel',
      emoji: '💦',
      description: 'Wasserbomben im Garten - Familienspaß.',
      cost: 35,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.summer],
      tier: RewardTier.small,
    ),

    // Herbst
    RewardItem(
      id: 'small_pumpkin_carve',
      title: 'Kürbis schnitzen',
      emoji: '🎃',
      description: 'Halloween-Kürbis selbst aussuchen und schnitzen.',
      cost: 45,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.autumn],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_leaf_collect',
      title: 'Blätter sammeln im Park',
      emoji: '🍁',
      description: 'Bunte Blätter sammeln gehen mit Mama oder Papa.',
      cost: 25,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.autumn],
      tier: RewardTier.small,
    ),

    // Winter
    RewardItem(
      id: 'small_hot_chocolate',
      title: 'Heiße Schokolade',
      emoji: '☕',
      description: 'Eine heiße Schokolade mit Schlagobers.',
      cost: 25,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.winter, Season.autumn],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_christmas_market',
      title: 'Christkindlmarkt-Besuch',
      emoji: '🎄',
      description: 'Auf den Christkindlmarkt mit Punsch und Lebkuchen.',
      cost: 60,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.winter],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_sledding',
      title: 'Schlitten fahren',
      emoji: '🛷',
      description: 'Ein Nachmittag Rodeln gehen.',
      cost: 70,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.winter],
      tier: RewardTier.small,
    ),
    RewardItem(
      id: 'small_snowman',
      title: 'Schneemann bauen',
      emoji: '⛄',
      description: 'Großer Schneemann mit Mama und Papa.',
      cost: 35,
      currency: RewardCurrency.stars,
      seasons: <Season>[Season.winter],
      tier: RewardTier.small,
    ),

    // ─────────────────── MITTLERE BELOHNUNGEN (Punkte) ───────────────────

    RewardItem(
      id: 'medium_family_park',
      title: 'Family Park Ausflug',
      emoji: '🎢',
      description: 'Einen Tag im Family Park.',
      cost: 80,
      currency: RewardCurrency.points,
      seasons: <Season>[Season.spring, Season.summer, Season.autumn],
      tier: RewardTier.medium,
    ),
    RewardItem(
      id: 'medium_pizza_night',
      title: 'Pizza-Abend mit Freunden',
      emoji: '🍕',
      description: 'Du darfst 1-2 Freunde zum Pizza-Abend einladen.',
      cost: 50,
      currency: RewardCurrency.points,
      seasons: <Season>[],
      tier: RewardTier.medium,
    ),
    RewardItem(
      id: 'medium_book',
      title: 'Neues Buch aussuchen',
      emoji: '📚',
      description: 'Ein Buch aus der Bücherei oder Buchhandlung aussuchen.',
      cost: 60,
      currency: RewardCurrency.points,
      seasons: <Season>[],
      tier: RewardTier.medium,
    ),
    RewardItem(
      id: 'medium_zoo',
      title: 'Tiergarten-Besuch',
      emoji: '🦓',
      description: 'Schönbrunn Tiergarten - großer Tag mit Mama und Papa.',
      cost: 100,
      currency: RewardCurrency.points,
      seasons: <Season>[Season.spring, Season.summer, Season.autumn],
      tier: RewardTier.medium,
    ),
    RewardItem(
      id: 'medium_cinema',
      title: 'Kino-Ausflug',
      emoji: '🎥',
      description: 'Einen Kinderfilm im Kino schauen mit Popcorn.',
      cost: 70,
      currency: RewardCurrency.points,
      seasons: <Season>[],
      tier: RewardTier.medium,
    ),

    // ─────────────────── GROSSE BELOHNUNGEN (Punkte) ───────────────────

    RewardItem(
      id: 'big_toy_small',
      title: 'Spielzeug aussuchen (klein)',
      emoji: '🧸',
      description: 'Ein kleines Spielzeug aus dem Spielzeugladen (bis 15 €).',
      cost: 150,
      currency: RewardCurrency.points,
      seasons: <Season>[],
      tier: RewardTier.big,
    ),
    RewardItem(
      id: 'big_toy_medium',
      title: 'Spielzeug aussuchen (mittel)',
      emoji: '🎁',
      description: 'Ein größeres Spielzeug (bis 30 €).',
      cost: 300,
      currency: RewardCurrency.points,
      seasons: <Season>[],
      tier: RewardTier.big,
    ),
    RewardItem(
      id: 'big_lego_set',
      title: 'Lego-Set',
      emoji: '🧱',
      description: 'Ein eigenes Lego-Set bauen.',
      cost: 350,
      currency: RewardCurrency.points,
      seasons: <Season>[],
      tier: RewardTier.big,
    ),
    RewardItem(
      id: 'big_overnight',
      title: 'Übernachtung bei Oma/Opa',
      emoji: '🏡',
      description: 'Eine Nacht bei Oma und Opa schlafen mit Frühstück.',
      cost: 200,
      currency: RewardCurrency.points,
      seasons: <Season>[],
      tier: RewardTier.big,
    ),
    RewardItem(
      id: 'big_summer_pool',
      title: 'Großer Schwimmbad-Tag',
      emoji: '🏊‍♀️',
      description: 'Ein ganzer Tag im großen Erlebnisbad (mit Rutschen).',
      cost: 250,
      currency: RewardCurrency.points,
      seasons: <Season>[Season.summer],
      tier: RewardTier.big,
    ),
    RewardItem(
      id: 'big_winter_ice_rink',
      title: 'Eislaufen am Rathausplatz',
      emoji: '⛸️',
      description: 'Eislaufen mit Kakao und Maroni.',
      cost: 180,
      currency: RewardCurrency.points,
      seasons: <Season>[Season.winter],
      tier: RewardTier.big,
    ),
  ];
}
