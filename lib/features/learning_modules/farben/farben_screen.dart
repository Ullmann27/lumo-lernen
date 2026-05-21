// ════════════════════════════════════════════════════════════════════════
// FARBEN LERNEN — Klasse 1 Sachkunde (mit Live-Bildern)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welche Farbe hat dieses [Tier/Objekt]?' (Bild -> Farbe waehlen)
//   - 'Tippe das rote Tier!' (4 Bilder, eines mit der gefragten Farbe)
// 10 Aufgaben, gemischte Typen, Pollinations.ai liefert die Bilder.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import '../../../core/lumo_companion_state.dart';
import '../../../core/lumo_cosmos.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class _Farbe {
  const _Farbe({required this.name, required this.color, required this.prompt});
  final String name;
  final Color color;
  /// Was im Pollinations-Prompt steht (englisch fuer bessere Ergebnisse)
  final String prompt;
}

class _Objekt {
  const _Objekt({
    required this.name,
    required this.artikel,
    required this.emoji,
    required this.prompt,
  });
  final String name;
  final String artikel; // 'der', 'die', 'das'
  final String emoji;   // lokales Fallback-Symbol fuer offline / Image-Fail
  final String prompt;  // englisch fuer evtl. spaetere Bildquelle
}

enum _FarbFrageTyp { farbeZuObjekt, objektZuFarbe }

class FarbenScreen extends StatefulWidget {
  const FarbenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<FarbenScreen> createState() => _FarbenScreenState();
}

class _FarbenScreenState extends State<FarbenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
  ];

  static const List<_Farbe> _farben = [
    _Farbe(name: 'Rot', color: Color(0xFFEF4444), prompt: 'red'),
    _Farbe(name: 'Blau', color: Color(0xFF3B82F6), prompt: 'blue'),
    _Farbe(name: 'Gelb', color: Color(0xFFFCD34D), prompt: 'yellow'),
    _Farbe(name: 'Grün', color: Color(0xFF10B981), prompt: 'green'),
    _Farbe(name: 'Orange', color: Color(0xFFF97316), prompt: 'orange'),
    _Farbe(name: 'Rosa', color: Color(0xFFEC4899), prompt: 'pink'),
    _Farbe(name: 'Lila', color: Color(0xFF8B5CF6), prompt: 'purple'),
    _Farbe(name: 'Braun', color: Color(0xFFA16207), prompt: 'brown'),
  ];

  // Objekte die in einer bestimmten Farbe gerendert werden.
  // Jedes Objekt hat: Artikel (der/die/das) + Emoji-Symbol.
  // Heinz Screenshot 2026-05-21: 'das Vogel/Hut/Luftballon' war
  // grammatikalisch falsch und alle Bilder zeigten 🎨 (Pollinations
  // war nicht erreichbar). Lokale Emojis + korrekte Artikel.
  static const List<_Objekt> _objekte = [
    _Objekt(name: 'Apfel', artikel: 'der', emoji: '🍎', prompt: 'apple'),
    _Objekt(name: 'Ball', artikel: 'der', emoji: '⚽', prompt: 'ball'),
    _Objekt(name: 'Auto', artikel: 'das', emoji: '🚗', prompt: 'car'),
    _Objekt(name: 'Blume', artikel: 'die', emoji: '🌸', prompt: 'flower'),
    _Objekt(name: 'Vogel', artikel: 'der', emoji: '🐦', prompt: 'bird'),
    _Objekt(name: 'Fisch', artikel: 'der', emoji: '🐟', prompt: 'fish'),
    _Objekt(name: 'Hut', artikel: 'der', emoji: '🎩', prompt: 'hat'),
    _Objekt(name: 'Schmetterling',
        artikel: 'der', emoji: '🦋', prompt: 'butterfly'),
    _Objekt(name: 'Luftballon',
        artikel: 'der', emoji: '🎈', prompt: 'balloon'),
    _Objekt(name: 'Stern', artikel: 'der', emoji: '⭐', prompt: 'star'),
    _Objekt(name: 'Herz', artikel: 'das', emoji: '❤️', prompt: 'heart'),
    _Objekt(name: 'Drache', artikel: 'der', emoji: '🐉', prompt: 'dragon'),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _FarbFrageTyp _typ;
  late _Farbe _correctFarbe;
  late _Objekt _objekt;
  // Bei objektZuFarbe: 4 Bilder, eines hat die richtige Farbe
  late List<_Farbe> _bildFarben; // Welche Farbe jedes Bild hat
  late int _correctImageIdx;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _generateTask();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakTask());
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _generateTask() {
    _typ = _FarbFrageTyp.values[_rng.nextInt(_FarbFrageTyp.values.length)];
    _objekt = _objekte[_rng.nextInt(_objekte.length)];
    final shuffled = List.of(_farben)..shuffle(_rng);
    _correctFarbe = shuffled.first;
    if (_typ == _FarbFrageTyp.objektZuFarbe) {
      // 4 verschieden-farbige Bilder vom selben Objekt
      _bildFarben = shuffled.take(4).toList();
      // Korrekte Position der richtigen Farbe
      _correctImageIdx = _rng.nextInt(4);
      // Sicherstellen dass die richtige Farbe am richtigen Index ist
      _bildFarben[_correctImageIdx] = _correctFarbe;
    }
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    switch (_typ) {
      case _FarbFrageTyp.farbeZuObjekt:
        text = 'Welche Farbe hat ${_objekt.artikel} ${_objekt.name}?';
        break;
      case _FarbFrageTyp.objektZuFarbe:
        text = 'Tippe ${_correctFarbe.name.toLowerCase()}!';
        break;
    }
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _onAnswer(int idx, bool isCorrect) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIdx = idx;
      _answered = true;
    });
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(7);
      CosmosWorld.instance.grantReward(
        subjectId: 's1_farben',
        isMath: false,
        isPerfect: false,
      );
      LumoCompanionState.instance.recordCorrect(topic: 'sachk');
      try {
        LumoVoice.instance
            .speak('Richtig! Das ist ${_correctFarbe.name}!');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(
            'Schau nochmal - die richtige Farbe ist ${_correctFarbe.name}!');
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _nextTask();
  }

  void _nextTask() {
    if (_taskIdx + 1 >= _totalTasks) {
      _showFinish();
      return;
    }
    setState(() {
      _taskIdx++;
      _generateTask();
    });
    _entryCtrl.forward(from: 0);
    _speakTask();
  }

  void _showFinish() {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correctCount * 10);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎨 Farben-Quiz fertig!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Farben erkannt!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.star_rounded,
                    size: 38,
                    color: i < stars
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFD1D5DB)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(LumoPhrases.celebrate(),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Fertig',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: _gradient[0])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, child) {
                  return Opacity(opacity: _entryCtrl.value, child: child);
                },
                child: Column(children: [
                  _buildTaskHeader(),
                  const SizedBox(height: 20),
                  if (_typ == _FarbFrageTyp.farbeZuObjekt) ...[
                    _buildSingleImage(_correctFarbe),
                    const SizedBox(height: 20),
                    _buildColorOptions(),
                  ] else ...[
                    _buildImageGrid(),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _gradient),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Column(
            children: [
              Text('Aufgabe ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Farben lernen',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFFCD34D), size: 18),
            const SizedBox(width: 4),
            Text('$_correctCount',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _buildTaskHeader() {
    String text;
    switch (_typ) {
      case _FarbFrageTyp.farbeZuObjekt:
        text = 'Welche Farbe hat ${_objekt.artikel} ${_objekt.name}?';
        break;
      case _FarbFrageTyp.objektZuFarbe:
        text = 'Tippe ${_correctFarbe.name.toLowerCase()}!';
        break;
    }
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(
            offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _gradient[1])),
      ),
    );
  }

  Widget _buildSingleImage(_Farbe farbe) {
    // Heinz Screenshot 2026-05-21: Pollinations-Bilder kamen NIE durch,
    // Kind sah immer nur 🎨-Palette als Fallback. Jetzt verlaesslich:
    // farbiger Hintergrund + echtes Emoji des Objekts.
    return _EmojiBubble(
      emoji: _objekt.emoji,
      color: farbe.color,
      size: 220,
    );
  }

  Widget _buildImageGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.0,
      children: List.generate(4, (i) {
        final farbe = _bildFarben[i];
        final isCorrect = i == _correctImageIdx;
        final isSelected = _selectedIdx == i;
        return _ColoredEmojiOption(
          emoji: _objekt.emoji,
          color: farbe.color,
          isSelected: isSelected,
          isCorrect: isCorrect,
          answered: _answered,
          bounceCtrl: _bounceCtrl,
          onTap: () => _onAnswer(i, isCorrect),
        );
      }),
    );
  }

  Widget _buildColorOptions() {
    final options = (List.of(_farben)..shuffle(_rng)).take(4).toList();
    if (!options.contains(_correctFarbe)) {
      options[0] = _correctFarbe;
      options.shuffle(_rng);
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: options.map((f) {
        final isSelected = _selectedIdx == options.indexOf(f);
        final isCorrect = f == _correctFarbe;
        Color borderColor = _gradient[0].withOpacity(0.3);
        if (_answered && isSelected) {
          borderColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        } else if (_answered && isCorrect) {
          borderColor = const Color(0xFFFCD34D);
        }
        return GestureDetector(
          onTap: _answered ? null : () => _onAnswer(options.indexOf(f), isCorrect),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: f.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12, width: 1),
                  ),
                ),
                const SizedBox(width: 10),
                Text(f.name,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _gradient[1])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Grosse Anzeige eines farbigen Objekts: gefuellter Farb-Hintergrund
/// mit dem Objekt-Emoji als grosse Mitte. Verlaesslich offline, kein
/// Internet-Bild noetig.
class _EmojiBubble extends StatelessWidget {
  const _EmojiBubble({
    required this.emoji,
    required this.color,
    required this.size,
  });
  final String emoji;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, _shadeOf(color, .78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Eine etwas hellere/dunklere Variante der gleichen Farbe -
/// fuer den Gradient innerhalb einer 'Tippe Farbe!'-Box.
Color _shadeOf(Color base, double factor) {
  final hsl = HSLColor.fromColor(base);
  final l = (hsl.lightness * factor).clamp(0.0, 1.0);
  return hsl.withLightness(l).toColor();
}

/// 'Tippe rot!'-Modus: 4 farbige Felder mit dem gleichen Objekt-Emoji,
/// jedes Feld in EINER der 4 Antwort-Farben. Kind erkennt die Farbe
/// und tippt das richtige Feld. Heinz Screenshot 2026-05-21: vorher
/// wurden alle 4 Felder gleich gerendert weil Bilder-API failte. Jetzt
/// reine lokale Render-Logik mit garantiert unterschiedlichen Farben.
class _ColoredEmojiOption extends StatelessWidget {
  const _ColoredEmojiOption({
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.isCorrect,
    required this.answered,
    required this.bounceCtrl,
    required this.onTap,
  });
  final String emoji;
  final Color color;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final AnimationController bounceCtrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white;
    if (answered && isSelected) {
      borderColor = isCorrect
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444);
    } else if (answered && isCorrect) {
      borderColor = const Color(0xFFFCD34D);
    }
    return AnimatedBuilder(
      animation: bounceCtrl,
      builder: (_, child) {
        final scale = isSelected && isCorrect
            ? 1 + math.sin(bounceCtrl.value * math.pi) * 0.08
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: answered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, _shadeOf(color, .78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(emoji,
              style: const TextStyle(fontSize: 70, height: 1.0)),
        ),
      ),
    );
  }
}
