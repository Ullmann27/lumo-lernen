import 'package:flutter/foundation.dart';

class RewardOrchestrator extends ChangeNotifier {
  int _xp = 0;
  int _stars = 0;

  int get xp => _xp;
  int get stars => _stars;
  int get level => (_xp ~/ 100) + 1;

  void addXP(int amount) {
    _xp += amount;
    final newStars = _xp ~/ 50;
    if (newStars > _stars) {
      _stars = newStars;
    }
    notifyListeners();
  }

  void addStar() {
    _stars++;
    notifyListeners();
  }

  void reset() {
    _xp = 0;
    _stars = 0;
    notifyListeners();
  }
}
