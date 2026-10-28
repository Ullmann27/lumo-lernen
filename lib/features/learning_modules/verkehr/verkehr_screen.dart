// ════════════════════════════════════════════════════════════════════════
// VERKEHR — Klasse 2 Sachkunde (Verkehrserziehung)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welche Farbe hat die Ampel?' (Bild der Ampel-Farbe -> Aktion)
//   - 'Was bedeutet dieses Zeichen?' (Zeichen erkennen)
//   - 'Wo darf man die Strasse ueberqueren?' (Sicherheits-Frage)
// 10 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import '../../../widgets/design/lumo_learning_module_frame.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../learning_module_progress.dart';
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
  static const int _totalTasks = 30;
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
      falsch: [
        'Einen grünen Kreis',
        'Ein blaues Dreieck',
        'Einen gelben Stern'
      ],
    ),
    _VerkehrFrage(
      frage: 'Wie fährst du als Kind sicher im Auto mit?',
      richtig: 'Passend gesichert und angeschnallt',
      falsch: ['Vorne ohne Gurt', 'Am Lenkrad', 'Im Kofferraum'],
      kontext: 'Im Auto brauchst du immer den Gurt und, wenn erforderlich, einen passenden Kindersitz.',
    ),
    _VerkehrFrage(
      frage: 'Wann ist es im Verkehr besonders gefährlich?',
      richtig: 'In der Dunkelheit',
      falsch: ['Am Vormittag', 'Im Sommer', 'Bei Sonne'],
      kontext: 'In der Dunkelheit Reflektoren tragen!',
    ),
    _VerkehrFrage(
      frage: 'Was bedeutet ein dreieckiges Warnschild mit rotem Rand?',
      richtig: 'Achtung, mögliche Gefahr',
      falsch: ['Schnell weglaufen', 'Klatschen', 'Schreien'],
    ),
    _VerkehrFrage(
      frage: 'Was machst du vor dem Losfahren mit einem Tretroller?',
      richtig: 'Bremsen und den Weg kontrollieren',
      falsch: ['Mit geschlossenen Augen fahren', 'Sofort auf die Fahrbahn rasen', 'Andere wegschubsen'],
    ),
    _VerkehrFrage(frage: 'Warum gehst du nicht zwischen parkenden Autos auf die Straße?', richtig: 'Dort können andere dich schlecht sehen', falsch: ['Autos haben keine Fenster', 'Dort ist es immer wärmer', 'Der Gehsteig verschwindet'], kontext: 'Suche eine übersichtliche Stelle zum Überqueren.'),
    _VerkehrFrage(frage: 'Der Schranken am Bahnübergang ist geschlossen. Was tust du?', richtig: 'Hinter dem Schranken warten', falsch: ['Darunter durchlaufen', 'Über die Schienen klettern', 'Dem Zug entgegenlaufen'], kontext: 'Warte, bis der Bahnübergang wieder sicher freigegeben ist.'),
    _VerkehrFrage(frage: 'Was hilft dir, bei Dunkelheit besser gesehen zu werden?', richtig: 'Reflektierende Kleidung tragen', falsch: ['Alle Reflektoren entfernen', 'Nur dunkle Kleidung anziehen', 'Die Augen schließen']),
    _VerkehrFrage(frage: 'Ein Bus ist noch in Bewegung. Wann steigst du aus?', richtig: 'Erst nach dem vollständigen Anhalten', falsch: ['Während der Fahrt', 'Durch ein Fenster', 'Noch vor dem Öffnen der Tür']),
    _VerkehrFrage(frage: 'Warum solltest du nicht direkt vor einem großen Lastwagen stehen?', richtig: 'Die Fahrerin oder der Fahrer sieht dich womöglich nicht', falsch: ['Lastwagen schweben', 'Dort ist die Luft immer zu heiß', 'Alle Lastwagen stehen für immer'], kontext: 'Halte Abstand zum toten Winkel.'),
    _VerkehrFrage(frage: 'Ein Ball rollt auf die Fahrbahn. Was ist sicher?', richtig: 'Anhalten und Erwachsene um Hilfe bitten', falsch: ['Sofort hinterherrennen', 'Ohne Schauen überqueren', 'Zwischen die Autos springen']),
    _VerkehrFrage(frage: 'Was solltest du tun, bevor du eine Straße überquerst?', richtig: 'Verkehr beobachten und sicheren Weg wählen', falsch: ['Musik lauter drehen', 'Nur auf das Handy schauen', 'Einfach losrennen']),
    _VerkehrFrage(frage: 'Warum sollten Fahrradbremsen vor der Fahrt geprüft werden?', richtig: 'Damit du sicher anhalten kannst', falsch: ['Damit Reifen größer werden', 'Damit die Klingel heller klingt', 'Damit du nicht lenken musst']),
    _VerkehrFrage(frage: 'Was tust du, wenn ein Verkehrsschild dir unbekannt ist?', richtig: 'Vorsichtig bleiben und die Bedeutung klären', falsch: ['Es absichtlich ignorieren', 'Schneller laufen', 'Einfach das Schild umdrehen']),
    _VerkehrFrage(frage: 'Wie verhältst du dich, wenn die Sicht durch starken Regen schlecht ist?', richtig: 'Langsam und besonders aufmerksam bewegen', falsch: ['Blind über die Straße laufen', 'Kopfhörer lauter drehen', 'Andere schubsen']),
    _VerkehrFrage(frage: 'Was bedeutet das rote Licht einer Fußgängerampel?', richtig: 'Warten und nicht losgehen', falsch: ['Schneller loslaufen', 'Die Straße ist ein Spielplatz', 'Nicht mehr auf Autos achten']),
    _VerkehrFrage(frage: 'Was tust du, wenn ein Auto am Zebrastreifen anhält?', richtig: 'Weiter aufmerksam schauen, dann sicher gehen', falsch: ['Nicht mehr in beide Richtungen schauen', 'Rückwärts blind laufen', 'Vor dem Auto spielen']),
    _VerkehrFrage(frage: 'Was solltest du auf einem Fahrrad niemals während der Fahrt tun?', richtig: 'Die Augen zumachen', falsch: ['Auf den Weg achten', 'Beide Hände zum Bremsen bereit halten', 'Hindernisse rechtzeitig erkennen']),
    _VerkehrFrage(frage: 'Was ist an einer Straßenkreuzung besonders wichtig?', richtig: 'Auf Fahrzeuge aus mehreren Richtungen achten', falsch: ['Nur den Himmel betrachten', 'Ohne Blick geradeaus laufen', 'Die Ohren verschließen']),
    _VerkehrFrage(frage: 'Was hilft dir, wenn du den Weg nach Hause nicht kennst?', richtig: 'Eine vertrauenswürdige erwachsene Person fragen', falsch: ['Auf unbekannte Fahrzeuge aufspringen', 'Ohne Plan auf die Straße laufen', 'Verkehrszeichen abdecken']),
    _VerkehrFrage(frage: 'Wie verhältst du dich neben einer Baustelle an der Straße?', richtig: 'Absperrungen beachten und Abstand halten', falsch: ['Unter Baugeräten spielen', 'Absperrbänder zerreißen', 'Auf die Fahrbahn springen']),
    _VerkehrFrage(frage: 'Wozu dient eine Fahrradklingel?', richtig: 'Andere rechtzeitig auf dich aufmerksam machen', falsch: ['Die Bremsen ersetzen', 'Die Straße absperren', 'Den Reifen aufpumpen']),
    _VerkehrFrage(frage: 'Warum ist es gefährlich, beim Gehen auf die Straße am Handy zu spielen?', richtig: 'Man übersieht leicht den Verkehr', falsch: ['Autos können nur stillstehen', 'Handys verändern die Ampel', 'Zebrastreifen werden unsichtbar']),
  ];

  late final LearningModuleProgress _progress;

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
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Sachunterricht',
      unit: 'Verkehr',
    );
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
    _progress.dispose();
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // Heinz-Scan 2026-05-21: vorher nextInt(_fragen.length) bei jedem
  // Task -> selbe Frage konnte bei 30 Aufgaben mehrmals vorkommen.
  // Jetzt: Shuffled-Pool, durchgehen bis leer, dann neu mischen
  // (gleiche Frage kommt nicht in den letzten N).
  List<_VerkehrFrage> _pool = [];

  void _generateTask() {
    if (_pool.isEmpty) {
      _pool = List.of(_fragen)..shuffle(_rng);
    }
    _aktuelle = _pool.removeLast();
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
    if (_answered || _progress.hasPending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIdx = idx;
      _answered = true;
    });
    final isCorrect = idx == _correctIdx;
    final saved = await _progress.saveAnswer(
      problemKey: _aktuelle.frage,
      correct: isCorrect,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 8 : 0,
    );
    if (!saved || !mounted) return;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      setState(() => _correctCount++);
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
    final canAdvance = await _progress.feedbackDelay(
        Duration(milliseconds: _aktuelle.kontext != null ? 2200 : 1500));
    if (!canAdvance || !mounted) return;
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

  void _showFinish() async {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    final saved = await _progress.saveBonus(
      stars: stars,
      xp: _correctCount * 12,
    );
    if (!saved || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🚦 Verkehrs-Quiz fertig!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
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
    return LearningModuleProgressScope(
      progress: _progress,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: 'Welt-Abenteuer',
        moduleTitle: 'Verkehr & Sicherheit',
        icon: Icons.traffic_rounded,
        taskIndex: _taskIdx,
        totalTasks: _totalTasks,
        correctAnswers: _correctCount,
        progressLabel: 'Aufgabe',
        canLeave: () => !_progress.hasPending,
        child: AnimatedBuilder(
          animation: _entryCtrl,
          builder: (_, child) {
            return Opacity(
                opacity: LumoLessonStyle.reducedMotion(context, widget.appState)
                    ? 1
                    : _entryCtrl.value,
                child: child);
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
    );
  }

  Widget _buildFrageHeader() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = LumoLessonStyle.reducedMotion(context, widget.appState)
            ? 0.0
            : math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 3),
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
                    color: LumoVisualTokens.white)),
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
        Color bgColor = LumoVisualTokens.lessonAnswer;
        Color borderColor = LumoVisualTokens.cyan.withValues(alpha: .8);
        Color textColor = LumoVisualTokens.white;
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
          textColor = const Color(0xFF713F12);
          borderColor = const Color(0xFFFCD34D);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedBuilder(
            animation: _bounceCtrl,
            builder: (_, child) {
              final scale = isSelected &&
                      isCorrect &&
                      !LumoLessonStyle.reducedMotion(context, widget.appState)
                  ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.06
                  : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: LumoLessonAnswerTap(
              correct: _answered && isSelected ? isCorrect : null,
              onTap: _answered ? null : () => _onAnswer(idx),
              child: AnimatedContainer(
                duration:
                    LumoLessonStyle.reducedMotion(context, widget.appState)
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: LumoLessonStyle.answer(
                    background: bgColor, border: borderColor),
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
