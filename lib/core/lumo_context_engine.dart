import 'package:flutter/foundation.dart';

import '../app/app_state.dart';
import '../widgets/fox/lumo_companion_requests.dart';
import 'lumo_ai_learning_access.dart';
import 'lumo_ai_learning_policy_bridge.dart';
import 'lumo_ai_proxy_client.dart';
import 'lumo_learning_session_contract.dart';
import 'lumo_voice.dart';

/// Read-only adapter over the EXISTING application and task request bus.
/// No touch coordinates, transcript, rewards or invented progress are uploaded.
class LumoContextEngine extends ChangeNotifier {
  LumoContextEngine(this.appState, {LumoCompanionRequests? requests})
      : requests = requests ?? LumoCompanionRequests.instance {
    _scope = _scopeKey;
    _taskSnapshot = task?.semanticKey;
    appState.addListener(_changed);
    this.requests.taskContext.addListener(_taskChanged);
  }

  final LumoAppState appState;
  final LumoCompanionRequests requests;
  String _scope = '';
  String? _taskSnapshot;
  int revision = 0;

  /// A new help/step snapshot invalidates pending work without erasing the
  /// conversation about the same task. A profile/page/task change clears it.
  String get conversationScope => '$_scope|${task?.conversationKey ?? ''}';
  LumoLearningIdentity? get learningIdentity =>
      task == null ? null : requests.learningIdentity.value;

  LumoCompanionTaskContext? get task {
    final current = requests.taskContext.value;
    return current?.belongsTo(
                section: appState.state.section.name,
                generation: appState.profileGeneration) ==
            true
        ? current
        : null;
  }

  List<LumoInteractionKind> get recentInteractions =>
      requests.recentInteractions.value;

  String get _scopeKey {
    final s = appState.state;
    return '${appState.profileGeneration}|${s.childName}|${s.section.name}|${s.grade}|'
        '${s.subject}|${s.unit}|${s.sessionKind.name}|'
        '${s.settings.aiProxyEnabled}|${s.settings.aiLearningMode.name}|'
        '${s.settings.aiProxyUrl}|${s.settings.cloudVoiceEnabled}|'
        '${s.settings.microphoneEnabled}|${s.settings.voiceEnabled}|'
        '${s.settings.localVoiceLicenseAccepted}';
  }

  bool get isAssessment {
    final s = appState.state;
    return task?.isExam == true ||
        s.section == LumoSection.tests ||
        s.section == LumoSection.schoolwork ||
        (s.section == LumoSection.exercises &&
            (s.sessionKind == LumoSessionKind.test ||
                s.sessionKind == LumoSessionKind.schoolwork));
  }

  bool get lumoSpeaking =>
      LumoVoice.instance.status.value == VoiceStatus.speaking;

  LumoAiContext get aiContext => task == null
      ? LumoAiContext.companion
      : task!.activity == 'reading'
          ? LumoAiContext.readingBuddy
          : task!.activity == 'writing'
              ? LumoAiContext.writingHelper
              : task!.subject == 'Mathematik'
                  ? LumoAiContext.mathCoach
                  : LumoAiContext.learningTutor;

  Map<String, Object?> get remoteContext {
    final s = appState.state;
    final result = <String, Object?>{'section': s.section.name};
    if (isAssessment) return result;
    final area = s.section == LumoSection.reading
        ? LumoAiLearningArea.readingHelp
        : LumoAiLearningArea.taskHelp;
    if (!s.settings.lumoAiLearningAccess.allows(area)) return result;
    result.addAll(
        {'subject': task?.subject ?? s.subject, 'unit': task?.unit ?? s.unit});
    final t = task;
    if (t != null) {
      result.addAll({
        'taskPrompt': t.prompt,
        'attempt': t.attempts,
        'helpLevel': t.helpLevel,
        'taskStatus': t.isExplanation
            ? 'explaining'
            : t.answering
                ? 'answering'
                : 'completed',
        'activity': t.activity,
        if (t.lastCorrect != null) 'lastCorrect': t.lastCorrect,
        if (t.lastAnswer != null) 'lastAnswer': t.lastAnswer,
        if (t.previousHelp != null) 'previousHelp': t.previousHelp,
      });
    }
    return Map.unmodifiable(result);
  }

  void _changed() {
    final current = _scopeKey;
    if (_scope == current) return;
    _scope = current;
    _taskSnapshot = task?.semanticKey;
    revision++;
    notifyListeners();
  }

  void _taskChanged() {
    final snapshot = task?.semanticKey;
    if (snapshot == _taskSnapshot) return;
    _taskSnapshot = snapshot;
    revision++;
    notifyListeners();
  }

  @override
  void dispose() {
    appState.removeListener(_changed);
    requests.taskContext.removeListener(_taskChanged);
    super.dispose();
  }
}
