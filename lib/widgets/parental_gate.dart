import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Erwachsenen-Schranke ("Parental Gate").
///
/// **Pflicht für Google Play "Designed for Families":**
/// Vor dem Zugang zu Bereichen, die nicht für Kinder gedacht sind
/// (Einstellungen, externe Links, Datenschutzerklärung, Käufe), muss
/// eine Gate vorgelagert sein, die ein typisches kleines Kind nicht
/// einfach lösen kann.
///
/// Diese Implementierung verlangt die Eingabe einer schriftlich
/// formulierten Multiplikations-Aufgabe (z. B. "Achtundzwanzig").
/// Das ist konform zu Googles Vorgaben, da sowohl Lesen mehrstelliger
/// Zahlwörter als auch zweistellige Multiplikation für jüngere
/// Kinder ungeeignet sind.
///
/// Verwendung:
/// ```
/// final ok = await ParentalGate.show(context);
/// if (ok) ...; // Zugriff freigegeben
/// ```
class ParentalGate extends StatefulWidget {
  const ParentalGate({super.key});

  /// Zeigt die Gate als modalen Dialog. Liefert `true` bei Erfolg.
  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.all(20),
        child: ParentalGate(),
      ),
    );
    return ok ?? false;
  }

  @override
  State<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  final _controller = TextEditingController();
  late int _a;
  late int _b;
  int _attempts = 0;
  String? _error;

  static const _wordNumbers = <int, String>{
    20: 'zwanzig', 21: 'einundzwanzig', 22: 'zweiundzwanzig',
    23: 'dreiundzwanzig', 24: 'vierundzwanzig', 25: 'fünfundzwanzig',
    26: 'sechsundzwanzig', 27: 'siebenundzwanzig', 28: 'achtundzwanzig',
    29: 'neunundzwanzig', 30: 'dreißig', 32: 'zweiunddreißig',
    35: 'fünfunddreißig', 36: 'sechsunddreißig', 40: 'vierzig',
    42: 'zweiundvierzig', 45: 'fünfundvierzig', 48: 'achtundvierzig',
    49: 'neunundvierzig', 50: 'fünfzig', 54: 'vierundfünfzig',
    56: 'sechsundfünfzig', 63: 'dreiundsechzig', 64: 'vierundsechzig',
    72: 'zweiundsiebzig', 81: 'einundachtzig', 84: 'vierundachtzig',
  };

  @override
  void initState() {
    super.initState();
    _newProblem();
  }

  void _newProblem() {
    final rng = math.Random();
    final candidates = _wordNumbers.keys.toList();
    int product;
    int a, b;
    do {
      product = candidates[rng.nextInt(candidates.length)];
      // Faktorisiere: nimm einen Teiler ≥ 4 wenn möglich
      final divisors = [
        for (int i = 4; i <= 9; i++) if (product % i == 0) i
      ];
      if (divisors.isEmpty) {
        a = product;
        b = 1;
      } else {
        b = divisors[rng.nextInt(divisors.length)];
        a = product ~/ b;
      }
    } while (a == 1 || b == 1);
    _a = a;
    _b = b;
  }

  void _check() {
    final input = _controller.text.trim().toLowerCase();
    final expected = _wordNumbers[_a * _b]!;
    final asNumber = int.tryParse(input);
    final correct =
        input == expected || asNumber == _a * _b;
    if (correct) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _attempts++;
        _error = _attempts >= 3
            ? 'Bitte einen Erwachsenen fragen.'
            : 'Hmm, das stimmt noch nicht. Probier es nochmal.';
        if (_attempts >= 3) {
          _newProblem();
          _controller.clear();
          _attempts = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffff7a2f), Color(0xffff9a5c)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffff7a2f).withValues(alpha: .3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bereich für Erwachsene',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff2d2621),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Text(
            'Bitte gib eine erwachsene Person das Gerät, '
            'um diese Frage zu beantworten:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xff6b6258),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xfffff4e3), Color(0xfffff8eb)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffffd5a8)),
            ),
            child: Center(
              child: Text(
                'Was ist  $_a × $_b ?',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff2d2621),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              hintText: 'Antwort als Wort oder Zahl',
              filled: true,
              fillColor: const Color(0xfff8f4ee),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              prefixIcon:
                  const Icon(Icons.edit_rounded, color: Color(0xff766a61)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xffd14655),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _check,
                child: const Text('Bestätigen'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
