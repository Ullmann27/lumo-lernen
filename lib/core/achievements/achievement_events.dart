import '../../app/app_state.dart';
import 'achievement_repository.dart';

/// Explicit participation metadata only. Call after a real accepted question,
/// reviewed spoken interaction or a returned camera photo, never on opening.
Future<bool> recordAchievementParticipation(LumoAppState appState,
    LearningProfileLease owner, AchievementParticipation kind) async {
  if (!appState.canUseLearningLease(owner) || appState.backupBusy) return false;
  try {
    await AchievementRepository(
            studentId: owner.studentId,
            mayWrite: () =>
                appState.canUseLearningLease(owner) && !appState.backupBusy)
        .recordParticipation(kind);
    return true;
  } catch (_) {
    return false;
  }
}
