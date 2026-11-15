import '../widgets/fox/lumo_companion_requests.dart';
import 'lumo_child_speech_normalizer.dart';
import 'lumo_learning_session_contract.dart';

/// A small, deterministic command parser. It does not claim to be an LLM and
/// never derives a grade from the child's wording or recognition confidence.
class LumoLearningDialogueIntent {
  const LumoLearningDialogueIntent(this.action,
      {this.candidate, this.isCorrection = false});

  final LumoLearningAction action;
  final String? candidate;
  final bool isCorrection;

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

    // A correction names the replacement, never the first number in
    // "nicht vier, sondern dreizehn". Nothing is checked until confirmation.
    final correction = RegExp(
            r'\b(?:sondern|ich meinte|ich meine|gemeint habe ich)\s+(.+)$',
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
