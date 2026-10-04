import 'package:flutter/material.dart';

import '../core/lumo_voice.dart';
import '../core/progress_recommendation_service.dart';
import '../features/agent/lumo_agent_content.dart';
import '../widgets/fox/lumo_companion_requests.dart';
import '../widgets/fox/lumo_animated_fox.dart';
import '../widgets/fox/lumo_free_companion.dart';
import 'app_state.dart';

/// Connects the visible fox to real learning records and existing app actions.
/// Recommendations never change a lesson until the child accepts them.
class LumoCompanionHost extends StatelessWidget {
  const LumoCompanionHost({
    super.key,
    required this.appState,
    required this.onSection,
    this.compact = false,
    this.section,
    this.subject,
    this.unit,
    this.onExplainTask,
    this.onSuggestTask,
    this.onAskLumo,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;
  final bool compact;
  final String? section;
  final String? subject;
  final String? unit;
  final VoidCallback? onExplainTask;
  final VoidCallback? onSuggestTask;
  final VoidCallback? onAskLumo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [appState, LumoCompanionRequests.instance.taskContext]),
      builder: (context, _) {
        final state = appState.state;
        final requestedSection = section ?? state.section.name;
        final reading = requestedSection == 'reading' ||
            (requestedSection == 'exercises' &&
                (state.subject.trim().toLowerCase() == 'lesen' ||
                    const ['aktives lesen', 'vorlesen']
                        .contains(state.unit.trim().toLowerCase())));
        final currentSection = reading ? 'reading' : requestedSection;
        final taskContext = currentSection == 'exercises'
            ? LumoCompanionRequests.instance.taskContext.value
            : null;
        final assessment = currentSection == 'tests' ||
            currentSection == 'schoolwork' ||
            (currentSection == 'exercises' &&
                (state.sessionKind == LumoSessionKind.test ||
                    state.sessionKind == LumoSessionKind.schoolwork));
        final hasTask = currentSection == 'exercises' || onExplainTask != null;
        final recommendation = const ProgressRecommendationService().recommend(
          grade: state.grade,
          skills: appState.learningSkills(),
          preferredSubject: subject,
        );
        return LumoFreeCompanion(
          compact: compact,
          reducedMotion: state.settings.reduceAnimations ||
              state.settings.calmMode ||
              MediaQuery.disableAnimationsOf(context),
          voiceEnabled: state.settings.voiceEnabled,
          message: state.lumoMessage,
          expression: switch (state.mood) {
            LumoMood.greet || LumoMood.wave => LumoFoxExpression.greet,
            LumoMood.point => LumoFoxExpression.explain,
            LumoMood.celebrate => LumoFoxExpression.celebrate,
            LumoMood.comfort => LumoFoxExpression.comfort,
            LumoMood.think => LumoFoxExpression.think,
            LumoMood.idle => LumoFoxExpression.idle,
          },
          scene: LumoCompanionScene(
            section: currentSection,
            childName: state.childName,
            recommendedSubject: subject ?? recommendation.subject,
            recommendedUnit: unit ?? recommendation.unit,
            solvedTasks: state.solved.values.fold(0, (a, b) => a + b),
            consecutiveWrong: state.practiceErrors,
            taskInProgress:
                (hasTask && (taskContext?.answering ?? true)) || reading,
            schoolwork: assessment,
            hasTask: hasTask,
          ),
          onAction: (action) {
            switch (action) {
              case LumoCompanionAction.suggestTask:
                if (assessment) return;
                if (onSuggestTask != null) {
                  onSuggestTask!();
                  return;
                }
                appState.update(state.copyWith(
                  subject: recommendation.subject,
                  unit: recommendation.unit,
                  sessionKind: recommendation.isTutoring
                      ? LumoSessionKind.tutoring
                      : LumoSessionKind.quickPractice,
                  lumoMessage: recommendation.message,
                  mood: LumoMood.point,
                ));
                onSection(LumoSection.exercises);
                return;
              case LumoCompanionAction.explainTask:
                if (assessment) return;
                if (onExplainTask != null) {
                  onExplainTask!();
                } else {
                  LumoCompanionRequests.instance.requestTaskHelp();
                }
                return;
              case LumoCompanionAction.askLumo:
                if (assessment) return;
                if (onAskLumo != null) {
                  onAskLumo!();
                } else {
                  showLumoConversation(context,
                      appState: appState, onSection: onSection);
                }
                return;
              case LumoCompanionAction.takeBreak:
                LumoVoice.instance.stop();
                return;
              case LumoCompanionAction.explainView:
              case LumoCompanionAction.explainApp:
                // The companion presents its context-specific guide itself.
                break;
            }
          },
        );
      },
    );
  }
}

Future<void> showLumoConversation(
  BuildContext context, {
  required LumoAppState appState,
  required ValueChanged<LumoSection> onSection,
}) async {
  final state = appState.state;
  final assessment = state.section == LumoSection.tests ||
      state.section == LumoSection.schoolwork ||
      (state.section == LumoSection.exercises &&
          (state.sessionKind == LumoSessionKind.test ||
              state.sessionKind == LumoSessionKind.schoolwork));
  if (assessment) {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Du schaffst das in deinem Tempo'),
              content: const Text('Im Test löst du die Aufgaben selbst. Danach '
                  'können wir zusammen üben und Fragen besprechen.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Weiter'))
              ],
            ));
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .82,
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 20),
            const Expanded(
                child: Text('Mit Lumo sprechen',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            IconButton(
              tooltip: 'Zurück zur Aufgabe',
              onPressed: () => Navigator.pop(sheetContext),
              icon: const Icon(Icons.close),
            ),
          ]),
          Expanded(
              child: LumoAgentContent(
            appState: appState,
            onSection: (section) {
              Navigator.pop(sheetContext);
              onSection(section);
            },
          )),
        ]),
      ),
    ),
  );
  await LumoVoice.instance.stop();
}
