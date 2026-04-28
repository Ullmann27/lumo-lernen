import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum VoiceStatus { idle, speaking, error }
enum LumoVoiceStyle { calm, explain, celebrate, comfort, whisper }

class LumoVoice {
  LumoVoice._internal();
  static final LumoVoice instance = LumoVoice._internal();

  final FlutterTts _tts = FlutterTts();
  Future<void>? _initFuture;
  bool _enabled = true;

  final ValueNotifier<VoiceStatus> status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  bool get isEnabled => _enabled;
  set isEnabled(bool v) => _enabled = v;

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

      var languageOk = false;
      for (final lang in ['de-AT', 'de-DE', 'de']) {
        try {
          final res = await _tts.isLanguageAvailable(lang);
          if (res == true || res == 1) {
            await _tts.setLanguage(lang);
            languageOk = true;
            break;
          }
        } catch (_) {}
      }
      if (!languageOk) {
        try {
          await _tts.setLanguage('de-DE');
        } catch (_) {}
      }

      await _applyStyle(LumoVoiceStyle.calm);
      try {
        await _tts.awaitSpeakCompletion(false);
      } catch (_) {}
      status.value = VoiceStatus.idle;
    } catch (e) {
      lastError.value = 'TTS-Init fehlgeschlagen: $e';
      status.value = VoiceStatus.error;
    }
  }

  Future<void> speak(String text, {LumoVoiceStyle style = LumoVoiceStyle.calm}) async {
    if (!_enabled || text.trim().isEmpty) return;
    await _ensureReady();
    try {
      await _tts.stop();
      await _applyStyle(style);
      final spoken = _shapeForSpeech(text, style);
      final r = await _tts.speak(spoken);
      if (kDebugMode) debugPrint('[LumoVoice] $style "$spoken" -> $r');
    } catch (e) {
      lastError.value = 'TTS-Fehler: $e';
      status.value = VoiceStatus.error;
    }
  }

  Future<void> speakEvent(String event, String text) async {
    final style = switch (event) {
      'correct' || 'mission_finished' || 'success_streak' => LumoVoiceStyle.celebrate,
      'wrong_1' || 'wrong_2' || 'wrong_3' => LumoVoiceStyle.comfort,
      'test_start' || 'explain' => LumoVoiceStyle.explain,
      'pause' => LumoVoiceStyle.whisper,
      _ => LumoVoiceStyle.calm,
    };
    await speak(text, style: style);
  }

  Future<void> _applyStyle(LumoVoiceStyle style) async {
    switch (style) {
      case LumoVoiceStyle.celebrate:
        await _tts.setSpeechRate(0.49);
        await _tts.setPitch(1.24);
        await _tts.setVolume(1.0);
        break;
      case LumoVoiceStyle.comfort:
        await _tts.setSpeechRate(0.39);
        await _tts.setPitch(1.08);
        await _tts.setVolume(.92);
        break;
      case LumoVoiceStyle.explain:
        await _tts.setSpeechRate(0.41);
        await _tts.setPitch(1.13);
        await _tts.setVolume(1.0);
        break;
      case LumoVoiceStyle.whisper:
        await _tts.setSpeechRate(0.36);
        await _tts.setPitch(1.04);
        await _tts.setVolume(.82);
        break;
      case LumoVoiceStyle.calm:
        await _tts.setSpeechRate(0.44);
        await _tts.setPitch(1.16);
        await _tts.setVolume(1.0);
        break;
    }
  }

  String _shapeForSpeech(String text, LumoVoiceStyle style) {
    var shaped = text
        .replaceAll('!', '! ')
        .replaceAll('. ', '.  ')
        .replaceAll('? ', '?  ')
        .replaceAll('XP', 'Ix Peh')
        .replaceAll('Lumo', 'Luumo');
    if (style == LumoVoiceStyle.celebrate) {
      shaped = shaped.replaceFirst(RegExp(r'^(Sehr gut|Super|Klasse|Richtig|Fuchsfreude)'), 'Juhu. ${RegExp(r'^(Sehr gut|Super|Klasse|Richtig|Fuchsfreude)').firstMatch(shaped)?.group(0) ?? ''}');
    }
    if (style == LumoVoiceStyle.comfort && !shaped.startsWith('Ganz ruhig')) {
      shaped = 'Ganz ruhig.  $shaped';
    }
    return shaped.trim();
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    status.value = VoiceStatus.idle;
  }

  Future<void> test() => speak('Hallo! Ich bin Lumo, dein Lernfuchs. Ich spreche jetzt ruhiger, freundlicher und mit kleinen Pausen.', style: LumoVoiceStyle.explain);
}
