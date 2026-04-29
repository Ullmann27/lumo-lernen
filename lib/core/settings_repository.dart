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
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return AppSettings.fromJson(json);
      if (json is Map) return AppSettings.fromJson(Map<String, dynamic>.from(json));
      return const AppSettings();
    } catch (_) {
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
