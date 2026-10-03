/// On-device decisions for Lumo's initiative. A suggestion never performs an
/// action on its own: the child accepts it first.
enum LumoCompanionAction {
  suggestTask,
  explainTask,
  explainView,
  explainApp,
  askLumo,
  takeBreak,
}

class LumoCompanionScene {
  const LumoCompanionScene({
    this.section = 'home',
    this.childName = '',
    this.recommendedSubject = 'Mathematik',
    this.recommendedUnit,
    this.solvedTasks = 0,
    this.consecutiveWrong = 0,
    this.taskInProgress = false,
    this.schoolwork = false,
    this.hasTask = false,
  });

  final String section;
  final String childName;
  final String recommendedSubject;
  final String? recommendedUnit;
  final int solvedTasks;
  final int consecutiveWrong;
  final bool taskInProgress;
  final bool schoolwork;
  final bool hasTask;

  String get topic {
    final unit = recommendedUnit;
    if (unit != null && unit.isNotEmpty && unit != 'Alle') return unit;
    return recommendedSubject == 'Alle' || recommendedSubject.isEmpty
        ? 'eine kleine gemischte Übung'
        : recommendedSubject;
  }

  String get viewExplanation => switch (section) {
        'home' => 'Hier startest du dein Lernabenteuer. Wähle ein Fach oder '
            'tippe auf „Idee“. Ich schlage dir dann eine passende Übung vor. '
            'Du entscheidest, ob du sie machen möchtest.',
        'learn' || 'exercises' => hasTask
            ? 'Lies oder höre zuerst die Aufgabe. Gib dann deine Antwort ein. '
                'Wenn du feststeckst, tippe auf „Aufgabe erklären“. '
                'Wir nehmen einen kleinen Schritt nach dem anderen.'
            : 'Wähle ein Fach und ein Thema. Dann kannst du üben. '
                'Während einer Übung kannst du mich um einen Hinweis bitten.',
        'reading' => 'Hier übst du das Lesen. Wähle einen Text und lies in '
            'deinem Tempo. Schwierige Wörter kannst du in kleine Teile zerlegen.',
        'games' => 'Hier findest du die Lernspiele. Wähle ein Spiel und '
            'schau dir zuerst seine Regeln an. Du kannst jederzeit zurückgehen.',
        'tests' || 'schoolwork' => 'Bei einer Schularbeit löst du die Aufgaben '
            'selbst. Ich verrate währenddessen keine Lösungen. Nachher können '
            'wir schwierige Themen zusammen üben.',
        'scanner' => 'Hier kannst du ein Arbeitsblatt aufnehmen. Lass dir '
            'beim Fotografieren helfen. Prüfe danach, ob der erkannte Text stimmt.',
        'missions' => 'Hier findest du Lernmissionen mit einem Ziel. '
            'Wähle eine Mission und erledige ihre Aufgaben in deinem Tempo.',
        'progress' => 'Hier siehst du deine bisherigen Lernschritte. '
            'Du kannst entdecken, was schon gut klappt und was du noch üben möchtest.',
        'rewards' => 'Hier findest du deine Belohnungen und Sterne. '
            'Schau zuerst, was eine Belohnung kostet, bevor du sie auswählst.',
        'agent' => 'Hier kannst du mir eine Lernfrage schreiben. '
            'Wenn das Mikrofon erlaubt ist, kannst du die Aufnahme selbst starten. '
            'Frag zum Beispiel: Wie rechne ich mit Zehnern?',
        'settings' || 'profile' => 'Das ist der Bereich für deine Eltern. '
            'Hier werden dein Profil und die Einstellungen verwaltet.',
        _ => 'Wähle, was du lernen möchtest. Mit „Fragen“ kannst du mir '
            'eine Lernfrage stellen. Wenn du eine Pause brauchst, ist das auch okay.',
      };

  static const appExplanation = 'Ich bin Lumo, dein Lernfuchs. '
      'Du kannst Fächer üben, lesen und Lernspiele ausprobieren. '
      'Bei „Idee“ schlage ich dir etwas vor. Bei „Erklären“ helfe ich dir '
      'auf dieser Seite oder bei einer Übung. Bei „Fragen“ kannst du mir '
      'eine eigene Lernfrage stellen. Du entscheidest, ob du meine Ideen '
      'ausprobierst. Mit „Später“ lässt du mich wieder warten.';
}

class LumoCompanionProposal {
  const LumoCompanionProposal({
    required this.id,
    required this.text,
    required this.action,
    required this.acceptLabel,
  });

  final String id;
  final String text;
  final LumoCompanionAction action;
  final String acceptLabel;
}

class LumoCompanionGuide {
  LumoCompanionGuide({
    required DateTime now,
    this.quietPeriod = const Duration(seconds: 15),
    this.cooldown = const Duration(seconds: 90),
    this.dismissDuration = const Duration(minutes: 10),
  }) : _lastInteraction = now;

  final Duration quietPeriod;
  final Duration cooldown;
  final Duration dismissDuration;
  DateTime _lastInteraction;
  DateTime? _lastProposal;
  DateTime? _mutedUntil;
  int? _initialSolved;
  final Set<String> _offered = <String>{};

  void noteInteraction(DateTime now) => _lastInteraction = now;

  void dismiss(DateTime now) {
    _mutedUntil = now.add(dismissDuration);
    noteInteraction(now);
  }

  LumoCompanionProposal choose(LumoCompanionScene scene) {
    if (scene.schoolwork) {
      return const LumoCompanionProposal(
        id: 'exam',
        text: 'Du arbeitest selbst. Danach üben wir gemeinsam weiter.',
        action: LumoCompanionAction.explainView,
        acceptLabel: 'So geht es',
      );
    }
    if (scene.hasTask && scene.consecutiveWrong >= 2) {
      return const LumoCompanionProposal(
        id: 'help',
        text: 'Sollen wir die Aufgabe gemeinsam in kleine Schritte teilen?',
        action: LumoCompanionAction.explainTask,
        acceptLabel: 'Zeig mir wie',
      );
    }
    if (scene.solvedTasks - (_initialSolved ?? scene.solvedTasks) >= 5) {
      return const LumoCompanionProposal(
        id: 'break',
        text: 'Du hast schon viel geübt. Möchtest du eine kleine Pause?',
        action: LumoCompanionAction.takeBreak,
        acceptLabel: 'Pause machen',
      );
    }
    if (scene.section == 'reading' || scene.section == 'games') {
      return LumoCompanionProposal(
        id: 'view:${scene.section}',
        text: 'Soll ich dir zeigen, wie es hier funktioniert?',
        action: LumoCompanionAction.explainView,
        acceptLabel: 'Ja, erklären',
      );
    }
    return LumoCompanionProposal(
      id: 'task:${scene.topic}',
      text: 'Ich habe eine Idee: Wir üben ${scene.topic}. Hast du Lust?',
      action: LumoCompanionAction.suggestTask,
      acceptLabel: 'Übung starten',
    );
  }

  LumoCompanionProposal? maybeSuggest(
    LumoCompanionScene scene, {
    required DateTime now,
    bool routeVisible = true,
  }) {
    _initialSolved ??= scene.solvedTasks;
    if (!routeVisible || scene.taskInProgress || scene.schoolwork) return null;
    if (scene.section == 'settings' ||
        scene.section == 'profile' ||
        scene.section == 'agent') {
      return null;
    }
    if (_mutedUntil != null && now.isBefore(_mutedUntil!)) return null;
    if (now.difference(_lastInteraction) < quietPeriod) return null;
    if (_lastProposal != null && now.difference(_lastProposal!) < cooldown) {
      return null;
    }
    final proposal = choose(scene);
    if (!_offered.add(proposal.id)) return null;
    _lastProposal = now;
    return proposal;
  }
}
