import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/design/lumo_materials.dart';
import '../../../widgets/design/lumo_scene_atmosphere.dart';
import '../../../widgets/design/lumo_scene_artwork.dart';
import '../../../widgets/design/lumo_character_stage.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';

/// The original character and original scene remain separate image layers.
/// All labels and the principal action are real, responsive Flutter widgets.
class LumoHomeHero extends StatelessWidget {
  const LumoHomeHero({
    super.key,
    required this.name,
    required this.reduceMotion,
    required this.onLearn,
  });

  final String name;
  final bool reduceMotion;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, bounds) {
          final width = bounds.maxWidth;
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final stacked = scale > 1.45;
          final foxSize = stacked
              ? (width * .66).clamp(150.0, 260.0)
              : (width * .51).clamp(124.0, 270.0);
          const eyebrow = Text('DEIN LERNABENTEUER',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: LumoVisualTokens.cyanBright,
                  fontWeight: FontWeight.w900));
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hallo, $name!',
                  key: const ValueKey('home-greeting'),
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: width < 340 ? 22 : 24,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white)),
              const SizedBox(height: 10),
              const Text('Bereit für ein neues Abenteuer?',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: LumoVisualTokens.white)),
            ],
          );
          final action = LumoGoldAction(
            key: const ValueKey('home-start-learning'),
            label: 'Loslernen',
            onPressed: onLearn,
          );
          final fox = SizedBox(
            width: foxSize,
            height: foxSize * 1.06,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: LumoCharacterStage(
                pose: LumoDesignFoxPose.bookWelcome,
                size: foxSize,
                reduceMotion: reduceMotion,
                onTap: () =>
                    LumoCompanionRequests.instance.requestAppExplanation(),
              ),
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, (1 - value) * 6),
                child: Transform.rotate(
                    angle: -.025 * (1 - value),
                    alignment: Alignment.bottomCenter,
                    child: child),
              ),
            ),
          );
          return Container(
            key: const ValueKey('home-adventure-hero'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: LumoVisualTokens.cyan.withValues(alpha: .55)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x4000081C),
                    blurRadius: 18,
                    offset: Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: LumoSceneAtmosphere(
                reduceMotion: reduceMotion,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: LumoSceneArtwork(
                        asset: 'assets/lumo_design/bg/bg_glass_islands.png',
                        alignment: Alignment(0, -.42),
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [0, .45, 1],
                            colors: [
                              Color(0xD503193F),
                              Color(0x6803193F),
                              Color(0x0003193F)
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0, .7, 1],
                            colors: [
                              Color(0x1003193F),
                              Color(0x0003193F),
                              Color(0xB003193F)
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (stacked)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            eyebrow,
                            const SizedBox(height: 10),
                            title,
                            const SizedBox(height: 8),
                            Align(alignment: Alignment.centerRight, child: fox),
                            const SizedBox(height: 12),
                            action,
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            eyebrow,
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      title,
                                      const SizedBox(height: 22),
                                      action,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                fox,
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
