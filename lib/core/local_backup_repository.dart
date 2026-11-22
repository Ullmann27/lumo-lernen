
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app_state.dart';
import '../domain/backup/local_backup.dart';

class LocalBackupRepository {
  const LocalBackupRepository();
  static const channel = MethodChannel('lumo_lernen/local_backup');

  Future<Map<String, dynamic>> status() async => Map<String, dynamic>.from(
      await channel.invokeMapMethod<String, dynamic>('status') ?? const {});

  Future<bool> saveBackup(LumoAppState app) async {
    final archive = await app.withBackupStoragePaused(() async {
      final native = await channel.invokeListMethod<dynamic>('snapshotNative');
      if (native == null) {
        throw StateError('Spielstände konnten nicht gelesen werden.');
      }
      final prefs = await SharedPreferences.getInstance();
      // Event acknowledgements follow durable wallet writes. Reading events
      // first, then the fresh wallet, preserves every pending reward or its ID.
      await prefs.reload();
      final values = <String, Object>{
        for (final key in prefs.getKeys())
          if (prefs.get(key) != null) key: prefs.get(key)!,
      };
      return LocalBackup.create(preferences: values, nativeFiles: [
        for (final row in native)
          LocalBackupFile(row['path'] as String, row['data'] as Uint8List),
      ]);
    });
    return await channel.invokeMethod<bool>('saveBackup', archive.bytes) ??
        false;
  }

  Future<LocalBackup?> choose() async {
    final bytes = await channel.invokeMethod<Uint8List>('pickBackup');
    return bytes == null ? null : LocalBackup.parse(bytes);
  }

  Future<void> restore(LumoAppState app, LocalBackup archive) async {
    // Revalidate the exact reviewed bytes immediately before staging them.
    final checked = LocalBackup.parse(archive.bytes);
    await app.withBackupStoragePaused(() async {
      if (await channel.invokeMethod<bool>('stageRestore', checked.bytes) !=
          true) {
        throw StateError('Die Wiederherstellung wurde nicht vorgemerkt.');
      }
    });
    await channel.invokeMethod<void>('closeForRestore');
  }

  Future<void> restorePrevious(LumoAppState app) async {
    await app.withBackupStoragePaused(() async {
      if (await channel.invokeMethod<bool>('stagePrevious') != true) {
        throw StateError('Die vorherige Sicherung ist nicht verfügbar.');
      }
    });
    await channel.invokeMethod<void>('closeForRestore');
  }
}
