import 'package:flutter/material.dart';

import '../../../core/lumo_voice.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../../widgets/design/lumo_design_system.dart';

/// Dark hologlass tutoring surface, using Lumo's original transparent fox art.
///
/// Keeps the explanation legible on phone and Fold layouts. Entrance motion is
/// finite, and is disabled when Android or Lumo requests reduced animations.
class LumoTutorHintCard extends StatefulWidget {
  const LumoTutorHintCard({
    super.key,
    required this.text,
    required this.onSpeak,
    this.reduceMotion = false,
  });

  final String text;
  final VoidCallback onSpeak;
  final bool reduceMotion;

  @override
  State<LumoTutorHintCard> createState() => _LumoTutorHintCardState();
}

class _LumoTutorHintCardState extends State<LumoTutorHintCard>
    with SingleTickerProviderStateMixin {
  final LumoCharacterController _fox = LumoCharacterController();

  void _speakWithLumoMotion() {
    _fox.talk();
    widget.onSpeak();
  }

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _fox.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = widget.reduceMotion ||
        MediaQuery.disableAnimationsOf(context);
    final card = Container(
      key: const ValueKey('lumo-hologlass-tutor-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 13, 16, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF00A3768), Color(0xF0071B3E)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xB04EDCFF), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3A00D7FF),
            blurRadius: 17,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 100,
            child: Center(
              // Keep the mascot still when silent: no perpetual ticker while
              // reading or in widget tests. During actual speech it breathes,
              // gestures and alternates between Lumo's original poses.
              child: ValueListenableBuilder<VoiceStatus>(
                valueListenable: LumoVoice.instance.status,
                builder: (context, status, _) => LumoCharacter(
                  key: const ValueKey('lumo-hint-animated-fox'),
                  pose: LumoDesignFoxPose.teacherStick,
                  size: 74,
                  shadow: false,
                  idleHops: false,
                  reduceMotion: reduceMotion ||
                      status != VoiceStatus.speaking,
                  controller: _fox,
                  onTap: _speakWithLumoMotion,
                  ambientPoses: const [
                    LumoDesignFoxPose.teacherStick,
                    LumoDesignFoxPose.bookPoint,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    const Text(
                      'Lumo erklärt',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x3340D9FF),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0x9940D9FF)),
                      ),
                      child: const Text(
                        'TIPP',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Color(0xFF81E9FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  widget.text,
                  key: const ValueKey('lumo-hint-readable-text'),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: Color(0xFFF3FAFF),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('lumo-hint-listen'),
                  onPressed: _speakWithLumoMotion,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 43),
                    foregroundColor: const Color(0xFFE2FAFF),
                    side: const BorderSide(
                        color: Color(0xB04EDCFF)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: const Icon(
                      Icons.volume_up_rounded, size: 18),
                  label: const Text(
                    'Tipp anhören',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) return card;
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.07),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeOutCubic)),
        child: card,
      ),
    );
  }
}
