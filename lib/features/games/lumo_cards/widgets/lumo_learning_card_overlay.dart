// ════════════════════════════════════════════════════════════════════════
// LUMO LEARNING CARD OVERLAY — Denkpause-Frage
// ════════════════════════════════════════════════════════════════════════
// Wird angezeigt wenn die Denkpause-Karte gespielt wurde.
// Richtig: +1 Stern + nochmal legen. Falsch: freundlicher Tipp + Zug wechselt.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../../../core/lumo_companion_pose.dart';
import '../../../companion/lumo_companion_pose_image.dart';
import '../lumo_cards_models.dart';

class LumoLearningCardOverlay extends StatelessWidget {
  const LumoLearningCardOverlay({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  final LearningQuestion question;
  final void Function(int chosenIndex) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFCD34D), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // PR B 2026-05-23: Lumo-Fuchs think-Pose statt Emoji.
                  const LumoCompanionPoseImage(
                    pose: LumoCompanionPose.think,
                    size: 44,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Denkpause',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7C2D12),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCD34D).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFCA8A04)),
                        SizedBox(width: 4),
                        Text(
                          '+1',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7C2D12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                question.prompt,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C2D12),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              // Antwort-Buttons als 2-spaltiges Grid.
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.5,
                children: [
                  for (int i = 0; i < question.options.length; i++)
                    _AnswerButton(
                      label: question.options[i],
                      onTap: () => onAnswer(i),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFF59E0B), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C2D12),
          ),
        ),
      ),
    );
  }
}
