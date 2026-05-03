import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsRepository {
  SettingsRepository._();
  static const _key = 'lumo_app_settings_v1';

  static Future<AppSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) return const AppSettings();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final settings = AppSettings.fromJson(decoded);
        await prefs.setString(_key, jsonEncode(settings.toJson()));
        return settings;
      }
      if (decoded is Map) {
        final settings = AppSettings.fromJson(Map<String, dynamic>.from(decoded));
        await prefs.setString(_key, jsonEncode(settings.toJson()));
        return settings;
      }
      await prefs.remove(_key);
      return const AppSettings();
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      } catch (_) {}
      return const AppSettings();
    }
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
