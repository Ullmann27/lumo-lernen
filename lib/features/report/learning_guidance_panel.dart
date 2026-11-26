import 'package:flutter/material.dart';

import '../../domain/school/adaptive_practice_plan.dart';
import '../../domain/school/learning_analysis.dart';
import '../../domain/school/learning_guidance.dart';
import '../../domain/tutoring/verstaendnis.dart';
import '../../widgets/design/lumo_subject_style.dart';
import '../teacher_demo/holo_widgets.dart';

/// „Auf einen Blick“ für Eltern und berechtigte Lehrkräfte: was das Kind gerade
/// übt, Stärken, Förderbedarf, Lernplan mit direktem Start ins passende
/// Lernmodul und Lernentwicklung. Zeigt nur die übergebene echte Auswertung
/// eines Kindes; bei wenigen Daten werden keine Aussagen getroffen.
class LearningGuidancePanel extends StatelessWidget {
  const LearningGuidancePanel({
    super.key,
    required this.guidance,
    this.onPractice,
    this.canPractice,
    this.onAssign,
  });

  final LearningGuidance guidance;

  /// Startet das Lernmodul der Empfehlung auf diesem Gerät (Elternbereich).
  final void Function(GuidanceRecommendation)? onPractice;

  /// Gibt es das Thema für die Schulstufe des Profils im Übungsbereich?
  final bool Function(GuidanceRecommendation)? canPractice;

  /// Weist das Thema als Aufgabe zu (Lehrkräftebereich).
  final void Function(GuidanceRecommendation)? onAssign;

  static const _body =
      TextStyle(color: HoloPalette.text, fontSize: 15, height: 1.35);
  static const _muted =
      TextStyle(color: HoloPalette.muted, fontSize: 13.5, height: 1.35);

  @override
  Widget build(BuildContext context) {
    final g = guidance;
    return HoloPanel(
      key: const ValueKey('learning-guidance'),
      shimmer: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HoloSectionTitle('Auf einen Blick',
              icon: Icons.visibility_rounded),
          if (g.total == 0)
            const Text(
              'Noch keine protokollierten Antworten. Sobald geübt wurde, steht '
              'hier, was gerade geübt wird und wobei Unterstützung hilft.',
              key: ValueKey('guidance-empty'),
              style: _body,
            )
          else ...[
            Text(
              'Grundlage: ${g.total} Antworten auf diesem Gerät, '
              'davon ${g.independentTotal} ohne Hilfe.',
              key: const ValueKey('guidance-basis'),
              style: _muted,
            ),
            const SizedBox(height: 14),
            _current(g),
            const SizedBox(height: 18),
            // Vergleichsaufgaben nach Hilfe sind eigene, einzeln belegte
            // Nachweise: Sie erscheinen ehrlich eingestuft auch bei wenigen
            // Antworten (eine einzelne nur als erstes Anzeichen).
            if (g.laterConfirmed.isNotEmpty) ...[
              _laterConfirmed(g),
              const SizedBox(height: 18),
            ],
            if (!g.hasReliableEvidence)
              _Hinweis(
                key: const ValueKey('guidance-few-data'),
                text: 'Noch zu wenige Antworten für Stärken, Förderbedarf und '
                    'Empfehlungen. Lumo urteilt erst ab fünf Antworten ohne '
                    'Hilfe zu einer Kompetenz (bisher ${g.independentTotal} '
                    'ohne Hilfe insgesamt).',
              )
            else ...[
              LayoutBuilder(builder: (context, constraints) {
                final staerken = _strengths(g);
                final bedarf = _needs(g);
                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [staerken, const SizedBox(height: 16), bedarf],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: staerken),
                    const SizedBox(width: 18),
                    Expanded(child: bedarf),
                  ],
                );
              }),
              const SizedBox(height: 18),
              _plan(context, g),
              const SizedBox(height: 18),
              _development(g),
            ],
          ],
          const SizedBox(height: 14),
          const Text(
            'Alle Werte stammen nur aus dem Aufgabenprotokoll dieses Geräts. '
            'Es gibt keine Synchronisierung zwischen Geräten. Vorschläge sind '
            'keine Noten und keine Diagnose.',
            key: ValueKey('guidance-local-note'),
            style: _muted,
          ),
        ],
      ),
    );
  }

  Widget _heading(String text, IconData icon, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ]),
      );

  Widget _current(LearningGuidance g) => Column(
        key: const ValueKey('guidance-current'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Gerade geübt · letzte 7 Tage', Icons.today_rounded,
              HoloPalette.cyan),
          if (g.current.isEmpty)
            const Text('In den letzten 7 Tagen wurde nichts geübt.',
                style: _body)
          else
            for (final t in g.current)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LumoSubjectBadge(subject: t.subject, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${t.subject} · ${t.unit}',
                              style: _body.copyWith(
                                  fontWeight: FontWeight.w800)),
                          Text(
                            '${t.answers} ${t.answers == 1 ? 'Antwort' : 'Antworten'} · '
                            '${t.independent == 0 ? 'keine ohne Hilfe' : '${t.independentCorrect} von ${t.independent} ohne Hilfe richtig'}'
                            '${t.assisted == 0 ? '' : ' · ${t.assisted} mit Hilfe'}',
                            style: _muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      );

  Widget _laterConfirmed(LearningGuidance g) => Column(
        key: const ValueKey('guidance-later-confirmed'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Später bestätigt · nach Hilfe allein gelöst',
              Icons.verified_rounded, HoloPalette.mint),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
                'Nach einer Hilfe bietet Lumo eine ähnliche Aufgabe an, die das '
                'Kind ganz allein löst. Erst mehrere solche Aufgaben zu '
                'verschiedenen Aufgaben gelten als bestätigt.',
                style: _muted),
          ),
          for (var i = 0; i < g.laterConfirmed.length; i++)
            _ConfirmationLine(
                key: ValueKey('guidance-confirmed-$i'),
                indiz: g.laterConfirmed[i]),
        ],
      );

  Widget _competencyLine(GuidanceCompetency c, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LumoSubjectBadge(subject: c.subject, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${c.subject} · ${c.competency}',
                      style: _body.copyWith(fontWeight: FontWeight.w800)),
                  Text(
                    '${c.independentCorrect} von ${c.independentAttempts} '
                    'ohne Hilfe richtig (${c.percent} %)'
                    '${c.level == MasteryLevel.developing ? ' · wird besser' : ''}',
                    style: _muted.copyWith(color: color),
                  ),
                  if (c.pattern != null)
                    Text('Häufiger Fehler: ${c.pattern}', style: _muted),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _strengths(LearningGuidance g) => Column(
        key: const ValueKey('guidance-strengths'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Stärken', Icons.star_rounded, HoloPalette.mint),
          if (g.strengths.isEmpty)
            const Text(
                'Noch keine Kompetenz mit mindestens 85 % ohne Hilfe '
                '(ab fünf Antworten).',
                style: _body)
          else
            for (final c in g.strengths) _competencyLine(c, HoloPalette.mint),
        ],
      );

  Widget _needs(LearningGuidance g) => Column(
        key: const ValueKey('guidance-needs'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Förderbedarf', Icons.flag_rounded, HoloPalette.amber),
          if (g.needs.isEmpty)
            const Text('Derzeit kein Förderbedarf erkennbar.', style: _body)
          else
            for (final c in g.needs) _competencyLine(c, HoloPalette.amber),
        ],
      );

  Widget _plan(BuildContext context, LearningGuidance g) => Column(
        key: const ValueKey('guidance-plan'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Lernplan · nächste Schritte', Icons.route_rounded,
              HoloPalette.cyan),
          if (g.recommendations.isEmpty)
            const Text(
                'Noch keine Empfehlung: dafür braucht ein Thema fünf Antworten '
                'ohne Hilfe.',
                style: _body)
          else ...[
            for (var i = 0; i < g.recommendations.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecommendationCard(
                  index: i,
                  recommendation: g.recommendations[i],
                  onPractice: onPractice,
                  canPractice: canPractice,
                  onAssign: onAssign,
                ),
              ),
            const Text(
              'Vorschlag: an verschiedenen Tagen je etwa 10 Minuten, '
              'oben beginnen.',
              style: _muted,
            ),
          ],
        ],
      );

  Widget _development(LearningGuidance g) => Column(
        key: const ValueKey('guidance-development'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Lernentwicklung · ohne Hilfe', Icons.trending_up_rounded,
              HoloPalette.violet),
          if (g.development.isEmpty)
            const Text(
                'Für einen Vorher-zuletzt-Vergleich braucht eine Kompetenz '
                'mindestens acht Antworten ohne Hilfe.',
                style: _body)
          else
            for (final d in g.development) _DevelopmentRow(development: d),
        ],
      );
}

class _ConfirmationLine extends StatelessWidget {
  const _ConfirmationLine({super.key, required this.indiz});
  final VerstaendnisIndiz indiz;

  @override
  Widget build(BuildContext context) {
    final i = indiz;
    final (label, color, icon) = switch (i.stufe) {
      VerstaendnisStufe.spaeterBestaetigt =>
        ('später bestätigt', HoloPalette.mint, Icons.verified_rounded),
      VerstaendnisStufe.erstesAnzeichen =>
        ('erstes Anzeichen', HoloPalette.cyan, Icons.trending_up_rounded),
      VerstaendnisStufe.nochUnsicher ||
      VerstaendnisStufe.keineDaten =>
        ('noch unsicher', HoloPalette.amber, Icons.replay_rounded),
    };
    final beispiel = i.bezuege.isEmpty ? null : i.bezuege.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: '${i.fach}, ${i.kompetenz}: $label. ${i.elternSatz}',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LumoSubjectBadge(subject: i.fach, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${i.fach} · ${i.kompetenz}',
                          style: LearningGuidancePanel._body
                              .copyWith(fontWeight: FontWeight.w800)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 4),
                          Text(label,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(i.elternSatz, style: LearningGuidancePanel._body),
                  if (beispiel != null && beispiel.$1.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                          'Zuletzt: Hilfe bei „${_kurz(beispiel.$1)}“, danach '
                          '„${_kurz(beispiel.$2)}“.',
                          style: LearningGuidancePanel._muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _kurz(String text) {
    final eine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return eine.length <= 60 ? eine : '${eine.substring(0, 57)}…';
  }
}

class _Hinweis extends StatelessWidget {
  const _Hinweis({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: HoloPalette.night.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HoloPalette.muted.withValues(alpha: .5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: HoloPalette.muted, size: 22),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(text, style: LearningGuidancePanel._body)),
            ],
          ),
        ),
      );
}

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({
    required this.index,
    required this.recommendation,
    this.onPractice,
    this.canPractice,
    this.onAssign,
  });

  final int index;
  final GuidanceRecommendation recommendation;
  final void Function(GuidanceRecommendation)? onPractice;
  final bool Function(GuidanceRecommendation)? canPractice;
  final void Function(GuidanceRecommendation)? onAssign;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _offen = false;

  Color get _farbe => switch (widget.recommendation.focus) {
        PracticeFocus.guidedPractice => HoloPalette.amber,
        PracticeFocus.consolidate => HoloPalette.cyan,
        PracticeFocus.review => HoloPalette.violet,
        PracticeFocus.extend => HoloPalette.mint,
      };

  @override
  Widget build(BuildContext context) {
    final r = widget.recommendation;
    final i = widget.index;
    final ruhig = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final startbar = widget.onPractice != null &&
        (widget.canPractice?.call(r) ?? true);
    final hilfe = !_offen
        ? const SizedBox(width: double.infinity)
        : Padding(
            key: ValueKey('guidance-help-$i'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${r.supportTip}\n${r.step.method}',
                style: LearningGuidancePanel._body),
          );
    return DecoratedBox(
      key: ValueKey('guidance-recommendation-$i'),
      decoration: BoxDecoration(
        color: HoloPalette.night.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _farbe.withValues(alpha: .6), width: 1.4),
        boxShadow: [
          BoxShadow(
              color: _farbe.withValues(alpha: .16),
              blurRadius: 16,
              spreadRadius: -4),
          const BoxShadow(
              color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LumoSubjectBadge(subject: r.subject, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ${r.step.title}',
                          style: TextStyle(
                              color: _farbe,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      Text('${r.subject} · ${r.unit}',
                          key: ValueKey('guidance-target-$i'),
                          style: LearningGuidancePanel._body.copyWith(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      if (r.competency != r.unit)
                        Text(r.competency, style: LearningGuidancePanel._muted),
                      const SizedBox(height: 4),
                      Text(
                        '${r.step.independentCorrect} von '
                        '${r.step.independentAttempts} zuletzt ohne Hilfe '
                        'richtig · ${r.step.guidedAttempts} mit Hilfe',
                        style: LearningGuidancePanel._muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Aufklappbare Hilfestellung für Erwachsene.
            Semantics(
              button: true,
              expanded: _offen,
              child: InkWell(
                key: ValueKey('guidance-help-toggle-$i'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _offen = !_offen),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(children: [
                    const Icon(Icons.support_agent_rounded,
                        color: HoloPalette.cyan, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('So können Sie unterstützen',
                          style: TextStyle(
                              color: HoloPalette.cyan,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                    AnimatedRotation(
                      turns: _offen ? .5 : 0,
                      duration: ruhig
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child: const Icon(Icons.expand_more_rounded,
                          color: HoloPalette.cyan),
                    ),
                  ]),
                ),
              ),
            ),
            // Reduzierte Bewegung: ohne Größenanimation (AnimatedSize mit
            // Dauer null verändert sich sonst während des eigenen Layouts).
            if (ruhig)
              hilfe
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: hilfe,
              ),
            if (widget.onPractice != null && !startbar)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                    'Dieses Thema gibt es für die Schulstufe des Profils '
                    'nicht im Übungsbereich.',
                    style: LearningGuidancePanel._muted),
              ),
            if (startbar || widget.onAssign != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (startbar)
                      LumoGoldButton(
                        key: ValueKey('guidance-practice-$i'),
                        label: r.guided ? 'Mit Lumo gemeinsam üben' : 'Jetzt üben',
                        onPressed: () => widget.onPractice!(r),
                      ),
                    if (widget.onAssign != null)
                      HoloButton(
                        key: ValueKey('guidance-assign-$i'),
                        label: 'Als Aufgabe zuweisen',
                        icon: Icons.assignment_rounded,
                        shimmer: false,
                        onPressed: () => widget.onAssign!(r),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentRow extends StatelessWidget {
  const _DevelopmentRow({required this.development});
  final GuidanceDevelopment development;

  @override
  Widget build(BuildContext context) {
    final d = development;
    final change = d.changePoints;
    final (text, color) = change >= 10
        ? ('+$change Prozentpunkte', HoloPalette.mint)
        : change <= -10
            ? ('−${-change} Prozentpunkte', HoloPalette.amber)
            : ('etwa gleich', HoloPalette.muted);
    Widget bar(String label, int correct, int total, Color c) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            SizedBox(
              width: 72,
              child: Text(label, style: LearningGuidancePanel._muted),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: correct / total,
                  minHeight: 10,
                  color: c,
                  backgroundColor: HoloPalette.deep,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$correct/$total', style: LearningGuidancePanel._body),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: '${d.subject}, ${d.competency}: vorher ${d.earlierCorrect} von '
            '${d.earlierTotal}, zuletzt ${d.recentCorrect} von ${d.recentTotal} '
            'ohne Hilfe richtig, $text',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              LumoSubjectBadge(subject: d.subject, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${d.subject} · ${d.competency}',
                    style: LearningGuidancePanel._body
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
            ]),
            bar('vorher', d.earlierCorrect, d.earlierTotal,
                HoloPalette.muted),
            bar('zuletzt', d.recentCorrect, d.recentTotal, HoloPalette.violet),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
