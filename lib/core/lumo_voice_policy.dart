import 'lumo_child_speech_normalizer.dart';

/// Pure text preparation for the fixed Sulafat speaker identity.
abstract final class LumoVoicePolicy {
  /// Keep the actual teaching text; never prepend a second greeting,
  /// patronising reassurance or a second question on every utterance.
  static String prepare(String input) {
    var text = LumoChildSpeechNormalizer.forSpeech(input)
        .replaceAll(RegExp(r'\s*\n+\s*'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAllMapped(RegExp(r'([.!?])\s*\.'), (match) => match.group(1)!)
        .trim();
    return text;
  }
}
