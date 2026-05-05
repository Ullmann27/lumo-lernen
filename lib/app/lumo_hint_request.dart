import 'app_state.dart';

extension LumoHintRequest on LumoAppState {
  Future<void> requestHint({
    required String subject,
    required String unit,
  }) async {
    if (!learningProfileLoaded) {
      await loadLearningProfile();
    }

    await learningProfile.recordHintRequested(
      subject: subject,
      unit: unit,
    );

    final safeSubject = subject.trim().isEmpty ? state.subject : subject.trim();
    final safeUnit = unit.trim().isEmpty ? state.unit : unit.trim();

    update(state.copyWith(
      subject: safeSubject,
      unit: safeUnit,
      mood: LumoMood.comfort,
      lumoMessage: 'Gute Idee.\nIch helfe dir\nSchritt für Schritt.',
    ));
  }
}
