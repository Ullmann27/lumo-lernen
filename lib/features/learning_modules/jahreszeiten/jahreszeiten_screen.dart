// ════════════════════════════════════════════════════════════════════════
// JAHRESZEITEN — Klasse 2 Sachkunde (mit Live-Bildern)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welche Jahreszeit zeigt das Bild?' (Bild -> Jahreszeit)
//   - 'In welcher Jahreszeit passiert X?' (Aktivitaet/Wetter -> Jahreszeit)
// 10 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_image_generator.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

enum _Jahreszeit { fruehling, sommer, herbst, winter }

extension _JahreszeitName on _Jahreszeit {
  String get label {
    switch (this) {
      case _Jahreszeit.fruehling:
        return 'Frühling';
      case _Jahreszeit.sommer:
        return 'Sommer';
      case _Jahreszeit.herbst:
        return 'Herbst';
      case _Jahreszeit.winter:
        return 'Winter';
    }
  }

  String get pollinationsPrompt {
    switch (this) {
      case _Jahreszeit.fruehling:
        return 'spring meadow with flowers and butterflies';
      case _Jahreszeit.sommer:
        return 'sunny summer beach with sun';
      case _Jahreszeit.herbst:
        return 'autumn forest with colorful leaves';
      case _Jahreszeit.winter:
        return 'snowy winter landscape with snowman';
    }
  }

  Color get themeColor {
    switch (this) {
      case _Jahreszeit.fruehling:
        return const Color(0xFF10B981);
      case _Jahreszeit.sommer:
        return const Color(0xFFFCD34D);
      case _Jahreszeit.herbst:
        return const Color(0xFFEA580C);
      case _Jahreszeit.winter:
        return const Color(0xFF3B82F6);
    }
  }
}

class _Hinweis {
  const _Hinweis(this.text, this.jz);
  final String text;
  final _Jahreszeit jz;
}

enum _JahreszeitFrageTyp { bildErraten, hinweisErraten }

class JahreszeitenScreen extends StatefulWidget {
  const JahreszeitenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<JahreszeitenScreen> createState() => _JahreszeitenScreenState();
}

class _JahreszeitenScreenState extends State<JahreszeitenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 10;
  static const List<Color> _gradient = [
    Color(0xFF06B6D4),
    Color(0xFF0E7490),
  ];

  static const List<_Hinweis> _hinweise = [
    _Hinweis('Es schneit und ist kalt', _Jahreszeit.winter),
    _Hinweis('Schneemann bauen', _Jahreszeit.winter),
    _Hinweis('Weihnachten', _Jahreszeit.winter),
    _Hinweis('Eis laufen', _Jahreszeit.winter),
    _Hinweis('Blumen blühen', _Jahreszeit.fruehling),
    _Hinweis('Ostern', _Jahreszeit.fruehling),
    _Hinweis('Vögel singen wieder', _Jahreszeit.fruehling),
    _Hinweis('Schmetterlinge', _Jahreszeit.fruehling),
    _Hinweis('Schwimmen gehen', _Jahreszeit.sommer),
    _Hinweis('Eis essen', _Jahreszeit.sommer),
    _Hinweis('Sommerferien', _Jahreszeit.sommer),
    _Hinweis('Es ist heiß', _Jahreszeit.sommer),
    _Hinweis('Bunte Blätter fallen', _Jahreszeit.herbst),
    _Hinweis('Drachen steigen lassen', _Jahreszeit.herbst),
    _Hinweis('Kürbis und Halloween', _Jahreszeit.herbst),
    _Hinweis('Wind und Regen', _Jahreszeit.herbst),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _JahreszeitFrageTyp _typ;
  late _Jahreszeit _correctJz;
  late _Hinweis _aktuellerHinweis;
  late List<_Jahreszeit> _options;

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
    _typ = _JahreszeitFrageTyp.values[_rng.nextInt(2)];
    if (_typ == _JahreszeitFrageTyp.bildErraten) {
      _correctJz = _Jahreszeit.values[_rng.nextInt(4)];
    } else {
      _aktuellerHinweis = _hinweise[_rng.nextInt(_hinweise.length)];
      _correctJz = _aktuellerHinweis.jz;
    }
    _options = List.of(_Jahreszeit.values)..shuffle(_rng);
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    if (_typ == _JahreszeitFrageTyp.bildErraten) {
      text = 'Welche Jahreszeit zeigt das Bild?';
    } else {
      text = 'In welcher Jahreszeit passiert das: ${_aktuellerHinweis.text}?';
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
      try {
        LumoVoice.instance.speak('Richtig! Das ist ${_correctJz.label}!');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance
            .speak('Schau nochmal - das ist ${_correctJz.label}!');
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
        title: const Text('🌸 Jahreszeiten-Quiz fertig!',
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
                  if (_typ == _JahreszeitFrageTyp.bildErraten)
                    _buildSeasonImage()
                  else
                    _buildHinweisBox(),
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
            const Text('Jahreszeiten',
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
    final text = _typ == _JahreszeitFrageTyp.bildErraten
        ? 'Welche Jahreszeit ist das?'
        : 'Wann passiert das?';
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

  Widget _buildSeasonImage() {
    final url = LumoImageGenerator.instance
        .buildSafeImageUrl(_correctJz.pollinationsPrompt);
    return Container(
      width: 240,
      height: 240,
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
        child: url == null
            ? Container(
                color: _gradient[0].withOpacity(0.15),
                alignment: Alignment.center,
                child: const Text('🌸', style: TextStyle(fontSize: 80)),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _gradient[0].withOpacity(0.1),
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                        color: _gradient[0], strokeWidth: 3),
                  );
                },
                errorBuilder: (ctx, err, st) => Container(
                  color: _gradient[0].withOpacity(0.15),
                  alignment: Alignment.center,
                  child: const Text('🌸', style: TextStyle(fontSize: 80)),
                ),
              ),
      ),
    );
  }

  Widget _buildHinweisBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gradient[0].withOpacity(0.4), width: 3),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Text('"${_aktuellerHinweis.text}"',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _gradient[1])),
    );
  }

  Widget _buildOptions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: _options.asMap().entries.map((entry) {
        final idx = entry.key;
        final jz = entry.value;
        final isCorrect = jz == _correctJz;
        final isSelected = _selectedIdx == idx;
        Color bgColor = Colors.white;
        Color borderColor = jz.themeColor.withOpacity(0.5);
        Color textColor = jz.themeColor;
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
                child: Text(jz.label,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
