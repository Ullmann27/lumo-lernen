// ════════════════════════════════════════════════════════════════════════
// LUMO PHOTO-LEKTION — Hausaufgabe scannen → Lumo generiert Übungen
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 35: Heinz' Innovations-Plan Schritt 3 von 5. Tochter
// fotografiert die Hausaufgabe aus dem Schul-Heft, OCR liest den Text
// (lokal mit google_mlkit), ScannedWorkAnalysisEngine erkennt Fach +
// Thema, dann generiert die App 5 aehnliche Aufgaben zum Ueben mit
// Step-by-Step-Loesung aus dem MathTaskTemplate-System.
//
// Brueckenkopf von 'echtem Schul-Heft' zu 'in-App-Uebung'. Niemand sonst
// hat diesen Lehrplan-spezifischen Workflow.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/math_task_templates.dart';
import '../../core/scanned_work_analysis.dart';
import '../../core/progress_repository.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../../widgets/scan_screen.dart';

class LumoPhotoLessonScreen extends StatefulWidget {
  const LumoPhotoLessonScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoPhotoLessonScreen> createState() => _LumoPhotoLessonScreenState();
}

class _LumoPhotoLessonScreenState extends State<LumoPhotoLessonScreen> {
  ScannedWorkAnalysis? _analysis;
  List<MathConcreteTask> _exercises = const <MathConcreteTask>[];
  bool _scanning = false;

  void _onTextDetected(String text) {
    final engine = const ScannedWorkAnalysisEngine();
    final analysis = engine.analyze(
      rawText: text,
      grade: widget.appState.state.grade,
      existingSkills: const <String, SkillRecord>{},
    );
    final exercises = _generateExercises(analysis);
    setState(() {
      _analysis = analysis;
      _exercises = exercises;
      _scanning = false;
    });
  }

  List<MathConcreteTask> _generateExercises(ScannedWorkAnalysis a) {
    final out = <MathConcreteTask>[];
    final unit = a.nextPracticeUnit;
    for (var i = 0; i < 5; i++) {
      try {
        final task = MathTaskTemplates.generate(
          grade: widget.appState.state.grade,
          unit: unit,
          seed:
              (DateTime.now().millisecondsSinceEpoch + i * 7919) & 0x7fffffff,
        );
        out.add(task);
      } catch (_) {
        // Skip wenn Template-Engine bei dieser Kombination versagt.
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Foto-Lektion',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: LumoMagicBackground(
        intensity: 1.0,
        starCount: 18,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _scanning
                ? ScanScreen(
                    onTextDetected: _onTextDetected,
                    onCancel: () => setState(() => _scanning = false),
                  )
                : _analysis == null
                    ? _IntroPanel(
                        onCapture: () => setState(() => _scanning = true),
                      )
                    : _ResultsPanel(
                        analysis: _analysis!,
                        exercises: _exercises,
                        onScanAgain: () => setState(() {
                          _analysis = null;
                          _exercises = const [];
                          _scanning = true;
                        }),
                      ),
          ),
        ),
      ),
    );
  }
}

// ── INTRO ──────────────────────────────────────────────────────────────

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.onCapture});
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF15803D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
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
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/companion/lumo_think.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🦊', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📸 Foto-Lektion',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Foto vom Heft → Lumo erkennt Fach + Thema → 5 Uebungen!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDCFCE7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _StepRow(
            num: '1',
            text: 'Mach ein Foto von deiner Aufgabe.',
            color: const Color(0xFFEA580C)),
        const SizedBox(height: 10),
        _StepRow(
            num: '2',
            text: 'Lumo liest den Text und erkennt das Thema.',
            color: const Color(0xFF6366F1)),
        const SizedBox(height: 10),
        _StepRow(
            num: '3',
            text: 'Du bekommst 5 aehnliche Uebungen zum Trainieren.',
            color: const Color(0xFF22C55E)),
        const SizedBox(height: 26),
        GestureDetector(
          onTap: onCapture,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
              ),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'Foto aufnehmen',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.num, required this.text, required this.color});
  final String num;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              num,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── RESULTS ────────────────────────────────────────────────────────────

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.analysis,
    required this.exercises,
    required this.onScanAgain,
  });

  final ScannedWorkAnalysis analysis;
  final List<MathConcreteTask> exercises;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analyse-Karte
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
                left: BorderSide(
                    color: const Color(0xFF22C55E), width: 5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '✓ ${analysis.workTypeLabel}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      analysis.subject,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Thema: ${analysis.primaryUnit}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                analysis.childSummary,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: LumoColors.ink600,
                  height: 1.35,
                ),
              ),
              if (analysis.practiceTip.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFCD34D), width: 1.3),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡',
                          style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analysis.practiceTip,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF78350F),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '5 Übungen zum Trainieren',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        if (exercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Lumo konnte keine passenden Aufgaben generieren. '
              'Versuch ein anderes Foto oder ein anderes Heft-Bild.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LumoColors.ink700,
              ),
            ),
          )
        else
          for (var i = 0; i < exercises.length; i++) ...[
            _ExerciseCard(index: i + 1, task: exercises[i]),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: onScanAgain,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Neues Foto aufnehmen',
                    style: TextStyle(
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
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({required this.index, required this.task});
  final int index;
  final MathConcreteTask task;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6366F1),
                ),
                child: Text(
                  '${widget.index}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.task.prompt,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showAnswer = !_showAnswer),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showAnswer
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: _showAnswer
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF6366F1),
                  width: 1.3,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showAnswer
                        ? Icons.lightbulb_rounded
                        : Icons.lightbulb_outline_rounded,
                    color: _showAnswer
                        ? const Color(0xFF14532D)
                        : const Color(0xFF4338CA),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showAnswer
                        ? 'Antwort: ${widget.task.answer}'
                        : 'Antwort zeigen',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _showAnswer
                          ? const Color(0xFF14532D)
                          : const Color(0xFF4338CA),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showAnswer && widget.task.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.task.explanation,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C2D12),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
