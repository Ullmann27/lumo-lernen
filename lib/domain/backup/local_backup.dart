import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/app_settings.dart';
import '../../core/reward_wallet_repository.dart';
import '../logic/logic_learning_profile.dart';

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
    'cloudVoiceEnabled',
    'localVoiceLicenseAccepted',
    'microphoneEnabled',
    'scannerEnabled',
    'aiProxyEnabled',
    'lanPlayEnabled',
    'ghostDuelEnabled',
    'kartOnlineEnabled',
  };

  static bool allowsPreference(String key) {
    if (key.isEmpty || key.length > 1024 || key.contains('\u0000')) {
      return false;
    }
    final inScope = key.startsWith('lumo_') ||
        key.startsWith('lumo.') ||
        key.startsWith('cross_grade_practice_v1:') ||
        key.startsWith('cross_grade_writing_v1:');
    final secret = RegExp(
      r'(^|[_.:])(api_?key|access_?token|refresh_?token|token|password|credential|secret|pin|premium|entitlement|permission|consent|license|auth|device_id|installation_id)([_.:]|$)',
      caseSensitive: false,
    ).hasMatch(key);
    return inScope && !secret;
  }

  static bool allowsNativePath(String path) {
    if (path.length > 220 ||
        path.contains('..') ||
        path.contains('\\') ||
        path.contains(RegExp(r'[\x00-\x1f]'))) {
      return false;
    }
    if (path.startsWith('kart_geister/')) {
      final name = path.substring('kart_geister/'.length);
      return name.isNotEmpty &&
          !name.contains('/') &&
          (name.endsWith('.lumogeist') || name.endsWith('.json'));
    }
    if (const {
      'settings.cfg',
      'progress.cfg',
      'lumo_game_events.json',
      'lumo_host_pending_rewards.cfg',
      'lumo_soundscape.cfg',
      'lumo_sternenjagd.cfg'
    }.contains(path)) {
      return true;
    }
    return RegExp(r'^(kart|run|skypost|jump)_[A-Za-z0-9_-]{1,180}\.cfg$')
            .hasMatch(path) ||
        RegExp(r'^lumo_(build|settlement|puzzle|rhythm|treasure|cards|chess|first_run|world)_[A-Za-z0-9_-]{1,160}\.(json|cfg)$')
            .hasMatch(path);
  }

  static Map<String, Object> portablePreferences(Map<String, Object> source) {
    final result = <String, Object>{};
    for (final key in source.keys.toList()..sort()) {
      if (!allowsPreference(key)) continue;
      var value = source[key]!;
      if (key == settingsKey) {
        if (value is! String) {
          throw const FormatException('Einstellungen sind beschädigt.');
        }
        final raw = jsonDecode(value);
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('Einstellungen sind beschädigt.');
        }
        final clean = AppSettings.fromJson(raw).toJson();
        for (final name in privateSettings) {
          clean[name] = false;
        }
        clean['aiProxyUrl'] = AppSettings.defaultAiProxyUrl;
        clean['kartOnlineUrl'] = '';
        value = jsonEncode(clean);
      }
      _typed(value);
      result[key] = value;
    }
    return result;
  }

  static Map<String, Object> _typed(Object value) {
    final type = switch (value) {
      bool() => 'bool',
      int() => 'int',
      double() => 'double',
      String() => 'string',
      List<String>() => 'strings',
      _ => throw const FormatException('Unbekannter Speichertyp.'),
    };
    if (value is double && !value.isFinite) {
      throw const FormatException('Ungültige Zahl in der Sicherung.');
    }
    return {'type': type, 'value': value};
  }

  static dynamic decodeJson(String source) {
    var depth = 0;
    var quoted = false;
    var escaped = false;
    for (final unit in source.codeUnits) {
      if (quoted) {
        if (escaped) {
          escaped = false;
        } else if (unit == 92) {
          escaped = true;
        } else if (unit == 34) {
          quoted = false;
        }
      } else if (unit == 34) {
        quoted = true;
      } else if (unit == 123 || unit == 91) {
        if (++depth > 64) {
          throw const FormatException(
              'Die Sicherung ist zu tief verschachtelt.');
        }
      } else if (unit == 125 || unit == 93) {
        depth--;
      }
    }
    return jsonDecode(source);
  }

  static void validateLearningData(Map<String, Object> prefs) {
    dynamic document(String key) {
      final value = prefs[key];
      if (value is! String) {
        throw const FormatException('Ein Lerndatensatz ist beschädigt.');
      }
      return decodeJson(value);
    }

    for (final value in prefs.values) {
      if (value is String) {
        if (value.startsWith('VGhpcyBpcyB0aGUgcHJlZml4IGZvci')) {
          throw const FormatException(
              'Ein Text verwendet einen reservierten Speichertyp.');
        }
        final trimmed = value.trimLeft();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          decodeJson(value);
        }
      }
    }
    for (final key in prefs.keys) {
      if (!key.startsWith(LogicProgress.preferencePrefix)) continue;
      final progress = LogicProgress.fromJson(document(key));
      if (key != LogicProgress.preferencePrefix +
          Uri.encodeComponent(progress.profileId)) {
        throw const FormatException(
            'Ein Logik-Spielstand ist dem falschen Kinderprofil zugeordnet.');
      }
    }
    if (prefs.containsKey('lumo_active_profile')) {
      final value = document('lumo_active_profile');
      if (value is! Map ||
          value['id'] is! String ||
          (value['id'] as String).isEmpty ||
          value['name'] is! String ||
          value['age'] is! int ||
          value['grade'] is! int ||
          value['grade'] < 1 ||
          value['grade'] > 4 ||
          value['createdAt'] is! String ||
          value['lastActiveAt'] is! String ||
          DateTime.tryParse(value['createdAt']) == null ||
          DateTime.tryParse(value['lastActiveAt']) == null) {
        throw const FormatException(
            'Das Kinderprofil in der Sicherung ist beschädigt.');
      }
    }
    if (prefs.containsKey('lumo_reward_wallet_v1')) {
      final value = document('lumo_reward_wallet_v1');
      if (value is! Map<String, dynamic> ||
          value['stars'] is! int ||
          value['xp'] is! int ||
          value['stars'] < 0 ||
          value['xp'] < 0 ||
          (value['gameResultIds'] != null &&
              (value['gameResultIds'] is! List ||
                  !(value['gameResultIds'] as List)
                      .every((v) => v is String)))) {
        throw const FormatException(
            'Die gespeicherten Sterne oder Ergebnis-IDs sind beschädigt.');
      }
      RewardWallet.fromJson(value);
    }
    if (prefs.containsKey('lumo_journal_entries')) {
      final value = document('lumo_journal_entries');
      if (value is! List ||
          value.any((entry) =>
              entry is! Map ||
              entry['id'] is! String ||
              entry['text'] is! String ||
              entry['createdAt'] is! int)) {
        throw const FormatException(
            'Das Journal in der Sicherung ist beschädigt.');
      }
    }
    if (prefs.containsKey('lumo_school_v1')) {
      final value = document('lumo_school_v1');
      if (value is! Map ||
          value['students'] is! List ||
          value['classes'] is! List) {
        throw const FormatException(
            'Das Schulverzeichnis in der Sicherung ist beschädigt.');
      }
      final ids = <String>{};
      for (final student in value['students'] as List) {
        if (student is! Map ||
            student['id'] is! String ||
            (student['id'] as String).isEmpty ||
            !ids.add(student['id'] as String) ||
            student['cls'] is! String) {
          throw const FormatException(
              'Die Kinderzuordnung im Schulverzeichnis ist beschädigt.');
        }
      }
      final active = prefs['lumo_school_active_student_v1'];
      if (active != null && (active is! String || !ids.contains(active))) {
        throw const FormatException(
            'Das aktive Schulkind fehlt im Schulverzeichnis.');
      }
    }
    if (prefs.containsKey('lumo_3d_profile_keys_v1')) {
      final value = document('lumo_3d_profile_keys_v1');
      final salt = prefs['lumo_3d_save_salt_v1'];
      if (salt is! String ||
          salt.isEmpty ||
          value is! Map ||
          value['version'] != 1 ||
          value['legacyAvailable'] is! bool ||
          value['owners'] is! Map ||
          value['legacy'] is! Map) {
        throw const FormatException(
            'Die Zuordnung der nativen Spielstände ist unvollständig.');
      }
      final owners = value['owners'] as Map;
      final keys = <String>{};
      final pattern = RegExp(r'^p_[a-f0-9]{32}$');
      for (final entry in owners.entries) {
        if (entry.key is! String ||
            (entry.key as String).isEmpty ||
            entry.value is! String ||
            !pattern.hasMatch(entry.value as String) ||
            !keys.add(entry.value as String)) {
          throw const FormatException(
              'Ein nativer Spielstand ist mehreren oder ungültigen Profilen zugeordnet.');
        }
      }
      for (final entry in (value['legacy'] as Map).entries) {
        final row = entry.value;
        if (entry.key is! String ||
            !pattern.hasMatch(entry.key as String) ||
            !keys.add(entry.key as String) ||
            row is! Map ||
            !owners.containsKey(row['owner']) ||
            row['name'] is! String ||
            row['grade'] is! int ||
            row['grade'] < 1 ||
            row['grade'] > 4) {
          throw const FormatException(
              'Die Zuordnung älterer Spielstände ist beschädigt.');
        }
      }
    }
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
    } catch (_) {/* Counts remain available for older profile schemas. */}
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
          {
            'path': file.path,
            'bytes': file.bytes.length,
            'sha256': sha256.convert(file.bytes).toString(),
            'data': base64Encode(file.bytes)
          },
      ],
    });
    return parse(utf8.encode(jsonEncode({
      'format': 'lumo-local-backup',
      'version': 1,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'payload': payload,
      'sha256': sha256.convert(utf8.encode(payload)).toString(),
    })));
  }

  static LocalBackup parse(List<int> data) {
    void fail(String message) => throw FormatException(message);
    if (data.isEmpty || data.length > LocalBackupPolicy.maxArchiveBytes) {
      fail('Die Sicherung ist leer oder größer als 64 MB.');
    }
    final root = LocalBackupPolicy.decodeJson(utf8.decode(data));
    if (root is! Map<String, dynamic> ||
        root.length != 5 ||
        root['format'] != 'lumo-local-backup' ||
        root['version'] != 1 ||
        root['payload'] is! String ||
        root['sha256'] is! String ||
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
    final decoded = LocalBackupPolicy.decodeJson(payload);
    // Our version writes one canonical payload. This also rejects duplicate
    // object keys instead of allowing different parsers to pick different data.
    if (decoded is! Map<String, dynamic> ||
        decoded.length != 2 ||
        decoded['preferences'] is! Map<String, dynamic> ||
        decoded['nativeFiles'] is! List ||
        jsonEncode(decoded) != payload) {
      fail('Die Datenstruktur der Sicherung ist ungültig.');
    }
    final body = decoded as Map<String, dynamic>;
    final rawPrefs = body['preferences'] as Map<String, dynamic>;
    if (rawPrefs.length > LocalBackupPolicy.maxPreferences ||
        utf8.encode(jsonEncode(rawPrefs)).length >
            LocalBackupPolicy.maxPreferenceBytes) {
      fail('Die Lerndaten überschreiten die Sicherungsgrenze.');
    }
    final prefs = <String, Object>{};
    for (final entry in rawPrefs.entries) {
      final row = entry.value;
      if (!LocalBackupPolicy.allowsPreference(entry.key) ||
          row is! Map ||
          row.length != 2 ||
          !row.containsKey('type') ||
          !row.containsKey('value')) {
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
          : row['type'] == 'double'
              ? (value as num).toDouble()
              : value as Object;
    }
    if (prefs.containsKey(LocalBackupPolicy.settingsKey)) {
      final sanitized = LocalBackupPolicy.portablePreferences(prefs);
      if (sanitized[LocalBackupPolicy.settingsKey] !=
          prefs[LocalBackupPolicy.settingsKey]) {
        fail(
            'Gerätefreigaben und Zugangsdaten dürfen nicht importiert werden.');
      }
    }
    LocalBackupPolicy.validateLearningData(prefs);
    final paths = <String>{};
    final files = <LocalBackupFile>[];
    var total = 0;
    final rawFiles = body['nativeFiles'] as List;
    if (rawFiles.length > LocalBackupPolicy.maxFiles) {
      fail('Zu viele Spielstandsdateien.');
    }
    for (final row in rawFiles) {
      if (row is! Map ||
          row.length != 4 ||
          row['path'] is! String ||
          row['bytes'] is! int ||
          row['sha256'] is! String ||
          row['data'] is! String ||
          !LocalBackupPolicy.allowsNativePath(row['path'] as String) ||
          !paths.add(row['path'] as String) ||
          (row['bytes'] as int) < 0 ||
          (row['bytes'] as int) > LocalBackupPolicy.maxFileBytes ||
          (row['data'] as String).length >
              (LocalBackupPolicy.maxFileBytes + 2) ~/ 3 * 4) {
        fail(
            'Ein Spielstandspfad, eine Dateigröße oder ein Eintrag ist ungültig.');
      }
      final bytes = base64Decode(row['data'] as String);
      total += bytes.length;
      if (bytes.length != row['bytes'] ||
          sha256.convert(bytes).toString() != row['sha256'] ||
          total > LocalBackupPolicy.maxNativeBytes) {
        fail('Ein Spielstand ist beschädigt oder die Sicherung ist zu groß.');
      }
      final content = utf8.decode(bytes);
      if (content.contains('\u0000')) {
        fail('Ein Spielstand enthält ungültige Daten.');
      }
      if (!(row['path'] as String).endsWith('.cfg')) {
        final gameData = LocalBackupPolicy.decodeJson(content);
        if (gameData is! Map) {
          fail('Ein Spielstand hat eine ungültige Datenstruktur.');
        }
      }
      files.add(LocalBackupFile(row['path'] as String, bytes));
    }
    return LocalBackup._(date!, Map.unmodifiable(prefs),
        List.unmodifiable(files), Uint8List.fromList(data), hash);
  }
}
