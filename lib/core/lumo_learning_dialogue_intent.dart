import '../widgets/fox/lumo_companion_requests.dart';
import 'lumo_child_speech_normalizer.dart';
import 'lumo_learning_session_contract.dart';

/// A small, deterministic command parser. It does not claim to be an LLM and
/// never derives a grade from the child's wording or recognition confidence.
class LumoLearningDialogueIntent {
  const LumoLearningDialogueIntent(this.action,
      {this.candidate, this.isCorrection = false, this.declinesHelp = false});

  final LumoLearningAction action;
  final String? candidate;
  final bool isCorrection;

  /// "Ich möchte es allein versuchen": the existing protocol stop, which
  /// leaves the child free to work. It never removes help already used.
  final bool declinesHelp;

  // Whole utterance only, so "ich kann es nicht allein" or a request for
  // help can never be mistaken for declining help.
  static final _declineHelp = RegExp(r'^(?:lumo )?(?:bitte )?(?:'
      r'(?:ich )?(?:moechte|will|mag|kann|darf)(?: es)?(?: jetzt)? '
      r'(?:allein|alleine|selbst|selber)'
      r'(?: (?:versuchen|probieren|machen|loesen|rechnen|schaffen))?'
      r'|lass mich(?: es)?(?: jetzt)? (?:allein|alleine|selbst|selber)'
      r'(?: (?:versuchen|probieren|machen|loesen|rechnen))?'
      r'|(?:ich brauche |ich will )?(?:keinen tipp|keine hilfe|keinen hinweis)'
      r'(?: mehr)?'
      r'|ohne (?:hilfe|tipp|hinweis))(?: bitte)?$');

  // "Zeig mir das", "Kannst du es mir zeigen?", "Zeig mir, wie das geht":
  // the existing explanation with the owner-validated pointing gesture.
  // "Zeig mir einen Hund" is not about the task and stays a normal question.
  static final _show = RegExp(r'^(?:lumo )?(?:bitte )?(?:'
      r'kannst du (?:(?:mir|uns|es|das|mal) )*zeigen'
      r'|zeige?(?: (?:es|mir|uns|mal|bitte|das))*'
      r'(?: (?:wie (?:das|es) geht|wie geht das|wo|'
      r'den (?:naechsten |1 |ersten |2 |zweiten )?schritt))?'
      r')(?: bitte)?$');

  // Lumo cannot see a finger on the screen. "Die zwei da" must be clarified,
  // never guessed as an object, a step or an answer.
  static final _ambiguousReference = RegExp(
      r'\b(?:die|der|das|den|diese|dieser|dieses|diesen)(?: \d+)? '
      r'(?:da|dort|hier)\b|\bdiese \d+\b');

  static final _differentExplanation = RegExp(
      r'\b(?:anders (?:erklaeren|erklaer|erklaere|zeigen)|andere erklaerung|'
      r'(?:erklaer|erklaere|zeig|zeige) (?:es |das |mir )*anders)\b');
  static final _secondStep = RegExp(
      r'\b(?:(?:zweiten|zweite|zweiter|2) schritt|schritt (?:zwei|2))\b');
  static final _tooFast = RegExp(r'^(?:lumo )?(?:bitte )?(?:'
      r'(?:(?:sprich|rede|lies)(?: bitte)? )?nicht so schnell|'
      r'das (?:geht|ist)(?: mir)? zu schnell)(?: bitte)?$');

  static bool requestsDifferentExplanation(String input) =>
      _differentExplanation.hasMatch(
          const LumoChildSpeechNormalizer().normalizeText(input));

  static bool requestsSecondStep(String input) => _secondStep.hasMatch(
      const LumoChildSpeechNormalizer().normalizeText(input));

  /// True for an unclassified utterance that points at something unnamed.
  static bool isAmbiguousReference(String input) =>
      _ambiguousReference.hasMatch(
          const LumoChildSpeechNormalizer().normalizeText(input));

  static LumoLearningDialogueIntent? parse(
      String input, LumoCompanionTaskContext? task) {
    final raw = input.trim();
    const normalizer = LumoChildSpeechNormalizer();
    final text = normalizer.normalizeText(raw);
    if (RegExp(r'^(?:lumo )?(?:bitte )?(?:stopp|stop|halt|abbrechen|pause|'
            r'hoer auf|hoer bitte auf)(?: bitte| jetzt)?$')
        .hasMatch(text)) {
      return const LumoLearningDialogueIntent(LumoLearningAction.stop);
    }
    if (task == null) return null;
    if (_declineHelp.hasMatch(text)) {
      return const LumoLearningDialogueIntent(LumoLearningAction.stop,
          declinesHelp: true);
    }

    // A correction names the replacement, never the first number in
    // "nicht vier, sondern dreizehn". Nothing is checked until confirmation.
    final correction = RegExp(
            r'\b(?:sondern|ich meinte|ich meine|gemeint habe ich|ich hab(?:e)? gesagt)\s+(.+)$',
            caseSensitive: false)
        .firstMatch(raw);
    final answerPhrase = RegExp(
            r'^(?:lumo[, ]+)?(?:meine antwort ist|die antwort ist|ich sage|'
            r'es ist|das ist|ich glaube(?: es ist)?)\s+(.+)$',
            caseSensitive: false)
        .firstMatch(raw);
    final proposal = correction?.group(1) ?? answerPhrase?.group(1);
    if (proposal != null) {
      final candidate =
          _candidate(proposal, task.answerChoices, explicit: true);
      if (candidate != null) {
        return LumoLearningDialogueIntent(LumoLearningAction.proposeAnswer,
            candidate: candidate, isCorrection: correction != null);
      }
    }

    // Negated requests must not unexpectedly start a narrated lesson.
    // "Nicht so schnell" explicitly asks to slow down; "nicht langsamer"
    // still declines that change. Replay remains owned by the visible task.
    if (_tooFast.hasMatch(text)) {
      return const LumoLearningDialogueIntent(LumoLearningAction.slower);
    }
    if (!RegExp(r'\b(?:nicht|kein|keine|ohne)\b').hasMatch(text)) {
      if (RegExp(r'\b(?:langsamer|langsam)\b').hasMatch(text)) {
        return const LumoLearningDialogueIntent(LumoLearningAction.slower);
      }
      if (RegExp(r'\b(?:wiederholen|wiederhole|nochmal|noch einmal|erneut)\b')
          .hasMatch(text)) {
        return const LumoLearningDialogueIntent(LumoLearningAction.repeat);
      }
      if (RegExp(r'\b(?:hinweis|tipp|hilfe|hilf)\b').hasMatch(text)) {
        return const LumoLearningDialogueIntent(LumoLearningAction.hint);
      }
      if (requestsDifferentExplanation(text) || requestsSecondStep(text)) {
        return const LumoLearningDialogueIntent(LumoLearningAction.explain);
      }
    }
    if (_show.hasMatch(text)) {
      return const LumoLearningDialogueIntent(LumoLearningAction.explain);
    }
    if (RegExp(r'\b(?:warum|wieso|weshalb|erklaer|erklaere|erklaeren|'
            r'verstehe|versteh|was soll ich|was muss ich)\b')
        .hasMatch(text)) {
      return const LumoLearningDialogueIntent(LumoLearningAction.explain);
    }
    final candidate = _candidate(raw, task.answerChoices, explicit: false);
    return candidate == null
        ? null
        : LumoLearningDialogueIntent(LumoLearningAction.proposeAnswer,
            candidate: candidate);
  }

  static String? _candidate(String raw, List<String> choices,
      {required bool explicit}) {
    final value = raw.trim().replaceAll(RegExp(r'[.!?]+$'), '').trim();
    if (value.isEmpty || value.length > 160) return null;
    const normalizer = LumoChildSpeechNormalizer();
    final normalized = normalizer.normalizeText(value);
    // Preserve signs and decimal separators before the general word matcher,
    // which deliberately removes punctuation for reading tasks.
    if (RegExp(r'^-?\d+(?:[,.]\d+)?$').hasMatch(value)) return value;
    final negative = RegExp(r'^minus (\d+)$').firstMatch(normalized);
    if (negative != null) return '-${negative.group(1)}';
    final matches = choices
        .where((choice) => normalizer.normalizeText(choice) == normalized)
        .toList();
    if (matches.length == 1) return matches.single;
    if (RegExp(r'^\d+$').hasMatch(normalized)) return normalized;
    // An explicitly named answer can be wrong, and remains editable. A
    // general question, however, is never guessed to be an answer choice.
    return explicit && !value.contains('?') ? value : null;
  }
}
