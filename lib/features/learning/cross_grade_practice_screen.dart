import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/school_exercise_generator.dart';
import 'widgets/cross_grade_visual_scene.dart';
import '../../widgets/design/lumo_answer_crystal.dart';

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
  String? _firstWrongChoice;
  int _answered = 0;
  int _correct = 0;
  bool _progressLoaded = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      // Do not treat malformed history as a fresh profile. Keep both keys
      // untouched so the family can recover the existing local data.
      final answered = prefs.getInt('$_scope:answered') ?? 0;
      final correct = prefs.getInt('$_scope:correct') ?? 0;
      if (answered < 0 || correct < 0 || correct > answered) {
        throw const FormatException('Invalid existing practice counters');
      }
      if (!mounted) return;
      setState(() {
        _answered = answered;
        _correct = correct;
        _progressLoaded = true;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progressLoaded = false;
        _loadError =
            'Der gespeicherte Lernstand konnte nicht sicher geladen werden. '
            'Deine bisherigen Daten bleiben unverändert.';
      });
    }
  }

  Future<void> _answer(String choice) async {
    if (!_progressLoaded ||
        _loadError != null ||
        _selected != null ||
        _saving) {
      return;
    }
    if (choice == _firstWrongChoice) return;
    final correct = choice == _task.answer;
    // The first wrong attempt is unfinished: offer a hint, without writing
    // counters or disclosing the solution until the child tries again.
    if (!correct && _firstWrongChoice == null) {
      setState(() => _firstWrongChoice = choice);
      return;
    }
    setState(() {
      _selected = choice;
      _answered++;
      if (correct) _correct++;
      _saveError = null;
      _saving = true;
    });
    await _persistAcceptedAnswer();
  }

  /// Persist the already accepted answer. Retry calls this exact method
  /// without changing the counters, so an interrupted partial write cannot
  /// award a second attempt or alter the registered school profile.
  Future<void> _persistAcceptedAnswer() async {
    if (!mounted || !_progressLoaded || _selected == null) return;
    final answered = _answered;
    final correct = _correct;
    bool saved = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Short-circuit on a rejected write rather than silently declaring
      // success; retry overwrites only the same target values.
      final answeredSaved = await prefs.setInt('$_scope:answered', answered);
      if (answeredSaved) {
        saved = await prefs.setInt('$_scope:correct', correct);
      }
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveError = saved
          ? null
          : 'Speichern nicht möglich. Bitte erneut versuchen. '
              'Die Antwort bleibt erhalten.';
    });
  }

  Future<void> _retrySave() async {
    if (_saving ||
        _saveError == null ||
        _selected == null ||
        !_progressLoaded) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    await _persistAcceptedAnswer();
  }

  void _next() {
    if (!_progressLoaded ||
        _saving ||
        _saveError != null ||
        _selected == null) {
      return;
    }
    setState(() {
      _task = _factory.next(
        grade: widget.lessonGrade,
        subject: widget.subject,
        unit: widget.unit,
      );
      _selected = null;
      _firstWrongChoice = null;
    });
  }

  String get _secondChanceHint {
    switch (widget.subject) {
      case 'Mathematik':
        return 'Prüfe das Rechenzeichen und rechne in kleinen Schritten.';
      case 'Deutsch':
      case 'Rechtschreibung':
      case 'Lesen':
        return 'Lies die Aufgabe langsam und vergleiche die übrigen Antworten.';
      case 'Englisch':
        return 'Lies die Wörter einzeln und prüfe ihre Bedeutung.';
      default:
        return 'Schau auf die Frage und prüfe die übrigen Möglichkeiten.';
    }
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
                  if (_progressLoaded) ...[
                    const SizedBox(height: 10),
                    CrossGradeProgressRibbon(
                        answered: _answered, correct: _correct),
                  ],
                ],
              ),
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 12),
              Text(
                _loadError!,
                key: const ValueKey('cross-grade-load-error'),
                style: const TextStyle(
                    color: Color(0xFFFFD58D), fontWeight: FontWeight.w800),
              ),
            ] else if (!_progressLoaded) ...[
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Lernfortschritt wird geladen …',
                    key: ValueKey('cross-grade-loading'),
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
            const SizedBox(height: 22),
            CrossGradeGlassPanel(
                child: Text(
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
              if (widget.subject == 'Mathematik' && choices[i].length <= 14)
                SizedBox(
                  height: 110,
                  child: LumoAnswerCrystal(
                    buttonKey: ValueKey('cross-grade-choice-$i'),
                    label: choices[i],
                    fontSize: choices[i].length <= 5 ? 29 : 19,
                    state: selected != null && choices[i] == _task.answer
                        ? LumoCrystalState.correct
                        : choices[i] == _firstWrongChoice
                            ? LumoCrystalState.retry
                            : LumoCrystalState.neutral,
                    onPressed: _progressLoaded &&
                            _loadError == null &&
                            !_saving &&
                            selected == null &&
                            choices[i] != _firstWrongChoice
                        ? () => _answer(choices[i])
                        : null,
                  ),
                )
              else
                OutlinedButton(
                  key: ValueKey('cross-grade-choice-$i'),
                  onPressed: _progressLoaded &&
                          _loadError == null &&
                          !_saving &&
                          selected == null &&
                          choices[i] != _firstWrongChoice
                      ? () => _answer(choices[i])
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    alignment: Alignment.centerLeft,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    backgroundColor:
                        selected != null && choices[i] == _task.answer
                            ? const Color(0xFF185848)
                            : selected == choices[i] ||
                                    choices[i] == _firstWrongChoice
                                ? const Color(0xFF593643)
                                : const Color(0xFF123B65),
                    side: BorderSide(
                      color: selected != null && choices[i] == _task.answer
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
            if (selected != null || _firstWrongChoice != null) ...[
              const SizedBox(height: 12),
              Text(
                selected == null
                    ? _secondChanceHint
                    : selected == _task.answer
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
              if (selected != null)
                CrossGradeGlassPanel(
                    child: Text(
                  _task.explanation,
                  key: const ValueKey('cross-grade-explanation'),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, height: 1.4),
                )),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(_saveError!,
                    key: const ValueKey('cross-grade-save-error'),
                    style: const TextStyle(
                        color: Color(0xFFFFD58D), fontWeight: FontWeight.w800)),
                TextButton.icon(
                    key: const ValueKey('cross-grade-save-retry'),
                    onPressed: _saving ? null : _retrySave,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Erneut speichern')),
              ],
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Antwort wird gespeichert …',
                      key: ValueKey('cross-grade-saving'),
                      style: TextStyle(color: Colors.white70)),
                ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('cross-grade-next'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16B9D7),
                  foregroundColor: const Color(0xFF07223C),
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: _selected == null
                    ? null
                    : (!_saving && _saveError == null && _progressLoaded
                        ? _next
                        : null),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Nächste Aufgabe',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
