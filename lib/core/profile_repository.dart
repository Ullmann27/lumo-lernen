import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

class ProfileRepository {
  static const _profileKey = 'lumo_active_profile';
  static const _introSeenKey = 'lumo_intro_seen';

  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await prefs.setBool(_introSeenKey, true);
  }

  Future<bool> hasFinishedIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introSeenKey) ?? false;
  }

  Future<void> resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_introSeenKey);
  }
}
