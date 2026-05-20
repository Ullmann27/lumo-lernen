// ════════════════════════════════════════════════════════════════════════
// ZEITFORMEN — Klasse 3 Deutsch (Vergangenheit / Gegenwart / Zukunft)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'In welcher Zeit steht der Satz?' (Satz -> Zeitform)
//   - 'Welcher Satz steht in der Zukunft?' (3 Saetze, einer richtig)
// 10 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

enum _Zeitform { vergangenheit, gegenwart, zukunft }

extension _ZeitformName on _Zeitform {
  String get label {
    switch (this) {
      case _Zeitform.vergangenheit:
        return 'Vergangenheit';
      case _Zeitform.gegenwart:
        return 'Gegenwart';
      case _Zeitform.zukunft:
        return 'Zukunft';
    }
  }

  String get hint {
    switch (this) {
      case _Zeitform.vergangenheit:
        return 'Was schon passiert ist (gestern)';
      case _Zeitform.gegenwart:
        return 'Was gerade passiert (jetzt)';
      case _Zeitform.zukunft:
        return 'Was noch passieren wird (morgen)';
    }
  }

  String get icon {
    switch (this) {
      case _Zeitform.vergangenheit:
        return '⏮';
      case _Zeitform.gegenwart:
        return '▶';
      case _Zeitform.zukunft:
        return '⏭';
    }
  }
}

class _SatzItem {
  const _SatzItem(this.satz, this.zeit);
  final String satz;
  final _Zeitform zeit;
}

enum _ZeitformFrageTyp { satzKategorisieren, satzAuswaehlen }

class ZeitformenScreen extends StatefulWidget {
  const ZeitformenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<ZeitformenScreen> createState() => _ZeitformenScreenState();
}

class _ZeitformenScreenState extends State<ZeitformenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 10;
  static const List<Color> _gradient = [
    Color(0xFF0EA5E9),
    Color(0xFF0369A1),
  ];

  static const List<_SatzItem> _saetze = [
    // Vergangenheit
    _SatzItem('Ich habe Eis gegessen.', _Zeitform.vergangenheit),
    _SatzItem('Wir spielten im Garten.', _Zeitform.vergangenheit),
    _SatzItem('Der Hund ist gelaufen.', _Zeitform.vergangenheit),
    _SatzItem('Sie sang ein Lied.', _Zeitform.vergangenheit),
    _SatzItem('Mama hat gekocht.', _Zeitform.vergangenheit),
    _SatzItem('Papa schwamm im See.', _Zeitform.vergangenheit),
    // Gegenwart
    _SatzItem('Ich spiele Fußball.', _Zeitform.gegenwart),
    _SatzItem('Der Vogel singt.', _Zeitform.gegenwart),
    _SatzItem('Mama kocht das Essen.', _Zeitform.gegenwart),
    _SatzItem('Wir lernen Mathe.', _Zeitform.gegenwart),
    _SatzItem('Die Sonne scheint.', _Zeitform.gegenwart),
    _SatzItem('Lumo lacht.', _Zeitform.gegenwart),
    // Zukunft
    _SatzItem('Ich werde morgen schwimmen.', _Zeitform.zukunft),
    _SatzItem('Wir werden Pizza essen.', _Zeitform.zukunft),
    _SatzItem('Der Hund wird bellen.', _Zeitform.zukunft),
    _SatzItem('Mama wird einkaufen gehen.', _Zeitform.zukunft),
    _SatzItem('Wir werden in die Schule fahren.', _Zeitform.zukunft),
    _SatzItem('Papa wird auch da sein.', _Zeitform.zukunft),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _ZeitformFrageTyp _typ;
  late _SatzItem _korrektSatz;
  late _Zeitform _gefragteZeit;
  late List<_Zeitform> _zeitOptions;
  late List<_SatzItem> _satzOptions;

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
    _typ = _ZeitformFrageTyp.values[_rng.nextInt(_ZeitformFrageTyp.values.length)];
    if (_typ == _ZeitformFrageTyp.satzKategorisieren) {
      _korrektSatz = _saetze[_rng.nextInt(_saetze.length)];
      _zeitOptions = List.of(_Zeitform.values)..shuffle(_rng);
    } else {
      _gefragteZeit = _Zeitform.values[_rng.nextInt(_Zeitform.values.length)];
      final passend = _saetze.where((s) => s.zeit == _gefragteZeit).toList()
        ..shuffle(_rng);
      final andere = _saetze.where((s) => s.zeit != _gefragteZeit).toList()
        ..shuffle(_rng);
      _korrektSatz = passend.first;
      _satzOptions = [passend.first, ...andere.take(3)]..shuffle(_rng);
    }
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    if (_typ == _ZeitformFrageTyp.satzKategorisieren) {
      text = 'In welcher Zeit steht der Satz?';
    } else {
      text = 'Welcher Satz steht in der ${_gefragteZeit.label}?';
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
            'Schau nochmal - das ist ${_korrektSatz.zeit.label}!');
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
        title: const Text('⏰ Zeitformen-Quiz fertig!',
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
                  const SizedBox(height: 24),
                  if (_typ == _ZeitformFrageTyp.satzKategorisieren) ...[
                    _buildSatzAnzeige(_korrektSatz.satz),
                    const SizedBox(height: 24),
                    _buildZeitOptions(),
                  ] else
                    _buildSatzOptions(),
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
            const Text('Zeitformen',
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
    final text = _typ == _ZeitformFrageTyp.satzKategorisieren
        ? 'In welcher Zeit ist der Satz?'
        : 'Welcher Satz steht in der ${_gefragteZeit.label}?\n(${_gefragteZeit.hint})';
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

  Widget _buildSatzAnzeige(String satz) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
      child: Text('"$satz"',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _gradient[1])),
    );
  }

  Widget _buildZeitOptions() {
    return Column(
      children: List.generate(_zeitOptions.length, (idx) {
        final zeit = _zeitOptions[idx];
        final isCorrect = zeit == _korrektSatz.zeit;
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
                  Text(zeit.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zeit.label,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor)),
                        Text(zeit.hint,
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

  Widget _buildSatzOptions() {
    return Column(
      children: List.generate(_satzOptions.length, (idx) {
        final s = _satzOptions[idx];
        final isCorrect = s.zeit == _gefragteZeit;
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: _answered ? null : () => _onAnswer(idx, isCorrect),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 3),
              ),
              child: Text(s.satz,
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
}
