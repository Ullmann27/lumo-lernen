enum LumoActorState {
  idle,
  lookLeft,
  lookCenter,
  pointLeft,
  greet,
  celebrate,
  comfort,
  walkSmall,
  stepForward,
  returnToBase,
}

class LumoDirectorSignal {
  const LumoDirectorSignal({
    required this.state,
    required this.speech,
    this.scale = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final LumoActorState state;
  final String speech;
  final double scale;
  final double offsetX;
  final double offsetY;
}

class LumoDirector {
  const LumoDirector();

  LumoDirectorSignal forHome() => const LumoDirectorSignal(
        state: LumoActorState.greet,
        speech: 'Hallo! Womit wollen wir heute lernen?',
      );

  LumoDirectorSignal forSubject(String subject) {
    if (subject == 'Mathematik') {
      return const LumoDirectorSignal(
        state: LumoActorState.pointLeft,
        speech: 'Ich zeige dir passende Mathe-Aufgaben.',
        offsetX: -6,
      );
    }
    if (subject == 'Deutsch') {
      return const LumoDirectorSignal(
        state: LumoActorState.lookLeft,
        speech: 'Wir lesen und schreiben heute ganz ruhig.',
      );
    }
    if (subject == 'Englisch') {
      return const LumoDirectorSignal(
        state: LumoActorState.lookCenter,
        speech: 'Englisch ueben wir mit kleinen Wortbildern.',
      );
    }
    return const LumoDirectorSignal(
      state: LumoActorState.greet,
      speech: 'Ich begleite dich Schritt fuer Schritt.',
    );
  }

  LumoDirectorSignal forScanner() => const LumoDirectorSignal(
        state: LumoActorState.pointLeft,
        speech: 'Mach ein Foto deiner Aufgabe. Ich helfe dir beim Verstehen.',
        offsetX: -8,
      );

  LumoDirectorSignal forSuccess() => const LumoDirectorSignal(
        state: LumoActorState.celebrate,
        speech: 'Fuchsstark! Die naechste Aufgabe wartet schon.',
        scale: 1.04,
        offsetY: -8,
      );

  LumoDirectorSignal forMistake(int count) {
    if (count >= 3) {
      return const LumoDirectorSignal(
        state: LumoActorState.comfort,
        speech: 'Kein Stress. Ich zeige dir den Weg jetzt langsam.',
        scale: 1.05,
        offsetY: -5,
      );
    }
    return const LumoDirectorSignal(
      state: LumoActorState.comfort,
      speech: 'Fast. Wir schauen noch einmal gemeinsam hin.',
    );
  }
}
