// ════════════════════════════════════════════════════════════════════════
// TIERE LERNEN — Klasse 1 Sachkunde (Tier-Quiz mit echten Bildern)
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: Module mit Bildgenerator-Integration. Hier kommen die
// Bilder live aus Pollinations.ai (sichere Allowlist, Comic-Stil).
//
// Aufgabentypen:
//   - 'Welches Tier macht XYZ?' (Tierlaut -> Bild)
//   - 'Welches Tier ist das?' (Bild -> Name)
//   - 'Wo lebt dieses Tier?' (Bild -> Lebensraum)
//
// 10 Aufgaben pro Session, 4 Multiple-Choice (Bilder oder Texte).
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_image_generator.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

enum _TierFrageTyp { bildZeigen, lautRaten, lebensraum }

class _Tier {
  const _Tier({
    required this.name,
    required this.laut,
    required this.lebensraum,
    required this.emoji,
  });
  final String name;
  final String laut;
  final String lebensraum;
  /// Sichtbares Emoji als Fallback wenn Pollinations-Bild nicht laedt.
  /// Heinz' Wunsch: keine generischen Pfoten mehr, sondern echte Tier-Emojis.
  final String emoji;
}

class TiereScreen extends StatefulWidget {
  const TiereScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<TiereScreen> createState() => _TiereScreenState();
}

class _TiereScreenState extends State<TiereScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  // 12 Tiere fuer Quiz - alle in der Allowlist - mit echten Tier-Emojis
  static const List<_Tier> _tiere = [
    _Tier(name: 'Kuh', laut: 'Muh', lebensraum: 'Bauernhof', emoji: '🐄'),
    _Tier(name: 'Hund', laut: 'Wau Wau', lebensraum: 'Zuhause', emoji: '🐶'),
    _Tier(name: 'Katze', laut: 'Miau', lebensraum: 'Zuhause', emoji: '🐱'),
    _Tier(name: 'Schaf', laut: 'Mäh', lebensraum: 'Bauernhof', emoji: '🐑'),
    _Tier(name: 'Pferd', laut: 'Wieher', lebensraum: 'Bauernhof', emoji: '🐴'),
    _Tier(name: 'Huhn', laut: 'Gack Gack', lebensraum: 'Bauernhof', emoji: '🐔'),
    _Tier(name: 'Ente', laut: 'Quak', lebensraum: 'See', emoji: '🦆'),
    _Tier(name: 'Frosch', laut: 'Quak Quak', lebensraum: 'See', emoji: '🐸'),
    _Tier(name: 'Löwe', laut: 'Brüll', lebensraum: 'Zoo', emoji: '🦁'),
    _Tier(name: 'Elefant', laut: 'Tröt', lebensraum: 'Zoo', emoji: '🐘'),
    _Tier(name: 'Pinguin', laut: 'Watschel', lebensraum: 'Zoo', emoji: '🐧'),
    _Tier(name: 'Affe', laut: 'Uh Uh', lebensraum: 'Zoo', emoji: '🐵'),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  String? _selectedAnswer;

  late _TierFrageTyp _typ;
  late _Tier _correctTier;
  late List<_Tier> _answerOptions;

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
    _typ = _TierFrageTyp.values[_rng.nextInt(_TierFrageTyp.values.length)];
    final shuffled = List.of(_tiere)..shuffle(_rng);
    _correctTier = shuffled.first;
    // 3 falsche Antworten + 1 richtige
    final wrong = shuffled.skip(1).take(3).toList();
    _answerOptions = [_correctTier, ...wrong]..shuffle(_rng);
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    switch (_typ) {
      case _TierFrageTyp.bildZeigen:
        text = 'Welches Tier ist das?';
        break;
      case _TierFrageTyp.lautRaten:
        text = 'Welches Tier macht "${_correctTier.laut}"?';
        break;
      case _TierFrageTyp.lebensraum:
        text = 'Wo lebt ein ${_correctTier.name}?';
        break;
    }
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _onAnswer(String answer) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final correctAnswer = _typ == _TierFrageTyp.lebensraum
        ? _correctTier.lebensraum
        : _correctTier.name;
    final isCorrect = answer == correctAnswer;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(7);
      try {
        LumoVoice.instance
            .speak('Richtig! Das ist ein ${_correctTier.name}!');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(
            'Schau nochmal - das ist ein ${_correctTier.name}!');
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
        title: const Text('🎉 Tier-Quiz fertig!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Tiere erkannt!',
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
                  _buildMainImage(),
                  const SizedBox(height: 20),
                  _buildAnswerOptions(),
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
              const Text('Tiere lernen',
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
      case _TierFrageTyp.bildZeigen:
        text = 'Welches Tier ist das?';
        break;
      case _TierFrageTyp.lautRaten:
        text = 'Welches Tier macht "${_correctTier.laut}"?';
        break;
      case _TierFrageTyp.lebensraum:
        text = 'Wo lebt ein ${_correctTier.name}?';
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

  /// Zeigt das Tier-Bild via Pollinations.ai - das Highlight des Moduls!
  /// Beim bildZeigen-Typ ist das die Hauptfrage.
  /// Beim lautRaten/lebensraum-Typ als Hilfe darunter.
  Widget _buildMainImage() {
    final url = LumoImageGenerator.instance.buildSafeImageUrl(_correctTier.name);
    if (url == null) {
      // Wenn kein Bild generiert werden kann: zeige Tier-Emoji gross.
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: _gradient[0].withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(_correctTier.emoji,
            style: const TextStyle(fontSize: 120)),
      );
    }
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: _gradient[0].withOpacity(0.1),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: _gradient[0], strokeWidth: 3),
                    const SizedBox(height: 8),
                    Text('Bild wird gemalt...',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _gradient[1])),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (ctx, err, st) => Container(
            color: _gradient[0].withOpacity(0.15),
            alignment: Alignment.center,
            // Heinz: keine generischen Pfoten - echtes Tier-Emoji.
            child: Text(_correctTier.emoji,
                style: const TextStyle(fontSize: 100)),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    final options = _typ == _TierFrageTyp.lebensraum
        ? _buildLebensraumOptions()
        : _answerOptions.map((t) => t.name).toList();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: options.map((opt) => _buildAnswerButton(opt)).toList(),
    );
  }

  List<String> _buildLebensraumOptions() {
    final all = ['Bauernhof', 'Zoo', 'See', 'Zuhause'];
    return all;
  }

  Widget _buildAnswerButton(String text) {
    final correctAnswer = _typ == _TierFrageTyp.lebensraum
        ? _correctTier.lebensraum
        : _correctTier.name;
    final isSelected = _selectedAnswer == text;
    final isCorrect = text == correctAnswer;
    Color bgColor = Colors.white;
    Color textColor = _gradient[1];
    Color borderColor = _gradient[0].withOpacity(0.3);
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
        onTap: _answered ? null : () => _onAnswer(text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 3),
          ),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
          ),
        ),
      ),
    );
  }
}
