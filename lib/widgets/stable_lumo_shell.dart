import 'package:flutter/material.dart';

class StableLumoShell extends StatelessWidget {
  const StableLumoShell({
    super.key,
    required this.activeIndex,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.lumo,
    required this.stars,
    required this.xp,
    required this.level,
    required this.progress,
    required this.onHome,
    required this.onLearn,
    required this.onPractice,
    required this.onTest,
    required this.onScan,
    required this.onProfile,
    this.onVoice,
  });

  final int activeIndex;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget lumo;
  final int stars;
  final int xp;
  final int level;
  final int progress;
  final VoidCallback onHome;
  final VoidCallback onLearn;
  final VoidCallback onPractice;
  final VoidCallback onTest;
  final VoidCallback onScan;
  final VoidCallback onProfile;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final items = [
      _Nav('Start', Icons.home_rounded, const Color(0xffff7a1a), onHome),
      _Nav('Lernen', Icons.school_rounded, const Color(0xff8b5cf6), onLearn),
      _Nav('Übungen', Icons.edit_rounded, const Color(0xffff6b6b), onPractice),
      _Nav('Fortschritt', Icons.bar_chart_rounded, const Color(0xff14b8a6), onProfile),
      _Nav('Belohnungen', Icons.star_rounded, const Color(0xffffc107), onPractice),
      _Nav('Profil', Icons.person_rounded, const Color(0xffa855f7), onProfile),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.28,
          colors: [Color(0xffffdfb3), Color(0xfffffbf4), Color(0xffecfff7)],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xfffffbf4),
          borderRadius: BorderRadius.circular(38),
          boxShadow: [
            BoxShadow(color: const Color(0xffff9f43).withOpacity(.14), blurRadius: 46, offset: const Offset(0, 24)),
            BoxShadow(color: Colors.white.withOpacity(.90), blurRadius: 20, offset: const Offset(-8, -8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: Material(
            color: Colors.transparent,
            child: wide
                ? Row(children: [
                    _LeftNavigation(items: items, activeIndex: activeIndex),
                    Expanded(
                      child: _MainContentHost(
                        title: title,
                        body: body,
                        stars: stars,
                        xp: xp,
                        level: level,
                        progress: progress,
                        onVoice: onVoice,
                      ),
                    ),
                    _LumoStagePanel(
                      lumo: lumo,
                      subtitle: subtitle,
                    ),
                  ])
                : Column(children: [
                    Expanded(
                      child: _MainContentHost(
                        title: title,
                        body: body,
                        stars: stars,
                        xp: xp,
                        level: level,
                        progress: progress,
                        onVoice: onVoice,
                      ),
                    ),
                    NavigationBar(
                      selectedIndex: activeIndex.clamp(0, items.length - 1),
                      onDestinationSelected: (i) => items[i].tap(),
                      destinations: [for (final n in items) NavigationDestination(icon: Icon(n.icon), label: n.label)],
                    ),
                  ]),
          ),
        ),
      ),
    );
  }
}

class _Nav {
  const _Nav(this.label, this.icon, this.color, this.tap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback tap;
}

class _LeftNavigation extends StatelessWidget {
  const _LeftNavigation({required this.items, required this.activeIndex});
  final List<_Nav> items;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.fromLTRB(24, 28, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xfffff7ee), Color(0xfffffbf6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
          for (var i = 0; i < items.length; i++) _NavPill(item: items[i], selected: i == activeIndex),
          const Spacer(),
          Container(
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
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.item, required this.selected});
  final _Nav item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: item.tap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: selected
              ? BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xfffff1df), Color(0xffffdfb9)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xffff8a2a).withOpacity(.24), blurRadius: 22, offset: const Offset(0, 10))],
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: _softBox(15, Colors.white.withOpacity(.94)),
                child: Icon(item.icon, color: item.color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: selected ? const Color(0xffff6d00) : const Color(0xff655b54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainContentHost extends StatelessWidget {
  const _MainContentHost({required this.title, required this.body, required this.stars, required this.xp, required this.level, required this.progress, this.onVoice});
  final String title;
  final Widget body;
  final int stars;
  final int xp;
  final int level;
  final int progress;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 28, 26, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hallo, Lena! 👋', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
                    SizedBox(height: 5),
                    Text('Bereit für ein neues Lernabenteuer?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xff766a61))),
                  ],
                ),
              ),
              if (onVoice != null) IconButton.filledTonal(onPressed: onVoice, icon: const Icon(Icons.volume_up_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _KpiCard(title: 'Sterne', value: '$stars /50', icon: '⭐', color: const Color(0xffb455f6), percent: (stars / 50).clamp(0, 1).toDouble()),
                const SizedBox(width: 16),
                _KpiCard(title: 'XP Punkte', value: '$xp', icon: '🏅', color: const Color(0xffffb000), percent: .62),
                const SizedBox(width: 16),
                _KpiCard(title: 'Level', value: '$level Einsteiger', icon: '💎', color: const Color(0xff12bfa6), percent: .70),
                const SizedBox(width: 16),
                _KpiCard(title: 'Lernfortschritt', value: '$progress%', icon: '🌊', color: const Color(0xff3b8dff), percent: progress / 100),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
          const SizedBox(height: 15),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(key: ValueKey(title), child: body),
          ),
        ],
      ),
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
      width: 168,
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: _softBox(24, Colors.white.withOpacity(.86)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 31, shadows: [Shadow(color: Colors.black12, blurRadius: 9, offset: Offset(0, 4))])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: percent.clamp(0, 1), minHeight: 7, color: color, backgroundColor: color.withOpacity(.13))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LumoStagePanel extends StatelessWidget {
  const _LumoStagePanel({required this.lumo, required this.subtitle});
  final Widget lumo;
  final String subtitle;

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
                child: Text(_bubbleText(subtitle), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, height: 1.12, fontWeight: FontWeight.w800, color: Color(0xff2d2621))),
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
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('Tagesziel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
                    SizedBox(height: 6),
                    Text('Schließe 3 Aktivitäten ab', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff766a61))),
                    SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xff4ec96f), size: 24),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_rounded, color: Color(0xff4ec96f), size: 24),
                      SizedBox(width: 8),
                      CircleAvatar(radius: 13, backgroundColor: Colors.white, child: Text('3', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xffb77c46)))),
                    ]),
                  ])),
                  CircleAvatar(radius: 32, backgroundColor: Color(0xfffff3c7), child: Text('🎁', style: TextStyle(fontSize: 27))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bubbleText(String text) {
    if (text.trim().isEmpty) return 'Hallo!\nWomit wollen wir\nheute lernen?';
    if (text.length > 42) return text.replaceAll('. ', '.\n');
    return text;
  }
}

BoxDecoration _softBox(double radius, Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(.76), width: 1),
      boxShadow: [
        BoxShadow(color: Colors.deepOrange.withOpacity(.10), blurRadius: 18, offset: const Offset(0, 10)),
        BoxShadow(color: Colors.white.withOpacity(.75), blurRadius: 8, offset: const Offset(-3, -3)),
      ],
    );
