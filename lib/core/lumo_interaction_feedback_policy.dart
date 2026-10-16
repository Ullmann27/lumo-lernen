/// Preserves the original UI while wiring already packaged offline audio.
class LumoInteractionFeedbackPolicy {
  const LumoInteractionFeedbackPolicy._();

  /// This exact sentence is present in the verified Lumo Frei clip catalog.
  static const recordedGreeting =
      'Hallo! Schön, dass du da bist. Ich bin Lumo. '
      'Komm, wir entdecken zusammen etwas Neues!';

  static bool shouldGreet({
    required bool hasProfile,
    required bool isDeepLink,
    required bool enabled,
    required bool autoRead,
  }) => hasProfile && !isDeepLink && enabled && autoRead;

  static bool shouldPlayTap({
    required bool soundEnabled,
    required bool destinationChanged,
  }) => soundEnabled && destinationChanged;
}
