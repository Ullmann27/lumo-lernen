import 'lumo_learning_domain.dart';

/// Local, deterministic feedback engine for Lumo.
///
/// This is intentionally not an open child chat. It is a guarded learning
/// dialogue algorithm that varies feedback, tracks interaction patterns and
/// produces context-aware tips from the current session.
class LumoLearningFeedbackEngine {
  final Map<String, int> _attemptsByUnit = <String, int>{};
  final Map<String, int> _correctByUnit = <String, int>{};
  final Map<String, int> _wrongByUnit = <String, int>{};
  final List<String> _recentPhraseIds = <String>[];
  final List<String> _recentTips = <String>[];

  int _interactionCount = 0;
  int _correctStreak = 0;
  int _wrongStreak = 0;
  int _helpCount = 0;
  int _fastCorrectCount = 0;
  int _slowAnswerCount = 0;
  int _writingAttempts = 0;

  LumoFeedbackTurn record(LumoInteractionEvent event) {
    _interactionCount++;
    _attemptsByUnit[event.unit] = (_attemptsByUnit[event.unit] ?? 0) + 1;

    if (event.correct) {
      _correctByUnit[event.unit] = (_correctByUnit[event.unit] ?? 0) + 1;
      _correctStreak++;
      _wrongStreak = 0;
    } else {
      _wrongByUnit[event.unit] = (_wrongByUnit[event.unit] ?? 0) + 1;
      _wrongStreak++;
      _correctStreak = 0;
    }

    if (event.helpUsed) _helpCount++;
    if (event.responseTimeMs < 4500 && event.correct) _fastCorrectCount++;
    if (event.responseTimeMs > 18000) _slowAnswerCount++;
    if (event.handwritingScore != null) _writingAttempts++;

    final tone = _toneFor(event);
    final title = _titleFor(event, tone);
    final message = _messageFor(event, tone);
    final tip = _tipFor(event, tone);
    final rewardLabel = _rewardLabelFor(event, tone);
    final badgeLabel = _badgeLabelFor(event, tone);

    return LumoFeedbackTurn(
      title: title,
      spokenText: _shortenForSpeech(message),
      cardMessage: message,
      learningTip: tip,
      rewardLabel: rewardLabel,
      badgeLabel: badgeLabel,
      tone: tone,
      autoAdvanceDelayMs: event.correct ? _autoAdvanceDelay(event) : 0,
    );
  }

  LumoFeedbackTone _toneFor(LumoInteractionEvent event) {
    if (event.handwritingScore != null) return LumoFeedbackTone.handwriting;
    if (!event.correct && _wrongStreak >= 2) return LumoFeedbackTone.rescue;
    if (!event.correct) return LumoFeedbackTone.coaching;
    if (_correctStreak >= 4) return LumoFeedbackTone.streak;
    if (event.masteryAfter > event.masteryBefore + .035) return LumoFeedbackTone.improvement;
    if (event.responseTimeMs < 4500) return LumoFeedbackTone.fastFocus;
    return LumoFeedbackTone.encouraging;
  }

  String _titleFor(LumoInteractionEvent event, LumoFeedbackTone tone) {
    return switch (tone) {
      LumoFeedbackTone.handwriting => event.correct ? 'Sauber gezeichnet!' : 'Die Form braucht noch Ruhe',
      LumoFeedbackTone.rescue => 'Wir machen es kleiner',
      LumoFeedbackTone.coaching => 'Guter Versuch',
      LumoFeedbackTone.streak => 'Du bist im Lauf!',
      LumoFeedbackTone.improvement => 'Das wird besser!',
      LumoFeedbackTone.fastFocus => 'Schnell erkannt!',
      LumoFeedbackTone.encouraging => 'Richtig gelöst!',
    };
  }

  String _messageFor(LumoInteractionEvent event, LumoFeedbackTone tone) {
    final subject = event.subject;
    final unit = event.unit;
    final variants = switch (tone) {
      LumoFeedbackTone.handwriting => event.correct
          ? <String>[
              'Ich sehe: Du hast die Spur bewusst geführt. Genau so wird Schreiben sicherer.',
              'Das war ein guter Schreibversuch. Start, Richtung und Form werden immer klarer.',
              'Deine Hand hat heute gut gearbeitet. Langsam zeichnen hilft deinem Gehirn beim Merken.',
            ]
          : <String>[
              'Fast. Beim Schreiben zählt nicht nur das Ergebnis, sondern auch der Weg der Linie.',
              'Die Form ist noch nicht ganz fertig. Starte ruhig am Punkt und fahre bis zum Ende.',
              'Wir üben das nochmal kleiner. Deine Hand darf langsam und sauber fahren.',
            ],
      LumoFeedbackTone.rescue => <String>[
        'Stopp, kein Stress. Ich sehe, dass $unit gerade schwer ist. Wir nehmen gleich einen kleineren Schritt.',
        'Das ist ein Übe-Signal, kein Fehler-Drama. Lumo zeigt dir den Denkweg nochmal einfacher.',
        'Dein Gehirn braucht hier noch eine Brücke. Wir gehen langsam: schauen, teilen, dann antworten.',
      ],
      LumoFeedbackTone.coaching => <String>[
        'Fast. Ich glaube, der Fehler ist beim Zwischenschritt passiert. Wir schauen direkt auf den Weg.',
        'Du hast gearbeitet, aber ein Schritt ist verrutscht. Das kann man gut trainieren.',
        'Noch nicht richtig, aber wertvoll: Jetzt wissen wir genauer, was Lumo mit dir üben soll.',
      ],
      LumoFeedbackTone.streak => <String>[
        'Das ist schon die ${_correctStreak}. richtige Antwort in Folge. Du bleibst richtig konzentriert.',
        'Starke Serie! Du löst nicht nur, du erkennst das Muster immer schneller.',
        'Lumo merkt sich: $unit klappt gerade richtig gut. Wir dürfen bald etwas schwerer werden.',
      ],
      LumoFeedbackTone.improvement => <String>[
        'Sehr gut. Bei $unit bist du gerade ein Stück sicherer geworden.',
        'Das war nicht nur richtig, das war Fortschritt. Lumo merkt: Dieser Lernweg hilft dir.',
        'Genau so wächst Können: kleiner Schritt, richtige Entscheidung, besseres Muster.',
      ],
      LumoFeedbackTone.fastFocus => <String>[
        'Schnell und richtig. Du hast das Muster sofort erkannt.',
        'Das ging flott. Wichtig: lieber ruhig bleiben als nur raten.',
        'Dein Kopf war schnell. Lumo prüft weiter, ob es wirklich sicher sitzt.',
      ],
      LumoFeedbackTone.encouraging => <String>[
        'Richtig. Du hast die Aufgabe sauber gelöst.',
        'Ja, genau. Du bist Schritt für Schritt zum Ergebnis gekommen.',
        'Gut gemacht. Das passt zu deinem Lernweg in $subject.',
        'Richtig erkannt. Lumo merkt sich, dass diese Art Aufgabe besser klappt.',
      ],
    };
    return _pick('msg.${tone.name}.${event.unit}.${event.taskIndex}', variants);
  }

  String _tipFor(LumoInteractionEvent event, LumoFeedbackTone tone) {
    final prompt = event.prompt.toLowerCase();
    final unit = event.unit.toLowerCase();
    final errors = event.errorTypes;

    final tips = <String>[];
    if (prompt.contains('-') && (prompt.contains('11') || prompt.contains('12') || prompt.contains('13') || prompt.contains('14') || prompt.contains('15') || prompt.contains('16') || prompt.contains('17') || prompt.contains('18') || prompt.contains('19'))) {
      tips.add('Lerntipp: Bei Minus über 10 zuerst bis zur 10 gehen, dann den Rest wegnehmen.');
    }
    if (unit.contains('rechen')) {
      tips.add('Lerntipp: Beim Rechenhaus sagt das Dach, wie viel beide Zimmer zusammen ergeben.');
    }
    if (unit.contains('blitz')) {
      tips.add('Lerntipp: Bei Blitzlicht nicht hetzen. Erst das Muster sehen, dann schreiben.');
    }
    if (unit.contains('st oder sp') || prompt.contains('st oder sp')) {
      tips.add('Lerntipp: Sprich den Anfang langsam. St klingt anders als Sp.');
    }
    if (unit.contains('mehrzahl')) {
      tips.add('Lerntipp: Sprich Einzahl und Mehrzahl nacheinander. Oft verändert sich der Klang in der Mitte.');
    }
    if (unit.contains('silben')) {
      tips.add('Lerntipp: Klatsche das Wort langsam. Jeder Klatscher ist eine Silbe.');
    }
    if (errors.contains(ErrorType.countingError)) {
      tips.add('Lerntipp: Du warst nur einen Schritt daneben. Zeige jede Zahl mit dem Finger.');
    }
    if (errors.contains(ErrorType.plusMinusConfusion)) {
      tips.add('Lerntipp: Achte zuerst auf das Zeichen. Plus legt dazu, Minus nimmt weg.');
    }
    if (event.handwritingScore != null && event.handwritingScore! < .72) {
      tips.add('Lerntipp: Beim Schreiben langsam starten, Richtung halten und die Form ganz fertig machen.');
    }
    if (_wrongStreak >= 2) {
      tips.add('Lerntipp: Jetzt kommt eine leichtere Erklärung. Erst verstehen, dann wieder schneller werden.');
    }
    if (_helpCount >= 3 && event.correct) {
      tips.add('Lerntipp: Hilfe benutzen ist erlaubt. Ziel ist, dass du den nächsten Schritt selbst erkennst.');
    }
    if (tips.isEmpty) {
      tips.addAll(<String>[
        'Lerntipp: Lies zuerst die Aufgabe, dann schaue auf das Bild, dann erst antworten.',
        'Lerntipp: Wenn du unsicher bist, mach die Aufgabe kleiner und suche den ersten Schritt.',
        'Lerntipp: Dein Fehler zeigt Lumo, welche Übung als Nächstes gut passt.',
      ]);
    }
    return _pick('tip.${event.unit}.${event.taskIndex}.${tone.name}', tips, recent: _recentTips);
  }

  String _rewardLabelFor(LumoInteractionEvent event, LumoFeedbackTone tone) {
    final labels = <String>[];
    if (event.correct) labels.add('Belohnung: richtige Lösung');
    labels.add('Belohnung: Aufgabe bearbeitet');
    if (event.helpUsed) labels.add('Belohnung: Hilfe sinnvoll genutzt');
    if (tone == LumoFeedbackTone.improvement) labels.add('Belohnung: echte Verbesserung');
    if (tone == LumoFeedbackTone.streak) labels.add('Belohnung: Konzentrations-Serie');
    if (event.handwritingScore != null) labels.add('Belohnung: Schreibversuch abgeschlossen');
    if (!event.correct && event.responseTimeMs > 7000) labels.add('Belohnung: drangeblieben trotz schwerer Aufgabe');
    return _pick('reward.${event.taskIndex}.${tone.name}', labels);
  }

  String? _badgeLabelFor(LumoInteractionEvent event, LumoFeedbackTone tone) {
    if (_correctStreak == 3) return 'Mini-Abzeichen: 3er-Fuchsserie';
    if (_correctStreak == 5) return 'Mini-Abzeichen: Konzentrationsfuchs';
    if (_wrongStreak == 0 && (_wrongByUnit[event.unit] ?? 0) > 0 && event.correct) return 'Mini-Abzeichen: Fehler verbessert';
    if (_writingAttempts == 3) return 'Mini-Abzeichen: Schreibhand trainiert';
    if (_fastCorrectCount == 4) return 'Mini-Abzeichen: Blitzblick';
    if (_slowAnswerCount == 3 && event.correct) return 'Mini-Abzeichen: Ruhe bewahrt';
    return null;
  }

  int _autoAdvanceDelay(LumoInteractionEvent event) {
    if (event.handwritingScore != null) return 2100;
    if (_correctStreak >= 3) return 1800;
    if (event.responseTimeMs < 4500) return 1400;
    return 1700;
  }

  String _pick(String seed, List<String> values, {List<String>? recent}) {
    if (values.isEmpty) return '';
    final memory = recent ?? _recentPhraseIds;
    final available = values.where((value) => !memory.contains(value)).toList();
    final pool = available.isEmpty ? values : available;
    final index = (seed.hashCode + _interactionCount + _correctStreak * 3 + _wrongStreak * 5).abs() % pool.length;
    final picked = pool[index];
    memory.add(picked);
    while (memory.length > 10) {
      memory.removeAt(0);
    }
    return picked;
  }

  String _shortenForSpeech(String value) {
    if (value.length <= 120) return value;
    final sentenceEnd = value.indexOf('.', 60);
    if (sentenceEnd > 0 && sentenceEnd < 120) return value.substring(0, sentenceEnd + 1);
    return '${value.substring(0, 116)}...';
  }
}

class LumoInteractionEvent {
  const LumoInteractionEvent({
    required this.subject,
    required this.unit,
    required this.prompt,
    required this.correctAnswer,
    required this.givenAnswer,
    required this.correct,
    required this.helpUsed,
    required this.responseTimeMs,
    required this.errorTypes,
    required this.masteryBefore,
    required this.masteryAfter,
    required this.taskIndex,
    required this.totalTasks,
    required this.sessionKind,
    this.handwritingScore,
  });

  final String subject;
  final String unit;
  final String prompt;
  final Object correctAnswer;
  final Object givenAnswer;
  final bool correct;
  final bool helpUsed;
  final int responseTimeMs;
  final List<ErrorType> errorTypes;
  final double masteryBefore;
  final double masteryAfter;
  final int taskIndex;
  final int totalTasks;
  final String sessionKind;
  final double? handwritingScore;
}

class LumoFeedbackTurn {
  const LumoFeedbackTurn({
    required this.title,
    required this.spokenText,
    required this.cardMessage,
    required this.learningTip,
    required this.rewardLabel,
    required this.tone,
    required this.autoAdvanceDelayMs,
    this.badgeLabel,
  });

  final String title;
  final String spokenText;
  final String cardMessage;
  final String learningTip;
  final String rewardLabel;
  final String? badgeLabel;
  final LumoFeedbackTone tone;
  final int autoAdvanceDelayMs;
}

enum LumoFeedbackTone {
  encouraging,
  fastFocus,
  improvement,
  streak,
  coaching,
  rescue,
  handwriting,
}
