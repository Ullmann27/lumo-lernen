/// Belohnungs-Shop fuer Heinz' Toechter.
///
/// Waehrung: Sterne (aus Lern-Aufgaben).
/// Tier-System: micro -> small -> medium -> big -> premium
///
/// Grosse und Premium-Belohnungen benoetigen Eltern-Freigabe.

import 'reward_catalog.dart';

/// Jahreszeiten - automatisch aus Datum bestimmt fuer passende Belohnungen.
enum Season {
  spring,
  summer,
  autumn,
  winter;

  /// Vereinfachte meteorologische Einteilung:
  ///   Maerz-Mai = Fruehling, Juni-Aug = Sommer,
  ///   Sep-Nov = Herbst, Dez-Feb = Winter.
  static Season fromDate(DateTime d) {
    final m = d.month;
    if (m >= 3 && m <= 5) return Season.spring;
    if (m >= 6 && m <= 8) return Season.summer;
    if (m >= 9 && m <= 11) return Season.autumn;
    return Season.winter;
  }

  String get germanLabel {
    switch (this) {
      case Season.spring:
        return 'Frühling';
      case Season.summer:
        return 'Sommer';
      case Season.autumn:
        return 'Herbst';
      case Season.winter:
        return 'Winter';
    }
  }

  String get emoji {
    switch (this) {
      case Season.spring:
        return '🌸';
      case Season.summer:
        return '☀️';
      case Season.autumn:
        return '🍂';
      case Season.winter:
        return '❄️';
    }
  }
}

/// Waehrung der Belohnung.
enum RewardCurrency {
  /// Sterne aus Lern-Aufgaben.
  stars,

  /// Punkte aus guten Test-Noten (Legacy, neue Items nutzen stars).
  points,
}

/// Groessen-Klasse der Belohnung (5 Stufen).
enum RewardTier {
  /// Tier 1 - Mini-Belohnungen: 50-250 Sterne.
  micro,

  /// Tier 2 - Kleine Familienbelohnungen: 300-800 Sterne.
  small,

  /// Tier 3 - Mittlere Belohnungen: 1000-3000 Sterne.
  medium,

  /// Tier 4 - Grosse Belohnungen: 5000-12000 Sterne, Eltern-Freigabe noetig.
  big,

  /// Tier 5 - Premium-Meilensteine: 20000+ Sterne, Eltern-Freigabe + Premium-Flag.
  premium,
}

/// Status einer Einloesungs-Anfrage.
enum RedeemState {
  /// Nicht freigeschaltet (z.B. zu wenig Sterne).
  locked,

  /// Genug Sterne vorhanden, kann angefragt werden.
  available,

  /// Kind hat Anfrage gestellt, wartet auf Eltern.
  requested,

  /// Eltern haben genehmigt.
  approved,

  /// Eingeloest und erfuellt.
  redeemed,
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
    this.parentApprovalRequired = false,
    this.isPremiumReward = false,
    this.estimatedTasksNeeded = 0,
  });

  final String id;
  final String title;
  final String emoji;
  final String description;
  final int cost;
  final RewardCurrency currency;

  /// Leere Liste = ganzjaehrig verfuegbar.
  final List<Season> seasons;
  final RewardTier tier;

  /// true = Eltern muessen die Einloesung aktiv bestaetigen.
  final bool parentApprovalRequired;

  /// true = Premium-Meilenstein (Tier 5).
  final bool isPremiumReward;

  /// Grobe Schaetzung: wie viele Aufgaben braucht das Kind (~10 Sterne/Aufgabe).
  final int estimatedTasksNeeded;

  /// Prueft ob diese Belohnung in der aktuellen Jahreszeit verfuegbar ist.
  bool availableIn(Season season) =>
      seasons.isEmpty || seasons.contains(season);
}

/// Eine Eltern-Freigabe-Anfrage fuer eine grosse Belohnung.
class RewardApprovalRequest {
  const RewardApprovalRequest({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemEmoji,
    required this.childId,
    required this.state,
    required this.requestedAt,
    this.resolvedAt,
    this.parentNote,
  });

  final String id;
  final String itemId;
  final String itemTitle;
  final String itemEmoji;
  final String childId;
  final RedeemState state;
  final DateTime requestedAt;
  final DateTime? resolvedAt;
  final String? parentNote;

  RewardApprovalRequest copyWith({
    RedeemState? state,
    DateTime? resolvedAt,
    String? parentNote,
  }) {
    return RewardApprovalRequest(
      id: id,
      itemId: itemId,
      itemTitle: itemTitle,
      itemEmoji: itemEmoji,
      childId: childId,
      state: state ?? this.state,
      requestedAt: requestedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      parentNote: parentNote ?? this.parentNote,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'itemEmoji': itemEmoji,
        'childId': childId,
        'state': state.name,
        'requestedAt': requestedAt.toIso8601String(),
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
        if (parentNote != null) 'parentNote': parentNote,
      };

  factory RewardApprovalRequest.fromJson(Map<String, Object?> json) {
    return RewardApprovalRequest(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemTitle: json['itemTitle']?.toString() ?? '',
      itemEmoji: json['itemEmoji']?.toString() ?? '🎁',
      childId: json['childId']?.toString() ?? '',
      state: RedeemState.values.firstWhere(
        (s) => s.name == json['state']?.toString(),
        orElse: () => RedeemState.requested,
      ),
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
          DateTime.now(),
      resolvedAt:
          DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
      parentNote: json['parentNote']?.toString(),
    );
  }
}

/// ─────────────────── SHOP STATE & ENGINE ───────────────────

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
    this.approvalRequests = const <RewardApprovalRequest>[],
    this.goalItemId,
  });

  final int availableStars;
  final int availablePoints;
  final List<RedeemedReward> redeemed;
  final List<TestPhotoEntry> testPhotos;

  /// Laufende Eltern-Freigabe-Anfragen.
  final List<RewardApprovalRequest> approvalRequests;

  /// ID der Belohnung, auf die das Kind aktuell spart.
  final String? goalItemId;

  RewardShopState copyWith({
    int? availableStars,
    int? availablePoints,
    List<RedeemedReward>? redeemed,
    List<TestPhotoEntry>? testPhotos,
    List<RewardApprovalRequest>? approvalRequests,
    String? goalItemId,
    bool clearGoal = false,
  }) {
    return RewardShopState(
      availableStars:
          (availableStars ?? this.availableStars).clamp(0, 999999) as int,
      availablePoints:
          (availablePoints ?? this.availablePoints).clamp(0, 999999) as int,
      redeemed: redeemed ?? this.redeemed,
      testPhotos: testPhotos ?? this.testPhotos,
      approvalRequests: approvalRequests ?? this.approvalRequests,
      goalItemId: clearGoal ? null : (goalItemId ?? this.goalItemId),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'availableStars': availableStars,
        'availablePoints': availablePoints,
        'redeemed': redeemed.map((r) => r.toJson()).toList(growable: false),
        'testPhotos': testPhotos.map((t) => t.toJson()).toList(growable: false),
        'approvalRequests':
            approvalRequests.map((a) => a.toJson()).toList(growable: false),
        if (goalItemId != null) 'goalItemId': goalItemId,
      };

  factory RewardShopState.fromJson(Map<String, Object?> json) {
    return RewardShopState(
      availableStars:
          (((json['availableStars'] as num?)?.toInt() ?? 0).clamp(0, 999999))
              as int,
      availablePoints:
          (((json['availablePoints'] as num?)?.toInt() ?? 0).clamp(0, 999999))
              as int,
      redeemed: (json['redeemed'] as List?)
              ?.whereType<Map>()
              .map((m) =>
                  RedeemedReward.fromJson(m.cast<String, Object?>()))
              .toList(growable: false) ??
          const <RedeemedReward>[],
      testPhotos: (json['testPhotos'] as List?)
              ?.whereType<Map>()
              .map((m) =>
                  TestPhotoEntry.fromJson(m.cast<String, Object?>()))
              .toList(growable: false) ??
          const <TestPhotoEntry>[],
      approvalRequests: (json['approvalRequests'] as List?)
              ?.whereType<Map>()
              .map((m) => RewardApprovalRequest.fromJson(
                  m.cast<String, Object?>()))
              .toList(growable: false) ??
          const <RewardApprovalRequest>[],
      goalItemId: json['goalItemId']?.toString(),
    );
  }
}

/// Hauptlogik des Belohnungs-Shops.
class RewardShopEngine {
  const RewardShopEngine();

  /// Liefert alle aktuell verfuegbaren Belohnungen, gefiltert nach Jahreszeit.
  List<RewardItem> availableRewards({DateTime? now}) {
    final season = Season.fromDate(now ?? DateTime.now());
    return RewardCatalog.all
        .where((r) => r.availableIn(season))
        .toList(growable: false);
  }

  /// Prueft ob die aktuelle Belohnung leistbar ist.
  bool canAfford(RewardShopState state, RewardItem item) {
    if (item.currency == RewardCurrency.stars) {
      return state.availableStars >= item.cost;
    }
    return state.availablePoints >= item.cost;
  }

  /// Loest eine Belohnung ein (nur fuer items ohne parentApprovalRequired).
  /// Gibt null zurueck wenn nicht genug Waehrung oder Freigabe benoetigt.
  RewardShopState? redeem(
    RewardShopState state,
    RewardItem item, {
    String? note,
    DateTime? now,
  }) {
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
      availableStars: item.currency == RewardCurrency.stars
          ? ((state.availableStars - item.cost).clamp(0, 999999) as int)
          : state.availableStars,
      availablePoints: item.currency == RewardCurrency.points
          ? ((state.availablePoints - item.cost).clamp(0, 999999) as int)
          : state.availablePoints,
      redeemed: <RedeemedReward>[...state.redeemed, entry],
    );
  }

  /// Erstellt eine Eltern-Freigabe-Anfrage fuer grosse/premium Belohnungen.
  RewardShopState requestApproval(
    RewardShopState state,
    RewardItem item,
    String childId, {
    DateTime? now,
  }) {
    final request = RewardApprovalRequest(
      id: 'req_${item.id}_${(now ?? DateTime.now()).millisecondsSinceEpoch}',
      itemId: item.id,
      itemTitle: item.title,
      itemEmoji: item.emoji,
      childId: childId,
      state: RedeemState.requested,
      requestedAt: now ?? DateTime.now(),
    );
    return state.copyWith(
      approvalRequests: <RewardApprovalRequest>[
        ...state.approvalRequests,
        request,
      ],
    );
  }

  /// Eltern genehmigen eine Anfrage.
  RewardShopState approveRequest(RewardShopState state, String requestId, {DateTime? now}) {
    return state.copyWith(
      approvalRequests: state.approvalRequests.map((r) {
        if (r.id == requestId) {
          return r.copyWith(
            state: RedeemState.approved,
            resolvedAt: now ?? DateTime.now(),
          );
        }
        return r;
      }).toList(growable: false),
    );
  }

  /// Eltern lehnen eine Anfrage ab.
  RewardShopState denyRequest(
    RewardShopState state,
    String requestId, {
    String? parentNote,
    DateTime? now,
  }) {
    return state.copyWith(
      approvalRequests: state.approvalRequests.map((r) {
        if (r.id == requestId) {
          return r.copyWith(
            state: RedeemState.locked,
            resolvedAt: now ?? DateTime.now(),
            parentNote: parentNote,
          );
        }
        return r;
      }).toList(growable: false),
    );
  }

  /// Markiert eine genehmigte Anfrage als eingeloest.
  RewardShopState markRedeemed(RewardShopState state, String requestId, {DateTime? now}) {
    return state.copyWith(
      approvalRequests: state.approvalRequests.map((r) {
        if (r.id == requestId) {
          return r.copyWith(
            state: RedeemState.redeemed,
            resolvedAt: now ?? DateTime.now(),
          );
        }
        return r;
      }).toList(growable: false),
    );
  }

  /// Setzt das Spar-Ziel des Kindes.
  RewardShopState setGoal(RewardShopState state, String? itemId) {
    return state.copyWith(goalItemId: itemId, clearGoal: itemId == null);
  }

  /// Fuegt einen Test-Foto-Eintrag hinzu und vergibt Punkte basierend auf der Note.
  RewardShopState addTestPhoto(
    RewardShopState state, {
    required String subject,
    required int grade,
    required int note,
    String? imagePath,
    DateTime? now,
  }) {
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
