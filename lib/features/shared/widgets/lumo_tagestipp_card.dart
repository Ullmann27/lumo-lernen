// ════════════════════════════════════════════════════════════════════════
// LUMO TAGESTIPP — taeglich wechselnder Tipp von Lumo auf dem Home-Screen
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 30: Heinz' Wunsch nach 'visuelle starke Verbesserungen,
// mehr Professionalitaet'. Ein kleiner Tagestipp im Home macht den Screen
// persoenlicher: jeden Tag eine neue Mini-Lektion oder Motivation, statt
// nur statischer Tiles. Inspiriert von Mildenberger-Heften wo jeden Tag
// ein kleiner Spruch oder Tipp im Buch steht.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class LumoTagestippCard extends StatelessWidget {
  const LumoTagestippCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tip = _pickTipForToday();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tip.color.withOpacity(0.10),
                tip.color.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            // 2026-06-06 FIX: non-uniform Border + borderRadius rendert nicht.
            border: Border.all(color: tip.color.withOpacity(0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: tip.color.withOpacity(0.14),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2026-06-06: echter Lumo-Charakter (errorBuilder -> Emoji-Fallback)
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: tip.color, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: tip.color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/companion/lumo_idle.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🦊', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: tip.color,
                            borderRadius: BorderRadius.circular(LumoRadius.pill),
                            boxShadow: [
                              BoxShadow(
                                color: tip.color.withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            tip.label,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tip.text,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: LumoColors.ink900,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Tip _pickTipForToday() {
    // Bewusst zyklisch: dayOfYear % tipCount damit der gleiche Kalendertag
    // immer denselben Tipp zeigt, aber die Reihenfolge nicht vorhersehbar
    // ist (Tipps sind nicht 1:1 zum Wochentag verknuepft).
    final now = DateTime.now();
    final dayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays;
    return _tips[dayOfYear % _tips.length];
  }
}

class _Tip {
  const _Tip(this.label, this.color, this.text);
  final String label;
  final Color color;
  final String text;
}

// Mildenberger-inspirierte Tipps + motivierende Mini-Lektionen.
// Pro Tipp eine Mentor-Farbe wenn moeglich.
const List<_Tip> _tips = <_Tip>[
  // Emma: Tauschen
  _Tip(
    'EMMAS TIPP',
    Color(0xFFEC4899),
    'Bei 2 + 7 kannst du die Zahlen tauschen: 7 + 2 = 9. Das geht schneller!',
  ),
  // Mira: Zehneruebergang
  _Tip(
    'MIRAS TIPP',
    Color(0xFFA855F7),
    'Bei 8 + 6: erst bis zur 10 (8+2=10), dann den Rest dazu (10+4=14).',
  ),
  // Max: Nachbar
  _Tip(
    'MAX RAET',
    Color(0xFF60A5FA),
    '5 + 4? Du kennst sicher 4 + 4 = 8. Dann nur +1 → 9.',
  ),
  // Hanna: Umkehr
  _Tip(
    'HANNAS TRICK',
    Color(0xFFF59E0B),
    'Nach 9 - 4 = 5 schnell pruefen: 5 + 4 = 9. Stimmt!',
  ),
  // Tim: Aufgabe zerlegen
  _Tip(
    'TIMS METHODE',
    Color(0xFF22C55E),
    '12 + 4? Erst 2 + 4 = 6, dann den Zehner dazu: 10 + 6 = 16.',
  ),
  // Lese-Tipp
  _Tip(
    'LESE-TIPP',
    Color(0xFF6366F1),
    'Sprich jeden Buchstaben langsam. Auch Silben helfen dir lange Woerter zu lesen.',
  ),
  // Schreib-Tipp
  _Tip(
    'SCHREIB-TIPP',
    Color(0xFF06B6D4),
    'Namenswoerter (Tisch, Hund, Mama) schreibst du immer GROSS.',
  ),
  // Sachkunde
  _Tip(
    'SACHKUNDE',
    Color(0xFF059669),
    'Ein Frosch fuehlt sich kalt an. Er ist ein Wechselwarmer Tier.',
  ),
  // Lerntipp
  _Tip(
    'LERN-TIPP',
    Color(0xFFFB923C),
    'Mache lieber 10 Minuten konzentriert als 30 Minuten halb. Pausen helfen!',
  ),
  // Motivation
  _Tip(
    'MOTIVATION',
    Color(0xFFEAB308),
    'Jeder Fehler ist eine Chance zu lernen. Sei stolz auf dich!',
  ),
  // Geometrie
  _Tip(
    'GEOMETRIE',
    Color(0xFFEA580C),
    'Ein Quadrat hat 4 gleich lange Seiten. Ein Rechteck hat 4 Ecken aber unterschiedliche Seiten.',
  ),
  // Bruechte
  _Tip(
    'BRUECHE',
    Color(0xFFDB2777),
    '1/2 ist die Haelfte. 1/4 ist ein Viertel. Schau dir Pizza-Stuecke vor!',
  ),
  // Times-Tabelle
  _Tip(
    'EINMALEINS',
    Color(0xFF8B5CF6),
    'Mal-Reihen werden leichter wenn du sie tauschst: 7 × 3 = 3 × 7.',
  ),
  // Uhr
  _Tip(
    'UHRZEIT',
    Color(0xFF0EA5E9),
    'Die kleine Zeiger zeigt die Stunde, die grosse die Minute.',
  ),
];
