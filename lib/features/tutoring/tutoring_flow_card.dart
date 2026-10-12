import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_voice.dart';
import '../../core/school_exercise_generator.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../domain/tutoring/tutoring_session_planner.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';

typedef TutoringStart = void Function(String subject, String unit);

/// Klassenstufen-spezifischer Nachhilfe-Einstieg.
///
/// Das Kind waehlt zuerst ein Fach und danach genau das Thema, bei dem es
/// Hilfe braucht. Jeder Eintrag ist an den lokalen Aufgaben-Generator
/// gebunden; die Nachhilfe funktioniert daher ohne Chat und ohne Cloud-KI.
class TutoringFlowCard extends StatefulWidget {
  const TutoringFlowCard({
    super.key,
    required this.appState,
    required this.onStartTutoring,
  });

  final LumoAppState appState;
  final TutoringStart onStartTutoring;

  @override
  State<TutoringFlowCard> createState() => _TutoringFlowCardState();
}

class _TutoringFlowCardState extends State<TutoringFlowCard> {
  static const _subjects = <String>[
    'Mathematik',
    'Deutsch',
    'Lesen',
    'Schreiben',
    'Rechtschreibung',
    'Englisch',
    'Sachunterricht',
    'Logik',
  ];

  late String _selectedSubject;
  late String _selectedUnit;

  int get _grade => widget.appState.state.grade.clamp(1, 4).toInt();

  @override
  void initState() {
    super.initState();
    final requested = widget.appState.state.subject;
    _selectedSubject =
        _subjects.contains(requested) ? requested : 'Mathematik';
    _selectedUnit = _initialUnit(_selectedSubject);
  }

  @override
  void didUpdateWidget(covariant TutoringFlowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState.state.grade == widget.appState.state.grade) return;
    _selectedUnit = _initialUnit(_selectedSubject);
  }

  List<String> _unitsFor(String subject) => Curriculum.unitsForGrade(
        subject,
        _grade,
        currentGradeOnly: true,
      );

  String _initialUnit(String subject) {
    final units = _unitsFor(subject);
    if (units.isEmpty) return 'Alle';
    final weak = widget.appState.state.weakSkills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in weak) {
      if (units.contains(entry.key)) return entry.key;
    }
    return units.first;
  }

  void _chooseSubject(String subject) {
    if (_selectedSubject == subject) return;
    setState(() {
      _selectedSubject = subject;
      _selectedUnit = _initialUnit(subject);
    });
  }

  @override
  Widget build(BuildContext context) {
    final units = _unitsFor(_selectedSubject);
    final plan = _buildPlan();
    final focusLabels = plan.focusSkills.map(_labelForSkill).toSet().toList();

    return LumoGlassCard(
      padding: const EdgeInsets.all(18),
      borderColor: LumoVisualTokens.cyan.withOpacity(.58),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LumoFoxPose(
                pose: LumoDesignFoxPose.teacherStick,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lumo-Nachhilfe',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$_grade. Klasse · Wobei brauchst du Hilfe?',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LumoVisualTokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (focusLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Lumo empfiehlt: ${focusLabels.take(3).join(' · ')}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: LumoVisualTokens.gold,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            '1. Fach auswählen',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final subject in _subjects)
                ChoiceChip(
                  selected: subject == _selectedSubject,
                  onSelected: (_) => _chooseSubject(subject),
                  label: Text(_subjectLabel(subject)),
                  labelStyle: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: subject == _selectedSubject
                        ? LumoVisualTokens.night
                        : LumoVisualTokens.white,
                  ),
                  selectedColor: LumoVisualTokens.cyanBright,
                  backgroundColor: LumoVisualTokens.glassRow.withOpacity(.78),
                  side: BorderSide(
                    color: subject == _selectedSubject
                        ? LumoVisualTokens.cyanBright
                        : LumoVisualTokens.cyan.withOpacity(.35),
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '2. Thema auswählen',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white,
            ),
          ),
          const SizedBox(height: 8),
          if (units.isEmpty)
            const Text(
              'Für dieses Fach sind in dieser Klasse noch keine Aufgaben hinterlegt.',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.muted,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final unit in units)
                  ChoiceChip(
                    selected: unit == _selectedUnit,
                    onSelected: (_) => setState(() => _selectedUnit = unit),
                    label: Text(Curriculum.prettifyUnit(unit)),
                    labelStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: unit == _selectedUnit
                          ? LumoVisualTokens.night
                          : LumoVisualTokens.white,
                    ),
                    selectedColor: LumoVisualTokens.gold,
                    backgroundColor: LumoVisualTokens.navigation.withOpacity(.72),
                    side: BorderSide(
                      color: unit == _selectedUnit
                          ? LumoVisualTokens.gold
                          : LumoVisualTokens.cyan.withOpacity(.28),
                    ),
                    showCheckmark: false,
                  ),
              ],
            ),
          const SizedBox(height: 18),
          LumoGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: LumoVisualTokens.navigation,
            borderColor: LumoVisualTokens.cyan.withOpacity(.28),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_rounded,
                    color: LumoVisualTokens.gold, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lumo erklärt kurz · zeigt ein Beispiel · dann löst du echte Aufgaben mit Hilfestufen.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LumoVisualTokens.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: units.isEmpty
                  ? null
                  : () {
                      LumoVoice.instance.speak(
                        'Wir üben ${Curriculum.prettifyUnit(_selectedUnit)}. Ich helfe dir Schritt für Schritt.',
                      );
                      widget.onStartTutoring(
                        _selectedSubject,
                        _selectedUnit,
                      );
                    },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                units.isEmpty
                    ? 'Kein Thema verfügbar'
                    : '${Curriculum.prettifyUnit(_selectedUnit)} üben',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: LumoVisualTokens.cyan,
                foregroundColor: LumoVisualTokens.night,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subjectLabel(String subject) => switch (subject) {
        'Mathematik' => 'Mathe',
        'Sachunterricht' => 'Sachkunde',
        _ => subject,
      };

  TutoringSessionPlan _buildPlan() {
    final planner = const TutoringSessionPlanner();
    final skillStates = _deriveSkillStates();
    final st = widget.appState.state;
    final childId = 'local_${st.childName.toLowerCase()}_${st.grade}';
    return planner.plan(
      childId: childId,
      skillStates: skillStates,
    );
  }

  List<SkillState> _deriveSkillStates() {
    final st = widget.appState.state;
    final childId = 'local_${st.childName.toLowerCase()}_${st.grade}';
    final entries = st.weakSkills.entries.toList();
    if (entries.isEmpty) return const <SkillState>[];

    return <SkillState>[
      for (final entry in entries)
        SkillState(
          childId: childId,
          skillId: SkillId(_normalizeSkillId(entry.key)),
          masteryScore:
              (1.0 - (entry.value / 6).clamp(0.0, 1.0)).clamp(0.05, 0.6),
          repetitionNeed: (entry.value / 4).clamp(0.3, 1.0),
          attempts: entry.value * 2,
          wrong: entry.value,
          currentDifficulty: 1,
        ),
    ];
  }

  String _normalizeSkillId(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('plus')) return 'math.addition';
    if (lower.contains('minus')) return 'math.subtraction';
    if (lower.contains('mal') || lower.contains('einmaleins')) {
      return 'math.multiplication';
    }
    if (lower.contains('teil') || lower.contains('division')) {
      return 'math.division';
    }
    if (lower.contains('lesen')) return 'german.reading';
    if (lower.contains('rechtschreib')) return 'german.spelling';
    if (lower.contains('schreib')) return 'german.writing';
    if (lower.contains('silb')) return 'german.syllables';
    if (lower.contains('engli')) return 'english.basics';
    return 'math.addition';
  }

  String _labelForSkill(SkillId id) => switch (id.value) {
        'math.addition' => 'Plus rechnen',
        'math.subtraction' => 'Minus rechnen',
        'math.multiplication' => 'Malrechnen',
        'math.division' => 'Teilen',
        'german.reading' => 'Lesen',
        'german.writing' => 'Schreiben',
        'german.spelling' => 'Rechtschreibung',
        'german.syllables' => 'Silben',
        'english.basics' => 'Englisch',
        _ => id.value,
      };
}
