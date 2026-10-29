import 'package:flutter/material.dart';

import '../../core/math/lumo_rechentricks.dart';
import '../../widgets/design/lumo_design_system.dart';

/// Die Rechentrick-Werkstatt: keine acht langen Schulbuch-Plakate.
/// Kinder wählen einen Freund und entdecken EINEN Schritt nach dem anderen.
/// Rechenalgorithmen und gespeicherte Lernfortschritte bleiben unberührt.
class LumoRechentricksPosterScreen extends StatefulWidget {
  const LumoRechentricksPosterScreen({super.key});

  @override
  State<LumoRechentricksPosterScreen> createState() =>
      _LumoRechentricksPosterScreenState();
}

class _LumoRechentricksPosterScreenState
    extends State<LumoRechentricksPosterScreen> {
  static const _night = Color(0xFF071C42);
  static const _cyan = Color(0xFF4DDCFC);
  static const _gold = Color(0xFFFFD061);

  late final List<_PosterEntry> _entries = _buildEntries();
  int _selected = 0;
  int _exampleIndex = 0;
  int _shownStep = 0;
  bool _showAnswer = false;
  bool _advanced = false;
  bool _showCredits = false;

  List<_PosterEntry> _buildEntries() {
    const tricks = LumoRechentricks();
    final result = <_PosterEntry>[];
    for (final mentor in kAllRechentricksMentors) {
      // Some sample prompts can be routed by the existing math engine
      // to another strategy. Only display the mentor's OWN examples.
      final examples = _examplesFor(mentor, tricks)
          .where((example) => example.mentor.kind == mentor.kind)
          .toList(growable: false);
      if (examples.isNotEmpty) {
        result.add(_PosterEntry(mentor: mentor, examples: examples));
      } else if (mentor.kind == RechentricksKind.decomposeBoth) {
        // The current core automatically prefers simplifying a near-ten
        // number. Keep its policy, but offer a correct, authored visual
        // demonstration of splitting both numbers on this reference page.
        result.add(_PosterEntry(mentor: mentor, examples: [
          RechentricksExplanation(
            mentor: mentor,
            taskText: '234 + 382 = ?',
            steps: const [
              '200 + 300 = 500',
              '34 + 82 = 116',
              '500 + 116 = 616',
            ],
            resultText: '616',
          ),
        ]));
      }
    }
    return result;
  }

  void _chooseMentor(int index) {
    setState(() {
      _selected = index;
      _exampleIndex = 0;
      _shownStep = 0;
      _showAnswer = false;
    });
  }

  void _nextStep(RechentricksExplanation exercise) {
    setState(() {
      if (_shownStep < exercise.steps.length - 1) {
        _shownStep++;
      } else {
        _showAnswer = true;
      }
    });
  }

  void _nextExample(_PosterEntry entry) {
    setState(() {
      _exampleIndex = (_exampleIndex + 1) % entry.examples.length;
      _shownStep = 0;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeEntries = _advanced
        ? _entries
        : _entries
            .where(
                (e) => e.mentor.kind.index <= RechentricksKind.bridgeTen.index)
            .toList(growable: false);
    if (activeEntries.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Hier entstehen bald neue Rechentricks.')),
      );
    }
    final selection = _selected.clamp(0, activeEntries.length - 1).toInt();
    final entry = activeEntries[selection];
    final exercise = entry.examples[_exampleIndex % entry.examples.length];
    final mentor = entry.mentor;
    final accent = Color(mentor.color);

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF071C42),
            border: Border(
              top: BorderSide(color: Color(0xFF2D85A8), width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: FilledButton.icon(
            key: const ValueKey('tricks-next'),
            onPressed: () =>
                _showAnswer ? _nextExample(entry) : _nextStep(exercise),
            icon: Icon(_showAnswer
                ? Icons.refresh_rounded
                : Icons.arrow_forward_rounded),
            label: Text(_showAnswer
                ? 'Noch ein Beispiel'
                : _shownStep == exercise.steps.length - 1
                    ? 'Lösung entdecken!'
                    : 'Nächster Schritt'),
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _night,
              minimumSize: const Size.fromHeight(58),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Lumos Trick-Werkstatt',
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
          child: LayoutBuilder(
            builder: (context, limits) => SingleChildScrollView(
              key: const ValueKey('tricks-scroll'),
              padding: EdgeInsets.fromLTRB(
                limits.maxWidth < 350 ? 12 : 20,
                12,
                limits.maxWidth < 350 ? 12 : 20,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 740),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _welcome(context),
                      const SizedBox(height: 18),
                      const Text(
                        'Wer hilft dir heute?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Tippe auf einen Freund!',
                        style: TextStyle(
                          color: Color(0xFFE0F2FF),
                          fontSize: 15,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _mentorChoices(activeEntries, selection),
                      const SizedBox(height: 16),
                      _lesson(context, entry, exercise, accent),
                      const SizedBox(height: 14),
                      if (!_advanced)
                        Center(
                          child: TextButton.icon(
                            key: const ValueKey('tricks-more-mentors'),
                            onPressed: () => setState(() => _advanced = true),
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Tricks für große Zahlen'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 52),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _advanced = false;
                              _selected = 0;
                              _exampleIndex = 0;
                              _shownStep = 0;
                              _showAnswer = false;
                            }),
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Leichte Tricks zeigen'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 52),
                            ),
                          ),
                        ),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _showCredits = !_showCredits),
                          child: const Text('Woher kommen die Ideen?',
                              style: TextStyle(color: Color(0xFFD8E8FA))),
                        ),
                      ),
                      if (_showCredits)
                        const Text(
                          'Die Rechenideen sind in Anlehnung an '
                          '„Meine Rechentricks“ aus dem Mildenberger-'
                          'Übungsheft Mathematik 1 + 3 entstanden.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Nunito',
                              fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF134F79), Color(0xFF0A2858), _night],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _cyan.withValues(alpha: .55), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: .17),
            blurRadius: 18,
            offset: const Offset(0, 5),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(17, 12, 10, 12),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rechnen kann zaubern!',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
                SizedBox(height: 4),
                Text('Wir probieren einen Trick nach dem anderen.',
                    style: TextStyle(
                        color: Color(0xFFDBF7FF),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const LumoFoxPose(
            pose: LumoDesignFoxPose.teacherStick,
            size: 78,
          ),
        ],
      ),
    );
  }

  Widget _mentorChoices(List<_PosterEntry> entries, int current) {
    return SizedBox(
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final mentor = entries[i].mentor;
          final active = i == current;
          final accent = Color(mentor.color);
          return Semantics(
            button: true,
            selected: active,
            label: 'Rechentrick von ${mentor.name}: ${mentor.catchphrase}',
            child: InkWell(
              key: ValueKey('tricks-mentor-$i'),
              onTap: () => _chooseMentor(i),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 108,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: active
                      ? accent.withValues(alpha: .25)
                      : const Color(0xE7092045),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? accent : _cyan.withValues(alpha: .35),
                    width: active ? 2.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _avatar(mentor, 53, accent),
                    const SizedBox(height: 6),
                    Text(mentor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 16,
                        )),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
      ),
    );
  }

  Widget _lesson(BuildContext context, _PosterEntry entry,
      RechentricksExplanation exercise, Color accent) {
    final mentor = entry.mentor;
    final steps = exercise.steps;
    final total = steps.length;
    final progress = (_shownStep + 1).clamp(1, total);
    return Container(
      width: double.infinity,
      key: const ValueKey('tricks-lesson'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xF514396A), Color(0xF509224A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: .78), width: 1.6),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .18), blurRadius: 22),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _avatar(mentor, 57, accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${mentor.name} zeigt dir:',
                      style: TextStyle(
                          color: accent,
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900)),
                  Text(mentor.catchphrase,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D456C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cyan.withValues(alpha: .65)),
            ),
            child: Column(children: [
              const Text('Unsere Aufgabe',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Color(0xFFC6EFFF),
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  exercise.taskText,
                  key: const ValueKey('tricks-task'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 36),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          _countingDots(exercise.taskText, accent),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: _gold, size: 23),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _showAnswer
                    ? 'Super, geschafft!'
                    : 'Schritt ${progress} von $total',
                key: const ValueKey('tricks-progress'),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _showAnswer ? 1 : progress / (total + 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            color: _gold,
            backgroundColor: Colors.white.withValues(alpha: .13),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey('step-$_shownStep'),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 90),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: .54)),
              ),
              child: Text(
                steps[_shownStep],
                key: const ValueKey('tricks-step-text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    height: 1.3),
              ),
            ),
          ),
          if (_showAnswer) ...[
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('tricks-result'),
              alignment: Alignment.center,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF217A4B), Color(0xFF114B46)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF72F0A4), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFFB5FFD4)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(exercise.resultText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (entry.examples.length > 1 && !_showAnswer)
            Center(
              child: TextButton(
                key: const ValueKey('tricks-change-example'),
                onPressed: () => _nextExample(entry),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 50),
                ),
                child: const Text('Anderes Beispiel'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _countingDots(String task, Color accent) {
    final parsed = RegExp(r'^(\d+)\s*\+\s*(\d+)').firstMatch(task);
    if (parsed == null) return const SizedBox.shrink();
    final a = int.tryParse(parsed.group(1)!);
    final b = int.tryParse(parsed.group(2)!);
    if (a == null || b == null || a > 10 || b > 10) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: '$a blaue und $b goldene Zählpunkte',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xD40B294D),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          runSpacing: 7,
          children: [
            for (var i = 0; i < a; i++) _dot(_cyan),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 23),
            ),
            for (var i = 0; i < b; i++) _dot(_gold),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .5), blurRadius: 7)
          ],
        ),
      );

  Widget _avatar(RechentricksMentor m, double size, Color accent) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF163454),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 10),
        ],
      ),
      child: ClipOval(
        child: m.avatarAsset == null
            ? Center(
                child: Text(m.emoji, style: TextStyle(fontSize: size * .55)))
            : Image.asset(m.avatarAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                      child:
                          Text(m.emoji, style: TextStyle(fontSize: size * .55)),
                    )),
      ),
    );
  }

  List<RechentricksExplanation> _examplesFor(
      RechentricksMentor m, LumoRechentricks tricks) {
    // Pro Strategie hartcodiert 2 Beispielaufgaben damit die Erklaerungen
    // pedagogisch eindeutig sind.
    switch (m.kind) {
      case RechentricksKind.swapNumbers:
        return [
          tricks.explain(prompt: '2 + 7 = ?', correctAnswer: '9', grade: 1),
          tricks.explain(prompt: '3 + 8 = ?', correctAnswer: '11', grade: 1),
          // 2026-06-05 Iter 24: Mal-Tauschtrick
          tricks.explain(prompt: '7 × 3 = ?', correctAnswer: '21', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.neighborTask:
        return [
          tricks.explain(prompt: '5 + 4 = ?', correctAnswer: '9', grade: 1),
          tricks.explain(prompt: '6 + 7 = ?', correctAnswer: '13', grade: 1),
          // 2026-06-05 Iter 24: Verdoppeln-Trick (Mal-Aufgabe)
          tricks.explain(prompt: '4 × 8 = ?', correctAnswer: '32', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.inverseCheck:
        return [
          tricks.explain(prompt: '9 - 4 = ?', correctAnswer: '5', grade: 1),
          tricks.explain(prompt: '15 - 7 = ?', correctAnswer: '8', grade: 1),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.smallFirst:
        return [
          tricks.explain(prompt: '12 + 4 = ?', correctAnswer: '16', grade: 1),
          tricks.explain(prompt: '15 + 3 = ?', correctAnswer: '18', grade: 1),
          // 2026-06-05 Iter 24: 5er-Trick fuer Einmaleins
          tricks.explain(prompt: '7 × 8 = ?', correctAnswer: '56', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.bridgeTen:
        return [
          tricks.explain(prompt: '8 + 6 = ?', correctAnswer: '14', grade: 1),
          tricks.explain(prompt: '7 + 5 = ?', correctAnswer: '12', grade: 1),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.stepByStep:
        return [
          tricks.explain(
              prompt: '467 + 258 = ?', correctAnswer: '725', grade: 3),
          tricks.explain(
              prompt: '725 - 258 = ?', correctAnswer: '467', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.decomposeBoth:
        return [
          tricks.explain(
              prompt: '234 + 382 = ?', correctAnswer: '616', grade: 3),
          tricks.explain(
              prompt: '156 + 273 = ?', correctAnswer: '429', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.simplify:
        return [
          tricks.explain(
              prompt: '325 + 197 = ?', correctAnswer: '522', grade: 3),
          tricks.explain(
              prompt: '504 - 199 = ?', correctAnswer: '305', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
    }
  }
}

class _PosterEntry {
  const _PosterEntry({required this.mentor, required this.examples});
  final RechentricksMentor mentor;
  final List<RechentricksExplanation> examples;
}
