import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/learning_attempt_id.dart';
import '../../../core/lumo_sound.dart';
import '../../../domain/logic/logic_games.dart';
import '../../../domain/logic/logic_learning_profile.dart';
import '../../tests/cognitive_profile_screen.dart';
import '../../tests/iq/iq_style.dart';
import 'logic_progress_store.dart';
import 'logic_puzzle_screen.dart';
import 'logic_widgets.dart';

class LogicGamesScreen extends StatefulWidget {
  const LogicGamesScreen({
    super.key,
    required this.appState,
    this.store = const LogicProgressStore(),
  });
  final LumoAppState appState;
  final LogicProgressStore store;

  @override
  State<LogicGamesScreen> createState() => _LogicGamesScreenState();
}

class _LogicGamesScreenState extends State<LogicGamesScreen> {
  final _visit = newLearningAttemptId();
  LearningProfileLease? _owner;
  LogicProgress? _progress;
  LogicGameKind? _kind;
  String? _error;
  bool _busy = false;

  bool get _current =>
      _owner != null &&
      !widget.appState.backupBusy &&
      widget.appState.isCurrentLearningLease(_owner!);

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_profileChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    widget.appState.removeListener(_profileChanged);
    super.dispose();
  }

  void _profileChanged() {
    if (mounted && _owner != null && !_current) setState(() {});
  }

  Future<void> _load() async {
    try {
      final grade = widget.appState.state.grade.clamp(1, 4);
      final owner = _owner ?? await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      var progress = await widget.store.load(owner.studentId);
      if (!mounted) return;
      if (!widget.appState.isCurrentLearningLease(owner) ||
          widget.appState.backupBusy) {
        throw StateError(
            'The selected learning profile changed while loading.');
      }
      if (_owner == null &&
          progress.results.isEmpty &&
          progress.drafts.isEmpty) {
        progress = await widget.store.setGrade(
          owner.studentId,
          grade,
        );
      }
      await LumoSound.instance.init();
      if (!mounted) return;
      if (!widget.appState.isCurrentLearningLease(owner) ||
          widget.appState.backupBusy) {
        throw StateError(
            'The selected learning profile changed while loading.');
      }
      setState(() {
        _owner = owner;
        _progress = progress;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Dein Rätselstand konnte noch nicht geladen werden. Bitte versuche es erneut.',
        );
      }
    }
  }

  void _click() {
    if (widget.appState.state.settings.soundEnabled &&
        !widget.appState.state.settings.calmMode) {
      unawaited(LumoSound.instance.play(SoundEffect.click));
    }
  }

  Future<void> _grade(int grade) async {
    if (_busy || !_current) return;
    _click();
    setState(() => _busy = true);
    try {
      final progress = await widget.store.setGrade(_owner!.studentId, grade);
      if (mounted && _current) {
        setState(() {
          _progress = progress;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Die Klassenwahl konnte noch nicht gespeichert werden.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(LogicPuzzle puzzle) async {
    if (_busy ||
        !_current ||
        !_progress!.isUnlocked(puzzle.kind, puzzle.grade, puzzle.level)) {
      return;
    }
    _click();
    setState(() => _busy = true);
    try {
      final session = await widget.store.begin(
        profileId: _owner!.studentId,
        puzzle: puzzle,
        sessionId: _visit,
      );
      if (!mounted || !_current) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => LogicPuzzleScreen(
            appState: widget.appState,
            owner: _owner!,
            puzzle: puzzle,
            session: session,
            store: widget.store,
          ),
        ),
      );
      if (mounted && _current) await _load();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Das Rätsel konnte noch nicht geöffnet werden. Dein bisheriger Stand bleibt erhalten.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final title = _kind == null ? 'Logikspiele' : logicDisplayTitle(_kind!);
    return Scaffold(
      backgroundColor: logicNavy,
      body: LogicBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip:
                          _kind == null ? 'Zur Spielwelt' : 'Alle Logikspiele',
                      color: Colors.white,
                      onPressed: () {
                        if (_kind == null) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _kind = null);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(title,
                            semanticsLabel: _kind?.title ?? 'Logikspiele',
                            style: iqText(24))),
                    const Icon(Icons.auto_awesome_rounded, color: logicCyan),
                  ],
                ),
              ),
              Expanded(
                child: progress == null
                    ? Center(
                        child: _error == null
                            ? const CircularProgressIndicator(color: logicCyan)
                            : Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_error!, style: iqText(18)),
                                    const SizedBox(height: 16),
                                    LogicAction(
                                      label: 'Erneut laden',
                                      onPressed: _load,
                                    ),
                                  ],
                                ),
                              ),
                      )
                    : !_current
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Das Kinderprofil wurde gewechselt. Öffne die Logikspiele für das ausgewählte Kind erneut.',
                                style: iqText(19),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            key: const ValueKey('logic-scroll'),
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1080),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_error != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Text(
                                          _error!,
                                          style: iqText(
                                            15,
                                            color: const Color(0xFFFFD388),
                                          ),
                                        ),
                                      ),
                                    if (_kind == null) _hero(),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Deine Schulstufe',
                                      style: iqText(15, color: logicMuted),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 9,
                                      runSpacing: 8,
                                      children: [
                                        for (var grade = 1; grade <= 4; grade++)
                                          Semantics(
                                            selected:
                                                progress.selectedGrade == grade,
                                            child: LogicAction(
                                              key: ValueKey(
                                                  'logic-grade-$grade'),
                                              label: '$grade. Klasse',
                                              primary: progress.selectedGrade ==
                                                  grade,
                                              onPressed: _busy
                                                  ? null
                                                  : () => _grade(grade),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    if (_kind == null) ...[
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final textScale =
                                              MediaQuery.textScalerOf(context)
                                                      .scale(21) /
                                                  21;
                                          final minCardWidth = 300 *
                                              (textScale < 1 ? 1 : textScale);
                                          final columns =
                                              ((constraints.maxWidth + 16) /
                                                      (minCardWidth + 16))
                                                  .floor()
                                                  .clamp(1, 3);
                                          final width = (constraints.maxWidth -
                                                  (columns - 1) * 16) /
                                              columns;
                                          return Wrap(
                                            spacing: 16,
                                            runSpacing: 16,
                                            children: [
                                              for (final kind
                                                  in LogicGameKind.values)
                                                SizedBox(
                                                  width: width,
                                                  child:
                                                      _gameCard(kind, progress),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      _profileCard(progress),
                                    ] else ...[
                                      Text(
                                        'Ein Rätsel öffnet das nächste Abenteuer.',
                                        style: iqText(17, color: logicMuted),
                                      ),
                                      const SizedBox(height: 14),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final columns =
                                              constraints.maxWidth >= 700
                                                  ? 4
                                                  : constraints.maxWidth >= 480
                                                      ? 3
                                                      : 2;
                                          final width = (constraints.maxWidth -
                                                  (columns - 1) * 12) /
                                              columns;
                                          return Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              for (final puzzle
                                                  in LogicCatalog.levels(
                                                _kind!,
                                                progress.selectedGrade,
                                              ))
                                                SizedBox(
                                                  width: width,
                                                  child: _levelCard(
                                                    puzzle,
                                                    progress,
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() => ClipRRect(
        key: const ValueKey('logic-hero'),
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image:
                    AssetImage('assets/lumo_design/spielwelt/cover_logic.webp'),
                fit: BoxFit.cover,
                alignment: Alignment(0, -.25),
                excludeFromSemantics: true,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00071C38), Color(0xF2071C38)],
                  ),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 218),
              width: double.infinity,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dein Rätsel-Abenteuer',
                    key: const ValueKey('logic-hero-title'),
                    semanticsLabel: 'Dein Rätselabenteuer',
                    style: iqText(27, shadows: iqScrim),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entdecken. Ausprobieren. Weiterkommen.',
                    key: const ValueKey('logic-hero-subtitle'),
                    style: iqText(15, color: const Color(0xFFE1F5FF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _gameCard(LogicGameKind kind, LogicProgress progress) => LogicGlass(
        color: logicColor(kind),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(logicIcon(kind), color: logicColor(kind)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  logicDisplayTitle(kind),
                  key: ValueKey('logic-game-title-${kind.name}'),
                  semanticsLabel: kind.title,
                  style: iqText(21),
                )),
              ],
            ),
            LogicBoardPreview(kind: kind, grade: progress.selectedGrade),
            Text(kind.subtitle, style: iqText(16, color: logicMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.completedCount(
                              kind, progress.selectedGrade) /
                          12,
                      minHeight: 6,
                      color: logicColor(kind),
                      backgroundColor: const Color(0xFF102C48),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${progress.completedCount(kind, progress.selectedGrade)} / 12',
                  style: iqText(13, color: logicMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LogicAction(
              key: ValueKey('logic-game-${kind.name}'),
              label: 'Level entdecken',
              icon: Icons.arrow_forward_rounded,
              primary: true,
              onPressed: () {
                _click();
                setState(() => _kind = kind);
              },
            ),
          ],
        ),
      );

  Widget _levelCard(LogicPuzzle puzzle, LogicProgress progress) {
    final unlocked = progress.isUnlocked(
      puzzle.kind,
      puzzle.grade,
      puzzle.level,
    );
    final completed = progress.isCompleted(puzzle.id);
    final draft = progress.drafts.containsKey(puzzle.id);
    return LogicGlass(
      color: completed ? logicGreen : logicColor(puzzle.kind),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : unlocked
                        ? Icons.explore_rounded
                        : Icons.lock_outline_rounded,
                color: completed ? logicGreen : logicColor(puzzle.kind),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Level ${puzzle.level}', style: iqText(18))),
            ],
          ),
          const SizedBox(height: 12),
          Text(puzzle.title, style: iqText(15, color: logicMuted)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: LogicAction(
              key: ValueKey('logic-level-${puzzle.level}'),
              label: completed
                  ? 'Noch einmal'
                  : draft
                      ? 'Weiter'
                      : unlocked
                          ? 'Starten'
                          : 'Noch verschlossen',
              onPressed: unlocked && !_busy ? () => _open(puzzle) : null,
              primary: unlocked && !completed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(LogicProgress progress) {
    final profile = LogicLearningProfile.fromProgress(
      progress,
      grade: progress.selectedGrade,
      contentVersion: LogicCatalog.contentVersion,
    );
    return LogicGlass(
      color: logicGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: logicGreen),
              const SizedBox(width: 10),
              Expanded(child: Text('Meine Lernstärken', style: iqText(23))),
            ],
          ),
          const SizedBox(height: 14),
          for (final report in profile.reports)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: iqText(17, color: logicColor(report.kind)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.summary,
                    style: iqText(15, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.nextStep,
                    style: iqText(
                      14,
                      color: logicMuted,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            LogicLearningProfile.explanation,
            style: iqText(13, color: logicMuted, weight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          LogicAction(
            label: 'Weitere Knobeltests',
            icon: Icons.psychology_rounded,
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) =>
                    CognitiveProfileScreen(appState: widget.appState),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
