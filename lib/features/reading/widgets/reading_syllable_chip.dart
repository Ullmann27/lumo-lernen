import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class ReadingSyllableChip extends StatelessWidget {
  const ReadingSyllableChip({
    super.key,
    required this.parts,
    this.active = false,
    this.problem = false,
    this.listening = false,
  });

  final List<String> parts;
  final bool active;
  final bool problem;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final visible = parts.where((part) => part.trim().isNotEmpty).toList(growable: false);
    final accent = problem ? LumoColors.orange : listening ? LumoColors.teal : LumoColors.orange;
    final marked = active || problem;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: EdgeInsets.symmetric(horizontal: marked ? 10 : 0, vertical: marked ? 6 : 0),
      decoration: BoxDecoration(
        color: marked ? accent.withOpacity(.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        border: marked ? Border.all(color: accent.withOpacity(.55), width: 1.6) : null,
      ),
      child: RichText(
        text: TextSpan(
          children: visible.asMap().entries.map((entry) {
            return TextSpan(
              text: entry.value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: active ? 29 : 27,
                fontWeight: FontWeight.w900,
                color: problem
                    ? LumoColors.orange
                    : entry.key.isEven
                        ? LumoColors.blue
                        : LumoColors.practice,
                height: 1.18,
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}
