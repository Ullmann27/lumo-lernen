import 'package:flutter/material.dart';

class ReferenceHomeDashboard extends StatelessWidget {
  const ReferenceHomeDashboard({
    super.key,
    required this.stars,
    required this.xp,
    required this.level,
    required this.progress,
    required this.lumo,
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

  final int stars;
  final int xp;
  final int level;
  final int progress;
  final Widget lumo;
  final VoidCallback onMath;
  final VoidCallback onGerman;
  final VoidCallback onEnglish;
  final VoidCallback onPractice;
  final VoidCallback onTest;
  final VoidCallback onSchoolwork;
  final VoidCallback onPhoto;
  final VoidCallback onContinue;
  final VoidCallback onProfile;

  static const String homeReferenceAsset = 'assets/images/lumo_home_reference.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfffffbf4),
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: Image.asset(
                    homeReferenceAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _fallbackHome(),
                  ),
                ),
                _tapZone(left: .155, top: .350, width: .175, height: .210, onTap: onMath),
                _tapZone(left: .345, top: .350, width: .175, height: .210, onTap: onGerman),
                _tapZone(left: .535, top: .350, width: .175, height: .210, onTap: onEnglish),
                _tapZone(left: .155, top: .585, width: .175, height: .205, onTap: onPractice),
                _tapZone(left: .345, top: .585, width: .175, height: .205, onTap: onTest),
                _tapZone(left: .535, top: .585, width: .175, height: .205, onTap: onSchoolwork),
                _tapZone(left: .155, top: .805, width: .290, height: .170, onTap: onPhoto),
                _tapZone(left: .455, top: .805, width: .255, height: .170, onTap: onContinue),
                _tapZone(left: .018, top: .865, width: .115, height: .110, onTap: onProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tapZone({
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Positioned(
          left: constraints.maxWidth * left,
          top: constraints.maxHeight * top,
          width: constraints.maxWidth * width,
          height: constraints.maxHeight * height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.orange.withOpacity(.08),
              highlightColor: Colors.orange.withOpacity(.05),
              borderRadius: BorderRadius.circular(28),
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackHome() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xfffffbf4), Color(0xfffff1df), Color(0xffffe0b2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.85),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(.12), blurRadius: 28, offset: const Offset(0, 14))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.image_rounded, size: 64, color: Color(0xffff8a00)),
              SizedBox(height: 16),
              Text('Home-Design-Bild fehlt', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text(
                'Bitte das finale HomeScreen-Bild als assets/images/lumo_home_reference.png hochladen. Danach erscheint der HomeScreen pixelnah wie die Vorlage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w600, color: Color(0xff6b5b4b)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
