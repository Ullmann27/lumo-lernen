// ════════════════════════════════════════════════════════════════════════
// LUMO SCHREIBCOACH — Wortmodus (Phase 5)
// ════════════════════════════════════════════════════════════════════════
// Diktat ohne Abschreiben:
//   1. Lumo sagt 'Schreib Sonne!' (Wort wird NICHT als Text angezeigt).
//   2. Oben sieht das Kind leere Buchstabenfelder.
//   3. Das aktuelle Feld blinkt sanft.
//   4. Auf dem grossen Canvas schreibt das Kind den naechsten Buchstaben.
//   5. Bei 'Fertig' wird genau dieser Buchstabe geprueft.
//   6. Richtig -> Feld faerbt sich gruen + Buchstabe wird sichtbar -> Cursor wandert weiter.
//   7. Falsch -> Feld blinkt rot sanft, Kind schreibt nochmal nur diesen Buchstaben.
//
// Phase 6: Jeder Versuch fliesst in WritingProgressRepository.
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_voice.dart';
import '../../core/writing_progress_repository.dart';
import '../../domain/writing/writing_progress.dart';
import '../../domain/writing/writing_word_bank.dart';
import '../../widgets/fox/lumo_idle_fox.dart';
import '../../widgets/fox/lumo_reaction_companion.dart';
import '../learning_modules/lumo_phrases.dart';
import 'writing_engine.dart';
import 'writing_feature_flags.dart';

class LumoWritingWordCoachScreen extends StatefulWidget {
  const LumoWritingWordCoachScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoWritingWordCoachScreen> createState() =>
      _LumoWritingWordCoachScreenState();
}

class _LumoWritingWordCoachScreenState extends State<LumoWritingWordCoachScreen>
    with TickerProviderStateMixin {
  static const int _wordsPerSession = 4;
  static const List<Color> _gradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
  ];

  late final AnimationController _demoCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _wrongShakeCtrl;
  final _rng = math.Random();
  final _progressRepo = WritingProgressRepository();

  late List<WritingWordTask> _sessionTasks;
  int _taskIdx = 0;

  WritingWordTask get _currentTask => _sessionTasks[_taskIdx];

  /// Index des aktuellen Buchstabens im Wort (0-basiert).
  int _letterCursor = 0;

  /// Welche Buchstabenfelder das Kind schon richtig hat.
  final Set<int> _completedSlots = {};

  final List<WritingStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  WritingFeedback? _lastFeedback;
  bool _showDemo = false;
  int _wrongSlot = -1;
  int _correctWords = 0;

  /// Anzahl Buchstaben, die das Kind ohne Retry richtig hatte.
  /// Basis fuer die finale Sterne-Vergabe - sonst gibt es immer 5/5.
  int _firstTryLetters = 0;

  /// Wurde der aktuelle Buchstabe schon einmal falsch geprueft?
  /// Damit zaehlt nur die erste richtige Antwort als 'first try'.
  bool _currentLetterHadMistake = false;

  /// Verhindert doppelte _checkLetter-Aufrufe bei schnellen Doppel-Taps.
  bool _checkInFlight = false;

  /// Stimmung des Lumo-Reaction-Companions im Wortdiktat.
  LumoReactionMood _companionMood = LumoReactionMood.idle;
  Timer? _moodResetTimer;

  void _setMood(LumoReactionMood next) {
    _moodResetTimer?.cancel();
    if (!mounted) return;
    setState(() => _companionMood = next);
    if (next != LumoReactionMood.idle) {
      _moodResetTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _companionMood = LumoReactionMood.idle);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _demoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _wrongShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    // Erste Session noch ohne Progress (random), dann nachladen und
    // ggf. adaptiv neu picken solange das Kind noch nicht angefangen
    // hat (taskIdx == 0 und keinen Buchstaben fertig).
    _sessionTasks = _pickSessionTasks();
    _progressRepo.load().then((p) {
      if (!mounted) return;
      final hasStarted = _taskIdx > 0 || _completedSlots.isNotEmpty;
      setState(() {
        _progress = p;
        if (!hasStarted && p.weakLetters.isNotEmpty) {
          _sessionTasks = _pickSessionTasks();
        }
      });
    }).catchError((_) {});
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  @override
  void dispose() {
    _moodResetTimer?.cancel();
    _demoCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _wrongShakeCtrl.dispose();
    super.dispose();
  }

  /// Schreibstatistik fuer adaptive Wort-Auswahl. Wird einmalig in
  /// initState geladen, Best-effort.
  WritingProgress _progress = WritingProgress.empty;

  List<WritingWordTask> _pickSessionTasks() {
    final pool = [...WritingWordBank.forGrade(widget.appState.state.grade)];
    if (pool.isEmpty) pool.addAll(WritingWordBank.all);

    // Phase 3 (E) adaptive Auswahl:
    // Wenn das Kind bestimmte Buchstaben schwach hat, sortiere Woerter
    // die diese Buchstaben enthalten nach oben. Pool bleibt komplett -
    // aber die ersten _wordsPerSession werden bevorzugt aus 'starken
    // Kandidaten' gezogen.
    final weak = _progress.weakLetters.toSet();
    if (weak.isNotEmpty) {
      int weakCount(WritingWordTask t) =>
          t.letters.where(weak.contains).length;
      pool.sort((a, b) {
        final delta = weakCount(b) - weakCount(a);
        if (delta != 0) return delta;
        // Sekundaer-Random: gleicher Score -> zufaellig
        return _rng.nextBool() ? 1 : -1;
      });
    } else {
      pool.shuffle(_rng);
    }
    return pool.take(_wordsPerSession).toList(growable: false);
  }

  String get _currentLetter {
    final letters = _currentTask.letters;
    if (letters.isEmpty || _letterCursor >= letters.length) return 'A';
    return letters[_letterCursor];
  }

  LetterTemplate? get _currentTemplate => LetterTemplates.all[_currentLetter];

  void _speakPrompt() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak(_currentTask.spokenPrompt);
    } catch (_) {}
  }

  void _speak(String msg) {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak(msg);
    } catch (_) {}
  }

  void _onPanStart(DragStartDetails d) {
    setState(() => _currentPoints = [d.localPosition]);
    // Phase 3: Lumo guckt aktiv mit waehrend das Kind schreibt.
    if (_companionMood != LumoReactionMood.cheer) {
      _setMood(LumoReactionMood.think);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentPoints = [..._currentPoints, d.localPosition]);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentPoints.length > 1) {
      setState(() {
        _strokes.add(WritingStroke(List.of(_currentPoints)));
        _currentPoints = [];
      });
    }
  }

  void _clearCanvas() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentPoints = [];
      _lastFeedback = null;
      _showDemo = false;
      _wrongSlot = -1;
    });
  }

  Future<void> _checkLetter() async {
    // Re-Entry-Guard: schnelle Doppel-Taps duerfen _checkLetter nicht
    // zweimal parallel laufen lassen. Sonst doppelte XP/Sterne und
    // moegliches Ueberspringen von Buchstaben.
    if (_checkInFlight) return;
    if (_strokes.isEmpty) return;
    if (_lastFeedback != null && _lastFeedback!.matched) return;

    _checkInFlight = true;
    try {
      final template = _currentTemplate;
      if (template == null) {
        // Falls Buchstabe nicht im Template-Lexikon - akzeptieren mit kurzer Notiz.
        await _onLetterCorrect();
        return;
      }
      HapticFeedback.lightImpact();
      final feedback = WritingFeedbackEngine.generate(
        template: template,
        userStrokes: _strokes,
      );
      if (WritingFeatureFlags.enableProgressTracking) {
        // Best-effort, kein await blockierend.
        unawaited(_progressRepo.recordAttempt(
          letter: _currentLetter,
          correct: feedback.matched,
        ));
      }
      setState(() {
        _lastFeedback = feedback;
        _showDemo = feedback.showDemo;
      });
      _speak(feedback.message);

      if (feedback.matched) {
        _setMood(LumoReactionMood.cheer);
        await _onLetterCorrect();
      } else {
        _currentLetterHadMistake = true;
        _setMood(LumoReactionMood.think);
        setState(() => _wrongSlot = _letterCursor);
        _wrongShakeCtrl.forward(from: 0);
        if (_showDemo) _demoCtrl.forward(from: 0);
      }
    } finally {
      _checkInFlight = false;
    }
  }

  Future<void> _onLetterCorrect() async {
    HapticFeedback.mediumImpact();
    // setState noetig, damit der gerade akzeptierte Slot SOFORT gruen
    // wird. Bei nicht-letzten Buchstaben maskierte das nachfolgende
    // setState(_letterCursor++) den Bug, beim letzten Buchstaben aber
    // raeumt _nextTask die _completedSlots wieder weg, bevor je ein
    // Rebuild passiert - der finale Slot blieb leer (Codex P2).
    setState(() {
      _completedSlots.add(_letterCursor);
      if (!_currentLetterHadMistake) {
        _firstTryLetters++;
      }
    });
    widget.appState.addXp(4);
    final isLastLetter = _letterCursor + 1 >= _currentTask.letters.length;
    if (isLastLetter) {
      _correctWords++;
      widget.appState.addStars(3);
      widget.appState.addXp(15);
      if (WritingFeatureFlags.enableProgressTracking) {
        unawaited(_progressRepo.recordCompletedWord(_currentTask.word));
      }
      _speak('Super! Du hast ${_currentTask.word} geschrieben!');
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      _nextTask();
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _letterCursor++;
        _currentLetterHadMistake = false;
        _strokes.clear();
        _currentPoints = [];
        _lastFeedback = null;
        _showDemo = false;
        _wrongSlot = -1;
      });
    }
  }

  void _nextTask() {
    if (_taskIdx + 1 >= _sessionTasks.length) {
      _showFinish();
      return;
    }
    setState(() {
      _taskIdx++;
      _letterCursor = 0;
      _currentLetterHadMistake = false;
      _completedSlots.clear();
      _strokes.clear();
      _currentPoints = [];
      _lastFeedback = null;
      _showDemo = false;
      _wrongSlot = -1;
    });
    _entryCtrl.forward(from: 0);
    _speakPrompt();
  }

  void _retry() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentPoints = [];
      _lastFeedback = null;
      _showDemo = false;
      _wrongSlot = -1;
    });
  }

  void _replayDemo() {
    final template = _currentTemplate;
    if (template == null) return;
    setState(() => _showDemo = true);
    _demoCtrl.forward(from: 0);
    _speak(template.description);
  }

  void _showHint() {
    final hint = _currentTask.hint;
    if (hint == null || hint.isEmpty) return;
    _speak(hint);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hint,
            style: const TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: _gradient[1],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showFinish() {
    final total = _sessionTasks.length;
    // Sterne basieren auf _firstTryLetters / Gesamtbuchstaben, nicht auf
    // _correctWords. _correctWords ist im Normalfall immer gleich total
    // (weil jedes Wort erst beim letzten korrekten Buchstaben weiterzaehlt),
    // also waere die Sterne-Anzeige sonst immer maximal.
    final totalLetters = _sessionTasks.fold<int>(
        0, (sum, task) => sum + task.letters.length);
    final accuracy =
        totalLetters > 0 ? _firstTryLetters / totalLetters : 0.0;
    final stars = (accuracy * 5).round().clamp(1, 5);
    widget.appState.addStars(stars);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Wortdiktat fertig!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctWords / $total Woerter geschafft!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.star_rounded,
                    size: 38,
                    color: i < stars
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFD1D5DB)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(LumoPhrases.celebrate(),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Fertig',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: _gradient[0])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, child) =>
                    Opacity(opacity: _entryCtrl.value, child: child),
                child: Column(children: [
                  _buildPrompt(),
                  const SizedBox(height: 14),
                  _buildLetterSlots(),
                  const SizedBox(height: 16),
                  _buildCanvas(),
                  const SizedBox(height: 12),
                  if (_lastFeedback != null) _buildFeedback(),
                  const SizedBox(height: 12),
                  _buildControls(),
                  const SizedBox(height: 12),
                  // Lumo-Reaction-Companion - reagiert sichtbar auf jeden
                  // Buchstabencheck (cheer bei richtig, think bei falsch).
                  Align(
                    alignment: Alignment.centerRight,
                    child: LumoReactionCompanion(
                      mood: _companionMood,
                      size: 80,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _gradient),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Column(children: [
            Text('Wort ${_taskIdx + 1} / ${_sessionTasks.length}',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const Text('Wortdiktat',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFFCD34D), size: 18),
            const SizedBox(width: 4),
            Text('$_correctWords',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _buildPrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
      ),
      child: Row(children: [
        const LumoIdleFox(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hoer gut zu!',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280))),
              Text(
                  'Schreib Buchstabe ${_letterCursor + 1} von ${_currentTask.letters.length}.',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _gradient[1])),
            ],
          ),
        ),
        IconButton(
          onPressed: _speakPrompt,
          icon: Icon(Icons.volume_up_rounded, color: _gradient[0], size: 32),
          tooltip: 'Nochmal hoeren',
        ),
      ]),
    );
  }

  Widget _buildLetterSlots() {
    final letters = _currentTask.letters;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _wrongShakeCtrl]),
      builder: (_, __) {
        final pulse = 0.85 + (_pulseCtrl.value * 0.15);
        final shake = _wrongShakeCtrl.value > 0
            ? math.sin(_wrongShakeCtrl.value * math.pi * 4) * 6
            : 0.0;
        // FittedBox + scaleDown: lange Woerter wie 'SONNE' oder 'BLUME'
        // passen auch auf 360dp-Geraeten in eine Zeile, weil die Slot-Row
        // bei Bedarf gleichmaessig runter-skaliert wird. Kein RenderFlex-
        // Overflow, Layout bleibt ruhig in einer Reihe.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < letters.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.translate(
                    offset: i == _wrongSlot ? Offset(shake, 0) : Offset.zero,
                    child: _slot(letters[i], i, pulse),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _slot(String letter, int index, double pulse) {
    final isCompleted = _completedSlots.contains(index);
    final isCurrent = index == _letterCursor && !isCompleted;
    final isWrong = index == _wrongSlot;

    Color bg = Colors.white;
    Color border = const Color(0xFFD1D5DB);
    Color textColor = const Color(0xFF9CA3AF);
    String display = '';

    if (isCompleted) {
      bg = const Color(0xFFD1FAE5);
      border = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
      display = letter;
    } else if (isWrong) {
      bg = const Color(0xFFFEE2E2);
      border = const Color(0xFFEF4444);
    } else if (isCurrent) {
      bg = Colors.white;
      border = _gradient[0].withOpacity(pulse);
    }

    final width = isCurrent ? 56.0 : 48.0;
    final height = isCurrent ? 64.0 : 56.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: border, width: isCurrent ? 3 : (isWrong ? 2.5 : 2)),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: _gradient[0].withOpacity(0.25 * pulse),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          display,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: textColor),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gradient[0].withOpacity(0.4), width: 3),
          boxShadow: [
            BoxShadow(
                color: _gradient[0].withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: AnimatedBuilder(
              animation: _demoCtrl,
              builder: (ctx, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 280),
                  painter: _WordCanvasPainter(
                    strokes: _strokes,
                    currentPoints: _currentPoints,
                    showDemo: _showDemo,
                    demoProgress: _demoCtrl.value,
                    template: _currentTemplate,
                    accent: _gradient[0],
                  ),
                  child: Container(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final f = _lastFeedback!;
    Color bg = const Color(0xFFD1FAE5);
    Color border = const Color(0xFF10B981);
    String icon = '✅';
    if (f.type == FeedbackType.almost) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFCD34D);
      icon = '👍';
    } else if (f.type == FeedbackType.missingStroke ||
        f.type == FeedbackType.demo) {
      bg = const Color(0xFFFEE2E2);
      border = const Color(0xFFEF4444);
      icon = '💡';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(f.message,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: border)),
        ),
      ]),
    );
  }

  Widget _buildControls() {
    final readyForCheck = _strokes.isNotEmpty && _lastFeedback == null;
    final canRetry = _lastFeedback != null && !_lastFeedback!.matched;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _btn(Icons.clear_rounded, 'Loeschen', const Color(0xFF6B7280),
            _clearCanvas),
        _btn(Icons.help_outline_rounded, 'Lumo zeigt', _gradient[0],
            _replayDemo),
        if (_currentTask.hint != null)
          _btn(Icons.lightbulb_outline_rounded, 'Tipp',
              const Color(0xFFFCD34D), _showHint),
        if (canRetry)
          _btn(Icons.refresh_rounded, 'Nochmal', _gradient[0], _retry),
        if (readyForCheck)
          _btn(Icons.check_circle_rounded, 'Fertig',
              const Color(0xFF10B981), _checkLetter),
      ],
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// CANVAS PAINTER — Wortmodus
// ════════════════════════════════════════════════════════════════════════

class _WordCanvasPainter extends CustomPainter {
  _WordCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.showDemo,
    required this.demoProgress,
    required this.template,
    required this.accent,
  });

  final List<WritingStroke> strokes;
  final List<Offset> currentPoints;
  final bool showDemo;
  final double demoProgress;
  final LetterTemplate? template;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = accent.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final topY = h * 0.18;
    final midY = h * 0.5;
    final botY = h * 0.82;
    canvas.drawLine(Offset(20, topY), Offset(w - 20, topY), linePaint);
    canvas.drawLine(Offset(20, midY), Offset(w - 20, midY), linePaint);
    canvas.drawLine(Offset(20, botY), Offset(w - 20, botY), linePaint);

    if (showDemo && template != null) {
      _drawDemo(canvas, size, template!);
    }

    final userPaint = Paint()
      ..color = accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      _drawStroke(canvas, s.points, userPaint);
    }
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, userPaint);
    }
  }

  void _drawDemo(Canvas canvas, Size size, LetterTemplate template) {
    final w = size.width;
    final h = size.height;
    final letterSize = h * 0.7;
    final offsetX = (w - letterSize) / 2;
    final offsetY = (h - letterSize) / 2;

    final demoPaint = Paint()
      ..color = const Color(0xFFFCD34D).withOpacity(0.8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final totalStrokes = template.demoStrokes.length;
    if (totalStrokes == 0) return;
    final currentStrokeIdx = (demoProgress * totalStrokes).floor();
    final localProgress = (demoProgress * totalStrokes) - currentStrokeIdx;

    for (int i = 0; i < totalStrokes; i++) {
      final stroke = template.demoStrokes[i];
      final scaled = stroke
          .map((p) => Offset(
                offsetX + (p.dx / 100) * letterSize,
                offsetY + (p.dy / 100) * letterSize,
              ))
          .toList();
      if (i < currentStrokeIdx) {
        _drawStroke(canvas, scaled, demoPaint);
      } else if (i == currentStrokeIdx) {
        final partLen = (scaled.length * localProgress).ceil();
        if (partLen >= 2) {
          _drawStroke(canvas, scaled.sublist(0, partLen), demoPaint);
        }
      }
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WordCanvasPainter old) =>
      old.strokes.length != strokes.length ||
      old.currentPoints != currentPoints ||
      old.showDemo != showDemo ||
      old.demoProgress != demoProgress ||
      old.template?.letter != template?.letter;
}
