import 'package:flutter/material.dart';

import '../../core/lumo_conversation_controller.dart';
import '../../core/lumo_voice.dart';
import 'lumo_animated_fox.dart';

/// Uses the purple-hoodie Baby Lumo artwork and its articulated 2D rig.
/// No kart asset, separate speech engine, microphone or network access.
class LumoBabyConversationAvatar extends StatelessWidget {
  const LumoBabyConversationAvatar({
    super.key,
    required this.conversation,
    required this.listening,
    required this.thinking,
    required this.blocked,
    required this.reducedMotion,
    required this.size,
  });

  final LumoConversationController conversation;
  final bool listening, thinking, blocked, reducedMotion;
  final double size;

  @override
  Widget build(BuildContext context) {
    final voice = LumoVoice.instance;
    final routeActive = ModalRoute.of(context)?.isCurrent ?? true;
    final quiet = reducedMotion || MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        conversation,
        voice.status,
        voice.clipMouth,
        voice.mediaAudibility,
      ]),
      builder: (context, _) {
        final phase = conversation.phase;
        final paused = phase == LumoConversationPhase.paused;
        final active = routeActive && !paused;
        final speaking = active && conversation.avatarAudioActive;
        final hearing = active &&
            !speaking &&
            (listening || phase == LumoConversationPhase.listening);
        final pondering = active &&
            !speaking &&
            !hearing &&
            (thinking || phase == LumoConversationPhase.thinking);
        final expression = !active
            ? LumoFoxExpression.idle
            : speaking
                ? blocked
                    ? LumoFoxExpression.comfort
                    : LumoFoxExpression.explain
                : hearing
                    ? LumoFoxExpression.idle
                    : pondering
                        ? LumoFoxExpression.think
                        : blocked
                            ? LumoFoxExpression.comfort
                            : LumoFoxExpression.greet;
        final label = !active
            ? 'Pause'
            : speaking
                ? 'Lumo spricht'
                : hearing
                    ? 'Lumo hört dir zu'
                    : pondering
                        ? 'Lumo denkt nach'
                        : 'Lumo ist bereit';

        final fox = LumoAnimatedFox(
          key: const ValueKey('baby-lumo-original-rig'),
          size: size,
          moving: false,
          active: active,
          reducedMotion: quiet,
          expression: expression,
          conversationPerformance: true,
          mouthOverride: speaking ? conversation.avatarMouth : 0.0,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              image: true,
              label: 'Baby Lumo, kleiner Fuchs im violetten Pullover',
              child: ExcludeSemantics(
                child: quiet
                    ? fox
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: .68, end: 1.0),
                        duration: const Duration(milliseconds: 430),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) => Transform.scale(
                          scale: scale,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                        child: fox,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                key: const ValueKey('baby-lumo-dialogue-state'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE0F8FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
