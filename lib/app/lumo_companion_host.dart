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
    this.floating = false,
    this.section,
    this.subject,
    this.unit,
    this.onExplainTask,
    this.onSuggestTask,
    this.onAskLumo,
    this.menuPresenter,
    this.offerOnly = false,
    this.taskUnit,
    this.guide,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;
  final bool compact;
  final bool floating;
  final String? section;
  final String? subject;
  final String? unit;
  final VoidCallback? onExplainTask;
  final VoidCallback? onSuggestTask;
  final VoidCallback? onAskLumo;
  final LumoCompanionMenuPresenter? menuPresenter;
  final bool offerOnly;
  final String? taskUnit;
  final LumoCompanionGuide? guide;

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
        final published = LumoCompanionRequests.instance.taskContext.value;
        final taskContext = published?.belongsTo(
                        section: currentSection,
                        generation: appState.profileGeneration) ==
                    true &&
                (taskUnit == null || published?.unit == taskUnit)
            ? published
            : null;
        final assessment = currentSection == 'tests' ||
            currentSection == 'schoolwork' ||
            (currentSection == 'exercises' &&
                (state.sessionKind == LumoSessionKind.test ||
                    state.sessionKind == LumoSessionKind.schoolwork)) ||
            taskContext?.isExam == true;
        final hasTask = taskContext != null ||
            currentSection == 'exercises' ||
            onExplainTask != null;
        final recommendation = const ProgressRecommendationService().recommend(
          grade: state.grade,
          skills: appState.learningSkills(),
          preferredSubject: subject,
        );
        return LumoFreeCompanion(
          guide: guide,
          menuPresenter: menuPresenter,
          offerOnly: offerOnly,
          proactive: offerOnly
              ? taskContext != null && taskContext.lastCorrect == false
              : !const ['learning_module', 'guided_lesson', 'discovery']
                  .contains(taskContext?.activity),
          compact: compact,
          floating: floating,
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
            recommendedSubject:
                subject ?? taskContext?.subject ?? recommendation.subject,
            recommendedUnit: unit ?? taskContext?.unit ?? recommendation.unit,
            solvedTasks: state.solved.values.fold(0, (a, b) => a + b),
            consecutiveWrong: taskContext == null
                ? state.practiceErrors
                : taskContext.lastCorrect == false
                    ? taskContext.attempts
                    : 0,
            taskInProgress:
                (hasTask && (taskContext?.answering ?? true)) || reading,
            schoolwork: assessment,
            hasTask: hasTask,
            taskId: taskContext?.taskId ?? '',
            profileGeneration: appState.profileGeneration,
            helpLevel: taskContext?.helpLevel ?? 0,
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

/// Presents only the menu route. The lesson owns its task lease and must
/// revalidate it before dispatching the returned action.
Future<LumoCompanionAction?> showLumoCompanionMenu(
  BuildContext context, {
  required WidgetBuilder builder,
  required ValueChanged<ModalRoute<dynamic>?> onRouteChanged,
}) async {
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  final route = _LumoConversationRoute<LumoCompanionAction>(
    builder: builder,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    barrierLabel: localizations.scrimLabel,
    barrierOnTapHint:
        localizations.scrimOnTapHint(localizations.bottomSheetLabel),
    modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
    onRouteChanged: onRouteChanged,
    // The existing menu builder already contains its SafeArea.
    useSafeArea: false,
  );
  final action = await navigator.push<LumoCompanionAction>(route);
  await route.completed;
  return action;
}

Future<void> showLumoConversation(
  BuildContext context, {
  required LumoAppState appState,
  required ValueChanged<LumoSection> onSection,
  ValueChanged<ModalRoute<dynamic>?>? onRouteChanged,
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
  Widget buildSheet(BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .82,
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 20),
              const Expanded(
                  child: Text('Mit Lumo sprechen',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700))),
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
      );
  if (onRouteChanged == null) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: buildSheet,
    );
    // The agent releases only its own audio during disposal. A global stop
    // after this await could cut a new page's already accepted speech request.
  } else {
    final navigator = Navigator.of(context);
    final localizations = MaterialLocalizations.of(context);
    final route = _LumoConversationRoute<void>(
      builder: buildSheet,
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint:
          localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      onRouteChanged: onRouteChanged,
    );
    await navigator.push<void>(route);
    // Keep the caller's closing lease until the old agent has been disposed;
    // its cancellation must not hit an already reactivated lesson receiver.
    await route.completed;
    // The disposed agent has already released its audio. Do not issue another
    // global stop here: a new page may have claimed the transport meanwhile.
  }
}

/// Reports this exact sheet synchronously when another route covers it. A
/// lesson can retain its own conversation without accepting unrelated overlays.
class _LumoConversationRoute<T> extends ModalBottomSheetRoute<T> {
  _LumoConversationRoute({
    required super.builder,
    required super.capturedThemes,
    required super.barrierLabel,
    required super.barrierOnTapHint,
    required super.modalBarrierColor,
    required this.onRouteChanged,
    bool useSafeArea = true,
  }) : super(
            isScrollControlled: true,
            useSafeArea: useSafeArea,
            showDragHandle: true);

  final ValueChanged<ModalRoute<dynamic>?> onRouteChanged;
  bool? _reportedCurrent;
  bool _completed = false;

  void _report() {
    if (_completed || _reportedCurrent == isCurrent) return;
    _reportedCurrent = isCurrent;
    onRouteChanged(this);
  }

  @override
  TickerFuture didPush() {
    final result = super.didPush();
    _report();
    return result;
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    _report();
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    _report();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    onRouteChanged(null);
  }

  @override
  void didComplete(T? result) {
    _complete();
    super.didComplete(result);
  }

  @override
  void dispose() {
    _complete();
    super.dispose();
  }
}
