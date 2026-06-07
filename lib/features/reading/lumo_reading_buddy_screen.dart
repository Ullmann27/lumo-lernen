// ════════════════════════════════════════════════════════════════════════
// LUMO READING BUDDY — Mit-Lese-Coach mit Voice-Recognition
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 34: Heinz' Innovations-Wunsch. Volksschuelerin liest
// einen Text laut, Lumo hoert via Mikrofon zu (speech_to_text deutsch
// AT) und vergleicht Wort fuer Wort. Jedes Wort wird farblich markiert:
//   - Grau: noch nicht gelesen
//   - Gruen: korrekt erkannt
//   - Gelb: aehnlich erkannt (Levenshtein 1-2)
//   - Orange-Unterstrichen: aktuell zu lesen (Cursor)
//
// Lumo-Pose-PNG reagiert: idle (Start) -> think (laeuft) -> cheer
// (>= 80% Accuracy am Ende) oder sad (< 50%). Es gibt nichts vergleich-
// bares fuer deutschsprachige Volksschueler.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_voice.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import 'reading_text_library.dart';
import 'voice_reading_evaluator.dart';

class LumoReadingBuddyScreen extends StatefulWidget {
  const LumoReadingBuddyScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoReadingBuddyScreen> createState() => _LumoReadingBuddyScreenState();
}

class _LumoReadingBuddyScreenState extends State<LumoReadingBuddyScreen> {
  ReadingText? _selectedText;
  final LumoSpeechListener _speech = LumoSpeechListener();
  final VoiceReadingEvaluator _eval = const VoiceReadingEvaluator();
  ReadingProgress? _progress;
  String _liveText = '';
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _speech.addListener(_onSpeechUpdate);
  }

  @override
  void dispose() {
    _speech.removeListener(_onSpeechUpdate);
    _speech.cancel();
    super.dispose();
  }

  void _onSpeechUpdate() {
    if (_selectedText == null) return;
    setState(() {
      // Hoere auf STT-Aenderungen, recompute progress
      final p = _eval.evaluate(
        targetWords: _selectedText!.words,
        recognizedText: _liveText,
      );
      _progress = p;
      if (p.isComplete && !_finished) {
        _finished = true;
        _speech.cancel();
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _startListening() async {
    if (_selectedText == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _liveText = '';
      _progress = null;
      _finished = false;
    });
    await _speech.startListening(
      onResult: (text) {
        setState(() {
          _liveText = text;
          _progress = _eval.evaluate(
            targetWords: _selectedText!.words,
            recognizedText: text,
          );
        });
      },
      onFinalResult: (text) {
        setState(() {
          _liveText = text;
          _progress = _eval.evaluate(
            targetWords: _selectedText!.words,
            recognizedText: text,
          );
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stopListening();
  }

  void _resetAndPickText() {
    _speech.cancel();
    setState(() {
      _selectedText = null;
      _progress = null;
      _liveText = '';
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedText == null) {
      return _TextPicker(
        grade: widget.appState.state.grade,
        onPick: (t) => setState(() => _selectedText = t),
      );
    }
    return _ReadingArena(
      text: _selectedText!,
      progress: _progress,
      isListening: _speech.listening,
      isInitialized: _speech.initialized,
      isAvailable: _speech.available,
      error: _speech.error,
      finished: _finished,
      onStart: _startListening,
      onStop: _stopListening,
      onBack: _resetAndPickText,
    );
  }
}

// ── TEXT-AUSWAHL ──────────────────────────────────────────────────────

class _TextPicker extends StatelessWidget {
  const _TextPicker({required this.grade, required this.onPick});
  final int grade;
  final ValueChanged<ReadingText> onPick;

  @override
  Widget build(BuildContext context) {
    final byGrade = <int, List<ReadingText>>{};
    for (final t in ReadingTextLibrary.all) {
      byGrade.putIfAbsent(t.grade, () => []).add(t);
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Reading Buddy',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: LumoMagicBackground(
        intensity: 1.0,
        starCount: 18,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Hero(),
                const SizedBox(height: 14),
                for (final g in [1, 2, 3, 4]) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: g == grade
                            ? const Color(0xFFFB923C)
                            : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Klasse $g',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  for (final t in (byGrade[g] ?? const <ReadingText>[])) ...[
                    _TextCard(text: t, onTap: () => onPick(t)),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
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
                'assets/companion/lumo_idle.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📖 Reading Buddy',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lies einen Text laut vor — Lumo hoert dir zu.\n'
                  'Wort fuer Wort wird gruen markiert.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEDE9FE),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.text, required this.onTap});
  final ReadingText text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            // 2026-06-06 FIX: Single-side Border + borderRadius = unsichtbar.
            border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.30), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(text.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                      ),
                    ),
                    Text(
                      '${text.words.length} Woerter · ${text.lines.length} Saetze',
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
              const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF6366F1), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LESE-ARENA ────────────────────────────────────────────────────────

class _ReadingArena extends StatelessWidget {
  const _ReadingArena({
    required this.text,
    required this.progress,
    required this.isListening,
    required this.isInitialized,
    required this.isAvailable,
    required this.error,
    required this.finished,
    required this.onStart,
    required this.onStop,
    required this.onBack,
  });

  final ReadingText text;
  final ReadingProgress? progress;
  final bool isListening;
  final bool isInitialized;
  final bool isAvailable;
  final String? error;
  final bool finished;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6366F1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        title: Text(
          text.title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (finished && progress != null)
                _FinishCard(progress: progress!)
              else
                _ReadingHeader(
                    progress: progress, isListening: isListening),
              const SizedBox(height: 14),
              _TextDisplay(text: text, progress: progress),
              const SizedBox(height: 16),
              if (error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF43F5E)),
                  ),
                  child: Text(
                    'Mikrofon-Fehler: $error',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF881337),
                    ),
                  ),
                ),
              if (!finished) ...[
                const SizedBox(height: 18),
                _MicButton(
                  isListening: isListening,
                  isAvailable: isAvailable || !isInitialized,
                  onStart: onStart,
                  onStop: onStop,
                ),
                const SizedBox(height: 10),
                Text(
                  isListening
                      ? 'Ich hoere dir zu... Lies langsam vor.'
                      : 'Tipp das Mikro an und lies den Text vor.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LumoColors.ink600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingHeader extends StatelessWidget {
  const _ReadingHeader({required this.progress, required this.isListening});
  final ReadingProgress? progress;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final pct = progress == null ? 0.0 : progress!.accuracy;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF6366F1), width: 1.6),
            ),
            child: ClipOval(
              child: Image.asset(
                isListening
                    ? 'assets/companion/lumo_think.png'
                    : 'assets/companion/lumo_idle.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isListening
                      ? 'Lumo hoert zu …'
                      : 'Bereit zum Lesen?',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4338CA),
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEEF2FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(pct * 100).round()}% richtig',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: LumoColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextDisplay extends StatelessWidget {
  const _TextDisplay({required this.text, required this.progress});
  final ReadingText text;
  final ReadingProgress? progress;

  @override
  Widget build(BuildContext context) {
    final statuses = progress?.statuses ??
        List<ReadingWordStatus>.filled(
            text.words.length, ReadingWordStatus.pending);
    final currentIdx = progress?.currentIndex ?? 0;
    var wordCounter = 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFEFA), Color(0xFFFFF7E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        // 2026-06-06 FIX: non-uniform Border + borderRadius rendert nicht.
        border: Border.all(color: const Color(0xFFFB923C), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFB923C).withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in text.lines) ...[
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: line
                  .split(RegExp(r'\s+'))
                  .where((w) => w.isNotEmpty)
                  .map((word) {
                final idx = wordCounter++;
                final status = idx < statuses.length
                    ? statuses[idx]
                    : ReadingWordStatus.pending;
                final isCurrent = idx == currentIdx;
                return _WordChip(
                    word: word, status: status, isCurrent: isCurrent);
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.word,
    required this.status,
    required this.isCurrent,
  });

  final String word;
  final ReadingWordStatus status;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg = Colors.transparent;
    FontWeight weight = FontWeight.w800;
    Color? decorationColor;
    TextDecoration deco = TextDecoration.none;

    switch (status) {
      case ReadingWordStatus.matched:
        color = const Color(0xFF14532D);
        bg = const Color(0xFFBBF7D0);
        break;
      case ReadingWordStatus.partial:
        color = const Color(0xFF92400E);
        bg = const Color(0xFFFEF3C7);
        break;
      case ReadingWordStatus.pending:
        color = const Color(0xFF1F2937);
        break;
    }
    if (isCurrent && status == ReadingWordStatus.pending) {
      deco = TextDecoration.underline;
      decorationColor = const Color(0xFFFB923C);
      weight = FontWeight.w900;
      color = const Color(0xFFEA580C);
    }

    return Container(
      padding: bg == Colors.transparent
          ? const EdgeInsets.symmetric(horizontal: 2, vertical: 1)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: bg == Colors.transparent
          ? null
          : BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
      child: Text(
        word,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: weight,
          color: color,
          decoration: deco,
          decorationColor: decorationColor,
          decorationThickness: 2.5,
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.isListening,
    required this.isAvailable,
    required this.onStart,
    required this.onStop,
  });

  final bool isListening;
  final bool isAvailable;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isListening ? onStop : (isAvailable ? onStart : null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isListening
              ? const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFFB7185)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
          boxShadow: [
            BoxShadow(
              color: (isListening
                      ? const Color(0xFFEC4899)
                      : const Color(0xFF6366F1))
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}

class _FinishCard extends StatelessWidget {
  const _FinishCard({required this.progress});
  final ReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.accuracy * 100).round();
    final stars = progress.accuracy >= 0.85
        ? 3
        : progress.accuracy >= 0.6
            ? 2
            : progress.accuracy >= 0.4
                ? 1
                : 0;
    final asset = stars >= 2
        ? 'assets/companion/lumo_cheer.png'
        : 'assets/companion/lumo_sad.png';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stars >= 2
              ? const [Color(0xFFDCFCE7), Color(0xFFA7F3D0)]
              : const [Color(0xFFFEF3C7), Color(0xFFFCD34D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stars >= 2 ? 'Spitze gelesen!' : 'Gut gemacht!',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$pct% erkannt · ${progress.matchedCount}/${progress.totalWords} Worter perfekt',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: LumoColors.ink600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List<Widget>.generate(3, (i) {
                    final filled = i < stars;
                    return Icon(
                      filled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: filled
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFFD1D5DB),
                      size: 28,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
