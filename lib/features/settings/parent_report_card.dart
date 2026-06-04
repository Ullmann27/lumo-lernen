import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_ai_learning_access.dart';
import '../../core/lumo_ai_learning_policy_bridge.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/reading_progress_repository.dart';
import '../../core/settings_repository.dart';
import '../../domain/analysis/daily_recommendation_engine.dart';
import '../../domain/analysis/lumo_analysis_domain.dart';
import '../parents/lumo_insight_dashboard.dart';
import '../parents/widgets/lumo_ai_policy_selector.dart';

class ParentReportCard extends StatefulWidget {
  const ParentReportCard({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<ParentReportCard> createState() => _ParentReportCardState();
}

class _ParentReportCardState extends State<ParentReportCard> {
  final _readingRepo = ReadingProgressRepository();
  final _engine = const ParentReportEngine();
  final _aiProxy = const LumoAiProxyClient();
  late Future<ParentReportSummary> _future;

  // KI-Wochenreport - optional, ergaenzt den lokalen Bericht durch
  // eine paedagogische Analyse vom parentAdvisor-Kontext.
  String? _aiInsight;
  bool _aiLoading = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _future = _buildReport();
  }

  Future<ParentReportSummary> _buildReport() async {
    if (!widget.appState.learningProfileLoaded) {
      try {
        await widget.appState.loadLearningProfile();
      } catch (_) {}
    }
    final reading = await _readingRepo.loadReadingSummaries();
    return _engine.buildReport(
      childName: widget.appState.state.childName,
      skills: widget.appState.learningSkills(),
      readingSummaries: reading,
    );
  }

  Future<void> _saveAiMode(LumoAiLearningMode mode) async {
    final next = widget.appState.state.settings.copyWith(
      aiLearningMode: mode.toAppAiLearningMode(),
    );
    widget.appState.updateSettings(next);
    await SettingsRepository.save(next);
    if (mounted) setState(() {});
  }

  /// KI-Wochenanalyse: schickt strukturierte Daten an parentAdvisor
  /// und bekommt 3-5 Saetze paedagogische Einschaetzung zurueck.
  /// Nicht-Automatik - Eltern muessen aktiv anfordern (Daten-
  /// sparsam, kein Background-Call).
  Future<void> _requestAiAnalysis(ParentReportSummary report) async {
    if (_aiLoading) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    String fmtBlock(SubjectAnalysisBlock b) {
      final s = b.strengths.take(3).join(', ');
      final w = b.weaknesses.take(3).join(', ');
      return '${b.subject}: Staerken [${s.isEmpty ? "keine erkannt" : s}], '
          'Foerderbedarf [${w.isEmpty ? "keiner" : w}], '
          'naechster Schritt [${b.recommendedAction}]';
    }

    final payload = StringBuffer()
      ..writeln('Wochenanalyse fuer ${report.childName} bitte:')
      ..writeln(fmtBlock(report.reading))
      ..writeln(fmtBlock(report.math))
      ..writeln(fmtBlock(report.german))
      ..writeln('Gib mir 3-5 Saetze als Elternteil: Was lief gut diese '
          'Woche, woran sollten wir zuhause arbeiten, ein konkreter '
          'Foerder-Tipp fuer die kommende Woche. Keine Floskeln, '
          'praktisch.');

    try {
      final response = await _aiProxy.ask(
        settings: widget.appState.state.settings,
        state: widget.appState.state,
        message: payload.toString(),
        context: LumoAiContext.parentAdvisor,
      );
      if (!mounted) return;
      setState(() {
        _aiInsight = response.reply;
        _aiLoading = false;
        if (response.source.startsWith('proxy_') ||
            response.source == 'local_not_enabled') {
          _aiError = response.reply;
          _aiInsight = null;
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParentReportSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: lumoCard(),
            child: const Text('Elternbericht wird erstellt …', style: LumoTextStyles.heading3),
          );
        }
        final report = snapshot.data!;
        final settings = widget.appState.state.settings;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFF7ED)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 2026-06-03: prominenter CTA zum neuen Lumo-Insight-Dashboard
            // (visuelle Kompetenz-Heatmap, das echte Game-Changer-Feature
            // gegen LernMax). Steht ganz oben damit Eltern es sofort sehen.
            _LumoInsightCta(appState: widget.appState),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.lg)),
                child: const Center(child: Text('📄', style: TextStyle(fontSize: 30))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Elternbericht MVP', style: LumoTextStyles.heading2.copyWith(color: LumoColors.ink900)),
                const SizedBox(height: 4),
                Text('Lokal erzeugt · ${_date(report.generatedAt)}', style: LumoTextStyles.caption.copyWith(color: LumoColors.ink600)),
              ])),
            ]),
            const SizedBox(height: 12),
            Text(report.summary, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
            const SizedBox(height: 14),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _SubjectReportMini(block: report.reading, color: LumoColors.blue),
              _SubjectReportMini(block: report.math, color: LumoColors.math),
              _SubjectReportMini(block: report.german, color: LumoColors.german),
            ]),
            const SizedBox(height: 14),
            // 2026-06-03: Master-Toggle Lumo KI aktivieren/deaktivieren.
            // Bisher konnten Eltern nur den Modus waehlen, mussten
            // aiProxyEnabled aber nirgends explizit aktivieren - die KI
            // blieb deshalb komplett stumm und der Bottom-Nav 'Lumo KI'
            // hatte nur das lokale Brain. Jetzt 1-Tap Aktivierung.
            _LumoKiMasterToggle(
              enabled: settings.aiProxyEnabled,
              onToggle: (v) async {
                final next = settings.copyWith(aiProxyEnabled: v);
                widget.appState.updateSettings(next);
                await SettingsRepository.save(next);
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 12),
            LumoAiPolicySelector(
              currentMode: settings.lumoAiLearningMode,
              onModeChanged: _saveAiMode,
            ),
            const SizedBox(height: 14),
            Text('Nächste sinnvolle Schritte', style: LumoTextStyles.heading3),
            const SizedBox(height: 8),
            ...report.nextSteps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: LumoColors.orange)),
                    Expanded(child: Text(step, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700))),
                  ]),
                )),
            const SizedBox(height: 18),
            _buildAiInsightSection(report),
          ]),
        );
      },
    );
  }

  Widget _buildAiInsightSection(ParentReportSummary report) {
    final aiEnabled = widget.appState.state.settings.aiProxyEnabled;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('✨', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
              child: Text('KI-Wochenanalyse',
                  style: LumoTextStyles.heading3
                      .copyWith(color: const Color(0xFF4338CA)))),
        ]),
        const SizedBox(height: 6),
        Text(
          aiEnabled
              ? 'Lumo-Berater fasst Lernfortschritt + Foerder-Tipp in 3-5 Saetzen zusammen.'
              : 'Lumo-KI-Server im Elternbereich noch nicht aktiviert.',
          style: LumoTextStyles.caption.copyWith(color: LumoColors.ink600),
        ),
        const SizedBox(height: 10),
        if (_aiInsight != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(LumoRadius.md),
            ),
            child: Text(_aiInsight!,
                style: LumoTextStyles.body.copyWith(color: LumoColors.ink900)),
          ),
          const SizedBox(height: 8),
        ],
        if (_aiError != null) ...[
          Text(_aiError!,
              style:
                  LumoTextStyles.caption.copyWith(color: LumoColors.orange)),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: (!aiEnabled || _aiLoading)
                ? null
                : () => _requestAiAnalysis(report),
            icon: _aiLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(_aiInsight == null
                ? 'KI-Analyse anfordern'
                : 'Neu generieren'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LumoRadius.md)),
            ),
          ),
        ),
      ]),
    );
  }

  String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }
}

class _SubjectReportMini extends StatelessWidget {
  const _SubjectReportMini({required this.block, required this.color});

  final SubjectAnalysisBlock block;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.82),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(block.subject, style: LumoTextStyles.heading3.copyWith(color: color)),
        const SizedBox(height: 8),
        if (block.strengths.isNotEmpty) ...[
          Text('Stärken', style: LumoTextStyles.label.copyWith(color: LumoColors.teal)),
          const SizedBox(height: 3),
          ...block.strengths.take(3).map((item) => Text('✓ $item', style: LumoTextStyles.caption.copyWith(color: LumoColors.ink700))),
          const SizedBox(height: 8),
        ],
        if (block.weaknesses.isNotEmpty) ...[
          Text('Förderbedarf', style: LumoTextStyles.label.copyWith(color: LumoColors.orange)),
          const SizedBox(height: 3),
          ...block.weaknesses.take(3).map((item) => Text('• $item', style: LumoTextStyles.caption.copyWith(color: LumoColors.ink700))),
          const SizedBox(height: 8),
        ],
        Text(block.recommendedAction, style: LumoTextStyles.caption.copyWith(color: LumoColors.ink900, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

// CTA-Karte 2026-06-03: Prominenter Einstieg zum neuen Lumo-Insight-Dashboard.
// Visuelle Kompetenz-Heatmap als Unterscheidung gegenueber LernMax (textuelles
// Kimaro-AI-Report). Fix oben in der ParentReportCard.
class _LumoInsightCta extends StatelessWidget {
  const _LumoInsightCta({required this.appState});

  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LumoInsightDashboard(appState: appState),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            boxShadow: [
              BoxShadow(
                color: LumoColors.orange.withOpacity(0.36),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(LumoRadius.md),
                ),
                alignment: Alignment.center,
                child: const Text('🦊', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lumo Insight',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Visuelle Staerken-Karte + Lumo schlaegt nächste Übung vor',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// 2026-06-03: Master-Toggle Lumo KI aktivieren. Ohne diesen Schalter
// blieb die OpenAI-Anbindung default aus (aiProxyEnabled=false) und der
// neue Bottom-Nav-Eintrag 'Lumo KI' hatte nur lokales Fallback.
class _LumoKiMasterToggle extends StatelessWidget {
  const _LumoKiMasterToggle({required this.enabled, required this.onToggle});

  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xFFFFB96B), Color(0xFFFF7A2F)]
              : const [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: LumoColors.orange.withOpacity(0.36),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -3,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(LumoRadius.md),
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? 'Lumo KI ist AN' : 'Lumo KI aktivieren',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'Lumo antwortet mit ChatGPT - sicher, kindgerecht.'
                      : 'Schalte die KI an damit Lumo wirklich antworten kann.',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}
