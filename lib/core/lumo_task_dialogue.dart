import 'lumo_child_speech_normalizer.dart';

/// Bounded, rule-based dialogue over content supplied by the active lesson.
/// This is not a language model. It cannot grade, save progress or give rewards.
enum LumoTaskDialogueIntent {
  help,
  why,
  repeat,
  slower,
  alternative,
  show,
  step,
  reference,
  answer,
  correction,
  stop,
  alone,
  clarification,
  identity,
  concern,
  unrelated,
}

enum LumoTaskDialogueGesture { lookAtChild, point, think, encourage, neutral }

enum LumoTaskAnswerFormat { none, choice, integer, word, freeText }

class LumoTaskDialogueObject {
  const LumoTaskDialogueObject({
    required this.id,
    required this.label,
    this.groupId = '',
    this.selected = false,
  });

  final String id;
  final String label;
  final String groupId;
  final bool selected;
}

/// Authored by the task adapter, never by a remote model. The help cutoff and
/// visible-object binding apply to every variant, including "why" and repeat.
class LumoReviewedTaskExplanation {
  LumoReviewedTaskExplanation({
    required this.id,
    required this.text,
    this.why,
    this.alternativeText,
    List<String> objectIds = const [],
    this.stepId = '',
    this.stepNumber = 0,
    this.minimumHelpLevel = 0,
    List<String> keywords = const [],
    List<String> speechParts = const [],
  })  : objectIds = List.unmodifiable(objectIds),
        keywords = List.unmodifiable(keywords),
        speechParts = List.unmodifiable(speechParts);

  final String id;
  final String text;
  final String? why;
  final String? alternativeText;
  final List<String> objectIds;
  final String stepId;
  final int stepNumber;
  final int minimumHelpLevel;
  final List<String> keywords;
  final List<String> speechParts;
}

/// A short-lived read-only view. Correct answers and reward callbacks do not
/// belong here. [acceptingAnswer] is independent of explanation availability:
/// a demonstration can be discussed even when it has no answer control.
class LumoTaskDialogueSnapshot {
  LumoTaskDialogueSnapshot({
    required this.sessionId,
    required this.taskId,
    required this.stepId,
    required this.revision,
    required this.learningGoal,
    required this.prompt,
    List<LumoTaskDialogueObject> objects = const [],
    List<String> selectedObjectIds = const [],
    List<LumoReviewedTaskExplanation> explanations = const [],
    List<String> answerChoices = const [],
    this.answerFormat = LumoTaskAnswerFormat.choice,
    this.helpLevel = 0,
    this.isAssessment = false,
    this.acceptingAnswer = true,
    this.lastAnswer,
    this.lastCorrect,
  })  : objects = List.unmodifiable(objects),
        selectedObjectIds = List.unmodifiable(selectedObjectIds),
        explanations = List.unmodifiable(explanations),
        answerChoices = List.unmodifiable(answerChoices);

  final String sessionId;
  final String taskId;
  final String stepId;
  final int revision;
  final String learningGoal;
  final String prompt;
  final List<LumoTaskDialogueObject> objects;
  final List<String> selectedObjectIds;
  final List<LumoReviewedTaskExplanation> explanations;
  final List<String> answerChoices;
  final LumoTaskAnswerFormat answerFormat;
  final int helpLevel;
  final bool isAssessment;
  final bool acceptingAnswer;
  final String? lastAnswer;
  final bool? lastCorrect;

  bool containsReply(LumoTaskDialogueReply reply) =>
      reply.sessionId == sessionId &&
      reply.taskId == taskId &&
      reply.stepId == stepId &&
      reply.revision == revision;
}

class LumoTaskDialogueReply {
  LumoTaskDialogueReply({
    required this.sessionId,
    required this.taskId,
    required this.stepId,
    required this.revision,
    required this.text,
    required this.intent,
    List<String> targetObjectIds = const [],
    this.gesture = LumoTaskDialogueGesture.lookAtChild,
    this.needsConfirmation = false,
    this.draftAnswer,
    this.explanationId,
    List<String> speechParts = const [],
    this.speechRateMultiplier = 1,
    this.handled = true,
  })  : targetObjectIds = List.unmodifiable(targetObjectIds),
        speechParts = List.unmodifiable(speechParts);

  final String sessionId;
  final String taskId;
  final String stepId;
  final int revision;
  final String text;
  final LumoTaskDialogueIntent intent;
  final List<String> targetObjectIds;
  final LumoTaskDialogueGesture gesture;
  final bool needsConfirmation;
  final String? draftAnswer;
  final String? explanationId;
  final List<String> speechParts;
  final double speechRateMultiplier;
  final bool handled;

  String get source => 'local_reviewed_dialogue';
  bool get shouldStopSpeech =>
      intent == LumoTaskDialogueIntent.stop ||
      intent == LumoTaskDialogueIntent.alone;
  bool get continueListening => intent != LumoTaskDialogueIntent.alone;
}

class LumoTaskDialogueEngine {
  const LumoTaskDialogueEngine();
  static const _normalizer = LumoChildSpeechNormalizer();

  LumoTaskDialogueReply respond({
    required String input,
    required LumoTaskDialogueSnapshot snapshot,
    LumoTaskDialogueReply? previousReply,
    double? recognitionConfidence,
    bool isFinal = true,
  }) {
    final q = _normalizer.normalizeText(input);
    LumoTaskDialogueReply reply(
      String text,
      LumoTaskDialogueIntent intent, {
      List<String> targets = const [],
      LumoTaskDialogueGesture gesture = LumoTaskDialogueGesture.lookAtChild,
      bool needsConfirmation = false,
      String? draftAnswer,
      LumoReviewedTaskExplanation? explanation,
      double rate = 1,
      bool handled = true,
    }) =>
        LumoTaskDialogueReply(
          sessionId: snapshot.sessionId,
          taskId: snapshot.taskId,
          stepId: snapshot.stepId,
          revision: snapshot.revision,
          text: text,
          intent: intent,
          targetObjectIds: targets,
          gesture: gesture,
          needsConfirmation: needsConfirmation,
          draftAnswer: draftAnswer,
          explanationId: explanation?.id,
          speechParts: explanation?.speechParts ?? const [],
          speechRateMultiplier: rate,
          handled: handled,
        );

    // Commands still work on a partial recognition result. No answer or
    // learning action is ever produced from partial speech.
    if (_isStop(q)) {
      return reply('Gestoppt. Ich höre zu.', LumoTaskDialogueIntent.stop);
    }
    if (_contains(q, const [
      'allein versuchen',
      'alleine versuchen',
      'allein machen',
      'selber versuchen',
      'selbst versuchen',
      'keine hilfe',
      'ohne hilfe',
    ])) {
      return reply('Du kannst es in Ruhe allein versuchen. '
          'Sag Bescheid, wenn du wieder Hilfe möchtest.', LumoTaskDialogueIntent.alone);
    }
    if (_contains(q, const [
      'jemand tut mir weh',
      'jemand schlaegt mich',
      'ich werde geschlagen',
      'ich will nicht mehr leben',
      'ich will mir weh tun',
    ])) {
      return reply(
        'Das klingt ernst. Bitte sag es jetzt einer erwachsenen Person, '
        'der du vertraust. Du musst damit nicht allein bleiben. '
        'Ich bin eine digitale Figur und kann keine Hilfe vor Ort holen.',
        LumoTaskDialogueIntent.concern,
        gesture: LumoTaskDialogueGesture.encourage,
      );
    }
    if (!isFinal ||
        q.isEmpty ||
        input.length > 1200 ||
        (recognitionConfidence != null &&
            (!recognitionConfidence.isFinite || recognitionConfidence < .65))) {
      return reply(
        'Ich habe dich noch nicht sicher verstanden. '
        'Sag es bitte noch einmal oder tippe deine Antwort.',
        LumoTaskDialogueIntent.clarification,
        needsConfirmation: true,
      );
    }
    if (_contains(q, const ['bist du echt', 'bist du lebendig', 'bist du ein mensch'])) {
      return reply(
        'Ich bin Lumo, eine digitale Figur in deiner Lern-App. '
        'Ich kann dir bei den Aufgaben helfen.',
        LumoTaskDialogueIntent.identity,
      );
    }
    if (snapshot.isAssessment) {
      return reply(
        'Im Test löst du die Aufgabe selbst. Danach können wir '
        'die Schritte gemeinsam anschauen.',
        LumoTaskDialogueIntent.help,
      );
    }

    final visibleIds = snapshot.objects.map((object) => object.id).toSet();
    final available = snapshot.explanations
        .where((explanation) =>
            explanation.minimumHelpLevel <= snapshot.helpLevel &&
            (explanation.stepId.isEmpty || explanation.stepId == snapshot.stepId) &&
            explanation.objectIds.every(visibleIds.contains) &&
            explanation.text.trim().isNotEmpty)
        .toList(growable: false);
    final previous = previousReply != null && snapshot.containsReply(previousReply)
        ? previousReply
        : null;

    LumoReviewedTaskExplanation? currentExplanation() {
      if (previous?.explanationId != null) {
        for (final explanation in available) {
          if (explanation.id == previous!.explanationId) return explanation;
        }
      }
      return available.isEmpty ? null : available.first;
    }

    LumoReviewedTaskExplanation? matchingExplanation() {
      LumoReviewedTaskExplanation? best;
      var score = 0;
      for (final explanation in available) {
        final matches = explanation.keywords
            .where((word) => _contains(q, [_normalizer.normalizeText(word)]))
            .length;
        if (matches > score) {
          score = matches;
          best = explanation;
        }
      }
      return best ?? currentExplanation();
    }

    LumoTaskDialogueReply explain(
      LumoReviewedTaskExplanation? explanation,
      LumoTaskDialogueIntent intent, {
      String? text,
      double rate = 1,
    }) {
      if (explanation == null) {
        return reply(
          'Welchen Teil der Aufgabe meinst du? '
          'Du kannst ihn auswählen oder den vorhandenen Tipp öffnen.',
          LumoTaskDialogueIntent.clarification,
          needsConfirmation: true,
        );
      }
      return reply(
        text ?? explanation.text,
        intent,
        targets: explanation.objectIds,
        gesture: explanation.objectIds.isEmpty
            ? LumoTaskDialogueGesture.lookAtChild
            : LumoTaskDialogueGesture.point,
        explanation: explanation,
        rate: rate,
      );
    }

    final slow = _contains(q, const ['langsamer', 'langsam', 'in ruhe sprechen']);
    final repeat = _contains(q, const ['noch einmal', 'nochmal', 'wiederholen', 'wiederhole']);
    if (slow || repeat) {
      final explanation = currentExplanation();
      final sameExplanation = previous != null && explanation != null &&
          previous.explanationId == explanation.id &&
          [explanation.text, explanation.why, explanation.alternativeText]
              .contains(previous.text);
      return explain(
        explanation,
        slow ? LumoTaskDialogueIntent.slower : LumoTaskDialogueIntent.repeat,
        text: sameExplanation ? previous.text : null,
        rate: slow ? .75 : (previous?.speechRateMultiplier ?? 1),
      );
    }

    final stepNumber = _requestedStep(q);
    if (stepNumber != null) {
      for (final explanation in available) {
        if (explanation.stepNumber == stepNumber) {
          return explain(explanation, LumoTaskDialogueIntent.step);
        }
      }
      return reply(
        'Diesen Schritt habe ich hier noch nicht als freigegebene '
        'Erklärung. Zeige mir bitte den Teil, den du meinst, '
        'oder öffne den nächsten Tipp.',
        LumoTaskDialogueIntent.clarification,
        needsConfirmation: true,
      );
    }

    if (_contains(q, const ['die 2 da', 'diese 2', 'die beiden da', 'das da', 'die da'])) {
      final selectedIds = {
        ...snapshot.selectedObjectIds.where(visibleIds.contains),
        ...snapshot.objects.where((object) => object.selected).map((object) => object.id),
      };
      final wantsTwo = _contains(q, const ['die 2 da', 'diese 2', 'die beiden da']);
      final expectedCount = wantsTwo ? 2 : 1;
      if (selectedIds.length != expectedCount) {
        return reply(
          wantsTwo
              ? 'Welche zwei meinst du? Tippe die beiden Objekte bitte an, damit ich sie sicher zuordnen kann.'
              : 'Welches Objekt meinst du? Tippe es bitte an, damit ich es sicher zuordnen kann.',
          LumoTaskDialogueIntent.clarification,
          needsConfirmation: true,
        );
      }
      final selected = snapshot.objects
          .where((object) => selectedIds.contains(object.id))
          .toList(growable: false);
      return reply(
        'Du meinst ${selected.map((object) => object.label).join(' und ')}. '
        'Was möchtest du dazu wissen?',
        LumoTaskDialogueIntent.reference,
        targets: selected.map((object) => object.id).toList(growable: false),
        gesture: LumoTaskDialogueGesture.point,
      );
    }

    if (_contains(q, const ['anders erklaeren', 'anders erklaer', 'andere erklaerung', 'anderes beispiel', 'anders zeigen'])) {
      final current = currentExplanation();
      if (current?.alternativeText?.trim().isNotEmpty == true) {
        return explain(current, LumoTaskDialogueIntent.alternative,
            text: current!.alternativeText);
      }
      for (final explanation in available) {
        if (explanation.id != current?.id && explanation.text != current?.text) {
          return explain(explanation, LumoTaskDialogueIntent.alternative);
        }
      }
      return reply(
        'Welcher Teil ist noch unklar? Zeige ihn mir bitte. '
        'Dann können wir die vorhandene Hilfe gemeinsam anschauen.',
        LumoTaskDialogueIntent.clarification,
        needsConfirmation: true,
      );
    }

    if (_contains(q, const ['warum', 'wieso', 'weshalb'])) {
      if (!_relatedWhy(q, snapshot, available)) {
        return reply('', LumoTaskDialogueIntent.unrelated, handled: false);
      }
      final explanation = matchingExplanation();
      return explain(explanation, LumoTaskDialogueIntent.why,
          text: explanation?.why ?? explanation?.text);
    }
    if (_contains(q, const ['zeig mir', 'zeige mir', 'zeig das', 'zeigen', 'was wiederholt sich', 'welche gruppe'])) {
      return explain(matchingExplanation(), LumoTaskDialogueIntent.show);
    }
    if (_contains(q, const ['erklaer', 'erklaere', 'erklaeren', 'hilfe', 'hilf mir', 'verstehe', 'weiss nicht', 'was soll ich', 'wie geht', 'naechster schritt'])) {
      return explain(matchingExplanation(), LumoTaskDialogueIntent.help);
    }

    if (snapshot.acceptingAnswer && snapshot.answerFormat != LumoTaskAnswerFormat.none) {
      final correction = RegExp(r'\b(?:meinte|meine antwort|sondern|korrektur|nein)\b').hasMatch(q);
      final match = _normalizer.normalizeAnswer(
        spokenText: input,
        choices: snapshot.answerChoices,
        recognitionConfidence: recognitionConfidence,
      );
      var candidate = match.matchedChoice;
      if (candidate == null && snapshot.answerFormat == LumoTaskAnswerFormat.integer) {
        var numeric = q;
        final explicit = RegExp(r'\b(?:ich meinte|ich meine|sondern|nein|die antwort ist|meine antwort ist)\b')
            .allMatches(numeric).toList();
        if (explicit.isNotEmpty) numeric = numeric.substring(explicit.last.end).trim();
        if (RegExp(r'^\d{1,7}$').hasMatch(numeric)) candidate = numeric;
      }
      if (candidate != null) {
        return reply(
          correction
              ? 'Danke für die Korrektur. Ich habe „$candidate“ verstanden. '
                  'Stimmt das? Bestätige die Antwort erst, wenn sie passt.'
              : 'Ich habe „$candidate“ verstanden. Stimmt das? '
                  'Du kannst bestätigen oder die Antwort ändern.',
          correction ? LumoTaskDialogueIntent.correction : LumoTaskDialogueIntent.answer,
          needsConfirmation: true,
          draftAnswer: candidate,
        );
      }
      if (correction || RegExp(r'^\d+(?:\s+.*)?$').hasMatch(q)) {
        return reply(
          'Ich bin bei deiner Antwort noch nicht sicher. '
          'Welche Antwort meinst du? Du kannst sie auch antippen.',
          LumoTaskDialogueIntent.clarification,
          needsConfirmation: true,
        );
      }
    }
    return reply('', LumoTaskDialogueIntent.unrelated, handled: false);
  }

  static bool _relatedWhy(String query, LumoTaskDialogueSnapshot snapshot,
      List<LumoReviewedTaskExplanation> explanations) {
    if (const ['warum', 'wieso', 'weshalb'].contains(query) ||
        _contains(query, const ['das', 'diese', 'diesen', 'zuerst', 'danach',
          'aufgabe', 'schritt', 'zehnerfeld', 'freien plaetze'])) return true;
    for (final explanation in explanations) {
      if (explanation.keywords.any((word) =>
          _contains(query, [_normalizer.normalizeText(word)]))) return true;
    }
    final taskWords = _normalizer.normalizeText(snapshot.prompt).split(' ').toSet();
    const stopWords = {'warum', 'wieso', 'weshalb', 'einen', 'einem', 'eine',
      'einer', 'sind', 'nicht', 'habe', 'haben', 'wird', 'werden', 'kann', 'kannst',
      'dann', 'aber', 'auch', 'bitte', 'noch', 'jetzt'};
    return query.split(' ').any((word) =>
        (word.length >= 4 || RegExp(r'^\d+$').hasMatch(word)) &&
        !stopWords.contains(word) && taskWords.contains(word));
  }

  static bool _contains(String query, List<String> phrases) => phrases.any(
      (phrase) => phrase.isNotEmpty && ' $query '.contains(' $phrase '));

  static bool _isStop(String query) => RegExp(
        r'^(?:(?:lumo|bitte)\s+)*(?:stopp?|halt|aufhoeren|hoer auf|abbrechen)(?:\s+(?:bitte|jetzt))?$',
      ).hasMatch(query);

  static int? _requestedStep(String query) {
    final ordinal = RegExp(r'\b(?:den |der |beim |im )?(ersten|erste|zweiten|zweite|dritten|dritte|vierten|vierte|\d+)\s+schritt\b')
        .firstMatch(query)?.group(1);
    final after = RegExp(r'\bschritt\s+(\d+)\b').firstMatch(query)?.group(1);
    return switch (ordinal ?? after) {
      'ersten' || 'erste' => 1,
      'zweiten' || 'zweite' => 2,
      'dritten' || 'dritte' => 3,
      'vierten' || 'vierte' => 4,
      final String number => int.tryParse(number),
      _ => null,
    };
  }
}
