from pathlib import Path

ROOT = Path('.')
learning = ROOT / 'lib/features/learning/learning_content.dart'
renderer = ROOT / 'lib/features/learning/renderers/adaptive_task_renderer.dart'
proxy = ROOT / 'lib/core/lumo_ai_proxy_client.dart'


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    if old not in text:
        raise SystemExit(f'missing anchor: {label}')
    return text.replace(old, new, 1)


def insert_after(text: str, anchor: str, addition: str, label: str) -> str:
    if addition.strip() in text:
        return text
    if anchor not in text:
        raise SystemExit(f'missing anchor: {label}')
    return text.replace(anchor, anchor + addition, 1)


def insert_before(text: str, anchor: str, addition: str, label: str) -> str:
    if addition.strip() in text:
        return text
    if anchor not in text:
        raise SystemExit(f'missing anchor: {label}')
    return text.replace(anchor, addition + anchor, 1)


# 1) Proxy: controlled live tutor method.
p = proxy.read_text(encoding='utf-8')
p0 = p
proxy_method = """
  Future<LumoAiProxyResponse> explainTaskMistake({
    required AppSettings settings,
    required LumoSessionState state,
    required String subject,
    required String unit,
    required String prompt,
    required String childAnswer,
    required String correctAnswer,
    required int attemptCount,
  }) async {
    final taskPrompt = prompt.trim();
    final given = childAnswer.trim().isEmpty ? '(keine Antwort)' : childAnswer.trim();
    final expected = correctAnswer.trim();
    final tutorMessage = '''Du bist Lumo der Tutor in einer Grundschul-Lernapp.
Erkläre kindgerecht, freundlich und kurz, ohne zu beschämen.
Gib nicht nur die Lösung aus, sondern zeige den nächsten Denk-Schritt.
Fach: $subject
Einheit: $unit
Klasse: ${state.grade}
Aufgabe: $taskPrompt
Antwort des Kindes: $given
Richtige Lösung: $expected
Fehlversuch Nummer: $attemptCount
Antworte auf Deutsch in maximal 4 kurzen Sätzen.''';
    return ask(
      settings: settings,
      state: state,
      message: tutorMessage,
      history: const <LumoAiChatTurn>[],
    );
  }
"""
p = insert_before(p, '  Uri _tasksEndpoint(Uri baseUri) {\n', proxy_method, 'proxy explainTaskMistake')
if 'Future<LumoAiProxyResponse> explainTaskMistake' not in p:
    raise SystemExit('proxy method not installed')
proxy.write_text(p, encoding='utf-8')

# 2) LearningContent: policy guard, 2-error rule, live KI tutor with fallback.
l = learning.read_text(encoding='utf-8')
l0 = l
l = insert_after(
    l,
    "import '../../core/lumo_ai_proxy_client.dart';\n",
    "import '../../core/lumo_ai_learning_access.dart';\nimport '../../core/lumo_ai_policy_guard.dart';\n",
    'learning policy imports',
)
l = insert_after(
    l,
    '  static const LumoTutorEngine _localTutorEngine = LumoTutorEngine();\n',
    '  static const LumoAiPolicyGuard _aiPolicyGuard = LumoAiPolicyGuard();\n  static const LumoAiProxyClient _liveTutorClient = LumoAiProxyClient();\n',
    'learning tutor fields',
)
l = insert_after(
    l,
    '  String? _tutorHint;\n',
    "  bool _tutorLoading = false;\n  String _tutorSource = 'local';\n",
    'learning tutor state',
)
old_reset = """    _tutorHint = null;
    if (resetCounter) {"""
new_reset = """    _tutorHint = null;
    _tutorLoading = false;
    _tutorSource = 'local';
    if (resetCounter) {"""
l = replace_once(l, old_reset, new_reset, 'reset tutor state')
old_allow = """  bool get _allowHelp =>
      widget.appState.state.sessionKind != LumoSessionKind.schoolwork;
"""
new_allow = """  bool get _allowHelp =>
      widget.appState.state.sessionKind != LumoSessionKind.schoolwork;

  bool get _isTestLikeSession =>
      widget.appState.state.sessionKind == LumoSessionKind.test ||
      widget.appState.state.sessionKind == LumoSessionKind.schoolwork;

  bool get _allowsImmediateTutor =>
      widget.appState.state.sessionKind == LumoSessionKind.quickPractice ||
      widget.appState.state.sessionKind == LumoSessionKind.exerciseSet ||
      widget.appState.state.sessionKind == LumoSessionKind.tutoring;
"""
l = replace_once(l, old_allow, new_allow, 'learning mode helpers')
old_build = """  String? _buildTutorHint(Object answerGiven, List<ErrorType> errorTypes) {
    if (!_allowHelp || _attemptCount < 3) return null;
    final helpLevel = _localTutorEngine.decideHelpLevel(
      attemptCount: _attemptCount,
      hasRepeatedWeakness: false,
      premiumEnabled: true,
    );
    final mode = _localTutorEngine.decideMode(
      attemptCount: _attemptCount,
      hasRepeatedWeakness: false,
      isTestReview: widget.appState.state.sessionKind == LumoSessionKind.test,
    );
    final request = LumoTutorRequest(
      mode: mode,
      subject: _tutorSubjectFor(_task.subject),
      grade: widget.appState.state.grade,
      unit: _task.unit,
      helpLevel: helpLevel,
      childFirstName: _childFirstName,
      currentPrompt: _task.prompt,
      childAnswer: '$answerGiven',
      correctAnswer: '${_taskInstance.correctAnswer}',
      attemptCount: _attemptCount,
      weaknessTags: errorTypes.map((type) => type.name).toList(growable: false),
    );
    final response = _localTutorEngine.buildLocalFallback(request);
    return response.shortHint ?? response.explanation ?? response.speech;
  }
"""
new_build = """  String? _buildTutorHint(Object answerGiven, List<ErrorType> errorTypes) {
    if (_attemptCount < 2) return null;
    if (_isTestLikeSession) {
      return 'Lumo hat sich das notiert. Wir schauen es uns nach dem Test gemeinsam an.';
    }
    if (!_allowHelp) return null;
    final response = _localTutorEngine.buildLocalFallback(
      _tutorRequestFor(answerGiven, errorTypes, isTestReview: false),
    );
    return response.shortHint ?? response.explanation ?? response.speech;
  }

  LumoTutorRequest _tutorRequestFor(
    Object answerGiven,
    List<ErrorType> errorTypes, {
    required bool isTestReview,
  }) {
    final helpLevel = _localTutorEngine.decideHelpLevel(
      attemptCount: _attemptCount,
      hasRepeatedWeakness: false,
      premiumEnabled: true,
    );
    final mode = _localTutorEngine.decideMode(
      attemptCount: _attemptCount,
      hasRepeatedWeakness: false,
      isTestReview: isTestReview,
    );
    return LumoTutorRequest(
      mode: mode,
      subject: _tutorSubjectFor(_task.subject),
      grade: widget.appState.state.grade,
      unit: _task.unit,
      helpLevel: helpLevel,
      childFirstName: _childFirstName,
      currentPrompt: _task.prompt,
      childAnswer: '$answerGiven',
      correctAnswer: '${_taskInstance.correctAnswer}',
      attemptCount: _attemptCount,
      weaknessTags: errorTypes.map((type) => type.name).toList(growable: false),
    );
  }

  Future<void> _startLiveTutorHelp(Object answerGiven, List<ErrorType> errorTypes) async {
    if (!mounted || _attemptCount < 2 || !_allowsImmediateTutor) return;
    final localResponse = _localTutorEngine.buildLocalFallback(
      _tutorRequestFor(answerGiven, errorTypes, isTestReview: false),
    );
    final localText = localResponse.explanation ?? localResponse.shortHint ?? localResponse.speech;
    final settings = widget.appState.state.settings;
    if (!_aiPolicyGuard.allows(settings, LumoAiLearningArea.taskHelp)) {
      if (!mounted) return;
      setState(() {
        _tutorLoading = false;
        _tutorSource = 'local';
        _tutorHint = '${_aiPolicyGuard.blockedMessageFor(LumoAiLearningArea.taskHelp)} $localText';
      });
      return;
    }

    try {
      final response = await _liveTutorClient.explainTaskMistake(
        settings: settings,
        state: widget.appState.state,
        subject: _task.subject,
        unit: _task.unit,
        prompt: _task.prompt,
        childAnswer: '$answerGiven',
        correctAnswer: '${_taskInstance.correctAnswer}',
        attemptCount: _attemptCount,
      );
      if (!mounted) return;
      final proxyUnavailable = response.source.startsWith('local_') ||
          response.source == 'proxy_unreachable' ||
          response.source == 'proxy_error' ||
          response.source.startsWith('proxy_http_');
      setState(() {
        _tutorLoading = false;
        _tutorSource = proxyUnavailable ? 'local' : 'ki';
        _tutorHint = proxyUnavailable ? localText : response.reply;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tutorLoading = false;
        _tutorSource = 'local';
        _tutorHint = localText;
      });
    }
  }
"""
l = replace_once(l, old_build, new_build, 'live tutor methods')
old_attempt = """    if (correct) {
      _attemptCount = 0;
    } else if (_allowHelp) {
      _attemptCount++;
    }
    final nextTutorHint = correct ? null : _buildTutorHint(answerGiven, errorTypes);"""
new_attempt = """    if (correct) {
      _attemptCount = 0;
    } else {
      _attemptCount++;
    }
    final shouldStartLiveTutor = !correct && _attemptCount >= 2 && _allowsImmediateTutor;
    final nextTutorHint = correct
        ? null
        : shouldStartLiveTutor
            ? 'Lumo denkt nach und sucht eine gute Erklärung für dich ...'
            : _buildTutorHint(answerGiven, errorTypes);"""
l = replace_once(l, old_attempt, new_attempt, 'attempt and live tutor trigger')
old_set = """      _lastFeedback = feedback;
      _tutorHint = nextTutorHint;
    });"""
new_set = """      _lastFeedback = feedback;
      _tutorHint = nextTutorHint;
      _tutorLoading = shouldStartLiveTutor;
      _tutorSource = shouldStartLiveTutor ? 'loading' : 'local';
    });"""
l = replace_once(l, old_set, new_set, 'set tutor state')
old_else = """    } else {
      widget.appState.wrongAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: false, hintUsed: hintUsed);
      LumoVoice.instance.speak(feedback.spokenText);
    }"""
new_else = """    } else {
      widget.appState.wrongAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: false, hintUsed: hintUsed);
      LumoVoice.instance.speak(feedback.spokenText);
      if (shouldStartLiveTutor) {
        _startLiveTutorHelp(answerGiven, errorTypes);
      }
    }"""
l = replace_once(l, old_else, new_else, 'start live tutor after wrong answer')
old_banner_call = """                _TutorHintBanner(text: _tutorHint!),"""
new_banner_call = """                _TutorHintBanner(
                  text: _tutorHint!,
                  loading: _tutorLoading,
                  source: _tutorSource,
                ),"""
l = replace_once(l, old_banner_call, new_banner_call, 'tutor banner call')
old_banner_class = """class _TutorHintBanner extends StatelessWidget {
  const _TutorHintBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container("""
new_banner_class = """class _TutorHintBanner extends StatelessWidget {
  const _TutorHintBanner({required this.text, required this.loading, required this.source});

  final String text;
  final bool loading;
  final String source;

  @override
  Widget build(BuildContext context) {
    final icon = source == 'ki' ? '🤖' : '🦊';
    final label = loading
        ? 'Lumo denkt nach ...'
        : source == 'ki'
            ? 'KI-Tutor aktiv'
            : 'Lokale Lumo-Hilfe';
    return Container("""
l = replace_once(l, old_banner_class, new_banner_class, 'tutor banner class header')
old_icon = """          child: const Text('🦊', style: TextStyle(fontSize: 19)),"""
new_icon = """          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: LumoColors.orange),
                )
              : Text(icon, style: const TextStyle(fontSize: 19)),"""
l = replace_once(l, old_icon, new_icon, 'tutor banner icon')
old_label = """            const Text(
              'Lumo erklärt',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
            ),"""
new_label = """            Text(
              label,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
            ),"""
l = replace_once(l, old_label, new_label, 'tutor banner source label')
for check in [
    'Future<void> _startLiveTutorHelp',
    '_aiPolicyGuard.allows(settings, LumoAiLearningArea.taskHelp)',
    'shouldStartLiveTutor',
    'Lumo hat sich das notiert',
    'KI-Tutor aktiv',
]:
    if check not in l:
        raise SystemExit('learning check failed: ' + check)
learning.write_text(l, encoding='utf-8')

# 3) AdaptiveTaskRenderer: never-empty quantity visuals.
r = renderer.read_text(encoding='utf-8')
r0 = r
old_dots = """    final data = task.visualPayload.data;
    final operation = data['operation']?.toString() ?? 'addition';
    final left = _readInt(data['left']) ?? _readInt(data['start']) ?? 0;
    final right = _readInt(data['right']) ?? _readInt(data['takeAway']) ?? 0;"""
new_dots = """    final data = task.visualPayload.data;
    final parsed = _ArithmeticPrompt.tryParse(task.prompt);
    final operation = data['operation']?.toString() ?? parsed?.operation ?? 'addition';
    final left = _readInt(data['left']) ??
        _readInt(data['first']) ??
        _readInt(data['start']) ??
        parsed?.left ??
        0;
    final right = _readInt(data['right']) ??
        _readInt(data['second']) ??
        _readInt(data['takeAway']) ??
        _readInt(data['remove']) ??
        parsed?.right ??
        0;"""
r = replace_once(r, old_dots, new_dots, 'dots header')
old_final = """    return const SizedBox.shrink();
  }
}

int? _readInt(Object? value) {"""
new_final = """    final parsedArithmetic = _ArithmeticPrompt.tryParse(task.prompt);
    if (parsedArithmetic != null) {
      return _DotsVisual(task: task);
    }

    return const SizedBox.shrink();
  }
}

class _ArithmeticPrompt {
  const _ArithmeticPrompt({required this.operation, required this.left, required this.right});

  final String operation;
  final int left;
  final int right;

  static _ArithmeticPrompt? tryParse(String prompt) {
    final plus = RegExp(r'(\\d+)\\s*(?:\\+|plus|und)\\s*(\\d+)', caseSensitive: false).firstMatch(prompt);
    if (plus != null) {
      return _ArithmeticPrompt(
        operation: 'addition',
        left: int.tryParse(plus.group(1) ?? '') ?? 0,
        right: int.tryParse(plus.group(2) ?? '') ?? 0,
      );
    }
    final minus = RegExp(r'(\\d+)\\s*(?:-|minus|weg)\\s*(\\d+)', caseSensitive: false).firstMatch(prompt);
    if (minus != null) {
      return _ArithmeticPrompt(
        operation: 'subtraction',
        left: int.tryParse(minus.group(1) ?? '') ?? 0,
        right: int.tryParse(minus.group(2) ?? '') ?? 0,
      );
    }
    final numbers = RegExp(r'\\d+').allMatches(prompt).map((match) => int.tryParse(match.group(0) ?? '')).whereType<int>().toList(growable: false);
    if (numbers.length >= 2) {
      final lower = prompt.toLowerCase();
      final subtraction = lower.contains('minus') || lower.contains('weg') || lower.contains('bleiben') || lower.contains('wegnehmen');
      return _ArithmeticPrompt(
        operation: subtraction ? 'subtraction' : 'addition',
        left: numbers[0],
        right: numbers[1],
      );
    }
    return null;
  }
}

int? _readInt(Object? value) {"""
r = replace_once(r, old_final, new_final, 'arithmetic fallback helper')
for check in ['_ArithmeticPrompt.tryParse(task.prompt)', 'class _ArithmeticPrompt', '_DotsVisual(task: task)']:
    if check not in r:
        raise SystemExit('renderer check failed: ' + check)
renderer.write_text(r, encoding='utf-8')

changed = []
if p != p0:
    changed.append(str(proxy))
if l != l0:
    changed.append(str(learning))
if r != r0:
    changed.append(str(renderer))
if not changed:
    print('Integrated AI tutor patch already applied')
else:
    print('Patched files:')
    for item in changed:
        print(' - ' + item)
