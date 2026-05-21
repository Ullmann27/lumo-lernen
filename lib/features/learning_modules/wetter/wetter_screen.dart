// ════════════════════════════════════════════════════════════════════════
// WETTER — Klasse 2 Sachkunde (mit Live-Bildern)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welches Wetter siehst du?' (Bild -> Wetter)
//   - 'Was zieht man bei X an?' (Wetter -> Kleidung)
//   - 'Welches Wetter passt zu diesem Satz?' (Hinweis -> Wetter)
// 10 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_companion_state.dart';
import '../../../core/lumo_cosmos.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class _Wetter {
  const _Wetter({
    required this.name,
    required this.icon,
    required this.color,
    required this.imagePrompt,
    required this.kleidung,
  });
  final String name;
  final String icon;
  final Color color;
  final String imagePrompt;
  final String kleidung;
}

enum _WetterFrageTyp { bildErraten, kleidungWaehlen, hinweisErraten }

class WetterScreen extends StatefulWidget {
  const WetterScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<WetterScreen> createState() => _WetterScreenState();
}

class _WetterScreenState extends State<WetterScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFF06B6D4),
    Color(0xFF0284C7),
  ];

  static const List<_Wetter> _wetterArten = [
    _Wetter(
      name: 'Sonne',
      icon: '☀️',
      color: Color(0xFFFCD34D),
      imagePrompt: 'wetter',
      kleidung: 'Sonnenhut und T-Shirt',
    ),
    _Wetter(
      name: 'Regen',
      icon: '🌧',
      color: Color(0xFF3B82F6),
      imagePrompt: 'regen',
      kleidung: 'Regenjacke und Gummistiefel',
    ),
    _Wetter(
      name: 'Wolken',
      icon: '☁️',
      color: Color(0xFF94A3B8),
      imagePrompt: 'wolke',
      kleidung: 'Pullover',
    ),
    _Wetter(
      name: 'Schnee',
      icon: '❄️',
      color: Color(0xFF60A5FA),
      imagePrompt: 'schnee',
      kleidung: 'Winterjacke und Mütze',
    ),
    _Wetter(
      name: 'Gewitter',
      icon: '⛈',
      color: Color(0xFF7C3AED),
      imagePrompt: 'gewitter',
      kleidung: 'drinnen bleiben',
    ),
    _Wetter(
      name: 'Nebel',
      icon: '🌫',
      color: Color(0xFFA1A1AA),
      imagePrompt: 'nebel',
      kleidung: 'helle Kleidung',
    ),
  ];

  static const List<MapEntry<String, String>> _hinweise = [
    MapEntry('Es ist heiß und hell draußen', 'Sonne'),
    MapEntry('Tropfen fallen vom Himmel', 'Regen'),
    MapEntry('Der Himmel ist grau', 'Wolken'),
    MapEntry('Alles ist weiß und kalt', 'Schnee'),
    MapEntry('Es blitzt und donnert', 'Gewitter'),
    MapEntry('Man sieht nicht weit', 'Nebel'),
    MapEntry('Ein Schneemann steht im Garten', 'Schnee'),
    MapEntry('Die Sonne scheint stark', 'Sonne'),
    MapEntry('Man braucht einen Regenschirm', 'Regen'),
    MapEntry('Es ist laut wegen dem Donner', 'Gewitter'),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _WetterFrageTyp _typ;
  late _Wetter _correctWetter;
  late MapEntry<String, String> _aktuellerHinweis;
  late List<_Wetter> _options;

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

  // Heinz CLAUDE.md Punkt 5: Anti-Repeat. Bei 30 Aufgaben aus 6
  // Wetterarten nie 2x dasselbe Wetter hintereinander.
  _Wetter? _lastWetter;

  void _generateTask() {
    _typ = _WetterFrageTyp.values[_rng.nextInt(3)];
    if (_typ == _WetterFrageTyp.hinweisErraten) {
      _aktuellerHinweis = _hinweise[_rng.nextInt(_hinweise.length)];
      _correctWetter =
          _wetterArten.firstWhere((w) => w.name == _aktuellerHinweis.value);
    } else {
      _Wetter pick;
      int safety = 8;
      do {
        pick = _wetterArten[_rng.nextInt(_wetterArten.length)];
      } while (pick == _lastWetter && --safety > 0);
      _correctWetter = pick;
    }
    _lastWetter = _correctWetter;
    final shuffled = List.of(_wetterArten)..shuffle(_rng);
    _options = [_correctWetter, ...shuffled.where((w) => w != _correctWetter).take(3)]
      ..shuffle(_rng);
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    switch (_typ) {
      case _WetterFrageTyp.bildErraten:
        text = 'Welches Wetter siehst du?';
        break;
      case _WetterFrageTyp.kleidungWaehlen:
        text = 'Was zieht man bei ${_correctWetter.name} an?';
        break;
      case _WetterFrageTyp.hinweisErraten:
        text = 'Welches Wetter passt: ${_aktuellerHinweis.key}?';
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
        subjectId: 's1_wetter',
        isMath: false,
        isPerfect: false,
      );
      LumoCompanionState.instance.recordCorrect(topic: 'sachk');
      try {
        LumoVoice.instance
            .speak('Richtig! Das ist ${_correctWetter.name}!');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(
            'Schau nochmal - das ist ${_correctWetter.name}!');
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
        title: const Text('🌤 Wetter-Quiz fertig!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks richtig!',
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
                  _buildVisualization(),
                  const SizedBox(height: 24),
                  _buildOptions(),
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
          child: Column(children: [
            Text('Aufgabe ${_taskIdx + 1} / $_totalTasks',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const Text('Wetter lernen',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ]),
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
      case _WetterFrageTyp.bildErraten:
        text = 'Welches Wetter ist das?';
        break;
      case _WetterFrageTyp.kleidungWaehlen:
        text = 'Was zieht man bei ${_correctWetter.name} an?';
        break;
      case _WetterFrageTyp.hinweisErraten:
        text = 'Welches Wetter passt?';
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

  Widget _buildVisualization() {
    switch (_typ) {
      case _WetterFrageTyp.bildErraten:
        // Pollinations raus (kam im Cloud-Setup nie zuverlaessig durch).
        // Stattdessen: grosser Wetter-Emoji auf himmelartigem RadialGradient,
        // pro Wetter eigene Stimmung.
        return _WetterBubble(
          icon: _correctWetter.icon,
          colors: _himmelGradient(_correctWetter.name),
          size: 220,
          bouncing: true,
          bounceCtrl: _bounceCtrl,
        );
      case _WetterFrageTyp.kleidungWaehlen:
        return _WetterBubble(
          icon: _correctWetter.icon,
          colors: _himmelGradient(_correctWetter.name),
          size: 180,
          bouncing: false,
          bounceCtrl: _bounceCtrl,
        );
      case _WetterFrageTyp.hinweisErraten:
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _gradient[0].withOpacity(0.4), width: 3),
          ),
          child: Text('"${_aktuellerHinweis.key}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _gradient[1])),
        );
    }
  }

  Widget _buildOptions() {
    if (_typ == _WetterFrageTyp.kleidungWaehlen) {
      // 4 Kleidungs-Optionen
      final richtigeKleidung = _correctWetter.kleidung;
      final allOptions = _wetterArten.map((w) => w.kleidung).toSet().toList();
      final wrong = allOptions.where((k) => k != richtigeKleidung).toList()
        ..shuffle(_rng);
      final options = [richtigeKleidung, ...wrong.take(3)]..shuffle(_rng);
      return Column(
        children: List.generate(options.length, (idx) {
          final opt = options[idx];
          final isCorrect = opt == richtigeKleidung;
          final isSelected = _selectedIdx == idx;
          Color bgColor = Colors.white;
          Color borderColor = _gradient[0].withOpacity(0.3);
          Color textColor = _gradient[1];
          if (_answered && isSelected) {
            bgColor = isCorrect
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFFEE2E2);
            textColor = isCorrect
                ? const Color(0xFF065F46)
                : const Color(0xFF991B1B);
            borderColor = isCorrect
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444);
          } else if (_answered && isCorrect) {
            bgColor = const Color(0xFFFEF3C7);
            borderColor = const Color(0xFFFCD34D);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: _answered ? null : () => _onAnswer(idx, isCorrect),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 3),
                ),
                child: Text(opt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
              ),
            ),
          );
        }),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: _options.asMap().entries.map((entry) {
        final idx = entry.key;
        final w = entry.value;
        final isCorrect = w == _correctWetter;
        final isSelected = _selectedIdx == idx;
        Color bgColor = Colors.white;
        Color borderColor = w.color.withOpacity(0.5);
        Color textColor = _gradient[1];
        if (_answered && isSelected) {
          if (isCorrect) {
            bgColor = const Color(0xFFD1FAE5);
            textColor = const Color(0xFF065F46);
            borderColor = const Color(0xFF10B981);
          } else {
            bgColor = const Color(0xFFFEE2E2);
            textColor = const Color(0xFF991B1B);
            borderColor = const Color(0xFFEF4444);
          }
        } else if (_answered && isCorrect) {
          bgColor = const Color(0xFFFEF3C7);
          borderColor = const Color(0xFFFCD34D);
        }
        return AnimatedBuilder(
          animation: _bounceCtrl,
          builder: (_, child) {
            final scale = isSelected && isCorrect
                ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.08
                : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: GestureDetector(
            onTap: _answered ? null : () => _onAnswer(idx, isCorrect),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 3),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(w.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(w.name,
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textColor)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Stimmungs-Gradient pro Wetterlage (oben=Himmel, unten=Boden/Tieferes).
  List<Color> _himmelGradient(String name) {
    switch (name) {
      case 'Sonne':
        return const [Color(0xFFFFF6B7), Color(0xFFFFC04D)];
      case 'Regen':
        return const [Color(0xFFCBD9E8), Color(0xFF4A7A9A)];
      case 'Wolken':
        return const [Color(0xFFE5EBF0), Color(0xFF9AA7B5)];
      case 'Schnee':
        return const [Color(0xFFEAF4FF), Color(0xFFA7C8E8)];
      case 'Gewitter':
        return const [Color(0xFF6E5B85), Color(0xFF2C2347)];
      case 'Nebel':
      default:
        return const [Color(0xFFE8EAEC), Color(0xFFB8BCBF)];
    }
  }
}

/// Visualisierung fuer Wetter: grosser Icon-Emoji auf passendem
/// RadialGradient, mit optionaler Atem-Animation.
class _WetterBubble extends StatelessWidget {
  const _WetterBubble({
    required this.icon,
    required this.colors,
    required this.size,
    required this.bouncing,
    required this.bounceCtrl,
  });
  final String icon;
  final List<Color> colors;
  final double size;
  final bool bouncing;
  final AnimationController bounceCtrl;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [colors[0], colors[1]],
          radius: 0.9,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(icon,
          style: TextStyle(fontSize: size * 0.55, height: 1.0)),
    );
    if (!bouncing) return card;
    return AnimatedBuilder(
      animation: bounceCtrl,
      builder: (_, child) {
        final s = 1.0 + math.sin(bounceCtrl.value * math.pi * 2) * 0.02;
        return Transform.scale(scale: s, child: child);
      },
      child: card,
    );
  }
}
