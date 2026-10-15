import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/school_exercise_generator.dart';
import 'widgets/cross_grade_visual_scene.dart';

/// Direct, offline, interactive lessons in a voluntarily selected school grade.
///
/// Deliberately independent of LumoAppState: choosing a different grade must
/// not silently change the enrolled profile or grant school-grade rewards.
/// Answers are stored in a separate, namespaced practice counter.
class CrossGradePracticeScreen extends StatefulWidget {
  const CrossGradePracticeScreen({
    super.key,
    required this.profileName,
    required this.enrolledGrade,
    required this.lessonGrade,
    required this.subject,
    required this.unit,
  });

  final String profileName;
  final int enrolledGrade;
  final int lessonGrade;
  final String subject;
  final String unit;

  @override
  State<CrossGradePracticeScreen> createState() =>
      _CrossGradePracticeScreenState();
}

class _CrossGradePracticeScreenState extends State<CrossGradePracticeScreen> {
  late final ExerciseFactory _factory;
  late LumoTask _task;
  String? _selected;
  int _answered = 0;
  int _correct = 0;

  String get _scope {
    // This lightweight local scope never changes the official profile grade.
    final safeName = widget.profileName.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9äöüß]+'),
          '_',
        );
    return 'cross_grade_practice_v1:${safeName.isEmpty ? 'kind' : safeName}:'
        '${widget.lessonGrade}:${widget.subject}:${widget.unit}';
  }

  @override
  void initState() {
    super.initState();
    _factory = ExerciseFactory();
    _task = _factory.next(
      grade: widget.lessonGrade,
      subject: widget.subject,
      unit: widget.unit,
    );
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _answered = prefs.getInt('$_scope:answered') ?? 0;
      _correct = prefs.getInt('$_scope:correct') ?? 0;
    });
  }

  Future<void> _answer(String choice) async {
    if (_selected != null) return;
    final correct = choice == _task.answer;
    setState(() {
      _selected = choice;
      _answered++;
      if (correct) _correct++;
    });
    // Only the independent cross-grade practice namespace is written;
    // no stars, XP, profile.grade, solved subjects or wallet are modified.
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('$_scope:answered', _answered),
      prefs.setInt('$_scope:correct', _correct),
    ]);
  }

  void _next() {
    setState(() {
      _task = _factory.next(
        grade: widget.lessonGrade,
        subject: widget.subject,
        unit: widget.unit,
      );
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF62E5F4);
    final choices = _task.choices;
    final selected = _selected;
    return CrossGradeVisualScene(
      title: '${widget.lessonGrade}. Klasse · ${widget.subject}',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            CrossGradeLumoHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.lessonGrade}. Klasse · ${widget.unit}',
                    key: const ValueKey('cross-grade-unit'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Frei üben · Dein Lernprofil bleibt in der '
                    '${widget.enrolledGrade}. Klasse.',
                    key: const ValueKey('cross-grade-profile-info'),
                    style: const TextStyle(color: Color(0xFFE2F1F8)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Extra-Übungen: $_answered · richtig: $_correct',
                    key: const ValueKey('cross-grade-counter'),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            CrossGradeGlassPanel(child: Text(
              _task.prompt,
              key: const ValueKey('cross-grade-question'),
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            )),
            const SizedBox(height: 16),
            for (var i = 0; i < choices.length; i++) ...[
              OutlinedButton(
                key: ValueKey('cross-grade-choice-$i'),
                onPressed: selected == null ? () => _answer(choices[i]) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  alignment: Alignment.centerLeft,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  backgroundColor: selected != null &&
                          choices[i] == _task.answer
                      ? const Color(0xFF185848)
                      : selected == choices[i]
                          ? const Color(0xFF593643)
                          : const Color(0xFF123B65),
                  side: BorderSide(
                    color: selected != null &&
                            choices[i] == _task.answer
                        ? const Color(0xFF72F0B0)
                        : accent.withOpacity(.75),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(choices[i],
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 9),
            ],
            if (selected != null) ...[
              const SizedBox(height: 12),
              Text(
                selected == _task.answer
                    ? 'Richtig! Gut gemacht!'
                    : 'Die richtige Antwort ist: ${_task.answer}',
                key: const ValueKey('cross-grade-feedback'),
                style: TextStyle(
                  color: selected == _task.answer
                      ? const Color(0xFF77F0B8)
                      : const Color(0xFFFFD58D),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              CrossGradeGlassPanel(child: Text(
                _task.explanation,
                key: const ValueKey('cross-grade-explanation'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.4),
              )),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('cross-grade-next'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16B9D7),
                  foregroundColor: const Color(0xFF07223C),
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Nächste Aufgabe',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
