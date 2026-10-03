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
import 'dart:convert';

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
    this.gameResultIds = const <String>[],
    this.lumoCardsWinStreak = 0,
  });

  final int stars;
  final int xp;
  final int level;
  final int streak;
  final int totalEarnedStars;

  /// Format: yyyy-mm-dd des letzten Lerntages, fuer Streak-Berechnung.
  final String lastDailyKey;

  /// IDs live in the same persisted snapshot as their reward, for crash-safe replay.
  final List<String> gameResultIds;

  /// Consecutive Cards wins share the same transaction as their Stars and XP.
  final int lumoCardsWinStreak;

  RewardWallet copyWith({
    int? stars,
    int? xp,
    int? level,
    int? streak,
    int? totalEarnedStars,
    String? lastDailyKey,
    List<String>? gameResultIds,
    int? lumoCardsWinStreak,
  }) {
    return RewardWallet(
      stars: stars ?? this.stars,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      totalEarnedStars: totalEarnedStars ?? this.totalEarnedStars,
      lastDailyKey: lastDailyKey ?? this.lastDailyKey,
      gameResultIds: gameResultIds ?? this.gameResultIds,
      lumoCardsWinStreak: lumoCardsWinStreak ?? this.lumoCardsWinStreak,
    );
  }

  Map<String, dynamic> toJson() => {
        'stars': stars,
        'xp': xp,
        'level': level,
        'streak': streak,
        'totalEarnedStars': totalEarnedStars,
        'lastDailyKey': lastDailyKey,
        'gameResultIds': gameResultIds,
        'lumoCardsWinStreak': lumoCardsWinStreak,
      };

  factory RewardWallet.fromJson(Map<String, dynamic> j) => RewardWallet(
        stars: (j['stars'] as int?) ?? 0,
        xp: (j['xp'] as int?) ?? 0,
        level: 1 + (((j['xp'] as int?) ?? 0).clamp(0, 999999999) ~/ 400),
        streak: (j['streak'] as int?) ?? 0,
        totalEarnedStars: (j['totalEarnedStars'] as int?) ?? 0,
        lastDailyKey: (j['lastDailyKey'] as String?) ?? '',
        gameResultIds:
            (j['gameResultIds'] as List?)?.whereType<String>().toList() ??
                const <String>[],
        lumoCardsWinStreak: j['lumoCardsWinStreak'] is int
            ? (j['lumoCardsWinStreak'] as int).clamp(0, 999999)
            : 0,
      );

  @override
  String toString() =>
      'RewardWallet(stars: $stars, xp: $xp, level: $level, streak: $streak)';
}

/// Persistente Wallet mit Lazy-Load + Write-Through.
class RewardWalletRepository {
  RewardWalletRepository();
  static final RewardWalletRepository instance = RewardWalletRepository();

  static const _storageKey = 'lumo_reward_wallet_v1';
  static const _legacyStarsKey = 'lumo_legacy_stars';
  static const _legacyXpKey = 'lumo_legacy_xp';

  RewardWallet _wallet = const RewardWallet();
  bool _loaded = false;
  Future<RewardWallet>? _loadFuture;
  // Every balance change shares this queue. A failed transaction cannot roll
  // back a later lesson reward, reset, or another completed game.
  Future<void> _mutations = Future<void>.value();
  final _controller = StreamController<RewardWallet>.broadcast();

  /// Stream, der bei jeder Aenderung den neuen Wallet-Stand emittiert.
  /// Spiele/Lernmodule koennen darauf hoeren.
  Stream<RewardWallet> get changes => _controller.stream;

  RewardWallet get snapshot => _wallet;

  /// Laedt die Wallet aus SharedPreferences. Sicher: bei Fehlern Defaults.
  /// Wenn keine Wallet existiert, aber Legacy-Stars/XP gefunden werden,
  /// migriert sie diese.
  Future<RewardWallet> load() {
    if (_loaded) return Future<RewardWallet>.value(_wallet);
    return _loadFuture ??= _loadFromDisk();
  }

  Future<RewardWallet> _loadFromDisk() async {
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
        final storedStars = prefs.getInt(_legacyStarsKey) ?? 0;
        final shopStars = _legacyShopStars(prefs);
        // These were two mirrors of the same balance, not separate earnings.
        final legacyStars = storedStars > shopStars ? storedStars : shopStars;
        final legacyXp = prefs.getInt(_legacyXpKey) ?? 0;
        if (legacyStars > 0 || legacyXp > 0) {
          _wallet = RewardWallet(
            stars: legacyStars,
            xp: legacyXp,
            level: 1 + (legacyXp ~/ 400),
            totalEarnedStars: legacyStars,
          );
        }
        // Persist even an empty wallet: an explicit zero must not later be
        // replaced by an old shop snapshot after rewards have been spent.
        try {
          await _persist(_wallet);
        } catch (_) {
          // Keep successfully read legacy balances. The next real transaction
          // includes them and retries persistence; loading never spends them.
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
  Future<RewardWallet> addStars(int delta) =>
      applyRewardDelta(starsDelta: delta);

  /// XP dazugeben + Level-Berechnung.
  Future<RewardWallet> addXp(int delta) => applyRewardDelta(xpDelta: delta);

  /// Persists both parts of one lesson reward in one transaction. Failure means
  /// neither part was committed; the caller may retry the complete delta.
  Future<RewardWallet> applyRewardDelta({
    int starsDelta = 0,
    int xpDelta = 0,
  }) =>
      _transaction((current) async {
        if (starsDelta == 0 && xpDelta == 0) return current;
        final nextXp = (current.xp + xpDelta).clamp(0, 9999999);
        return _commit(current.copyWith(
          stars: (current.stars + starsDelta).clamp(0, 999999),
          totalEarnedStars:
              current.totalEarnedStars + (starsDelta > 0 ? starsDelta : 0),
          xp: nextXp,
          level: 1 + nextXp ~/ 400,
        ));
      });

  /// Awards one completed native race exactly once, including after process death.
  Future<RewardWallet> awardGameResult({
    required String resultId,
    required int stars,
    required int xp,
  }) =>
      _transaction((current) async {
        if (resultId.isEmpty ||
            resultId.length > 160 ||
            stars < 0 ||
            stars > 100 ||
            xp < 0 ||
            xp > 1000) {
          throw ArgumentError('Ungültiges Spielergebnis');
        }
        if (current.gameResultIds.contains(resultId)) return current;
        final nextXp = (current.xp + xp).clamp(0, 9999999);
        return _commit(current.copyWith(
          stars: (current.stars + stars).clamp(0, 999999),
          totalEarnedStars: current.totalEarnedStars + stars,
          xp: nextXp,
          level: 1 + nextXp ~/ 400,
          gameResultIds: [...current.gameResultIds, resultId],
        ));
      });

  /// Cards reward, win sequence, and XP either all persist or all remain pending.
  Future<RewardWallet> awardLumoCardsResult({required bool won}) =>
      _transaction((current) async {
        final nextStreak =
            won ? (current.lumoCardsWinStreak + 1).clamp(0, 999999) : 0;
        final stars = won ? (2 + nextStreak).clamp(3, 6) : 1;
        final xp = won ? 15 + nextStreak * 5 : 0;
        final nextXp = (current.xp + xp).clamp(0, 9999999);
        return _commit(current.copyWith(
          stars: (current.stars + stars).clamp(0, 999999),
          totalEarnedStars: current.totalEarnedStars + stars,
          xp: nextXp,
          level: 1 + nextXp ~/ 400,
          lumoCardsWinStreak: nextStreak,
        ));
      });

  /// Markiere heutigen Lerntag - aktualisiert Streak.
  Future<RewardWallet> markDailyActivity() => _transaction((current) async {
        final today = _todayKey();
        if (current.lastDailyKey == today) return current;
        int newStreak = 1;
        if (current.lastDailyKey.isNotEmpty) {
          final last = DateTime.tryParse(current.lastDailyKey);
          if (last != null) {
            final diff = DateTime.now().difference(last).inDays;
            if (diff == 1) {
              newStreak = current.streak + 1;
            } else if (diff > 1) {
              newStreak = 1;
            } else {
              newStreak = current.streak; // gleicher Tag = nicht aendern
            }
          }
        }
        return _commit(
            current.copyWith(streak: newStreak, lastDailyKey: today));
      });

  /// Reset (z.B. fuer Profil-Wechsel oder Eltern-Sperre).
  Future<void> reset() =>
      _transaction((_) => _commit(const RewardWallet())).then<void>((_) {});

  Future<RewardWallet> _transaction(
    Future<RewardWallet> Function(RewardWallet current) operation,
  ) {
    final pending = _mutations.then((_) async {
      await load();
      return operation(_wallet);
    });
    // A failed operation is reported to its caller but must not poison the
    // queue: later rewards and replay of the failed native event still run.
    _mutations =
        pending.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return pending;
  }

  Future<RewardWallet> _commit(RewardWallet next) async {
    // Balance and result identities are persisted in one snapshot before any
    // subscriber can observe them. Failure leaves the previous state intact.
    await _persist(next);
    _wallet = next;
    _emit();
    return next;
  }

  // ── Interna ───────────────────────────────────────────────────────
  int _legacyShopStars(SharedPreferences prefs) {
    try {
      final profileRaw = prefs.getString('lumo_active_profile');
      final profile = profileRaw == null ? null : jsonDecode(profileRaw);
      final name =
          profile is Map ? (profile['name'] as String? ?? 'Lena') : 'Lena';
      final grade =
          profile is Map ? (profile['grade'] as num?)?.toInt() ?? 1 : 1;
      final safeName = name.trim().isEmpty
          ? 'kind'
          : name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final raw = prefs.getString('lumo.reward_shop.local_${safeName}_$grade');
      if (raw == null) return 0;
      final shop = jsonDecode(raw);
      if (shop is! Map) return 0;
      return ((shop['availableStars'] as num?)?.toInt() ?? 0).clamp(0, 999999);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _persist(RewardWallet snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        await prefs.setString(_storageKey, _encode(snapshot.toJson()));
    if (!saved) throw StateError('Belohnung konnte nicht gespeichert werden');
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
    return jsonEncode(m);
  }

  Map<String, dynamic> _decode(String json) {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Invalid wallet');
  }
}
