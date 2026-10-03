import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lumo_child_speech_normalizer.dart';

/// Eine installierte Sprachausgabe-Stimme, so wie Android sie meldet.
///
/// Android liefert neben Name und Sprache auch die Qualitaet, ob Internet
/// noetig ist und ob die Stimme ueberhaupt heruntergeladen ist. Diese Werte
/// sind verlaesslicher als Vermutungen anhand des Stimmnamens.
@immutable
class LumoVoiceOption {
  const LumoVoiceOption({
    required this.name,
    required this.locale,
    this.quality = '',
    this.networkRequired = false,
    this.installed = true,
  });

  final String name;
  final String locale;

  /// Androids Qualitaetsstufe: 'very high', 'high', 'normal', 'low',
  /// 'very low' oder leer, wenn die Plattform nichts meldet.
  final String quality;
  final bool networkRequired;
  final bool installed;

  static LumoVoiceOption? fromRaw(Object? raw) {
    if (raw is! Map) return null;
    final name = (raw['name'] ?? raw['voice'] ?? '').toString().trim();
    final locale = (raw['locale'] ?? raw['language'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final features = (raw['features'] ?? '').toString().toLowerCase();
    return LumoVoiceOption(
      name: name,
      locale: locale,
      quality: (raw['quality'] ?? '').toString().toLowerCase().trim(),
      networkRequired: raw['network_required']?.toString() == '1',
      installed: !features.contains('notinstalled'),
    );
  }

  bool get isGerman {
    final l = locale.toLowerCase();
    final n = name.toLowerCase();
    return l.startsWith('de') || n.contains('german') || n.contains('deutsch');
  }

  String get regionLabel {
    final l = locale.toLowerCase().replaceAll('_', '-');
    if (l.startsWith('de-at')) return 'Österreich';
    if (l.startsWith('de-ch')) return 'Schweiz';
    if (l.startsWith('de-de')) return 'Deutschland';
    return 'Deutsch';
  }

  String get qualityLabel {
    switch (quality) {
      case 'very high':
        return 'sehr gute Qualität';
      case 'high':
        return 'gute Qualität';
      case 'normal':
        return 'normale Qualität';
      case 'low':
      case 'very low':
        return 'einfache Qualität';
      default:
        return '';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LumoVoiceOption && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);
}

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

  static const String _voiceNamePrefKey = 'lumo_voice_name';
  static const String _voiceLocalePrefKey = 'lumo_voice_locale';

  /// Alle installierten deutschen Stimmen, die beste zuerst.
  /// Liefert eine leere Liste, wenn die Plattform keine Stimmen meldet.
  Future<List<LumoVoiceOption>> germanVoices() async {
    try {
      return rankGermanVoices(await _tts.getVoices);
    } catch (e) {
      if (kDebugMode) debugPrint('[LumoVoice] Voice scan failed: $e');
      return const <LumoVoiceOption>[];
    }
  }

  /// Von Eltern oder Kind ausgewaehlte Stimme (Name), oder null fuer
  /// automatische Auswahl.
  Future<String?> savedVoiceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_voiceNamePrefKey);
    } catch (_) {
      return null;
    }
  }

  /// Waehlt eine bestimmte Stimme und merkt sie sich dauerhaft.
  /// `null` setzt zurueck auf die automatisch beste Stimme.
  /// Gespeichert wird nur, was Android tatsaechlich setzen konnte, damit
  /// nach einem Neustart keine nicht vorhandene Stimme gesucht wird.
  Future<bool> chooseVoice(LumoVoiceOption? option) async {
    await stop();
    if (option == null) {
      await _persistVoice(null);
      _voiceSelected = false;
      _selectedVoiceName = null;
      _selectedLocale = null;
      await _selectBestGermanVoice();
      return true;
    }
    final applied = await _useVoice(option);
    if (applied) await _persistVoice(option);
    return applied;
  }

  Future<void> _persistVoice(LumoVoiceOption? option) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (option == null) {
        await prefs.remove(_voiceNamePrefKey);
        await prefs.remove(_voiceLocalePrefKey);
      } else {
        await prefs.setString(_voiceNamePrefKey, option.name);
        await prefs.setString(_voiceLocalePrefKey, option.locale);
      }
    } catch (_) {
      // Ohne Speicher gilt die Wahl nur bis zum Neustart.
    }
  }

  Future<bool> _useVoice(LumoVoiceOption option) async {
    try {
      final result = await _tts.setVoice({'name': option.name, 'locale': option.locale});
      if (result == 0) return false;
      _selectedVoiceName = option.name;
      _selectedLocale = option.locale;
      _voiceSelected = true;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[LumoVoice] setVoice failed: $e');
      return false;
    }
  }

  /// Sortiert die rohen Plattform-Stimmen: nur deutsche, nur installierte,
  /// beste zuerst. Gleich bewertete Stimmen bleiben stabil nach Name sortiert.
  @visibleForTesting
  static List<LumoVoiceOption> rankGermanVoices(Object? rawVoices) {
    if (rawVoices is! List) return const <LumoVoiceOption>[];
    final seen = <LumoVoiceOption>{};
    final voices = <LumoVoiceOption>[];
    for (final raw in rawVoices) {
      final option = LumoVoiceOption.fromRaw(raw);
      if (option == null || !option.isGerman || !option.installed) continue;
      if (seen.add(option)) voices.add(option);
    }
    voices.sort((a, b) {
      final byScore = scoreVoice(b).compareTo(scoreVoice(a));
      return byScore != 0 ? byScore : a.name.compareTo(b.name);
    });
    return voices;
  }

  Future<void> _selectBestGermanVoice() async {
    if (_voiceSelected) return;

    final fallbackLanguages = <String>['de-AT', 'de-DE', 'de'];

    final voices = await germanVoices();
    if (voices.isNotEmpty) {
      // Gespeicherte Lieblingsstimme zuerst, danach die beste verfuegbare.
      final savedName = await savedVoiceName();
      final ordered = <LumoVoiceOption>[
        ...voices.where((v) => v.name == savedName),
        ...voices.where((v) => v.name != savedName),
      ];
      for (final candidate in ordered) {
        if (await _useVoice(candidate)) return;
      }
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

  /// Bewertung fuer die automatische Auswahl. Die von Android gemeldete
  /// Qualitaet zaehlt am meisten; bekannte natuerlich klingende Stimmen und
  /// oesterreichisches Deutsch bekommen einen Bonus, alte robotische
  /// Engines (Pico, eSpeak, Compact) einen Abzug. Stimmen, die Internet
  /// brauchen, sind leicht abgewertet, damit Lumo auch offline spricht.
  @visibleForTesting
  static int scoreVoice(LumoVoiceOption voice) {
    final name = voice.name.toLowerCase();
    final locale = voice.locale.toLowerCase().replaceAll('_', '-');
    var score = 0;

    if (locale.startsWith('de-at')) {
      score += 30;
    } else if (locale.startsWith('de-de')) {
      score += 20;
    } else if (locale.startsWith('de')) {
      score += 10;
    }

    switch (voice.quality) {
      case 'very high':
        score += 120;
        break;
      case 'high':
        score += 80;
        break;
      case 'low':
        score -= 60;
        break;
      case 'very low':
        score -= 100;
        break;
    }

    for (final marker in const ['neural', 'natural', 'wavenet', 'enhanced', 'premium']) {
      if (name.contains(marker)) {
        score += 60;
        break;
      }
    }
    for (final known in const ['marlene', 'vicki', 'hedda', 'katja', 'anna', 'petra', 'helena']) {
      if (name.contains(known)) {
        score += 40;
        break;
      }
    }
    if (name.contains('female') || name.contains('frau')) score += 30;

    for (final robotic in const ['pico', 'espeak', 'compact', 'legacy']) {
      if (name.contains(robotic)) {
        score -= 80;
        break;
      }
    }
    if (voice.networkRequired) score -= 10;

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

  // Der Begruessungs-Stil stellt selbst "Hallo." voran, deshalb beginnt der
  // Testsatz ohne eigene Begruessung (vorher: "Hallo. Hallo! Ich bin ...").
  Future<void> test() => speak(
        'Ich bin Lumo, dein Lernfuchs. Klingt meine Stimme schön für dich?',
        style: VoiceStyle.greeting,
      );
}

enum VoiceStyle { warm, greeting, explain, celebrate, comfort, question }

enum VoiceStatus { idle, speaking, error }
