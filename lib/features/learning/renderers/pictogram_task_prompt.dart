import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';

/// Renders the existing, checked picture-diagram prompts without an emoji font.
class PictogramTaskPrompt extends StatelessWidget {
  const PictogramTaskPrompt({super.key, required this.prompt});

  final String prompt;
  static const String _symbol = '🟦';
  static final RegExp _legend = RegExp('Ein $_symbol (?:ist|sind)');
  static final RegExp _row = RegExp('^([^:]+): ((?:$_symbol)+|0 \\(.*\\))\$');

  static bool supports(String prompt) {
    if (!prompt.startsWith('Lies das Diagramm. ')) return false;
    final lines = prompt.split('\n');
    return lines.length >= 4 &&
        _legend.hasMatch(lines.first) &&
        lines.getRange(1, lines.length - 1).every(_row.hasMatch);
  }

  @override
  Widget build(BuildContext context) {
    final lines = prompt.split('\n');
    final rows = lines.getRange(1, lines.length - 1).map((line) {
      final match = _row.firstMatch(line)!;
      final value = match[2]!;
      return (
        name: match[1]!,
        value: value,
        count: _symbol.allMatches(value).length
      );
    }).toList();
    final longest = rows.fold(
      1,
      (width, row) => math.max(width, row.count),
    );
    const tileSize = 17.0;
    const gap = 3.0;
    final fullWidth = longest * tileSize + (longest - 1) * gap;
    const label = TextStyle(
      color: LumoVisualTokens.white,
      fontFamily: 'Nunito',
      fontSize: 15,
      fontWeight: FontWeight.w800,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lines.first.replaceFirst(_legend, 'Ein blaues Kästchen zählt als'),
          style: label,
        ),
        const SizedBox(height: 12),
        for (final row in rows) ...[
          Text(row.name, style: label),
          const SizedBox(height: 4),
          if (row.count > 0)
            Semantics(
              label: _spokenCount(row.count),
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                // Every row has the same reference width, so a long row
                // cannot end up with smaller marks than a short one.
                child: SizedBox(
                  width: fullWidth,
                  child: Row(
                    children: [
                      for (var tile = 0; tile < row.count; tile++) ...[
                        if (tile > 0) const SizedBox(width: gap),
                        const SizedBox.square(
                          dimension: tileSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xff60bafa),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(3)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            Text(row.value, style: label),
          const SizedBox(height: 10),
        ],
        Text(
          lines.last,
          style: label.copyWith(fontSize: 19, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  static String _spokenCount(int count) =>
      count == 1 ? 'Ein blaues Kästchen' : '$count blaue Kästchen';
}
