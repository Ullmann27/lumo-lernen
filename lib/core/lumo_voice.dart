import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'lumo_sulafat_client.dart';
import 'lumo_voice_clips.dart';
import 'lumo_voice_policy.dart';

/// Einheitliche Lumo-Sprecheridentitaet: Gemini TTS / Sulafat.
/// Die Begruessungs-Stimmprobe bleibt die originale M4A-Datei.
/// Andere Saetze kommen ausschliesslich aus demselben Sulafat-Clipkatalog
/// oder (nach aktiver Elternfreigabe) aus der Sulafat-Server-Synthese.
/// Keine Android-TTS-Stimme, kein heimlicher Ersatz bei Netzfehlern.
class LumoVoice {
  LumoVoice._internal();
  static final LumoVoice instance = LumoVoice._internal();

  final LumoSulafatClient _client = const LumoSulafatClient();
  bool _enabled = true;
  bool _cloudVoiceEnabled = false;
  String _serverUrl = 'https://lumo-ai-proxy.onrender.com';
  double _playbackRate = 1.0;
  int _speechGeneration = 0;

  AudioPlayer? _player;
  StreamSubscription<void>? _doneSubscription;
  Completer<void>? _playbackFinished;
  Timer? _mouthTicker;

  final ValueNotifier<VoiceStatus> status =
      ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  final ValueNotifier<int> spokenWordRevision = ValueNotifier<int>(0);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<double?> clipMouth = ValueNotifier<double?>(null);

  /// Tests koennen Clip-Audio isoliert deaktivieren, niemals eine
  /// unpassende Stimme als Ersatz aktivieren.
  bool clipsEnabled = true;

  bool get isEnabled => _enabled;
  bool get cloudVoiceEnabled => _cloudVoiceEnabled;
  String get selectedVoiceName => 'Sulafat';
  String get selectedLocale => 'de-DE';

  set isEnabled(bool value) {
    _enabled = value;
    if (!value) unawaited(stop());
  }

  Future<void> configure({
    bool? enabled,
    double? rate,
    double? pitch,
    bool? cloudVoiceEnabled,
    String? voiceServerUrl,
  }) async {
    if (enabled != null) {
      _enabled = enabled;
      if (!enabled) await stop();
    }
    if (rate != null) {
      // Real speed control for BOTH pre-recorded and generated audio.
      // The device-specific TTS voice (and its pitch controls) is removed.
      _playbackRate = (rate / 0.35).clamp(0.75, 1.30).toDouble();
      try {
        await _player?.setPlaybackRate(_playbackRate);
      } catch (_) {}
    }
    // Pitch is retained as a call parameter for older callers/settings.
    // We do not pretend it changes prerecorded Sulafat voice identity.
    if (cloudVoiceEnabled != null) {
      _cloudVoiceEnabled = cloudVoiceEnabled;
      if (!cloudVoiceEnabled) await stop();
    }
    if (voiceServerUrl != null && voiceServerUrl.trim().isNotEmpty) {
      _serverUrl = voiceServerUrl.trim();
    }
  }

  @visibleForTesting
  static VoiceStyle suggestedStyle(String text) {
    final s = text.trim().toLowerCase();
    if (s.isEmpty || s.length > 140) return VoiceStyle.warm;
    if (RegExp(r'^(super|toll gemacht|genau richtig|wow|bravo|klasse|stark|genial|perfekt|wahnsinn|voll richtig|mega|spitze|ich bin stolz)').hasMatch(s)) {
      return VoiceStyle.celebrate;
    }
    if (RegExp(r'^(fast|knapp daneben|hmm|nicht ganz|kein problem|das war fast|du schaffst|das war schwierig|ruhig)').hasMatch(s)) {
      return VoiceStyle.comfort;
    }
    if (RegExp(r'^(hallo|hi!|guten morgen|schön dich zu sehen)').hasMatch(s)) {
      return VoiceStyle.greeting;
    }
    if (s.endsWith('?')) return VoiceStyle.question;
    if (RegExp(r'^(schau|hier ist|lass uns|probier|zuerst|bei plus|bei minus)').hasMatch(s)) {
      return VoiceStyle.explain;
    }
    return VoiceStyle.warm;
  }

  AudioPlayer _ensurePlayer() {
    final player = _player ??= AudioPlayer(playerId: 'lumo-sulafat')
      ..positionUpdater = null;
    _doneSubscription ??= player.onPlayerComplete.listen((_) => _finishAudio());
    return player;
  }

  Future<void> speak(String text, {VoiceStyle style = VoiceStyle.warm}) async {
    if (!_enabled || text.trim().isEmpty) return;
    final generation = ++_speechGeneration;
    await _stopPlayback();
    if (!_enabled || generation != _speechGeneration) return;
    lastError.value = null;

    try {
      await LumoVoiceClips.ensureLoaded();
      final original = clipsEnabled ? LumoVoiceClips.lookup(text) : null;
      if (!_enabled || generation != _speechGeneration) return;
      if (original != null) {
        await _play(
          AssetSource(original.assetSource),
          generation,
          duration: original.duration,
          mouth: original.mouthAt,
        );
        return;
      }
      if (!_cloudVoiceEnabled) {
        // Conscious silence is safer than an entirely different old speaker.
        lastError.value =
            'Für freie Sulafat-Sätze bitte Online-Lumo-Stimme im Elternbereich freigeben.';
        status.value = VoiceStatus.error;
        return;
      }
      unawaited(_speakDynamic(text,
          style == VoiceStyle.warm ? suggestedStyle(text) : style, generation));
    } catch (e) {
      if (generation != _speechGeneration) return;
      lastError.value = 'Sulafat-Audio konnte nicht gestartet werden.';
      status.value = VoiceStatus.error;
    }
  }

  Future<void> _speakDynamic(
      String text, VoiceStyle style, int generation) async {
    final cleaned = LumoVoicePolicy.prepare(text);
    final fragments = LumoSulafatClient.segments(cleaned);
    for (final fragment in fragments) {
      if (!_enabled || !_cloudVoiceEnabled || generation != _speechGeneration) return;
      try {
        final audio = await _client.synthesize(
          text: fragment,
          style: style.name,
          baseUrl: _serverUrl,
        );
        if (!_enabled || !_cloudVoiceEnabled || generation != _speechGeneration) return;
        final ms = _wavDuration(audio);
        final end = Completer<void>();
        await _play(BytesSource(audio), generation, duration: Duration(milliseconds: ms),
            onFinished: end);
        await end.future.timeout(Duration(milliseconds: ms + 5000), onTimeout: () {});
      } catch (e) {
        if (!_enabled || generation != _speechGeneration) return;
        // No Android fallback, even if the provider, network or cache fails.
        lastError.value = 'Sulafat ist derzeit nicht erreichbar. '
            'Bitte Online-Stimme im Elternbereich und die Serververbindung prüfen.';
        status.value = VoiceStatus.error;
        return;
      }
    }
  }

  static int _wavDuration(Uint8List audio) {
    if (audio.length < 44) return 1000;
    final data = ByteData.sublistView(audio);
    final bytesPerSecond = data.getUint32(28, Endian.little);
    final dataSize = data.getUint32(40, Endian.little);
    if (bytesPerSecond < 1000 || dataSize < 20) return 1000;
    return (dataSize * 1000 / bytesPerSecond).ceil().clamp(250, 120000).toInt();
  }

  Future<void> _play(
    Source source,
    int generation, {
    required Duration duration,
    double Function(Duration)? mouth,
    Completer<void>? onFinished,
  }) async {
    if (!_enabled || generation != _speechGeneration) return;
    final player = _ensurePlayer();
    _playbackFinished = onFinished;
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(1);
    if (!_enabled || generation != _speechGeneration) return;
    await player.play(source);
    if (!_enabled || generation != _speechGeneration) {
      await player.stop();
      _finishAudio();
      return;
    }
    try {
      await player.setPlaybackRate(_playbackRate);
    } catch (_) {}
    status.value = VoiceStatus.speaking;
    clipMouth.value = 0;
    final watch = Stopwatch()..start();
    _mouthTicker?.cancel();
    final playbackMax = Duration(
      milliseconds: (duration.inMilliseconds / _playbackRate).ceil() + 400,
    );
    _mouthTicker = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (generation != _speechGeneration || watch.elapsed > playbackMax) {
        unawaited(player.stop());
        _finishAudio();
        return;
      }
      final scaled = Duration(
        milliseconds: (watch.elapsedMilliseconds * _playbackRate).round(),
      );
      clipMouth.value = mouth != null
          ? mouth(scaled)
          : (0.24 + 0.55 * (0.5 + 0.5 *
                  math.sin(watch.elapsedMilliseconds * 0.028))).clamp(0.0, 1.0);
      if (mouth == null) spokenWordRevision.value++;
    });
  }

  void _finishAudio() {
    _mouthTicker?.cancel();
    _mouthTicker = null;
    clipMouth.value = null;
    if (_playbackFinished != null && !_playbackFinished!.isCompleted) {
      _playbackFinished!.complete();
    }
    _playbackFinished = null;
    if (status.value == VoiceStatus.speaking) status.value = VoiceStatus.idle;
  }

  Future<void> _stopPlayback() async {
    _finishAudio();
    try {
      await _player?.stop();
    } catch (_) {}
    if (status.value != VoiceStatus.error) status.value = VoiceStatus.idle;
  }

  Future<void> stop() async {
    ++_speechGeneration;
    await _stopPlayback();
    status.value = VoiceStatus.idle;
  }

  /// Keinesfalls aendern: genau die Originalaufnahme des Nutzerwunsches.
  Future<void> test() => speak(
    'Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues!',
    style: VoiceStyle.greeting,
  );
}

/// Beendet Lumos Sprechen, sobald eine Seite verlassen oder ersetzt wird,
/// damit alter Text nicht auf der nächsten Seite weiterläuft.
class LumoVoiceRouteObserver extends NavigatorObserver {
  LumoVoiceRouteObserver({LumoVoice? voice})
      : _voice = voice ?? LumoVoice.instance;

  final LumoVoice _voice;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stopForPage(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stopForPage(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stopForPage(oldRoute);
  }

  void _stopForPage(Route<dynamic> route) {
    // Dialoge und Bottom-Sheets (z. B. Lumo-Gespräch) steuern ihr Sprechen selbst.
    if (route is! PageRoute) return;
    // Auch eine noch laufende Online-Synthese abbrechen, bevor sie auf
    // einer anderen Seite versehentlich abgespielt werden koennte.
    unawaited(_voice.stop());
  }
}

enum VoiceStyle { warm, greeting, explain, celebrate, comfort, question }

enum VoiceStatus { idle, speaking, error }
