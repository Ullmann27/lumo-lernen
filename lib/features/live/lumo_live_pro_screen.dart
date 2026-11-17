// ════════════════════════════════════════════════════════════════════════
// LUMO LIVE PRO — Voice + Foto-Quiz mit Lumo-Companion
// ════════════════════════════════════════════════════════════════════════
// Premium-Wert fuer 10 Euro/Monat Abo.
//
// 3 MODI:
//   1. WORT-MAGIE: Kind sagt Wort -> Lumo erklaert
//   2. FOTO-QUIZ:  Kind macht Foto -> Lumo stellt 3 Fragen drum
//   3. SAFARI:     Lumo zeigt Tier -> Kind muss raten und sprechen
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/lumo_speech_listener.dart';

import '../../app/app_state.dart';
import '../../core/lumo_brain.dart';
import '../../core/lumo_feature_permissions.dart';
import '../../core/lumo_voice.dart';
import '../../core/learning_attempt_id.dart';
import '../../core/lumo_learning_session_contract.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../learning/widgets/learning_question_coach.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/lumo_mirror.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../../widgets/premium/lumo_premium_card.dart';
import '../../widgets/premium/lumo_reward_burst.dart';

enum LiveMode {
  wordMagic, // Sprich ein Wort -> Erklaerung
  photoQuiz, // Foto -> 3 Fragen
  safari, // Lumo zeigt Tier -> Kind raet
}

extension LiveModeMeta on LiveMode {
  String get title {
    switch (this) {
      case LiveMode.wordMagic:
        return 'Wort-Magie';
      case LiveMode.photoQuiz:
        return 'Foto-Quiz';
      case LiveMode.safari:
        return 'Tier-Safari';
    }
  }

  String get subtitle {
    switch (this) {
      case LiveMode.wordMagic:
        return 'Sag ein Wort - ich erkläre es!';
      case LiveMode.photoQuiz:
        return 'Mach ein Foto - ich frage dich!';
      case LiveMode.safari:
        return 'Erkennst du das Tier?';
    }
  }

  IconData get icon {
    switch (this) {
      case LiveMode.wordMagic:
        return Icons.auto_fix_high_rounded;
      case LiveMode.photoQuiz:
        return Icons.camera_alt_rounded;
      case LiveMode.safari:
        return Icons.pets_rounded;
    }
  }
}

class LumoLiveProScreen extends StatefulWidget {
  const LumoLiveProScreen(
      {super.key, required this.appState, this.speechListener, this.voice});
  final LumoAppState appState;
  final LumoSpeechListener? speechListener;
  final LumoVoice? voice;

  @override
  State<LumoLiveProScreen> createState() => _LumoLiveProScreenState();
}

class _LumoLiveProScreenState extends State<LumoLiveProScreen>
    with WidgetsBindingObserver {
  late final LumoSpeechListener _stt =
      widget.speechListener ?? LumoSpeechListener();
  final _bus = LumoCompanionRequests.instance;
  final _session = newLearningAttemptId();
  LumoVoice get _voice => widget.voice ?? LumoVoice.instance;
  final ImagePicker _picker = ImagePicker();
  final _rng = math.Random();

  LiveMode _mode = LiveMode.wordMagic;
  bool _sttReady = false;
  bool _listening = false;
  Object? _photoCaptureOperation;
  bool get _capturingPhoto => _photoCaptureOperation != null;
  int _modeRevision = 0, _interactionEpoch = 0, _captureEpoch = 0;
  late int _profileGeneration;
  int? _voiceRequest;
  bool _foreground = true, _routeCurrent = true, _rewardOpen = false;
  bool _answered = false, _photoComplete = false, _helpUsed = false;
  bool? _lastCorrect;
  String? _lastAnswer;
  Object? _listenOperation, _answerOperation;
  LumoLearningIdentity? _listenIdentity;
  Timer? _greeting, _advance;

  bool get _active =>
      mounted && _foreground && _routeCurrent && !widget.appState.resetting;
  bool get _taskAnswering =>
      !_answered &&
      (_mode != LiveMode.photoQuiz || _capturedImagePath != null) &&
      (_mode != LiveMode.safari || _safariAnimal != null);
  String get _taskId => 'live:$_session:${_mode.name}:$_modeRevision';
  String get _prompt => switch (_mode) {
        LiveMode.wordMagic => 'Sag mir ein Wort und ich erkläre es dir!',
        LiveMode.photoQuiz => _capturedImagePath == null
            ? 'Mach ein Foto und ich stelle dir kluge Fragen!'
            : _extendedPhotoQuestions[_photoQuizQuestionIdx],
        LiveMode.safari => 'Welches Tier siehst du? Sag mir den Namen!',
      };
  String get _helpText => switch (_mode) {
        LiveMode.wordMagic =>
          'Wähle ein Wort, über das du mehr erfahren möchtest. Prüfe deinen Vorschlag vor dem Bestätigen.',
        LiveMode.photoQuiz =>
          'Schau auf dein eigenes Foto. Beschreibe, was du selbst erkennen kannst. Deine Beschreibung wird hier nicht als richtig oder falsch bewertet.',
        LiveMode.safari =>
          'Schau genau auf das gezeigte Tier. Welche Beine, Flügel oder besonderen Merkmale erkennst du?',
      };
  String _recognized = '';
  String? _capturedImagePath;
  String? _lumoMessage;
  LumoMirrorMood _mood = LumoMirrorMood.idle;
  bool _speaking = false;

  // Safari-Modus state
  String? _safariAnimal;
  int _safariScore = 0;
  int _safariRound = 0;
  int _safariTotal = 0;

  // Photo-Quiz state - nutzt jetzt _extendedPhotoQuestions
  int _photoQuizQuestionIdx = 0;

  // Lumo redet
  bool _lumoCurrentlySpeaking = false;

  static const _animalPictures = <String, String>{
    'Loewe': '🦁',
    'Elefant': '🐘',
    'Giraffe': '🦒',
    'Zebra': '🦓',
    'Affe': '🐒',
    'Tiger': '🐯',
    'Baer': '🐻',
    'Wolf': '🐺',
    'Eule': '🦉',
    'Pinguin': '🐧',
    'Delfin': '🐬',
    'Schmetterling': '🦋',
    'Hund': '🐕',
    'Katze': '🐈',
    'Pferd': '🐎',
    'Kuh': '🐄',
    'Schaf': '🐑',
    'Schwein': '🐖',
    'Krokodil': '🐊',
    'Nashorn': '🦏',
    'Flusspferd': '🦛',
    'Kaenguru': '🦘',
    'Koala': '🐨',
    'Faultier': '🦥',
    'Hai': '🦈',
    'Wal': '🐳',
    'Robbe': '🦭',
    'Eisbaer': '🐻‍❄️',
    'Rentier': '🦌',
    'Fuchs': '🦊',
    'Eichhoernchen': '🐿️',
    'Igel': '🦔',
    'Frosch': '🐸',
    'Schildkroete': '🐢',
    'Adler': '🦅',
    'Papagei': '🦜',
    'Biene': '🐝',
    'Marienkaefer': '🐞',
  };

  /// Photo-Quiz-Fragen mit etwas mehr Variation.
  static const List<String> _extendedPhotoQuestions = [
    'Was siehst du da auf dem Foto?',
    'Welche Farbe hat das?',
    'Wo findet man so etwas?',
    'Ist das gross oder klein?',
    'Mag das jemand essen?',
    'Hast du das schon einmal gesehen?',
    'Wie fuehlt sich das an, glaubst du?',
  ];

  @override
  void initState() {
    super.initState();
    _profileGeneration = widget.appState.profileGeneration;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    widget.appState.addListener(_profileChanged);
    _voice.status.addListener(_voiceStatusChanged);
    _stt.addListener(_speechStatusChanged);
    _bus.learningCancellation.addListener(_learningCancelled);
    final revision = _modeRevision;
    _greeting = Timer(const Duration(milliseconds: 600), () {
      if (_active && revision == _modeRevision) {
        setState(() => _mood = LumoMirrorMood.happy);
        unawaited(_speak('Hallo! Was sollen wir heute spielen?'));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!_routeCurrent && !_rewardOpen) _cancelInteraction();
  }

  void _profileChanged() {
    if (_profileGeneration != widget.appState.profileGeneration ||
        widget.appState.resetting) {
      _profileGeneration = widget.appState.profileGeneration;
      _modeRevision++;
      _cancelInteraction();
      if (mounted) {
        setState(() {
          _lastAnswer = null;
          _lastCorrect = null;
          _helpUsed = false;
        });
      }
    }
  }

  void _speechStatusChanged() {
    if (mounted) setState(() => _listening = _active && _stt.listening);
  }

  void _learningCancelled() {
    final identity = _listenIdentity;
    if (identity != null && !_bus.isCurrentLearningIdentity(identity)) {
      _cancelListening();
    }
  }

  bool _isCurrentInteraction(int revision, LearningProfileLease owner) =>
      _active &&
      revision == _modeRevision &&
      widget.appState.isCurrentLearningLease(owner);

  void _cancelListening() {
    ++_captureEpoch;
    _listenOperation = null;
    _listenIdentity = null;
    _listening = false;
    unawaited(_stt.cancel());
  }

  void _cancelOwnedVoice() {
    final request = _voiceRequest;
    _voiceRequest = null;
    if (request != null && _voice.requestRevision == request) {
      unawaited(_voice.stop());
    }
  }

  void _cancelInteraction() {
    ++_interactionEpoch;
    _greeting?.cancel();
    _advance?.cancel();
    _answerOperation = null;
    _cancelListening();
    _cancelOwnedVoice();
  }

  void _switchMode(LiveMode mode) {
    if (!_active) return;
    _cancelInteraction();
    _modeRevision++;
    setState(() {
      _mode = mode;
      _recognized = '';
      _capturedImagePath = null;
      _lumoMessage = null;
      _safariAnimal = null;
      _safariScore = _safariRound = _safariTotal = 0;
      _photoQuizQuestionIdx = 0;
      _answered = _photoComplete = _helpUsed = false;
      _lastAnswer = null;
      _lastCorrect = null;
      _mood = LumoMirrorMood.curious;
    });
    HapticFeedback.lightImpact();
    if (mode == LiveMode.safari) {
      _nextSafariAnimal();
    } else {
      unawaited(_speak(_prompt));
    }
  }

  Future<void> _speak(String text, {LearningProfileLease? owner}) async {
    if (!_active ||
        (owner != null && !widget.appState.isCurrentLearningLease(owner))) {
      return;
    }
    final revision = _modeRevision, epoch = _interactionEpoch;
    setState(() => _lumoMessage = text);
    await widget.appState.ensureSettingsLoaded();
    if (!_active ||
        revision != _modeRevision ||
        epoch != _interactionEpoch ||
        (owner != null && !widget.appState.isCurrentLearningLease(owner)) ||
        !widget.appState.state.settings.voiceEnabled) {
      return;
    }
    final voice = _voice;
    final before = voice.requestRevision;
    final playing = voice.speakAndWait(text);
    final request =
        voice.requestRevision == before ? null : voice.requestRevision;
    _voiceRequest = request;
    try {
      await playing;
    } catch (_) {
      // Local visible feedback remains available when playback is unavailable.
    } finally {
      if (_voiceRequest == request) _voiceRequest = null;
    }
  }

  void _voiceStatusChanged() {
    if (!mounted) return;
    setState(() {
      _speaking = _active && _voice.status.value == VoiceStatus.speaking;
      _lumoCurrentlySpeaking = _active &&
          const {
            VoiceStatus.preparing,
            VoiceStatus.speaking,
            VoiceStatus.paused,
          }.contains(_voice.status.value);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _cancelInteraction();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(_profileChanged);
    _voice.status.removeListener(_voiceStatusChanged);
    _bus.learningCancellation.removeListener(_learningCancelled);
    _stt.removeListener(_speechStatusChanged);
    _cancelInteraction();
    if (widget.speechListener == null) _stt.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!_active ||
        !_taskAnswering ||
        _listening ||
        _listenOperation != null ||
        _capturingPhoto ||
        _answerOperation != null) {
      return;
    }
    final identity = _bus.learningIdentity.value;
    if (identity == null || identity.taskId != _taskId) return;
    final revision = _modeRevision, epoch = ++_captureEpoch;
    final operation = Object();
    _listenOperation = operation;
    _listenIdentity = identity;
    LearningProfileLease? owner;
    bool current() =>
        owner != null &&
        _isCurrentInteraction(revision, owner) &&
        epoch == _captureEpoch &&
        identical(_listenOperation, operation) &&
        _bus.isCurrentLearningIdentity(identity);
    try {
      owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      if (!mounted || !current()) return;
      if (!await LumoFeaturePermissions.microphone(context, widget.appState) ||
          !current()) {
        return;
      }
      if (!_sttReady) {
        final ready = await _stt.initialize();
        if (!current()) return;
        _sttReady = ready;
      }
      if (!_sttReady) {
        unawaited(_speak(_stt.error ??
            'Die Spracheingabe ist nicht bereit. Du kannst deine Antwort tippen.'));
        return;
      }
      _cancelOwnedVoice();
      HapticFeedback.lightImpact();
      setState(() {
        _recognized = '';
        _mood = LumoMirrorMood.curious;
      });
      var finished = false;
      await _stt.startListening(
        onResult: (words) {
          if (!finished && current()) setState(() => _recognized = words);
        },
        onFinalResult: (words) {
          if (finished || !current()) return;
          finished = true;
          // The device final replaces any partial. It only proposes an answer;
          // the existing evaluator runs after an explicit, scoped confirmation.
          final finalWords = words.trim();
          setState(() {
            _recognized = finalWords;
            _listening = false;
            _mood = LumoMirrorMood.think;
          });
          _listenOperation = null;
          _listenIdentity = null;
          if (finalWords.isEmpty) {
            unawaited(_speak('Hmm, ich hab nichts gehoert. Probier nochmal!'));
          } else {
            _bus.requestLearningAction(LumoLearningAction.proposeAnswer,
                identity: identity, candidate: finalWords);
          }
        },
        onNoMatch: () {
          if (finished || !current()) return;
          finished = true;
          _listenOperation = null;
          _listenIdentity = null;
          setState(() => _listening = false);
        },
      );
    } catch (_) {
      if (current()) setState(() => _listening = false);
    } finally {
      if (identical(_listenOperation, operation) &&
          (!_stt.listening && !_stt.starting && !_stt.awaitingFinalResult)) {
        _listenOperation = null;
        _listenIdentity = null;
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _confirmAnswer(String text) async {
    if (!_active || !_taskAnswering || _answerOperation != null) return;
    final identity = _bus.learningIdentity.value;
    if (identity == null || identity.taskId != _taskId) return;
    final operation = Object();
    final revision = _modeRevision, epoch = _interactionEpoch;
    _answerOperation = operation;
    _cancelListening();
    try {
      final owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      if (!_isCurrentInteraction(revision, owner) ||
          epoch != _interactionEpoch ||
          !identical(_answerOperation, operation) ||
          !_bus.isCurrentLearningIdentity(identity)) {
        return;
      }
      setState(() {
        _answered = true;
        _recognized = text;
        _lastAnswer = text;
        _lastCorrect = null;
      });
      switch (_mode) {
        case LiveMode.wordMagic:
          _handleWordMagic(owner, text);
        case LiveMode.photoQuiz:
          _handlePhotoQuiz(owner);
        case LiveMode.safari:
          _handleSafariAnswer(owner, text);
      }
    } catch (_) {
      // A failed or retired profile lease cannot submit or reward an answer.
      if (_active && identical(_answerOperation, operation)) {
        setState(() => _lumoMessage =
            'Deine Antwort wurde noch nicht übernommen. Bitte versuche es erneut.');
      }
    } finally {
      if (mounted && identical(_answerOperation, operation)) {
        setState(() => _answerOperation = null);
      }
    }
  }

  void _handleWordMagic(LearningProfileLease owner, String word) {
    final reply = LumoBrain.instance
        .ask('Was ist ein ${word.trim()}?', topicId: 's1_tiere');
    setState(() => _mood = LumoMirrorMood.happy);
    // Existing participation reward; no correctness claim is inferred.
    widget.appState.addStars(1);
    widget.appState.addXp(5);
    widget.appState.grantCosmosReward(
        lease: owner, subjectId: 'live_word', isMath: false, isPerfect: false);
    unawaited(_speak(reply.text, owner: owner));
  }

  Future<void> _capturePhoto() async {
    if (!_active || _capturingPhoto || _mode != LiveMode.photoQuiz) return;
    final revision = _modeRevision;
    final operation = Object();
    LearningProfileLease? captureOwner;
    setState(() => _photoCaptureOperation = operation);
    try {
      final owner = await widget.appState.captureLearningProfile();
      captureOwner = owner;
      await widget.appState.prepareLearningLease(owner);
      if (!mounted || !_isCurrentInteraction(revision, owner)) return;
      if (!await LumoFeaturePermissions.camera(context, widget.appState) ||
          !_isCurrentInteraction(revision, owner)) {
        return;
      }
      final photo = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 60, maxWidth: 800);
      if (photo == null || !_isCurrentInteraction(revision, owner)) return;
      _cancelInteraction();
      _modeRevision++;
      setState(() {
        _capturedImagePath = photo.path;
        _photoQuizQuestionIdx = 0;
        _answered = _photoComplete = _helpUsed = false;
        _lastAnswer = null;
        _lastCorrect = null;
        _mood = LumoMirrorMood.curious;
      });
      unawaited(_speak(_prompt, owner: owner));
    } catch (_) {
      final owner = captureOwner;
      if (identical(_photoCaptureOperation, operation) &&
          owner != null &&
          _isCurrentInteraction(revision, owner)) {
        unawaited(_speak('Das Foto hat nicht geklappt. Probier nochmal!',
            owner: owner));
      }
    } finally {
      if (mounted && identical(_photoCaptureOperation, operation)) {
        setState(() => _photoCaptureOperation = null);
      }
    }
  }

  void _scheduleAdvance(
      Duration duration, LearningProfileLease owner, VoidCallback next) {
    final revision = _modeRevision, epoch = _interactionEpoch;
    _advance?.cancel();
    _advance = Timer(duration, () {
      if (_isCurrentInteraction(revision, owner) &&
          epoch == _interactionEpoch) {
        next();
      }
    });
  }

  void _showReward({required int stars, required int xp}) {
    _rewardOpen = true;
    unawaited(showLumoRewardBurst(context, stars: stars, xp: xp)
        .whenComplete(() => _rewardOpen = false));
  }

  void _handlePhotoQuiz(LearningProfileLease owner) {
    if (_mode != LiveMode.photoQuiz || _capturedImagePath == null) return;
    // Preserve the existing participation reward without declaring the unseen
    // content of a child's photograph correct or incorrect.
    widget.appState.addStars(1);
    widget.appState.addXp(5);
    widget.appState.grantCosmosReward(
        lease: owner, subjectId: 'live_photo', isMath: false, isPerfect: false);
    if (_photoQuizQuestionIdx + 1 < _extendedPhotoQuestions.length) {
      setState(() => _mood = LumoMirrorMood.happy);
      _scheduleAdvance(
          const Duration(milliseconds: 1500), owner, _nextPhotoQuestion);
    } else {
      setState(() {
        _photoComplete = true;
        _mood = LumoMirrorMood.cheer;
      });
      unawaited(_speak('Du hast alle Foto-Fragen beantwortet!', owner: owner));
      _showReward(stars: 3, xp: 15);
      widget.appState.addStars(2);
      widget.appState.addXp(10);
    }
  }

  void _nextPhotoQuestion() {
    if (!_active ||
        _mode != LiveMode.photoQuiz ||
        !_answered ||
        _photoQuizQuestionIdx + 1 >= _extendedPhotoQuestions.length) {
      return;
    }
    _cancelInteraction();
    _modeRevision++;
    setState(() {
      _photoQuizQuestionIdx++;
      _answered = _helpUsed = false;
      _recognized = '';
      _lastAnswer = null;
      _lastCorrect = null;
    });
    unawaited(_speak(_prompt));
  }

  void _newWord() {
    if (!_active) return;
    _cancelInteraction();
    _modeRevision++;
    setState(() {
      _answered = _helpUsed = false;
      _recognized = '';
      _lastAnswer = null;
      _lastCorrect = null;
    });
    unawaited(_speak(_prompt));
  }

  void _nextSafariAnimal() {
    if (!_active || _mode != LiveMode.safari) return;
    _cancelInteraction();
    _modeRevision++;
    _safariRound++;
    _safariTotal = _safariRound;
    final animals = _animalPictures.keys.toList(growable: false);
    final animal = animals[_rng.nextInt(animals.length)];
    setState(() {
      _safariAnimal = animal;
      _recognized = '';
      _answered = _helpUsed = false;
      _lastAnswer = null;
      _lastCorrect = null;
      _mood = LumoMirrorMood.curious;
    });
    unawaited(_speak(_prompt));
  }

  void _handleSafariAnswer(LearningProfileLease owner, String answer) {
    if (_safariAnimal == null) return;
    final said = answer.toLowerCase().trim();
    final correct = _safariAnimal!.toLowerCase();
    // Existing Safari evaluator and its length-dependent tolerance remain the
    // sole correctness authority, reached only by confirmed final input.
    final tol = (correct.length / 4).floor().clamp(1, 3);
    final isRight = said.contains(correct) ||
        correct.contains(said) ||
        _levenshtein(said, correct) <= tol;
    setState(() => _lastCorrect = isRight);
    if (isRight) {
      _safariScore++;
      setState(() => _mood = LumoMirrorMood.cheer);
      unawaited(_speak('Richtig! Das ist ein $_safariAnimal!', owner: owner));
      widget.appState.addStars(2);
      widget.appState.addXp(10);
      widget.appState.grantCosmosReward(
          lease: owner,
          subjectId: 'live_safari',
          isMath: false,
          isPerfect: true);
      _showReward(stars: 2, xp: 10);
      _scheduleAdvance(
          const Duration(milliseconds: 2200), owner, _nextSafariAnimal);
    } else {
      setState(() => _mood = LumoMirrorMood.sad);
      unawaited(_speak(
          'Hmm, nicht ganz. Es ist ein $_safariAnimal. Versuch noch eins!',
          owner: owner));
      _scheduleAdvance(
          const Duration(milliseconds: 2500), owner, _nextSafariAnimal);
    }
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final dp =
        List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }
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
                  child: LearningQuestionCoach(
                    key: ValueKey('live-coach:$_profileGeneration'),
                    appState: widget.appState,
                    taskId: _taskId,
                    ownerSection: 'live',
                    activity: 'live-${_mode.name}',
                    subject:
                        _mode == LiveMode.safari ? 'Sachunterricht' : 'Deutsch',
                    unit: _mode.title,
                    prompt: _prompt,
                    choices: const {},
                    answering: _taskAnswering,
                    active: !widget.appState.resetting,
                    lastAnswer: _lastAnswer,
                    lastCorrect: _lastCorrect,
                    helpUsed: _helpUsed,
                    helpText: _helpUsed ? _helpText : null,
                    visibleExplanation: _answered && _mode == LiveMode.wordMagic
                        ? _lumoMessage
                        : null,
                    onHint: () => setState(() => _helpUsed = true),
                    onConfirmedAnswer: _confirmAnswer,
                    voice: widget.voice,
                    beforeInteraction: _cancelInteraction,
                    onStop: _cancelInteraction,
                    child: Column(
                      children: [
                        // Original-Lumo remains the lead character; the expressive
                        // mirror is a live reaction indicator, not the sole mascot.
                        Center(
                          child: SizedBox(
                            height: 195,
                            width: 260,
                            child:
                                Stack(alignment: Alignment.center, children: [
                              const LumoFoxPose(
                                  pose: LumoDesignFoxPose.armsOpen, size: 178),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: LumoMirror(
                                    mood: _mood,
                                    size: 105,
                                    isSpeaking: _speaking),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          key: const ValueKey('live-mode-instruction'),
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF16395E), Color(0xFF4A3F87)]),
                            border: Border.all(
                                color:
                                    const Color(0xFF7FD9F1).withOpacity(.65)),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_mode.title,
                                  style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(_mode.subtitle,
                                  style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFFE2F2FD))),
                            ],
                          ),
                        ),
                        const SizedBox(height: LumoTokens.space12),
                        // Lumo-Nachricht
                        if (_lumoMessage != null)
                          LumoPremiumCard(
                            gradient: LumoTokens.colors.heroLila,
                            child: Row(children: [
                              const Text('🦊', style: TextStyle(fontSize: 28)),
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
                              Text(
                                  _listening
                                      ? 'Ich höre …'
                                      : (_answered
                                          ? 'Deine bestätigte Antwort:'
                                          : 'Dein Antwortvorschlag:'),
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
                        // Aufgenommenes Foto oder vorhandenes Safari-Tier
                        if (_capturedImagePath != null ||
                            (_mode == LiveMode.safari && _safariAnimal != null))
                          _buildImagePane(),
                      ],
                    ),
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
                Text('Lumo LIVE ✨', style: LumoTokens.typo.headlineMedium),
                Text(_mode.subtitle,
                    style: LumoTokens.typo.bodyMedium
                        .copyWith(color: LumoTokens.colors.textMuted)),
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
                      Icon(m.icon,
                          color: active
                              ? Colors.white
                              : LumoTokens.colors.lumoOrange,
                          size: 22),
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
              style: LumoTokens.typo.titleMedium.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildImagePane() {
    final path = _capturedImagePath;
    if (_mode == LiveMode.safari && _safariAnimal != null) {
      return AspectRatio(
        aspectRatio: 1,
        child: LumoPremiumCard(
            child: Center(
          child: Text(_animalPictures[_safariAnimal]!,
              style: const TextStyle(fontSize: 112)),
        )),
      );
    }
    return AspectRatio(
      aspectRatio: 1,
      child: LumoPremiumCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: LumoTokens.brLarge,
          child: path != null
              ? Image.file(File(path), fit: BoxFit.cover)
              : Container(
                  color: LumoTokens.colors.cremeDeep,
                  alignment: Alignment.center,
                  child: const Text('📷', style: TextStyle(fontSize: 80)),
                ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final needsPhoto =
        _mode == LiveMode.photoQuiz && _capturedImagePath == null;
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
                  onPressed: !_active ||
                          _capturingPhoto ||
                          _listening ||
                          _listenOperation != null ||
                          _answerOperation != null ||
                          _lumoCurrentlySpeaking
                      ? null
                      : needsPhoto
                          ? _capturePhoto
                          : _answered
                              ? (_mode == LiveMode.wordMagic
                                  ? _newWord
                                  : _mode == LiveMode.safari
                                      ? _nextSafariAnimal
                                      : _photoComplete
                                          ? _capturePhoto
                                          : _nextPhotoQuestion)
                              : _startListening,
                  icon: Icon(
                      needsPhoto
                          ? Icons.camera_alt_rounded
                          : (_listening
                              ? Icons.hearing_rounded
                              : Icons.mic_rounded),
                      size: 28),
                  label: Text(needsPhoto
                      ? 'Foto machen'
                      : _answered
                          ? (_mode == LiveMode.wordMagic
                              ? 'Neues Wort'
                              : _mode == LiveMode.safari
                                  ? 'Nächstes Tier'
                                  : _photoComplete
                                      ? 'Neues Foto'
                                      : 'Nächste Frage')
                          : (_listening
                              ? 'Hoere...'
                              : (_mode == LiveMode.photoQuiz
                                  ? 'Antwort sprechen'
                                  : 'Sprechen'))),
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
            if (_mode == LiveMode.safari && _safariAnimal != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                height: 64,
                child: ElevatedButton(
                  onPressed: _active ? _nextSafariAnimal : null,
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
