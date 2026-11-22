import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/app_settings.dart';

/// Portable learning data only. Credentials and device permissions stay local.
class LocalBackupPolicy {
  static const maxArchiveBytes = 64 * 1024 * 1024;
  static const maxNativeBytes = 32 * 1024 * 1024;
  static const maxFileBytes = 8 * 1024 * 1024;
  static const maxPreferenceBytes = 16 * 1024 * 1024;
  static const maxFiles = 1024;
  static const maxPreferences = 20000;
  static const settingsKey = 'lumo_app_settings_v1';
  static const privateSettings = {
    'cloudVoiceEnabled', 'localVoiceLicenseAccepted', 'microphoneEnabled',
    'scannerEnabled', 'aiProxyEnabled', 'lanPlayEnabled', 'ghostDuelEnabled',
  };

  static bool allowsPreference(String key) {
    if (key.isEmpty || key.length > 1024 || key.contains('\u0000')) return false;
    final inScope = key.startsWith('lumo_') || key.startsWith('lumo.') ||
        key.startsWith('cross_grade_practice_v1:') ||
        key.startsWith('cross_grade_writing_v1:');
    final secret = RegExp(
      r'(^|[_.:])(api_?key|access_?token|refresh_?token|password|credential|secret|pin|premium|entitlement|permission|consent)([_.:]|$)',
      caseSensitive: false,
    ).hasMatch(key);
    return inScope && !secret;
  }

  static bool allowsNativePath(String path) {
    if (path.length > 220 || path.contains('..') || path.contains('\\') ||
        path.contains(RegExp(r'[\x00-\x1f]'))) return false;
    if (path.startsWith('kart_geister/')) {
      final name = path.substring('kart_geister/'.length);
      return name.isNotEmpty && !name.contains('/') &&
          (name.endsWith('.lumogeist') || name.endsWith('.json'));
    }
    if (const {'settings.cfg', 'progress.cfg', 'lumo_game_events.json',
      'lumo_host_pending_rewards.cfg', 'lumo_soundscape.cfg',
      'lumo_sternenjagd.cfg'}.contains(path)) return true;
    return RegExp(r'^(kart|run|skypost|jump)_[A-Za-z0-9_-]{1,180}\.cfg$')
            .hasMatch(path) ||
        RegExp(r'^lumo_(build|settlement|puzzle|rhythm|treasure|cards|chess|first_run)_[A-Za-z0-9_-]{1,160}\.(json|cfg)$')
            .hasMatch(path);
  }

  static Map<String, Object> portablePreferences(Map<String, Object> source) {
    final result = <String, Object>{};
    for (final key in source.keys.toList()..sort()) {
      if (!allowsPreference(key)) continue;
      var value = source[key]!;
      if (key == settingsKey) {
        if (value is! String) throw const FormatException('Einstellungen sind beschädigt.');
        final raw = jsonDecode(value);
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('Einstellungen sind beschädigt.');
        }
        final clean = AppSettings.fromJson(raw).toJson();
        for (final name in privateSettings) { clean[name] = false; }
        clean['aiProxyUrl'] = AppSettings.defaultAiProxyUrl;
        value = jsonEncode(clean);
      }
      _typed(value);
      result[key] = value;
    }
    return result;
  }

  static Map<String, Object> _typed(Object value) {
    final type = switch (value) {
      bool() => 'bool', int() => 'int', double() => 'double',
      String() => 'string', List<String>() => 'strings',
      _ => throw const FormatException('Unbekannter Speichertyp.'),
    };
    if (value is double && !value.isFinite) {
      throw const FormatException('Ungültige Zahl in der Sicherung.');
    }
    return {'type': type, 'value': value};
  }
}

class LocalBackupFile {
  LocalBackupFile(this.path, List<int> data) : bytes = Uint8List.fromList(data);
  final String path;
  final Uint8List bytes;
}

class LocalBackup {
  LocalBackup._(this.createdAt, this.preferences, this.nativeFiles, this.bytes,
      this.digest);
  final DateTime createdAt;
  final Map<String, Object> preferences;
  final List<LocalBackupFile> nativeFiles;
  final Uint8List bytes;
  final String digest;

  List<String> get profileNames {
    final names = <String>{};
    void add(Object? name) {
      if (name is String && name.trim().isNotEmpty && name.length <= 200) {
        names.add(name);
      }
    }
    try {
      final raw = preferences['lumo_active_profile'];
      if (raw is String) add((jsonDecode(raw) as Map)['name']);
      final directory = preferences['lumo_school_v1'];
      if (directory is String) {
        final students = (jsonDecode(directory) as Map)['students'];
        if (students is List) {
          for (final student in students) {
            if (student is Map) add(student['name']);
          }
        }
      }
    } catch (_) { /* Counts remain available for older profile schemas. */ }
    return names.toList(growable: false);
  }

  static LocalBackup create({
    required Map<String, Object> preferences,
    required List<LocalBackupFile> nativeFiles,
    DateTime? now,
  }) {
    final portable = LocalBackupPolicy.portablePreferences(preferences);
    final payload = jsonEncode({
      'preferences': {
        for (final entry in portable.entries)
          entry.key: LocalBackupPolicy._typed(entry.value),
      },
      'nativeFiles': [
        for (final file in nativeFiles)
          {'path': file.path, 'bytes': file.bytes.length,
            'sha256': sha256.convert(file.bytes).toString(),
            'data': base64Encode(file.bytes)},
      ],
    });
    return parse(utf8.encode(jsonEncode({
      'format': 'lumo-local-backup', 'version': 1,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'payload': payload, 'sha256': sha256.convert(utf8.encode(payload)).toString(),
    })));
  }

  static LocalBackup parse(List<int> data) {
    void fail(String message) => throw FormatException(message);
    if (data.isEmpty || data.length > LocalBackupPolicy.maxArchiveBytes) {
      fail('Die Sicherung ist leer oder größer als 64 MB.');
    }
    final root = jsonDecode(utf8.decode(data));
    if (root is! Map<String, dynamic> || root.length != 5 ||
        root['format'] != 'lumo-local-backup' || root['version'] != 1 ||
        root['payload'] is! String || root['sha256'] is! String ||
        root['createdAt'] is! String) {
      fail('Dies ist keine unterstützte Lumo-Sicherung (Version 1). '
          'Die älteren HTML-Exporte sind ein anderes Format.');
    }
    final envelope = root as Map<String, dynamic>;
    final date = DateTime.tryParse(envelope['createdAt'] as String);
    if (date == null || !date.isUtc || date.year < 2000 || date.year > 2200) {
      fail('Das Sicherungsdatum ist ungültig.');
    }
    final payload = envelope['payload'] as String;
    final hash = sha256.convert(utf8.encode(payload)).toString();
    if (hash != envelope['sha256']) fail('Die Prüfsumme stimmt nicht überein.');
    final decoded = jsonDecode(payload);
    // Our version writes one canonical payload. This also rejects duplicate
    // object keys instead of allowing different parsers to pick different data.
    if (decoded is! Map<String, dynamic> || decoded.length != 2 ||
        decoded['preferences'] is! Map<String, dynamic> ||
        decoded['nativeFiles'] is! List || jsonEncode(decoded) != payload) {
      fail('Die Datenstruktur der Sicherung ist ungültig.');
    }
    final body = decoded as Map<String, dynamic>;
    final rawPrefs = body['preferences'] as Map<String, dynamic>;
    if (rawPrefs.length > LocalBackupPolicy.maxPreferences ||
        utf8.encode(jsonEncode(rawPrefs)).length > LocalBackupPolicy.maxPreferenceBytes) {
      fail('Die Lerndaten überschreiten die Sicherungsgrenze.');
    }
    final prefs = <String, Object>{};
    for (final entry in rawPrefs.entries) {
      final row = entry.value;
      if (!LocalBackupPolicy.allowsPreference(entry.key) || row is! Map ||
          row.length != 2 || !row.containsKey('type') || !row.containsKey('value')) {
        fail('Die Sicherung enthält einen nicht erlaubten Speichereintrag.');
      }
      final value = (row as Map)['value'];
      final valid = switch (row['type']) {
        'bool' => value is bool,
        'int' => value is int,
        'double' => value is num && value.isFinite,
        'string' => value is String,
        'strings' => value is List && value.every((v) => v is String),
        _ => false,
      };
      if (!valid) fail('Ein Speichereintrag hat den falschen Datentyp.');
      prefs[entry.key] = row['type'] == 'strings'
          ? List<String>.from(value as List)
          : row['type'] == 'double' ? (value as num).toDouble() : value as Object;
    }
    if (prefs.containsKey(LocalBackupPolicy.settingsKey)) {
      final sanitized = LocalBackupPolicy.portablePreferences(prefs);
      if (sanitized[LocalBackupPolicy.settingsKey] != prefs[LocalBackupPolicy.settingsKey]) {
        fail('Gerätefreigaben und Zugangsdaten dürfen nicht importiert werden.');
      }
    }
    final registry = prefs['lumo_3d_profile_keys_v1'];
    if (registry != null &&
        (prefs['lumo_3d_save_salt_v1'] is! String ||
         (prefs['lumo_3d_save_salt_v1'] as String).isEmpty)) {
      fail('Die Zuordnung der nativen Spielstände ist unvollständig.');
    }
    final paths = <String>{};
    final files = <LocalBackupFile>[];
    var total = 0;
    final rawFiles = body['nativeFiles'] as List;
    if (rawFiles.length > LocalBackupPolicy.maxFiles) fail('Zu viele Spielstandsdateien.');
    for (final row in rawFiles) {
      if (row is! Map || row.length != 4 || row['path'] is! String ||
          row['bytes'] is! int || row['sha256'] is! String || row['data'] is! String ||
          !LocalBackupPolicy.allowsNativePath(row['path'] as String) ||
          !paths.add(row['path'] as String) ||
          (row['bytes'] as int) < 0 ||
          (row['bytes'] as int) > LocalBackupPolicy.maxFileBytes ||
          (row['data'] as String).length > (LocalBackupPolicy.maxFileBytes + 2) ~/ 3 * 4) {
        fail('Ein Spielstandspfad, eine Dateigröße oder ein Eintrag ist ungültig.');
      }
      final bytes = base64Decode(row['data'] as String);
      total += bytes.length;
      if (bytes.length != row['bytes'] || sha256.convert(bytes).toString() != row['sha256'] ||
          total > LocalBackupPolicy.maxNativeBytes) {
        fail('Ein Spielstand ist beschädigt oder die Sicherung ist zu groß.');
      }
      files.add(LocalBackupFile(row['path'] as String, bytes));
    }
    return LocalBackup._(date!, Map.unmodifiable(prefs), List.unmodifiable(files),
        Uint8List.fromList(data), hash);
  }
}
