import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/games/game_world.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const strict = GameUnlockPolicy(games: [
    GameDefinition(
      id: GameId.memory,
      title: 'Memory',
      tagline: '',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(minEarnedStars: 5),
    ),
    GameDefinition(
      id: GameId.cards,
      title: 'Cards',
      tagline: '',
      availability: GameAvailability.playable,
      rule: GameUnlockRule(requires: GameId.memory, minEarnedStars: 10),
    ),
  ]);

  test('Reihenfolge und konfigurierbare Schwellen', () {
    final low = strict.evaluate(const EarnedProgress(totalEarnedStars: 2));
    expect(low[GameId.memory]!.unlocked, isFalse);
    expect(low[GameId.memory]!.missingStars, 3);
    expect(low[GameId.cards]!.reason, GameLockReason.needsPreviousGame);
    final mid = strict.evaluate(const EarnedProgress(totalEarnedStars: 7));
    expect(mid[GameId.memory]!.unlocked, isTrue);
    expect(mid[GameId.cards]!.reason, GameLockReason.needsEarnedStars);
  });

  test('Ohne festgelegte Schwellen sperrt nur die Reihenfolge', () {
    final all = const GameUnlockPolicy()
        .evaluate(const EarnedProgress(totalEarnedStars: 0));
    expect(all.values.every((s) => s.unlocked), isTrue);
  });

  test('Dauerhaft offen bleibt offen, auch wenn Sterne ausgegeben wurden',
      () async {
    final service = GameUnlockService(policy: strict);
    final open = await service.load(const EarnedProgress(totalEarnedStars: 12));
    expect(open[GameId.cards]!.unlocked, isTrue);
    // Verdiente Sterne sinken nie; selbst ein Wert 0 darf nichts sperren.
    final later = await service.load(const EarnedProgress(totalEarnedStars: 0));
    expect(later[GameId.memory]!.unlocked, isTrue);
    expect(later[GameId.cards]!.unlocked, isTrue);
  });
}
