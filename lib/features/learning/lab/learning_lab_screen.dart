import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/app_state.dart';
import '../../../core/learning_journey.dart';
import '../../../core/lumo_learning_narration.dart';
import '../../../core/progress_repository.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../learning_modules/learning_module_progress.dart';
import 'learning_lab_catalog.dart';
import 'learning_manipulatives.dart';

enum _Phase { example, build, recall, transfer, reflection }

/// Offline learning session, using only existing profile-safe persistence.
class LearningLabScreen extends StatefulWidget {
  const LearningLabScreen({super.key, required this.appState,
      required this.topic, this.seed = 0});
  final LumoAppState appState;
  final LabTopic topic;
  final int seed;
  @override
  State<LearningLabScreen> createState() => _LearningLabScreenState();
}

class _LearningLabScreenState extends State<LearningLabScreen> {
  late final LearningModuleProgress _progress = LearningModuleProgress(
      appState: widget.appState, subject: widget.topic.subject,
      unit: widget.topic.unit);
  final _narration = LumoLearningNarration();
  final _fox = LumoCharacterController();
  final _answer = TextEditingController();
  LearningProfileLease? _lease;
  _Phase _phase = _Phase.example;
  bool _loading = true, _invalid = false, _busy = false, _done = false;
  bool _wrongBefore = false;
  int _hint = 0, _moved = 0, _attempt = 0;
  Set<int> _pieces = <int>{};
  List<int> _tokens = <int>[];
  String _feedback = '';
  late final String _sessionId =
      'lab-' + DateTime.now().microsecondsSinceEpoch.toString();

  bool get _reduced => widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode;
  LabProblem _problem(int index) => widget.topic.problems[
      (widget.seed + index) % widget.topic.problems.length];
  LabProblem get _current => _problem(switch (_phase) {
      _Phase.example => 0, _Phase.build => 1,
      _Phase.recall => 2, _Phase.transfer || _Phase.reflection => 3});
  bool get _safe => !_invalid && _lease != null &&
      widget.appState.isCurrentLearningLease(_lease!) &&
      widget.appState.state.grade >= widget.topic.minimumGrade;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_checkProfile);
    _progress.addListener(_repaint);
    _narration.addListener(_repaint);
    unawaited(_load());
  }
  Future<void> _load() async {
    try {
      final lease = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(lease);
      await lease.profile.loadJourney();
      if (!mounted) return;
      setState(() {
        _lease = lease;
        _invalid = !widget.appState.isCurrentLearningLease(lease);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _invalid = true; _loading = false; });
    }
  }
  void _checkProfile() {
    if (!mounted || _lease == null || _invalid) return;
    if (!widget.appState.isCurrentLearningLease(_lease!) ||
        widget.appState.state.grade < widget.topic.minimumGrade) {
      setState(() => _invalid = true);
      unawaited(_narration.stop());
    }
  }
  void _repaint() { if (mounted) setState(() {}); }
  String _id() => _sessionId + '-' + (++_attempt).toString();
  Future<void> _read(String text, {bool automatic = false}) async {
    final settings = widget.appState.state.settings;
    if (!_safe || !mounted || !settings.voiceEnabled ||
        (automatic && !settings.autoReadEnabled) ||
        ModalRoute.of(context)?.isCurrent != true) return;
    try {
      if (automatic) {
        await _narration.feedback(text);
      } else {
        _fox.talk();
        await _narration.read(text);
      }
    } catch (_) {
      // The existing voice player may be unavailable. Text stays readable.
    }
  }
  bool _modelValid() => switch (_current.mode) {
    LabMode.bridge => _moved == _current.modelTarget,
    LabMode.fraction => _pieces.length == _current.modelTarget,
    LabMode.word || LabMode.english || LabMode.nature =>
        _current.modelAccepts(_tokens)
  };
  Future<void> _checkModel() async {
    if (!_safe || _busy || _done || _progress.hasPending) return;
    if (!_modelValid()) {
      setState(() => _feedback =
          'Fast! Prüfe die Reihenfolge und baue das Modell noch einmal.');
      _fox.think();
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await _progress.saveObservation(LearningEvidence(
          taskId: _id(), problemId: _current.id, correct: true, helpLevel: 3));
      if (!mounted || !_safe) return;
      setState(() {
        _busy = false;
        _done = ok;
        _feedback = ok ? 'Gut gebaut! Jetzt kommt eine neue Aufgabe.' :
            'Dein Lernschritt wurde nicht gespeichert.';
      });
      if (ok) { _fox.cheer(); unawaited(_read(_feedback, automatic: true)); }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> _checkAnswer() async {
    if (!_safe || _busy || _done || _progress.hasPending) return;
    final text = _answer.text.trim();
    if (text.isEmpty) {
      setState(() => _feedback = 'Trage zuerst deine Antwort ein.');
      return;
    }
    final p = _current;
    final correct = p.accepts(text);
    final support = _wrongBefore ? (_hint > 0 ? _hint : 1) : _hint;
    final evidence = LearningEvidence(
        taskId: _id(), problemId: p.id, correct: correct,
        helpLevel: support, transferCheck: _phase == _Phase.transfer,
        errorTag: correct ? null : p.errorTag(text));
    setState(() => _busy = true);
    try {
      final ok = await _progress.saveAnswer(
          correct: correct, hintUsed: support > 0, prompt: p.prompt,
          given: text, expected: p.expected, learningEvidence: evidence);
      if (!mounted || !_safe) return;
      final response = correct
          ? support == 0 ? 'Richtig! Ganz selbstständig geschafft.' :
              'Richtig! Diese Antwort war noch mit Hilfe.'
          : p.feedback(text);
      setState(() {
        _busy = false;
        _done = ok && correct;
        if (ok) { _wrongBefore = !correct; _feedback = response; }
        else { _invalid = true; _feedback = 'Lernprofil nicht mehr aktiv.'; }
      });
      if (ok) {
        if (correct) { _fox.cheer(); } else { _fox.think(); }
        unawaited(_read(response, automatic: true));
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }
  void _next() {
    if (!_safe || _busy || _progress.hasPending ||
        (_phase != _Phase.example && !_done) ||
        _phase == _Phase.reflection) return;
    unawaited(_narration.stop());
    setState(() {
      _phase = _Phase.values[_phase.index + 1];
      _moved = 0; _pieces = <int>{}; _tokens = <int>[];
      _hint = 0; _wrongBefore = false; _done = false;
      _feedback = ''; _answer.clear();
    });
  }
  void _help() {
    if (!_safe || _done || _hint >= 5) return;
    setState(() { _hint++; _feedback = _current.hints[_hint - 1]; });
    _fox.think(); unawaited(_read(_feedback));
  }
  Widget _model(LabProblem p, bool enabled) => switch (p.mode) {
    LabMode.bridge => QuantityBridgeBoard(
      start: p.start, addend: p.addend, moved: _moved,
      onChanged: (n) => setState(() => _moved = n),
      enabled: enabled, reduceMotion: _reduced, reveal: _hint >= 3),
    LabMode.fraction => FractionBuildBoard(
      denominator: p.denominator, selected: _pieces,
      onChanged: (n) => setState(() => _pieces = n),
      enabled: enabled, reduceMotion: _reduced),
    LabMode.word || LabMode.english || LabMode.nature =>
      LearningTokenWorkbench(tokens: p.tokens, selected: _tokens,
        onChanged: (n) => setState(() => _tokens = n),
        enabled: enabled, reduceMotion: _reduced),
  };
  Widget _button(String key, String caption, VoidCallback? onTap) =>
    FilledButton(
      key: ValueKey(key), onPressed: onTap,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52),
          backgroundColor: LumoVisualTokens.cyan,
          foregroundColor: const Color(0xFF071F36)),
      child: Text(caption, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 17, fontWeight: FontWeight.w900)),
    );
  /// Playback controls use the existing session-bound narrator; no new
  /// audio service or profile data is created.
  Widget _narrationControls() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        key: const ValueKey('lab-voice-repeat'),
        onPressed: _safe ? () => unawaited(_narration.repeat()) : null,
        icon: const Icon(Icons.replay),
        label: const Text('Wiederholen'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: LumoVisualTokens.cyanBright,
        ),
      ),
      if (_narration.isActive)
        OutlinedButton.icon(
          key: const ValueKey('lab-voice-pause'),
          onPressed: _safe ? () => unawaited(_narration.pause()) : null,
          icon: const Icon(Icons.pause),
          label: const Text('Pause'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 52),
            foregroundColor: LumoVisualTokens.cyanBright,
          ),
        ),
    ],
  );

  Widget _content() {
    final p = _current;
    if (_phase == _Phase.reflection) {
      final record = _lease!.profile.journey.records[
          SkillRecord.makeId(widget.topic.subject, widget.topic.unit)];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Dein Verstehensmoment',
            style: TextStyle(color: LumoVisualTokens.white,
                fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Text(p.reflection, style: const TextStyle(
            color: LumoVisualTokens.white, fontSize: 18)),
        const SizedBox(height: 14),
        Text(record?.explanation ?? 'Wir lernen Schritt für Schritt.',
            style: const TextStyle(color: LumoVisualTokens.muted)),
        const SizedBox(height: 16),
        _button('lab-finish', 'Zurück zu den Lernwelten',
            () => Navigator.of(context).maybePop()),
      ]);
    }
    if (_phase == _Phase.example) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(p.prompt, style: const TextStyle(
            fontSize: 19, fontWeight: FontWeight.bold,
            color: LumoVisualTokens.white)),
        const SizedBox(height: 14),
        Text(p.workedExample, style: const TextStyle(fontSize: 17,
            height: 1.5, color: LumoVisualTokens.white)),
        const SizedBox(height: 12),
        _button('lab-speak', 'Beispiel vorlesen',
            () => unawaited(_read(p.workedExample))),
        const SizedBox(height: 12),
        _button('lab-next', 'Jetzt gemeinsam bauen', _next),
      ]);
    }
    if (_phase == _Phase.build) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(p.guidedPrompt, style: const TextStyle(fontSize: 19,
            fontWeight: FontWeight.w800, color: LumoVisualTokens.white)),
        const SizedBox(height: 12),
        KeyedSubtree(key: const ValueKey('lab-model'),
            child: _model(p, !_done && !_busy)),
        const SizedBox(height: 14),
        _button('lab-check-model', 'Mein Modell prüfen',
            _done || _busy ? null : () => unawaited(_checkModel())),
        if (_done) ...[
          const SizedBox(height: 12),
          _button('lab-next', 'Jetzt selbstständig antworten', _next),
        ],
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(p.prompt, style: const TextStyle(fontSize: 19,
          color: LumoVisualTokens.white, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (_hint >= 3) KeyedSubtree(
          key: const ValueKey('lab-model'),
          child: _model(p, !_done && !_busy)),
      TextField(
        key: const ValueKey('lab-answer'), controller: _answer,
        enabled: !_done && !_busy, maxLength: 80,
        autocorrect: false,
        style: const TextStyle(color: LumoVisualTokens.white, fontSize: 20),
        decoration: const InputDecoration(
          labelText: 'Deine Antwort',
          hintText: 'Hier schreiben',
          border: OutlineInputBorder(), filled: true),
      ),
      OutlinedButton.icon(
        key: const ValueKey('lab-help'),
        onPressed: _done ? null : _help,
        icon: const Icon(Icons.lightbulb_outline),
        label: Text('Tipp anzeigen ($_hint/5)'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: LumoVisualTokens.cyanBright),
      ),
      const SizedBox(height: 12),
      _button('lab-check-answer', 'Antwort prüfen',
          _done || _busy ? null : () => unawaited(_checkAnswer())),
      if (_done) ...[
        const SizedBox(height: 12),
        _button('lab-next',
            _phase == _Phase.recall ? 'Neue Aufgabe' : 'Mein Rückblick', _next),
      ],
    ]);
  }
  @override
  Widget build(BuildContext context) {
    const captions = ['Beispiel', 'Gemeinsam bauen', 'Freier Abruf',
      'Neue Aufgabe', 'Rückblick'];
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
          title: Text(widget.topic.title),
          backgroundColor: LumoVisualTokens.night,
          foregroundColor: LumoVisualTokens.white),
      body: SafeArea(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_safe
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Text(
                    'Kinderprofil wurde gewechselt oder die Lernwelt ist für eine spätere Klasse vorgesehen. Bitte kehre zurück.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: LumoVisualTokens.white, fontSize: 18))))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
                  children: [
                    Center(child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(
                            value: (_phase.index + 1) / 5,
                            minHeight: 7, color: LumoVisualTokens.cyan),
                          const SizedBox(height: 12),
                          Text(captions[_phase.index],
                              style: const TextStyle(
                                color: LumoVisualTokens.cyanBright,
                                fontSize: 17, fontWeight: FontWeight.w900)),
                          Row(children: [
                            LumoCharacter(
                              pose: LumoDesignFoxPose.bookWelcome,
                              size: 78, controller: _fox,
                              reduceMotion: _reduced),
                            const SizedBox(width: 8),
                            Expanded(child: Text(widget.topic.goal,
                                style: const TextStyle(
                                    color: LumoVisualTokens.white,
                                    fontSize: 15))),
                          ]),
                          const SizedBox(height: 12),
                          DecoratedBox(
                            key: ValueKey('lab-phase-' + _phase.name),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF153D64), Color(0xFF0B2341)]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF3A648A))),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _content()),
                          ),
                          if (widget.appState.state.settings.voiceEnabled &&
                              _narration.currentText != null) ...[
                            const SizedBox(height: 8),
                            _narrationControls(),
                          ],
                          if (_feedback.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Semantics(liveRegion: true,
                              child: Text(_feedback,
                                style: const TextStyle(fontSize: 16,
                                    color: LumoVisualTokens.white))),
                          ],
                          if (_progress.error != null) ...[
                            const SizedBox(height: 10),
                            Text(_progress.error!,
                                style: const TextStyle(color: Color(0xFFFFC17C))),
                            _button('lab-retry-save', 'Speichern wiederholen',
                                _progress.saving ? null : _progress.retry),
                          ],
                          if (_progress.saving || _busy)
                            const LinearProgressIndicator(),
                        ],
                      ),
                    )),
                  ],
                )),
    );
  }
  @override
  void dispose() {
    widget.appState.removeListener(_checkProfile);
    _progress.removeListener(_repaint);
    _narration.removeListener(_repaint);
    _progress.dispose();
    _narration.dispose();
    _fox.dispose();
    _answer.dispose();
    super.dispose();
  }
}
