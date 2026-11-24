import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/local_backup_repository.dart';
import '../../domain/backup/local_backup.dart';

/// Parent settings entry. Existing learning/journal editors remain unchanged.
class LocalBackupCard extends StatefulWidget {
  const LocalBackupCard(
      {super.key,
      required this.app,
      this.repository = const LocalBackupRepository(),
      this.available});
  final LumoAppState app;
  final LocalBackupRepository repository;
  final bool? available;

  @override
  State<LocalBackupCard> createState() => _LocalBackupCardState();
}

class _LocalBackupCardState extends State<LocalBackupCard> {
  bool _busy = false;
  bool _reviewing = false;
  bool _previous = false;
  String? _message;
  bool get _available =>
      widget.available ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    _readStatus();
  }

  Future<void> _readStatus() async {
    if (!_available) return;
    try {
      final status = await widget.repository.status();
      if (!mounted) return;
      setState(() {
        _previous = status['previousAvailable'] == true;
        _message = switch (status['result']) {
          'restored' => 'Die Sicherung wurde beim App-Start wiederhergestellt.',
          'rolled_back' => 'Die Wiederherstellung wurde unterbrochen. '
              'Dein vorheriger Stand wurde vollständig zurückgesichert.',
          'invalid' =>
            'Die vorgemerkte Datei war ungültig. Deine bisherigen Daten wurden behalten.',
          _ => null,
        };
      });
    } catch (_) {
      if (mounted) {
        setState(
            () => _message = 'Die Datensicherung ist gerade nicht erreichbar.');
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _message = error.message.startsWith('Unexpected')
            ? 'Die Datei ist keine gültige Lumo-Sicherung.'
            : error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _message = 'Die Sicherung konnte nicht abgeschlossen werden. '
                'Schließe offene Spiele und versuche es erneut. Deine bisherigen Daten bleiben erhalten.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
        final written = await widget.repository.saveBackup(widget.app);
        if (mounted) {
          setState(() => _message = written
              ? 'Die Sicherungsdatei wurde am gewählten Speicherort gespeichert.'
              : 'Speichern abgebrochen. Deine Daten wurden nicht geändert.');
        }
      });

  Future<void> _import() => _run(() async {
        final backup = await widget.repository.choose();
        if (!mounted) return;
        if (backup == null) {
          setState(() => _message =
              'Dateiauswahl abgebrochen. Deine Daten wurden nicht geändert.');
          return;
        }
        if (!await _confirm(backup)) return;
        await widget.repository.restore(widget.app, backup);
        if (mounted) {
          setState(() => _message = 'Bitte öffne Lumo erneut. '
              'Die vorgemerkte Sicherung wird vor dem Lernen wiederhergestellt.');
        }
      });

  Future<void> _undo() => _run(() async {
        if (!await _confirm(null)) return;
        await widget.repository.restorePrevious(widget.app);
        if (mounted) {
          setState(() => _message =
              'Bitte öffne Lumo erneut, um den vorherigen Stand zu laden.');
        }
      });

  Future<bool> _confirm(LocalBackup? backup) async {
    var accepted = false;
    final date = backup?.createdAt.toLocal();
    final names = backup?.profileNames ?? const <String>[];
    setState(() => _reviewing = true);
    try {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                      title: Text(backup == null
                          ? 'Vorherigen Stand wiederherstellen?'
                          : 'Geprüfte Sicherung wiederherstellen?'),
                      content: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            if (date != null)
                              Text(
                                  'Sicherung vom ${date.day}.${date.month}.${date.year} '
                                  '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'),
                            if (names.isNotEmpty)
                              Text('Profile: ${names.join(', ')}'),
                            if (backup != null)
                              Text(
                                  '${backup.preferences.length} Lerndaten-Einträge und '
                                  '${backup.nativeFiles.length} native Spielstandsdateien.'),
                            const SizedBox(height: 12),
                            const Text(
                                'Alle bisherigen Lern-, Profil-, Journal- und Spielstände dieses Geräts '
                                'werden durch diesen Stand ersetzt. Lumo sichert vorher den aktuellen Stand lokal.'),
                            const SizedBox(height: 8),
                            const Text(
                                'Lumo schließt nach der Bestätigung. Öffne die App anschließend erneut. '
                                'Erst beim Start werden die Daten sicher übernommen. '
                                'Mikrofon-, Kamera-, Netzwerk- und Modellfreigaben werden aus einer Datei nicht übernommen.'),
                            CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                    'Als erwachsene Person möchte ich diesen Stand wiederherstellen.'),
                                value: accepted,
                                onChanged: (value) => setDialogState(
                                    () => accepted = value == true)),
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Abbrechen')),
                        FilledButton(
                            key: const ValueKey('backup-confirm-restore'),
                            onPressed: accepted
                                ? () => Navigator.pop(context, true)
                                : null,
                            child:
                                const Text('Wiederherstellen und schließen')),
                      ],
                    )),
          ) ??
          false;
    } finally {
      if (mounted) {
        setState(() => _reviewing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        key: const ValueKey('local-backup-card'),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daten sichern und wiederherstellen',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                    'Lernstände, Kinderprofile, Journal, Sterne, eigene Aufgaben und Gutscheine '
                    'sowie gespeicherte 3D-Spiele in einer Datei sichern.'),
                const SizedBox(height: 8),
                const Text(
                    'Die Datei enthält persönliche Daten und ist nicht verschlüsselt. '
                    'Wähle einen sicheren Speicherort. Zugangsdaten und Gerätefreigaben werden ausgelassen.'),
                if (!_available)
                  const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                          'Die Dateisicherung steht in der Android-App zur Verfügung.')),
                if (_busy && !_reviewing)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator()),
                if (_message != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_message!,
                          key: const ValueKey('backup-status'))),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(
                      key: const ValueKey('backup-export'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: _available && !_busy ? _export : null,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Sicherungsdatei speichern')),
                  OutlinedButton.icon(
                      key: const ValueKey('backup-import'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: _available && !_busy ? _import : null,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Sicherung auswählen und prüfen')),
                  if (_previous)
                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48)),
                        onPressed: !_busy ? _undo : null,
                        child: const Text('Vorherigen Stand zurückholen')),
                ]),
              ],
            )),
      );
}
