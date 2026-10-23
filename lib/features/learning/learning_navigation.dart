import 'package:flutter/foundation.dart';

/// Browsing state only. Never changes a child's enrolled grade or progress.
/// The shell owns it so a task can be disposed without losing its return path.
class LearningNavigation extends ChangeNotifier {
  int? _grade;
  String? _subject;

  int gradeFor(int enrolledGrade) => _grade ?? enrolledGrade.clamp(1, 4);
  String? get subject => _subject;

  void selectGrade(int grade) {
    _grade = grade.clamp(1, 4);
    _subject = null;
    notifyListeners();
  }

  void selectSubject(String? subject) {
    _subject = subject;
    notifyListeners();
  }

  bool backToSubjects() {
    if (_subject == null) return false;
    selectSubject(null);
    return true;
  }
}
