import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/cognitive_profile_generator.dart';
import '../../core/cognitive_profile_repository.dart';
import '../../core/cognitive_profile_scorer.dart';
import '../../domain/cognitive/cognitive_profile.dart';
import '../../domain/school/attempt.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';
import 'cognitive_profile_start_view.dart';
import 'cognitive_profile_visual_prompt.dart';
import 'iq/iq_widgets.dart';
import 'iq/iq_style.dart';

class CognitiveProfileScreen extends StatefulWidget {
  const CognitiveProfileScreen({
    super.key,
    required this.appState,
    this.repository = const CognitiveProfileRepository(),
  });

  final LumoAppState appState;
  final CognitiveProfileRepository repository;

  @override
  State<CognitiveProfileScreen> createState() => _CognitiveProfileScreenState();
}

class _CognitiveProfileScreenState extends State<CognitiveProfileScreen> {
  late final List<CognitiveQuestion> _questions;
  late DateTime _startedAt;
  final Map<String, String> _answers = <String, String>{};
  int _index = 0;
  bool _started = false;
  String? _selected;
  bool _stimulusVisible = false;
  Timer? _stimulusTimer;
  bool _saving = false;
  CognitiveProfileResult? _result;

  @override
  void initState() {
    super.initState();
    _questions =
        CognitiveProfileGenerator.forGrade(widget.appState.state.grade);
    // The stopwatch and memory stimulus begin only after the child taps Start.
  }

  @override
  void dispose() {
    _stimulusTimer?.cancel();
    super.dispose();
  }

  CognitiveQuestion get _question => _questions[_index];

  void _prepareQuestion() {
    _stimulusTimer?.cancel();
    final q = _questions[_index];
    _selected = _answers[q.id];
    _stimulusVisible = q.stimulus != null && q.stimulusVisibleMs > 0;
    if (_stimulusVisible) {
      _stimulusTimer = Timer(
        Duration(milliseconds: q.stimulusVisibleMs),
        () {
          if (mounted) setState(() => _stimulusVisible = false);
        },
      );
    }
  }

  Future<void> _next() async {
    final selected = _selected;
    if (selected == null || _stimulusVisible || _saving) return;
    _answers[_question.id] = selected;
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _prepareQuestion();
      });
      return;
    }
    await _finish();
  }

  String _fallbackStudentId() {
    final state = widget.appState.state;
    final safeName = state.childName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), '_');
    return 'local_${safeName.isEmpty ? 'kind' : safeName}_${state.grade}';
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final finishedAt = DateTime.now();
    final studentId =
        await widget.appState.school.activeStudentId() ?? _fallbackStudentId();
    final result = CognitiveProfileScorer.score(
      id: 'cog-${finishedAt.microsecondsSinceEpoch}',
      studentId: studentId,
      grade: widget.appState.state.grade,
      questions: _questions,
      answers: _answers,
      finishedAt: finishedAt,
      durationMs: finishedAt.difference(_startedAt).inMilliseconds,
    );
    await widget.repository.save(result);

    final attempts = <Attempt>[
      for (final q in _questions)
        Attempt(
          id: '${result.id}-${q.id}',
          studentId: studentId,
          subject: 'Denkprofil',
          unit: q.domain.label,
          competency: q.domain.label,
          correct: _answers[q.id] == q.correctAnswer,
          at: finishedAt,
          prompt: q.prompt,
          given: _answers[q.id] ?? '',
          expected: q.correctAnswer,
          score: _answers[q.id] == q.correctAnswer ? 1 : 0,
        ),
    ];
    await widget.appState.attemptLog.appendAll(attempts);

    if (!mounted) return;
    setState(() {
      _result = result;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.tests,
        dimmed: true,
        child: SafeArea(
          child: result == null
              ? (_started
                  ? _testBody()
                  : CognitiveProfileStartView(
                      questionCount: _questions.length,
                      onStart: () => setState(() {
                        _startedAt = DateTime.now();
                        _prepareQuestion();
                        _started = true;
                      }),
                      onBack: () => Navigator.of(context).maybePop(),
                    ))
              : _resultBody(result),
        ),
      ),
    );
  }

  Widget _testBody() {
    final q = _question;
    final progress = (_index + 1) / _questions.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 12, 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Zurück',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: LumoVisualTokens.white),
              ),
              const Expanded(
                child: Text(
                  'Lumo Denkprofil · 50',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_index + 1}/${_questions.length}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.cyanBright,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0x4437D2FD),
              color: LumoVisualTokens.cyanBright,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _DomainHeader(question: q),
              const SizedBox(height: 12),
              if (_stimulusVisible && q.stimulus != null)
                _MemoryStimulus(text: q.stimulus!)
              else ...[
                _QuestionCard(question: q),
                const SizedBox(height: 12),
                CognitiveProfileVisualPrompt(
                  key: const ValueKey('cognitive-puzzle-board'),
                  question: q,
                ),
                const SizedBox(height: 12),
                for (final choice in q.choices) ...[
                  _ChoiceTile(
                    label: choice,
                    selected: _selected == choice,
                    onTap: () => setState(() => _selected = choice),
                  ),
                  const SizedBox(height: 9),
                ],

              ],
            ],
          ),
        ),
        if (!_stimulusVisible)
          IqBottomBar(
            child: IqPrimaryButton(
              key: const ValueKey('cognitive-next'),
              onPressed: _selected == null || _saving ? null : _next,
              label: _index == _questions.length - 1
                  ? 'Denkprofil auswerten'
                  : 'Weiter',
              icon: _index == _questions.length - 1
                  ? Icons.flag_rounded
                  : Icons.arrow_forward_rounded,
            ),
          ),
      ],
    );
  }

  Widget _resultBody(CognitiveProfileResult result) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Zurück',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: LumoVisualTokens.white),
            ),
            const Expanded(
              child: Text(
                'Dein Denkprofil',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LumoGlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const LumoCharacter(
                pose: LumoDesignFoxPose.trophyWink,
                size: 112,
                intro: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.totalCorrect} von ${result.totalQuestions} gelöst',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Die fünf Bereiche werden getrennt ausgewertet. '
                      'So erkennt man Stärken und Bereiche, die noch Übung '
                      'brauchen.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.muted,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final score in result.domainScores) ...[
          _ScoreRow(score: score),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xD90A2B54),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: LumoVisualTokens.cyan.withOpacity(.30)),
          ),
          child: const Text(
            'Wichtig: Dieses Denkprofil ist ein schulstufenbezogener '
            'Lern- und Problemlösecheck. Es ist noch kein klinisch '
            'normierter Intelligenztest und erzeugt deshalb bewusst keine '
            'erfundene IQ-Zahl. Vergleiche sind nur innerhalb derselben '
            'Lumo-Testversion sinnvoll, bis echte Altersnormen validiert sind.',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: LumoVisualTokens.white,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Fertig'),
        ),
      ],
    );
  }
}

class _DomainHeader extends StatelessWidget {
  const _DomainHeader({required this.question});
  final CognitiveQuestion question;

  @override
  Widget build(BuildContext context) => IqPanel(
        radius: 18,
        accent: LumoVisualTokens.cyanBright,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.psychology_rounded,
                color: LumoVisualTokens.cyanBright),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question.domain.label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'Stufe ${question.difficulty}/5',
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _MemoryStimulus extends StatelessWidget {
  const _MemoryStimulus({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xF0164B78), Color(0xF0092953)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LumoVisualTokens.cyanBright, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x5537D2FD), blurRadius: 22),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Merke dir die Folge',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            FittedBox(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.cyanBright,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Die Folge verschwindet gleich. Danach kommt die Frage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final CognitiveQuestion question;

  @override
  Widget build(BuildContext context) => IqPanel(
        strong: true,
        accent: LumoVisualTokens.cyanBright,
        radius: 22,
        padding: const EdgeInsets.all(19),
        child: Text(
          question.prompt,
          style: iqText(20,
              weight: FontWeight.w900, height: 1.35, shadows: iqScrim),
        ),
      );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: IqTile(
              highlighted: selected,
              accent: LumoVisualTokens.cyanBright,
              radius: 20,
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 15),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 28),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? LumoVisualTokens.cyanBright
                          : LumoVisualTokens.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          style: iqText(16, weight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.score});
  final CognitiveDomainScore score;

  @override
  Widget build(BuildContext context) {
    final percent = (score.ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xD90B2A55),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  score.domain.label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${score.correct}/${score.total} · $percent%',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.cyanBright,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score.ratio,
              minHeight: 8,
              backgroundColor: const Color(0x4437D2FD),
              color: LumoVisualTokens.cyanBright,
            ),
          ),
        ],
      ),
    );
  }
}
