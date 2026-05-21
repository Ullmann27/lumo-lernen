// ════════════════════════════════════════════════════════════════════════
// LUMO COMPANION STATE — Persistente Persoenlichkeit fuer Mirror
// ════════════════════════════════════════════════════════════════════════
// Premium-Wert: Lumo erinnert sich an das Kind, hat Beziehung, wird zum
// echten Freund. Speichert Likes, Streak, letzte Interaktion.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/lumo_mirror.dart';

/// Lumo-Companion-Mood basierend auf Tageszeit + Aktivitaet.
class LumoCompanionState {
  LumoCompanionState._();
  static final LumoCompanionState instance = LumoCompanionState._();

  static const _key = 'lumo_companion_v1';

  String _childName = 'Freund';
  int _correctToday = 0;
  int _wrongToday = 0;
  int _streakDays = 0;
  String? _lastDate;
  String? _favoriteTopic; // 'math', 'tiere', etc
  int _totalInteractions = 0;
  // Lifetime-Stats (Premium-Erinnerungen):
  int _bestStreak = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  int _bestDay = 0; // hoechste correct an einem Tag jemals
  bool _loaded = false;

  String get childName => _childName;
  int get correctToday => _correctToday;
  int get wrongToday => _wrongToday;
  int get streakDays => _streakDays;
  int get totalInteractions => _totalInteractions;
  int get bestStreak => _bestStreak;
  int get totalCorrect => _totalCorrect;
  int get totalWrong => _totalWrong;
  int get bestDay => _bestDay;
  String? get favoriteTopic => _favoriteTopic;

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _childName = j['name'] as String? ?? 'Freund';
        _correctToday = j['ct'] as int? ?? 0;
        _wrongToday = j['wt'] as int? ?? 0;
        _streakDays = j['sd'] as int? ?? 0;
        _lastDate = j['ld'] as String?;
        _favoriteTopic = j['ft'] as String?;
        _totalInteractions = j['ti'] as int? ?? 0;
        _bestStreak = j['bs'] as int? ?? 0;
        _totalCorrect = j['tc'] as int? ?? 0;
        _totalWrong = j['tw'] as int? ?? 0;
        _bestDay = j['bd'] as int? ?? 0;
      } catch (_) {}
    }
    // Tageswechsel-Check
    final today = _today();
    if (_lastDate != today) {
      // Best-Day-Check bevor wir _correctToday zuruecksetzen.
      if (_correctToday > _bestDay) _bestDay = _correctToday;
      _correctToday = 0;
      _wrongToday = 0;
      final yesterday = _todayMinus(1);
      if (_lastDate == yesterday) {
        _streakDays++;
        if (_streakDays > _bestStreak) _bestStreak = _streakDays;
      } else if (_lastDate != null) {
        _streakDays = 0;
      }
      _lastDate = today;
      await save();
    }
    _loaded = true;
  }

  String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
  }
  String _todayMinus(int days) {
    final d = DateTime.now().subtract(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode({
      'name': _childName,
      'ct': _correctToday,
      'wt': _wrongToday,
      'sd': _streakDays,
      'ld': _lastDate,
      'ft': _favoriteTopic,
      'ti': _totalInteractions,
      'bs': _bestStreak,
      'tc': _totalCorrect,
      'tw': _totalWrong,
      'bd': _bestDay,
    }));
  }

  Future<void> setChildName(String name) async {
    _childName = name;
    await save();
  }

  /// Wird von Modulen aufgerufen wenn Kind richtig antwortet.
  Future<void> recordCorrect({String? topic}) async {
    await load();
    _correctToday++;
    _totalCorrect++;
    _totalInteractions++;
    if (topic != null) _favoriteTopic = topic;
    // Best-Day live aktualisieren - Eltern sehen heute schon den neuen Rekord.
    if (_correctToday > _bestDay) _bestDay = _correctToday;
    await save();
  }

  Future<void> recordWrong() async {
    await load();
    _wrongToday++;
    _totalWrong++;
    _totalInteractions++;
    await save();
  }

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
    if (_wrongToday >= 5) return LumoMirrorMood.sad;
    if (_wrongToday >= 3) return LumoMirrorMood.think;
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
      greetings.add(
          'Heute Lust auf deinen Rekord ($_bestDay an einem Tag)?');
    }
    if (_totalCorrect >= 500) {
      greetings.add('Du hast schon $_totalCorrect Aufgaben gemeistert!');
    } else if (_totalCorrect >= 100) {
      greetings.add('Bist schon ueber $_totalCorrect richtige Antworten!');
    }
    // Favorit
    if (_favoriteTopic != null && greetings.length < 2) {
      greetings.add('Heute wieder ${_favoriteTopic}?');
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
