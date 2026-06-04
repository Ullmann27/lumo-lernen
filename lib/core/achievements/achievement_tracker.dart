// ════════════════════════════════════════════════════════════════════════
// LUMO ACHIEVEMENT TRACKER — Live-Tracking + Unlock-Trigger
// ════════════════════════════════════════════════════════════════════════
// Singleton-ChangeNotifier. Beim App-Start einmal hydrate(). Danach via
// recordEvent(metric, by:n) inkrementieren. Wenn dabei ein Achievement
// freigeschaltet wird, wird unlockStream gefeuert + persistiert.
//
// UI lauscht auf:
//   - notifyListeners (zaehler-Aenderungen, Wall-UI)
//   - unlockStream (zeigt globalen Unlock-Toast/Burst)

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'achievement_repository.dart';
import 'lumo_achievement.dart';

class AchievementTracker extends ChangeNotifier {
  AchievementTracker._();

  static final AchievementTracker instance = AchievementTracker._();

  final AchievementRepository _repo = const AchievementRepository();

  final Map<AchievementMetric, int> _counters = <AchievementMetric, int>{};
  final Map<String, DateTime> _unlocked = <String, DateTime>{};
  final StreamController<LumoAchievement> _unlockController =
      StreamController<LumoAchievement>.broadcast();

  bool _hydrated = false;

  Stream<LumoAchievement> get unlockStream => _unlockController.stream;
  bool get hydrated => _hydrated;

  Future<void> hydrate() async {
    if (_hydrated) return;
    final c = await _repo.loadCounters();
    _counters
      ..clear()
      ..addAll(c);
    final u = await _repo.loadUnlocked();
    _unlocked
      ..clear()
      ..addAll(u);
    _hydrated = true;
    notifyListeners();
  }

  int counter(AchievementMetric metric) => _counters[metric] ?? 0;

  bool isUnlocked(String achievementId) => _unlocked.containsKey(achievementId);

  Map<String, DateTime> get unlockedMap => Map.unmodifiable(_unlocked);

  /// Liefert Progress-Liste fuer die Wall-UI (alle 14 Achievements mit
  /// aktuellem Stand und Unlock-Flag).
  List<LumoAchievementProgress> progressList() {
    return LumoAchievementCatalog.all
        .map((a) => LumoAchievementProgress(
              achievement: a,
              current: counter(a.metric),
              unlocked: isUnlocked(a.id),
              unlockedAt: _unlocked[a.id],
            ))
        .toList(growable: false);
  }

  int unlockedCount() => _unlocked.length;

  /// Inkrementiert einen Counter. Wenn dadurch ein Achievement-Target erreicht
  /// ist, wird das Achievement freigeschaltet + Stream gefeuert.
  Future<void> recordEvent(AchievementMetric metric, {int by = 1}) async {
    if (!_hydrated) await hydrate();
    final old = _counters[metric] ?? 0;
    final updated = old + by;
    _counters[metric] = updated;
    // Achievement-Check: alle die diese Metric nutzen und noch nicht
    // freigeschaltet sind.
    final newlyUnlocked = <LumoAchievement>[];
    for (final a in LumoAchievementCatalog.all) {
      if (a.metric != metric) continue;
      if (_unlocked.containsKey(a.id)) continue;
      if (updated >= a.target) {
        final when = DateTime.now();
        _unlocked[a.id] = when;
        newlyUnlocked.add(a);
        // Best-Effort Persist (await aber kein Fehler-Throw)
        unawaited(_repo.setUnlocked(a.id, when));
      }
    }
    // Counter persistieren (kein await da nicht UI-blocking)
    unawaited(_repo.saveCounters(Map<AchievementMetric, int>.from(_counters)));
    notifyListeners();
    // Stream-Events FEUERN nachdem notifyListeners damit UI-Subscriber
    // den Counter schon aktualisiert hat.
    for (final a in newlyUnlocked) {
      _unlockController.add(a);
    }
  }

  /// Direkt-Setzer fuer Metriken die schon woanders persistiert sind
  /// (z.B. starsTotal kommt aus AppState). Triggert Unlock-Check.
  Future<void> setMetric(AchievementMetric metric, int value) async {
    if (!_hydrated) await hydrate();
    final old = _counters[metric] ?? 0;
    if (old == value) return;
    final delta = value - old;
    if (delta > 0) {
      await recordEvent(metric, by: delta);
    } else {
      _counters[metric] = value;
      unawaited(_repo.saveCounters(Map<AchievementMetric, int>.from(_counters)));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _unlockController.close();
    super.dispose();
  }
}
