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
  late final Future<(List<Attempt>, LearningAnalysis)> _data = _load();

  Future<(List<Attempt>, LearningAnalysis)> _load() async {
    final attempts = await widget.appState.attemptLog.load(studentId: 'self');
    return (attempts, LearningAnalysis.analyze(attempts));
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
              child: FutureBuilder<(List<Attempt>, LearningAnalysis)>(
                future: _data,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: LumoVisualTokens.cyan));
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
