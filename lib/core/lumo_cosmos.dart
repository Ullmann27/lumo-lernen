// ════════════════════════════════════════════════════════════════════════
// LUMO COSMOS — Wachsende Lern-Welt
// ════════════════════════════════════════════════════════════════════════
// Vorschlag 4 aus Heinz' Auswahl: 'Jede Mathe-Aufgabe -> Baum waechst.
// Jeder Buchstabe -> Blume. Nach Wochen ein magisches Dorf.'
//
// Storage: SharedPreferences mit Counter pro Item-Typ.
// Items werden in 2D-Welt via CustomPainter gerendert.
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'legacy_learning_data.dart';

/// Item-Typen die in der Welt wachsen koennen.
enum CosmosItemType {
  flower,    // Blume - fuer Sachkunde-Antworten
  tree,      // Baum - fuer Mathe
  bush,      // Busch - fuer Lesen/Wort
  house,     // Haus - alle 20 Items
  star,      // Stern - fuer Streak-Tage
  rainbow,   // Regenbogen - bei perfekter Note
  cloud,     // Wolke - Dekoration
  butterfly, // Schmetterling - Tier
  bird,      // Vogel - Tier
  rabbit,    // Hase - Tier
  castle,    // Schloss - nach 200 Items
  dragon,    // Drache - nach 500 Items
  unicorn,   // Einhorn - nach 1000 Items
}

extension CosmosItemMeta on CosmosItemType {
  String get emoji {
    switch (this) {
      case CosmosItemType.flower: return '🌸';
      case CosmosItemType.tree: return '🌳';
      case CosmosItemType.bush: return '🌿';
      case CosmosItemType.house: return '🏠';
      case CosmosItemType.star: return '⭐';
      case CosmosItemType.rainbow: return '🌈';
      case CosmosItemType.cloud: return '☁️';
      case CosmosItemType.butterfly: return '🦋';
      case CosmosItemType.bird: return '🐦';
      case CosmosItemType.rabbit: return '🐰';
      case CosmosItemType.castle: return '🏰';
      case CosmosItemType.dragon: return '🐉';
      case CosmosItemType.unicorn: return '🦄';
    }
  }

  String get name {
    switch (this) {
      case CosmosItemType.flower: return 'Blume';
      case CosmosItemType.tree: return 'Baum';
      case CosmosItemType.bush: return 'Busch';
      case CosmosItemType.house: return 'Haus';
      case CosmosItemType.star: return 'Stern';
      case CosmosItemType.rainbow: return 'Regenbogen';
      case CosmosItemType.cloud: return 'Wolke';
      case CosmosItemType.butterfly: return 'Schmetterling';
      case CosmosItemType.bird: return 'Vogel';
      case CosmosItemType.rabbit: return 'Hase';
      case CosmosItemType.castle: return 'Schloss';
      case CosmosItemType.dragon: return 'Drache';
      case CosmosItemType.unicorn: return 'Einhorn';
    }
  }
}

class CosmosItem {
  const CosmosItem({
    required this.type,
    required this.x,
    required this.y,
    required this.scale,
    this.rotation = 0,
  });
  final CosmosItemType type;
  final double x; // 0..1 relative
  final double y;
  final double scale;
  final double rotation;

  Map<String, dynamic> toJson() => {
        't': type.index, 'x': x, 'y': y, 's': scale, 'r': rotation,
      };
  static CosmosItem fromJson(Map<String, dynamic> j) => CosmosItem(
        type: CosmosItemType.values[j['t']],
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        scale: (j['s'] as num).toDouble(),
        rotation: (j['r'] as num?)?.toDouble() ?? 0,
      );
}

/// Tageszeit basierend auf realer Uhr.
enum LumoDayPeriod {
  morning,   // 5-11
  noon,      // 11-17
  evening,   // 17-21
  night,     // 21-5
}

LumoDayPeriod currentDayPeriod() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 11) return LumoDayPeriod.morning;
  if (h >= 11 && h < 17) return LumoDayPeriod.noon;
  if (h >= 17 && h < 21) return LumoDayPeriod.evening;
  return LumoDayPeriod.night;
}

/// Jahreszeit basierend auf realem Datum.
enum Season { spring, summer, autumn, winter }

Season currentSeason() {
  final m = DateTime.now().month;
  if (m >= 3 && m <= 5) return Season.spring;
  if (m >= 6 && m <= 8) return Season.summer;
  if (m >= 9 && m <= 11) return Season.autumn;
  return Season.winter;
}

/// Persistente Lern-Welt des Kindes.
class CosmosWorld {
  CosmosWorld({String? studentId})
      : _namespace = LearningDataNamespace(studentId: studentId);

  final LearningDataNamespace _namespace;
  Future<String> get studentId => _namespace.studentId;

  static const _key = 'lumo_cosmos_items_v1';
  static const _snapshotKey = 'lumo_cosmos_v2';
  static const _meta = 'lumo_cosmos_meta_v1';
  final _rng = math.Random();

  List<CosmosItem> _items = [];
  int _totalCorrect = 0;
  int _streakDays = 0;
  String? _lastVisitDate; // YYYY-MM-DD
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _operationTail = Future<void>.value();
  bool _dirty = false;
  String? _saveError;
  final List<CosmosItem> _pendingNotifications = [];

  bool get isLoaded => _loaded;
  bool get hasPendingSave => _dirty;
  String? get saveError => _saveError;

  /// Listeners die nach grantReward benachrichtigt werden (z.B. fuer
  /// Toast 'Du hast einen Baum gepflanzt!' in Modul-Screens).
  final List<void Function(List<CosmosItem>)> _listeners = [];

  void addListener(void Function(List<CosmosItem>) cb) {
    _listeners.add(cb);
  }
  void removeListener(void Function(List<CosmosItem>) cb) {
    _listeners.remove(cb);
  }

  List<CosmosItem> get items => List.unmodifiable(_items);
  int get totalItems => _items.length;
  int get totalCorrect => _totalCorrect;
  int get streakDays => _streakDays;

  String get worldStage {
    if (totalItems < 10) return 'Leere Wiese';
    if (totalItems < 30) return 'Erste Bluemchen';
    if (totalItems < 60) return 'Bluehender Garten';
    if (totalItems < 100) return 'Kleines Dorf';
    if (totalItems < 200) return 'Lebendiges Dorf';
    if (totalItems < 400) return 'Magisches Reich';
    if (totalItems < 800) return 'Koenigreich';
    if (totalItems < 1500) return 'Sterne-Land';
    if (totalItems < 3000) return 'Galaktisches Reich';
    return 'Unendliche Welt';
  }

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      await _loadSnapshot();
    } finally {
      _loading = null;
    }
  }

  Future<void> _loadSnapshot() async {
    final stored = await _namespace.read(_snapshotKey);
    Map<String, dynamic>? snapshot;
    if (stored != null) {
      snapshot = jsonDecode(stored) as Map<String, dynamic>;
    }
    final raw = snapshot == null
        ? await _namespace.read(_key) : jsonEncode(snapshot['items']);
    _items = [];
    _totalCorrect = 0;
    _streakDays = 0;
    _lastVisitDate = null;
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _items = list.map(CosmosItem.fromJson).toList();
      } catch (_) {
        throw StateError('Stored learning world could not be read');
      }
    }
    final metaRaw = snapshot == null
        ? await _namespace.read(_meta) : jsonEncode(snapshot['meta']);
    if (metaRaw != null) {
      try {
        final m = jsonDecode(metaRaw) as Map<String, dynamic>;
        _totalCorrect = m['c'] as int? ?? 0;
        _streakDays = m['s'] as int? ?? 0;
        _lastVisitDate = m['d'] as String?;
      } catch (_) {
        throw StateError('Stored learning world metadata could not be read');
      }
    }
    // Streak-Check: Wenn lastVisit gestern war, dann +1.
    // Wenn schon heute, kein Update. Wenn aelter, reset.
    final today = _todayString();
    if (_lastVisitDate != today) {
      final yesterday = _dateString(
          DateTime.now().subtract(const Duration(days: 1)));
      if (_lastVisitDate == yesterday) {
        _streakDays++;
      } else if (_lastVisitDate != null) {
        _streakDays = 1; // Reset auf 1 (heute zaehlt schon)
      } else {
        _streakDays = 1;
      }
      _lastVisitDate = today;
      // Opening an untouched world must not claim a child's destination and
      // prevent the parent from assigning preserved legacy history. The first
      // real reward persists its visit and world together.
      if (stored != null || raw != null || metaRaw != null) {
        _dirty = true;
        await _save();
      }
    }
    _loaded = true;
  }

  String _todayString() => _dateString(DateTime.now());
  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final pending = _operationTail.then((_) => action());
    _operationTail = pending.then<void>((_) {},
        onError: (Object _, StackTrace __) {});
    return pending;
  }

  /// Retries the same pending snapshot; it never grants a second reward.
  Future<void> flush() => _enqueue(() async {
    await load();
    if (_dirty) await _save();
    _publishPending();
  });

  Future<void> save() => flush();

  Future<void> _save() async {
    try {
      // Items and counters are one atomic platform write.
      await _namespace.write(_snapshotKey, jsonEncode({
        'items': _items.map((item) => item.toJson()).toList(),
        'meta': {'c': _totalCorrect, 's': _streakDays, 'd': _lastVisitDate},
      }));
      _dirty = false;
      _saveError = null;
    } catch (_) {
      _dirty = true;
      _saveError = 'Deine Lernwelt wartet noch aufs Speichern.';
      rethrow;
    }
  }

  void _publishPending() {
    if (_pendingNotifications.isEmpty) return;
    final items = List<CosmosItem>.unmodifiable(_pendingNotifications);
    _pendingNotifications.clear();
    for (final callback in List.of(_listeners)) {
      callback(items);
    }
  }

  /// Hauptmethode: Kind hat richtig geantwortet -> Welt waechst.
  /// Heinz: jede Mathe-Aufgabe -> Baum, jeder Buchstabe -> Blume.
  /// Saison-adaptiv: Schmetterlinge bevorzugt im Fruehling/Sommer,
  /// Sterne bevorzugt im Winter.
  Future<List<CosmosItem>> grantReward({
    required String subjectId,
    required bool isMath,
    required bool isPerfect,
  }) => _enqueue(() async {
    await load();
    final newItems = <CosmosItem>[];
    _totalCorrect++;
    final season = currentSeason();

    // Basis-Item passt zum Subject + Saison.
    if (isMath) {
      newItems.add(_randomItem(CosmosItemType.tree));
    } else if (subjectId.contains('sachk')) {
      // Tier zufaellig - saison-gewichtet:
      // Fruehling/Sommer: Schmetterlinge bevorzugt
      // Herbst: Voegel bevorzugt
      // Winter: Hasen bevorzugt (im Schnee gut sichtbar)
      final animals = <CosmosItemType>[];
      switch (season) {
        case Season.spring:
        case Season.summer:
          animals.addAll([
            CosmosItemType.butterfly, CosmosItemType.butterfly,
            CosmosItemType.bird, CosmosItemType.rabbit,
          ]);
          break;
        case Season.autumn:
          animals.addAll([
            CosmosItemType.bird, CosmosItemType.bird,
            CosmosItemType.rabbit, CosmosItemType.butterfly,
          ]);
          break;
        case Season.winter:
          animals.addAll([
            CosmosItemType.rabbit, CosmosItemType.rabbit,
            CosmosItemType.bird, CosmosItemType.butterfly,
          ]);
          break;
      }
      newItems.add(_randomItem(animals[_rng.nextInt(animals.length)]));
    } else if (subjectId.contains('lesen') ||
        subjectId.contains('story')) {
      newItems.add(_randomItem(CosmosItemType.bush));
    } else {
      newItems.add(_randomItem(CosmosItemType.flower));
    }

    // Bonus alle 20 Items -> Haus
    if ((_totalCorrect % 20) == 0) {
      newItems.add(_randomItem(CosmosItemType.house));
    }
    // Bonus alle 50 -> Busch
    if ((_totalCorrect % 50) == 0) {
      newItems.add(_randomItem(CosmosItemType.bush));
    }
    // Bonus alle 100 -> Stern
    if ((_totalCorrect % 100) == 0) {
      newItems.add(_randomItem(CosmosItemType.star));
    }
    // Im Winter: zusaetzliche Sterne (klare Nacht)
    if (season == Season.winter && (_totalCorrect % 25) == 0) {
      newItems.add(_randomItem(CosmosItemType.star));
    }
    // Streak-Belohnungen: alle 7 Tage Streak -> Bonus-Stern,
    // alle 14 Tage -> Bonus-Schmetterling
    if (_streakDays > 0 && _streakDays % 7 == 0 && (_totalCorrect % 5) == 0) {
      newItems.add(_randomItem(CosmosItemType.star));
    }
    if (_streakDays >= 14 && (_totalCorrect % 30) == 0) {
      newItems.add(_randomItem(CosmosItemType.butterfly));
    }
    // Meilensteine
    if (_totalCorrect == 200) {
      newItems.add(_randomItem(CosmosItemType.castle));
    }
    if (_totalCorrect == 500) {
      newItems.add(_randomItem(CosmosItemType.dragon));
    }
    if (_totalCorrect == 1000) {
      newItems.add(_randomItem(CosmosItemType.unicorn));
    }
    // Perfekte Note -> Regenbogen (Herbst-Bonus: hoeher)
    final rainbowChance =
        season == Season.autumn ? 0.45 : 0.30;
    if (isPerfect && _rng.nextDouble() < rainbowChance) {
      newItems.add(_randomItem(CosmosItemType.rainbow));
    }

    _items.addAll(newItems);
    _pendingNotifications.addAll(newItems);
    _dirty = true;
    await _save();
    _publishPending();
    return newItems;
  });

  Future<void> recordStreak() => _enqueue(() async {
    await load();
    _streakDays++;
    _dirty = true;
    await _save();
  });

  CosmosItem _randomItem(CosmosItemType type) {
    // Y-Verteilung passt zum Item-Typ
    double y;
    switch (type) {
      case CosmosItemType.cloud:
      case CosmosItemType.rainbow:
      case CosmosItemType.star:
      case CosmosItemType.bird:
        y = 0.05 + _rng.nextDouble() * 0.3; // oben
        break;
      case CosmosItemType.butterfly:
        y = 0.2 + _rng.nextDouble() * 0.5; // mitte
        break;
      case CosmosItemType.castle:
      case CosmosItemType.dragon:
      case CosmosItemType.unicorn:
        y = 0.4 + _rng.nextDouble() * 0.2; // mitte
        break;
      default:
        y = 0.55 + _rng.nextDouble() * 0.4; // unten
    }
    return CosmosItem(
      type: type,
      x: 0.05 + _rng.nextDouble() * 0.9,
      y: y,
      scale: 0.8 + _rng.nextDouble() * 0.5,
      rotation: (_rng.nextDouble() - 0.5) * 0.2,
    );
  }

  /// Reset fuer Tests / Eltern.
  Future<void> reset() => _enqueue(() async {
    if (_loading != null) await _loading;
    _items = [];
    _totalCorrect = 0;
    _streakDays = 0;
    _lastVisitDate = null;
    _pendingNotifications.clear();
    _dirty = true;
    await _save();
    _loaded = true;
  });
}
