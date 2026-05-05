import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/app/app_state.dart';

void main() {
  group('wallet split', () {
    test('migrates legacy stars into earned and spendable stars', () {
      final state = LumoSessionState(stars: 42);

      expect(state.totalEarnedStars, 42);
      expect(state.spendableStars, 42);
      expect(state.stars, 42);
    });

    test('spendableStars is the visible stars value', () {
      final state = LumoSessionState(
        totalEarnedStars: 100,
        spendableStars: 35,
      );

      expect(state.stars, 35);
    });

    test('correct answer increases earned and spendable stars', () {
      final appState = LumoAppState();
      appState.update(LumoSessionState(totalEarnedStars: 10, spendableStars: 4, xp: 0));

      appState.correctAnswer('Plus bis 20');

      expect(appState.state.totalEarnedStars, 13);
      expect(appState.state.spendableStars, 7);
      expect(appState.state.stars, 7);
      expect(appState.state.xp, 20);
    });

    test('spendStars decreases only spendable stars', () {
      final appState = LumoAppState();
      appState.update(LumoSessionState(totalEarnedStars: 100, spendableStars: 40));

      final ok = appState.spendStars(25);

      expect(ok, isTrue);
      expect(appState.state.totalEarnedStars, 100);
      expect(appState.state.spendableStars, 15);
      expect(appState.state.stars, 15);
    });

    test('spendStars rejects negative or zero amounts', () {
      final appState = LumoAppState();
      appState.update(LumoSessionState(totalEarnedStars: 50, spendableStars: 20));

      expect(appState.spendStars(0), isFalse);
      expect(appState.spendStars(-5), isFalse);
      expect(appState.state.totalEarnedStars, 50);
      expect(appState.state.spendableStars, 20);
    });

    test('spendStars rejects amounts above balance', () {
      final appState = LumoAppState();
      appState.update(LumoSessionState(totalEarnedStars: 50, spendableStars: 10));

      final ok = appState.spendStars(11);

      expect(ok, isFalse);
      expect(appState.state.totalEarnedStars, 50);
      expect(appState.state.spendableStars, 10);
    });
  });
}
