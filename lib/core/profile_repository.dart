import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile.dart';

/// Saves the child's profile without deleting a damaged or temporarily
/// unreadable previous record. Recovery belongs to an explicit parent action,
/// never to a failed automatic read or a failed first-run save.
class ProfileRepository {
  static const _profileKey = 'lumo_active_profile';
  static const _introSeenKey = 'lumo_intro_seen';

  Future<UserProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final profile =
          UserProfile.fromJson(Map<String, dynamic>.from(decoded)).normalized();

      // Read-only profile restoration: do not rewrite/migrate the JSON here.
      // That would destroy unknown future fields or good bytes on partial
      // storage failures. The legacy intro marker is only a best-effort hint;
      // its failure must never erase or hide an otherwise valid child profile.
      try {
        if (prefs.getBool(_introSeenKey) != true) {
          await prefs.setBool(_introSeenKey, true);
        }
      } catch (_) {
        // The valid saved profile remains usable; a later normal save retries.
      }
      return profile;
    } catch (_) {
      // Missing/corrupt/temporarily unreadable is never an instruction to
      // delete keys or reset a child's journal, wallet or learning progress.
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();

    // The initial onboarding must never silently overwrite bytes that the
    // app could not deserialize at startup. A parent-controlled recovery can
    // still explicitly reset them through resetProfile().
    final previous = prefs.getString(_profileKey);
    if (previous != null && previous.trim().isNotEmpty) {
      try {
        if (jsonDecode(previous) is! Map) {
          throw const FormatException('Previously stored profile is not a map');
        }
      } catch (_) {
        throw StateError('Das vorhandene Kinderprofil kann nicht gelesen '
            'werden. Die alten Daten wurden nicht ueberschrieben.');
      }
    }

    final clean = profile.normalized().copyWith(lastActiveAt: DateTime.now());

    // Auxiliary intro completion must succeed BEFORE replacing the primary
    // record. If Android rejects this write, the old profile stays intact.
    final introSaved = await prefs.setBool(_introSeenKey, true);
    if (!introSaved) {
      throw StateError('Android hat das Speichern des Profils nicht bestaetigt '
          '(Einrichtung).');
    }
    final profileSaved =
        await prefs.setString(_profileKey, jsonEncode(clean.toJson()));
    if (!profileSaved) {
      throw StateError('Android hat das Speichern des Kinderprofils abgelehnt.');
    }
  }

  Future<bool> hasFinishedIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_introSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Explicit user-requested reset only. Never called by loadProfile().
  Future<void> resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(_profileKey)) {
      throw StateError('Das Kinderprofil konnte nicht geloescht werden.');
    }
    if (!await prefs.remove(_introSeenKey)) {
      throw StateError('Der Einrichtungsstatus konnte nicht geloescht werden.');
    }
  }
}
