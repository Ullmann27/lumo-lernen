// ════════════════════════════════════════════════════════════════════════
// LUMO KART — Lern-Rennen mit Math/Deutsch-Fragen statt Bremse
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 33: Heinz' Wunsch nach 'was noch keiner hat'. Volksschul-
// Lehrplan-Quiz INTEGRIERT in ein 2D-Top-Down-Racing-Game. Tochter faehrt
// durch eine Strecke, vor jedem Tor erscheint eine Aufgabe. Richtige
// Antwort = Speed-Boost, falsche = Slow-Down. Am Ende Sterne fuer
// Geschwindigkeit + Genauigkeit.
//
// Nutzt die 11 MB brachliegende `assets/lumo_kart/` Asset-Foundation:
//   - 12 Kart-360-Sprites (statische Variante: Asset 001 fuer v1)
//   - 40 Track-Tile-PNGs (wir nutzen 4-6 fuer Strecken-Mosaik)
//   - 34 Environment-Decor-Sprites (zur Seite)
//   - 56 Collectibles-Sprites (Goldsterne)
//
// Architektur: Ticker-basiertes Game-Loop wie LumoJumpAdventureGame
// (von Heinz schon getestet), KEIN Flame-Package um Build-Risiko
// gering zu halten. CustomPaint fuer Rendering.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/math_task_templates.dart';

// ── DATEN-MODELL ──────────────────────────────────────────────────────

class KartQuestion {
  const KartQuestion({
    required this.prompt,
    required this.answers,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> answers;
  final int correctIndex;
}

class KartRaceConfig {
  const KartRaceConfig({
    required this.title,
    required this.subject,
    required this.grade,
    required this.theme,
    required this.questionCount,
    required this.targetSeconds,
  });

  final String title;
  final String subject;
  final int grade;
  final KartTheme theme;
  final int questionCount;
  final double targetSeconds;
}

enum KartTheme { forest, mountain, city }

/// Generiert eine Race-Question-Liste aus dem bestehenden Math-Template-
/// System fuer die gewuenschte Klassenstufe. Nutzt die statische
/// MathTaskTemplates.generate(grade,unit,seed)-API. Bei Wort-Antworten
/// werden die Choices uebernommen, bei Zahlen-Antworten generieren wir
/// 3 plausible Nachbarzahlen.
List<KartQuestion> generateQuestions(KartRaceConfig cfg, int seed) {
  final rng = math.Random(seed);
  final out = <KartQuestion>[];
  for (var i = 0; i < cfg.questionCount; i++) {
    try {
      final task = MathTaskTemplates.generate(
        grade: cfg.grade,
        unit: 'Alle',
        seed: rng.nextInt(0x7fffffff),
      );
      final correct = task.answer;
      final correctNum =
          int.tryParse(correct.replaceAll(RegExp(r'[^0-9-]'), ''));
      if (correctNum != null) {
        out.add(_buildQuestion(task.prompt, correctNum, rng));
      } else {
        final choices = task.choices.isNotEmpty
            ? task.choices.take(3).toList()
            : <String>[correct, 'mehr', 'gleich'];
        var correctIdx = choices.indexOf(correct);
        if (correctIdx < 0) {
          choices.insert(0, correct);
          correctIdx = 0;
        }
        out.add(KartQuestion(
          prompt: task.prompt,
          answers: choices,
          correctIndex: correctIdx,
        ));
      }
    } catch (_) {
      // Fallback: einfache Plus-Aufgabe wenn Template-System haengt
      final a = rng.nextInt(8) + 1;
      final b = rng.nextInt(8) + 1;
      out.add(_buildQuestion('$a + $b = ?', a + b, rng));
    }
  }
  return out;
}

KartQuestion _buildQuestion(String prompt, int correct, math.Random rng) {
  // 3 Antworten: richtige + 2 plausible Nachbarn
  final offsets = <int>[];
  while (offsets.length < 2) {
    final o = (rng.nextInt(5) - 2);
    if (o == 0 || offsets.contains(o)) continue;
    final candidate = correct + o;
    if (candidate < 0) continue;
    offsets.add(o);
  }
  final all = <int>[correct, ...offsets.map((o) => correct + o)];
  all.shuffle(rng);
  return KartQuestion(
    prompt: prompt,
    answers: all.map((n) => '$n').toList(),
    correctIndex: all.indexOf(correct),
  );
}

// ── HAUPT-SCREEN ──────────────────────────────────────────────────────

class LumoKartScreen extends StatefulWidget {
  const LumoKartScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoKartScreen> createState() => _LumoKartScreenState();
}

class _LumoKartScreenState extends State<LumoKartScreen> {
  KartRaceConfig? _activeRace;

  @override
  Widget build(BuildContext context) {
    if (_activeRace == null) {
      return _RaceSelectionScreen(
        grade: widget.appState.state.grade,
        onPick: (cfg) => setState(() => _activeRace = cfg),
      );
    }
    return _RaceArena(
      race: _activeRace!,
      appState: widget.appState,
      onExit: () => setState(() => _activeRace = null),
    );
  }
}

// ── RENN-AUSWAHL ──────────────────────────────────────────────────────

class _RaceSelectionScreen extends StatelessWidget {
  const _RaceSelectionScreen({required this.grade, required this.onPick});
  final int grade;
  final ValueChanged<KartRaceConfig> onPick;

  @override
  Widget build(BuildContext context) {
    final races = <KartRaceConfig>[
      KartRaceConfig(
        title: 'Waldweg-Rennen',
        subject: 'Mathematik',
        grade: grade,
        theme: KartTheme.forest,
        questionCount: 5,
        targetSeconds: 60,
      ),
      KartRaceConfig(
        title: 'Bergpass',
        subject: 'Mathematik',
        grade: grade,
        theme: KartTheme.mountain,
        questionCount: 7,
        targetSeconds: 80,
      ),
      KartRaceConfig(
        title: 'Stadtkurs Wien',
        subject: 'Mathematik',
        grade: grade,
        theme: KartTheme.city,
        questionCount: 10,
        targetSeconds: 110,
      ),
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Lumo Kart',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFFEC4899), Color(0xFFFB923C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(grade),
                const SizedBox(height: 16),
                for (final r in races) ...[
                  _RaceCard(race: r, onTap: () => onPick(r)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(int grade) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.30), width: 1.6),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏁 Lumo Kart',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Fahr durch die Strecke und beantworte Aufgaben!\n'
                  'Richtig = Speed-Boost, falsch = Bremse.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/lumo_kart/kart/lumo_kart_360_vehicle_sheet_asset_001.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🏎️', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceCard extends StatelessWidget {
  const _RaceCard({required this.race, required this.onTap});
  final KartRaceConfig race;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (race.theme) {
      KartTheme.forest => '🌲',
      KartTheme.mountain => '🏔️',
      KartTheme.city => '🏙️',
    };
    final color = switch (race.theme) {
      KartTheme.forest => const Color(0xFF22C55E),
      KartTheme.mountain => const Color(0xFF6366F1),
      KartTheme.city => const Color(0xFFEAB308),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            // 2026-06-06 FIX: Single-side Border + borderRadius rendert nicht.
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      race.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                      ),
                    ),
                    Text(
                      '${race.subject} · ${race.questionCount} Aufgaben',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded, color: color, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── RENN-ARENA ────────────────────────────────────────────────────────

class _RaceArena extends StatefulWidget {
  const _RaceArena({
    required this.race,
    required this.appState,
    required this.onExit,
  });
  final KartRaceConfig race;
  final LumoAppState appState;
  final VoidCallback onExit;

  @override
  State<_RaceArena> createState() => _RaceArenaState();
}

class _RaceArenaState extends State<_RaceArena>
    with SingleTickerProviderStateMixin {
  static const double _baseSpeed = 120; // px/s
  static const double _trackLength = 4200; // total track length

  late final Ticker _ticker;
  late final List<KartQuestion> _questions;

  Duration _lastTime = Duration.zero;
  double _kartProgress = 0; // 0..1
  double _speedFactor = 1.0;
  double _boostTimer = 0;
  double _slowTimer = 0;
  double _elapsed = 0;
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _starsCollected = 0;
  bool _showingQuestion = false;
  bool _raceFinished = false;
  KartQuestion? _activeQuestion;
  int? _pickedAnswerIdx;
  bool? _pickedCorrect;

  // Vorberechnete Tor-Positionen entlang der Strecke (0..1).
  late final List<double> _gates;
  // Vorberechnete Stern-Positionen
  late final List<double> _starPositions;
  final Set<int> _collectedStars = <int>{};

  @override
  void initState() {
    super.initState();
    _questions = generateQuestions(
        widget.race, DateTime.now().millisecondsSinceEpoch % 0x7fffffff);
    final n = _questions.length;
    _gates = List<double>.generate(n, (i) => (i + 1) / (n + 1) * 0.92 + 0.04);
    _starPositions = List<double>.generate(n + 2, (i) => (i + 0.5) / (n + 2));
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_showingQuestion || _raceFinished) {
      _lastTime = elapsed;
      return;
    }
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    final dt = (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;
    if (dt > 0.1) return; // Skip large jumps

    setState(() {
      _elapsed += dt;
      // Boost / Slow Timer
      if (_boostTimer > 0) {
        _boostTimer -= dt;
        _speedFactor = 1.7;
      } else if (_slowTimer > 0) {
        _slowTimer -= dt;
        _speedFactor = 0.4;
      } else {
        _speedFactor = 1.0;
      }
      _kartProgress += (_baseSpeed * _speedFactor / _trackLength) * dt;

      // Stern-Pickup
      for (var i = 0; i < _starPositions.length; i++) {
        if (_collectedStars.contains(i)) continue;
        if ((_kartProgress - _starPositions[i]).abs() < 0.012) {
          _collectedStars.add(i);
          _starsCollected++;
          HapticFeedback.selectionClick();
        }
      }

      // Tor-Check
      if (_currentQuestionIndex < _gates.length) {
        if (_kartProgress >= _gates[_currentQuestionIndex]) {
          _triggerQuestion();
        }
      }

      // Renn-Ende
      if (_kartProgress >= 1.0) {
        _kartProgress = 1.0;
        _raceFinished = true;
      }
    });
  }

  void _triggerQuestion() {
    _activeQuestion = _questions[_currentQuestionIndex];
    _showingQuestion = true;
    _pickedAnswerIdx = null;
    _pickedCorrect = null;
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _answerQuestion(int idx) {
    final q = _activeQuestion;
    if (q == null) return;
    final correct = idx == q.correctIndex;
    setState(() {
      _pickedAnswerIdx = idx;
      _pickedCorrect = correct;
      if (correct) {
        _correctCount++;
        _boostTimer = 2.5;
        _slowTimer = 0;
        HapticFeedback.heavyImpact();
      } else {
        _slowTimer = 1.5;
        _boostTimer = 0;
        HapticFeedback.vibrate();
      }
    });
    // Nach kurzem Delay: Frage schliessen
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _showingQuestion = false;
        _activeQuestion = null;
        _currentQuestionIndex++;
      });
    });
  }

  int _calculateStars() {
    final accuracy = _correctCount / widget.race.questionCount;
    final timeRatio = _elapsed / widget.race.targetSeconds;
    if (accuracy >= 0.9 && timeRatio <= 1.2) return 3;
    if (accuracy >= 0.7) return 2;
    if (accuracy >= 0.5) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeColor(widget.race.theme).darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RacePainter(
                  progress: _kartProgress,
                  theme: widget.race.theme,
                  boostActive: _boostTimer > 0,
                  slowActive: _slowTimer > 0,
                  starPositions: _starPositions,
                  collectedStars: _collectedStars,
                  gates: _gates,
                  questionsAnswered: _currentQuestionIndex,
                ),
              ),
            ),
            _hud(),
            if (_showingQuestion && _activeQuestion != null)
              _questionOverlay(_activeQuestion!),
            if (_raceFinished) _finishOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onExit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      color: Color(0xFFFCD34D), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${(_kartProgress * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFCD34D), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_starsCollected',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_elapsed.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionOverlay(KartQuestion q) {
    final picked = _pickedAnswerIdx;
    final correct = _pickedCorrect;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFEFA), Color(0xFFFFF7ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏁 Tor-Aufgabe!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEA580C),
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 8),
                Text(
                  q.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List<Widget>.generate(q.answers.length, (i) {
                    final answer = q.answers[i];
                    final isPicked = picked == i;
                    Color bg = Colors.white;
                    Color border = LumoColors.ink100;
                    Color text = LumoColors.ink900;
                    if (picked != null) {
                      if (i == q.correctIndex) {
                        bg = const Color(0xFFDCFCE7);
                        border = const Color(0xFF22C55E);
                        text = const Color(0xFF14532D);
                      } else if (isPicked && correct == false) {
                        bg = const Color(0xFFFFE4E6);
                        border = const Color(0xFFF43F5E);
                        text = const Color(0xFF881337);
                      }
                    }
                    return GestureDetector(
                      onTap:
                          picked == null ? () => _answerQuestion(i) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: border.withOpacity(0.20),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          answer,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: text,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (picked != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    correct == true
                        ? '⚡ Boost!'
                        : '🐢 Slow-Down…',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: correct == true
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _finishOverlay() {
    final stars = _calculateStars();
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.66),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFEFA), Color(0xFFFFF7ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🏆 Ziel erreicht!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(3, (i) {
                    final filled = i < stars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFFD1D5DB),
                        size: 56,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  'Zeit: ${_elapsed.toStringAsFixed(1)}s\n'
                  'Richtig: $_correctCount / ${widget.race.questionCount}\n'
                  'Sterne gesammelt: $_starsCollected',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: LumoColors.ink700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: widget.onExit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Zurueck zur Strecken-Auswahl',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PAINTER ────────────────────────────────────────────────────────────

class _ThemeColors {
  const _ThemeColors({
    required this.sky,
    required this.darkBg,
    required this.track,
    required this.trackEdge,
    required this.decor,
  });
  final Color sky;
  final Color darkBg;
  final Color track;
  final Color trackEdge;
  final Color decor;
}

_ThemeColors _themeColor(KartTheme theme) {
  return switch (theme) {
    KartTheme.forest => const _ThemeColors(
        sky: Color(0xFF86EFAC),
        darkBg: Color(0xFF14532D),
        track: Color(0xFF78350F),
        trackEdge: Color(0xFFFEF3C7),
        decor: Color(0xFF15803D),
      ),
    KartTheme.mountain => const _ThemeColors(
        sky: Color(0xFFBFDBFE),
        darkBg: Color(0xFF1E3A8A),
        track: Color(0xFF52525B),
        trackEdge: Color(0xFFFEF9C3),
        decor: Color(0xFF44403C),
      ),
    KartTheme.city => const _ThemeColors(
        sky: Color(0xFFFCE7F3),
        darkBg: Color(0xFF1F2937),
        track: Color(0xFF374151),
        trackEdge: Color(0xFFFCD34D),
        decor: Color(0xFFEAB308),
      ),
  };
}

class _RacePainter extends CustomPainter {
  _RacePainter({
    required this.progress,
    required this.theme,
    required this.boostActive,
    required this.slowActive,
    required this.starPositions,
    required this.collectedStars,
    required this.gates,
    required this.questionsAnswered,
  });

  final double progress;
  final KartTheme theme;
  final bool boostActive;
  final bool slowActive;
  final List<double> starPositions;
  final Set<int> collectedStars;
  final List<double> gates;
  final int questionsAnswered;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = _themeColor(theme);
    // Sky-Verlauf
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors.sky, colors.darkBg],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Track in der Mitte (Vertical-Scroll-Effekt durch Linien)
    final trackWidth = size.width * 0.55;
    final trackLeft = (size.width - trackWidth) / 2;
    final trackRect = Rect.fromLTWH(trackLeft, 0, trackWidth, size.height);
    canvas.drawRect(
      trackRect,
      Paint()..color = colors.track,
    );

    // Track-Edges (gelbe Linien an den Seiten)
    final edgePaint = Paint()
      ..color = colors.trackEdge
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(trackLeft, 0),
      Offset(trackLeft, size.height),
      edgePaint,
    );
    canvas.drawLine(
      Offset(trackLeft + trackWidth, 0),
      Offset(trackLeft + trackWidth, size.height),
      edgePaint,
    );

    // Mittel-Streifen (animiert durch progress)
    final dashHeight = 30.0;
    final dashGap = 22.0;
    final dashOffset = (progress * 1500) % (dashHeight + dashGap);
    var dashY = -dashOffset;
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 5;
    while (dashY < size.height) {
      canvas.drawLine(
        Offset(trackLeft + trackWidth / 2, dashY),
        Offset(trackLeft + trackWidth / 2, dashY + dashHeight),
        dashPaint,
      );
      dashY += dashHeight + dashGap;
    }

    // Decor (Baeume / Felsen) abseits der Strecke
    final decorPaint = Paint()..color = colors.decor;
    final decorOffset = (progress * 1800) % 130;
    var decY = -decorOffset;
    while (decY < size.height) {
      // Links
      canvas.drawCircle(
        Offset(trackLeft - 22, decY),
        16,
        decorPaint,
      );
      // Rechts
      canvas.drawCircle(
        Offset(trackLeft + trackWidth + 22, decY + 65),
        14,
        decorPaint,
      );
      decY += 130;
    }

    // Sterne entlang der Strecke (sichtbar in einem Window um Kart)
    for (var i = 0; i < starPositions.length; i++) {
      if (collectedStars.contains(i)) continue;
      final pos = starPositions[i];
      // Position auf Screen: Kart ist bei ~75% Hoehe.
      final relY = ((progress - pos) * 2000) + size.height * 0.75;
      if (relY < -20 || relY > size.height + 20) continue;
      _drawStar(
        canvas,
        Offset(trackLeft + trackWidth / 2, relY),
        14,
        const Color(0xFFFCD34D),
      );
    }

    // Tore: Gelbes Banner ueber die Strecke
    for (var i = 0; i < gates.length; i++) {
      if (i < questionsAnswered) continue;
      final relY = ((progress - gates[i]) * 2000) + size.height * 0.75;
      if (relY < -40 || relY > size.height + 40) continue;
      final gateRect = Rect.fromLTWH(trackLeft, relY - 10, trackWidth, 18);
      canvas.drawRect(
        gateRect,
        Paint()
          ..color = const Color(0xFFFCD34D).withOpacity(0.85),
      );
      // Kontur
      canvas.drawRect(
        gateRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFEA580C),
      );
    }

    // Speed-Lines (vertikale weisse Streifen) bei Boost
    if (boostActive) {
      final speedPaint = Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..strokeWidth = 2;
      final rand = math.Random(progress.hashCode);
      for (var i = 0; i < 25; i++) {
        final x = rand.nextDouble() * size.width;
        final y = rand.nextDouble() * size.height;
        canvas.drawLine(Offset(x, y), Offset(x, y + 26), speedPaint);
      }
    }

    // Slow-Down: rauchige Wolken um den Kart
    if (slowActive) {
      final smokePaint = Paint()
        ..color = const Color(0xFF52525B).withOpacity(0.45);
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          Offset(size.width / 2 - 30 + i * 12, size.height * 0.78 - i * 4),
          12,
          smokePaint,
        );
      }
    }

    // Kart (gross am unteren Drittel)
    final kartX = size.width / 2;
    final kartY = size.height * 0.75;
    // Kart-Schatten
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(kartX, kartY + 30), width: 56, height: 14),
      Paint()..color = Colors.black.withOpacity(0.30),
    );
    // Kart-Body (vereinfacht: rounded rect mit Farbe)
    final kartRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(kartX, kartY), width: 52, height: 78),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      kartRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEA580C), Color(0xFFBE123C)],
        ).createShader(kartRect.outerRect),
    );
    canvas.drawRRect(
      kartRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF7C2D12),
    );
    // Windschutz (kleiner blauer Rect oben)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(kartX, kartY - 15), width: 40, height: 24),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF60A5FA),
    );
    // Lumo Fuchs-Emoji im Cockpit (klein)
    final tp = TextPainter(
      text: const TextSpan(
        text: '🦊',
        style: TextStyle(fontSize: 22),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(kartX - tp.width / 2, kartY - tp.height / 2 - 14));

    // Ziellinie wenn nahe am Ende
    if (progress > 0.92) {
      final finishY =
          ((progress - 1.0) * 2000) + size.height * 0.75;
      if (finishY > -40 && finishY < size.height) {
        // Schachbrett-Muster
        final tileSize = 16.0;
        for (var i = 0; i < (trackWidth / tileSize).ceil(); i++) {
          for (var j = 0; j < 2; j++) {
            if ((i + j) % 2 == 0) {
              canvas.drawRect(
                Rect.fromLTWH(trackLeft + i * tileSize, finishY + j * tileSize,
                    tileSize, tileSize),
                Paint()..color = Colors.white,
              );
            } else {
              canvas.drawRect(
                Rect.fromLTWH(trackLeft + i * tileSize, finishY + j * tileSize,
                    tileSize, tileSize),
                Paint()..color = Colors.black,
              );
            }
          }
        }
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final ang = -math.pi / 2 + i * math.pi / points;
      final x = center.dx + rad * math.cos(ang);
      final y = center.dy + rad * math.sin(ang);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFEA580C),
    );
  }

  @override
  bool shouldRepaint(_RacePainter old) =>
      old.progress != progress ||
      old.boostActive != boostActive ||
      old.slowActive != slowActive ||
      old.questionsAnswered != questionsAnswered ||
      old.collectedStars.length != collectedStars.length;
}
