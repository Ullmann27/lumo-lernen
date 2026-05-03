import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile.dart';

class ProfileRepository {
  static const _profileKey = 'lumo_active_profile';
  static const _introSeenKey = 'lumo_intro_seen';

  Future<UserProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await _clearBrokenProfile(prefs);
        return null;
      }
      final profile = UserProfile.fromJson(Map<String, dynamic>.from(decoded)).normalized();
      // Reparierte Werte sofort zurückspeichern, damit spätere Starts sauber sind.
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
      await prefs.setBool(_introSeenKey, true);
      return profile;
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await _clearBrokenProfile(prefs);
      } catch (_) {}
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanProfile = profile.normalized().copyWith(lastActiveAt: DateTime.now());
    await prefs.setString(_profileKey, jsonEncode(cleanProfile.toJson()));
    await prefs.setBool(_introSeenKey, true);
  }

  Future<bool> hasFinishedIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_introSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_introSeenKey);
  }

  Future<void> _clearBrokenProfile(SharedPreferences prefs) async {
    await prefs.remove(_profileKey);
    await prefs.remove(_introSeenKey);
  }
}
