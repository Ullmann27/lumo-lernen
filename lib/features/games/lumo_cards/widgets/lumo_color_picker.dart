// ════════════════════════════════════════════════════════════════════════
// LUMO COLOR PICKER — Farbwahl nach Farbzauber-Karte
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';

class LumoColorPicker extends StatelessWidget {
  const LumoColorPicker({super.key, required this.onPick});
  final void Function(LumoCardColor) onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌈', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'Waehle eine Farbe',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  for (final c in LumoCardColor.values)
                    _colorButton(c),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorButton(LumoCardColor c) {
    final colors = _gradientOf(c);
    return GestureDetector(
      onTap: () => onPick(c),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: colors[1].withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          _labelOf(c),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static List<Color> _gradientOf(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return const [Color(0xFFFFB96B), Color(0xFFFF7A2F)];
      case LumoCardColor.purple:
        return const [Color(0xFFC4B5FD), Color(0xFF7C3AED)];
      case LumoCardColor.blue:
        return const [Color(0xFF93C5FD), Color(0xFF2563EB)];
      case LumoCardColor.green:
        return const [Color(0xFF86EFAC), Color(0xFF059669)];
    }
  }

  static String _labelOf(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return 'Orange';
      case LumoCardColor.purple:
        return 'Lila';
      case LumoCardColor.blue:
        return 'Blau';
      case LumoCardColor.green:
        return 'Gruen';
    }
  }
}
