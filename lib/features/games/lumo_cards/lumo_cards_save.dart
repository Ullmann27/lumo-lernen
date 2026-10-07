// Speichern/Fortsetzen einer laufenden Lumo-Cards-Partie (nur gegen Lumo).
// Gespeichert wird nur ein ruhiger Zustand: Phase `playing`, Mensch am Zug.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'lumo_cards_models.dart';

class LumoCardsSave {
  static const String prefsKey = 'lumo_cards_save_v1';

  /// Nur ruhige Zustaende werden gespeichert (kein Bot-Zug, keine offene Frage).
  static bool isSavable(LumoCardsGameState s) =>
      s.phase == GamePhase.playing &&
      s.players.length == 2 &&
      s.currentPlayerIndex == 0 &&
      s.topCard != null;

  static Map<String, Object?> _card(LumoCard c) => {
        'id': c.id,
        'c': c.color.name,
        't': c.type.name,
        'n': c.number,
        's': c.symbol,
      };

  static LumoCard _cardFrom(Map<String, dynamic> m) => LumoCard(
        id: m['id'] as String,
        color: LumoCardColor.values.byName(m['c'] as String),
        type: LumoCardType.values.byName(m['t'] as String),
        number: m['n'] as int?,
        symbol: m['s'] as String?,
      );

  static List<LumoCard> _cards(Object? l) => [
        for (final e in l as List) _cardFrom(Map<String, dynamic>.from(e as Map))
      ];

  static String encode(LumoCardsGameState s) => jsonEncode({
        'cur': s.currentPlayerIndex,
        'dir': s.direction,
        'color': s.selectedColor.name,
        'msg': s.lastActionMessage,
        'draw': s.drawPile.map(_card).toList(),
        'discard': s.discardPile.map(_card).toList(),
        'players': [
          for (final p in s.players)
            {
              'id': p.id,
              'name': p.name,
              'kind': p.kind.name,
              'stars': p.stars,
              'score': p.score,
              'hand': p.hand.map(_card).toList(),
            }
        ],
      });

  /// Gibt null zurueck, wenn die Daten kaputt oder unplausibel sind.
  static LumoCardsGameState? decode(String raw) {
    try {
      final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final players = [
        for (final e in m['players'] as List)
          () {
            final p = Map<String, dynamic>.from(e as Map);
            return LumoPlayer(
              id: p['id'] as String,
              name: p['name'] as String,
              hand: _cards(p['hand']),
              stars: p['stars'] as int? ?? 0,
              score: p['score'] as int? ?? 0,
              kind: LumoPlayerKind.values.byName(p['kind'] as String),
            );
          }()
      ];
      final discard = _cards(m['discard']);
      final state = LumoCardsGameState(
        players: players,
        currentPlayerIndex: m['cur'] as int,
        drawPile: _cards(m['draw']),
        discardPile: discard,
        selectedColor: LumoCardColor.values.byName(m['color'] as String),
        phase: GamePhase.playing,
        direction: m['dir'] as int? ?? 1,
        lastActionMessage: m['msg'] as String?,
      );
      if (players.length != 2 ||
          discard.isEmpty ||
          state.currentPlayerIndex < 0 ||
          state.currentPlayerIndex >= players.length ||
          players.any((p) => p.hand.isEmpty)) {
        return null;
      }
      return state;
    } catch (_) {
      return null;
    }
  }

  static Future<LumoCardsGameState?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(prefsKey);
    return raw == null ? null : decode(raw);
  }

  static Future<void> save(LumoCardsGameState s) async {
    await (await SharedPreferences.getInstance())
        .setString(prefsKey, encode(s));
  }

  static Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(prefsKey);
  }
}
