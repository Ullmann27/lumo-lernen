import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/lumo_speech_readiness.dart';
import '../../core/lumo_voice.dart';

class LumoVoiceDiagnosticsCard extends StatefulWidget {
  const LumoVoiceDiagnosticsCard({super.key, required this.serverUrl});
  final String serverUrl;

  @override
  State<LumoVoiceDiagnosticsCard> createState() => _DiagnosticsState();
}

class _DiagnosticsState extends State<LumoVoiceDiagnosticsCard> {
  bool _checking = false;
  String? _identity;
  String? _server;

  Future<void> _check() async {
    setState(() => _checking = true);
    String identity;
    try {
      final data = await const MethodChannel('lumo_lernen/diagnostics')
          .invokeMapMethod<String, dynamic>('runtimeIdentity');
      identity = data == null
          ? 'App-Identität nicht verfügbar.'
          : 'Installiert: ${data['versionName']} / Build ${data['versionCode']}\n'
              'Paket: ${data['package']}\nAndroid-API: ${data['androidApi']}\n'
              'Signatur SHA-256: ${data['certificateSha256'] ?? 'nicht verfügbar'}';
    } catch (_) {
      identity = 'App-Identität ist außerhalb der Android-App nicht verfügbar.';
    }
    final readiness = await LumoSpeechReadiness.check(widget.serverUrl);
    if (!mounted) return;
    setState(() {
      _identity = identity;
      _server = readiness.message;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _checking ? null : _check,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(_checking
                ? 'Diagnose läuft ...'
                : 'App und Sprachserver prüfen'),
          ),
          const Text(
              'Prüft nur App-Identität und Serverkonfiguration. '
              'Keine Kindertexte, Mikrofonaufnahme oder kostenpflichtige Synthese.',
              style: TextStyle(fontSize: 12)),
          ValueListenableBuilder<VoiceStatus>(
            valueListenable: LumoVoice.instance.status,
            builder: (_, status, __) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sprachstatus: ${switch (status) {
                  VoiceStatus.idle => 'Ruhe',
                  VoiceStatus.preparing => 'Sulafat wird vorbereitet',
                  VoiceStatus.speaking => 'Sprachausgabe läuft',
                  VoiceStatus.error => 'Keine Sprachausgabe verfügbar',
                }}'
                '${LumoVoice.instance.lastStartedAudioIdentity == null ? '' : '\nZuletzt gestartete Quelle: ${LumoVoice.instance.lastStartedAudioIdentity}'}'
                '\nBestätigte Wiedergabestarts: ${LumoVoice.instance.startedPlaybackCount}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          if (_identity != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(_identity!,
                    style: const TextStyle(fontSize: 12))),
          if (_server != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_server!, style: const TextStyle(fontSize: 12))),
          ValueListenableBuilder<String?>(
            valueListenable: LumoVoice.instance.lastError,
            builder: (_, error, __) => error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Letzte Sprachausgabe: $error',
                        style: const TextStyle(fontSize: 12))),
          ),
        ],
      );
}
