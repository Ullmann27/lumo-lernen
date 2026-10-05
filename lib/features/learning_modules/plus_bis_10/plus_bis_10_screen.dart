// ════════════════════════════════════════════════════════════════════════
// PLUS BIS 10 — Erstes echtes interaktives Lern-Modul (Klasse 1 Mathematik)
// ════════════════════════════════════════════════════════════════════════
// Heinz Feedback: 'Alle Optionen sind nur Chats - keine aktiven Lern-Module'.
//
// Loesung: Echtes Tap-basiertes Uebungs-Modul mit:
//   - 10 Aufgaben pro Session
//   - Visualisierung mit Aepfeln (Zaehlbar)
//   - 4 Multiple-Choice Antwort-Buttons
//   - Bei richtig: Lumo lobt, Sterne, naechste Aufgabe
//   - Bei falsch: Sanftes Feedback, Erklaerung mit Bildern, nochmal
//   - Am Ende: Auswertung mit Sternen
// ════════════════════════════════════════════════════════════════════════

import '../../../widgets/fox/lumo_character.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../core/lumo_companion_state.dart';
import '../../../core/lumo_cosmos.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../lumo_phrases.dart';

class PlusBis10Screen extends StatefulWidget {
  const PlusBis10Screen({
    super.key,
    required this.appState,
  });

  final LumoAppState appState;

  @override
  State<PlusBis10Screen> createState() => _PlusBis10ScreenState();
}

class _PlusBis10ScreenState extends State<PlusBis10Screen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFFFB923C),
    Color(0xFFEA580C),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  /// Lumo freut sich bei richtigen Antworten und tröstet bei falschen.
  final _lumo = LumoCharacterController();

  int _taskIdx = 0;
  int _correctCount = 0;
  int _wrongAttempts = 0;
  bool _showHint = false;
  bool _answered = false;
  int? _selectedAnswer;
  int? _pendingAnswer;
  bool _pendingHintUsed = false;
  bool _saving = false;
  bool _rewardBooked = false;
  bool _profileRecorded = false;
  String? _saveError;
  Timer? _feedbackTimer;
  VoidCallback? _afterFeedback;
  bool _foreground = true;
  bool _finishSavePending = false;
  bool _finishRewardBooked = false;

  // Aktuelle Aufgabe
  late int _a;
  late int _b;
  late List<int> _answers;

  int get _correct => _a + _b;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _generateTask();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakTask();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedbackTimer?.cancel();
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    _lumo.dispose();
    super.dispose();
  }

  void _generateTask() {
    // a + b mit a+b <= 10, a >= 1, b >= 1
    _a = 1 + _rng.nextInt(5); // 1-5
    _b = 1 + _rng.nextInt(10 - _a); // mind. 1, max. 10 - a
    if (_b < 1) _b = 1;

    // 4 Antworten: richtige + 3 plausibel falsche.
    // Heinz-Scan 2026-05-21: bisherige Loop hatte Edge-Case wo
    // wrong == _correct (innerhalb 0..10) weder if- noch else-if-
    // Branch traf -> potenzielle Endlos-Iteration. Neu: klare
    // 2-Stufen-Strategie: zuerst nahe Plausibel-Werte, dann beliebige
    // 0..10 als Fallback.
    final answers = <int>{_correct};
    // Stufe 1: Plausibel-nahe Werte (correct +/- 1..2)
    final nearby = <int>[
      for (final d in const [-2, -1, 1, 2])
        if (_correct + d >= 0 && _correct + d <= 10) _correct + d,
    ]..shuffle(_rng);
    for (final n in nearby) {
      if (answers.length >= 4) break;
      answers.add(n);
    }
    // Stufe 2: Fallback aus 0..10 (falls correct am Rand liegt, zb
    // 0 oder 10, gibt's weniger nearby).
    int safety = 30;
    while (answers.length < 4 && safety-- > 0) {
      final cand = _rng.nextInt(11);
      if (cand != _correct) answers.add(cand);
    }
    _answers = answers.toList()..shuffle(_rng);
    _showHint = false;
    _answered = false;
    _selectedAnswer = null;
    _wrongAttempts = 0;
    _pendingAnswer = null;
    _rewardBooked = false;
    _profileRecorded = false;
    _saveError = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _feedbackTimer?.cancel();
      _feedbackTimer = null;
    } else if (_afterFeedback != null) {
      _scheduleFeedback(const Duration(milliseconds: 1300), _afterFeedback!);
    }
  }

  void _scheduleFeedback(Duration duration, VoidCallback action) {
    _feedbackTimer?.cancel();
    _afterFeedback = action;
    if (!_foreground) return;
    _feedbackTimer = Timer(duration, () {
      _feedbackTimer = null;
      _afterFeedback = null;
      if (mounted) action();
    });
  }

  void _speakTask() {
    try {
      LumoVoice.instance.speak('$_a plus $_b - wie viel ist das?');
    } catch (_) {}
  }

  void _handleAnswer(int answer) {
    if (_answered || _pendingAnswer != null || _afterFeedback != null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _pendingAnswer = answer;
      _pendingHintUsed = _showHint;
      _saving = true;
      _answered = answer == _correct;
      if (!_answered) _wrongAttempts++;
    });
    unawaited(_saveAnswer());
  }

  Future<void> _saveAnswer() async {
    final answer = _pendingAnswer;
    if (answer == null) return;
    final correct = answer == _correct;
    final hintUsed = _pendingHintUsed;
    try {
      if (correct) {
        if (!_rewardBooked) {
          _rewardBooked = true;
          widget.appState.addRewards(stars: 1, xp: 5);
        }
        await widget.appState.flushRewards();
      }
      if (!widget.appState.learningProfileLoaded) {
        await widget.appState.loadLearningProfile();
        if (!widget.appState.learningProfileLoaded) {
          throw StateError('Learning profile could not be loaded');
        }
      }
      if (!_profileRecorded) {
        // recordAnswer mutates its in-memory counters before saving. A retry
        // must flush that same state, rather than recording a second answer.
        _profileRecorded = true;
        await widget.appState.recordLearningAnswer(
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          correct: correct,
          hintUsed: hintUsed,
          requireSaved: true,
        );
      } else {
        await widget.appState.flushLearningProgress();
      }
      if (!mounted) return;
      setState(() {
        _pendingAnswer = null;
        _saving = false;
        _saveError = null;
      });
      if (correct) {
        _handleCorrect();
      } else {
        _handleWrong(answer);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Deine Antwort wartet noch aufs Speichern. '
            'Wir versuchen es gemeinsam erneut.';
      });
    }
  }

  void _retrySave() {
    if (_saving || (_pendingAnswer == null && !_finishSavePending)) return;
    setState(() => _saving = true);
    unawaited(_finishSavePending ? _saveFinish() : _saveAnswer());
  }

  void _continueAfterCorrect() {
    if (!_answered || _pendingAnswer != null || _saving) return;
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _afterFeedback = null;
    _nextTask();
  }

  void _handleCorrect() {
    setState(() {
      _answered = true;
      // Nur beim ersten Versuch richtig geloeste Aufgaben zaehlen. Vorher
      // stand am Ende immer "30 von 30", weil jede Aufgabe erst mit der
      // richtigen Antwort endet.
      if (_wrongAttempts == 0) _correctCount++;
    });
    _bounceCtrl.forward(from: 0);
    _lumo.cheer();
    HapticFeedback.mediumImpact();
    // Cosmos-Belohnung: pflanze einen Baum in der Welt!
    CosmosWorld.instance.grantReward(
      subjectId: 'm1_plus10',
      isMath: true,
      isPerfect: false,
    );
    LumoCompanionState.instance.recordCorrect(topic: 'math');
    try {
      LumoVoice.instance.speak(LumoPhrases.correct());
    } catch (_) {}

    _scheduleFeedback(const Duration(milliseconds: 1300), _nextTask);
  }

  void _handleWrong(int answer) {
    _shakeCtrl.forward(from: 0);
    _lumo.comfort();
    HapticFeedback.heavyImpact();
    try {
      LumoVoice.instance.speak(LumoPhrases.wrongGentle());
    } catch (_) {}

    // Nach 2 Fehlversuchen: Hint zeigen
    if (_wrongAttempts >= 2 && !_showHint) {
      _scheduleFeedback(
          const Duration(milliseconds: 800),
          () => setState(() {
                _showHint = true;
                _selectedAnswer = null;
                _profileRecorded = false;
              }));
    } else {
      _scheduleFeedback(
          const Duration(milliseconds: 600),
          () => setState(() {
                _selectedAnswer = null;
                _profileRecorded = false;
              }));
    }
  }

  void _nextTask() {
    if (_taskIdx + 1 >= _totalTasks) {
      _showFinish();
      return;
    }
    setState(() {
      _taskIdx++;
      _generateTask();
    });
    _entryCtrl.reset();
    _entryCtrl.forward();
    _speakTask();
  }

  void _showFinish() {
    setState(() {
      _finishSavePending = true;
      _saving = true;
    });
    unawaited(_saveFinish());
  }

  Future<void> _saveFinish() async {
    final percent = _correctCount / _totalTasks;
    final stars = (percent * 5).round().clamp(1, 5);
    // FIX: vorher stars*2 - das war Star-Inflation: 30 richtige Antworten
    // gaben 30 Sterne wahrend des Spiels + 10 Bonus = 40 Sterne. Die
    // anderen Module geben am Ende nur `stars` (1-5). Jetzt konsistent.
    try {
      if (!_finishRewardBooked) {
        _finishRewardBooked = true;
        widget.appState.addRewards(stars: stars, xp: _correctCount * 10);
      }
      await widget.appState.flushRewards();
      if (!mounted) return;
      setState(() {
        _finishSavePending = false;
        _saving = false;
        _saveError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'Deine Belohnung wartet noch aufs Speichern.';
        });
      }
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFEF3C7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          percent >= 0.8 ? '🎉 ${LumoPhrases.celebrate()}' : '👍 Geschafft!',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Du hast $_correctCount von $_totalTasks Aufgaben richtig!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.star_rounded,
                    size: 42,
                    color: i < stars
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFD1D5DB)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              percent >= 0.8
                  ? 'Du bist ein Plus-Profi! 🦊'
                  : 'Gut! Probier nochmal für mehr Sterne!',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: _gradient[0],
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ]),
        actions: [
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Fertig',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6B7280))),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _taskIdx = 0;
                    _correctCount = 0;
                    _finishRewardBooked = false;
                    _generateTask();
                  });
                  _entryCtrl.reset();
                  _entryCtrl.forward();
                  _speakTask();
                },
                child: Text('Nochmal',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        color: _gradient[0])),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  bool get _canLeave => _pendingAnswer == null && !_finishSavePending;

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  /// Untere Leiste wie in Bild 02: Sie führt aus der Übung in einen anderen
  /// Bereich, aber nie mitten aus einer Antwort, die noch gespeichert wird.
  void _leaveTo(LumoSection section) {
    if (!_canLeave) return;
    Navigator.of(context).pop();
    if (section != LumoSection.learn) widget.appState.setSection(section);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
        canPop: _canLeave,
        child: Scaffold(
          backgroundColor: LumoVisualTokens.night,
          body: LumoSceneBackground(
            scene: LumoScene.library,
            showPlaceholderLabel: false,
            dimmed: true,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: LumoTopBar(appState: widget.appState),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          _buildHero(),
                          AnimatedBuilder(
                            animation:
                                Listenable.merge([_entryCtrl, _shakeCtrl]),
                            builder: (_, child) {
                              final shake = _shakeCtrl.value < 1.0
                                  ? math.sin(_shakeCtrl.value * math.pi * 4) * 8
                                  : 0.0;
                              return Transform.translate(
                                offset: Offset(shake, 0),
                                child: FadeTransition(
                                    opacity: _entryCtrl, child: child),
                              );
                            },
                            child: _buildAdventureCard(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  LumoBottomNavigation(
                    active: LumoSection.learn,
                    onSelect: _leaveTo,
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  /// Lumo zeigt auf das Buch, links seine Sprechblase, rechts der Spruch.
  Widget _buildHero() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = (width * .3).clamp(108.0, 180.0);
      final foxSize = height * 1.3;
      final Widget fox = LumoCharacter(
        pose: LumoDesignFoxPose.bookPoint,
        size: foxSize,
        reduceMotion: _reduceMotion,
        controller: _lumo,
        // Antippen: Lumo wackelt kitzlig.
        onTap: () {},
      );
      return SizedBox(
        height: height,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: (width - foxSize) / 2,
            bottom: -foxSize * .1,
            child: RepaintBoundary(child: fox),
          ),
          Positioned(
            left: 12,
            top: height * .04,
            width: width * .3,
            child: Transform.rotate(
              angle: -.05,
              child: const LumoHeroBubble(
                text: 'Super! Gemeinsam rechnen wir das!',
                handwritten: true,
              ),
            ),
          ),
          Positioned(
            right: -4,
            top: height * .18,
            width: width * .25,
            child: Transform.rotate(
              angle: -.08,
              child: const LumoHeroBubble(
                text: 'Kleine Schritte\nGroße Zukunft!',
                handwritten: true,
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _buildAdventureCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        radius: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardHeader(),
            const SizedBox(height: 8),
            _buildProgressRow(),
            const SizedBox(height: 8),
            _buildTaskCard(),
            const SizedBox(height: 8),
            _buildHelpCard(),
            if (_saving || _saveError != null) _buildSaveStatus(),
            const SizedBox(height: 8),
            _buildAnswerButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF3FA9F5), Color(0xFF1E5FD0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(.5)),
          boxShadow: [
            BoxShadow(
                color: LumoVisualTokens.cyan.withOpacity(.4), blurRadius: 10),
          ],
        ),
        child:
            const Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mathe-Abenteuer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Entdecke Zahlen, löse Aufgaben, werde ein Mathe-Profi!',
              maxLines: 2,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  /// „Aufgabe N / M“ mit zehn Leuchtsegmenten und der echten XP pro Aufgabe.
  Widget _buildProgressRow() {
    const segments = 10;
    final filled = ((_taskIdx + 1) / _totalTasks * segments).ceil();
    return Row(children: [
      Expanded(
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: LumoVisualTokens.navigation.withOpacity(.7),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.35)),
          ),
          child: Row(children: [
            Text(
              'Aufgabe ${_taskIdx + 1} / $_totalTasks',
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(children: [
                for (var i = 0; i < segments; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: _reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      height: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i < filled
                            ? LumoVisualTokens.cyanBright
                            : const Color(0xFF1C3A66),
                        boxShadow: i < filled
                            ? [
                                BoxShadow(
                                  color: LumoVisualTokens.cyan.withOpacity(.6),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: LumoVisualTokens.glassRow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.5)),
        ),
        child: const Row(children: [
          Icon(Icons.star_rounded, color: LumoVisualTokens.gold, size: 20),
          SizedBox(width: 4),
          Text(
            '+5 XP',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: LumoVisualTokens.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildTaskCard() {
    const decoStar = Icon(Icons.star_border_rounded,
        color: LumoVisualTokens.cyanBright, size: 18);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3A78).withOpacity(.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.6)),
        boxShadow: [
          BoxShadow(
              color: LumoVisualTokens.cyan.withOpacity(.18), blurRadius: 14),
        ],
      ),
      child: Stack(children: [
        const Positioned(left: 0, top: 4, child: decoStar),
        const Positioned(right: 0, top: 4, child: decoStar),
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(width: double.infinity),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$_a + $_b = ?',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 42,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: LumoVisualTokens.cyan, blurRadius: 14),
                ],
              ),
            ),
          ),
          const Text(
            'Wähle die richtige Antwort aus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: LumoVisualTokens.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ]),
      ]),
    );
  }

  /// Hilfe-Karte aus Bild 02: zwei Apfel-Mengen, „= ?“ und Lumo mit
  /// Zeigestab. Nach zwei Fehlversuchen oder auf „Tipp“ zählt Lumo vor.
  Widget _buildHelpCard() {
    final bubble = _showHint
        ? 'Zähle alle Äpfel zusammen: '
            '${List.filled(_a, '🍎').join('')} und '
            '${List.filled(_b, '🍏').join('')}'
        : 'Erst $_a … und noch $_b … Wie viele sind es insgesamt?';
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return Container(
      height: 116 * scale,
      decoration: BoxDecoration(
        color: LumoVisualTokens.glassRow.withOpacity(.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.4)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth * .36;
        return Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(
            left: 10,
            top: 8,
            bottom: 10,
            right: side,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lightbulb_rounded,
                      color: LumoVisualTokens.gold,
                      size: 22,
                      shadows: [
                        Shadow(color: Color(0xAAFFC94A), blurRadius: 10)
                      ]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showHint ? LumoPhrases.hint() : 'Hilfe',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Zähle die Äpfel mit Lumo!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const Spacer(),
                Row(children: [
                  Expanded(child: _appleBox(_a)),
                  _operator('+'),
                  Expanded(child: _appleBox(_b)),
                  _operator('='),
                  _questionBox(),
                ]),
              ],
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            width: side - 8,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0B3C78).withOpacity(.88),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: LumoVisualTokens.cyan.withOpacity(.7)),
              ),
              child: Text(
                bubble,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.white,
                  fontSize: 10,
                  height: 1.2,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -6,
            child: LumoFoxPose(
              pose: LumoDesignFoxPose.teacherStick,
              size: (c.maxHeight * .62).clamp(60.0, 110.0),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _appleBox(int count) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0A3A78).withOpacity(.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.55)),
      ),
      child: Semantics(
        label: '$count Äpfel',
        excludeSemantics: true,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 1,
          runSpacing: 1,
          children: [
            for (var i = 0; i < count; i++)
              const Text('🍎', style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _operator(String symbol) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text(
          symbol,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: LumoVisualTokens.white,
          ),
        ),
      );

  Widget _questionBox() => Container(
        width: 30,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: LumoVisualTokens.white.withOpacity(.85), width: 1.4),
        ),
        child: const Text(
          '?',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: LumoVisualTokens.white,
          ),
        ),
      );

  Widget _buildSaveStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(children: [
        Text(
          _saveError ?? 'Wir speichern deine Antwort…',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: LumoVisualTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_saveError != null)
          FilledButton(
            onPressed: _saving ? null : _retrySave,
            child: const Text('Erneut versuchen'),
          ),
      ]),
    );
  }

  Widget _buildAnswerButtons() {
    final canContinue = _answered && _pendingAnswer == null && !_saving;
    return Column(children: [
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: _answers.map((ans) {
          final isSelected = _selectedAnswer == ans;
          final isCorrect = _answered && ans == _correct;
          final isWrong = isSelected && ans != _correct;

          var colors = const [Color(0xFF1C5BB8), Color(0xFF0E3A82)];
          var borderColor = LumoVisualTokens.cyan.withOpacity(.55);
          if (isCorrect) {
            colors = const [Color(0xFF1FA27A), Color(0xFF0F6B50)];
            borderColor = const Color(0xFF4BE0A5);
          } else if (isWrong) {
            colors = const [Color(0xFF9B2C55), Color(0xFF6B1D3B)];
            borderColor = const Color(0xFFFF6B8A);
          } else if (isSelected) {
            colors = const [Color(0xFF2AA7E8), Color(0xFF1466B8)];
            borderColor = LumoVisualTokens.cyanBright;
          }

          return AnimatedScale(
            scale: isCorrect ? 1.0 + (_bounceCtrl.value * 0.1) : 1.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => _handleAnswer(ans),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                        color: borderColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                alignment: Alignment.center,
                child: Text('$ans',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          _pillButton(
            label: 'Tipp',
            onPressed: _showHint || _answered
                ? null
                : () => setState(() => _showHint = true),
            leading: const Icon(Icons.lightbulb_rounded,
                color: LumoVisualTokens.gold, size: 24),
            colors: const [Color(0xFF123F7C), Color(0xFF0B2A5A)],
            border: LumoVisualTokens.cyan.withOpacity(.6),
          ),
          const Spacer(),
          _pillButton(
            label: 'Weiter',
            onPressed: canContinue ? _continueAfterCorrect : null,
            colors: const [Color(0xFF4FE3C1), Color(0xFF16A889)],
            border: const Color(0xFFB4FFEE),
            wide: true,
          ),
        ],
      ),
    ]);
  }

  /// Glas-Pillen „Tipp“ und „Weiter“ wie in Bild 02; gesperrt wirken sie
  /// gedämpft.
  Widget _pillButton({
    required String label,
    required VoidCallback? onPressed,
    required List<Color> colors,
    required Color border,
    Widget? leading,
    bool wide = false,
  }) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onPressed,
            child: Ink(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: border, width: 1.4),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                            color: border.withOpacity(.45), blurRadius: 14)
                      ]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (leading != null) ...[leading, const SizedBox(width: 8)],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: wide ? 20 : 17,
                    fontWeight: FontWeight.w900,
                    color: wide ? const Color(0xFF053B33) : Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: wide ? const Color(0xFF053B33) : Colors.white),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
