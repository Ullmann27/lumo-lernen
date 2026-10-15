import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original Lumo illustrated subject emblem. Replaces platform-dependent
/// emoji flags/numbers with distinct native artwork on narrow Fold screens.
/// Geometry is painted with Flutter; only the existing Deutsch book PNG is
/// required. No network or downloadable fonts.
class AcademySubjectArt extends StatelessWidget {
  const AcademySubjectArt({
    super.key,
    required this.subjectName,
    required this.subjectId,
    required this.accent,
  });

  final String subjectName;
  final String subjectId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final base = switch (subjectName) {
      'Mathematik' => const Color(0xFF533518),
      'Deutsch' => const Color(0xFF3B2364),
      'Englisch' => const Color(0xFF153F83),
      'Sachunterricht' => const Color(0xFF11554D),
      _ => const Color(0xFF183153),
    };
    return Semantics(
      label: 'Fachsymbol $subjectName',
      child: Container(
        key: ValueKey('academy-grade-icon-$subjectId'),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base.withOpacity(.94), const Color(0xFF071B35)],
          ),
          border: Border.all(color: accent.withOpacity(.85), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(.33),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -24,
                left: -26,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      accent.withOpacity(.34),
                      accent.withOpacity(0),
                    ]),
                  ),
                ),
              ),
              Positioned(
                top: 4, left: 9, right: 9,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Center(child: ExcludeSemantics(child: _illustration())),
              Positioned(
                top: 6, right: 6,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 12, color: Colors.white.withOpacity(.80)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _illustration() => switch (subjectName) {
    'Mathematik' => const _MathEmblem(),
    'Deutsch' => const _BookEmblem(),
    'Englisch' => const _SpeechEmblem(),
    'Sachunterricht' => const _WorldEmblem(),
    _ => Icon(Icons.school_rounded, color: accent, size: 39),
  };
}

class _MathEmblem extends StatelessWidget {
  const _MathEmblem();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 60,
        height: 55,
        child: Stack(children: [
          Positioned(
            top: 4, left: 3,
            child: Transform.rotate(
              angle: -math.pi / 13,
              child: _NumberTile(
                value: '8',
                colors: [Color(0xFFFFD16A), Color(0xFFFF852B)],
                size: 35,
              ),
            ),
          ),
          Positioned(
            right: 2, bottom: 0,
            child: Transform.rotate(
              angle: math.pi / 13,
              child: _NumberTile(
                value: '+',
                colors: [Color(0xFFB5F3FF), Color(0xFF39A5D8)],
                size: 31,
              ),
            ),
          ),
        ]),
      );
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.value,
    required this.colors,
    required this.size,
  });

  final String value;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withOpacity(.88)),
          boxShadow: const [
            BoxShadow(
                color: Color(0xB0001020),
                blurRadius: 5,
                offset: Offset(3, 5)),
          ],
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 23,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Color(0xFF163552),
            shadows: [
              Shadow(color: Color(0x55FFFFFF), offset: Offset(0, 1)),
            ],
          ),
        ),
      );
}

class _BookEmblem extends StatelessWidget {
  const _BookEmblem();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 61,
    height: 55,
    child: Stack(children: [
      Positioned(
        top: 11,
        left: 6,
        child: Container(
          width: 51, height: 37,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color(0xFF9D75F7).withOpacity(.28),
            boxShadow: const [
              BoxShadow(color: Color(0xAAAB74FF), blurRadius: 13),
            ],
          ),
        ),
      ),
      Positioned.fill(
        child: Image.asset(
          'assets/lumo_design/icons/book_open.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.auto_stories_rounded,
            color: Color(0xFFF7D9FF),
            size: 42,
          ),
        ),
      ),
    ]),
  );
}

class _SpeechEmblem extends StatelessWidget {
  const _SpeechEmblem();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    height: 55,
    child: Stack(children: [
      Positioned(
        top: 3, right: 0,
        child: Icon(Icons.chat_bubble_rounded,
            color: const Color(0xFF2A94DB).withOpacity(.88), size: 39),
      ),
      const Positioned(
        top: 10, left: 0,
        child: Icon(Icons.chat_bubble_rounded,
            color: Color(0xFFA9F2FF), size: 43,
            shadows: [Shadow(color: Color(0xAA50DFFF), blurRadius: 9)]),
      ),
      const Positioned(
        top: 18, left: 9,
        child: Text('Hi!', style: TextStyle(
            color: Color(0xFF174779),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            height: 1,
          )),
      ),
    ]),
  );
}

class _WorldEmblem extends StatelessWidget {
  const _WorldEmblem();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 58,
    height: 55,
    child: Stack(children: [
      Positioned(
        top: 5, left: 5,
        child: Container(
          width: 47, height: 47,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-.6, -.65),
              radius: 1.15,
              colors: [
                Color(0xFFA4F6E8),
                Color(0xFF32B9B0),
                Color(0xFF146D7C),
              ],
            ),
            boxShadow: [
              BoxShadow(color: Color(0x8845DFD1), blurRadius: 12),
            ],
          ),
        ),
      ),
      const Positioned(
        top: 7, left: 7,
        child: Icon(Icons.public_rounded,
          size: 43, color: Color(0xFFDBFFF7)),
      ),
      const Positioned(
        bottom: 2, right: 0,
        child: Icon(Icons.eco_rounded,
          size: 20,
          color: Color(0xFFBAF47A),
          shadows: [Shadow(color: Color(0xAA86D73C), blurRadius: 7)],
        ),
      ),
    ]),
  );
}
