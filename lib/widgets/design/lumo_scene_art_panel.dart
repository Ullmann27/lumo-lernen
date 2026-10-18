import 'package:flutter/material.dart';

import 'lumo_design_system.dart';

/// Transparent decorative 3D illustrations. Text, navigation and answers are
/// deliberately NOT baked into artwork and remain native Flutter widgets.
enum LumoSceneArt {
  storyLibrary,
  storyStarMap,
  seasons,
  mathematics,
}

extension LumoSceneArtAssets on LumoSceneArt {
  // Lightweight native cues keep each lesson recognizable even without PNGs.
  IconData get subjectIcon => switch (this) {
    LumoSceneArt.storyLibrary => Icons.menu_book_rounded,
    LumoSceneArt.storyStarMap => Icons.auto_awesome_rounded,
    LumoSceneArt.seasons => Icons.wb_sunny_rounded,
    LumoSceneArt.mathematics => Icons.calculate_rounded,
  };

  Color get subjectColor => switch (this) {
    LumoSceneArt.storyLibrary => const Color(0xFFFFCD75),
    LumoSceneArt.storyStarMap => const Color(0xFF81EBFF),
    LumoSceneArt.seasons => const Color(0xFFB0EEAE),
    LumoSceneArt.mathematics => const Color(0xFFFFAFDD),
  };

  String get assetPath {
    switch (this) {
      case LumoSceneArt.storyLibrary:
        return 'assets/lumo_design/fox/lumo_story_library_cutout.png';
      case LumoSceneArt.storyStarMap:
        return 'assets/lumo_design/fox/lumo_story_starmap_cutout.png';
      case LumoSceneArt.seasons:
        return 'assets/lumo_design/fox/lumo_seasons_cutout.png';
      case LumoSceneArt.mathematics:
        return 'assets/lumo_design/fox/lumo_math_cutout.png';
    }
  }

  String get description {
    switch (this) {
      case LumoSceneArt.storyLibrary:
        return 'Lumo liest mit seiner Katze ein magisches Buch in der Bücherei';
      case LumoSceneArt.storyStarMap:
        return 'Lumo entdeckt mit seinem Roboter eine leuchtende Sternenkarte';
      case LumoSceneArt.seasons:
        return 'Lumo erforscht die Jahreszeiten';
      case LumoSceneArt.mathematics:
        return 'Lumo begleitet dich beim Zahlenrätsel';
    }
  }
}

/// Real artwork is optional at runtime until the four transparent PNG assets
/// are uploaded. Existing Lumo fox artwork is used as a safe fallback.
/// This panel has no gesture handlers and never covers actionable UI.
class LumoSceneArtPanel extends StatelessWidget {
  const LumoSceneArtPanel({
    super.key,
    required this.scene,
    this.height = 180,
  });

  final LumoSceneArt scene;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Only the entry moves. The art itself never triggers perpetual repaints.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      image: true,
      label: scene.description,
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => Transform.translate(
            offset: Offset(0, (1 - progress) * 8),
            child: child,
          ),
          child: SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF071C3B),
                  Color(0xFF124772),
                  Color(0xFF0A2148),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF53D9FB), width: 1.25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5539D5FF),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -70,
                  right: -35,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x8874D9FF), Color(0x0074D9FF)],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(
                    scene.assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: LumoFoxPose(
                          pose: LumoDesignFoxPose.bookPoint,
                          size: 130,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Icon(
                    scene.subjectIcon,
                    color: scene.subjectColor,
                    size: 27,
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }
}
