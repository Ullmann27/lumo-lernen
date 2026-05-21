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
