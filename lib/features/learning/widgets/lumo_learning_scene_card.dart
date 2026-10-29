import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/app_state.dart';
import '../../../core/learning_attempt_id.dart';
import '../../../core/tutor_coordination_engine.dart';
import '../../../domain/learning_intelligence/learning_scene_contract.dart';
import '../../../domain/learning_intelligence/lesson_scene_engine.dart';
import '../../../domain/learning_intelligence/lumo_intelligence_engine.dart';
import '../../../domain/learning_intelligence/scene_memory.dart';
import 'lumo_place_value_blocks.dart';

/// Productive renderer of the versioned contract. Decisions and storage stay
/// in Sol's domain services. No microphone, provider or rewards are involved.
class LumoLearningSceneCard extends StatefulWidget {
  const LumoLearningSceneCard(
      {super.key,
      required this.appState,
      required this.scope,
      required this.number,
      required this.requestedHelpLevel,
      required this.onMethodChosen,
      required this.onDifferentTask,
      this.reduceMotion = false,
      this.requestSerial = 0});
  final LumoAppState appState;
  final TutorTaskScope scope;
  final int number, requestedHelpLevel;
  final int requestSerial;
  final bool reduceMotion;
  final ValueChanged<ExplanationMethod> onMethodChosen;
  final VoidCallback onDifferentTask;
  @override
  State<LumoLearningSceneCard> createState() => _LumoLearningSceneCardState();
}

class _LumoLearningSceneCardState extends State<LumoLearningSceneCard> {
  static const _intelligence = LumoIntelligenceEngine();
  late final Future<LearningProfileLease> _owner =
      widget.appState.captureLearningProfile();
  SceneMemory _memory = SceneMemory();
  ExplanationMethod _method = ExplanationMethod.verbal;
  final List<SceneObservation> _pending = [];
  bool _ready = false, _quiet = false, _saving = false, _allTried = false;
  String? _error;
  String _reason =
      'Du hast um Hilfe gebeten. Wir machen einen Lernschritt sichtbar.';
  bool get _current =>
      widget.scope.generation == widget.appState.profileGeneration;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final owner = await _owner;
      await widget.appState.prepareLearningLease(owner);
      await owner.profile.loadSceneMemory();
      if (!mounted ||
          !_current ||
          !widget.appState.isCurrentLearningLease(owner)) return;
      _memory = owner.profile.sceneMemory;
      final decision = _intelligence.decide(
          conceptId: 'math.tens_ones',
          problemId: widget.scope.problemId,
          memory: _memory,
          explicitRequest: true,
          isExam: widget.scope.isExam,
          preferredMethod: widget.requestedHelpLevel >= 3
              ? ExplanationMethod.interactive
              : null);
      _ready = true;
      _choose(decision.method, decision.reason);
    } catch (_) {
      if (mounted && _current)
        setState(() => _error =
            'Dein Erklärweg wartet noch aufs Laden. Bitte versuche es erneut.');
    }
  }

  @override
  void didUpdateWidget(covariant LumoLearningSceneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestSerial != oldWidget.requestSerial) {
      _quiet = false;
      if (_ready) {
        _alternative(markFailure: false);
      } else if (_error != null) {
        unawaited(_load());
      }
    }
  }

  void _choose(ExplanationMethod? method, String reason) {
    if (!mounted || !_current || widget.scope.isExam) return;
    setState(() {
      _reason = reason;
      _allTried = method == null;
      if (method != null) _method = method;
    });
    if (method == null) return;
    _queue(understood: true);
    final selected = _method;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _current && selected == _method)
        widget.onMethodChosen(selected);
    });
  }

  void _alternative({bool markFailure = true}) {
    if (!_ready || !_current) return;
    if (markFailure) _queue(understood: false);
    final d = _intelligence.decide(
        conceptId: 'math.tens_ones',
        problemId: widget.scope.problemId,
        memory: _memory,
        explicitRequest: true,
        isExam: widget.scope.isExam);
    _choose(d.method, d.reason);
  }

  void _queue({required bool understood}) {
    final observation = SceneObservation.methodFeedback(
        id: newLearningAttemptId(),
        conceptId: 'math.tens_ones',
        problemId: widget.scope.problemId,
        method: _method,
        understood: understood,
        at: DateTime.now());
    _memory = _memory.record(observation);
    _pending.add(observation);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_saving) return;
    _saving = true;
    try {
      final owner = await _owner;
      while (
          _pending.isNotEmpty && widget.appState.canUseLearningLease(owner)) {
        final saved = await widget.appState
            .saveLearningScene(observation: _pending.first, lease: owner);
        if (!saved) break;
        _pending.removeAt(0);
      }
      if (mounted && _current) setState(() => _error = null);
    } catch (_) {
      if (mounted && _current)
        setState(() => _error = 'Dein Erklärweg wartet noch aufs Speichern.');
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quiet || !_current || widget.scope.isExam)
      return const SizedBox.shrink();
    final scene = const LessonSceneEngine().placeValue(
        number: widget.number,
        method: _method,
        reduceMotion:
            widget.reduceMotion || MediaQuery.disableAnimationsOf(context));
    return Semantics(
        label: scene.accessibilityLabel,
        child: Container(
            key: ValueKey('lumo-scene-${_method.name}'),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xEF082849),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xA065DEFF))),
            child: DefaultTextStyle(
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    height: 1.4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          switch (_method) {
                            ExplanationMethod.verbal => 'In Worten verstehen',
                            ExplanationMethod.pictorial => 'Als Bild entdecken',
                            ExplanationMethod.interactive =>
                              'Mit Würfeln begreifen',
                            ExplanationMethod.guided => 'Schritt für Schritt'
                          },
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Wir betrachten die Zahl ${widget.number}.',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(_reason,
                          style: const TextStyle(color: Color(0xFF9EEAFF))),
                      if (!_allTried) ...[
                        for (final step in scene.steps)
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(step.instruction)),
                        if (_method == ExplanationMethod.pictorial) ...[
                          const SizedBox(height: 12),
                          LumoPlaceValueBlocks(
                              tens: widget.number ~/ 10,
                              ones: widget.number % 10,
                              reduceMotion: scene.reduceMotion),
                        ],
                        if (_ready)
                          _button(
                              'lumo-scene-not-understood',
                              'Noch nicht verstanden – anderer Weg',
                              () => _alternative()),
                      ] else
                        _button(
                            'lumo-scene-other-task',
                            'Eine andere Aufgabe wählen',
                            widget.onDifferentTask),
                      _button('lumo-scene-think', 'Ich probiere jetzt allein',
                          () => setState(() => _quiet = true)),
                      if (_error != null) ...[
                        Text(_error!),
                        _button(
                            'lumo-scene-retry',
                            'Erklärweg erneut speichern',
                            () => unawaited(_ready ? _drain() : _load()))
                      ],
                    ]))));
  }

  Widget _button(String key, String label, VoidCallback callback) => TextButton(
      key: ValueKey(key),
      onPressed: callback,
      style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: const Color(0xFFBCEFFF),
          textStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800)),
      child: Text(label));
}
