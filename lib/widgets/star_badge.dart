import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarBadge extends StatelessWidget {
  final int stars;
  final int xp;
  const StarBadge({super.key, required this.stars, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.yellow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.yellow, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$stars • $xp XP',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
