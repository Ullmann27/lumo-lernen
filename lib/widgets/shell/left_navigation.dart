import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';
import '../navigation/nav_item_tile.dart';

class LeftNavigation extends StatelessWidget {
  const LeftNavigation({super.key, required this.items, required this.activeIndex, this.childName = 'Lena', this.gradeLabel = 'Klasse 2'});

  final List<NavItemData> items;
  final int activeIndex;
  final String childName;
  final String gradeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.fromLTRB(24, 28, 18, 22),
      decoration: const BoxDecoration(gradient: LumoGradients.sidebar),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(text: const TextSpan(children: [
          TextSpan(text: 'Lumo', style: LumoTextStyles.logoLumo),
          TextSpan(text: ' ✦\n', style: TextStyle(fontSize: 17, height: .9, fontWeight: FontWeight.w900, color: LumoColors.softGold)),
          TextSpan(text: 'Lernen', style: LumoTextStyles.logoLernen),
        ])),
        const SizedBox(height: 34),
        for (var i = 0; i < items.length; i++) NavItemTile(item: items[i], selected: i == activeIndex),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: LumoSurfaces.softCard(color: Colors.white.withOpacity(.88), radius: LumoRadius.kpi, shadowColor: LumoColors.apricot),
          child: Row(children: [
            const CircleAvatar(radius: 18, backgroundColor: Color(0xffffdfb8), child: Text('🦊', style: TextStyle(fontSize: 18))),
            const SizedBox(width: 10),
            Expanded(child: Text('$childName\n$gradeLabel', style: const TextStyle(fontSize: 13, height: 1.08, fontWeight: FontWeight.w900, color: LumoColors.warmText))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xff8c7b70)),
          ]),
        ),
      ]),
    );
  }
}
