import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/design/lumo_night_scope.dart';

/// Ein Eintrag der letzten Spielstarts aus `MainActivity.gameStartLog`.
class NativeGameStart {
  const NativeGameStart({
    required this.scene,
    required this.startedAt,
    required this.outcome,
    this.endedAt,
    this.loadedAfterMs,
    this.loadedScene,
    this.detail,
    this.note,
  });

  final String scene;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String outcome;
  final int? loadedAfterMs;
  final String? loadedScene;
  final String? detail;
  final String? note;

  static NativeGameStart? fromJson(Object? value) {
    if (value is! Map) return null;
    final scene = value['scene'];
    final started = value['startedAt'];
    final outcome = value['outcome'];
    if (scene is! String || started is! int || outcome is! String) return null;
    final ended = value['endedAt'];
    final loaded = value['loadedAfterMs'];
    String? text(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;
    return NativeGameStart(
      scene: scene,
      startedAt: DateTime.fromMillisecondsSinceEpoch(started),
      endedAt: ended is int ? DateTime.fromMillisecondsSinceEpoch(ended) : null,
      outcome: outcome,
      loadedAfterMs: loaded is int ? loaded : null,
      loadedScene: text(value['loadedScene']),
      detail: text(value['detail']),
      note: text(value['note']),
    );
  }

  static String _seconds(int milliseconds) =>
      (milliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',');

  /// Ergebnis in einem Satz, so wie es der Elternteil vorlesen kann.
  String get sentence {
    final loaded = loadedAfterMs;
    final loadedText = loaded == null
        ? null
        : 'geladen nach ${_seconds(loaded)} s'
            '${loadedScene != null && loadedScene != scene ? ' ($loadedScene)' : ''}';
    final base = switch (outcome) {
      'running' => loadedText == null
          ? 'Gestartet, noch keine Rückkehr gemeldet.'
          : 'Gestartet und $loadedText, noch keine Rückkehr gemeldet.',
      'returned' => loadedText == null
          ? 'Normal zurückgekehrt, kein „geladen“ im Protokoll gefunden.'
          : 'Ohne Fehler $loadedText und normal zurückgekehrt.',
      'process_ended' => loadedText == null
          ? 'Fehler: Das Spiel wurde beendet, bevor es fertig geladen war '
              '(Prozess beendet, keine Rückmeldung).'
          : 'Fehler: $loadedText, danach ohne Rückmeldung beendet (Prozess beendet).',
      'closed' => loadedText == null
          ? 'Ohne Rückmeldung geschlossen, bevor es fertig geladen war '
              '(z. B. Zurück-Taste).'
          : 'Ohne Fehler $loadedText, dann ohne Rückmeldung geschlossen '
              '(z. B. Zurück-Taste).',
      'game_running' =>
        'Nicht gestartet: Ein anderes Spiel war noch geöffnet (game_running).',
      'exception' => 'Nicht gestartet: Ausnahme beim Start'
          '${detail == null ? '' : ' ($detail)'}.',
      'refused' => 'Nicht gestartet: Startdaten abgelehnt'
          '${detail == null ? '' : ' ($detail)'}.',
      'host_closed' =>
        'Unbekannt: Die App wurde geschlossen, während das Spiel lief.',
      _ => 'Ergebnis: $outcome.',
    };
    return note == null ? base : '$base $note';
  }

  bool get failed => const {
        'process_ended',
        'game_running',
        'exception',
        'refused',
      }.contains(outcome);
}

/// Antwort von `gameStartLog`: Gerätedaten, letzte Starts, gefiltertes Log.
class NativeGameStartReport {
  const NativeGameStartReport(
      {required this.device, required this.starts, required this.log});

  final Map<String, String> device;
  final List<NativeGameStart> starts;
  final String log;

  static NativeGameStartReport fromPlatform(Object? raw) {
    final map = raw is Map ? raw : const {};
    final device = <String, String>{};
    final rawDevice = map['device'];
    if (rawDevice is Map) {
      for (final entry in rawDevice.entries) {
        device['${entry.key}'] = '${entry.value}';
      }
    }
    var starts = <NativeGameStart>[];
    final rawStarts = map['starts'];
    if (rawStarts is String) {
      try {
        final decoded = jsonDecode(rawStarts);
        if (decoded is List) {
          starts = decoded
              .map(NativeGameStart.fromJson)
              .whereType<NativeGameStart>()
              .toList()
              .reversed
              .toList();
        }
      } on FormatException {
        starts = const [];
      }
    }
    final log = map['log'];
    return NativeGameStartReport(
        device: device, starts: starts, log: log is String ? log : '');
  }

  static String _time(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}. '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  static String startLine(NativeGameStart start) =>
      '${_time(start.startedAt)}  ${start.scene}: ${start.sentence}';

  /// Alles in einem Text, damit es kopiert oder fotografiert werden kann.
  String get copyText {
    final buffer = StringBuffer('LUMO Spiel-Startprotokoll\n');
    for (final entry in device.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    buffer.writeln('\nLetzte Spielstarts (neueste zuerst):');
    if (starts.isEmpty) buffer.writeln('– noch keine –');
    for (final start in starts) {
      buffer.writeln(startLine(start));
    }
    buffer.writeln('\nProtokoll (godot, LumoHost, Absturzmeldungen):');
    buffer.write(log.isEmpty ? '– leer –' : log);
    return buffer.toString();
  }
}

/// Elternbereich: die letzten Spielstarts und das eigene, gefilterte Log.
/// Nur Anzeige am Gerät; nichts wird gesendet.
class NativeGameStartLogScreen extends StatefulWidget {
  const NativeGameStartLogScreen({super.key});

  static const channel = MethodChannel('lumo_lernen/diagnostics');

  @override
  State<NativeGameStartLogScreen> createState() =>
      _NativeGameStartLogScreenState();
}

class _NativeGameStartLogScreenState extends State<NativeGameStartLogScreen> {
  NativeGameStartReport? _report;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final raw = await NativeGameStartLogScreen.channel
          .invokeMethod<Object?>('gameStartLog');
      if (!mounted) return;
      setState(() => _report = NativeGameStartReport.fromPlatform(raw));
    } on MissingPluginException {
      if (mounted) {
        setState(() => _error =
            'Das Startprotokoll gibt es nur in der Android-App mit 3D-Spielen.');
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Das Startprotokoll konnte nicht gelesen werden. '
                'Bitte versuche es erneut.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final report = _report;
    if (report == null) return;
    await Clipboard.setData(ClipboardData(text: report.copyText));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Startprotokoll kopiert.')));
  }

  @override
  Widget build(BuildContext context) => LumoNightScope(
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final report = _report;
            return RepaintBoundary(
              key: const ValueKey('game-start-log-boundary'),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Spiel-Startprotokoll'),
                  actions: [
                    IconButton(
                      key: const ValueKey('game-start-log-refresh'),
                      tooltip: 'Neu laden',
                      onPressed: _busy ? null : _load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: ListView(
                    key: const ValueKey('game-start-log-list'),
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                          'Hier steht, wie die letzten 3D-Spiele gestartet sind. '
                          'Das Protokoll bleibt auf diesem Gerät und wird nicht '
                          'gesendet. Bei einem Fehler: „Kopieren“ tippen oder die '
                          'Seite fotografieren.'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('game-start-log-copy'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48)),
                        onPressed: report == null ? null : _copy,
                        icon: const Icon(Icons.copy),
                        label: const Text('Kopieren'),
                      ),
                      if (_busy)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator()),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_error!,
                              key: const ValueKey('game-start-log-error')),
                        ),
                      if (report != null) ...[
                        const SizedBox(height: 20),
                        Text('Letzte Spielstarts',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (report.starts.isEmpty)
                          const Text('Noch keine Spielstarts aufgezeichnet.'),
                        for (final start in report.starts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  start.failed
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  color: start.failed
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                      NativeGameStartReport.startLine(start)),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text('Gerät', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final entry in report.device.entries)
                          Text('${entry.key}: ${entry.value}'),
                        const SizedBox(height: 20),
                        Text('Protokoll', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Container(
                          key: const ValueKey('game-start-log-text'),
                          constraints: const BoxConstraints(maxHeight: 480),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              report.log.isEmpty
                                  ? 'Keine passenden Logzeilen gefunden.'
                                  : report.log,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  height: 1.35),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}
