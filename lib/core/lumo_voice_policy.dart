import 'lumo_child_speech_normalizer.dart';

/// Pure, testable policy. A naturally expressive voice matters more than
/// artificial high pitch. Prefer usable offline voices for children's data.
abstract final class LumoVoicePolicy {
  static int score(Map<String, String> voice) {
    final name = (voice['name'] ?? '').toLowerCase();
    final locale = (voice['locale'] ?? '').toLowerCase().replaceAll('_', '-');
    var score = locale == 'de-at'
        ? 115
        : locale == 'de-de'
            ? 100
            : 70;
    final network =
        (voice['network_required'] ?? voice['networkRequired'] ?? '')
            .toLowerCase();
    if (network == 'true' || name.contains('network')) score -= 140;
    final quality = int.tryParse(voice['quality'] ?? '') ?? 0;
    score += (quality ~/ 10).clamp(0, 50);
    for (final label in ['neural', 'natural', 'enhanced', 'premium']) {
      if (name.contains(label)) score += 35;
    }
    if (name.contains('google')) score += 15;
    if (name.contains('compact')) score -= 30;
    if (name.contains('default')) score -= 10;
    return score;
  }

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
