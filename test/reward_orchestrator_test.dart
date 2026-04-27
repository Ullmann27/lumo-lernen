import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/services/reward_orchestrator.dart';

void main() {
  group('RewardOrchestrator', () {
    test('initial state is zero', () {
      final ro = RewardOrchestrator();
      expect(ro.xp, equals(0));
      expect(ro.stars, equals(0));
      expect(ro.level, equals(1));
    });

    test('addXP increases xp', () {
      final ro = RewardOrchestrator();
      ro.addXP(10);
      expect(ro.xp, equals(10));
    });

    test('level increases with xp', () {
      final ro = RewardOrchestrator();
      ro.addXP(100);
      expect(ro.level, equals(2));
    });

    test('stars are awarded for xp milestones', () {
      final ro = RewardOrchestrator();
      ro.addXP(50);
      expect(ro.stars, equals(1));
    });

    test('reset clears xp and stars', () {
      final ro = RewardOrchestrator();
      ro.addXP(200);
      ro.reset();
      expect(ro.xp, equals(0));
      expect(ro.stars, equals(0));
    });
  });
}
