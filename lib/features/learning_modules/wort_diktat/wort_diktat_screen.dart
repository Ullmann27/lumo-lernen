// ════════════════════════════════════════════════════════════════════════
// WORT-DIKTAT — Klasse 1 Deutsch (interaktiv, Heinz-Wunsch)
// ════════════════════════════════════════════════════════════════════════
// Heinz Feedback: 'Wenn ein Kind ein Wort schreiben muss, darf es nicht
// gezeigt werden, erst am Schluss, und es wird nur angesagt.'
//
// Ablauf:
//   1) Lumo sagt das Wort vor (TTS, mehrmals wenn Kind tippt 'nochmal')
//   2) Kind sieht NICHT das Wort - schreibt frei auf Schulheft-Linien
//   3) 'Fertig'-Button -> das richtige Wort erscheint als Vergleich
//   4) Kind selbst-bewertet: 'Das war richtig' / 'Nochmal probieren'
//   5) Selbst-Bewertung -> Sterne (lernt Selbsteinschaetzung)
//
// 10 Woerter pro Session, vom einfachen zum schwierigeren.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class WortDiktatScreen extends StatefulWidget {
  const WortDiktatScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<WortDiktatScreen> createState() => _WortDiktatScreenState();
}

class _WortDiktatScreenState extends State<WortDiktatScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFF06B6D4),
    Color(0xFF0E7490),
  ];

  // Wortschatz Klasse 1 - vom leicht zum schwer
  static const List<String> _vocabulary = [
    'MAMA', 'PAPA', 'OMA', 'OPA',
    'BALL', 'AUTO', 'BAUM', 'SONNE',
    'HUND', 'KATZE', 'MAUS', 'VOGEL',
    'HAUS', 'KIND', 'BROT', 'APFEL',
    'MILCH', 'TISCH', 'STUHL', 'BLUME',
  ];

  late final AnimationController _entryCtrl;
  late final AnimationController _revealCtrl;
  final _rng = math.Random();
  late List<String> _sessionWords;

  int _taskIdx = 0;
  int _correctCount = 0;

  // 4 Schreibzeilen wie im Buchstaben-Modul
  final List<List<List<Offset>>> _rows = [
    <List<Offset>>[], <List<Offset>>[], <List<Offset>>[], <List<Offset>>[],
  ];

  bool _showReveal = false; // wird auf true wenn 'Fertig' gedrueckt

  String get _currentWord => _sessionWords[_taskIdx];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _sessionWords = List.of(_vocabulary)..shuffle(_rng);
    _sessionWords = _sessionWords.take(_totalTasks).toList();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sayWord());
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  void _sayWord() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('Schreibe das Wort: ${_currentWord.toLowerCase()}');
    } catch (_) {}
  }

  void _repeatWord() {
    HapticFeedback.selectionClick();
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak(_currentWord.toLowerCase());
    } catch (_) {}
  }

  void _clearAllStrokes() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final r in _rows) {
        r.clear();
      }
    });
  }

  bool get _hasAnything => _rows.any((r) => r.isNotEmpty);

  /// 'Fertig' gedrueckt -> Wort wird ENTHUELLT als Vergleich
  void _onFinish() {
    if (!_hasAnything) {
      // Sanfter Hinweis statt zu verhindern
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _gradient[1],
        content: const Text('Schreib zuerst das Wort - dann tippe Fertig!',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _showReveal = true);
    _revealCtrl.forward(from: 0);
    if (widget.appState.state.settings.voiceEnabled) {
      try {
        LumoVoice.instance
            .speak('So sieht das Wort ${_currentWord.toLowerCase()} aus. Vergleiche.');
      } catch (_) {}
    }
  }

  void _onSelfRate(bool wasCorrect) async {
    HapticFeedback.lightImpact();
    if (wasCorrect) {
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(8);
      try {
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
    } else {
      try {
        LumoVoice.instance.speak(LumoPhrases.wrongGentle());
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _nextTask();
  }

  void _nextTask() {
    if (_taskIdx + 1 >= _sessionWords.length) {
      _showFinish();
      return;
    }
    setState(() {
      _taskIdx++;
      _showReveal = false;
      for (final r in _rows) {
        r.clear();
      }
    });
    _entryCtrl.forward(from: 0);
    _sayWord();
  }

  void _showFinish() {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correctCount * 12);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Diktat fertig!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks richtig geschrieben!',
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
      body: Column(
        children: [
          _buildTopBar(),
          if (!_showReveal) ...[
            _buildHearWordBox(),
            Expanded(child: _buildWritingArea()),
            _buildBottomActions(),
          ] else
            Expanded(child: _buildRevealView()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, MediaQuery.of(context).padding.top + 4, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _gradient),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2))
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
              Text('Wort ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Wort-Diktat',
                  style: TextStyle(
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

  /// HEINZ' KERN-WUNSCH: Wort WIRD NICHT GEZEIGT, nur ein "Hör mir zu"-Box
  /// mit dem Lautsprecher-Button. Kind muss das Wort aus dem Klang erschliessen.
  Widget _buildHearWordBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: GestureDetector(
        onTap: _repeatWord,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradient[0].withOpacity(0.10), _gradient[1].withOpacity(0.15)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gradient[0].withOpacity(0.4), width: 2),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _gradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _gradient[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hör genau zu!',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _gradient[1])),
                  const SizedBox(height: 2),
                  const Text('Tippe für nochmal',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const Icon(Icons.touch_app_rounded,
                color: Color(0xFF6B7280), size: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildWritingArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        children: [
          for (int row = 0; row < 4; row++) ...[
            Expanded(
              child: _WritingRow(
                gradient: _gradient,
                strokes: _rows[row],
                onPanStart: (offset) {
                  setState(() => _rows[row].add([offset]));
                },
                onPanUpdate: (offset) {
                  if (_rows[row].isEmpty) return;
                  setState(() => _rows[row].last.add(offset));
                },
              ),
            ),
            if (row < 3) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearAllStrokes,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFD1D5DB), width: 2),
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
              onTap: _onFinish,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _gradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _gradient[0].withOpacity(0.4),
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
    );
  }

  /// HEINZ' KERN-WUNSCH: ERST AM SCHLUSS wird das Wort gezeigt.
  /// Kind sieht jetzt was es schreiben sollte + selbst-bewertet.
  Widget _buildRevealView() {
    return AnimatedBuilder(
      animation: _revealCtrl,
      builder: (_, child) {
        return Opacity(
          opacity: _revealCtrl.value,
          child: Transform.translate(
              offset: Offset(0, (1 - _revealCtrl.value) * 20), child: child),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 16),
          Text('Das richtige Wort war:',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          // Großes Wort als Vergleich
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: _gradient[0].withOpacity(0.5), width: 3),
              boxShadow: [
                BoxShadow(
                    color: _gradient[0].withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Text(_currentWord,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: _gradient[1],
                    letterSpacing: 4)),
          ),
          const SizedBox(height: 20),
          // Buchstaben einzeln als Hilfe zum Buchstaben-Vergleich
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _currentWord.split('').map((c) {
              return Container(
                width: 36,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _gradient[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _gradient[0].withOpacity(0.4), width: 1.5),
                ),
                child: Text(c,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _gradient[1])),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text('Wie war dein Wort?',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF374151))),
          const SizedBox(height: 14),
          // Selbst-Bewertung
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onSelfRate(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFFFCD34D), width: 2),
                  ),
                  child: const Column(children: [
                    Text('🤔', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 4),
                    Text('Nochmal\nüben',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF92400E))),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _onSelfRate(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFF10B981), width: 2),
                  ),
                  child: const Column(children: [
                    Text('🎉', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 4),
                    Text('Ich hatte\nes richtig!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF065F46))),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
              'Schau ehrlich auf dein geschriebenes Wort. Wenn du dich vertippt hast, sag "Nochmal üben".',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Schreibzeile mit Schulheft-Linien (wie im letter_writing)
// ────────────────────────────────────────────────────────────────────────

class _WritingRow extends StatelessWidget {
  const _WritingRow({
    required this.gradient,
    required this.strokes,
    required this.onPanStart,
    required this.onPanUpdate,
  });
  final List<Color> gradient;
  final List<List<Offset>> strokes;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          return Stack(children: [
            CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _SchoolLinesPainter(),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => onPanStart(d.localPosition),
              onPanUpdate: (d) => onPanUpdate(d.localPosition),
              child: CustomPaint(
                size: Size(c.maxWidth, c.maxHeight),
                painter: _StrokesPainter(
                    strokes: strokes, color: gradient[0]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

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
