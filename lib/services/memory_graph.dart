import 'package:flutter/foundation.dart';

class MemoryGraph extends ChangeNotifier {
  final Map<String, double> _skills = {
    'Addition': 0.6,
    'Subtraktion': 0.4,
    'Zahlenreihen': 0.7,
    'Buchstaben': 0.5,
    'Reimwörter': 0.3,
    'Lesen': 0.6,
    'Schreiben': 0.4,
  };

  Map<String, double> get skills => Map.unmodifiable(_skills);

  List<String> get weakSkills =>
      _skills.entries.where((e) => e.value < 0.5).map((e) => e.key).toList();

  void updateSkill(String skill, double delta) {
    if (_skills.containsKey(skill)) {
      _skills[skill] = (_skills[skill]! + delta).clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  void addSkill(String skill, {double initialProgress = 0.1}) {
    if (!_skills.containsKey(skill)) {
      _skills[skill] = initialProgress;
      notifyListeners();
    }
  }
}
