import '../learning/lumo_learning_domain.dart';
import 'lumo_agent_domain.dart';

class LumoOrchestrator {
  LumoOrchestrator({InterventionEngine? interventionEngine})
      : interventionEngine = interventionEngine ?? const InterventionEngine();

  final InterventionEngine interventionEngine;
  final Map<String, AgentSessionMemory> _memoryByChild = <String, AgentSessionMemory>{};

  AgentDecision handle(AgentEvent event) {
    final memory = _memoryByChild.putIfAbsent(event.childId, () => AgentSessionMemory(childId: event.childId));
    memory.record(event);

    if (event.type == AgentEventType.readingErrorDetected || event.type == AgentEventType.readingSentenceHeard) {
      return interventionEngine.readingDecision(event: event, memory: memory);
    }

    if (event.type == AgentEventType.taskAnswered || event.type == AgentEventType.writingSubmitted) {
      return _taskDecision(event, memory);
    }

    if (event.type == AgentEventType.tutoringStepAnswered) {
      return _tutoringDecision(event, memory);
    }

    if (event.type == AgentEventType.scanImported) {
      return AgentDecision(
        primary: const AgentAction(
          type: AgentActionType.createRecommendation,
          tone: AgentTone.focused,
          message: 'Ich habe die Aufgabe erkannt und erstelle daraus einen kurzen Trainingsblock.',
        ),
        memoryTags: const <String>['scan_imported'],
      );
    }

    return AgentDecision(
      primary: AgentAction(
        type: AgentActionType.continueFlow,
        tone: AgentTone.warm,
        message: memory.pickFresh('continue.${event.type}', const <String>[
          'Ich begleite dich Schritt fuer Schritt.',
          'Wir bleiben ruhig und machen weiter.',
          'Lumo schaut mit und merkt sich, was dir hilft.',
        ]),
      ),
    );
  }

  AgentDecision _taskDecision(AgentEvent event, AgentSessionMemory memory) {
    if (event.correct == true) {
      final streak = memory.correctStreak;
      final action = AgentAction(
        type: streak >= 3 ? AgentActionType.increaseDifficulty : AgentActionType.continueFlow,
        tone: streak >= 3 ? AgentTone.celebrating : AgentTone.warm,
        message: memory.pickFresh('correct.$streak.${event.unit}', <String>[
          'Richtig. Ich merke: Dieser Schritt klappt schon besser.',
          'Gut geloest. Lumo speichert das als sicheren Lernmoment.',
          'Das war sauber gedacht. Wir pruefen gleich, ob es stabil bleibt.',
          if (streak >= 3) 'Starke Serie. Ich gebe dir bald eine etwas spannendere Aufgabe.',
        ]),
      );
      return AgentDecision(
        primary: action,
        secondary: const <AgentAction>[
          AgentAction(type: AgentActionType.grantReward, tone: AgentTone.celebrating, message: 'Belohnung fuer richtiges Arbeiten und Dranbleiben.'),
        ],
      );
    }

    final action = memory.wrongStreak >= 2
        ? AgentAction(
            type: AgentActionType.reduceDifficulty,
            tone: AgentTone.calming,
            message: memory.pickFresh('rescue.${event.unit}', const <String>[
              'Ich mache den naechsten Schritt kleiner. Erst verstehen, dann weiter.',
              'Das ist ein Hinweis fuer Lumo: Wir brauchen eine klarere Hilfe.',
              'Kein Stress. Ich zeige dir den Weg mit einem einfacheren Bild.',
            ]),
          )
        : AgentAction(
            type: AgentActionType.showHint,
            tone: AgentTone.coaching,
            message: memory.pickFresh('hint.${event.unit}', const <String>[
              'Fast. Ein Zwischenschritt ist verrutscht.',
              'Guter Versuch. Wir schauen auf das Zeichen und den ersten Schritt.',
              'Noch nicht richtig, aber jetzt weiss Lumo genauer, was wir ueben.',
            ]),
          );

    return AgentDecision(
      primary: action,
      memoryTags: <String>['needs_repetition:${event.unit ?? event.skillId?.value ?? 'unknown'}'],
      recommendationSkillIds: event.skillId == null ? const <SkillId>[] : <SkillId>[event.skillId!],
    );
  }

  AgentDecision _tutoringDecision(AgentEvent event, AgentSessionMemory memory) {
    if (event.correct == true) {
      return AgentDecision(
        primary: AgentAction(
          type: AgentActionType.continueFlow,
          tone: AgentTone.warm,
          message: memory.pickFresh('tutor.ok.${event.unit}', const <String>[
            'Der Schritt sitzt besser. Wir nehmen den naechsten kleinen Schritt.',
            'Gut. Du hast nicht geraten, sondern den Weg erkannt.',
            'Das war ein Versteh-Schritt. Genau darum geht es in der Nachhilfe.',
          ]),
        ),
      );
    }
    return AgentDecision(
      primary: AgentAction(
        type: AgentActionType.showSchoolbookVisual,
        tone: AgentTone.coaching,
        message: memory.pickFresh('tutor.help.${event.unit}', const <String>[
          'Ich zeige es dir jetzt anders: mit Bild, kleiner Zahl und einem Beispiel.',
          'Wir bleiben bei diesem Schritt. Noch keine neue schwere Aufgabe.',
          'Lumo baut eine Bruecke: erst Beispiel, dann du.',
        ]),
      ),
      secondary: const <AgentAction>[
        AgentAction(type: AgentActionType.reduceDifficulty, tone: AgentTone.calming, message: 'Hilfestufe wird erhoeht.'),
      ],
    );
  }
}

class InterventionEngine {
  const InterventionEngine();

  AgentDecision readingDecision({required AgentEvent event, required AgentSessionMemory memory}) {
    final attempt = (event.payload['attemptNumber'] as int?) ?? 1;
    final sentence = event.payload['sentence']?.toString() ?? 'diesen Satz';
    final word = event.payload['word']?.toString();

    if (event.correct == true) {
      return AgentDecision(
        primary: AgentAction(
          type: AgentActionType.continueFlow,
          tone: AgentTone.warm,
          message: memory.pickFresh('reading.ok.$sentence', const <String>[
            'Gut gelesen. Lies jetzt hier weiter.',
            'Das war ruhig und klar. Weiter geht es mit dem naechsten Satz.',
            'Sehr gut. Lumo bleibt dabei und hoert weiter zu.',
          ]),
        ),
      );
    }

    if (attempt <= 1) {
      return AgentDecision(
        primary: AgentAction(
          type: AgentActionType.repeatSentence,
          tone: AgentTone.coaching,
          message: word == null
              ? 'Stopp, kleiner Lesefuchs. Lies diesen Satz bitte noch einmal langsam.'
              : 'Stopp, kleiner Lesefuchs. Das Wort "$word" schauen wir nochmal an. Lies ab dort erneut.',
          payload: <String, Object?>{'repeat': sentence, 'attemptNumber': attempt + 1},
        ),
      );
    }

    if (attempt == 2) {
      return AgentDecision(
        primary: AgentAction(
          type: AgentActionType.showSyllables,
          tone: AgentTone.calming,
          message: word == null
              ? 'Ich mache den Satz leichter und markiere die Silben. Dann liest du ihn nochmal.'
              : 'Ich teile "$word" in Silben. Danach probierst du es noch einmal.',
          payload: <String, Object?>{'repeat': sentence, 'attemptNumber': 3, if (word != null) 'word': word},
        ),
      );
    }

    return AgentDecision(
      primary: AgentAction(
        type: AgentActionType.continueFlow,
        tone: AgentTone.calming,
        message: word == null
            ? 'Wir gehen kontrolliert weiter. Ich merke mir diesen Satz fuer spaeter.'
            : 'Wir gehen weiter. Ich merke mir "$word" als Uebungswort fuer spaeter.',
        payload: <String, Object?>{'storeProblemWord': word, 'repeatLater': true},
      ),
      memoryTags: <String>[if (word != null) 'problem_word:$word'],
    );
  }
}
