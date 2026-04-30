import 'package:flutter/material.dart';
import '../../app/app_design.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_voice.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../domain/tutoring/tutoring_session_planner.dart';

/// Sichtbare Nachhilfe-Einheit fuer die App. Liest die Schwaechen aus
/// dem AppState (weakSkills-Map und learningSkills-Engine), uebergibt
/// sie an den TutoringSessionPlanner und visualisiert die fuenf
/// Nachhilfe-Schritte als kindgerechten Mini-Lernkurs.
///
/// Wird als Top-Block der Missionen-Seite eingebunden (siehe
/// section_content.dart -> _MissionsPage).
class TutoringFlowCard extends StatelessWidget {
  const TutoringFlowCard({
    super.key,
    required this.appState,
    required this.onStartTutoring,
  });

  final LumoAppState appState;

  /// Wird aufgerufen, wenn das Kind die Nachhilfe-Einheit startet.
  /// Der Empfaenger setzt sessionKind=tutoring und navigiert zu
  /// LumoSection.exercises.
  final VoidCallback onStartTutoring;

  @override
  Widget build(BuildContext context) {
    final plan = _buildPlan();
    final focusLabels = plan.focusSkills.map(_labelForSkill).toList();

    return LumoCard(
      accent: LumoColors.purple,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LumoGradients.comfort,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lumo-Nachhilfe',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lumo hat geschaut, wo du Hilfe brauchst.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              const LumoBadge(
                label: '8 Schritte',
                color: LumoColors.purple,
                icon: Icons.timeline_rounded,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Fokus-Bereiche
          if (focusLabels.isNotEmpty) ...[
            const Text(
              'Wir konzentrieren uns auf:',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: LumoColors.ink700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: focusLabels
                  .map((label) => LumoBadge(
                        label: label,
                        color: LumoColors.purple,
                        icon: Icons.star_rounded,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 18),
          ],
          // Schrittplan
          _StepRow(
            number: '1',
            icon: Icons.lightbulb_rounded,
            title: 'Lumo erklärt',
            subtitle: 'Eine kleine Mini-Erklärung in einfachen Worten.',
          ),
          _StepRow(
            number: '2',
            icon: Icons.visibility_rounded,
            title: 'Beispiel anschauen',
            subtitle: 'Ich zeige dir, wie es geht.',
          ),
          _StepRow(
            number: '3',
            icon: Icons.handshake_rounded,
            title: 'Gemeinsam lösen',
            subtitle: 'Wir machen eine Aufgabe zusammen.',
          ),
          _StepRow(
            number: '4',
            icon: Icons.videogame_asset_rounded,
            title: 'Lumo-Spiel',
            subtitle: 'Spielerisch festigen.',
          ),
          _StepRow(
            number: '5',
            icon: Icons.celebration_rounded,
            title: 'Geschafft',
            subtitle: 'Zusammenfassung und Belohnung.',
            isLast: true,
          ),
          const SizedBox(height: 18),
          Center(
            child: LumoPrimaryButton(
              label: 'Nachhilfe starten',
              icon: Icons.play_arrow_rounded,
              color: LumoColors.purple,
              onPressed: () {
                LumoVoice.instance.speak(
                  'Lass uns gemeinsam üben. Ich helfe dir Schritt für Schritt.',
                );
                onStartTutoring();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Baut einen Tutoring-Plan basierend auf den verfuegbaren Skill-Daten.
  /// Wenn keine echten Skills vorliegen, nutzt der Planner einen
  /// sinnvollen Fallback (math.addition).
  TutoringSessionPlan _buildPlan() {
    final planner = const TutoringSessionPlanner();
    final skillStates = _deriveSkillStates();
    final st = appState.state;
    final childId = 'local_${st.childName.toLowerCase()}_${st.grade}';
    return planner.plan(
      childId: childId,
      skillStates: skillStates,
    );
  }

  /// Leitet aus AppState.weakSkills (Map<String,int>) eine Liste von
  /// SkillStates ab. Hoeherer Wert = haeufiger falsch -> niedrigerer
  /// masteryScore und hoeherer repetitionNeed.
  List<SkillState> _deriveSkillStates() {
    final st = appState.state;
    final childId = 'local_${st.childName.toLowerCase()}_${st.grade}';
    final entries = st.weakSkills.entries.toList();
    if (entries.isEmpty) return const <SkillState>[];

    final result = <SkillState>[];
    for (final e in entries) {
      final mastery = (1.0 - (e.value / 6).clamp(0.0, 1.0)).clamp(0.05, 0.6);
      final repetition = (e.value / 4).clamp(0.3, 1.0);
      result.add(SkillState(
        childId: childId,
        skillId: SkillId(_normalizeSkillId(e.key)),
        masteryScore: mastery,
        repetitionNeed: repetition,
        attempts: e.value * 2,
        wrong: e.value,
        currentDifficulty: 1,
      ));
    }
    return result;
  }

  String _normalizeSkillId(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('plus')) return 'math.addition';
    if (lower.contains('minus')) return 'math.subtraction';
    if (lower.contains('mal')) return 'math.multiplication';
    if (lower.contains('teil')) return 'math.division';
    if (lower.contains('lesen')) return 'german.reading';
    if (lower.contains('schreib')) return 'german.writing';
    if (lower.contains('rechtschreib')) return 'german.spelling';
    if (lower.contains('silb')) return 'german.syllables';
    if (lower.contains('engli')) return 'english.basics';
    return 'math.addition';
  }

  String _labelForSkill(SkillId id) {
    switch (id.value) {
      case 'math.addition': return 'Plus rechnen';
      case 'math.subtraction': return 'Minus rechnen';
      case 'math.multiplication': return 'Malrechnen';
      case 'math.division': return 'Teilen';
      case 'german.reading': return 'Lesen';
      case 'german.writing': return 'Schreiben';
      case 'german.spelling': return 'Rechtschreibung';
      case 'german.syllables': return 'Silben';
      case 'english.basics': return 'Englisch';
      default: return id.value;
    }
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LumoColors.purple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: LumoColors.purple, size: 18),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: LumoColors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LumoColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
