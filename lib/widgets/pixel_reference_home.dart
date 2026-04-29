import 'package:flutter/material.dart';

class PixelReferenceHome extends StatelessWidget {
  const PixelReferenceHome({
    super.key,
    required this.fallback,
    required this.onMath,
    required this.onGerman,
    required this.onEnglish,
    required this.onPractice,
    required this.onTest,
    required this.onSchoolwork,
    required this.onPhoto,
    required this.onContinue,
    required this.onProfile,
  });

  final Widget fallback;
  final VoidCallback onMath;
  final VoidCallback onGerman;
  final VoidCallback onEnglish;
  final VoidCallback onPractice;
  final VoidCallback onTest;
  final VoidCallback onSchoolwork;
  final VoidCallback onPhoto;
  final VoidCallback onContinue;
  final VoidCallback onProfile;

  static const String assetPath = 'assets/images/lumo_home_reference.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null && !wasSynchronouslyLoaded) return fallback;
        return Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(34), child: child),
                _hotspot(left: .160, top: .275, width: .160, height: .230, onTap: onMath),
                _hotspot(left: .330, top: .275, width: .160, height: .230, onTap: onGerman),
                _hotspot(left: .500, top: .275, width: .160, height: .230, onTap: onEnglish),
                _hotspot(left: .160, top: .520, width: .160, height: .220, onTap: onPractice),
                _hotspot(left: .330, top: .520, width: .160, height: .220, onTap: onTest),
                _hotspot(left: .500, top: .520, width: .160, height: .220, onTap: onSchoolwork),
                _hotspot(left: .160, top: .760, width: .245, height: .205, onTap: onPhoto),
                _hotspot(left: .420, top: .760, width: .245, height: .205, onTap: onContinue),
                _hotspot(left: .020, top: .845, width: .105, height: .120, onTap: onProfile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hotspot({
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * left,
              top: constraints.maxHeight * top,
              width: constraints.maxWidth * width,
              height: constraints.maxHeight * height,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onTap,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
