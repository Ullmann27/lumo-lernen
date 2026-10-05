import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../domain/school/learning_analysis.dart';
import '../../theme/lumo_visual_tokens.dart';

/// Lumo spricht das Kind persönlich an: Hilfe bei einer Schwäche oder Lob für
/// etwas, das schon sicher sitzt. Ohne belastbare Daten bleibt das Feld leer.
class LumoCoachCard extends StatefulWidget {
  const LumoCoachCard({super.key, required this.appState, required this.onStart});
  final LumoAppState appState;
  final void Function(String subject, String unit) onStart;

  @override
  State<LumoCoachCard> createState() => _LumoCoachCardState();
}

class _LumoCoachCardState extends State<LumoCoachCard> {
  CoachMessage? _message;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final who = await widget.appState.school.activeStudentId() ?? 'self';
      final attempts = await widget.appState.attemptLog.load(studentId: who);
      final message = LearningAnalysis.analyze(attempts).coachMessage;
      if (!mounted) return;
      if (message?.text != _message?.text) setState(() => _message = message);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final m = _message;
    if (m == null) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('lumo-coach-card'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xD90B2A5C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: m.isHelp ? LumoVisualTokens.cyanBright : const Color(0xFF7BE08C),
            width: 1.6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(m.isHelp ? Icons.pets_rounded : Icons.verified_rounded,
              color: m.isHelp ? LumoVisualTokens.gold : const Color(0xFF7BE08C),
              size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(m.text,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ]),
        if (m.isHelp) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              key: const ValueKey('lumo-coach-start'),
              borderRadius: BorderRadius.circular(99),
              onTap: () => widget.onStart(m.subject, m.unit),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF63E4FF), Color(0xFF1E7FE0)]),
                  border: Border.all(color: const Color(0xFFBDF4FF), width: 1.6),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Ja, los geht’s!',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
