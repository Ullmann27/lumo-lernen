// ════════════════════════════════════════════════════════════════════════
// LUMO LIVE — Sprich oder Fotografiere, Lumo lernt mit dir!
// ════════════════════════════════════════════════════════════════════════
// Vorschlag 1 aus Heinz' Auswahl: Speech + Photo Lern-Magie.
//
// MVP-Features:
//   1. Mikrofon: Kind sagt ein Wort -> STT erkennt -> Pollinations malt
//      -> Lumo erklaert was es ist und stellt Frage
//   2. Foto: Kind fotografiert Gegenstand -> Lumo zeigt Bild + fragt
//      'Was siehst du?' Kind antwortet via Mikro oder Multi-Choice.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../app/app_state.dart';
import '../../core/lumo_brain.dart';
import '../../core/lumo_image_generator.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/lumo_mirror.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../../widgets/premium/lumo_premium_card.dart';

class LumoLiveScreen extends StatefulWidget {
  const LumoLiveScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoLiveScreen> createState() => _LumoLiveScreenState();
}

class _LumoLiveScreenState extends State<LumoLiveScreen> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();

  bool _sttReady = false;
  bool _listening = false;
  String _recognized = '';
  String? _generatedImageUrl;
  String? _lumoExplanation;
  String? _capturedImagePath;
  LumoMirrorMood _mood = LumoMirrorMood.idle;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    try {
      final ok = await _stt.initialize(
        onError: (e) => debugPrint('STT-Error: $e'),
        onStatus: (s) => debugPrint('STT-Status: $s'),
      );
      if (mounted) setState(() => _sttReady = ok);
    } catch (e) {
      debugPrint('STT init error: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_sttReady) {
      _speakAndShow(
          'Sag mir bitte was ich auf deinem Handy einstellen darf, '
          'dann kann ich dich hoeren!');
      return;
    }
    setState(() {
      _listening = true;
      _recognized = '';
      _generatedImageUrl = null;
      _lumoExplanation = null;
      _mood = LumoMirrorMood.curious;
    });
    try {
      await _stt.listen(
        localeId: 'de_DE',
        listenFor: const Duration(seconds: 6),
        onResult: (r) {
          setState(() => _recognized = r.recognizedWords);
          if (r.finalResult) {
            _onSpeechDone();
          }
        },
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      setState(() => _listening = false);
    }
  }

  Future<void> _onSpeechDone() async {
    setState(() {
      _listening = false;
      _mood = LumoMirrorMood.think;
    });
    if (_recognized.isEmpty) {
      _speakAndShow('Hmm, ich hab nichts gehoert. Versuch nochmal!');
      setState(() => _mood = LumoMirrorMood.idle);
      return;
    }
    // Bild generieren basierend auf gesagtem Wort
    final url = LumoImageGenerator.instance
        .buildSafeImageUrl(_recognized);
    // Lumo-Brain fragt nach Erklaerung
    final reply = LumoBrain.instance
        .ask('Was ist ein ${_recognized}?', topicId: 's1_tiere');
    final explanation = reply.text;

    setState(() {
      _generatedImageUrl = url;
      _lumoExplanation = explanation;
      _mood = LumoMirrorMood.happy;
    });
    _speakAndShow(explanation);
  }

  Future<void> _capturePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 800,
      );
      if (photo == null) return;
      setState(() {
        _capturedImagePath = photo.path;
        _mood = LumoMirrorMood.curious;
      });
      _speakAndShow('Tolles Foto! Was siehst du da? '
          'Sag es mir oder druecke das Mikrofon!');
    } catch (e) {
      _speakAndShow('Das Foto hat nicht geklappt. '
          'Versuch nochmal!');
    }
  }

  void _speakAndShow(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _reset() {
    setState(() {
      _recognized = '';
      _generatedImageUrl = null;
      _lumoExplanation = null;
      _capturedImagePath = null;
      _mood = LumoMirrorMood.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(LumoTokens.space16),
                  child: Column(
                    children: [
                      // Lumo-Mirror gross zentriert
                      Center(
                        child: LumoMirror(
                          mood: _mood,
                          size: 180,
                          isSpeaking: _listening,
                        ),
                      ),
                      const SizedBox(height: LumoTokens.space16),
                      // Recognized Text / Hint
                      if (_recognized.isNotEmpty)
                        LumoPremiumCard(
                          gradient: LumoTokens.colors.heroLila,
                          child: Column(
                            children: [
                              Text('Du hast gesagt:',
                                  style: LumoTokens.typo.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.85))),
                              const SizedBox(height: 4),
                              Text('"$_recognized"',
                                  style: LumoTokens.typo.headlineMedium
                                      .copyWith(color: Colors.white)),
                            ],
                          ),
                        )
                      else if (!_listening)
                        LumoPremiumCard(
                          child: Column(
                            children: [
                              Text('Probier es aus!',
                                  style: LumoTokens.typo.headlineSmall),
                              const SizedBox(height: 8),
                              Text(
                                  'Druecke das Mikro und sag ein Wort '
                                  '(z.B. "Hund") - ich male es fuer dich!',
                                  style: LumoTokens.typo.bodyMedium,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      if (_listening)
                        LumoPremiumCard(
                          gradient: LumoTokens.colors.heroOrange,
                          child: Column(
                            children: [
                              const Icon(Icons.mic_rounded,
                                  color: Colors.white, size: 48),
                              const SizedBox(height: 8),
                              Text('Ich hoere zu...',
                                  style: LumoTokens.typo.titleLarge
                                      .copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                      const SizedBox(height: LumoTokens.space16),
                      // Generiertes Bild
                      if (_generatedImageUrl != null)
                        AspectRatio(
                          aspectRatio: 1,
                          child: LumoPremiumCard(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: LumoTokens.brLarge,
                              child: Image.network(
                                _generatedImageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, p) {
                                  if (p == null) return child;
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(),
                                        const SizedBox(height: 12),
                                        Text('Ich male...',
                                            style: LumoTokens.typo.titleMedium),
                                      ],
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text('🎨', style: TextStyle(fontSize: 80)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: LumoTokens.space12),
                      // Captured Photo
                      if (_capturedImagePath != null)
                        AspectRatio(
                          aspectRatio: 1,
                          child: LumoPremiumCard(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: LumoTokens.brLarge,
                              child: Image.asset(
                                _capturedImagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: LumoTokens.colors.cremeDeep,
                                  alignment: Alignment.center,
                                  child: const Text('📷',
                                      style: TextStyle(fontSize: 80)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Lumo's Erklaerung
                      if (_lumoExplanation != null) ...[
                        const SizedBox(height: LumoTokens.space12),
                        LumoPremiumCard(
                          child: Column(
                            children: [
                              Row(children: [
                                const Text('🦊',
                                    style: TextStyle(fontSize: 28)),
                                const SizedBox(width: 8),
                                Text('Lumo sagt:',
                                    style: LumoTokens.typo.titleMedium),
                              ]),
                              const SizedBox(height: 8),
                              Text(_lumoExplanation!,
                                  style: LumoTokens.typo.bodyLarge,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Lumo LIVE',
                style: LumoTokens.typo.headlineMedium),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(LumoTokens.space16),
      decoration: BoxDecoration(
        color: LumoTokens.colors.surface,
        boxShadow: LumoTokens.shadows.floating,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _listening ? null : _startListening,
                  icon: Icon(_listening
                      ? Icons.hearing_rounded
                      : Icons.mic_rounded, size: 28),
                  label: Text(_listening ? 'Hoere...' : 'Sprechen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumoTokens.colors.lumoOrange,
                    foregroundColor: Colors.white,
                    textStyle: LumoTokens.typo.titleLarge,
                    shape: RoundedRectangleBorder(
                        borderRadius: LumoTokens.brLarge),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              height: 64,
              child: ElevatedButton(
                onPressed: _capturePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoTokens.colors.lumoLila,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: LumoTokens.brLarge),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
