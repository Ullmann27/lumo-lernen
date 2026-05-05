import 'scanned_task_fallback_policy.dart';
import 'scanned_work_analysis.dart';

extension ScannedWorkTaskFallback on ScannedWorkAnalysis {
  RecognizedTaskFallback buildRecognizedTaskFallback({
    int grade = 1,
    double? ocrConfidence,
  }) {
    return const ScannedTaskFallbackPolicy().analyze(
      rawText: rawText,
      subject: subject,
      unit: primaryUnit,
      grade: grade,
      ocrConfidence: ocrConfidence,
    );
  }

  bool get canStartRecognizedTask {
    final fallback = buildRecognizedTaskFallback();
    return fallback.isSolvable;
  }

  bool get requiresParentReviewForRecognizedTask {
    final fallback = buildRecognizedTaskFallback();
    return fallback.requiresParentReview;
  }
}
