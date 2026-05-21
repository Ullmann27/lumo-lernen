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
  bool _loaded = false;

  String get childName => _childName;
  int get correctToday => _correctToday;
  int get wrongToday => _wrongToday;
  int get streakDays => _streakDays;
  int get totalInteractions => _totalInteractions;

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
      } catch (_) {}
    }
    // Tageswechsel-Check
    final today = _today();
    if (_lastDate != today) {
      _correctToday = 0;
      _wrongToday = 0;
      final yesterday = _todayMinus(1);
      if (_lastDate == yesterday) {
        _streakDays++;
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
    _totalInteractions++;
    if (topic != null) _favoriteTopic = topic;
    await save();
  }

  Future<void> recordWrong() async {
    await load();
    _wrongToday++;
    await save();
  }

  /// Smart-Mood: berechnet automatisch passenden Mood basierend auf
  /// aktueller Situation.
  LumoMirrorMood smartMood() {
    final h = DateTime.now().hour;
    if (h >= 21 || h < 6) return LumoMirrorMood.sleepy;
    if (_correctToday >= 5) return LumoMirrorMood.proud;
    if (_correctToday >= 1) return LumoMirrorMood.happy;
    if (_wrongToday >= 3) return LumoMirrorMood.sad;
    if (h >= 17) return LumoMirrorMood.curious;
    return LumoMirrorMood.idle;
  }

  /// Begruessung basierend auf Tageszeit + Streak + Aktivitaet.
  String smartGreeting() {
    final h = DateTime.now().hour;
    final greetings = <String>[];
    // Zeit
    if (h < 11) {
      greetings.add('Guten Morgen, ${_childName}!');
    } else if (h < 17) {
      greetings.add('Hallo ${_childName}!');
    } else if (h < 21) {
      greetings.add('Guten Abend, ${_childName}!');
    } else {
      greetings.add('Schon spaet, ${_childName}! Schlaef gut!');
    }
    // Streak
    if (_streakDays >= 7) {
      greetings.add('${_streakDays} Tage in Folge - du bist eine Maschine!');
    } else if (_streakDays >= 3) {
      greetings.add('Schon $_streakDays Tage hintereinander - super!');
    }
    // Heute
    if (_correctToday >= 10) {
      greetings.add('Du hast heute schon ${_correctToday} richtig - WOW!');
    } else if (_correctToday >= 1) {
      greetings.add('Du hast heute schon ${_correctToday} richtig!');
    } else if (_totalInteractions > 5) {
      greetings.add('Schoen dich zu sehen!');
    }
    return greetings[math.Random().nextInt(greetings.length)];
  }
}
