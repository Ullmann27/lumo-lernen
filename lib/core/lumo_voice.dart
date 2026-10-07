import 'dart:async';
import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'lumo_child_speech_normalizer.dart';
import 'lumo_voice_clips.dart';

/// Zentrales Voice-System fuer Lumo.
///
/// Ziel:
/// - deutlich weniger robotisch
/// - kindgerechter, waermer, ruhiger
/// - beste verfuegbare deutsche Stimme automatisch waehlen
/// - emotionale Sprechmodi statt immer gleicher TTS-Ausgabe
/// - stabiler Fallback ohne neue Build-Risiken
///
/// Feste, häufige Sätze kommen als vorproduzierte Lumo-Stimme
/// ([LumoVoiceClips]); alles andere und jeder Clip-Fehler fällt auf die
/// Geräte-Sprachausgabe zurück.
class LumoVoice {
  LumoVoice._internal();
  static final LumoVoice instance = LumoVoice._internal();

  final FlutterTts _tts = FlutterTts();
  Future<void>? _initFuture;
  bool _enabled = true;
  bool _voiceSelected = false;
  double _rateFactor = 1.0;
  double _pitchOffset = 0.0;
  String? _selectedVoiceName;
  String? _selectedLocale;
  int _speechGeneration = 0;

  final ValueNotifier<VoiceStatus> status =
      ValueNotifier<VoiceStatus>(VoiceStatus.idle);

  /// Native TTS word boundaries, used by Lumo's approximate mouth animation.
  /// This never starts speech or advances while a local timer is running.
  final ValueNotifier<int> spokenWordRevision = ValueNotifier<int>(0);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  /// Mundöffnung 0–1 aus der Hüllkurve des gerade laufenden Clips;
  /// null, wenn kein Clip spricht (dann gelten Wortgrenzen der TTS).
  final ValueNotifier<double?> clipMouth = ValueNotifier<double?>(null);

  /// Vorproduzierte Clips verwenden. In Widget-Tests standardmäßig aus, weil
  /// dort kein Audio-Plugin läuft; Tests schalten es gezielt ein.
  bool clipsEnabled =
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  AudioPlayer? _clipPlayer;
  StreamSubscription<void>? _clipDone;
  Timer? _clipTicker;

  bool get isEnabled => _enabled;
  set isEnabled(bool value) {
    _enabled = value;
    if (!value) unawaited(stop());
  }

  String? get selectedVoiceName => _selectedVoiceName;
  String? get selectedLocale => _selectedLocale;

  Future<void> configure({bool? enabled, double? rate, double? pitch}) async {
    if (enabled != null) {
      _enabled = enabled;
      if (!enabled) await stop();
    }
    if (rate != null) _rateFactor = (rate / 0.35).clamp(0.70, 1.55).toDouble();
    if (pitch != null) {
      _pitchOffset = (pitch - 1.0).clamp(-0.20, 0.20).toDouble();
    }
    if (_initFuture != null) {
      await _applyStyle(VoiceStyle.warm);
    }
  }

  Future<void> _ensureReady() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      _tts.setStartHandler(() =>
          status.value = _enabled ? VoiceStatus.speaking : VoiceStatus.idle);
      _tts.setCompletionHandler(() => status.value = VoiceStatus.idle);
      _tts.setCancelHandler(() => status.value = VoiceStatus.idle);
      _tts.setPauseHandler(() => status.value = VoiceStatus.idle);
      _tts.setContinueHandler(() =>
          status.value = _enabled ? VoiceStatus.speaking : VoiceStatus.idle);
      _tts.setProgressHandler((text, start, end, word) {
        if (_enabled &&
            status.value == VoiceStatus.speaking &&
            word.trim().isNotEmpty) {
          spokenWordRevision.value++;
        }
      });
      _tts.setErrorHandler((msg) {
        lastError.value = msg.toString();
        status.value = VoiceStatus.error;
      });

      await _selectBestGermanVoice();
      await _applyStyle(VoiceStyle.warm);

      try {
        await _tts.awaitSpeakCompletion(false);
      } catch (_) {}

      status.value = VoiceStatus.idle;
    } catch (e) {
      lastError.value = 'TTS-Init fehlgeschlagen: $e';
      status.value = VoiceStatus.error;
    }
  }

  Future<void> _selectBestGermanVoice() async {
    if (_voiceSelected) return;

    final fallbackLanguages = <String>['de-AT', 'de-DE', 'de'];

    try {
      final rawVoices = await _tts.getVoices;
      final voices = _normaliseVoices(rawVoices);
      final germanVoices = voices.where(_isGermanVoice).toList();

      if (germanVoices.isNotEmpty) {
        germanVoices.sort((a, b) => _scoreVoice(b).compareTo(_scoreVoice(a)));
        final best = germanVoices.first;
        final name = best['name'];
        final locale = best['locale'];

        if (name != null && locale != null) {
          await _tts.setVoice({'name': name, 'locale': locale});
          _selectedVoiceName = name;
          _selectedLocale = locale;
          _voiceSelected = true;
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LumoVoice] Voice scan failed: $e');
    }

    for (final lang in fallbackLanguages) {
      try {
        final available = await _tts.isLanguageAvailable(lang);
        if (available == true || available == 1) {
          await _tts.setLanguage(lang);
          _selectedLocale = lang;
          _voiceSelected = true;
          return;
        }
      } catch (_) {}
    }

    try {
      await _tts.setLanguage('de-DE');
      _selectedLocale = 'de-DE';
    } catch (_) {}
    _voiceSelected = true;
  }

  List<Map<String, String>> _normaliseVoices(dynamic rawVoices) {
    if (rawVoices is! List) return const <Map<String, String>>[];
    return rawVoices
        .map<Map<String, String>?>((voice) {
          if (voice is Map) {
            final name = (voice['name'] ?? voice['voice'] ?? '').toString();
            final locale =
                (voice['locale'] ?? voice['language'] ?? '').toString();
            if (name.isEmpty && locale.isEmpty) return null;
            return <String, String>{'name': name, 'locale': locale};
          }
          return null;
        })
        .whereType<Map<String, String>>()
        .toList();
  }

  bool _isGermanVoice(Map<String, String> voice) {
    final locale = (voice['locale'] ?? '').toLowerCase();
    final name = (voice['name'] ?? '').toLowerCase();
    return locale.startsWith('de') ||
        name.contains('german') ||
        name.contains('deutsch');
  }

  int _scoreVoice(Map<String, String> voice) {
    final name = (voice['name'] ?? '').toLowerCase();
    final locale = (voice['locale'] ?? '').toLowerCase();
    var score = 0;

    if (locale == 'de-at') score += 120;
    if (locale == 'de-de') score += 100;
    if (locale.startsWith('de')) score += 80;

    if (name.contains('google')) score += 45;
    if (name.contains('neural')) score += 45;
    if (name.contains('natural')) score += 40;
    if (name.contains('enhanced')) score += 35;
    if (name.contains('premium')) score += 30;
    if (name.contains('female')) score += 22;
    if (name.contains('frau')) score += 22;
    if (name.contains('anna')) score += 18;
    if (name.contains('marlene')) score += 18;
    if (name.contains('katja')) score += 18;
    if (name.contains('vicki')) score += 18;

    if (name.contains('network')) score -= 15;
    if (name.contains('compact')) score -= 20;
    if (name.contains('default')) score -= 8;

    return score;
  }

  Future<void> _applyStyle(VoiceStyle style) async {
    // Heinz wollte schnellere Stimme. Alle Raten um ~25-35% erhoeht.
    // Vorher waren die Werte zwischen 0.30-0.42 - zu langsam.
    // Jetzt 0.46-0.60 - normales Sprechtempo, aber noch kindgerecht.
    switch (style) {
      case VoiceStyle.greeting:
        await _set(rate: 0.50, pitch: 1.05, volume: 1.0);
        break;
      case VoiceStyle.explain:
        // Erklaer-Modus etwas langsamer als greeting, damit Kinder folgen koennen.
        await _set(rate: 0.46, pitch: 1.00, volume: 1.0);
        break;
      case VoiceStyle.celebrate:
        // Bei Erfolg: schnell und froh.
        await _set(rate: 0.58, pitch: 1.10, volume: 1.0);
        break;
      case VoiceStyle.comfort:
        // Bei Problemen: ruhig aber nicht mehr so langsam wie vorher.
        await _set(rate: 0.44, pitch: 0.98, volume: 0.96);
        break;
      case VoiceStyle.question:
        await _set(rate: 0.50, pitch: 1.04, volume: 1.0);
        break;
      case VoiceStyle.warm:
        // Standard-Lese-Modus: natuerliches Sprechtempo.
        await _set(rate: 0.50, pitch: 1.03, volume: 1.0);
        break;
    }
  }

  Future<void> _set(
      {required double rate,
      required double pitch,
      required double volume}) async {
    // Clamp-Obergrenze von 0.60 auf 0.85 erhoeht, damit schnellere Raten
    // ueberhaupt durchkommen. Untergrenze 0.30 reicht fuer comfort-Modus.
    await _tts.setSpeechRate((rate * _rateFactor).clamp(0.30, 0.85).toDouble());
    await _tts.setPitch((pitch + _pitchOffset).clamp(0.80, 1.25).toDouble());
    await _tts.setVolume(volume);
  }

  Future<void> speak(String text, {VoiceStyle style = VoiceStyle.warm}) async {
    if (!_enabled || text.trim().isEmpty) return;
    final generation = ++_speechGeneration;
    await _ensureReady();
    if (!_enabled || generation != _speechGeneration) return;
    try {
      await _tts.stop();
      await _stopClip();
      if (!_enabled || generation != _speechGeneration) return;
      if (await _speakClip(text, generation)) return;
      if (!_enabled || generation != _speechGeneration) return;
      await _applyStyle(style);
      if (!_enabled || generation != _speechGeneration) return;
      final prepared = _prepareHumanText(text, style);
      final result = await _tts.speak(prepared);
      if (kDebugMode) {
        debugPrint(
            '[LumoVoice] voice=$_selectedVoiceName locale=$_selectedLocale style=$style -> $result');
      }
    } catch (e) {
      lastError.value = 'TTS-Fehler: $e';
      status.value = VoiceStatus.error;
    }
  }

  Future<bool> _speakClip(String text, int generation) async {
    if (!clipsEnabled) return false;
    try {
      await LumoVoiceClips.ensureLoaded();
      final clip = LumoVoiceClips.lookup(text);
      if (clip == null || generation != _speechGeneration) return false;
      final player = _clipPlayer ??= AudioPlayer(playerId: 'lumo-voice')
        // Die Mundbewegung nutzt eine eigene Uhr; ohne Positions-Updater
        // plant der Player keine zusätzlichen Frames ein.
        ..positionUpdater = null;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);
      _clipDone ??= player.onPlayerComplete.listen((_) => _finishClip());
      if (generation != _speechGeneration) return true;
      await player.play(AssetSource(clip.assetSource));
      if (generation != _speechGeneration) {
        await _stopClip();
        return true;
      }
      clipMouth.value = 0;
      status.value = VoiceStatus.speaking;
      final watch = Stopwatch()..start();
      _clipTicker?.cancel();
      _clipTicker = Timer.periodic(const Duration(milliseconds: 50), (t) {
        if (watch.elapsed > clip.duration + const Duration(milliseconds: 400)) {
          // Sicherheitsnetz, falls das Abschluss-Ereignis ausbleibt.
          _finishClip();
          return;
        }
        clipMouth.value = clip.mouthAt(watch.elapsed);
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[LumoVoice] Clip fehlgeschlagen, TTS: $e');
      _finishClip();
      return false;
    }
  }

  void _finishClip() {
    _clipTicker?.cancel();
    _clipTicker = null;
    if (clipMouth.value != null) {
      clipMouth.value = null;
      status.value = VoiceStatus.idle;
    }
  }

  Future<void> _stopClip() async {
    final wasPlaying = _clipTicker != null;
    _finishClip();
    if (!wasPlaying) return;
    try {
      await _clipPlayer?.stop();
    } catch (_) {}
  }

  String _prepareHumanText(String input, VoiceStyle style) {
    // Erst Mathezeichen, Geld, Uhrzeit, Brueche, Emojis schoener machen.
    // LumoChildSpeechNormalizer.forSpeech() macht aus '3 + 4 = ?' einen
    // natuerlichen Satz: 'drei plus vier. Was kommt heraus?'
    final beautified = LumoChildSpeechNormalizer.forSpeech(input);

    var text = beautified
        .replaceAll('\n', '. ')
        .replaceAll('  ', ' ')
        .replaceAll('⭐', '')
        .replaceAll('🚀', '')
        .replaceAll('🦊', 'Lumo')
        .trim();

    while (text.contains('..')) {
      text = text.replaceAll('..', '.');
    }

    switch (style) {
      case VoiceStyle.greeting:
        return 'Hallo. $text';
      case VoiceStyle.celebrate:
        return 'Juhu! $text';
      case VoiceStyle.comfort:
        return 'Ganz ruhig. $text';
      case VoiceStyle.question:
        return '$text. Was denkst du?';
      case VoiceStyle.explain:
        return text;
      case VoiceStyle.warm:
        return text;
    }
  }

  Future<void> stop() async {
    _speechGeneration++;
    status.value = VoiceStatus.idle;
    await _stopClip();
    try {
      await _tts.stop();
    } catch (_) {}
    status.value = VoiceStatus.idle;
  }

  Future<void> test() => speak(
        'Hallo! Ich bin Lumo, dein Lernfuchs. Ich spreche jetzt ruhiger, freundlicher und menschlicher.',
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
    if (_voice.status.value == VoiceStatus.speaking) unawaited(_voice.stop());
  }
}

enum VoiceStyle { warm, greeting, explain, celebrate, comfort, question }

enum VoiceStatus { idle, speaking, error }
