// ════════════════════════════════════════════════════════════════════════
// LUMO COSMOS — Wachsende Lern-Welt
// ════════════════════════════════════════════════════════════════════════
// Vorschlag 4 aus Heinz' Auswahl: 'Jede Mathe-Aufgabe -> Baum waechst.
// Jeder Buchstabe -> Blume. Nach Wochen ein magisches Dorf.'
//
// Storage: SharedPreferences mit Counter pro Item-Typ.
// Items werden in 2D-Welt via CustomPainter gerendert.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Persistente Lern-Welt des Kindes.
class CosmosWorld {
  CosmosWorld._();
  static final CosmosWorld instance = CosmosWorld._();

  static const _key = 'lumo_cosmos_items_v1';
  static const _meta = 'lumo_cosmos_meta_v1';
  final _rng = math.Random();

  List<CosmosItem> _items = [];
  int _totalCorrect = 0;
  int _streakDays = 0;

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
    return 'Unendliche Welt';
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _items = list.map(CosmosItem.fromJson).toList();
      } catch (_) {
        _items = [];
      }
    }
    final metaRaw = p.getString(_meta);
    if (metaRaw != null) {
      try {
        final m = jsonDecode(metaRaw) as Map<String, dynamic>;
        _totalCorrect = m['c'] as int? ?? 0;
        _streakDays = m['s'] as int? ?? 0;
      } catch (_) {}
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key,
        jsonEncode(_items.map((i) => i.toJson()).toList()));
    await p.setString(_meta,
        jsonEncode({'c': _totalCorrect, 's': _streakDays}));
  }

  /// Hauptmethode: Kind hat richtig geantwortet -> Welt waechst.
  /// Heinz: jede Mathe-Aufgabe -> Baum, jeder Buchstabe -> Blume.
  Future<List<CosmosItem>> grantReward({
    required String subjectId,
    required bool isMath,
    required bool isPerfect,
  }) async {
    final newItems = <CosmosItem>[];
    _totalCorrect++;

    // Basis-Item passt zum Subject
    if (isMath) {
      newItems.add(_randomItem(CosmosItemType.tree));
    } else if (subjectId.contains('sachk')) {
      // Tier zufaellig
      const animals = [
        CosmosItemType.butterfly,
        CosmosItemType.bird,
        CosmosItemType.rabbit,
      ];
      newItems.add(_randomItem(animals[_rng.nextInt(animals.length)]));
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
    // Perfekte Note -> Regenbogen
    if (isPerfect && _rng.nextDouble() < 0.3) {
      newItems.add(_randomItem(CosmosItemType.rainbow));
    }

    _items.addAll(newItems);
    await save();
    return newItems;
  }

  Future<void> recordStreak() async {
    _streakDays++;
    await save();
  }

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
  Future<void> reset() async {
    _items = [];
    _totalCorrect = 0;
    _streakDays = 0;
    await save();
  }
}
