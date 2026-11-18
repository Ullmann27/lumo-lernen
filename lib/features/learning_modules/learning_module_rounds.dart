import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/session_round_resume.dart';
import '../../domain/learning/practice_session_plan.dart';
import 'learning_module_progress.dart';

/// Thirty tasks in one go are too long for a primary school child. The long
/// Akademie modules therefore run in rounds of ten: after each round the
/// child may stop, and the module opens at that round the next time.
class LearningModuleRounds {
  LearningModuleRounds({
    required LearningModuleProgress progress,
    required this.totalTasks,
  })  : appState = progress.appState,
        _scope = 'module|${progress.subject}|${progress.unit}';

  /// For a module that saves its answers itself.
  LearningModuleRounds.forUnit({
    required this.appState,
    required String subject,
    required String unit,
    required this.totalTasks,
  }) : _scope = 'module|$subject|$unit';

  final LumoAppState appState;
  final int totalTasks;
  final String _scope;

  /// The round boundary saved for this child and module, if any.
  Future<SessionRoundPosition?> restore() =>
      appState.loadSessionRound(_scope, totalTasks: totalTasks);

  /// The whole module is done; next time it starts at round 1.
  void finished() {
    if (SessionRounds.applies(totalTasks)) {
      appState.saveSessionRound(_scope, null);
    }
  }

  /// Call after [completedTasks] tasks are finished. At the end of a round
  /// the position is saved and the child chooses: true continues with the
  /// next round, false means "Für heute aufhören" (the caller leaves).
  Future<bool> continueAfter(
    BuildContext context, {
    required int completedTasks,
    required int correct,
  }) async {
    if (!SessionRounds.endsRound(completedTasks, totalTasks)) return true;
    await appState.saveSessionRound(
        _scope,
        SessionRoundPosition(
            completedTasks: completedTasks,
            totalTasks: totalTasks,
            correct: correct));
    if (!context.mounted) return false;
    final round = SessionRounds.roundOf(completedTasks, totalTasks);
    final rounds = SessionRounds.count(totalTasks);
    final goOn = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          key: const ValueKey('module-round-break'),
          backgroundColor: const Color(0xFFFFFBEB),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Runde $round von $rounds geschafft!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937))),
          content: const Text(
              'Zehn Aufgaben sind fertig. Du kannst weitermachen oder für '
              'heute aufhören. Ich merke mir die Stelle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: Color(0xFF374151))),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowButtonSpacing: 8,
          actions: [
            TextButton(
              key: const ValueKey('module-round-stop'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFF92400E)),
              child: const Text('Für heute aufhören',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
            ),
            FilledButton(
              key: const ValueKey('module-round-continue'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: const Color(0xFF0E7490),
                  foregroundColor: Colors.white),
              child: Text('Weiter mit Runde ${round + 1}',
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
    return goOn ?? false;
  }
}
