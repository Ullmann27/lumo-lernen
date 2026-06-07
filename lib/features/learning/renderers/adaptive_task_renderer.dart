import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../shared/widgets/lumo_premium_effects.dart';
import '../../schoolbook/widgets/schoolbook_task_widgets.dart';
import 'lumo_premium_visuals.dart';
import 'shape_trace_task_renderer.dart';
import 'writing_task_renderer.dart';

class AdaptiveTaskAnswer {
  const AdaptiveTaskAnswer({
    required this.task,
    required this.answer,
    required this.correct,
  });

  final TaskInstance task;
  final Object answer;
  final bool correct;
}

class AdaptiveTaskRenderer extends StatefulWidget {
  const AdaptiveTaskRenderer({
    super.key,
    required this.task,
    this.onAnswered,
    this.onWritingSubmitted,
    this.onShapeTraced,
  });

  final TaskInstance task;
  final ValueChanged<AdaptiveTaskAnswer>? onAnswered;
  final ValueChanged<WritingTaskResult>? onWritingSubmitted;
  final ValueChanged<ShapeTraceTaskResult>? onShapeTraced;

  @override
  State<AdaptiveTaskRenderer> createState() => _AdaptiveTaskRendererState();
}

class _AdaptiveTaskRendererState extends State<AdaptiveTaskRenderer> {
  Object? _picked;
  final Set<String> _wrongAnswers = <String>{};

  bool get _solved => _picked != null && '$_picked' == '${widget.task.correctAnswer}';

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    if (task.taskType == TaskType.writingCanvas) {
      return WritingTaskRenderer(
        task: task,
        onSubmitted: widget.onWritingSubmitted,
      );
    }

    // 2026-06-05 Iter 20: Form-Nachzeichnen-Aufgaben (Quadrat, Kreis, ...).
    // Eigener Renderer mit Demo-Phase (Strich fuer Strich vorgezeichnet)
    // und Trace-Phase (Kind zeichnet auf leerem Canvas nach).
    if (task.taskType == TaskType.shapeTrace) {
      return ShapeTraceTaskRenderer(
        task: task,
        onSubmitted: widget.onShapeTraced,
      );
    }

    // 2026-06-06 Iter 26: Frage-Card mit Schulbuch-Akzent.
    // Heinz: 'sieht nicht eindrucksvoll aus'. Vorher schlichte cream Card.
    // Jetzt: linker Buch-Spine in Subject-Farbe (vertikaler 8px Streifen),
    // Subject-Label als Chip-Pill statt nur Text, papier-Schatten unten.
    final subjectAccent = switch (task.subject) {
      LearningSubject.mathematik => const Color(0xFFEA580C),
      LearningSubject.deutsch => const Color(0xFF6366F1),
      LearningSubject.sachkunde => const Color(0xFF059669),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 2026-06-06 FIX: Border mit unterschiedlichen Farben + borderRadius
      // crasht Flutter silent (Widget unsichtbar). Loesung: Outer Container
      // mit border-Side links als separate child, dann inner Card mit
      // borderRadius + uniform border.
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: subjectAccent.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Linker Buch-Spine (5px), eigenes Container
            Container(width: 5, color: subjectAccent),
            // Hauptbereich
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(17, 18, 18, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF8ED), Color(0xFFFFFEFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: subjectAccent.withOpacity(0.18), width: 1),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: subjectAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(LumoRadius.pill),
                      border: Border.all(
                          color: subjectAccent.withOpacity(0.35)),
                    ),
                    child: Text(
                      _subjectLabel(task.subject),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: subjectAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.prompt,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: LumoColors.ink900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AdaptiveVisual(task: task, picked: _picked, solved: _solved),
                  if (_wrongAnswers.length >= 2 && !_solved) ...[
                    const SizedBox(height: 14),
                    _LocalHelpBanner(task: task, wrongCount: _wrongAnswers.length),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        _wrongAnswers.length >= 2 && !_solved
            ? 'Versuch es nochmal mit Lumos Hilfe:'
            : 'Wähle die richtige Antwort:',
        style: LumoTextStyles.label.copyWith(color: LumoColors.ink500, fontSize: 14),
      ),
      const SizedBox(height: 12),
      _OptionGrid(
        task: task,
        picked: _picked,
        wrongAnswers: _wrongAnswers,
        solved: _solved,
        onPick: _pick,
      ),
    ]);
  }

  void _pick(AnswerOption option) {
    if (_solved) return;
    final answer = option.payload ?? option.label;
    final answerKey = '$answer';
    if (_wrongAnswers.contains(answerKey)) return;
    final correct = answerKey == '${widget.task.correctAnswer}';

    setState(() {
      if (correct) {
        _picked = answer;
      } else {
        _wrongAnswers.add(answerKey);
      }
    });

    if (correct) {
      widget.onAnswered?.call(
        AdaptiveTaskAnswer(task: widget.task, answer: answer, correct: true),
      );
    }
  }

  String _subjectLabel(LearningSubject subject) {
    return switch (subject) {
      LearningSubject.deutsch => 'Deutsch',
      LearningSubject.mathematik => 'Mathematik',
      LearningSubject.sachkunde => 'Sachkunde',
    };
  }
}

class _LocalHelpBanner extends StatelessWidget {
  const _LocalHelpBanner({required this.task, required this.wrongCount});

  final TaskInstance task;
  final int wrongCount;

  @override
  Widget build(BuildContext context) {
    final hint = _buildHint(task);
    // 2026-06-06 Iter 27: Premium-Look fuer Lumo-Hilfe-Banner.
    // Vorher: flacher gelber Container. Jetzt: Gradient + Glow + groesserer
    // Mascot-Avatar im farbigen Kreis. Header in Pill-Form abgesetzt.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFCD34D).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFB923C), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFB923C).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // 2026-06-06 Iter 28: Echte Lumo-Pose statt nur Emoji.
          // Heinz' Wunsch: 'mehr Professionalitaet'. Wir nutzen den
          // vorhandenen Companion-PNG (lumo_think) - faellt bei
          // Asset-Fehler auf Emoji zurueck.
          child: ClipOval(
            child: Image.asset(
              'assets/companion/lumo_think.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Text('🦊', style: TextStyle(fontSize: 26)),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFB923C),
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFB923C).withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                wrongCount == 2
                    ? '💡 Lumo hilft Schritt fuer Schritt'
                    : '💡 Noch ein Tipp von Lumo',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF78350F),
                height: 1.35,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _buildHint(TaskInstance task) {
    // 2026-06-05 Iter 25: variantenreiche, aufgaben-spezifische Hilfe.
    // Heinz' Feedback: 'Hilfen sind eintoenig'. Vorher fielen Deutsch und
    // Sachkunde auf den selben Default-Satz zurueck. Jetzt:
    // - parst aufgaben-konkrete Schluesselwoerter (Satz, Wort, Tier, Koerper, ...)
    // - liefert 2-4 sinnvolle Varianten pro Kategorie
    // - waehlt die Variante per Seed-Hash der Aufgabe (stabil aber abwechslungsreich)
    final prompt = task.prompt.toLowerCase();
    final numbers = _allInts(task.prompt);

    if (task.subject == LearningSubject.mathematik && numbers.length >= 2) {
      final a = numbers[0];
      final b = numbers[1];
      final op = _operationFromTask(task);
      if (op == 'subtraction') {
        return _pick(task, <String>[
          'Du startest mit $a. Dann nimmst du $b weg. Decke $b Dinge ab oder streiche sie. Was uebrig bleibt, ist die Antwort.',
          'Stell dir $a Aepfel vor. Du gibst $b weg. Zaehl was uebrig bleibt.',
          'Beginne bei $a auf dem Zahlenstrahl und huepfe $b Schritte zurueck.',
        ]);
      }
      if (op == 'multiplication' || prompt.contains('×') || prompt.contains('mal')) {
        return _pick(task, <String>[
          'Stell dir $a Gruppen mit je $b Dingen vor. Wie viele insgesamt?',
          'Du kannst auch tauschen: $b × $a ist genau dasselbe.',
          'Zerlege $a × $b in $a Reihen mit $b Wuerfeln.',
        ]);
      }
      return _pick(task, <String>[
        'Zaehle zuerst $a Dinge, dann noch $b dazu. Danach zaehlst du alle zusammen.',
        'Erst $a, dann $b mehr - huepfe auf dem Zahlenstrahl weiter.',
        'Vertausche zur Probe: $b + $a ist genau dasselbe wie $a + $b.',
      ]);
    }

    // ── Deutsch / Lesen ──
    if (prompt.contains('welcher satz ist richtig') || prompt.contains('satz')) {
      return _pick(task, <String>[
        'Ein Satz beginnt gross und endet mit einem Punkt. Pruef das bei jeder Antwort.',
        'Welcher Satz klingt richtig wenn du ihn laut liest? Probiers!',
        'Subjekt (wer?), dann das Verb (was tut er?) - die richtige Reihenfolge.',
        'Sprich jeden Satz langsam vor dich hin. Welcher klingt schoen?',
      ]);
    }
    if (prompt.contains('namenswort') || prompt.contains('hauptwort') || prompt.contains('nomen')) {
      return _pick(task, <String>[
        'Namenswoerter sind Dinge, Personen oder Tiere. Sie werden GROSS geschrieben.',
        'Vor ein Namenswort kannst du der/die/das setzen. Probier es bei jeder Antwort!',
        'Such das Wort das ein Ding meint - kein Tun, keine Eigenschaft.',
      ]);
    }
    if (prompt.contains('tunwort') || prompt.contains('verb')) {
      return _pick(task, <String>[
        'Tunwoerter sagen was jemand MACHT: laufen, malen, lachen.',
        'Pass auf das Wort auf das eine Bewegung oder Taetigkeit zeigt.',
        'Welches Wort kannst du nach "Ich..." setzen? Das ist das Tunwort.',
      ]);
    }
    if (prompt.contains('wiewort') || prompt.contains('adjektiv') || prompt.contains('eigenschaft')) {
      return _pick(task, <String>[
        'Wiewoerter beschreiben WIE etwas ist: gross, klein, schnell, leise.',
        'Frag dich: "wie ist es?" - das passt nur auf das Wiewort.',
        'Ein Wiewort sagt nicht WAS das ist, sondern WIE es ist.',
      ]);
    }
    if (prompt.contains('reim') || prompt.contains('reimt sich')) {
      return _pick(task, <String>[
        'Reimwoerter klingen am Ende gleich: Hase - Nase, Ball - Fall.',
        'Sprich beide Woerter laut. Hoeren sich die letzten Laute gleich an?',
        'Nur die letzten Buchstaben muessen gleich klingen, nicht das ganze Wort.',
      ]);
    }
    if (prompt.contains('silbe')) {
      return _pick(task, <String>[
        'Sprich das Wort langsam. Bei jeder Silbe klatschst du einmal mit.',
        'Stell dir die Silben wie kleine Pakete vor: Ba-na-ne = 3 Pakete.',
        'Lege fuer jede Silbe einen Finger hin. Zaehl am Ende deine Finger.',
      ]);
    }
    if (prompt.contains('anfangs') || prompt.contains('beginnt')) {
      return _pick(task, <String>[
        'Sprich das Wort ganz langsam und hoere nur auf den ersten Laut.',
        'Welcher Laut kommt zuerst raus wenn du den Mund auf-machst?',
        'Sprich nur den ersten Buchstaben sehr lang: "Aaaa-pfel" - das A!',
      ]);
    }
    if (prompt.contains('endlaut') || prompt.contains('endet')) {
      return _pick(task, <String>[
        'Sprich das Wort langsam. Welcher Laut kommt ganz am Ende?',
        'Sprich nur den letzten Buchstaben lang: "Bal-llll" - das L!',
        'Hoer beim letzten Laut genau hin. Das ist die Antwort.',
      ]);
    }
    if (prompt.contains('mehrzahl') || prompt.contains('plural')) {
      return _pick(task, <String>[
        '"Eins" oder "viele"? Bei viele endet das Wort oft auf -e, -en oder -s.',
        'Setze "viele" davor und sprich das Wort - so klingt die Mehrzahl.',
      ]);
    }
    if (prompt.contains('artikel') || prompt.contains('der die das')) {
      return _pick(task, <String>[
        'Frag dich: heisst es der, die oder das? Hoer auf den natuerlichen Klang.',
        'Setze "ein" oder "eine" davor - das hilft beim Artikel finden.',
      ]);
    }

    // ── Sachkunde ──
    if (prompt.contains('koerper') ||
        prompt.contains('hoer') ||
        prompt.contains('seh') ||
        prompt.contains('riech') ||
        prompt.contains('schmeck')) {
      return _pick(task, <String>[
        'Greif dir an den Koerper-Teil mit dem du das machst - der gehoert dazu!',
        'Womit machst DU das gerade? Spuer es selber - das ist die Antwort.',
        'Schau dich kurz im Spiegel an. Welches Koerper-Teil passt zur Frage?',
      ]);
    }
    if (prompt.contains('tier') || prompt.contains('hund') || prompt.contains('katze') ||
        prompt.contains('vogel')) {
      return _pick(task, <String>[
        'Stell dir das Tier vor: wo lebt es? was frisst es? - das hilft.',
        'Ueberleg was das Tier kann - schwimmen, fliegen, klettern?',
      ]);
    }
    if (prompt.contains('wetter') || prompt.contains('regen') || prompt.contains('sonne') ||
        prompt.contains('jahreszeit')) {
      return _pick(task, <String>[
        'Denk an die Jahreszeiten: Fruehling, Sommer, Herbst, Winter - was passt?',
        'Schau aus dem Fenster: welche Wetter siehst du im Kopf?',
      ]);
    }
    if (prompt.contains('verkehr') || prompt.contains('ampel') ||
        prompt.contains('strasse') || prompt.contains('zebrastreifen')) {
      return _pick(task, <String>[
        'Bei der Ampel: rot = stehen, gruen = gehen. Was war die Frage?',
        'Schau immer erst links, dann rechts, dann nochmal links bevor du gehst.',
      ]);
    }
    if (prompt.contains('pflanz') || prompt.contains('blume') || prompt.contains('baum')) {
      return _pick(task, <String>[
        'Pflanzen brauchen Wasser, Sonne und Erde - das hilft beim Antworten.',
        'Denk an die Teile der Pflanze: Wurzel, Stamm/Stiel, Blatt, Blueten.',
      ]);
    }

    // ── Generischer Fallback aber variantenreich ──
    return _pick(task, <String>[
      'Lies die Frage nochmal langsam. Welche Antwort klingt richtig wenn du sie laut sagst?',
      'Schau dir jede Antwort einzeln an. Welche kannst du auf jeden Fall ausschliessen?',
      'Sprich die Frage und jede Antwort laut. Welche fuehlt sich am sichersten an?',
      'Such die wichtigsten Woerter in der Frage. Was wird wirklich gefragt?',
    ]);
  }

  /// Stabile aber variierende Auswahl: gleicher Task = gleicher Tipp,
  /// neue Task = anderer Tipp. Vermeidet, dass dasselbe Kind staendig
  /// die exakt selbe Hilfe sieht.
  String _pick(TaskInstance task, List<String> variants) {
    if (variants.isEmpty) return '';
    final h = task.taskInstanceId.hashCode ^ task.prompt.hashCode;
    return variants[h.abs() % variants.length];
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.task,
    required this.picked,
    required this.wrongAnswers,
    required this.solved,
    required this.onPick,
  });

  final TaskInstance task;
  final Object? picked;
  final Set<String> wrongAnswers;
  final bool solved;
  final ValueChanged<AnswerOption> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 460;
      final itemWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: task.options.map((option) {
          final payload = option.payload ?? option.label;
          final isPicked = picked != null && '$picked' == '$payload';
          final isWrongPicked = wrongAnswers.contains('$payload');
          final isCorrect = '$payload' == '${task.correctAnswer}';
          return SizedBox(
            width: itemWidth,
            child: _AnswerButton(
              label: option.label,
              isPicked: isPicked,
              isWrongPicked: isWrongPicked,
              isCorrect: isCorrect,
              solved: solved,
              onTap: () => onPick(option),
            ),
          );
        }).toList(),
      );
    });
  }
}

/// 2026-06-05 Iter 19/B5: Stateful Antwort-Button mit Feedback-Animation.
/// - Richtig (solved+isCorrect): kurz pulsen (Scale 1.0 -> 1.08 -> 1.0)
/// - Falsch (isWrongPicked): 3x wackeln (links/rechts) wie Kopfschuetteln
/// Animation startet einmalig wenn Status sich aendert; alte Tilt+Color
/// bleiben unveraendert.
class _AnswerButton extends StatefulWidget {
  const _AnswerButton({
    required this.label,
    required this.isPicked,
    required this.isWrongPicked,
    required this.isCorrect,
    required this.solved,
    required this.onTap,
  });

  final String label;
  final bool isPicked;
  final bool isWrongPicked;
  final bool isCorrect;
  final bool solved;
  final VoidCallback onTap;

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant _AnswerButton old) {
    super.didUpdateWidget(old);
    final justSolved =
        widget.solved && widget.isCorrect && !(old.solved && old.isCorrect);
    final justWrong = widget.isWrongPicked && !old.isWrongPicked;
    if (justSolved) {
      _pulse.forward(from: 0);
    } else if (justWrong) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;

    if (widget.solved && widget.isCorrect) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      textColor = const Color(0xFF14532D);
    } else if (widget.isWrongPicked) {
      bg = const Color(0xFFFFE4E6);
      border = const Color(0xFFF43F5E);
      textColor = const Color(0xFF881337);
    } else if (widget.solved) {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink300;
    } else {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink900;
    }

    // 2026-06-05 Iter 17/A5: LumoTiltCard 3D-Neigung um die Antwort-Cards.
    // Auf Desktop/Tablet folgt die Karte dem Finger-/Mouse-Hover (4.6 Grad),
    // auf Touch-only spring-back. Tap funktioniert weiterhin normal.
    // Disabled-State (solved/isWrongPicked) ohne Tilt damit nur aktive Cards
    // reagieren.
    final tilted = !(widget.solved || widget.isWrongPicked);
    // 2026-06-06 Iter 26: Premium-Look fuer Answer-Cards.
    // Heinz: 'Aufgaben sehen nicht eindrucksvoll aus'. Vorher flache Pills mit
    // 2px Border. Jetzt: weicher 3D-Schatten + Top-Shine (Glas-Effekt) +
    // subtiler Hintergrund-Verlauf, abgerundete Card statt komplette Pill.
    final shadowColor = widget.solved && widget.isCorrect
        ? const Color(0xFF22C55E)
        : widget.isWrongPicked
            ? const Color(0xFFF43F5E)
            : Colors.black;
    final card = AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              Color.alphaBlend(Colors.white.withOpacity(0.4), bg),
            ],
          ),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(
                  widget.solved || widget.isWrongPicked ? 0.22 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            // Subtiler Inner-Glow oben (Glas-Shine) ueber zweite Box-Shadow
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 1,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.solved && widget.isCorrect)
            const Padding(
              padding: EdgeInsets.only(right: 7),
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
            ),
          if (widget.isWrongPicked)
            const Padding(
              padding: EdgeInsets.only(right: 7),
              child: Icon(Icons.cancel_rounded, color: Color(0xFFF43F5E), size: 20),
            ),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ]),
      );
    // 2026-06-05 Iter 19/B5: Feedback-Animation um die Card legen.
    // Pulse fuer Richtig, Shake fuer Falsch. AnimatedBuilder nur wenn aktiv.
    Widget animated = card;
    animated = AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_pulse, _shake]),
      child: card,
      builder: (context, child) {
        // Pulse: 1.0 -> 1.08 -> 1.0 (sin-Kurve)
        final p = _pulse.value;
        final scale = p == 0 ? 1.0 : 1.0 + 0.08 * (1 - (2 * p - 1) * (2 * p - 1));
        // Shake: 3x links/rechts +/- 8px ueber 420ms
        final s = _shake.value;
        final dx = s == 0 ? 0.0 : 8.0 * (1 - s) * _shakeWave(s);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
    // Wenn aktive Card: in LumoTiltCard fuer 3D-Effekt + Tap-Forward.
    // Sonst nur GestureDetector (kein Tilt fuer disabled Cards).
    if (tilted) {
      return LumoTiltCard(onTap: widget.onTap, child: animated);
    }
    return GestureDetector(onTap: null, child: animated);
  }

  /// Sinus-Shake-Welle: drei volle Schwingungen ueber 0..1.
  double _shakeWave(double t) => math.sin(t * 3 * 2 * math.pi);
}

class _AdaptiveVisual extends StatelessWidget {
  const _AdaptiveVisual({required this.task, required this.picked, required this.solved});

  final TaskInstance task;
  final Object? picked;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return switch (task.visualPayload.type) {
      VisualType.dots => _DotsVisual(task: task),
      VisualType.tenOnes => _TenOnesVisual(task: task),
      VisualType.numberLine => _NumberLineVisual(task: task, picked: picked, solved: solved),
      VisualType.shape => _ShapeVisual(task: task, picked: picked, solved: solved),
      VisualType.syllables => _SyllableVisual(task: task),
      // Heinz' neue Visuals (Mai 2026):
      VisualType.quantityCompare => QuantityCompareVisual(task: task),
      VisualType.clock => ClockFaceVisual(task: task),
      VisualType.money => MoneyCoinsVisual(task: task),
      VisualType.fractionPizza => FractionPizzaVisual(task: task),
      VisualType.barChart => BarChartMiniVisual(task: task),
      VisualType.rhymeBubble => RhymeBubbleVisual(task: task),
      VisualType.syllableClap => SyllableClapVisual(task: task),
      VisualType.wordFamilyTree => WordFamilyTreeVisual(task: task),
      VisualType.sentenceBlocks => SentenceBlocksVisual(task: task),
      VisualType.wordTypeColor => WordTypeColorVisual(task: task),
      VisualType.articleCards => ArticleCardsVisual(task: task),
      // Geometrie + Groessen 2026-06-03 (Heinz: "Rechteck mit Maßen"):
      VisualType.rectangleMeasure => RectangleMeasureVisual(task: task),
      VisualType.rulerCompare => RulerCompareVisual(task: task),
      VisualType.scaleMeasure => ScaleMeasureVisual(task: task),
      // 2026-06-05 Iter 18/B1:
      VisualType.writtenArithmetic => WrittenArithmeticVisual(task: task),
      VisualType.divisionGroups => DivisionGroupsVisual(task: task),
      VisualType.numberCompare => NumberCompareVisual(task: task),
      VisualType.simpleBarChart => SimpleBarChartVisual(task: task),
      // 2026-06-05 Iter 19/B3:
      VisualType.storyStage => StoryStageVisual(task: task),
      _ => _SchoolbookFallbackVisual(task: task),
    };
  }
}

class _DotsVisual extends StatelessWidget {
  const _DotsVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final numbers = _allInts(task.prompt);
    final operation = _operationFromTask(task);
    final left = _readInt(data['left']) ?? _readInt(data['start']) ?? (numbers.isNotEmpty ? numbers[0] : 0);
    final right = _readInt(data['right']) ?? _readInt(data['takeAway']) ?? (numbers.length > 1 ? numbers[1] : 0);
    final emoji = _emojiForPrompt(task.prompt);

    if (operation == 'subtraction' && left > 10 && right > 0) {
      return SchoolbookTaskCard(
        title: 'Wegnehmen-Bild',
        subtitle: 'Erst anschauen, dann wegnehmen und zählen.',
        ribbonLabel: '−',
        helperText: 'Start: $left. Wegnehmen: $right. Ergebnis: ${task.correctAnswer}.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TwentyFrameVisual(start: left, takeAway: right),
          const SizedBox(height: 16),
          NumberLineJumpVisual(start: left, takeAway: right),
        ]),
      );
    }

    return SchoolbookTaskCard(
      title: operation == 'subtraction' ? 'Wegnehmen-Bild' : 'Mengenbild',
      subtitle: operation == 'subtraction' ? 'Streiche weg und zähle, was bleibt.' : 'Lege beide Mengen zusammen.',
      ribbonLabel: operation == 'subtraction' ? '−' : '+',
      child: emoji != null
          ? _ObjectMathVisual(left: left, right: right, operation: operation, emoji: emoji)
          : QuantityDotsVisual(left: left, operator: operation == 'subtraction' ? '-' : '+', right: right),
    );
  }
}

class _ObjectMathVisual extends StatelessWidget {
  const _ObjectMathVisual({required this.left, required this.right, required this.operation, required this.emoji});

  final int left;
  final int right;
  final String operation;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    if (operation == 'subtraction') {
      return _ObjectGroup(count: left, crossed: right, emoji: emoji);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _ObjectGroup(count: left, crossed: 0, emoji: emoji),
        Text('+', style: LumoTextStyles.heading1.copyWith(color: LumoColors.orange, fontWeight: FontWeight.w900)),
        _ObjectGroup(count: right, crossed: 0, emoji: emoji),
      ],
    );
  }
}

class _ObjectGroup extends StatelessWidget {
  const _ObjectGroup({required this.count, required this.crossed, required this.emoji});

  final int count;
  final int crossed;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final safeCount = count.clamp(0, 20).toInt();
    final safeCrossed = crossed.clamp(0, safeCount).toInt();
    if (safeCount == 0) {
      return Text('0', style: LumoTextStyles.heading2.copyWith(color: LumoColors.ink500));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(safeCount, (index) {
        final isCrossed = index < safeCrossed;
        return Stack(alignment: Alignment.center, children: [
          Opacity(
            opacity: isCrossed ? .25 : 1,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.86),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LumoColors.orange.withOpacity(.18)),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          if (isCrossed)
            Transform.rotate(
              angle: -.68,
              child: Container(width: 38, height: 3, color: LumoColors.ink700.withOpacity(.72)),
            ),
        ]);
      }),
    );
  }
}

class _TenOnesVisual extends StatelessWidget {
  const _TenOnesVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final tens = (_readInt(data['tens']) ?? 0).clamp(0, 9).toInt();
    final ones = (_readInt(data['ones']) ?? 0).clamp(0, 9).toInt();
    final target = tens * 10 + ones;
    return SchoolbookTaskCard(
      title: 'Zehner und Einer',
      subtitle: 'Stangen sind Zehner, Punkte sind Einer.',
      ribbonLabel: '$target',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(tens, (_) => Container(
                width: 18,
                height: 72,
                decoration: BoxDecoration(color: LumoColors.orange.withOpacity(.78), borderRadius: BorderRadius.circular(LumoRadius.sm)),
              )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(ones, (_) => Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: LumoColors.gold.withOpacity(.85), shape: BoxShape.circle),
              )),
        ),
      ]),
    );
  }
}

class _NumberLineVisual extends StatelessWidget {
  const _NumberLineVisual({required this.task, required this.picked, required this.solved});

  final TaskInstance task;
  final Object? picked;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final start = _readInt(data['start']);
    final takeAway = _readInt(data['takeAway']);
    if (start != null && takeAway != null && start > 0 && takeAway > 0) {
      return SchoolbookTaskCard(
        title: 'Zahlenstrahl-Sprung',
        subtitle: 'Springe Schritt für Schritt zurück.',
        ribbonLabel: '0–20',
        child: NumberLineJumpVisual(start: start, takeAway: takeAway),
      );
    }
    final numbers = task.options.map((option) => _readInt(option.payload ?? option.label)).whereType<int>().toSet().toList()..sort();
    if (numbers.length < 2) return const SizedBox.shrink();
    final answer = _readInt(task.correctAnswer);
    final pickedNumber = picked == null ? null : _readInt(picked);
    return SchoolbookTaskCard(
      title: 'Zahlenstrahl',
      subtitle: 'Suche die Zahl auf der Linie.',
      ribbonLabel: 'Linie',
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: numbers.map((number) {
        final selected = pickedNumber == number;
        final correct = solved && number == answer;
        return Container(
          width: correct || selected ? 42 : 34,
          height: correct || selected ? 42 : 34,
          decoration: BoxDecoration(
            color: correct ? const Color(0xFF22C55E) : selected ? LumoColors.orange : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: correct ? const Color(0xFF22C55E) : LumoColors.orange.withOpacity(.55), width: 2),
          ),
          child: Center(
            child: Text('$number', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: correct || selected ? Colors.white : LumoColors.ink900)),
          ),
        );
      }).toList()),
    );
  }
}

class _ShapeVisual extends StatelessWidget {
  const _ShapeVisual({required this.task, required this.picked, required this.solved});

  final TaskInstance task;
  final Object? picked;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    // Premium-Formen mit echtem CustomPainter statt nur Material-Icon.
    // Jede Form bekommt eigene Farbe + Schatten + Verlauf.
    const shapes = <String, _ShapeKind>{
      'Dreieck': _ShapeKind.triangle,
      'Kreis': _ShapeKind.circle,
      'Quadrat': _ShapeKind.square,
      'Rechteck': _ShapeKind.rectangle,
    };
    const colors = <String, Color>{
      'Dreieck': Color(0xFFFFB800),
      'Kreis': Color(0xFF60A5FA),
      'Quadrat': Color(0xFFF472B6),
      'Rechteck': Color(0xFF34D399),
    };
    return SchoolbookTaskCard(
      title: 'Formenhilfe',
      subtitle: 'Schau genau: Welche Form passt?',
      ribbonLabel: 'Form',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: shapes.entries.map((entry) {
          final selected = '$picked' == entry.key;
          final correct = solved && '${task.correctAnswer}' == entry.key;
          final shapeColor = colors[entry.key] ?? LumoColors.orange;
          return Container(
            width: 110,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: correct
                    ? const [Color(0xFFDCFCE7), Colors.white]
                    : selected
                        ? [LumoColors.orangeSurface, Colors.white]
                        : [Colors.white, shapeColor.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(LumoRadius.lg),
              border: Border.all(
                color: correct
                    ? const Color(0xFF22C55E)
                    : selected
                        ? LumoColors.orange
                        : shapeColor.withOpacity(0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: shapeColor.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: _ShapePainter(
                      kind: entry.value,
                      color: correct ? const Color(0xFF22C55E) : shapeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.key,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _ShapeKind { triangle, circle, square, rectangle }

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.kind, required this.color});
  final _ShapeKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withOpacity(0.65)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = color.withOpacity(0.85)
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case _ShapeKind.triangle:
        final path = Path()
          ..moveTo(w / 2, h * 0.10)
          ..lineTo(w * 0.90, h * 0.88)
          ..lineTo(w * 0.10, h * 0.88)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, stroke);
        break;
      case _ShapeKind.circle:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.40, paint);
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.40, stroke);
        break;
      case _ShapeKind.square:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.14, h * 0.14, w * 0.72, h * 0.72),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, stroke);
        break;
      case _ShapeKind.rectangle:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.08, h * 0.25, w * 0.84, h * 0.50),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.kind != kind || old.color != color;
}

class _SyllableVisual extends StatelessWidget {
  const _SyllableVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final word = task.visualPayload.data['word']?.toString() ?? task.parameters['word']?.toString() ?? '';
    final rawSyllables = task.visualPayload.data['syllables'];
    final syllables = rawSyllables is List ? rawSyllables.map((e) => e.toString()).toList(growable: false) : null;
    return SchoolbookTaskCard(
      title: 'Silben klatschen',
      subtitle: 'Sprich das Wort langsam und klatsche bei jeder Silbe.',
      ribbonLabel: 'Silben',
      accentColor: LumoColors.purple,
      child: SyllableChipRow(word: word.isEmpty ? 'Wort' : word, syllables: syllables, accentColor: LumoColors.purple),
    );
  }
}

class _SchoolbookFallbackVisual extends StatelessWidget {
  const _SchoolbookFallbackVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final visual = task.parameters['visual']?.toString() ?? '';
    final data = task.visualPayload.data;

    if (visual == 'number_house') {
      final target = _readInt(data['target']) ?? _readInt(task.correctAnswer) ?? 10;
      final left = _readInt(data['left']) ?? 0;
      final right = _readInt(data['right']) ?? _readInt(task.correctAnswer) ?? 0;
      return SchoolbookTaskCard(
        title: 'Rechenhaus',
        subtitle: 'Die Dachzahl ist das Ganze. Die Zimmer ergeben zusammen das Dach.',
        ribbonLabel: '$target',
        helperText: 'Schau zuerst auf das Dach. Dann suchst du die Partnerzahl zu $left.',
        child: NumberHouseVisual(target: target, rows: <List<int>>[<int>[left, right], <int>[0, target]], missingIndex: 1),
      );
    }

    if (visual == 'sound_choice') {
      final word = data['word']?.toString() ?? task.prompt.replaceFirst('St oder Sp?', '').trim();
      return SchoolbookTaskCard(
        title: 'St oder Sp?',
        subtitle: 'Sprich den Anfang langsam und höre genau hin.',
        ribbonLabel: 'Laut',
        accentColor: LumoColors.purple,
        child: SoundChoiceCard(word: word, choices: const <String>['St', 'Sp']),
      );
    }

    if (visual == 'writing_line') {
      final target = data['target']?.toString() ?? '${task.correctAnswer}';
      final word = data['word']?.toString() ?? target;
      return SchoolbookTaskCard(
        title: 'Schreib wie im Heft',
        subtitle: 'Lies genau und schreibe das passende Wort.',
        ribbonLabel: 'Wort',
        accentColor: LumoColors.purple,
        child: WritingLineBox(placeholder: word, cells: target.length.clamp(3, 10).toInt()),
      );
    }

    final numbers = _allInts(task.prompt);
    if (task.subject == LearningSubject.mathematik && numbers.length >= 2) {
      return _DotsVisual(task: task);
    }

    final unitFromParams = task.parameters['unit']?.toString() ?? '';
    if (task.subject == LearningSubject.deutsch && unitFromParams == 'Satz bauen' && task.correctAnswer is String) {
      final words = task.correctAnswer.toString().replaceAll(RegExp(r'[.!?]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList(growable: false);
      if (words.length >= 2) {
        return SchoolbookTaskCard(
          title: 'Satz aus Wortkarten',
          subtitle: 'So sieht der richtige Satz aus. Nun finde ihn unten.',
          ribbonLabel: 'Satz',
          accentColor: LumoColors.blue,
          child: WordCardRow(words: words, accentColor: LumoColors.blue),
        );
      }
    }

    if (task.subject == LearningSubject.deutsch && (unitFromParams.startsWith('Anfangslaut') || unitFromParams.startsWith('Endlaut'))) {
      final word = task.visualPayload.data['word']?.toString() ?? task.parameters['word']?.toString() ?? task.correctAnswer.toString();
      final highlight = unitFromParams.startsWith('End') ? 'end' : 'start';
      return SchoolbookTaskCard(
        title: highlight == 'end' ? 'Endlaut hören' : 'Anfangslaut hören',
        subtitle: highlight == 'end' ? 'Sprich das Wort und höre genau auf den letzten Laut.' : 'Sprich das Wort und höre genau auf den ersten Laut.',
        ribbonLabel: 'Laut',
        accentColor: LumoColors.purple,
        child: SoundHighlightWord(word: word, highlight: highlight, color: LumoColors.purple),
      );
    }

    return const SizedBox.shrink();
  }
}

String _operationFromTask(TaskInstance task) {
  final dataOperation = task.visualPayload.data['operation']?.toString();
  if (dataOperation == 'subtraction' || dataOperation == 'addition') return dataOperation!;
  final p = task.prompt.toLowerCase();
  if (p.contains('-') || p.contains('isst') || p.contains('iszt') || p.contains('weg') || p.contains('bleiben') || p.contains('übrig') || p.contains('gibt') || p.contains('verliert')) {
    return 'subtraction';
  }
  return 'addition';
}

String? _emojiForPrompt(String prompt) {
  final p = prompt.toLowerCase();
  if (p.contains('schokolade')) return '🍫';
  if (p.contains('apfel') || p.contains('äpfel')) return '🍎';
  if (p.contains('banane')) return '🍌';
  if (p.contains('birne')) return '🍐';
  if (p.contains('keks')) return '🍪';
  if (p.contains('ball')) return '⚽';
  if (p.contains('stern')) return '⭐';
  if (p.contains('blume')) return '🌸';
  return null;
}

List<int> _allInts(String value) {
  return RegExp(r'-?\d+').allMatches(value).map((match) => int.parse(match.group(0)!)).toList(growable: false);
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  final match = RegExp(r'-?\d+').firstMatch('$value');
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}
