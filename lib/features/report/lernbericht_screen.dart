import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../domain/school/attempt.dart';
import '../../domain/school/learning_analysis.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import 'student_report_view.dart';

/// „Mein Lernbericht“: zeigt dem Kind (und den Eltern), was schon sicher
/// sitzt und was Lumo gemeinsam üben möchte. Alle Daten bleiben auf dem Gerät.
class LernberichtScreen extends StatefulWidget {
  const LernberichtScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LernberichtScreen> createState() => _LernberichtScreenState();
}

class _LernberichtScreenState extends State<LernberichtScreen> {
  late Future<(List<Attempt>, LearningAnalysis)?> _data;
  late int _generation;

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    _data = _load(widget.appState);
    widget.appState.addListener(_selectionChanged);
  }

  @override
  void didUpdateWidget(covariant LernberichtScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      oldWidget.appState.removeListener(_selectionChanged);
      widget.appState.addListener(_selectionChanged);
      _generation = widget.appState.profileGeneration;
      _data = _load(widget.appState);
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_selectionChanged);
    super.dispose();
  }

  void _selectionChanged() {
    if (_generation != widget.appState.profileGeneration) _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _generation = widget.appState.profileGeneration;
      _data = _load(widget.appState);
    });
  }

  Future<(List<Attempt>, LearningAnalysis)?> _load(LumoAppState app) async {
    try {
      final generation = app.profileGeneration;
      final owner = await app.captureLearningProfile();
      if (owner.generation != generation || !app.canUseLearningLease(owner)) {
        return null;
      }
      final attempts = await app.attemptLog.load(studentId: owner.logStudentId);
      if (!mounted || !identical(app, widget.appState) ||
          generation != app.profileGeneration || !app.canUseLearningLease(owner)) {
        return null;
      }
      return (attempts, LearningAnalysis.analyze(attempts));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.library,
        dimmed: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(children: [
                IconButton(
                  tooltip: 'Zurück',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Text('Mein Lernbericht',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ]),
            ),
            Expanded(
              child: FutureBuilder<(List<Attempt>, LearningAnalysis)?>(
                key: ValueKey(_generation),
                future: _data,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: LumoVisualTokens.cyan));
                  }
                  if (!snap.hasData) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Lernbericht konnte nicht sicher geladen werden.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white)),
                          TextButton(onPressed: _reload,
                              child: const Text('Erneut versuchen')),
                        ],
                      ),
                    );
                  }
                  final (attempts, analysis) = snap.data!;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: StudentReportView(
                          analysis: analysis, attempts: attempts),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
