// ════════════════════════════════════════════════════════════════════════
// LUMO INSIGHT DASHBOARD — Eltern-Dashboard mit visueller Kompetenz-Karte.
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-06-03: "echtes neues Level gegenueber LernMax". LernMax verkauft
// ihren Kimaro-AI fuer 95€/Jahr als Premium-Feature - reine Text-Reports.
// Lumo Insight gibt Eltern stattdessen eine SOFORT lesbare visuelle Karte:
//
//   - Hero-Stats (Heute geuebt, Streak, Sterne, Schwaechen-Zahl)
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
import '../../core/error_breakdown_repository.dart';
import '../../domain/learning/learning_dna.dart';
import '../../domain/learning/learning_dna_engine.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../widgets/premium/lumo_empty_error_state.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../learning/learning_dna_card.dart';
import 'widgets/lumo_insight_heatmap.dart';

class LumoInsightDashboard extends StatefulWidget {
  const LumoInsightDashboard({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<LumoInsightDashboard> createState() => _LumoInsightDashboardState();
}

class _LumoInsightDashboardState extends State<LumoInsightDashboard> {
  final _errorRepo = const ErrorBreakdownRepository();
  final _dnaEngine = const LearningDnaEngine();
  final _aiProxy = const LumoAiProxyClient();
  LearningDna? _dna;
  bool _loading = true;
  bool _showFullDna = false;

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
    _build();
  }

  Future<void> _build() async {
    final state = widget.appState.state;
    final childKey = (state.childName.isEmpty ? 'kind' : state.childName).toLowerCase();
    final errors = await _errorRepo.load(childKey);
    final dna = _dnaEngine.compute(
      state: state,
      errorBreakdown: errors,
      // recentCorrect / Incorrect kommen aus solved/practiceErrors:
      recentCorrect: state.solved.values.fold<int>(0, (a, b) => a + b),
      recentIncorrect: state.practiceErrors,
      recentHelpUsed: 0,
      totalSessions: 1,
    );
    if (!mounted) return;
    setState(() {
      _dna = dna;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF7C2D12)),
        title: const Text(
          '🦊 Lumo Insight',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C2D12),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LumoMagicBackground(
        intensity: 1.0,
        starCount: 22,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: LumoColors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _hero(),
                  const SizedBox(height: 16),
                  _statsRow(),
                  const SizedBox(height: 16),
                  _lumoSays(),
                  const SizedBox(height: 16),
                  if (_dna!.nextRecommendation != null) ...[
                    _nextRecCard(),
                    const SizedBox(height: 16),
                  ],
                  LumoInsightHeatmap(entries: _allEntries()),
                  const SizedBox(height: 16),
                  if (_dna!.errorBreakdown.isNotEmpty) ...[
                    _errorTop3(),
                    const SizedBox(height: 16),
                  ],
                  // 2026-06-04 KI-Wochenanalyse: ChatGPT-Berater fuer Eltern.
                  _aiAnalysisSection(),
                  const SizedBox(height: 16),
                  _toggleFullDna(),
                  if (_showFullDna) ...[
                    const SizedBox(height: 12),
                    LearningDnaParentCard(dna: _dna!),
                  ],
                ],
              ),
            ),
      ), // close LumoMagicBackground
    );
  }

  List<DnaSkillEntry> _allEntries() {
    return <DnaSkillEntry>[..._dna!.strengths, ..._dna!.weaknesses];
  }

  Widget _hero() {
    final name = widget.appState.state.childName;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🦊', style: TextStyle(fontSize: 44)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Hallo Eltern!' : 'Hallo, $name lernt fleissig!',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hier sehen Sie genau, wo Lumo helfen kann.',
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

  Widget _statsRow() {
    final state = widget.appState.state;
    final solved = state.solved.values.fold<int>(0, (a, b) => a + b);
    final streak = widget.appState.learningStreakDays();
    final strengths = _dna!.strengths.length;
    final weaknesses = _dna!.weaknesses.length;
    return Row(
      children: [
        Expanded(child: _statCard('Geuebt', '$solved', '📝', const Color(0xFF60A5FA))),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Streak', '$streak T.', '🔥', const Color(0xFFFF7A2F))),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Staerken', '$strengths', '💪', const Color(0xFF34D399))),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Übung', '$weaknesses', '🎯', const Color(0xFFF472B6))),
      ],
    );
  }

  Widget _statCard(String label, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.0,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.85),
          )),
        ],
      ),
    );
  }

  Widget _lumoSays() {
    final text = _dna!.recentProgress.trim().isEmpty
        ? 'Sobald euer Kind ein paar Aufgaben loest, fasse ich hier den Fortschritt zusammen.'
        : _dna!.recentProgress;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E5),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('💬', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C2D12),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextRecCard() {
    final rec = _dna!.nextRecommendation!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text('🎯', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lumo schlaegt vor: ${rec.title}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
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
                    color: Color(0xFF374151),
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

  Widget _errorTop3() {
    final entries = _dna!.errorBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🕵️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Wo Lumo aktuell oft helfen muss',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
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
                      color: Color(0xFFFEE2E2),
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
                        color: Color(0xFF7C2D12),
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
  Future<void> _requestAiAnalysis() async {
    if (_aiLoading) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    final state = widget.appState.state;
    final strengths = _dna!.strengths.take(3).map((e) => '${e.subject}/${e.skillLabel}').join(', ');
    final weaknesses = _dna!.weaknesses.take(3).map((e) => '${e.subject}/${e.skillLabel}').join(', ');
    final errors = _dna!.errorBreakdown.entries
        .take(3)
        .map((e) => '${e.key}(${e.value}x)')
        .join(', ');
    final payload = StringBuffer()
      ..writeln('Wochenanalyse fuer ${state.childName.isEmpty ? "das Kind" : state.childName} (Klasse ${state.grade}) bitte:')
      ..writeln('Staerken: ${strengths.isEmpty ? "noch wenig Daten" : strengths}')
      ..writeln('Foerderbedarf: ${weaknesses.isEmpty ? "noch wenig Daten" : weaknesses}')
      ..writeln('Haeufigste Fehlertypen: ${errors.isEmpty ? "keine" : errors}')
      ..writeln('Gib mir 3-5 Saetze als Elternteil: Was lief diese Woche gut, '
          'woran sollten wir zuhause arbeiten, ein konkreter Foerder-Tipp fuer '
          'die kommende Woche. Keine Floskeln, praktisch.');
    try {
      final response = await _aiProxy.ask(
        settings: state.settings,
        state: state,
        message: payload.toString(),
        context: LumoAiContext.parentAdvisor,
      );
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiError = 'KI-Berater gerade nicht erreichbar. Spaeter erneut.';
      });
    }
  }

  Widget _aiAnalysisSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
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
              const Text('🤖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lumo-KI Wochenanalyse',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5B21B6),
                  ),
                ),
              ),
              if (_aiLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF7C3AED)),
                )
              else
                FilledButton.icon(
                  onPressed: _requestAiAnalysis,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    _aiInsight == null && _aiError == null ? 'KI fragen' : 'Erneut',
                    style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                color: Color(0xFF1F2937),
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
              onAction: _requestAiAnalysis,
            )
          else
            const Text(
              'Drueck auf "KI fragen" - Lumo gibt euch eine kurze Foerder-Einschaetzung mit konkretem Wochen-Tipp.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B21A8),
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
          color: LumoColors.orange,
        ),
        label: Text(
          _showFullDna ? 'Detail-DNA ausblenden' : 'Vollstaendige DNA anzeigen',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: LumoColors.orange,
          ),
        ),
      ),
    );
  }
}
