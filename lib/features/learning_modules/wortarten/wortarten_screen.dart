// ════════════════════════════════════════════════════════════════════════
// WORTARTEN — Klasse 3 Deutsch (Nomen / Verb / Adjektiv)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Ist <Wort> ein Nomen, Verb oder Adjektiv?'
//   - 'Welches Wort ist ein Nomen?' (4 Wörter, eines ist Nomen)
// 10 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

enum _Wortart { nomen, verb, adjektiv }

extension _WortartName on _Wortart {
  String get label {
    switch (this) {
      case _Wortart.nomen:
        return 'Nomen';
      case _Wortart.verb:
        return 'Verb';
      case _Wortart.adjektiv:
        return 'Adjektiv';
    }
  }

  String get explainer {
    switch (this) {
      case _Wortart.nomen:
        return 'Etwas das man anfassen kann';
      case _Wortart.verb:
        return 'Eine Tätigkeit (was man tut)';
      case _Wortart.adjektiv:
        return 'Wie etwas ist (Eigenschaft)';
    }
  }
}

class _WortItem {
  const _WortItem(this.wort, this.art);
  final String wort;
  final _Wortart art;
}

enum _WortartenFrageTyp { wortKategorisieren, kategorieFinden }

class WortartenScreen extends StatefulWidget {
  const WortartenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<WortartenScreen> createState() => _WortartenScreenState();
}

class _WortartenScreenState extends State<WortartenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFF7C3AED),
    Color(0xFF5B21B6),
  ];

  static const List<_WortItem> _woerter = [
    // Nomen
    _WortItem('Hund', _Wortart.nomen),
    _WortItem('Schule', _Wortart.nomen),
    _WortItem('Auto', _Wortart.nomen),
    _WortItem('Apfel', _Wortart.nomen),
    _WortItem('Mama', _Wortart.nomen),
    _WortItem('Buch', _Wortart.nomen),
    _WortItem('Wiese', _Wortart.nomen),
    _WortItem('Garten', _Wortart.nomen),
    // Verb
    _WortItem('laufen', _Wortart.verb),
    _WortItem('lachen', _Wortart.verb),
    _WortItem('schwimmen', _Wortart.verb),
    _WortItem('essen', _Wortart.verb),
    _WortItem('spielen', _Wortart.verb),
    _WortItem('singen', _Wortart.verb),
    _WortItem('tanzen', _Wortart.verb),
    _WortItem('schreiben', _Wortart.verb),
    // Adjektiv
    _WortItem('schnell', _Wortart.adjektiv),
    _WortItem('rot', _Wortart.adjektiv),
    _WortItem('groß', _Wortart.adjektiv),
    _WortItem('klein', _Wortart.adjektiv),
    _WortItem('lustig', _Wortart.adjektiv),
    _WortItem('müde', _Wortart.adjektiv),
    _WortItem('hungrig', _Wortart.adjektiv),
    _WortItem('schön', _Wortart.adjektiv),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _WortartenFrageTyp _typ;
  late _WortItem _korrektWort;
  late List<_Wortart> _wortartOptions;
  late List<_WortItem> _woerterOptions;
  late _Wortart _gefragteArt;

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
    _typ = _WortartenFrageTyp.values[_rng.nextInt(_WortartenFrageTyp.values.length)];
    if (_typ == _WortartenFrageTyp.wortKategorisieren) {
      _korrektWort = _woerter[_rng.nextInt(_woerter.length)];
      _wortartOptions = List.of(_Wortart.values)..shuffle(_rng);
    } else {
      _gefragteArt = _Wortart.values[_rng.nextInt(_Wortart.values.length)];
      final richtige = _woerter.where((w) => w.art == _gefragteArt).toList()
        ..shuffle(_rng);
      final falsche = _woerter.where((w) => w.art != _gefragteArt).toList()
        ..shuffle(_rng);
      _woerterOptions = [richtige.first, ...falsche.take(3)]..shuffle(_rng);
      _korrektWort = richtige.first;
    }
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    if (_typ == _WortartenFrageTyp.wortKategorisieren) {
      text = 'Ist "${_korrektWort.wort}" ein Nomen, Verb oder Adjektiv?';
    } else {
      text = 'Welches Wort ist ein ${_gefragteArt.label}?';
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
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(
            'Schau nochmal - "${_korrektWort.wort}" ist ein ${_korrektWort.art.label}!');
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 1500));
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
        title: const Text('📚 Wortarten-Quiz fertig!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Wörter richtig!',
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
                  const SizedBox(height: 24),
                  if (_typ == _WortartenFrageTyp.wortKategorisieren) ...[
                    _buildWortAnzeige(),
                    const SizedBox(height: 24),
                    _buildWortartGrid(),
                  ] else ...[
                    _buildWortGrid(),
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
              const Text('Wortarten',
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
    if (_typ == _WortartenFrageTyp.wortKategorisieren) {
      text = 'Was ist das für ein Wort?';
    } else {
      text = 'Welches Wort ist ein ${_gefragteArt.label}?\n(${_gefragteArt.explainer})';
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _gradient[1])),
      ),
    );
  }

  Widget _buildWortAnzeige() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
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
      child: Text(_korrektWort.wort,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: _gradient[1])),
    );
  }

  Widget _buildWortartGrid() {
    return Column(
      children: List.generate(_wortartOptions.length, (idx) {
        final art = _wortartOptions[idx];
        final isCorrect = art == _korrektWort.art;
        final isSelected = _selectedIdx == idx;
        Color bgColor = Colors.white;
        Color borderColor = _gradient[0].withOpacity(0.3);
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedBuilder(
            animation: _bounceCtrl,
            builder: (_, child) {
              final scale = isSelected && isCorrect
                  ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.06
                  : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: _answered ? null : () => _onAnswer(idx, isCorrect),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 3),
                ),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(art.label[0],
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textColor)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(art.label,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor)),
                        Text(art.explainer,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textColor.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWortGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: _woerterOptions.asMap().entries.map((entry) {
        final idx = entry.key;
        final w = entry.value;
        final isCorrect = w.art == _gefragteArt;
        final isSelected = _selectedIdx == idx;
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
            onTap: _answered ? null : () => _onAnswer(idx, isCorrect),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 3),
              ),
              child: Center(
                child: Text(w.wort,
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
