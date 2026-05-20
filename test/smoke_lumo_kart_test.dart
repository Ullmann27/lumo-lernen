// Smoke-Test fuer Lumo Kart Premium-Vertical-Slice.
//
// Pflicht-Checks:
//   - LumoKartGame laesst sich instanzieren ohne Crash
//   - kart-Feld ist VOR onLoad initialisiert (Heinz-Pflicht)
//   - KartTuning-Konstanten sind plausibel
//   - KartCatalog hat genau eine entsperrte Auswahl pro Kategorie
//   - KartQuestionPool liefert valide Fragen
//   - setSteering / triggerBoost / restart crashen nicht

import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/features/games/kart/kart_models.dart';
import 'package:lumo_lernen/features/games/kart/kart_question_pool.dart';
import 'package:lumo_lernen/features/games/kart/kart_tuning.dart';
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
      expect(game.kart, isNotNull);
    });

    test('setSteering / triggerBoost crashen nicht vor onLoad', () {
      final game = LumoKartGame(
        onFinish: (s, t) {},
        onStar: (s) {},
      );
      expect(() => game.setSteering(0.5), returnsNormally);
      expect(() => game.setSteering(-1.0), returnsNormally);
      expect(() => game.triggerBoost(), returnsNormally);
      // Waehrend Countdown wird stickX auf 0 gezwungen
      expect(game.kart.stickX, 0);
    });

    test('restart() resettet obere Spielzustand-Felder', () {
      final game = LumoKartGame(
        onFinish: (s, t) {},
        onStar: (s) {},
      );
      game.stars = 5;
      game.totalTime = 12.3;
      game.finished = true;
      // restart vor onLoad ruft resumeEngine() ggf nicht produktiv auf,
      // sollte aber kein Crash sein, weil children leer sind.
      expect(() => game.restart(), returnsNormally);
      expect(game.stars, 0);
      expect(game.totalTime, 0);
      expect(game.finished, isFalse);
    });
  });

  group('KartTuning', () {
    test('Werte sind im plausiblen Bereich', () {
      expect(KartTuning.maxSpeed, greaterThan(100));
      expect(KartTuning.maxSpeed, lessThan(2000));
      expect(KartTuning.acceleration, greaterThan(0));
      expect(KartTuning.boostMultiplier, greaterThan(1.0));
      expect(KartTuning.boostMultiplier, lessThan(4.0));
      expect(KartTuning.crashSlowdown, greaterThan(0.0));
      expect(KartTuning.crashSlowdown, lessThan(1.0));
      expect(KartTuning.trackWidth, greaterThan(100));
      expect(KartTuning.finishDistance, greaterThan(1000));
      expect(KartTuning.laneClamp, lessThanOrEqualTo(1.0));
      expect(KartTuning.laneClamp, greaterThan(0.5));
    });
  });

  group('KartCatalog', () {
    test('Genau ein entsperrter Fahrer in Phase 1', () {
      final unlocked = KartCatalog.drivers.where((d) => d.unlocked).length;
      expect(unlocked, 1);
      expect(KartCatalog.lumoDriver.unlocked, isTrue);
      expect(KartCatalog.lumoDriver.id, 'lumo');
    });

    test('Genau ein entsperrtes Kart in Phase 1', () {
      final unlocked = KartCatalog.vehicles.where((v) => v.unlocked).length;
      expect(unlocked, 1);
      expect(KartCatalog.starterKart.unlocked, isTrue);
    });

    test('Genau eine entsperrte Strecke in Phase 1', () {
      final unlocked = KartCatalog.tracks.where((t) => t.unlocked).length;
      expect(unlocked, 1);
      expect(KartCatalog.meadowLap.unlocked, isTrue);
      expect(KartCatalog.meadowLap.name, 'Blumen-Tal-Runde');
    });
  });

  group('KartQuestionPool', () {
    test('Pool ist nicht leer', () {
      expect(KartQuestionPool.length, greaterThanOrEqualTo(3));
    });

    test('Jede Frage hat genau eine korrekte Option', () {
      for (int i = 0; i < KartQuestionPool.length; i++) {
        final q = KartQuestionPool.at(i);
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(q.options.length));
        expect(q.prompt.trim().isNotEmpty, isTrue);
        // Keine doppelten Optionen
        final unique = q.options.toSet();
        expect(unique.length, q.options.length,
            reason: 'Frage "${q.prompt}" hat doppelte Optionen');
      }
    });

    test('random() liefert reproduzierbare Frage mit Seed', () {
      final a = KartQuestionPool.random(seed: 7);
      final b = KartQuestionPool.random(seed: 7);
      expect(a.prompt, b.prompt);
    });
  });
}
