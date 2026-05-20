// ════════════════════════════════════════════════════════════════════════
// VERKEHR — Klasse 2 Sachkunde (Verkehrserziehung)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welche Farbe hat die Ampel?' (Bild der Ampel-Farbe -> Aktion)
//   - 'Was bedeutet dieses Zeichen?' (Zeichen erkennen)
//   - 'Wo darf man die Strasse ueberqueren?' (Sicherheits-Frage)
// 10 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class _VerkehrFrage {
  const _VerkehrFrage({
    required this.frage,
    required this.richtig,
    required this.falsch,
    this.kontext,
  });
  final String frage;
  final String richtig;
  final List<String> falsch;
  /// Optionaler kurzer Lern-Kontext nach der Antwort
  final String? kontext;
}

class VerkehrScreen extends StatefulWidget {
  const VerkehrScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<VerkehrScreen> createState() => _VerkehrScreenState();
}

class _VerkehrScreenState extends State<VerkehrScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 10;
  static const List<Color> _gradient = [
    Color(0xFFDC2626),
    Color(0xFF991B1B),
  ];

  static const List<_VerkehrFrage> _fragen = [
    _VerkehrFrage(
      frage: 'Die Ampel ist rot. Was machst du?',
      richtig: 'Stehen bleiben',
      falsch: ['Schnell rüber laufen', 'Hand heben', 'Rufen'],
      kontext: 'Bei Rot bleibt man immer stehen!',
    ),
    _VerkehrFrage(
      frage: 'Die Ampel ist grün. Was machst du?',
      richtig: 'Schauen und sicher überqueren',
      falsch: ['Schnell rennen', 'Augen zuhalten', 'Stehen bleiben'],
      kontext: 'Bei Grün: nochmal nach links und rechts schauen!',
    ),
    _VerkehrFrage(
      frage: 'Wo darf man die Straße überqueren?',
      richtig: 'Am Zebrastreifen',
      falsch: ['Hinter parkenden Autos', 'Auf der Kurve', 'Bei Nacht überall'],
      kontext: 'Der Zebrastreifen ist der sichere Weg!',
    ),
    _VerkehrFrage(
      frage: 'Was bedeutet der Zebrastreifen?',
      richtig: 'Sichere Überquerung für Fußgänger',
      falsch: ['Parkplatz', 'Spielplatz', 'Tankstelle'],
    ),
    _VerkehrFrage(
      frage: 'Wann schaut man vor dem Überqueren?',
      richtig: 'Links, rechts, links',
      falsch: ['Nur links', 'Nur geradeaus', 'Gar nicht'],
      kontext: 'Erst links, dann rechts, dann nochmal links!',
    ),
    _VerkehrFrage(
      frage: 'Was trägt man beim Radfahren?',
      richtig: 'Einen Helm',
      falsch: ['Eine Krone', 'Einen Sonnenhut', 'Nichts'],
      kontext: 'Der Helm schützt deinen Kopf!',
    ),
    _VerkehrFrage(
      frage: 'Wo gehst du als Fußgänger?',
      richtig: 'Am Gehweg',
      falsch: ['Mitten auf der Straße', 'Auf der Radspur', 'Auf den Schienen'],
    ),
    _VerkehrFrage(
      frage: 'Was siehst du an einem Stoppschild?',
      richtig: 'Ein rotes Achteck',
      falsch: ['Einen grünen Kreis', 'Ein blaues Dreieck', 'Einen gelben Stern'],
    ),
    _VerkehrFrage(
      frage: 'Im Auto sitzt du wo?',
      richtig: 'Auf dem Kindersitz mit Gurt',
      falsch: ['Vorne ohne Gurt', 'Am Lenkrad', 'Im Kofferraum'],
      kontext: 'Bis 14 Jahre Kindersitz, immer angeschnallt!',
    ),
    _VerkehrFrage(
      frage: 'Wann ist es im Verkehr besonders gefährlich?',
      richtig: 'In der Dunkelheit',
      falsch: ['Am Vormittag', 'Im Sommer', 'Bei Sonne'],
      kontext: 'In der Dunkelheit Reflektoren tragen!',
    ),
    _VerkehrFrage(
      frage: 'Was bedeutet ein gelbes Achtung-Schild?',
      richtig: 'Vorsicht und schauen',
      falsch: ['Schnell weglaufen', 'Klatschen', 'Schreien'],
    ),
    _VerkehrFrage(
      frage: 'Wo darfst du mit dem Roller fahren?',
      richtig: 'Am Gehweg oder Radweg',
      falsch: ['Auf der Autobahn', 'In Geschäften', 'Auf Schienen'],
    ),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _VerkehrFrage _aktuelle;
  late List<String> _options;
  late int _correctIdx;

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
    _aktuelle = _fragen[_rng.nextInt(_fragen.length)];
    _options = [_aktuelle.richtig, ..._aktuelle.falsch]..shuffle(_rng);
    _correctIdx = _options.indexOf(_aktuelle.richtig);
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak(_aktuelle.frage);
    } catch (_) {}
  }

  void _onAnswer(int idx) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIdx = idx;
      _answered = true;
    });
    final isCorrect = idx == _correctIdx;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(8);
      try {
        LumoVoice.instance.speak('Richtig! ${_aktuelle.kontext ?? ""}');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(
            'Schau nochmal - richtig ist: ${_aktuelle.richtig}. ${_aktuelle.kontext ?? ""}');
      } catch (_) {}
    }
    await Future.delayed(
        Duration(milliseconds: _aktuelle.kontext != null ? 2200 : 1500));
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
    widget.appState.addXp(_correctCount * 12);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🚦 Verkehrs-Quiz fertig!',
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
                  _buildFrageHeader(),
                  if (_answered && _aktuelle.kontext != null) ...[
                    const SizedBox(height: 12),
                    _buildKontextBox(),
                  ],
                  const SizedBox(height: 20),
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
            const Text('Verkehr & Sicherheit',
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

  Widget _buildFrageHeader() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(
            offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gradient[0].withOpacity(0.4), width: 3),
          boxShadow: [
            BoxShadow(
                color: _gradient[0].withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          const Text('🚦', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_aktuelle.frage,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _gradient[1])),
          ),
        ]),
      ),
    );
  }

  Widget _buildKontextBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 2),
      ),
      child: Row(children: [
        const Icon(Icons.lightbulb_outline_rounded,
            color: Color(0xFFD97706), size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_aktuelle.kontext!,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E))),
        ),
      ]),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: List.generate(_options.length, (idx) {
        final opt = _options[idx];
        final isCorrect = idx == _correctIdx;
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
              onTap: _answered ? null : () => _onAnswer(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 3),
                ),
                child: Text(opt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
              ),
            ),
          ),
        );
      }),
    );
  }
}
