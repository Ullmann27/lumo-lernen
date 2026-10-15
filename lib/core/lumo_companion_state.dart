import 'dart:math' as math;

import '../widgets/lumo_mirror.dart';
import 'learning_profile_engine.dart';

/// Read-only companion summary of the existing, captured learning profile.
/// Unowned legacy lumo_companion_v1 bytes are deliberately never read/written.
/// Accepted answers remain solely in LearningProfileEngine.
class LumoCompanionState {
  LumoCompanionState.fromProfile({
    required LearningProfileEngine profile,
    required String childName,
  }) {
    _childName = childName.trim().isEmpty ? 'Freund' : childName.trim();
    _correctToday = profile.dailyDone();
    _streakDays = profile.currentStreakDays();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final skill in profile.skills.values) {
      _totalCorrect += skill.correct;
      _totalWrong += skill.wrong;
      if (skill.lastSeen.toIso8601String().startsWith(today)) {
        _recentMisses = math.max(_recentMisses, skill.currentMisses);
      }
      if (skill.correct > _favoriteCorrect) {
        _favoriteCorrect = skill.correct;
        _favoriteTopic = skill.unit;
      }
    }
    _totalInteractions = _totalCorrect + _totalWrong;
    DateTime? previous;
    var run = 0;
    final days = profile.daily.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final day in days) {
      final date = DateTime.tryParse('${day.key}T00:00:00Z');
      if (date == null) continue;
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      _bestStreak = math.max(_bestStreak, run);
      _bestDay = math.max(_bestDay, day.value);
      previous = date;
    }
  }

  String _childName = 'Freund';
  int _correctToday = 0, _recentMisses = 0, _streakDays = 0;
  int _totalCorrect = 0, _totalWrong = 0, _totalInteractions = 0;
  int _bestStreak = 0, _bestDay = 0, _favoriteCorrect = 0;
  String? _favoriteTopic;

  String get childName => _childName;
  int get correctToday => _correctToday;
  int get streakDays => _streakDays;
  int get totalInteractions => _totalInteractions;
  int get bestStreak => _bestStreak;
  int get totalCorrect => _totalCorrect;
  int get totalWrong => _totalWrong;
  int get bestDay => _bestDay;
  String? get favoriteTopic => _favoriteTopic;

  /// Smart-Mood: berechnet automatisch passenden Mood basierend auf
  /// aktueller Situation. Reicher als vorher: jetzt 8 Zustaende.
  LumoMirrorMood smartMood() {
    final h = DateTime.now().hour;
    // Sehr spaet -> mued
    if (h >= 22 || h < 6) return LumoMirrorMood.sleepy;
    // Heutiger Best-Day-Rekord uebertroffen -> celebrating
    if (_bestDay > 0 && _correctToday > _bestDay) {
      return LumoMirrorMood.cheer;
    }
    if (_correctToday >= 10) return LumoMirrorMood.cheer;
    if (_correctToday >= 5) return LumoMirrorMood.proud;
    if (_streakDays >= 7) return LumoMirrorMood.proud;
    if (_correctToday >= 1) return LumoMirrorMood.happy;
    if (_recentMisses >= 5) return LumoMirrorMood.sad;
    if (_recentMisses >= 3) return LumoMirrorMood.think;
    // Abends nachdenklich / morgens neugierig
    if (h >= 18) return LumoMirrorMood.curious;
    if (h < 9) return LumoMirrorMood.curious;
    return LumoMirrorMood.idle;
  }

  /// Begruessung basierend auf Tageszeit + Streak + Aktivitaet +
  /// Lifetime-Erinnerungen. Viel mehr Variation als vorher.
  String smartGreeting() {
    final h = DateTime.now().hour;
    final greetings = <String>[];
    // Zeit + Wochentag
    final weekday = DateTime.now().weekday;
    final isWeekend = weekday >= 6;
    if (h < 11) {
      greetings.add('Guten Morgen, $_childName!');
      if (isWeekend) greetings.add('Wochenende mit Lumo - juhu!');
    } else if (h < 14) {
      greetings.add('Hallo $_childName!');
      greetings.add('Schoen dich zu sehen, $_childName!');
    } else if (h < 17) {
      greetings.add('Schoenen Nachmittag, $_childName!');
      greetings.add('Hallo $_childName, jetzt aber Power!');
    } else if (h < 21) {
      greetings.add('Guten Abend, $_childName!');
      greetings.add('Noch eine Runde, $_childName?');
    } else {
      greetings.add('Schon spaet, $_childName! Schlaef gut!');
    }
    // Streak
    if (_streakDays >= 30) {
      greetings.add('$_streakDays Tage Streak - du bist mein Held!');
    } else if (_streakDays >= 14) {
      greetings.add('Zwei Wochen am Stueck - Wahnsinn!');
    } else if (_streakDays >= 7) {
      greetings.add('$_streakDays Tage in Folge - du bist eine Maschine!');
    } else if (_streakDays >= 3) {
      greetings.add('Schon $_streakDays Tage hintereinander - super!');
    }
    // Heute
    if (_correctToday >= 20) {
      greetings.add('Heute schon $_correctToday richtig - heisser Tag!');
    } else if (_correctToday >= 10) {
      greetings.add('Du hast heute schon $_correctToday richtig - WOW!');
    } else if (_correctToday >= 1) {
      greetings.add('Du hast heute schon $_correctToday richtig!');
    }
    // Lifetime / Persoenliche Bestmarken
    if (_bestStreak >= 14) {
      greetings.add('Erinnerung: deine Bestmarke ist $_bestStreak Tage!');
    }
    if (_bestDay >= 30 && _correctToday < _bestDay) {
      greetings.add('Heute Lust auf deinen Rekord ($_bestDay an einem Tag)?');
    }
    if (_totalCorrect >= 500) {
      greetings.add('Du hast schon $_totalCorrect Aufgaben gemeistert!');
    } else if (_totalCorrect >= 100) {
      greetings.add('Bist schon ueber $_totalCorrect richtige Antworten!');
    }
    // Favorit
    if (_favoriteTopic != null && greetings.length < 2) {
      greetings.add('Heute wieder $_favoriteTopic?');
    }
    if (greetings.isEmpty) {
      greetings.add('Hallo $_childName!');
    }
    // Stabiler Random pro Sekunde - keine flackernde Begruessung wenn UI
    // mehrmals rebuilden sollte.
    final seed = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return greetings[math.Random(seed).nextInt(greetings.length)];
  }
}
