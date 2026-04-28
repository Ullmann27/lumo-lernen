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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.25,
          colors: [Color(0xffffdfb3), Color(0xfffffbf4), Color(0xffecfff7)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xfffffbf4),
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              BoxShadow(color: Colors.deepOrange.withOpacity(.12), blurRadius: 46, offset: const Offset(0, 24)),
              BoxShadow(color: Colors.white.withOpacity(.95), blurRadius: 18, offset: const Offset(-6, -6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              _Sidebar(onProfile: onProfile, onLearn: onMath, onPractice: onPractice),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(30, 28, 26, 26),
                  child: _CenterDashboard(
                    stars: stars,
                    xp: xp,
                    level: level,
                    progress: progress,
                    onMath: onMath,
                    onGerman: onGerman,
                    onEnglish: onEnglish,
                    onPractice: onPractice,
                    onTest: onTest,
                    onSchoolwork: onSchoolwork,
                    onPhoto: onPhoto,
                    onContinue: onContinue,
                  ),
                ),
              ),
              _LumoStage(lumo: lumo),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.onProfile, required this.onLearn, required this.onPractice});
  final VoidCallback onProfile;
  final VoidCallback onLearn;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.fromLTRB(24, 28, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xfffff7ee), Color(0xfffffbf6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Lumo', style: TextStyle(fontSize: 30, height: .9, fontWeight: FontWeight.w900, color: Color(0xffff6d00))),
                TextSpan(text: ' ✦\n', style: TextStyle(fontSize: 17, height: .9, fontWeight: FontWeight.w900, color: Color(0xffffa000))),
                TextSpan(text: 'Lernen', style: TextStyle(fontSize: 30, height: .9, fontWeight: FontWeight.w900, color: Color(0xff2e2925))),
              ],
            ),
          ),
          const SizedBox(height: 34),
          _NavItem(icon: Icons.home_rounded, label: 'Start', selected: true, color: const Color(0xffff7a1a), onTap: () {}),
          _NavItem(icon: Icons.school_rounded, label: 'Lernen', color: const Color(0xff8b5cf6), onTap: onLearn),
          _NavItem(icon: Icons.edit_rounded, label: 'Übungen', color: const Color(0xffff6b6b), onTap: onPractice),
          _NavItem(icon: Icons.bar_chart_rounded, label: 'Fortschritt', color: const Color(0xff14b8a6), onTap: onProfile),
          _NavItem(icon: Icons.star_rounded, label: 'Belohnungen', color: const Color(0xffffc107), onTap: () {}),
          _NavItem(icon: Icons.person_rounded, label: 'Profil', color: const Color(0xffa855f7), onTap: onProfile),
          const Spacer(),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: _softBox(24, Colors.white.withOpacity(.88)),
              child: const Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: Color(0xffffdfb8), child: Text('🦊', style: TextStyle(fontSize: 18))),
                  SizedBox(width: 10),
                  Expanded(child: Text('Lena\nKlasse 2', style: TextStyle(fontSize: 13, height: 1.08, fontWeight: FontWeight.w900, color: Color(0xff2e2925)))),
                  Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xff8c7b70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.color, required this.onTap, this.selected = false});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: selected
              ? BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xffff7a1a), Color(0xffff9a4e)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(.32), blurRadius: 18, offset: const Offset(0, 8))],
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: _softBox(15, selected ? Colors.white.withOpacity(.25) : Colors.white.withOpacity(.94)),
                child: Icon(icon, color: selected ? Colors.white : color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: selected ? Colors.white : const Color(0xff655b54)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterDashboard extends StatelessWidget {
  const _CenterDashboard({
    required this.stars,
    required this.xp,
    required this.level,
    required this.progress,
    required this.onMath,
    required this.onGerman,
    required this.onEnglish,
    required this.onPractice,
    required this.onTest,
    required this.onSchoolwork,
    required this.onPhoto,
    required this.onContinue,
  });

  final int stars;
  final int xp;
  final int level;
  final int progress;
  final VoidCallback onMath;
  final VoidCallback onGerman;
  final VoidCallback onEnglish;
  final VoidCallback onPractice;
  final VoidCallback onTest;
  final VoidCallback onSchoolwork;
  final VoidCallback onPhoto;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cardW = ((c.maxWidth - 32) / 3).clamp(185.0, 265.0);
        final wideW = ((c.maxWidth - 16) / 2).clamp(285.0, 430.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hallo, Lena! 👋', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
            const SizedBox(height: 5),
            const Text('Bereit für ein neues Lernabenteuer?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xff766a61))),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _KpiCard(title: 'Sterne', value: '$stars /50', icon: '⭐', color: const Color(0xffb455f6), percent: stars / 50),
                  const SizedBox(width: 16),
                  _KpiCard(title: 'XP Punkte', value: '$xp', icon: '🏅', color: const Color(0xffffb000), percent: (xp % 1000) / 1000),
                  const SizedBox(width: 16),
                  _KpiCard(title: 'Level', value: '$level Einsteiger', icon: '💎', color: const Color(0xff12bfa6), percent: .70),
                  const SizedBox(width: 16),
                  _CircularKpiCard(title: 'Lernfortschritt', value: '$progress%', subtitle: 'Diese Woche', color: const Color(0xff3b8dff), percent: progress / 100),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Was möchtest du lernen?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
            const SizedBox(height: 15),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _LearningCard(width: cardW, title: 'Mathematik', sub: 'Zahlen, Rechnen,\nGeometrie & mehr', cta: 'Weiterlernen', object: '1²', icon: Icons.calculate_rounded, colors: const [Color(0xfffff4bd), Color(0xffffdfa2)], accent: const Color(0xffff8700), onTap: onMath),
                _LearningCard(width: cardW, title: 'Deutsch', sub: 'Lesen, Schreiben,\nGrammatik', cta: 'Weiterlernen', object: 'A', icon: Icons.menu_book_rounded, colors: const [Color(0xffffe8fb), Color(0xfff0dcff)], accent: const Color(0xff8b5cf6), onTap: onGerman),
                _LearningCard(width: cardW, title: 'Englisch', sub: 'Wörter, Sätze,\nVerstehen', cta: 'Weiterlernen', object: 'Hi!', icon: Icons.language_rounded, colors: const [Color(0xffdffff6), Color(0xffc8f5ed)], accent: const Color(0xff10a894), onTap: onEnglish),
                _LearningCard(width: cardW, title: 'Übung', sub: 'Interaktive Übungen\nund Spiele', cta: 'Üben', object: '🎮', icon: Icons.edit_rounded, colors: const [Color(0xffffe6e2), Color(0xffffd2ce)], accent: const Color(0xffff625d), onTap: onPractice),
                _LearningCard(width: cardW, title: 'Test', sub: 'Teste dein Wissen\nund sammle Sterne', cta: 'Test starten', object: '📋', icon: Icons.assignment_turned_in_rounded, colors: const [Color(0xffeaf3ff), Color(0xffdbeaff)], accent: const Color(0xff3a86e8), onTap: onTest),
                _LearningCard(width: cardW, title: 'Schularbeit', sub: 'Gemischter Test\nmit Note', cta: 'Starten', object: 'A+', icon: Icons.description_rounded, colors: const [Color(0xfffff2c9), Color(0xffffe0a8)], accent: const Color(0xffff9800), onTap: onSchoolwork),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _WideLearningCard(width: wideW, title: 'Aufgabe fotografieren', sub: 'Mach ein Foto deiner Aufgabe\nund lass dir helfen!', cta: 'Foto machen', object: '📷', icon: Icons.photo_camera_rounded, colors: const [Color(0xffffe8ff), Color(0xfff2d7ff)], accent: const Color(0xff9c55e8), onTap: onPhoto),
                _WideLearningCard(width: wideW, title: 'Weiterlernen', sub: 'Setze da weiter, wo du\naufgehört hast', cta: 'Anzeigen', object: '📖', icon: Icons.play_circle_rounded, colors: const [Color(0xffe5fff6), Color(0xffcffff0)], accent: const Color(0xff08a892), onTap: onContinue),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value, required this.icon, required this.color, required this.percent});
  final String title;
  final String value;
  final String icon;
  final Color color;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      height: 112,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: _softBox(26, Colors.white.withOpacity(.92)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(
                fontSize: 34,
                shadows: [Shadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              )),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(height: 1),
                    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 26, height: 1.05, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 7,
              color: color,
              backgroundColor: color.withOpacity(.13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lernfortschritt-Karte mit Kreis-Fortschrittsanzeige (wie im Screenshot)
class _CircularKpiCard extends StatelessWidget {
  const _CircularKpiCard({required this.title, required this.value, required this.subtitle, required this.color, required this.percent});
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      height: 112,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _softBox(26, Colors.white.withOpacity(.92)),
      child: Row(
        children: [
          // Donut ring
          SizedBox(
            width: 56, height: 56,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                strokeWidth: 6.5,
                color: color,
                backgroundColor: color.withOpacity(.13),
                strokeCap: StrokeCap.round,
              ),
              Text(value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 26, height: 1.05, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff9ca3af))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.width, required this.title, required this.sub, required this.cta, required this.object, required this.icon, required this.colors, required this.accent, required this.onTap});
  final double width;
  final String title;
  final String sub;
  final String cta;
  final String object;
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(width: width, height: 168, colors: colors, onTap: onTap, child: Stack(children: [
      Positioned(right: 12, bottom: 8, child: _ObjectBadge(text: object, color: accent, big: true)),
      _CardText(title: title, sub: sub, cta: cta, icon: icon, accent: accent),
    ]));
  }
}

class _WideLearningCard extends StatelessWidget {
  const _WideLearningCard({required this.width, required this.title, required this.sub, required this.cta, required this.object, required this.icon, required this.colors, required this.accent, required this.onTap});
  final double width;
  final String title;
  final String sub;
  final String cta;
  final String object;
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(width: width, height: 148, colors: colors, onTap: onTap, child: Stack(children: [
      Positioned(right: 18, bottom: 8, child: _ObjectBadge(text: object, color: accent, big: true)),
      _CardText(title: title, sub: sub, cta: cta, icon: icon, accent: accent),
    ]));
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.width, required this.height, required this.colors, required this.child, required this.onTap});
  final double width;
  final double height;
  final List<Color> colors;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      builder: (context, v, _) => Transform.translate(
        offset: Offset(0, (1 - v) * 10),
        child: Opacity(
          opacity: v,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(.78), width: 1.2),
                boxShadow: [
                  BoxShadow(color: colors.last.withOpacity(.32), blurRadius: 22, offset: const Offset(0, 13)),
                  BoxShadow(color: Colors.white.withOpacity(.95), blurRadius: 8, offset: const Offset(-4, -4)),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({required this.title, required this.sub, required this.cta, required this.icon, required this.accent});
  final String title;
  final String sub;
  final String cta;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: _softBox(15, Colors.white.withOpacity(.88)), child: Icon(icon, color: accent, size: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accent.darken(.20)))),
        ]),
        const SizedBox(height: 10),
        Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.15, fontWeight: FontWeight.w700, color: Color(0xff635850))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.74), borderRadius: BorderRadius.circular(99), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 4))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(cta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accent.darken(.25))), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 15, color: accent.darken(.25))]),
        ),
      ],
    );
  }
}

class _ObjectBadge extends StatelessWidget {
  const _ObjectBadge({required this.text, required this.color, this.big = false});
  final String text;
  final Color color;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: big ? 70 : 52, minHeight: big ? 62 : 48),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(.92), color.withOpacity(.22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(.28), blurRadius: 18, offset: const Offset(0, 9))],
      ),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: big ? 39 : 28, height: 1, fontWeight: FontWeight.w900, color: color, shadows: const [Shadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))])),
    );
  }
}

class _LumoStage extends StatelessWidget {
  const _LumoStage({required this.lumo});
  final Widget lumo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(0, 16, 22, 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xffffd190), Color(0xffffe2af), Color(0xffffedcf)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: Colors.white.withOpacity(.72), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xffffb96b).withOpacity(.38), blurRadius: 32, spreadRadius: 4, offset: const Offset(0, 14))],
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.88), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 15, offset: const Offset(0, 7))]),
                child: const Text('Hallo!\nWomit wollen wir\nheute lernen?', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, height: 1.12, fontWeight: FontWeight.w800, color: Color(0xff2d2621))),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.20), boxShadow: [BoxShadow(color: Colors.white.withOpacity(.55), blurRadius: 50, spreadRadius: 18)])),
                  lumo,
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.74), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 8))]),
              child: const Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Tagesziel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xff2d2621))), SizedBox(height: 6), Text('Schließe 3 Aktivitäten ab', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff766a61))), SizedBox(height: 10), Row(children: [Icon(Icons.check_circle_rounded, color: Color(0xff4ec96f), size: 24), SizedBox(width: 8), Icon(Icons.check_circle_rounded, color: Color(0xff4ec96f), size: 24), SizedBox(width: 8), CircleAvatar(radius: 13, backgroundColor: Colors.white, child: Text('3', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xffb77c46))))])])),
                  CircleAvatar(radius: 32, backgroundColor: Color(0xfffff3c7), child: Text('🎁', style: TextStyle(fontSize: 27))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _softBox(double radius, Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(.76), width: 1),
      boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(.10), blurRadius: 18, offset: const Offset(0, 10)), BoxShadow(color: Colors.white.withOpacity(.75), blurRadius: 8, offset: const Offset(-3, -3))],
    );

extension _ColorX on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
