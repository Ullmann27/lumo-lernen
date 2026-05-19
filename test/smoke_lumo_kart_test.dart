// Smoke-Test fuer Lumo Kart
// Heinz-Auftrag (Punkt 6): 'smoke test: LumoKartGame.kart ist vor onLoad
// verfuegbar'.

import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/features/games/kart/lumo_kart_screen.dart';

void main() {
  group('Lumo Kart Smoke', () {
    test('LumoKartGame laesst sich instanzieren ohne Crash', () {
      var finishCalled = false;
      var stars = 0;
      final game = LumoKartGame(
        onFinish: (s, t) => finishCalled = true,
        onStar: (s) => stars = s,
      );
      expect(game, isNotNull);
      expect(finishCalled, isFalse);
      expect(stars, 0);
    });

    test('LumoKartGame.kart ist VOR onLoad() initialisiert (Heinz-Pflicht)',
        () {
      final game = LumoKartGame(
        onFinish: (s, t) {},
        onStar: (s) {},
      );
      // Kein Aufruf von onLoad - kart muss schon da sein.
      // Frueher: 'late KartPlayerComponent kart' wurde erst in onLoad gesetzt
      // -> NullPointer wenn UI das Widget rendered bevor onLoad fertig war.
      // Jetzt: im Constructor eager initialisiert.
      expect(game.kart, isNotNull);
    });
  });
}
