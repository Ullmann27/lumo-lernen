// ════════════════════════════════════════════════════════════════════════
// REWARD WALLET REPOSITORY — Zentrale persistente Sterne/XP-Speicherung
// ════════════════════════════════════════════════════════════════════════
// Heinz-Auftrag: 'Sterne/XP persistent speichern, Lumo Jump, Lumo Kart und
// Lernaufgaben verwenden dieselbe Wallet'.
//
// Diese Wallet wird beim App-Start geladen, bei jeder Aenderung sofort
// persistent gespeichert (write-through) und bleibt nach Neustart erhalten.
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Aktueller Wallet-Zustand (Snapshot).
class RewardWallet {
  const RewardWallet({
    this.stars = 0,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.totalEarnedStars = 0,
    this.lastDailyKey = '',
  });

  final int stars;
  final int xp;
  final int level;
  final int streak;
  final int totalEarnedStars;
  /// Format: yyyy-mm-dd des letzten Lerntages, fuer Streak-Berechnung.
  final String lastDailyKey;

  RewardWallet copyWith({
    int? stars,
    int? xp,
    int? level,
    int? streak,
    int? totalEarnedStars,
    String? lastDailyKey,
  }) {
    return RewardWallet(
      stars: stars ?? this.stars,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      totalEarnedStars: totalEarnedStars ?? this.totalEarnedStars,
      lastDailyKey: lastDailyKey ?? this.lastDailyKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'stars': stars,
        'xp': xp,
        'level': level,
        'streak': streak,
        'totalEarnedStars': totalEarnedStars,
        'lastDailyKey': lastDailyKey,
      };

  factory RewardWallet.fromJson(Map<String, dynamic> j) => RewardWallet(
        stars: (j['stars'] as int?) ?? 0,
        xp: (j['xp'] as int?) ?? 0,
        level: (j['level'] as int?) ?? 1,
        streak: (j['streak'] as int?) ?? 0,
        totalEarnedStars: (j['totalEarnedStars'] as int?) ?? 0,
        lastDailyKey: (j['lastDailyKey'] as String?) ?? '',
      );

  @override
  String toString() =>
      'RewardWallet(stars: $stars, xp: $xp, level: $level, streak: $streak)';
}

/// Persistente Wallet mit Lazy-Load + Write-Through.
class RewardWalletRepository {
  RewardWalletRepository._();
  static final RewardWalletRepository instance = RewardWalletRepository._();

  static const _storageKey = 'lumo_reward_wallet_v1';
  static const _legacyStarsKey = 'lumo_legacy_stars';
  static const _legacyXpKey = 'lumo_legacy_xp';

  RewardWallet _wallet = const RewardWallet();
  bool _loaded = false;
  final _controller = StreamController<RewardWallet>.broadcast();

  /// Stream, der bei jeder Aenderung den neuen Wallet-Stand emittiert.
  /// Spiele/Lernmodule koennen darauf hoeren.
  Stream<RewardWallet> get changes => _controller.stream;

  RewardWallet get snapshot => _wallet;

  /// Laedt die Wallet aus SharedPreferences. Sicher: bei Fehlern Defaults.
  /// Wenn keine Wallet existiert, aber Legacy-Stars/XP gefunden werden,
  /// migriert sie diese.
  Future<RewardWallet> load() async {
    if (_loaded) return _wallet;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        // Defensive JSON-Parsing
        try {
          final map = _decode(raw);
          _wallet = RewardWallet.fromJson(map);
        } catch (_) {
          _wallet = const RewardWallet();
        }
      } else {
        // Legacy-Migration falls vorhanden
        final legacyStars = prefs.getInt(_legacyStarsKey) ?? 0;
        final legacyXp = prefs.getInt(_legacyXpKey) ?? 0;
        if (legacyStars > 0 || legacyXp > 0) {
          _wallet = RewardWallet(
            stars: legacyStars,
            xp: legacyXp,
            level: 1 + (legacyXp ~/ 100),
            totalEarnedStars: legacyStars,
          );
          await _persist();
        }
      }
    } catch (_) {
      // Bei jeglichem Fehler: leere Wallet, App startet trotzdem
      _wallet = const RewardWallet();
    }
    _loaded = true;
    return _wallet;
  }

  /// Sterne dazugeben. Sofort persistent gespeichert.
  Future<RewardWallet> addStars(int delta) async {
    if (!_loaded) await load();
    if (delta == 0) return _wallet;
    final newStars = (_wallet.stars + delta).clamp(0, 999999);
    final newTotal = _wallet.totalEarnedStars + (delta > 0 ? delta : 0);
    _wallet = _wallet.copyWith(
      stars: newStars,
      totalEarnedStars: newTotal,
    );
    await _persist();
    _emit();
    return _wallet;
  }

  /// XP dazugeben + Level-Berechnung.
  Future<RewardWallet> addXp(int delta) async {
    if (!_loaded) await load();
    if (delta == 0) return _wallet;
    final newXp = (_wallet.xp + delta).clamp(0, 9999999);
    // Einfache Level-Formel: Level = 1 + xp / 100
    final newLevel = 1 + (newXp ~/ 100);
    _wallet = _wallet.copyWith(xp: newXp, level: newLevel);
    await _persist();
    _emit();
    return _wallet;
  }

  /// Markiere heutigen Lerntag - aktualisiert Streak.
  Future<RewardWallet> markDailyActivity() async {
    if (!_loaded) await load();
    final today = _todayKey();
    if (_wallet.lastDailyKey == today) return _wallet;
    int newStreak = 1;
    if (_wallet.lastDailyKey.isNotEmpty) {
      final last = DateTime.tryParse(_wallet.lastDailyKey);
      if (last != null) {
        final diff = DateTime.now().difference(last).inDays;
        if (diff == 1) {
          newStreak = _wallet.streak + 1;
        } else if (diff > 1) {
          newStreak = 1;
        } else {
          newStreak = _wallet.streak; // gleicher Tag = nicht aendern
        }
      }
    }
    _wallet = _wallet.copyWith(streak: newStreak, lastDailyKey: today);
    await _persist();
    _emit();
    return _wallet;
  }

  /// Reset (z.B. fuer Profil-Wechsel oder Eltern-Sperre).
  Future<void> reset() async {
    _wallet = const RewardWallet();
    await _persist();
    _emit();
  }

  // ── Interna ───────────────────────────────────────────────────────
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _encode(_wallet.toJson()));
    } catch (_) {
      // Fehler beim Speichern ist nicht App-kritisch
    }
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_wallet);
  }

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _encode(Map<String, dynamic> m) {
    // Simple inline JSON encode without dart:convert dependency duplication
    // We rely on shared_preferences storing strings - use minimalist encoding
    final parts = <String>[];
    m.forEach((k, v) {
      parts.add('"$k":${v is String ? '"$v"' : v}');
    });
    return '{${parts.join(',')}}';
  }

  Map<String, dynamic> _decode(String json) {
    final result = <String, dynamic>{};
    // Minimal JSON-Parser fuer unsere flachen Wallet-Objekte.
    final body = json.trim();
    if (!body.startsWith('{') || !body.endsWith('}')) return result;
    final inner = body.substring(1, body.length - 1);
    final parts = _splitTopLevel(inner);
    for (final part in parts) {
      final colon = part.indexOf(':');
      if (colon < 0) continue;
      var key = part.substring(0, colon).trim();
      var val = part.substring(colon + 1).trim();
      if (key.startsWith('"') && key.endsWith('"')) {
        key = key.substring(1, key.length - 1);
      }
      if (val.startsWith('"') && val.endsWith('"')) {
        result[key] = val.substring(1, val.length - 1);
      } else {
        result[key] = int.tryParse(val) ?? 0;
      }
    }
    return result;
  }

  List<String> _splitTopLevel(String s) {
    final out = <String>[];
    int depth = 0;
    bool inStr = false;
    var buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '"' && (i == 0 || s[i - 1] != '\\')) inStr = !inStr;
      if (!inStr) {
        if (c == '{' || c == '[') depth++;
        if (c == '}' || c == ']') depth--;
        if (c == ',' && depth == 0) {
          out.add(buf.toString());
          buf = StringBuffer();
          continue;
        }
      }
      buf.write(c);
    }
    if (buf.isNotEmpty) out.add(buf.toString());
    return out;
  }
}
