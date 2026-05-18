import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'lumo_child_speech_normalizer.dart';
import 'lumo_premium_voice.dart';

/// Zentrales Voice-System fuer Lumo.
///
/// Reihenfolge:
/// 1. optionale Premium-Stimme per dart-define
/// 2. lokaler MP3-Cache ueber LumoPremiumVoice
/// 3. sicherer Offline-Fallback ueber flutter_tts
///
/// Die App darf nie abstuerzen, wenn Premium-TTS fehlt, offline ist oder
/// fehlschlaegt. Dann spricht automatisch die lokale deutsche TTS.
class LumoVoice {
  LumoVoice._internal();
  static final LumoVoice instance = LumoVoice._internal();

  final FlutterTts _tts = FlutterTts();
  final LumoPremiumVoice _premium = LumoPremiumVoice();

  Future<void>? _initFuture;
  bool _enabled = true;
  bool _voiceSelected = false;
  double _rateFactor = 1.0;
  double _pitchOffset = 0.0;
  String? _selectedVoiceName;
  String? _selectedLocale;
  int _speechTicket = 0;

  final ValueNotifier<VoiceStatus> status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  bool get isEnabled => _enabled;
  set isEnabled(bool v) => _enabled = v;

  bool get premiumConfigured => _premium.configured;
  String? get selectedVoiceName => _selectedVoiceName;
  String? get selectedLocale => _selectedLocale;

  Future<void> configure({bool? enabled, double? rate, double? pitch}) async {
    if (enabled != null) _enabled = enabled;
    if (rate != null) _rateFactor = (rate / 0.35).clamp(0.70, 1.55).toDouble();
    if (pitch != null) _pitchOffset = (pitch - 1.0).clamp(-0.20, 0.20).toDouble();
    if (_initFuture != null) await _applyStyle(VoiceStyle.warm);
  }

  Future<void> _ensureReady() => _initFuture ??= _doInit();

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
    switch (style) {
      case VoiceStyle.greeting:
        await _set(rate: 0.50, pitch: 1.05, volume: 1.0);
        break;
      case VoiceStyle.explain:
        await _set(rate: 0.46, pitch: 1.00, volume: 1.0);
        break;
      case VoiceStyle.celebrate:
        await _set(rate: 0.58, pitch: 1.10, volume: 1.0);
        break;
      case VoiceStyle.comfort:
        await _set(rate: 0.44, pitch: 0.98, volume: 0.96);
        break;
      case VoiceStyle.question:
        await _set(rate: 0.50, pitch: 1.04, volume: 1.0);
        break;
      case VoiceStyle.warm:
        await _set(rate: 0.50, pitch: 1.03, volume: 1.0);
        break;
    }
  }

  Future<void> _set({required double rate, required double pitch, required double volume}) async {
    await _tts.setSpeechRate((rate * _rateFactor).clamp(0.30, 0.85).toDouble());
    await _tts.setPitch((pitch + _pitchOffset).clamp(0.80, 1.25).toDouble());
    await _tts.setVolume(volume);
  }

  Future<void> speak(String text, {VoiceStyle style = VoiceStyle.warm}) async {
    if (!_enabled || text.trim().isEmpty) return;
    final ticket = ++_speechTicket;
    final prepared = _prepareHumanText(text, style);

    try {
      await stop();
      if (ticket != _speechTicket) return;
      status.value = VoiceStatus.speaking;

      final premiumOk = await _premium.speak(prepared);
      if (premiumOk) {
        if (ticket == _speechTicket) status.value = VoiceStatus.idle;
        return;
      }

      await _ensureReady();
      if (ticket != _speechTicket) return;
      await _applyStyle(style);
      final result = await _tts.speak(prepared);
      if (kDebugMode) {
        debugPrint('[LumoVoice] locale=$_selectedLocale premium=$premiumConfigured style=$style -> $result');
      }
    } catch (e) {
      lastError.value = 'TTS-Fehler: $e';
      status.value = VoiceStatus.error;
    }
  }

  String _prepareHumanText(String input, VoiceStyle style) {
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
      case VoiceStyle.warm:
        return text;
    }
  }

  Future<void> stop() async {
    _speechTicket++;
    try {
      await _premium.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    status.value = VoiceStatus.idle;
  }

  Future<void> test() => speak(
        'Hallo! Ich bin Lumo, dein Lernfuchs. Ich spreche freundlich, ruhig und kindgerecht.',
        style: VoiceStyle.greeting,
      );
}

enum VoiceStyle { warm, greeting, explain, celebrate, comfort, question }

enum VoiceStatus { idle, speaking, error }
