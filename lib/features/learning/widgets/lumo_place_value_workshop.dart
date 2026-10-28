import 'package:flutter/material.dart';

/// An offline, hands-on representation for two-digit tens-and-ones tasks.
///
/// The child taps each ten-block independently. The conclusion stays hidden
/// until the child has actually counted every block; this is a learning aid,
/// not a scored answer and never modifies progress or reward storage.
class LumoPlaceValueWorkshop extends StatefulWidget {
  const LumoPlaceValueWorkshop({
    super.key,
    required this.number,
    this.reduceMotion = false,
  }) : assert(number >= 10 && number <= 99);

  final int number;
  final bool reduceMotion;

  static int? numberForPrompt(String prompt) {
    final normalized = prompt.toLowerCase();
    if (!normalized.contains('zehner') && !normalized.contains('einer')) {
      return null;
    }
    final matches = RegExp(r'\b\d{2}\b').allMatches(normalized).toList();
    if (matches.length != 1) return null;
    final value = int.tryParse(matches.single.group(0)!);
    if (value == null || value < 10 || value > 99) return null;
    return value;
  }

  @override
  State<LumoPlaceValueWorkshop> createState() => _LumoPlaceValueWorkshopState();
}

class _LumoPlaceValueWorkshopState extends State<LumoPlaceValueWorkshop> {
  final Set<int> _counted = <int>{};

  @override
  void didUpdateWidget(covariant LumoPlaceValueWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) _counted.clear();
  }

  @override
  Widget build(BuildContext context) {
    final totalTens = widget.number ~/ 10;
    final ones = widget.number % 10;
    final complete = _counted.length == totalTens;
    final calm = widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    return Container(
      key: const ValueKey('lumo-place-value-workshop'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF00A3768), Color(0xF0071B3E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xB04EDCFF), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lumos Zehner-Werkstatt',
            style: TextStyle(
              color: Colors.white, fontSize: 19,
              fontFamily: 'Nunito', fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Wir bauen ${widget.number}. Tippe jede blaue Zehnerstange '
            'einmal an und zähle die vollen Zehner.',
            style: const TextStyle(
              color: Color(0xFFDEFAFF), fontSize: 14,
              fontFamily: 'Nunito', fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (var i = 0; i < totalTens; i++)
                Semantics(
                  label: 'Zehnerstange ${i + 1}',
                  selected: _counted.contains(i),
                  child: Tooltip(
                    message: 'Zehnerstange ${i + 1} zählen',
                    child: InkWell(
                      key: ValueKey('lumo-tens-block-$i'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        if (!_counted.add(i)) _counted.remove(i);
                      }),
                      child: AnimatedContainer(
                        duration: calm
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        constraints: const BoxConstraints(
                          minWidth: 57, minHeight: 64,
                        ),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _counted.contains(i)
                              ? const Color(0xFF14749F)
                              : const Color(0xFF0F3C65),
                          border: Border.all(
                            color: _counted.contains(i)
                                ? const Color(0xFFB7F7FF)
                                : const Color(0xFF39C6EE),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var row = 0; row < 5; row++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var col = 0; col < 2; col++)
                                      Container(
                                        width: 12, height: 6,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB9F2FF),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (_counted.contains(i))
                              const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Einzelne Würfel',
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13,
              color: Color(0xFFDDF5FF), fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < ones; i++)
                Container(
                  key: ValueKey('lumo-one-block-$i'),
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB65E),
                    border: Border.all(color: const Color(0xFFFFE5B4), width: 1.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              if (ones == 0)
                const Text(
                  'Keine einzelnen Würfel übrig',
                  style: TextStyle(color: Color(0xFFFFE5B4)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            complete
                ? 'Geschafft! Du hast ${_counted.length} volle Zehner '
                    'und $ones Einer gezählt.'
                : 'Du hast ${_counted.length} volle Zehner gezählt. '
                    'Zähle weiter – in jeder Stange stecken zehn.',
            key: const ValueKey('lumo-place-value-feedback'),
            style: const TextStyle(
              color: Color(0xFFFFFFFF), fontSize: 14,
              fontFamily: 'Nunito', fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (_counted.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('lumo-place-value-reset'),
              onPressed: () => setState(_counted.clear),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: const Color(0xFFE3F7FF),
                side: const BorderSide(color: Color(0xAA65DEFF)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text('Noch einmal zählen'),
            ),
          ],
        ],
      ),
    );
  }
}
