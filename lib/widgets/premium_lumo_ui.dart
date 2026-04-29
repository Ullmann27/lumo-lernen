import 'package:flutter/material.dart';

class PremiumBackdrop extends StatelessWidget {
  const PremiumBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(top: -90, left: -80, child: _Orb(size: 240, color: const Color(0xffffc46b).withOpacity(.32))),
          Positioned(top: 90, right: -70, child: _Orb(size: 210, color: const Color(0xffa78bfa).withOpacity(.23))),
          Positioned(bottom: -120, left: 30, child: _Orb(size: 260, color: const Color(0xff5eead4).withOpacity(.22))),
          Positioned(bottom: 120, right: 40, child: _Orb(size: 120, color: const Color(0xffff8a65).withOpacity(.16))),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: <BoxShadow>[BoxShadow(color: color.withOpacity(.35), blurRadius: 44, spreadRadius: 10)],
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(22), this.radius = 34});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.78),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(.78)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.deepOrange.withOpacity(.10), blurRadius: 24, offset: const Offset(0, 14)),
          BoxShadow(color: Colors.purple.withOpacity(.05), blurRadius: 34, offset: const Offset(0, 18)),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class PremiumHeroBanner extends StatelessWidget {
  const PremiumHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.lumo,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget lumo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xffffd58a), Color(0xfffff0be), Color(0xffffe4d4)]),
        borderRadius: BorderRadius.circular(34),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.orange.withOpacity(.20), blurRadius: 28, offset: const Offset(0, 18))],
      ),
      child: Row(
        children: <Widget>[
          lumo,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: const TextStyle(fontSize: 26, height: 1.02, fontWeight: FontWeight.w900, color: Color(0xff321b0b))),
                const SizedBox(height: 8),
                Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xff5a3a1b))),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.play_arrow_rounded), label: Text(actionLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LearningWorldCard extends StatelessWidget {
  const LearningWorldCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 248,
        height: 188,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[color.withOpacity(.22), Colors.white.withOpacity(.75)]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(.20)),
          boxShadow: <BoxShadow>[BoxShadow(color: color.withOpacity(.14), blurRadius: 22, offset: const Offset(0, 14))],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(right: -8, top: -10, child: Icon(icon, size: 76, color: color.withOpacity(.18))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                CircleAvatar(backgroundColor: Colors.white, child: Icon(icon, color: color)),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(.16), borderRadius: BorderRadius.circular(99)),
                    child: Text(badge!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                  ),
                const SizedBox(height: 6),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, height: 1.05, fontWeight: FontWeight.w900, color: Color(0xff20143d))),
                const SizedBox(height: 5),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.1, color: Color(0xff5f5871))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumStatCard extends StatelessWidget {
  const PremiumStatCard({super.key, required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(.18)),
        boxShadow: <BoxShadow>[BoxShadow(color: color.withOpacity(.10), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff70677f))),
        ],
      ),
    );
  }
}
