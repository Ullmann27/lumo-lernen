import 'package:flutter/material.dart';

import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';

/// Optional, non-modal help invitation after repeat attempts. No voice or
/// automatic answer reveal until the child explicitly chooses "Zeig es mir".
class LumoTutorOfferCard extends StatelessWidget {
  const LumoTutorOfferCard({
    super.key,
    required this.onAccept,
    required this.onDecline,
    this.reduceMotion = false,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final calm = reduceMotion || MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      label: 'Lumo bietet freiwillige Lernhilfe an.',
      child: Container(
        key: const ValueKey('lumo-tutor-offer-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF00A3768), Color(0xF0071B3E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xB04EDCFF),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3400DFFF),
              blurRadius: 17,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: LumoCharacter(
                    key: const ValueKey('lumo-tutor-offer-fox'),
                    pose: LumoDesignFoxPose.teacherStick,
                    size: 76,
                    reduceMotion: calm,
                    idleHops: !calm,
                    intro: !calm,
                    shadow: false,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lumo ist für dich da',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Soll ich dir das auf eine andere Art zeigen?',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: Color(0xFFE1F7FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 315;
                final accept = FilledButton.icon(
                  key: const ValueKey('lumo-tutor-offer-accept'),
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: const Color(0xFF50D5F9),
                    foregroundColor: const Color(0xFF052A4B),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 19),
                  label: const Text(
                    'Ja, zeig es mir',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontWeight: FontWeight.w900),
                  ),
                );
                final decline = OutlinedButton(
                  key: const ValueKey('lumo-tutor-offer-decline'),
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: const Color(0xFFF3FAFF),
                    side: const BorderSide(color: Color(0xA2B5EEFF)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Ich probiere allein',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontWeight: FontWeight.w800),
                  ),
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      accept,
                      const SizedBox(height: 8),
                      decline,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: accept),
                    const SizedBox(width: 8),
                    Expanded(child: decline),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
