// ════════════════════════════════════════════════════════════════════════
// LUMO PHOTO-LEKTION — Hausaufgabe scannen → Lumo generiert Übungen
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 35: Heinz' Innovations-Plan Schritt 3 von 5. Tochter
// fotografiert die Hausaufgabe aus dem Schul-Heft, OCR liest den Text
// (lokal mit google_mlkit), ScannedWorkAnalysisEngine erkennt Fach +
// Thema, dann generiert die App 5 aehnliche Aufgaben zum Ueben mit
// Erklaerung aus den vorhandenen fachbezogenen Aufgabenvorlagen.
//
// Brueckenkopf von 'echtem Schul-Heft' zu 'in-App-Uebung'. Niemand sonst
// hat diesen Lehrplan-spezifischen Workflow.
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/scanned_work_analysis.dart';
import '../../core/progress_repository.dart';
import '../../core/lumo_feature_permissions.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/scan_screen.dart';
import 'photo_lesson_practice.dart';
import 'photo_lesson_session.dart';
import 'photo_lesson_practice_screen.dart';

class LumoPhotoLessonScreen extends StatefulWidget {
  const LumoPhotoLessonScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoPhotoLessonScreen> createState() => _LumoPhotoLessonScreenState();
}

class _LumoPhotoLessonScreenState extends State<LumoPhotoLessonScreen> {
  ScannedWorkAnalysis? _analysis;
  List<LumoTask> _exercises = const <LumoTask>[];
  String _practiceNotice = '';
  bool _scanning = false;
  bool _opening = false;
  LearningProfileLease? _lease;
  PhotoLessonSessionRepository? _sessions;
  PhotoLessonSession? _resume;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_profileChanged);
    unawaited(_restore());
  }

  @override
  void dispose() {
    widget.appState.removeListener(_profileChanged);
    super.dispose();
  }

  void _profileChanged() {
    final lease = _lease;
    if (!mounted ||
        lease == null ||
        (lease.generation == widget.appState.profileGeneration &&
            widget.appState.canUseLearningLease(lease))) {
      return;
    }
    setState(() {
      _lease = null;
      _sessions = null;
      _resume = null;
      _analysis = null;
      _exercises = const [];
      _scanning = false;
      _storageError =
          'Das Kinderprofil hat gewechselt. Lade die Foto-Lektion erneut.';
    });
  }

  Future<void> _restore() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _storageError = null;
    });
    try {
      final lease = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(lease);
      final repository = PhotoLessonSessionRepository(
        studentId: lease.studentId,
        mayWrite: () =>
            widget.appState.canUseLearningLease(lease) &&
            lease.generation == widget.appState.profileGeneration,
      );
      final session = await repository.load();
      if (!mounted || !widget.appState.isCurrentLearningLease(lease)) return;
      setState(() {
        _lease = lease;
        _sessions = repository;
        _resume = session;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _storageError =
            'Deine gespeicherten Foto-Übungen konnten noch nicht geladen werden.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openPractice({bool resume = false}) async {
    final repository = _sessions;
    final lease = _lease;
    if (_opening ||
        repository == null ||
        lease == null ||
        !widget.appState.isCurrentLearningLease(lease)) {
      return;
    }
    setState(() {
      _opening = true;
      _storageError = null;
    });
    try {
      // Finish a durable, accepted observation before replacing its view.
      final continuePending = _resume?.needsEvidenceSync == true;
      final session = resume || continuePending
          ? _resume!
          : PhotoLessonSession.start(_exercises);
      if (!resume && !continuePending) {
        await repository.save(session, replacing: _resume);
        _resume = session;
      }
      if (!mounted || !widget.appState.isCurrentLearningLease(lease)) return;
      await Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => PhotoLessonPracticeScreen(
              appState: widget.appState,
              lease: lease,
              repository: repository,
              session: session)));
      final updated = await repository.load();
      if (mounted && widget.appState.isCurrentLearningLease(lease)) {
        setState(() => _resume = updated);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _storageError =
            'Die Übungen warten noch aufs Speichern. Bitte erneut versuchen.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _startScan({bool reset = false}) async {
    if (!await LumoFeaturePermissions.camera(context, widget.appState) ||
        !mounted) {
      return;
    }
    setState(() {
      if (reset) {
        _analysis = null;
        _exercises = const [];
        _practiceNotice = '';
      }
      _scanning = true;
    });
  }

  void _onTextDetected(String text) {
    const engine = ScannedWorkAnalysisEngine();
    final analysis = engine.analyze(
      rawText: text,
      grade: widget.appState.state.grade,
      existingSkills: const <String, SkillRecord>{},
    );
    final exercises = _generateExercises(analysis);
    setState(() {
      _analysis = analysis;
      _exercises = exercises.tasks;
      _practiceNotice = exercises.notice;
      _scanning = false;
    });
  }

  PhotoLessonPractice _generateExercises(ScannedWorkAnalysis a) =>
      PhotoLessonPractice.generate(
        analysis: a,
        grade: widget.appState.state.grade,
        seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      );

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
      body: LumoSceneBackground(
        scene: LumoScene.library,
        dimmed: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_resume != null && !_scanning) ...[
                    FilledButton.icon(
                      key: const ValueKey('photo-resume'),
                      onPressed: _opening
                          ? null
                          : () => unawaited(_openPractice(resume: true)),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 52)),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(_resume!.complete
                          ? 'Gespeicherte Foto-Übungen ansehen'
                          : 'Foto-Übungen fortsetzen'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_storageError != null) ...[
                    Text(_storageError!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
                    OutlinedButton(
                        onPressed:
                            _opening ? null : () => unawaited(_restore()),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48)),
                        child: const Text('Lernstand erneut laden')),
                  ],
                  if (_opening && _sessions == null)
                    const LinearProgressIndicator(),
                  _scanning
                      ? ScanScreen(
                          onTextDetected: _onTextDetected,
                          onCancel: () => setState(() => _scanning = false),
                        )
                      : _analysis == null
                          ? _IntroPanel(
                              onCapture: _startScan,
                            )
                          : _ResultsPanel(
                              analysis: _analysis!,
                              exercises: _exercises,
                              practiceNotice: _practiceNotice,
                              onScanAgain: () => _startScan(reset: true),
                              onStartPractice: _opening || _sessions == null
                                  ? null
                                  : () => unawaited(_openPractice()),
                            ),
                ]),
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
                      child: LumoFoxPose(
                          pose: LumoDesignFoxPose.tabletThumb, size: 64),
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
    required this.practiceNotice,
    required this.onScanAgain,
    required this.onStartPractice,
  });

  final ScannedWorkAnalysis analysis;
  final List<LumoTask> exercises;
  final String practiceNotice;
  final VoidCallback onScanAgain;
  final VoidCallback? onStartPractice;

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
            // 2026-06-06 FIX: Single-side Border + borderRadius rendert nicht.
            border: Border.all(color: const Color(0xFF22C55E), width: 2),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    border:
                        Border.all(color: const Color(0xFFFCD34D), width: 1.3),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
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
        Text(
          exercises.isEmpty
              ? 'Passende Übungen'
              : '${exercises.length} Übungen zum Trainieren',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        if (practiceNotice.isNotEmpty && exercises.isNotEmpty) ...[
          Text(
            practiceNotice,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'Nunito', fontSize: 13),
          ),
          const SizedBox(height: 10),
        ],
        if (exercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              practiceNotice.isNotEmpty
                  ? practiceNotice
                  : 'Lumo konnte keine passenden Aufgaben generieren. '
                      'Versuch ein anderes Foto oder ein anderes Heft-Bild.',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LumoColors.ink700,
              ),
            ),
          )
        else ...[
          FilledButton.icon(
            key: const ValueKey('photo-start-practice'),
            onPressed: onStartPractice,
            style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
            icon: const Icon(Icons.touch_app_rounded),
            label: const Text('Jetzt selbst üben'),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < exercises.length; i++) ...[
            _ExerciseCard(index: i + 1, task: exercises[i]),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: onScanAgain,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
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

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.index, required this.task});
  final int index;
  final LumoTask task;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF123960),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4386B8)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55000000), offset: Offset(0, 5), blurRadius: 12)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'Aufgabe $index · ${task.subject} · ${Curriculum.prettifyUnit(task.unit)}',
              style: const TextStyle(color: Color(0xFFB8D5EE), fontSize: 13)),
          const SizedBox(height: 8),
          Text(task.prompt,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.35)),
        ]),
      );
}
