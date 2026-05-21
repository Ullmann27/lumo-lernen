// ════════════════════════════════════════════════════════════════════════
// LUMO LIVE PRO — Voice + Foto-Quiz mit Lumo-Companion
// ════════════════════════════════════════════════════════════════════════
// Premium-Wert fuer 10 Euro/Monat Abo.
//
// 3 MODI:
//   1. WORT-MAGIE: Kind sagt Wort -> Lumo malt + erklaert
//   2. FOTO-QUIZ:  Kind macht Foto -> Lumo stellt 3 Fragen drum
//   3. SAFARI:     Lumo zeigt Tier -> Kind muss raten und sprechen
// ════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../app/app_state.dart';
import '../../core/lumo_brain.dart';
import '../../core/lumo_cosmos.dart';
import '../../core/lumo_image_generator.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/lumo_mirror.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../../widgets/premium/lumo_premium_card.dart';
import '../../widgets/premium/lumo_reward_burst.dart';

enum LiveMode {
  wordMagic,  // Sprich ein Wort -> Bild + Erklaerung
  photoQuiz,  // Foto -> 3 Fragen
  safari,     // Lumo zeigt Tier -> Kind raet
}

extension LiveModeMeta on LiveMode {
  String get title {
    switch (this) {
      case LiveMode.wordMagic: return 'Wort-Magie';
      case LiveMode.photoQuiz: return 'Foto-Quiz';
      case LiveMode.safari: return 'Tier-Safari';
    }
  }

  String get subtitle {
    switch (this) {
      case LiveMode.wordMagic:
        return 'Sag ein Wort - ich male es!';
      case LiveMode.photoQuiz:
        return 'Mach ein Foto - ich frage dich!';
      case LiveMode.safari:
        return 'Erkennst du das Tier?';
    }
  }

  IconData get icon {
    switch (this) {
      case LiveMode.wordMagic: return Icons.auto_fix_high_rounded;
      case LiveMode.photoQuiz: return Icons.camera_alt_rounded;
      case LiveMode.safari: return Icons.pets_rounded;
    }
  }
}

class LumoLiveProScreen extends StatefulWidget {
  const LumoLiveProScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoLiveProScreen> createState() => _LumoLiveProScreenState();
}

class _LumoLiveProScreenState extends State<LumoLiveProScreen> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();
  final _rng = math.Random();

  LiveMode _mode = LiveMode.wordMagic;
  bool _sttReady = false;
  bool _listening = false;
  String _recognized = '';
  String? _generatedImageUrl;
  String? _capturedImagePath;
  String? _lumoMessage;
  LumoMirrorMood _mood = LumoMirrorMood.idle;
  bool _speaking = false;

  // Safari-Modus state
  String? _safariAnimal;
  int _safariScore = 0;
  int _safariRound = 0;
  int _safariTotal = 0;

  // Photo-Quiz state
  String? _photoQuizSubject;
  int _photoQuizQuestionIdx = 0;
  final List<String> _photoQuestions = [
    'Was siehst du da auf dem Foto?',
    'Welche Farbe hat das?',
    'Wo findet man so etwas?',
  ];

  // Lumo redet
  bool _lumoCurrentlySpeaking = false;

  static const List<String> _safariAnimals = [
    'Loewe', 'Elefant', 'Giraffe', 'Zebra', 'Affe',
    'Tiger', 'Baer', 'Wolf', 'Eule', 'Pinguin',
    'Delfin', 'Schmetterling', 'Hund', 'Katze',
    'Pferd', 'Kuh', 'Schaf', 'Schwein',
  ];

  @override
  void initState() {
    super.initState();
    _initStt();
    // Mood Wechsel demo
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _mood = LumoMirrorMood.happy);
        _speak('Hallo! Was sollen wir heute spielen?');
      }
    });
  }

  Future<void> _initStt() async {
    try {
      final ok = await _stt.initialize(
        onError: (e) => debugPrint('STT-Error: ${e.errorMsg}'),
        onStatus: (s) {
          if (s == 'notListening' && _listening) {
            setState(() => _listening = false);
          }
        },
      );
      if (mounted) setState(() => _sttReady = ok);
    } catch (e) {
      debugPrint('STT init error: $e');
    }
  }

  void _switchMode(LiveMode m) {
    setState(() {
      _mode = m;
      _recognized = '';
      _generatedImageUrl = null;
      _capturedImagePath = null;
      _lumoMessage = null;
      _safariAnimal = null;
      _safariScore = 0;
      _safariRound = 0;
      _safariTotal = 0;
      _photoQuizSubject = null;
      _photoQuizQuestionIdx = 0;
      _mood = LumoMirrorMood.curious;
    });
    HapticFeedback.lightImpact();
    if (m == LiveMode.safari) {
      _nextSafariAnimal();
    } else if (m == LiveMode.wordMagic) {
      _speak('Sag mir ein Wort und ich male es fuer dich!');
    } else if (m == LiveMode.photoQuiz) {
      _speak('Mach ein Foto und ich stelle dir kluge Fragen!');
    }
  }

  void _speak(String text) {
    setState(() {
      _lumoMessage = text;
      _speaking = true;
      _lumoCurrentlySpeaking = true;
    });
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
    // Lippen ca 3s lang animieren
    Future.delayed(Duration(milliseconds: 80 * text.length.clamp(20, 80)), () {
      if (mounted) {
        setState(() {
          _speaking = false;
          _lumoCurrentlySpeaking = false;
        });
      }
    });
  }

  Future<void> _startListening() async {
    if (!_sttReady) {
      _speak('Ich brauch dein Mikrofon - bitte erlauben!');
      return;
    }
    if (_listening) return;
    HapticFeedback.lightImpact();
    setState(() {
      _listening = true;
      _recognized = '';
      _mood = LumoMirrorMood.curious;
    });
    try {
      await _stt.listen(
        localeId: 'de_DE',
        listenFor: const Duration(seconds: 8),
        onResult: (r) {
          if (mounted) {
            setState(() => _recognized = r.recognizedWords);
            if (r.finalResult) _onSpeechDone();
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
      _speak('Hmm, ich hab nichts gehoert. Probier nochmal!');
      setState(() => _mood = LumoMirrorMood.sad);
      return;
    }
    // Mode-spezifische Behandlung
    switch (_mode) {
      case LiveMode.wordMagic: await _handleWordMagic(); break;
      case LiveMode.photoQuiz: await _handlePhotoQuiz(); break;
      case LiveMode.safari: await _handleSafariAnswer(); break;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // MODE 1: WORT-MAGIE
  // ────────────────────────────────────────────────────────────────
  Future<void> _handleWordMagic() async {
    final word = _recognized.trim();
    final url = LumoImageGenerator.instance.buildSafeImageUrl(word);
    final reply = LumoBrain.instance
        .ask('Was ist ein $word?', topicId: 's1_tiere');
    setState(() {
      _generatedImageUrl = url;
      _mood = LumoMirrorMood.happy;
    });
    widget.appState.addStars(1);
    widget.appState.addXp(5);
    CosmosWorld.instance.grantReward(
      subjectId: 'live_word', isMath: false, isPerfect: false,
    );
    _speak(reply.text);
  }

  // ────────────────────────────────────────────────────────────────
  // MODE 2: FOTO-QUIZ
  // ────────────────────────────────────────────────────────────────
  Future<void> _capturePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60, maxWidth: 800,
      );
      if (photo == null) return;
      setState(() {
        _capturedImagePath = photo.path;
        _photoQuizQuestionIdx = 0;
        _mood = LumoMirrorMood.curious;
      });
      _speak(_photoQuestions[0]);
    } catch (e) {
      _speak('Das Foto hat nicht geklappt. Probier nochmal!');
    }
  }

  Future<void> _handlePhotoQuiz() async {
    // Nach jeder Antwort: naechste Frage oder Ende
    setState(() => _photoQuizSubject = _recognized);
    widget.appState.addStars(1);
    widget.appState.addXp(5);
    CosmosWorld.instance.grantReward(
      subjectId: 'live_photo', isMath: false, isPerfect: false,
    );
    if (_photoQuizQuestionIdx + 1 < _photoQuestions.length) {
      _photoQuizQuestionIdx++;
      setState(() => _mood = LumoMirrorMood.happy);
      await Future.delayed(const Duration(milliseconds: 1500));
      _speak(_photoQuestions[_photoQuizQuestionIdx]);
    } else {
      setState(() => _mood = LumoMirrorMood.cheer);
      _speak('Super! Du hast alle Fragen beantwortet! '
          'Du hast 3 Sterne verdient!');
      if (mounted) showLumoRewardBurst(context, stars: 3, xp: 15);
      widget.appState.addStars(2);
      widget.appState.addXp(10);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // MODE 3: TIER-SAFARI
  // ────────────────────────────────────────────────────────────────
  void _nextSafariAnimal() {
    _safariRound++;
    _safariTotal = _safariRound;
    final animal = _safariAnimals[_rng.nextInt(_safariAnimals.length)];
    final url = LumoImageGenerator.instance
        .buildSafeImageUrl('cute $animal photo style');
    setState(() {
      _safariAnimal = animal;
      _generatedImageUrl = url;
      _recognized = '';
      _mood = LumoMirrorMood.curious;
    });
    _speak('Welches Tier siehst du? Sag mir den Namen!');
  }

  Future<void> _handleSafariAnswer() async {
    if (_safariAnimal == null) return;
    final said = _recognized.toLowerCase().trim();
    final correct = _safariAnimal!.toLowerCase();
    final isRight = said.contains(correct) ||
        correct.contains(said) ||
        _levenshtein(said, correct) <= 2;
    if (isRight) {
      _safariScore++;
      setState(() => _mood = LumoMirrorMood.cheer);
      _speak('Richtig! Das ist ein $_safariAnimal!');
      widget.appState.addStars(2);
      widget.appState.addXp(10);
      CosmosWorld.instance.grantReward(
        subjectId: 'live_safari', isMath: false, isPerfect: true,
      );
      if (mounted) showLumoRewardBurst(context, stars: 2, xp: 10);
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) _nextSafariAnimal();
    } else {
      setState(() => _mood = LumoMirrorMood.sad);
      _speak('Hmm, nicht ganz. Es ist ein $_safariAnimal. Versuch noch eins!');
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) _nextSafariAnimal();
    }
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final dp = List.generate(
        a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) dp[i][0] = i;
    for (int j = 0; j <= b.length; j++) dp[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce(math.min);
      }
    }
    return dp[a.length][b.length];
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
              _buildModePicker(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(LumoTokens.space16),
                  child: Column(
                    children: [
                      // Lumo-Mirror gross zentriert
                      Center(
                        child: LumoMirror(
                          mood: _mood,
                          size: 160,
                          isSpeaking: _speaking,
                        ),
                      ),
                      const SizedBox(height: LumoTokens.space12),
                      // Lumo-Nachricht
                      if (_lumoMessage != null)
                        LumoPremiumCard(
                          gradient: LumoTokens.colors.heroLila,
                          child: Row(children: [
                            const Text('🦊',
                                style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_lumoMessage!,
                                  style: LumoTokens.typo.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        ),
                      const SizedBox(height: LumoTokens.space12),
                      // Erkanntes Wort
                      if (_recognized.isNotEmpty)
                        LumoPremiumCard(
                          gradient: LumoTokens.colors.heroOrange,
                          child: Column(children: [
                            Text('Du hast gesagt:',
                                style: LumoTokens.typo.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.85))),
                            Text('"$_recognized"',
                                style: LumoTokens.typo.headlineMedium
                                    .copyWith(color: Colors.white)),
                          ]),
                        ),
                      if (_listening)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(children: [
                            Icon(Icons.mic_rounded,
                                color: LumoTokens.colors.lumoOrange),
                            const SizedBox(width: 8),
                            Text('Ich hoere...',
                                style: LumoTokens.typo.titleMedium),
                          ]),
                        ),
                      const SizedBox(height: LumoTokens.space12),
                      // Safari-Score
                      if (_mode == LiveMode.safari && _safariRound > 0)
                        _buildSafariScore(),
                      // Generiertes / Captured Bild
                      if (_generatedImageUrl != null || _capturedImagePath != null)
                        _buildImagePane(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lumo LIVE ✨',
                    style: LumoTokens.typo.headlineMedium),
                Text(_mode.subtitle,
                    style: LumoTokens.typo.bodyMedium.copyWith(
                        color: LumoTokens.colors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LumoTokens.space12),
      child: Row(
        children: LiveMode.values.map((m) {
          final active = m == _mode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _switchMode(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: active ? LumoTokens.colors.heroOrange : null,
                    color: active ? null : Colors.white,
                    borderRadius: LumoTokens.brMedium,
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : LumoTokens.colors.outline,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, color: active
                          ? Colors.white
                          : LumoTokens.colors.lumoOrange, size: 22),
                      const SizedBox(height: 2),
                      Text(m.title,
                          style: LumoTokens.typo.labelMedium.copyWith(
                              color: active
                                  ? Colors.white
                                  : LumoTokens.colors.textDark),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSafariScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LumoTokens.colors.heroGold,
        borderRadius: LumoTokens.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white),
          const SizedBox(width: 4),
          Text('$_safariScore von $_safariTotal',
              style: LumoTokens.typo.titleMedium.copyWith(
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildImagePane() {
    final url = _generatedImageUrl;
    final path = _capturedImagePath;
    return AspectRatio(
      aspectRatio: 1,
      child: LumoPremiumCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: LumoTokens.brLarge,
          child: url != null
              ? Image.network(
                  url,
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
                )
              : path != null
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : Container(
                      color: LumoTokens.colors.cremeDeep,
                      alignment: Alignment.center,
                      child: const Text('📷',
                          style: TextStyle(fontSize: 80)),
                    ),
        ),
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
                  onPressed: _listening || _lumoCurrentlySpeaking
                      ? null
                      : _startListening,
                  icon: Icon(_listening
                      ? Icons.hearing_rounded
                      : Icons.mic_rounded, size: 28),
                  label: Text(_listening ? 'Hoere...' : 'Sprechen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumoTokens.colors.lumoOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        LumoTokens.colors.outline.withOpacity(0.5),
                    textStyle: LumoTokens.typo.titleLarge,
                    shape: RoundedRectangleBorder(
                        borderRadius: LumoTokens.brLarge),
                  ),
                ),
              ),
            ),
            if (_mode == LiveMode.photoQuiz) ...[
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
            if (_mode == LiveMode.safari && _safariAnimal != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                height: 64,
                child: ElevatedButton(
                  onPressed: _nextSafariAnimal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumoTokens.colors.gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: LumoTokens.brLarge),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.skip_next_rounded, size: 28),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
