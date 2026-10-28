import 'package:flutter/material.dart';

/// Shared local base-ten material. Interactive pieces have 48dp touch targets;
/// rods always contain ten visibly separated cubes, independent of text scale.
class LumoPlaceValueBlocks extends StatelessWidget {
  const LumoPlaceValueBlocks({super.key, required this.tens, required this.ones,
    this.selectedTens = const {}, this.selectedOnes = const {},
    this.onTenTap, this.onOneTap, this.oneKeyPrefix = 'lumo-one-block',
    this.reduceMotion = false});
  final int tens;
  final int ones;
  final Set<int> selectedTens;
  final Set<int> selectedOnes;
  final ValueChanged<int>? onTenTap;
  final ValueChanged<int>? onOneTap;
  final String oneKeyPrefix;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(spacing: 9, runSpacing: 9, children: [
        for (var i = 0; i < tens; i++)
          _piece(key: ValueKey('lumo-tens-block-$i'), label: 'Zehnerstange ${i + 1}',
            selected: selectedTens.contains(i), onTap: onTenTap == null ? null : () => onTenTap!(i),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var row = 0; row < 5; row++)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var col = 0; col < 2; col++) _cube(const Color(0xFFB9F2FF), 12),
                ]),
              if (selectedTens.contains(i)) const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            ])),
      ]),
      const SizedBox(height: 12),
      const Text('Einzelne Würfel', style: TextStyle(color: Color(0xFFDDF5FF), fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < ones; i++)
          if (onOneTap == null)
            SizedBox(key: ValueKey('$oneKeyPrefix-$i'), width: 24, height: 24,
              child: _cube(const Color(0xFFFFB65E), 21))
          else
            _piece(key: ValueKey('$oneKeyPrefix-$i'), label: 'Einzelwürfel ${i + 1}',
              selected: selectedOnes.contains(i), onTap: () => onOneTap!(i),
              child: _cube(const Color(0xFFFFB65E), 21)),
        if (ones == 0) const Text('Keine einzelnen Würfel übrig', style: TextStyle(color: Color(0xFFFFE5B4))),
      ]),
    ]);

  Widget _cube(Color color, double size) => Container(width: size, height: size,
    margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: color,
      border: Border.all(color: Colors.white38), borderRadius: BorderRadius.circular(3),
      boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 2)]));

  Widget _piece({required Key key, required String label, required bool selected,
      required VoidCallback? onTap, required Widget child}) => Semantics(
    label: label, selected: selected, button: onTap != null,
    child: Material(color: Colors.transparent, child: InkWell(key: key, onTap: onTap,
      borderRadius: BorderRadius.circular(12), child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 57, minHeight: 64),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: selected ? const Color(0xFF14749F) : const Color(0xFF0F3C65),
          border: Border.all(color: selected ? const Color(0xFFB7F7FF) : const Color(0xFF39C6EE), width: 2),
          borderRadius: BorderRadius.circular(12)), child: Center(widthFactor: 1, heightFactor: 1, child: child)))));
}
