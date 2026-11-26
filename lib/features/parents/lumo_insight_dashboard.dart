// ════════════════════════════════════════════════════════════════════════
// LUMO INSIGHT DASHBOARD — Eltern-Dashboard mit visueller Kompetenz-Karte.
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-06-03: "echtes neues Level gegenueber LernMax". LernMax verkauft
// ihren Kimaro-AI fuer 95€/Jahr als Premium-Feature - reine Text-Reports.
// Lumo Insight gibt Eltern stattdessen eine SOFORT lesbare visuelle Karte:
//
//   - Hero-Stats (gespeicherte Antworten, protokollierter Streak, Übungsgruppen)
//   - Lumo's Auswertung als kindgerechte 2-Saetze-Zusammenfassung
//   - Empfehlung der DnaEngine als grosse Action-Karte
//   - HEATMAP: pro Fach pro Kompetenz Farb-Cell (rot/gelb/gruen/grau)
//   - Top-3 Fehlertypen aus ErrorBreakdown
//   - Vollstaendige Text-DNA als ausklappbare Detail-Karte
//
// Aufgerufen aus parent_report_card.dart oder direkt aus Settings/Eltern-Bereich.

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../domain/learning/learning_dna.dart';
import '../../domain/learning/learning_dna_engine.dart';
import '../../domain/school/adaptive_practice_plan.dart';
import '../../domain/school/learning_analysis.dart';
import '../../domain/school/learning_chart_data.dart';
import '../../domain/school/learning_guidance.dart';
import '../../domain/school/parent_insight_metrics.dart';
import '../report/learning_analytics_panel.dart';
import '../report/adaptive_practice_plan_card.dart';
import '../report/learning_guidance_panel.dart';
import '../report/learning_route_launcher.dart';
import '../report/lernbericht_screen.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/premium/lumo_empty_error_state.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';
import '../learning/learning_dna_card.dart';
import 'widgets/lumo_insight_heatmap.dart';

class LumoInsightDashboard extends StatefulWidget {
  const LumoInsightDashboard({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<LumoInsightDashboard> createState() => _LumoInsightDashboardState();
}

/// Alles, was das Dashboard zeigt, aus genau einem Profil und einem Ladevorgang.
typedef _InsightData = ({
  AdaptivePracticePlan plan,
  LearningChartData chart,
  LearningGuidance guidance,
  ParentInsightMetrics metrics,
  LearningDna dna,
});

class _LumoInsightDashboardState extends State<LumoInsightDashboard> {
  final _dnaEngine = const LearningDnaEngine();
  final _aiProxy = const LumoAiProxyClient();
  bool _showFullDna = false;
  int _dataRevision = 0;
  Future<_InsightData?>? _data;

  // 2026-06-04: KI-Wochenanalyse direkt im Insight-Dashboard.
  // Bisher war diese Funktion nur in parent_report_card.dart versteckt.
  // Jetzt prominenter Button, gleiches Backend (LumoAiProxyClient mit
  // parentAdvisor-Kontext), aber sichtbar wo Eltern ohnehin schon
  // schauen.
  String? _aiInsight;
  String? _aiError;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_build);
    _build();
  }

  @override
  void didUpdateWidget(covariant LumoInsightDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      oldWidget.appState.removeListener(_build);
      widget.appState.addListener(_build);
      _build();
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_build);
    super.dispose();
  }

  void _build() {
    if (!mounted) return;
    setState(() {
      _dataRevision++;
      _data = _load(widget.appState);
      _aiInsight = null;
      _aiError = null;
      _aiLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: LumoVisualTokens.white),
        title: const Text(
          'Lumo Insight',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: LumoVisualTokens.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      // LUMO-Stil: dunkelblaue Bibliotheksszene wie Lernbericht und
      // Lehrkräftebereich statt des früheren Orange-Verlaufs.
      body: LumoSceneBackground(
        scene: LumoScene.library,
        dimmed: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(),
                const SizedBox(height: 16),
                // Neue Profilgeneration = neuer Zustand: nie Zahlen eines
                // anderen Kindes, auch nicht während des Ladens.
                FutureBuilder<_InsightData?>(
                  key: ValueKey(widget.appState.profileGeneration),
                  future: _data,
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    if (data == null) {
                      return _notLoaded(
                          loading: snapshot.connectionState !=
                              ConnectionState.done);
                    }
                    return _content(data);
                  },
                ),
              ],
            ),
          ),
        ),
      ), // close LumoSceneBackground
    );
  }

  Widget _notLoaded({required bool loading}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statsRow(null, loading: loading),
          const SizedBox(height: 16),
          if (loading)
            const Center(
                child: CircularProgressIndicator(color: LumoVisualTokens.gold))
          else
            Center(
              child: TextButton(
                key: const ValueKey('insight-retry'),
                style: TextButton.styleFrom(
                  foregroundColor: LumoVisualTokens.cyanBright,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: _build,
                child: const Text('Erneut versuchen'),
              ),
            ),
        ],
      );

  Widget _content(_InsightData data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statsRow(data.metrics),
          const SizedBox(height: 16),
          // Echte, profilgebundene Auswertung zuerst: was das
          // Kind gerade übt und welche Unterstützung hilft.
          _adaptivePlan(data),
          const SizedBox(height: 16),
          _lumoSays(data.metrics),
          const SizedBox(height: 16),
          // Der Lernplan oben ist die Empfehlung aus dem Protokoll. Die
          // ältere Themen-Empfehlung erscheint nur, wenn es dort noch keine
          // gibt – nie zwei widersprüchliche Vorschläge.
          if (data.guidance.recommendations.isEmpty &&
              data.dna.nextRecommendation != null) ...[
            _nextRecCard(data.dna),
            const SizedBox(height: 16),
          ],
          LumoInsightHeatmap(entries: data.dna.skillObservations),
          const SizedBox(height: 16),
          if (data.dna.errorBreakdown.isNotEmpty) ...[
            _errorTop3(data.dna),
            const SizedBox(height: 16),
          ],
          // 2026-06-04 KI-Wochenanalyse: ChatGPT-Berater fuer Eltern.
          _aiAnalysisSection(data.dna),
          const SizedBox(height: 16),
          _toggleFullDna(),
          if (_showFullDna) ...[
            const SizedBox(height: 12),
            LearningDnaParentCard(dna: data.dna),
          ],
        ],
      );

  /// Lädt Aufgabenprotokoll und Themenzähler desselben Profils. Solange das
  /// läuft, zeigt das Dashboard „wird geladen“ statt 0; ein Lesefehler wird
  /// als solcher gezeigt, nie als leeres oder fremdes Profil.
  Future<_InsightData?> _load(LumoAppState app) async {
    try {
      final generation = app.profileGeneration;
      final owner = await app.captureLearningProfile();
      if (owner.generation != generation || !app.canUseLearningLease(owner)) {
        return null;
      }
      // Nur lesen: Die Zähler dieses Profils, unabhängig davon, ob die App
      // sie für einen anderen Bildschirm schon geladen hat.
      await owner.profile.load();
      final attempts = await app.attemptLog.load(studentId: owner.logStudentId);
      if (!mounted || !identical(app, widget.appState) ||
          generation != app.profileGeneration || !app.canUseLearningLease(owner)) {
        return null;
      }
      final asOf = DateTime.now();
      final skills = owner.profile.skills;
      return (
        plan: AdaptivePracticePlan.fromAttempts(attempts,
            studentId: owner.logStudentId, now: asOf),
        chart: LearningChartData.fromAttempts(attempts,
            studentId: owner.logStudentId, now: asOf),
        guidance: LearningGuidance.fromAttempts(attempts,
            studentId: owner.logStudentId, now: asOf),
        metrics: ParentInsightMetrics.from(
            attempts: attempts,
            studentId: owner.logStudentId,
            now: asOf,
            skills: skills,
            daily: owner.profile.daily),
        dna: _dnaEngine.compute(state: app.state, skills: skills),
      );
    } catch (_) {
      // Do not show an empty or previous child's report on storage failure.
      return null;
    }
  }

  Widget _adaptivePlan(_InsightData data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LearningGuidancePanel(
            guidance: data.guidance,
            canPractice: (r) => LearningRouteLauncher.canStart(
                widget.appState, r.subject, r.unit),
            onPractice: (r) => LearningRouteLauncher.start(
                context, widget.appState,
                subject: r.subject, unit: r.unit, guided: r.guided),
          ),
          const SizedBox(height: 16),
          LearningAnalyticsPanel(data: data.chart),
          const SizedBox(height: 16),
          AdaptivePracticePlanCard(plan: data.plan),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: LumoVisualTokens.white,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => LernberichtScreen(appState: widget.appState))),
            icon: const Icon(Icons.insights_rounded),
            label: const Text('Echten Lernverlauf ansehen'),
          ),
        ],
      );

  Widget _hero() {
    final name = widget.appState.state.childName;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xF2123B6B), Color(0xF20B2A5C), Color(0xF2081F45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoVisualTokens.gold, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: LumoVisualTokens.gold.withValues(alpha: .25),
            blurRadius: 20,
            spreadRadius: -6,
          ),
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Der echte Lumo atmet, blinzelt und schaut; bei reduzierter
          // Bewegung steht er still.
          LumoCharacter(
            key: const ValueKey('insight-hero-lumo'),
            pose: LumoDesignFoxPose.armsOpen,
            size: 76,
            intro: false,
            idleHops: false,
            reduceMotion: widget.appState.state.settings.reduceAnimations ||
                MediaQuery.disableAnimationsOf(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty
                      ? 'Hallo Eltern!'
                      : 'Hallo, $name lernt fleißig!',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hier sehen Sie, was gerade geübt wird und wobei '
                  'Unterstützung hilft.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Die vier Kennzahlen. [metrics] ist `null`, solange die Daten laden
  /// ([loading]) oder nicht gelesen werden konnten: dann „…“ bzw. „–“, nie 0.
  Widget _statsRow(ParentInsightMetrics? metrics, {bool loading = false}) {
    final m = metrics;
    final missing = loading ? '…' : '–';
    final missingHint = loading ? 'wird geladen' : 'nicht geladen';
    final tiles = <Widget>[
      _statCard(
        key: 'answers',
        label: 'Antworten',
        value: m == null ? missing : '${m.answers}',
        hint: m == null
            ? missingHint
            : m.answers == 0
                ? 'noch keine'
                : m.olderAnswers > 0
                    ? 'inkl. ${m.olderAnswers} ältere'
                    : '${m.loggedIndependent} ohne Hilfe',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF60A5FA),
      ),
      _statCard(
        key: 'streak',
        label: 'Lerntage in Folge',
        value: m == null ? missing : '${m.streakDays}',
        hint: m == null ? missingHint : _lastPracticeHint(m.lastPracticeDay),
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF9F5A),
      ),
      _statCard(
        key: 'strengths',
        label: 'Stärken',
        value: m == null ? missing : m.strengths?.toString() ?? '–',
        hint: m == null
            ? missingHint
            : m.strengths == null
                ? 'noch offen'
                : 'ab 85 % ohne Hilfe',
        icon: Icons.star_rounded,
        color: const Color(0xFF34D399),
      ),
      _statCard(
        key: 'needs',
        label: 'Förderbedarf',
        value: m == null ? missing : m.needs?.toString() ?? '–',
        hint: m == null
            ? missingHint
            : m.needs == null
                ? 'noch offen'
                : 'unter 85 % ohne Hilfe',
        icon: Icons.flag_rounded,
        color: const Color(0xFFF472B6),
      ),
    ];

    // Two spacious tiles on phones, four on an unfolded display. Each row
    // keeps equal tile heights; short viewports scroll with the page.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final columns = constraints.maxWidth >= 640
                ? 4
                : constraints.maxWidth >= 260
                    ? 2
                    : 1;
            return Column(
              key: const ValueKey('insight-stats-grid'),
              children: [
                for (var start = 0; start < tiles.length; start += columns) ...[
                  if (start > 0) const SizedBox(height: gap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = start;
                            i < start + columns && i < tiles.length;
                            i++) ...[
                          if (i > start) const SizedBox(width: gap),
                          Expanded(child: tiles[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          _statsBasis(m, loading: loading),
          key: const ValueKey('insight-stats-basis'),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: LumoVisualTokens.muted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// Klar benannte Grundlage der Kennzahlen, damit sie zu „Auf einen Blick“
  /// passen und ältere Zähler nachvollziehbar bleiben.
  String _statsBasis(ParentInsightMetrics? m, {required bool loading}) {
    if (m == null) {
      return loading
          ? 'Kennzahlen werden geladen …'
          : 'Die Kennzahlen konnten nicht sicher geladen werden.';
    }
    if (m.isEmpty) return 'Noch keine Antworten in diesem Profil.';
    final out = StringBuffer(m.loggedAnswers == 0
        ? 'Noch keine Antworten im Aufgabenprotokoll dieses Profils.'
        : 'Grundlage wie „Auf einen Blick“: ${m.loggedAnswers} '
            '${m.loggedAnswers == 1 ? 'Antwort' : 'Antworten'} im '
            'Aufgabenprotokoll dieses Profils, davon ${m.loggedIndependent} '
            'ohne Hilfe.');
    if (m.olderAnswers > 0) {
      out.write(' Dazu ${m.olderAnswers} ältere '
          '${m.olderAnswers == 1 ? 'Antwort' : 'Antworten'} ohne Datum aus '
          'der Zeit vor dem Aufgabenprotokoll: zählen bei „Antworten“ mit, '
          'nicht bei Stärken und Förderbedarf.');
    }
    if (m.strengths == null) {
      out.write(' Stärken und Förderbedarf gibt es ab '
          '${LearningAnalysis.minReliable} Antworten ohne Hilfe zu einer '
          'Kompetenz.');
    }
    return out.toString();
  }

  static String _lastPracticeHint(DateTime? last) {
    if (last == null) return 'noch keine';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(last.year, last.month, last.day);
    if (day == today) return 'zuletzt heute';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'zuletzt gestern';
    }
    return 'zuletzt am ${day.day}.${day.month}.';
  }

  Widget _statCard({
    required String key,
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Semantics(
      key: ValueKey('insight-stat-$key'),
      container: true,
      label: '$label: $value, $hint',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          decoration: BoxDecoration(
            color: const Color(0xE60B2A55),
            borderRadius: BorderRadius.circular(LumoRadius.md),
            border: Border.all(color: color.withOpacity(0.40), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.16),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 2),
              Text(value,
                  key: ValueKey('insight-stat-$key-value'),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.85),
                  )),
              const SizedBox(height: 2),
              Text(hint,
                  key: ValueKey('insight-stat-$key-hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: LumoVisualTokens.muted,
                    height: 1.2,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// Lumos Kurzfassung aus denselben Zahlen wie die Kennzahlen oben.
  Widget _lumoSays(ParentInsightMetrics m) {
    final String text;
    if (m.isEmpty) {
      text = 'Sobald euer Kind ein paar Aufgaben löst, fasse ich hier den '
          'Fortschritt zusammen.';
    } else {
      final out = StringBuffer();
      if (m.loggedAnswers == 0) {
        out.write('Bisher nur ältere Antworten ohne Datum. Neue Antworten '
            'zeige ich oben unter „Auf einen Blick“.');
      } else if (m.loggedIndependent == 0) {
        out.write('${m.loggedAnswers} protokollierte '
            '${m.loggedAnswers == 1 ? 'Antwort' : 'Antworten'}, alle mit '
            'Hilfe – noch kein Nachweis ohne Hilfe.');
      } else {
        final percent =
            (m.loggedIndependentCorrect * 100 / m.loggedIndependent).round();
        out.write('Von ${m.loggedIndependent} '
            '${m.loggedIndependent == 1 ? 'Antwort' : 'Antworten'} ohne Hilfe '
            '${m.loggedIndependentCorrect == 1 ? 'war' : 'waren'} '
            '${m.loggedIndependentCorrect} richtig ($percent %).');
        if (m.loggedAssisted > 0) {
          out.write(' ${m.loggedAssisted} mit Hilfe zählen nicht als '
              'Nachweis.');
        }
        if (m.loggedIndependent < 10) out.write(' Kleine Stichprobe.');
      }
      if (m.olderAnswers > 0 && m.loggedAnswers > 0) {
        out.write(' Dazu ${m.olderAnswers} ältere '
            '${m.olderAnswers == 1 ? 'Antwort' : 'Antworten'} ohne Datum.');
      }
      out.write(' Übungsbeobachtungen, keine Kompetenzdiagnose.');
      text = out.toString();
    }
    return Container(
      key: const ValueKey('insight-lumo-says'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xE614355F),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.chat_bubble_rounded,
                color: Color(0xFFFCD34D), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: LumoVisualTokens.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextRecCard(LearningDna dna) {
    final rec = dna.nextRecommendation!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xE60B2A55),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0xFF60A5FA), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded,
              color: LumoVisualTokens.gold, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lumo schlägt vor: ${rec.title}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rec.subject}${rec.suggestedUnit == null ? "" : " - ${rec.suggestedUnit}"}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rec.reason,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LumoVisualTokens.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorTop3(LearningDna dna) {
    final entries = dna.errorBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xE60B2A55),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.manage_search_rounded,
                  color: Color(0xFFFCA5A5), size: 22),
              SizedBox(width: 8),
              Text(
                'Wo Lumo aktuell oft helfen muss',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: LumoVisualTokens.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in top)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0x664A2233),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LumoVisualTokens.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 2026-06-04 KI-Wochenanalyse: schickt strukturierte Eltern-Daten an den
  /// LumoAiProxyClient (parentAdvisor-Kontext) und zeigt 3-5 Saetze
  /// paedagogische Einschaetzung zurueck. Daten-sparsam: kein Background-
  /// Call, Eltern muessen aktiv tippen.
  Future<void> _requestAiAnalysis(LearningDna dna) async {
    if (_aiLoading) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    final revision = _dataRevision;
    final state = widget.appState.state.copyWith();
    final payload = dna.parentAnalysisPrompt(grade: state.grade);
    try {
      final response = await _aiProxy.ask(
        settings: state.settings,
        state: state,
        message: payload,
        context: LumoAiContext.parentAdvisor,
      );
      if (!mounted || revision != _dataRevision) return;
      setState(() {
        _aiLoading = false;
        if (response.source.startsWith('local_') || response.blocked) {
          _aiError = response.reply;
          _aiInsight = null;
        } else {
          _aiInsight = response.reply;
        }
      });
    } catch (_) {
      if (!mounted || revision != _dataRevision) return;
      setState(() {
        _aiLoading = false;
        _aiError = 'KI-Berater gerade nicht erreichbar. Spaeter erneut.';
      });
    }
  }

  Widget _aiAnalysisSection(LearningDna dna) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xE31D2F69), Color(0xE30C214A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFC4B5FD), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lumo-KI Lernanalyse',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                  ),
                ),
              ),
              if (_aiLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Color(0xFF7C3AED)),
                )
              else
                FilledButton.icon(
                  onPressed: () => _requestAiAnalysis(dna),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    _aiInsight == null && _aiError == null
                        ? 'KI fragen'
                        : 'Erneut',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_aiInsight != null)
            Text(
              _aiInsight!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LumoVisualTokens.white,
                height: 1.45,
              ),
            )
          else if (_aiError != null)
            // 2026-06-05 Iter 16/A3: Warmer Fehler-Zustand mit Lumo-Sad-Lottie
            // statt nackt-rotem Text. LumoEmptyErrorState.cloud zeigt Wolke +
            // Titel/Message + optionalen Retry-Button.
            LumoEmptyErrorState.cloud(
              title: 'Lumo-KI gerade nicht erreichbar',
              message: _aiError,
              actionLabel: 'Nochmal versuchen',
              onAction: () => _requestAiAnalysis(dna),
            )
          else
            const Text(
              'Die KI nutzt gespeicherte Gesamtwerte. Ohne Zeitdaten gibt es keine Aussage über diese Woche; kleine Stichproben bleiben vorsichtig eingeordnet.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LumoVisualTokens.muted,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _toggleFullDna() {
    return Center(
      child: TextButton.icon(
        onPressed: () => setState(() => _showFullDna = !_showFullDna),
        icon: Icon(
          _showFullDna ? Icons.expand_less : Icons.expand_more,
          color: LumoVisualTokens.cyanBright,
        ),
        label: Text(
          _showFullDna ? 'Detail-DNA ausblenden' : 'Vollständige DNA anzeigen',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: LumoVisualTokens.cyanBright,
          ),
        ),
      ),
    );
  }
}
