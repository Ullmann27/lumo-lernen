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
      _Nav('Start', Icons.home_rounded, onHome),
      _Nav('Lernen', Icons.school_rounded, onLearn),
      _Nav('Übungen', Icons.edit_rounded, onPractice),
      _Nav('Test', Icons.assignment_rounded, onTest),
      _Nav('Erkennen', Icons.photo_camera_rounded, onScan),
      _Nav('Profil', Icons.person_rounded, onProfile),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment.topRight, radius: 1.25, colors: [Color(0xffffdfb3), Color(0xfffffbf4), Color(0xffecfff7)]),
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: Material(
          color: const Color(0xfffffbf4),
          child: wide
              ? Row(children: [_Side(items, activeIndex), Expanded(child: _Center(title, subtitle, body, onVoice)), _Right(lumo, stars, xp, level, progress, subtitle)])
              : Column(children: [Expanded(child: _Center(title, subtitle, body, onVoice)), NavigationBar(selectedIndex: activeIndex.clamp(0, items.length - 1), onDestinationSelected: (i) => items[i].tap(), destinations: [for (final n in items) NavigationDestination(icon: Icon(n.icon), label: n.label)])]),
        ),
      ),
    );
  }
}

class _Nav {
  const _Nav(this.label, this.icon, this.tap);
  final String label;
  final IconData icon;
  final VoidCallback tap;
}

class _Side extends StatelessWidget {
  const _Side(this.items, this.active);
  final List<_Nav> items;
  final int active;
  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.fromLTRB(24, 28, 18, 22),
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xfffff7ee), Color(0xfffffbf6)])),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Lumo ✦\nLernen', style: TextStyle(fontSize: 30, height: .9, fontWeight: FontWeight.w900, color: Color(0xffff6d00))),
      const SizedBox(height: 32),
      for (var i = 0; i < items.length; i++) Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(backgroundColor: i == active ? const Color(0xffff8a2a) : Colors.white.withOpacity(.75), foregroundColor: i == active ? Colors.white : const Color(0xff655b54), minimumSize: const Size.fromHeight(52), alignment: Alignment.centerLeft),
          onPressed: items[i].tap,
          icon: Icon(items[i].icon),
          label: Text(items[i].label, overflow: TextOverflow.ellipsis),
        ),
      ),
      const Spacer(),
      const Card(child: ListTile(leading: CircleAvatar(child: Text('L')), title: Text('Lena'), subtitle: Text('Klasse 2'), trailing: Icon(Icons.chevron_right_rounded))),
    ]),
  );
}

class _Center extends StatelessWidget {
  const _Center(this.title, this.subtitle, this.body, this.onVoice);
  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback? onVoice;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(30, 28, 26, 26),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff766a61)))])), if (onVoice != null) IconButton.filledTonal(onPressed: onVoice, icon: const Icon(Icons.volume_up_rounded))]),
      const SizedBox(height: 22),
      AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(title), child: body)),
    ]),
  );
}

class _Right extends StatelessWidget {
  const _Right(this.lumo, this.stars, this.xp, this.level, this.progress, this.subtitle);
  final Widget lumo;
  final int stars;
  final int xp;
  final int level;
  final int progress;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: 350,
    padding: const EdgeInsets.fromLTRB(0, 16, 22, 16),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xffffd190), Color(0xffffe2af), Color(0xffffedcf)]), borderRadius: BorderRadius.circular(38)),
      child: Column(children: [Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)))), Expanded(child: Center(child: lumo)), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Lernstand', style: TextStyle(fontWeight: FontWeight.w900)), Text('Sterne $stars   XP $xp   Level $level'), LinearProgressIndicator(value: (progress / 100).clamp(0, 1))])))]),
    ),
  );
}
