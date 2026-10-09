import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsRepository {
  SettingsRepository._();
  static const _key = 'lumo_app_settings_v1';
  static Future<AppSettings> load() => _loadStoredSettings();

  static Future<AppSettings> _loadStoredSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) return const AppSettings();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final settings = AppSettings.fromJson(decoded);
        // Rewriting the supported settings removes obsolete access credentials
        // without touching profiles, progress, rewards or saved permissions.
        await prefs.setString(_key, jsonEncode(settings.toJson()));
        return settings;
      }
      if (decoded is Map) {
        final settings =
            AppSettings.fromJson(Map<String, dynamic>.from(decoded));
        await prefs.setString(_key, jsonEncode(settings.toJson()));
        return settings;
      }
      return const AppSettings();
    } catch (_) {
      // A read/migration failure must not erase the previous on-disk settings.
      return const AppSettings();
    }
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_key, jsonEncode(settings.toJson()));
    if (!saved) {
      throw StateError('Einstellungen konnten nicht gespeichert werden.');
    }
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
