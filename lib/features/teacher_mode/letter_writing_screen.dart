// ════════════════════════════════════════════════════════════════════════
// LETTER WRITING SCREEN — Buchstaben-Schreibtraining
// ════════════════════════════════════════════════════════════════════════
// Heinz Feedback nach Build 88:
//   1. Bildschirm bewegte sich beim Schreiben (Scroll-Konflikt)
//   2. Linien waren nicht auf den Buchstaben ausgerichtet
//   3. Wunsch: oben A anzeigen, dann BUTTON zum Extra-Bildschirm wie
//      bei "Schreibe Wörter"
//
// Neue Struktur:
//   1. Übersichts-Screen: nur Anzeige Buchstabe + Button "Schreiben üben"
//   2. Vollbild-Schreibmodus (Modal): Linien perfekt ausgerichtet,
//      KEIN Scroll mehr - Kind kann ohne Verrutschen schreiben
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_voice.dart';
import 'lumo_akademie_screen.dart';

class LetterWritingScreen extends StatefulWidget {
  const LetterWritingScreen({
    super.key,
    required this.appState,
    required this.topic,
    required this.subject,
  });

  final LumoAppState appState;
  final LearningTopic topic;
  final LearningSubject subject;

  @override
  State<LetterWritingScreen> createState() => _LetterWritingScreenState();
}

class _LetterWritingScreenState extends State<LetterWritingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bigLetterCtrl;
  int _currentLetterIdx = 0;
  int _correctCount = 0;

  String get _letter => widget.topic.writingChars[_currentLetterIdx];

  @override
  void initState() {
    super.initState();
    _bigLetterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        LumoVoice.instance.speak('Heute lernen wir den Buchstaben $_letter!');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _bigLetterCtrl.dispose();
    super.dispose();
  }

  void _openPracticeMode() async {
    HapticFeedback.lightImpact();
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _LetterPracticeScreen(
          letter: _letter,
          gradient: widget.topic.gradient,
          letterNumber: _currentLetterIdx + 1,
          totalLetters: widget.topic.writingChars.length,
        ),
        fullscreenDialog: true,
      ),
    );
    if (completed == true) _markAsLearned();
  }

  void _markAsLearned() {
    HapticFeedback.mediumImpact();
    setState(() {
      _correctCount++;
      if (_currentLetterIdx + 1 >= widget.topic.writingChars.length) {
        _showFinish();
        return;
      }
      _currentLetterIdx++;
    });
    _bigLetterCtrl.reset();
    _bigLetterCtrl.forward();
    try {
      LumoVoice.instance.speak('Super! Jetzt das $_letter!');
    } catch (_) {}
  }

  void _showFinish() {
    final stars = (_correctCount / widget.topic.writingChars.length * 5)
        .round()
        .clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correctCount * 10);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFEF3C7),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Alle Buchstaben!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              'Du hast ${widget.topic.writingChars.length} Buchstaben geübt!',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
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
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Weiter zur Akademie',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: widget.topic.gradient[0])),
          ),
        ],
      ),
    );
  }

  void _previousLetter() {
    if (_currentLetterIdx == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _currentLetterIdx--);
    _bigLetterCtrl.reset();
    _bigLetterCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBigLetter(),
                  const SizedBox(height: 32),
                  _buildPracticeButton(),
                  const SizedBox(height: 16),
                  _buildHint(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final g = widget.topic.gradient;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: g),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: g[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                  'Buchstabe ${_currentLetterIdx + 1} / ${widget.topic.writingChars.length}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              Text(widget.topic.title,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
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
            Text('$_correctCount',
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

  Widget _buildBigLetter() {
    return AnimatedBuilder(
      animation: _bigLetterCtrl,
      builder: (_, __) {
        final t = Curves.easeOutBack.transform(_bigLetterCtrl.value);
        return Transform.scale(
          scale: 0.7 + t * 0.3,
          child: Opacity(
            opacity: _bigLetterCtrl.value,
            child: Column(
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.topic.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                          color: widget.topic.gradient[0].withOpacity(0.45),
                          blurRadius: 40,
                          offset: const Offset(0, 16))
                    ],
                  ),
                  child: Center(
                    child: Text(_letter,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 180,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 0.9,
                            shadows: [
                              Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 4))
                            ])),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Heute lernen wir den Buchstaben',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700)),
                Text('"$_letter"',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: widget.topic.gradient[0])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPracticeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: _openPracticeMode,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.topic.gradient),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: widget.topic.gradient[0].withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text('Schreiben üben',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Text('Tippe oben um zu üben - im Vollbild',
        style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600));
  }

  Widget _buildBottomNav() {
    final hasPrev = _currentLetterIdx > 0;
    final hasNext =
        _currentLetterIdx < widget.topic.writingChars.length - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: hasPrev ? _previousLetter : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: hasPrev ? Colors.white : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: hasPrev
                          ? widget.topic.gradient[0].withOpacity(0.5)
                          : const Color(0xFFE5E7EB),
                      width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        size: 18,
                        color: hasPrev
                            ? widget.topic.gradient[0]
                            : Colors.grey),
                    const SizedBox(width: 6),
                    Text('Voriger',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: hasPrev
                                ? widget.topic.gradient[0]
                                : Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (hasNext) {
                  setState(() => _currentLetterIdx++);
                  _bigLetterCtrl.reset();
                  _bigLetterCtrl.forward();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: hasNext ? Colors.white : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: hasNext
                          ? widget.topic.gradient[0].withOpacity(0.5)
                          : const Color(0xFFE5E7EB),
                      width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nächster',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: hasNext
                                ? widget.topic.gradient[0]
                                : Colors.grey)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        size: 18,
                        color: hasNext
                            ? widget.topic.gradient[0]
                            : Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// VOLLBILD-SCHREIBMODUS - kein Scroll, perfekt ausgerichtete Linien
// ════════════════════════════════════════════════════════════════════════

class _LetterPracticeScreen extends StatefulWidget {
  const _LetterPracticeScreen({
    required this.letter,
    required this.gradient,
    required this.letterNumber,
    required this.totalLetters,
  });
  final String letter;
  final List<Color> gradient;
  final int letterNumber;
  final int totalLetters;

  @override
  State<_LetterPracticeScreen> createState() => _LetterPracticeScreenState();
}

class _LetterPracticeScreenState extends State<_LetterPracticeScreen> {
  final List<List<List<Offset>>> _rows = [
    <List<Offset>>[],
    <List<Offset>>[],
    <List<Offset>>[],
    <List<Offset>>[],
  ];
  List<Offset>? _activeStroke;
  int _activeRow = -1;

  void _clearAll() {
    setState(() {
      for (final r in _rows) {
        r.clear();
      }
    });
  }

  void _clearRow(int row) {
    setState(() => _rows[row].clear());
  }

  bool get _hasAnything => _rows.any((r) => r.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      // KEIN SafeArea + KEIN Scroll - alles fest, sodass Kind ungestört schreiben kann
      body: Column(
        children: [
          // ── KOMPAKTE KOPFZEILE ─────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                8, MediaQuery.of(context).padding.top + 4, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.gradient),
              boxShadow: [
                BoxShadow(
                    color: widget.gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(widget.letter,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schreibe das "${widget.letter}" nach',
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                    Text(
                        'Buchstabe ${widget.letterNumber} / ${widget.totalLetters}',
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (_hasAnything)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 26),
                  onPressed: _clearAll,
                ),
            ]),
          ),
          // ── SCHREIBFLÄCHE - fest, kein Scroll ──────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (int row = 0; row < 4; row++) ...[
                    Expanded(
                      child: _PracticeRow(
                        letter: widget.letter,
                        gradient: widget.gradient,
                        strokes: _rows[row],
                        showHints: row == 0,
                        onPanStart: (offset) {
                          setState(() {
                            _activeRow = row;
                            _activeStroke = [offset];
                            _rows[row].add(_activeStroke!);
                          });
                        },
                        onPanUpdate: (offset) {
                          if (_activeRow != row) return;
                          setState(() {
                            _activeStroke?.add(offset);
                          });
                        },
                        onPanEnd: () {
                          _activeStroke = null;
                        },
                        onClear: () => _clearRow(row),
                      ),
                    ),
                    if (row < 3) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          // ── BOTTOM ACTIONS ─────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _clearAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFD1D5DB), width: 2),
                      ),
                      child: const Center(
                        child: Text('Alles löschen',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B7280))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: widget.gradient),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: widget.gradient[0].withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                        child: Text('Fertig ✓',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// EINE ÜBUNGSZEILE - mit korrekt ausgerichteten Schulheft-Linien
// ════════════════════════════════════════════════════════════════════════
// Heinz: 'die Linien musst mehr ausrichten auf das A jetzt hängt das A
// zwischen denn zeilen'
// Lösung: Geist-Buchstabe SITZT EXAKT zwischen Mittel- und Grundlinie.
//   Oberlinie (gestrichelt) bei 18% Höhe
//   Mittellinie (durchgehend gelb) bei 35% Höhe - CAPITAL TOP
//   Grundlinie (durchgehend orange, HAUPT) bei 75% Höhe - BASELINE
//   Unterlinie (gestrichelt) bei 90% Höhe
// Großbuchstabe FÜLLT exakt die Zone 35%..75%

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.letter,
    required this.gradient,
    required this.strokes,
    required this.showHints,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onClear,
  });
  final String letter;
  final List<Color> gradient;
  final List<List<Offset>> strokes;
  final bool showHints;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            return Stack(children: [
              // Schulheft-Linien (HINTER allem)
              CustomPaint(
                size: Size(c.maxWidth, c.maxHeight),
                painter: _SchoolLinesPainter(),
              ),
              // Geist-Buchstaben (nur erste Zeile als Hilfe)
              if (showHints)
                ..._buildGhostLetters(c.maxWidth, c.maxHeight),
              // Mal-Fläche (über allem)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => onPanStart(d.localPosition),
                onPanUpdate: (d) => onPanUpdate(d.localPosition),
                onPanEnd: (_) => onPanEnd(),
                child: CustomPaint(
                  size: Size(c.maxWidth, c.maxHeight),
                  painter: _StrokesPainter(
                    strokes: strokes,
                    color: gradient[0],
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
      // Clear-Button für diese Zeile
      if (strokes.isNotEmpty)
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 16, color: Colors.red.shade700),
            ),
          ),
        ),
    ]);
  }

  // ── GEIST-BUCHSTABEN: SITZEN EXAKT ZWISCHEN Mittel- und Grundlinie ──
  // Mittellinie 35% = Buchstaben-Oberkante (Capital Top)
  // Grundlinie  75% = Buchstaben-Unterkante (Baseline)
  // Höhe = 75% - 35% = 40% der Zeilenhöhe
  List<Widget> _buildGhostLetters(double w, double h) {
    final zoneTop = h * 0.35;
    final zoneBottom = h * 0.75;
    final zoneHeight = zoneBottom - zoneTop;
    // FontSize so dass die GLYPHE genau in die Zone passt
    // Nunito Bold: Capital Height ≈ 0.72 * fontSize
    final fontSize = zoneHeight / 0.72;
    final spacing = w / 4;
    return List.generate(3, (i) {
      return Positioned(
        // Positioniere so dass Baseline auf 75% liegt
        left: spacing * (i + 1) - fontSize * 0.35,
        top: zoneTop - fontSize * 0.10, // FontSize-Padding kompensieren
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: gradient[0].withOpacity(0.20),
            height: 1.0,
          ),
        ),
      );
    });
  }
}

// ── Schulheft-Hilfslinien (4-Linien-System Volksschule Österreich) ─────
class _SchoolLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    final thin = Paint()
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 1;
    final mid = Paint()
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 1.5;
    final base = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 2.0;

    // Volksschul-Schreibhefte haben 4 Linien:
    //   Oberlinie 18%  - gestrichelt (Oberlängen: K, L, T)
    //   Mittellinie 35% - durchgehend gelb (Capital Top)
    //   Grundlinie 75%  - durchgehend orange (Baseline - HAUPT!)
    //   Unterlinie 90% - gestrichelt (Unterlängen: g, p, q)
    _drawDashed(canvas, Offset(8, h * 0.18), Offset(w - 8, h * 0.18), thin);
    canvas.drawLine(Offset(8, h * 0.35), Offset(w - 8, h * 0.35), mid);
    canvas.drawLine(Offset(8, h * 0.75), Offset(w - 8, h * 0.75), base);
    _drawDashed(canvas, Offset(8, h * 0.90), Offset(w - 8, h * 0.90), thin);
  }

  void _drawDashed(Canvas c, Offset from, Offset to, Paint p) {
    const dashW = 6.0;
    const gap = 4.0;
    final dx = to.dx - from.dx;
    final n = dx ~/ (dashW + gap);
    for (int i = 0; i < n; i++) {
      final x1 = from.dx + i * (dashW + gap);
      c.drawLine(Offset(x1, from.dy), Offset(x1 + dashW, to.dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Strokes-Painter: zeichnet die Striche des Kindes ────────────────────
class _StrokesPainter extends CustomPainter {
  _StrokesPainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 3.5, Paint()..color = color);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) =>
      old.strokes.length != strokes.length ||
      (strokes.isNotEmpty &&
          old.strokes.isNotEmpty &&
          old.strokes.last.length != strokes.last.length) ||
      old.color != color;
}
