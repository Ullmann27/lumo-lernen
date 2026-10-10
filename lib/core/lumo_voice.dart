import 'dart:async';
import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'lumo_voice_clips.dart';
import 'lumo_voice_policy.dart';

/// Zentrales Voice-System fuer Lumo.
///
/// Ziel:
/// - deutlich weniger robotisch
/// - kindgerechter, waermer, ruhiger
/// - beste verfuegbare deutsche Stimme automatisch waehlen
/// - emotionale Sprechmodi statt immer gleicher TTS-Ausgabe
/// - stabiler Fallback ohne neue Build-Risiken
///
/// Die Original-Lumo-Stimme (vorproduzierte Sulafat-Aufnahmen) hat Vorrang.
/// Bekannte Saetze verwenden die Originalaufnahme und bewegen den Mund;
/// dynamische Lerntexte werden vorerst mit lokaler deutscher TTS gesprochen.
/// Die Eltern-Stimmprobe spielt dieselbe Originalaufnahme wie die Lern-App.
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
  Future<void> _outputQueue = Future<void>.value();

  final ValueNotifier<VoiceStatus> status =
      ValueNotifier<VoiceStatus>(VoiceStatus.idle);

  /// Native TTS word boundaries, used by Lumo's approximate mouth animation.
  /// This never starts speech or advances while a local timer is running.
  final ValueNotifier<int> spokenWordRevision = ValueNotifier<int>(0);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  /// Mundöffnung 0–1 aus der Hüllkurve des gerade laufenden Clips;
  /// null, wenn kein Clip spricht (dann gelten Wortgrenzen der TTS).
  final ValueNotifier<double?> clipMouth = ValueNotifier<double?>(null);

  /// Original-Lumo-Aufnahmen in der App verwenden, auch bei `Stimme testen`.
  /// Nur in Flutter-Unit-Tests ohne Audio-Plugin standardmaessig deaktiviert.
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
            return <String, String>{
              for (final entry in voice.entries)
                entry.key.toString(): entry.value.toString(),
              'name': name,
              'locale': locale,
            };
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
    return LumoVoicePolicy.score(voice);
  }

  /// Zentrale Sprechabsicht fuer kurze Standardreaktionen aller Bereiche.
  /// Lerntasks und Diktattexte werden nicht umgeschrieben; das vermeidet
  /// inhaltlich falsche Antworten oder ungewollte zusaetzliche Saetze.
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

  Future<void> _applyStyle(VoiceStyle style) async {
    // Heinz wollte schnellere Stimme. Alle Raten um ~25-35% erhoeht.
    // Vorher waren die Werte zwischen 0.30-0.42 - zu langsam.
    // Jetzt 0.46-0.60 - normales Sprechtempo, aber noch kindgerecht.
    switch (style) {
      case VoiceStyle.greeting:
        await _set(rate: 0.51, pitch: 1.04, volume: 0.95);
        break;
      case VoiceStyle.explain:
        // Erklaer-Modus etwas langsamer als greeting, damit Kinder folgen koennen.
        await _set(rate: 0.46, pitch: 1.00, volume: 1.0);
        break;
      case VoiceStyle.celebrate:
        // Bei Erfolg: schnell und froh.
        await _set(rate: 0.54, pitch: 1.07, volume: 0.95);
        break;
      case VoiceStyle.comfort:
        // Bei Problemen: ruhig aber nicht mehr so langsam wie vorher.
        await _set(rate: 0.47, pitch: 1.01, volume: 0.92);
        break;
      case VoiceStyle.question:
        await _set(rate: 0.50, pitch: 1.04, volume: 1.0);
        break;
      case VoiceStyle.warm:
        // Standard-Lese-Modus: natuerliches Sprechtempo.
        await _set(rate: 0.49, pitch: 1.02, volume: 0.95);
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
    _outputQueue = _outputQueue.then((_) async {
      if (!_enabled || generation != _speechGeneration) return;
      try {
        lastError.value = null;
        await _tts.stop();
        await _stopClip();
        if (!_enabled || generation != _speechGeneration) return;
        if (await _speakClip(text, generation)) return;
        if (!_enabled || generation != _speechGeneration) return;
        // Alle Lernmodule laufen durch dieselbe expressive Engine. Kurztexte
        // werden nach ihrer kommunikativen Funktion betont, sofern der
        // Aufrufer nicht selbst bereits einen Sprechmodus festlegt.
        final effectiveStyle =
            style == VoiceStyle.warm ? suggestedStyle(text) : style;
        await _applyStyle(effectiveStyle);
        if (!_enabled || generation != _speechGeneration) return;
        final prepared = _prepareHumanText(text, effectiveStyle);
        if (prepared.isEmpty) return;
        final result = await _tts.speak(prepared);
        if (kDebugMode) {
          debugPrint(
              '[LumoVoice] voice=$_selectedVoiceName locale=$_selectedLocale style=$style -> $result');
        }
      } catch (e) {
        if (generation != _speechGeneration) return;
        lastError.value = 'TTS-Fehler: $e';
        status.value = VoiceStatus.error;
      }
    });
    await _outputQueue;
  }

  Future<bool> _speakClip(String text, int generation) async {
    if (!clipsEnabled) return false;
    try {
      await LumoVoiceClips.ensureLoaded();
      final clip = LumoVoiceClips.lookup(text);
      if (!_enabled || clip == null || generation != _speechGeneration) {
        return false;
      }
      final player = _clipPlayer ??= AudioPlayer(playerId: 'lumo-voice')
        // Die Mundbewegung nutzt eine eigene Uhr; ohne Positions-Updater
        // plant der Player keine zusätzlichen Frames ein.
        ..positionUpdater = null;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);
      _clipDone ??= player.onPlayerComplete.listen((_) => _finishClip());
      if (!_enabled || generation != _speechGeneration) return true;
      await player.play(AssetSource(clip.assetSource));
      if (!_enabled || generation != _speechGeneration) {
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
    _finishClip();
    // A player can already be starting while no envelope ticker exists.
    // Always stop the native player, including that startup window.
    try {
      await _clipPlayer?.stop();
    } catch (_) {}
  }

  String _prepareHumanText(String input, VoiceStyle style) {
    return LumoVoicePolicy.prepare(input);
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
    if (_voice.status.value == VoiceStatus.speaking) unawaited(_voice.stop());
  }
}

enum VoiceStyle { warm, greeting, explain, celebrate, comfort, question }

enum VoiceStatus { idle, speaking, error }
