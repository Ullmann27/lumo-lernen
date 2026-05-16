/// Belohnungs-Shop fuer Heinz' Toechter.
///
/// Zwei Waehrungen:
///   1. Sterne (kleine, alltaegliche Erfolge - aus reward_engine.dart)
///      -> kleine Belohnungen (Eis, Schwimmen, Einkaufen-Wunsch)
///   2. Punkte (grosse Erfolge - gute Noten aus Tests)
///      -> grosse Belohnungen (Spielzeug, Ausflug)
///
/// Eltern muessen die Einloesung freigeben (PIN-Schutz, wie im Eltern-Bereich).

import 'reward_catalog.dart';

/// Jahreszeiten - automatisch aus Datum bestimmt fuer passende Belohnungen.
enum Season {
  spring,
  summer,
  autumn,
  winter;

  /// Liest die aktuelle Jahreszeit aus einem Datum.
  /// Vereinfachte meteorologische Einteilung:
  ///   Maerz-Mai = Fruehling
  ///   Juni-August = Sommer
  ///   September-November = Herbst
  ///   Dezember-Februar = Winter
  static Season fromDate(DateTime d) {
    final m = d.month;
    if (m >= 3 && m <= 5) return Season.spring;
    if (m >= 6 && m <= 8) return Season.summer;
    if (m >= 9 && m <= 11) return Season.autumn;
    return Season.winter;
  }

  String get germanLabel {
    switch (this) {
      case Season.spring: return 'Frühling';
      case Season.summer: return 'Sommer';
      case Season.autumn: return 'Herbst';
      case Season.winter: return 'Winter';
    }
  }

  String get emoji {
    switch (this) {
      case Season.spring: return '🌸';
      case Season.summer: return '☀️';
      case Season.autumn: return '🍂';
      case Season.winter: return '❄️';
    }
  }
}

/// Eine konkrete Belohnung im Shop.
class RewardItem {
  const RewardItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.currency,
    required this.seasons,
    this.tier = RewardTier.small,
  });

  final String id;
  final String title;
  final String emoji;
  final String description;
  final int cost;
  final RewardCurrency currency;
  /// Liste der Jahreszeiten in denen diese Belohnung verfuegbar ist.
  /// Leere Liste = ganzjaehrig.
  final List<Season> seasons;
  final RewardTier tier;

  /// Prueft ob diese Belohnung in der aktuellen Jahreszeit verfuegbar ist.
  bool availableIn(Season season) =>
      seasons.isEmpty || seasons.contains(season);
}

/// Waehrung der Belohnung.
enum RewardCurrency {
  /// Sterne aus Lern-Aufgaben.
  stars,
  /// Punkte aus guten Test-Noten (per Foto eingereicht).
  points,
}

/// Groessen-Klasse der Belohnung.
enum RewardTier {
  /// Kleine alltaegliche Belohnung (Eis, Schwimmen).
  small,
  /// Mittlere Belohnung (Ausflug, kleines Geschenk).
  medium,
  /// Grosse Belohnung (Spielzeug, grosser Ausflug).
  big,
}

/// Eine eingeloeste Belohnung (Historie).
class RedeemedReward {
  const RedeemedReward({
    required this.itemId,
    required this.title,
    required this.redeemedAt,
    required this.cost,
    required this.currency,
    this.note,
  });

  final String itemId;
  final String title;
  final DateTime redeemedAt;
  final int cost;
  final RewardCurrency currency;
  /// Optional: Eltern-Notiz beim Einloesen ("Eingeloest am Samstag im Park").
  final String? note;

  Map<String, Object?> toJson() => <String, Object?>{
        'itemId': itemId,
        'title': title,
        'redeemedAt': redeemedAt.toIso8601String(),
        'cost': cost,
        'currency': currency.name,
        if (note != null) 'note': note,
      };

  factory RedeemedReward.fromJson(Map<String, Object?> json) {
    return RedeemedReward(
      itemId: json['itemId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      redeemedAt: DateTime.tryParse(json['redeemedAt']?.toString() ?? '') ?? DateTime.now(),
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      currency: RewardCurrency.values.firstWhere(
        (c) => c.name == json['currency']?.toString(),
        orElse: () => RewardCurrency.stars,
      ),
      note: json['note']?.toString(),
    );
  }
}

/// Test-Note Foto-Eintrag - gibt Punkte basierend auf Note.
class TestPhotoEntry {
  const TestPhotoEntry({
    required this.subject,
    required this.grade,
    required this.note,
    required this.recordedAt,
    this.pointsAwarded = 0,
    this.imagePath,
  });

  final String subject;
  final int grade; // Klasse
  /// Schulnote 1-5 (Oesterreich).
  final int note;
  final DateTime recordedAt;
  final int pointsAwarded;
  /// Pfad zum lokal gespeicherten Foto (optional).
  final String? imagePath;

  Map<String, Object?> toJson() => <String, Object?>{
        'subject': subject,
        'grade': grade,
        'note': note,
        'recordedAt': recordedAt.toIso8601String(),
        'pointsAwarded': pointsAwarded,
        if (imagePath != null) 'imagePath': imagePath,
      };

  factory TestPhotoEntry.fromJson(Map<String, Object?> json) {
    return TestPhotoEntry(
      subject: json['subject']?.toString() ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 1,
      note: (json['note'] as num?)?.toInt() ?? 5,
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ?? DateTime.now(),
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
      imagePath: json['imagePath']?.toString(),
    );
  }

  /// Berechnet wie viele Punkte fuer diese Note vergeben werden.
  /// Skala (Oesterreich):
  ///   Note 1 (Sehr gut) = 50 Punkte
  ///   Note 2 (Gut)      = 25 Punkte
  ///   Note 3 (Befriedig) = 10 Punkte
  ///   Note 4 (Genuegend) = 3 Punkte
  ///   Note 5 (Nicht gen.) = 0 Punkte
  static int pointsForNote(int note) {
    switch (note) {
      case 1: return 50;
      case 2: return 25;
      case 3: return 10;
      case 4: return 3;
      default: return 0;
    }
  }
}

/// Kompletter Stand des Belohnungs-Shops.
class RewardShopState {
  const RewardShopState({
    this.availableStars = 0,
    this.availablePoints = 0,
    this.redeemed = const <RedeemedReward>[],
    this.testPhotos = const <TestPhotoEntry>[],
  });

  /// Aktuell verfuegbare Sterne (kann eingeloest werden).
  final int availableStars;
  /// Aktuell verfuegbare Punkte aus Test-Noten.
  final int availablePoints;
  final List<RedeemedReward> redeemed;
  final List<TestPhotoEntry> testPhotos;

  RewardShopState copyWith({
    int? availableStars,
    int? availablePoints,
    List<RedeemedReward>? redeemed,
    List<TestPhotoEntry>? testPhotos,
  }) {
    return RewardShopState(
      availableStars: availableStars ?? this.availableStars,
      availablePoints: availablePoints ?? this.availablePoints,
      redeemed: redeemed ?? this.redeemed,
      testPhotos: testPhotos ?? this.testPhotos,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'availableStars': availableStars,
        'availablePoints': availablePoints,
        'redeemed': redeemed.map((r) => r.toJson()).toList(growable: false),
        'testPhotos': testPhotos.map((t) => t.toJson()).toList(growable: false),
      };

  factory RewardShopState.fromJson(Map<String, Object?> json) {
    return RewardShopState(
      availableStars: (json['availableStars'] as num?)?.toInt() ?? 0,
      availablePoints: (json['availablePoints'] as num?)?.toInt() ?? 0,
      redeemed: (json['redeemed'] as List?)
              ?.whereType<Map>()
              .map((m) => RedeemedReward.fromJson(m.cast<String, Object?>()))
              .toList(growable: false) ??
          const <RedeemedReward>[],
      testPhotos: (json['testPhotos'] as List?)
              ?.whereType<Map>()
              .map((m) => TestPhotoEntry.fromJson(m.cast<String, Object?>()))
              .toList(growable: false) ??
          const <TestPhotoEntry>[],
    );
  }
}

/// Hauptlogik des Belohnungs-Shops.
class RewardShopEngine {
  const RewardShopEngine();

  /// Liefert alle aktuell verfuegbaren Belohnungen, gefiltert nach Jahreszeit.
  List<RewardItem> availableRewards({DateTime? now}) {
    final season = Season.fromDate(now ?? DateTime.now());
    return RewardCatalog.all.where((r) => r.availableIn(season)).toList(growable: false);
  }

  /// Prueft ob die aktuelle Belohnung leistbar ist.
  bool canAfford(RewardShopState state, RewardItem item) {
    if (item.currency == RewardCurrency.stars) {
      return state.availableStars >= item.cost;
    }
    return state.availablePoints >= item.cost;
  }

  /// Loest eine Belohnung ein. Gibt neuen State zurueck.
  /// Liefert null wenn nicht genug Waehrung.
  RewardShopState? redeem(RewardShopState state, RewardItem item, {String? note, DateTime? now}) {
    if (!canAfford(state, item)) return null;
    final entry = RedeemedReward(
      itemId: item.id,
      title: item.title,
      redeemedAt: now ?? DateTime.now(),
      cost: item.cost,
      currency: item.currency,
      note: note,
    );
    return state.copyWith(
      availableStars: item.currency == RewardCurrency.stars ? state.availableStars - item.cost : state.availableStars,
      availablePoints: item.currency == RewardCurrency.points ? state.availablePoints - item.cost : state.availablePoints,
      redeemed: <RedeemedReward>[...state.redeemed, entry],
    );
  }

  /// Fuegt einen Test-Foto-Eintrag hinzu und vergibt Punkte basierend auf der Note.
  RewardShopState addTestPhoto(RewardShopState state, {required String subject, required int grade, required int note, String? imagePath, DateTime? now}) {
    final pts = TestPhotoEntry.pointsForNote(note);
    final entry = TestPhotoEntry(
      subject: subject,
      grade: grade,
      note: note,
      recordedAt: now ?? DateTime.now(),
      pointsAwarded: pts,
      imagePath: imagePath,
    );
    return state.copyWith(
      availablePoints: state.availablePoints + pts,
      testPhotos: <TestPhotoEntry>[...state.testPhotos, entry],
    );
  }

  /// Fuegt Sterne hinzu (aus Lern-Aufgaben).
  RewardShopState addStars(RewardShopState state, int starsToAdd) {
    if (starsToAdd <= 0) return state;
    return state.copyWith(availableStars: state.availableStars + starsToAdd);
  }
}
