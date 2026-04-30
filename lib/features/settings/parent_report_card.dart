import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/reading_progress_repository.dart';
import '../../domain/analysis/daily_recommendation_engine.dart';
import '../../domain/analysis/lumo_analysis_domain.dart';

class ParentReportCard extends StatefulWidget {
  const ParentReportCard({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<ParentReportCard> createState() => _ParentReportCardState();
}

class _ParentReportCardState extends State<ParentReportCard> {
  final _readingRepo = ReadingProgressRepository();
  final _engine = const ParentReportEngine();
  late Future<ParentReportSummary> _future;

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
            Text('Nächste sinnvolle Schritte', style: LumoTextStyles.heading3),
            const SizedBox(height: 8),
            ...report.nextSteps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: LumoColors.orange)),
                    Expanded(child: Text(step, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700))),
                  ]),
                )),
          ]),
        );
      },
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
