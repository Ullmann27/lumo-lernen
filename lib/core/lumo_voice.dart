import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'lumo_child_speech_normalizer.dart';

/// Zentrales Voice-System fuer Lumo.
///
/// Ziel:
/// - deutlich weniger robotisch
/// - kindgerechter, waermer, ruhiger
/// - beste verfuegbare deutsche Stimme automatisch waehlen
/// - emotionale Sprechmodi statt immer gleicher TTS-Ausgabe
/// - stabiler Fallback ohne neue Build-Risiken
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

  final ValueNotifier<VoiceStatus> status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  bool get isEnabled => _enabled;
  set isEnabled(bool v) => _enabled = v;

  String? get selectedVoiceName => _selectedVoiceName;
  String? get selectedLocale => _selectedLocale;

  Future<void> configure({bool? enabled, double? rate, double? pitch}) async {
    if (enabled != null) _enabled = enabled;
    // 2026-06-14: Anker auf neuen Default 0.46 verschoben + Pitch-Offset-
    // Range vergroessert damit Kinder-Stimme (bis +0.25) durchgereicht wird.
    if (rate != null) _rateFactor = (rate / 0.46).clamp(0.55, 1.45).toDouble();
    if (pitch != null) _pitchOffset = (pitch - 1.14).clamp(-0.25, 0.25).toDouble();
    if (_initFuture != null) {
      await _applyStyle(VoiceStyle.warm);
    }
  }

  Future<void> _ensureReady() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      _tts.setStartHandler(() => status.value = VoiceStatus.speaking);
      _tts.setCompletionHandler(() => status.value = VoiceStatus.idle);
      _tts.setCancelHandler(() => status.value = VoiceStatus.idle);
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
    return rawVoices.map<Map<String, String>?>((voice) {
      if (voice is Map) {
        final name = (voice['name'] ?? voice['voice'] ?? '').toString();
        final locale = (voice['locale'] ?? voice['language'] ?? '').toString();
        if (name.isEmpty && locale.isEmpty) return null;
        return <String, String>{'name': name, 'locale': locale};
      }
      return null;
    }).whereType<Map<String, String>>().toList();
  }

  bool _isGermanVoice(Map<String, String> voice) {
    final locale = (voice['locale'] ?? '').toLowerCase();
    final name = (voice['name'] ?? '').toLowerCase();
    return locale.startsWith('de') || name.contains('german') || name.contains('deutsch');
  }

  int _scoreVoice(Map<String, String> voice) {
    final name = (voice['name'] ?? '').toLowerCase();
    final locale = (voice['locale'] ?? '').toLowerCase();
    var score = 0;

    // 2026-06-14 Heinz' Tochter: "Stimme klingt nicht schön".
    // Neu-Gewichtung: Premium-Qualitaet (Neural/WaveNet/Google-Network) wird
    // viel hoeher gewertet als die alte robotische Pico-TTS-Standardstimme.
    // Frauen-/Maedchen-Stimmen bekommen DEUTLICH mehr Gewicht weil Kinder
    // sie als waermer und freundlicher empfinden.
    if (locale == 'de-at') score += 120;
    if (locale == 'de-de') score += 100;
    if (locale.startsWith('de')) score += 80;

    // Premium-Qualitaet (massiv hoehere Gewichtung als vorher)
    if (name.contains('google')) score += 110;
    if (name.contains('neural')) score += 100;
    if (name.contains('wavenet')) score += 100;
    if (name.contains('natural')) score += 90;
    if (name.contains('enhanced')) score += 70;
    if (name.contains('premium')) score += 65;
    if (name.contains('hd')) score += 60;
    // Network-Voices auf Android sind meistens Google's premium Cloud-TTS -
    // also POSITIV, nicht negativ wie vorher.
    if (name.contains('network')) score += 50;

    // Konkrete bekannte deutsche Frauenstimmen (Android + iOS)
    if (name.contains('marlene')) score += 60;
    if (name.contains('vicki')) score += 60;
    if (name.contains('hedda')) score += 55;
    if (name.contains('petra')) score += 55;
    if (name.contains('anna')) score += 50;
    if (name.contains('katja')) score += 50;
    if (name.contains('katharina')) score += 45;
    if (name.contains('helena')) score += 40;
    // de-de-x-deg / de-de-x-nfh sind Google's neuesten Female-Voices
    if (name.contains('-deg')) score += 70;
    if (name.contains('-nfh')) score += 70;
    if (name.contains('-deb')) score += 65;
    if (name.contains('-def')) score += 65;

    // Allgemeine Female-Marker
    if (name.contains('female')) score += 45;
    if (name.contains('frau')) score += 45;
    if (name.contains('woman')) score += 40;
    // f-suffix in Voice-Namen ist oft Female
    if (name.endsWith('-f') || name.endsWith('_f')) score += 25;

    // Robotische / alte Stimmen abwerten
    if (name.contains('compact')) score -= 40;
    if (name.contains('legacy')) score -= 50;
    if (name.contains('pico')) score -= 60;
    if (name.contains('espeak')) score -= 60;
    if (name.contains('default')) score -= 20;
    // Männerstimmen leicht abwerten (Heinz' Tochter mag Mädchenstimme lieber)
    if (name.contains('male') && !name.contains('female')) score -= 15;
    if (name.contains('mann')) score -= 15;

    return score;
  }

  Future<void> _applyStyle(VoiceStyle style) async {
    // 2026-06-14 Heinz' Tochter findet die Stimme nicht schoen.
    // Neu-Tuning: Pitch generell HOEHER (kindlicher / freundlicher),
    // Rate moderat (nicht zu schnell, damit Kinder folgen koennen) und
    // staerkere emotionale Differenzierung zwischen den Styles.
    switch (style) {
      case VoiceStyle.greeting:
        await _set(rate: 0.48, pitch: 1.18, volume: 1.0);
        break;
      case VoiceStyle.explain:
        // Erklaer-Modus: ruhig + klar, aber waermer als vorher.
        await _set(rate: 0.44, pitch: 1.12, volume: 1.0);
        break;
      case VoiceStyle.celebrate:
        // Bei Erfolg: deutlich froher + hoeher.
        await _set(rate: 0.56, pitch: 1.22, volume: 1.0);
        break;
      case VoiceStyle.comfort:
        // Bei Problemen: weich, langsam, beruhigend.
        await _set(rate: 0.42, pitch: 1.08, volume: 0.96);
        break;
      case VoiceStyle.question:
        // Frage-Modus: leicht ansteigend, neugierig.
        await _set(rate: 0.48, pitch: 1.16, volume: 1.0);
        break;
      case VoiceStyle.warm:
        // Standard: warm + freundlich, nicht zu robotisch.
        await _set(rate: 0.46, pitch: 1.14, volume: 1.0);
        break;
    }
  }

  Future<void> _set({required double rate, required double pitch, required double volume}) async {
    // Pitch-Obergrenze auf 1.40 angehoben damit der waermere Default-Pitch
    // + User-Offset noch Spielraum hat (kindlichere Stimme).
    await _tts.setSpeechRate((rate * _rateFactor).clamp(0.30, 0.85).toDouble());
    await _tts.setPitch((pitch + _pitchOffset).clamp(0.80, 1.40).toDouble());
    await _tts.setVolume(volume);
  }

  Future<void> speak(String text, {VoiceStyle style = VoiceStyle.warm}) async {
    if (!_enabled || text.trim().isEmpty) return;
    await _ensureReady();
    try {
      await _tts.stop();
      await _applyStyle(style);
      final prepared = _prepareHumanText(text, style);
      final result = await _tts.speak(prepared);
      if (kDebugMode) {
        debugPrint('[LumoVoice] voice=$_selectedVoiceName locale=$_selectedLocale style=$style -> $result');
      }
    } catch (e) {
      lastError.value = 'TTS-Fehler: $e';
      status.value = VoiceStatus.error;
    }
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
    try {
      await _tts.stop();
    } catch (_) {}
    status.value = VoiceStatus.idle;
  }

  Future<void> test() => speak(
        'Hallo! Ich bin Lumo, dein Lernfuchs. Klingt meine Stimme schön für dich?',
        style: VoiceStyle.greeting,
      );
}

enum VoiceStyle { warm, greeting, explain, celebrate, comfort, question }

enum VoiceStatus { idle, speaking, error }
