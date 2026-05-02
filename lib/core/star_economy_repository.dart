import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lokales Sternkonto-Fundament für Lumo Lernen.
///
/// Grundregeln:
/// - keine Echtgeld-Logik
/// - keine externen Links
/// - keine Cloud-Speicherung
/// - Sterne verfallen nie
/// - Tageslimit gegen Suchtdesign
/// - Eltern-/Shop-Funktionen kommen später separat
class StarEconomyRepository {
  const StarEconomyRepository();

  static const int maxRegularStarsPerDay = 100;
  static const int maxLedgerEntries = 300;

  Future<StarEconomySnapshot> load({
    required String childId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(_entriesKey(childId));
    final entries = _decodeEntries(rawEntries);
    final todayKey = _dateKey(DateTime.now());
    final todayRegularStars = entries
        .where((entry) => _dateKey(entry.createdAt) == todayKey)
        .where((entry) => !entry.allowBeyondDailyCap)
        .fold<int>(0, (sum, entry) => sum + entry.stars);
    final totalStars = entries.fold<int>(0, (sum, entry) => sum + entry.stars);
    final totalXp = entries.fold<int>(0, (sum, entry) => sum + entry.xp);

    return StarEconomySnapshot(
      childId: childId,
      totalStars: totalStars,
      totalXp: totalXp,
      level: StarLevelCurve.levelForStars(totalStars),
      todayRegularStars: todayRegularStars,
      todayRemainingRegularStars: (maxRegularStarsPerDay - todayRegularStars).clamp(0, maxRegularStarsPerDay),
      entries: entries,
    );
  }

  /// Verbucht Sterne lokal und respektiert das Tageslimit.
  ///
  /// Schularbeiten/Tests dürfen mit [allowBeyondDailyCap] echte Top-Leistung
  /// zusätzlich belohnen. Normale Übungssterne sind auf 100 pro Tag begrenzt.
  Future<StarGrantResult> grant({
    required String childId,
    required int requestedStars,
    required int xp,
    required StarRewardReason reason,
    required String source,
    bool allowBeyondDailyCap = false,
    DateTime? now,
  }) async {
    final createdAt = now ?? DateTime.now();
    final snapshot = await load(childId: childId);
    final sanitizedRequest = requestedStars.clamp(0, 500);
    final grantedStars = allowBeyondDailyCap
        ? sanitizedRequest
        : sanitizedRequest.clamp(0, snapshot.todayRemainingRegularStars);

    if (grantedStars == 0 && xp <= 0) {
      return StarGrantResult(
        granted: false,
        requestedStars: sanitizedRequest,
        grantedStars: 0,
        cappedByDailyLimit: !allowBeyondDailyCap && sanitizedRequest > 0 && snapshot.todayRemainingRegularStars == 0,
        snapshot: snapshot,
      );
    }

    final entry = StarLedgerEntry(
      id: 'star_${createdAt.microsecondsSinceEpoch}',
      stars: grantedStars,
      xp: xp.clamp(0, 1000),
      reason: reason,
      source: source,
      createdAt: createdAt,
      allowBeyondDailyCap: allowBeyondDailyCap,
    );

    final nextEntries = <StarLedgerEntry>[...snapshot.entries, entry];
    final trimmed = nextEntries.length > maxLedgerEntries
        ? nextEntries.sublist(nextEntries.length - maxLedgerEntries)
        : nextEntries;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_entriesKey(childId), _encodeEntries(trimmed));
    final next = await load(childId: childId);

    return StarGrantResult(
      granted: true,
      requestedStars: sanitizedRequest,
      grantedStars: grantedStars,
      cappedByDailyLimit: !allowBeyondDailyCap && grantedStars < sanitizedRequest,
      snapshot: next,
    );
  }

  Future<void> reset({required String childId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey(childId));
  }

  String _entriesKey(String childId) => 'lumo_star_ledger_${_sanitize(childId)}';

  String _sanitize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _dateKey(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _encodeEntries(List<StarLedgerEntry> entries) =>
      jsonEncode(entries.map((entry) => entry.toJson()).toList(growable: false));

  List<StarLedgerEntry> _decodeEntries(String? raw) {
    if (raw == null || raw.isEmpty) return const <StarLedgerEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <StarLedgerEntry>[];
      return decoded
          .whereType<Map>()
          .map((entry) => StarLedgerEntry.fromJson(Map<String, Object?>.from(entry)))
          .whereType<StarLedgerEntry>()
          .toList(growable: false);
    } catch (_) {
      return const <StarLedgerEntry>[];
    }
  }
}

class StarEconomySnapshot {
  const StarEconomySnapshot({
    required this.childId,
    required this.totalStars,
    required this.totalXp,
    required this.level,
    required this.todayRegularStars,
    required this.todayRemainingRegularStars,
    required this.entries,
  });

  final String childId;
  final int totalStars;
  final int totalXp;
  final int level;
  final int todayRegularStars;
  final int todayRemainingRegularStars;
  final List<StarLedgerEntry> entries;

  bool get dailyLimitReached => todayRemainingRegularStars <= 0;
}

class StarGrantResult {
  const StarGrantResult({
    required this.granted,
    required this.requestedStars,
    required this.grantedStars,
    required this.cappedByDailyLimit,
    required this.snapshot,
  });

  final bool granted;
  final int requestedStars;
  final int grantedStars;
  final bool cappedByDailyLimit;
  final StarEconomySnapshot snapshot;
}

class StarLedgerEntry {
  const StarLedgerEntry({
    required this.id,
    required this.stars,
    required this.xp,
    required this.reason,
    required this.source,
    required this.createdAt,
    required this.allowBeyondDailyCap,
  });

  final String id;
  final int stars;
  final int xp;
  final StarRewardReason reason;
  final String source;
  final DateTime createdAt;
  final bool allowBeyondDailyCap;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'stars': stars,
        'xp': xp,
        'reason': reason.name,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        'allowBeyondDailyCap': allowBeyondDailyCap,
      };

  static StarLedgerEntry? fromJson(Map<String, Object?> json) {
    final id = json['id']?.toString();
    final stars = json['stars'];
    final xp = json['xp'];
    final reasonRaw = json['reason']?.toString();
    final source = json['source']?.toString();
    final createdRaw = json['createdAt']?.toString();
    if (id == null || stars is! int || xp is! int || reasonRaw == null || source == null || createdRaw == null) {
      return null;
    }
    final createdAt = DateTime.tryParse(createdRaw);
    if (createdAt == null) return null;
    final reason = StarRewardReason.values.where((value) => value.name == reasonRaw).firstOrNull;
    if (reason == null) return null;
    return StarLedgerEntry(
      id: id,
      stars: stars,
      xp: xp,
      reason: reason,
      source: source,
      createdAt: createdAt,
      allowBeyondDailyCap: json['allowBeyondDailyCap'] == true,
    );
  }
}

enum StarRewardReason {
  taskCorrect,
  firstTryBonus,
  taskCompleted,
  dailyGoal,
  testCompleted,
  schoolworkTopResult,
  weaknessImproved,
  readingCompleted,
  parentGift,
}

class StarLevelCurve {
  const StarLevelCurve._();

  static const List<int> thresholds = <int>[
    0,
    100,
    250,
    500,
    1000,
    2000,
    3500,
    5500,
    8000,
    11500,
    16000,
  ];

  static int levelForStars(int stars) {
    var level = 1;
    for (var i = 0; i < thresholds.length; i++) {
      if (stars >= thresholds[i]) level = i + 1;
    }
    return level;
  }

  static int nextThresholdForLevel(int level) {
    if (level <= 0) return thresholds.first;
    if (level >= thresholds.length) {
      final extraLevels = level - thresholds.length + 1;
      return thresholds.last + extraLevels * 6000;
    }
    return thresholds[level];
  }
}
