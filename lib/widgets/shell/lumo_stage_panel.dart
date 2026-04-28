import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';
import '../cards/goal_card.dart';

class LumoStagePanel extends StatelessWidget {
  const LumoStagePanel({
    super.key,
    required this.lumo,
    required this.subtitle,
  });

  final Widget lumo;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(0, 16, 22, 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LumoGradients.lumoStage,
          borderRadius: BorderRadius.circular(LumoRadius.stage),
          border: Border.all(color: Colors.white.withOpacity(.72), width: 2),
          boxShadow: LumoShadows.stage,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: LumoSurfaces.softCard(
                  color: Colors.white.withOpacity(.88),
                  radius: LumoRadius.bubble,
                  shadowColor: LumoColors.apricot,
                ),
                child: Text(
                  _bubbleText(subtitle),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, height: 1.12, fontWeight: FontWeight.w800, color: LumoColors.warmText),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.20),
                      boxShadow: [BoxShadow(color: Colors.white.withOpacity(.55), blurRadius: 50, spreadRadius: 18)],
                    ),
                  ),
                  lumo,
                ],
              ),
            ),
            const GoalCard(
              title: 'Tagesziel',
              subtitle: 'Schließe 3 Aktivitäten ab',
              completedSteps: 2,
              totalSteps: 3,
            ),
          ],
        ),
      ),
    );
  }

  String _bubbleText(String text) {
    if (text.trim().isEmpty) return 'Hallo!\nWomit wollen wir\nheute lernen?';
    if (text.length > 42) return text.replaceAll('. ', '.\n');
    return text;
  }
}
