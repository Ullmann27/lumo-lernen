import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'parent_pin_recovery.dart';

class SettingsRepository {
  SettingsRepository._();
  static const _key = 'lumo_app_settings_v1';
  static const _coachActivationKey = 'lumo_requested_coach_activation_2026_10_02';
  static const _requestedCoachActivation =
      bool.fromEnvironment('LUMO_ACTIVATE_COACH');

  static Future<AppSettings> load() async {
    final settings = await _loadStoredSettings();
    return activateRequestedCoachOnce(settings, requested: _requestedCoachActivation);
  }

  static Future<AppSettings> _loadStoredSettings() async {
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

  /// Explicitly requested owner build only. Once applied, later parent choices
  /// remain authoritative, including switching the coach off again.
  static Future<AppSettings> activateRequestedCoachOnce(
    AppSettings current, {required bool requested}
  ) async {
    if (!requested) return current;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_coachActivationKey) == true) return current;
    final next = current.copyWith(
      aiProxyEnabled: true,
      aiLearningMode: AiLearningMode.fullCoach,
    );
    await save(next);
    final marked = await prefs.setBool(_coachActivationKey, true);
    if (!marked) throw StateError('KI-Aktivierung konnte nicht gespeichert werden.');
    return next;
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_key, jsonEncode(settings.toJson()));
    if (!saved) throw StateError('Einstellungen konnten nicht gespeichert werden.');
  }

  /// Called by first-time setup, or by the already authenticated parent editor.
  static Future<AppSettings> setParentPin({
    required String pin,
    required String recoveryCodeHash,
    bool firstSetupOnly = false,
  }) async {
    _validateParentCredentials(pin, recoveryCodeHash);
    final current = await load();
    if (firstSetupOnly && current.parentPinConfigured) {
      throw StateError('Es ist bereits eine eigene Eltern-PIN eingerichtet.');
    }
    final next = current.copyWith(
      parentPin: pin,
      parentPinConfigured: true,
      parentRecoveryCodeHash: recoveryCodeHash,
    );
    await save(next);
    return next;
  }

  /// A saved recovery secret is required. There is no shared reset PIN.
  static Future<AppSettings> recoverParentPin({
    required String recoveryCode,
    required String newPin,
    required String newRecoveryCodeHash,
  }) async {
    _validateParentCredentials(newPin, newRecoveryCodeHash);
    final current = await load();
    if (!ParentPinRecovery.matches(recoveryCode, current.parentRecoveryCodeHash)) {
      throw StateError('Der Wiederherstellungscode stimmt nicht.');
    }
    final next = current.copyWith(
      parentPin: newPin,
      parentPinConfigured: true,
      parentRecoveryCodeHash: newRecoveryCodeHash,
    );
    await save(next);
    return next;
  }

  static void _validateParentCredentials(String pin, String recoveryCodeHash) {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin) ||
        pin == AppSettings.initialParentPin ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(recoveryCodeHash)) {
      throw ArgumentError('Eine eigene PIN mit 4 bis 8 Ziffern und ein Wiederherstellungscode sind erforderlich.');
    }
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
