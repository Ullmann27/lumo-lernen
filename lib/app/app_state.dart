import 'package:flutter/foundation.dart';
import '../core/app_settings.dart';
import '../core/learning_profile_engine.dart';
import '../core/progress_repository.dart';
import '../core/recommendation_engine.dart';

enum LumoSection {
  home,
  learn,
  exercises,
  tests,
  schoolwork,
  scanner,
  missions,
  progress,
  rewards,
  agent,
  profile,
  settings,
}

enum LumoMood { greet, point, celebrate, comfort, think, wave, idle }

class LumoSessionState {
  LumoSessionState({
    this.section = LumoSection.home,
    this.childName = 'Lena',
    this.grade = 1,
    this.subject = 'Alle',
    this.unit = 'Alle',
    this.stars = 24,
    this.xp = 840,
    this.lastGrade = 0,
    this.mood = LumoMood.greet,
    this.lumoMessage = 'Hallo!\nWomit wollen wir\nheute lernen?',
    this.practiceErrors = 0,
    this.solved = const {},
    this.weakSkills = const {},
    this.settings = const AppSettings(),
  });

  LumoSection section;
  String childName;
  int grade;
  String subject;
  String unit;
  int stars;
  int xp;
  int lastGrade;
  LumoMood mood;
  String lumoMessage;
  int practiceErrors;
  Map<String, int> solved;
  Map<String, int> weakSkills;
  AppSettings settings;

  int get level => xp ~/ 400 + 1;
  int get levelXpPercent => ((xp % 400) / 4).round().clamp(0, 100);
  int get progressPercent => ((solved.values.fold(0, (a, b) => a + b) / 30) * 100).round().clamp(0, 100);
  int get weeklyProgress => 62;

  LumoSessionState copyWith({
    LumoSection? section,
    String? childName,
    int? grade,
    String? subject,
    String? unit,
    int? stars,
    int? xp,
    int? lastGrade,
    LumoMood? mood,
    String? lumoMessage,
    int? practiceErrors,
    Map<String, int>? solved,
    Map<String, int>? weakSkills,
    AppSettings? settings,
  }) {
    return LumoSessionState(
      section: section ?? this.section,
      childName: childName ?? this.childName,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      unit: unit ?? this.unit,
      stars: stars ?? this.stars,
      xp: xp ?? this.xp,
      lastGrade: lastGrade ?? this.lastGrade,
      mood: mood ?? this.mood,
      lumoMessage: lumoMessage ?? this.lumoMessage,
      practiceErrors: practiceErrors ?? this.practiceErrors,
      solved: solved ?? this.solved,
      weakSkills: weakSkills ?? this.weakSkills,
      settings: settings ?? this.settings,
    );
  }
}

class LumoAppState extends ChangeNotifier {
  LumoSessionState _state = LumoSessionState();
  LumoSessionState get state => _state;

  // ── Phase 3: Lernprofil-Engine ──────────────────────────────
  // Die Engine speichert lokal pro Skill (Subject + Unit) den Fortschritt
  // des Kindes. Sie wird einmal beim App-Start geladen und schreibt danach
  // bei jeder beantworteten Aufgabe automatisch in den lokalen Speicher.
  final LearningProfileEngine _learningProfile = LearningProfileEngine();
  bool _learningProfileLoaded = false;

  /// Zugriff auf die Engine fuer Eltern-Dashboard-Auswertungen.
  /// Nicht direkt fuer UI-Manipulation gedacht.
  LearningProfileEngine get learningProfile => _learningProfile;
  bool get learningProfileLoaded => _learningProfileLoaded;

  /// Laedt die Lerndaten vom lokalen Speicher.
  /// Wird von der AppShell beim Start aufgerufen, parallel zu den Settings.
  Future<void> loadLearningProfile() async {
    if (_learningProfileLoaded) return;
    await _learningProfile.load();
    _learningProfileLoaded = true;
    notifyListeners();
  }

  /// Erfasst eine beantwortete Uebung.
  /// Aufruf erfolgt aus dem Uebungs-Widget, parallel zu correctAnswer/wrongAnswer.
  Future<void> recordLearningAnswer({
    required String subject,
    required String unit,
    required bool correct,
    bool hintUsed = false,
  }) async {
    if (!_learningProfileLoaded) {
      // Engine ist noch nicht geladen. Wir versuchen es nachzuladen, damit
      // die Antwort nicht verloren geht.
      await _learningProfile.load();
      _learningProfileLoaded = true;
    }
    await _learningProfile.recordAnswer(
      subject: subject,
      unit: unit,
      isCorrect: correct,
      hintUsed: hintUsed,
    );
    // Wir loesen einen Listener-Notify aus, damit Widgets die Empfehlungen
    // anzeigen koennten. Der eigentliche Session-State bleibt unveraendert.
    notifyListeners();
  }

  /// Liefert die wichtigste aktuelle Empfehlung — oder null, wenn noch nicht
  /// genug Daten vorliegen.
  Recommendation? topLearningRecommendation() {
    if (!_learningProfileLoaded) return null;
    return _learningProfile.topRecommendation(
      dailyGoalTarget: _state.settings.dailyGoal,
    );
  }

  /// Anzahl der heute richtig beantworteten Aufgaben.
  int learningDailyDone() =>
      _learningProfileLoaded ? _learningProfile.dailyDone() : 0;

  /// Aktuelle Tagesserie in Tagen.
  int learningStreakDays() =>
      _learningProfileLoaded ? _learningProfile.currentStreakDays() : 0;

  /// Schwaechen-Uebersicht fuer den Eltern-Bereich.
  Map<String, List<String>> learningWeaknessesBySubject() =>
      _learningProfileLoaded
          ? _learningProfile.weaknessesBySubject()
          : <String, List<String>>{};

  /// Zugriff auf die rohen SkillRecords fuer Statistiken.
  Map<String, SkillRecord> learningSkills() =>
      _learningProfileLoaded ? _learningProfile.skills : <String, SkillRecord>{};

  /// Setzt alle Lerndaten zurueck. Nur Eltern-PIN-geschuetzt aufrufen.
  Future<void> resetLearningProfile() async {
    await _learningProfile.reset();
    notifyListeners();
  }

  void update(LumoSessionState next) {
    _state = next;
    notifyListeners();
  }

  void updateSettings(AppSettings settings) {
    _state = _state.copyWith(settings: settings);
    notifyListeners();
  }

  void setSection(LumoSection section) {
    final messages = {
      LumoSection.home: 'Hallo!\nWomit wollen wir\nheute lernen?',
      LumoSection.learn: 'Such dir ein\nFach aus. Ich\nbegleite dich!',
      LumoSection.exercises: 'Los gehts!\nEine kleine Übung\nreicht schon.',
      LumoSection.tests: 'Testmodus.\nRuhig lesen,\ndann antworten.',
      LumoSection.schoolwork: 'Wie in der\nSchule – nur\nfreundlicher.',
      LumoSection.scanner: 'Mach ein Foto\ndeiner Aufgabe.\nIch helfe dir!',
      LumoSection.missions: 'Deine Missionen\nwarten schon.\nStarten wir?',
      LumoSection.progress: 'Schau mal,\nwie weit du\nschon bist!',
      LumoSection.rewards: 'Du hast dir\nBelohnungen\nverdient!',
      LumoSection.agent: 'Frag mich etwas.\nIch erkläre es\nkindgerecht.',
      LumoSection.profile: 'Das ist dein\nLernprofil.\nSuper stark!',
      LumoSection.settings: 'Hier stellen\nEltern alles\nsicher ein.',
    };
    final moods = {
      LumoSection.home: LumoMood.greet,
      LumoSection.learn: LumoMood.point,
      LumoSection.exercises: LumoMood.wave,
      LumoSection.tests: LumoMood.think,
      LumoSection.schoolwork: LumoMood.think,
      LumoSection.scanner: LumoMood.point,
      LumoSection.missions: LumoMood.celebrate,
      LumoSection.progress: LumoMood.think,
      LumoSection.rewards: LumoMood.celebrate,
      LumoSection.agent: LumoMood.greet,
      LumoSection.profile: LumoMood.idle,
      LumoSection.settings: LumoMood.idle,
    };
    update(_state.copyWith(
      section: section,
      mood: moods[section] ?? LumoMood.greet,
      lumoMessage: messages[section] ?? _state.lumoMessage,
    ));
  }

  void correctAnswer(String unit) {
    final newSolved = Map<String, int>.from(_state.solved);
    newSolved[unit] = (newSolved[unit] ?? 0) + 1;
    final variants = [
      'Juhu!\nDas war richtig.\nWeiter so! ⭐',
      'Stark gedacht!\nDu hast es\ngeschafft!',
      'Super!\nDein Lernweg\nwird stärker.',
      'Klasse!\nIch merke mir,\nwas gut klappt.',
    ];
    final msg = variants[DateTime.now().millisecond % variants.length];
    update(_state.copyWith(
      stars: _state.stars + 3,
      xp: _state.xp + 20,
      solved: newSolved,
      practiceErrors: 0,
      mood: LumoMood.celebrate,
      lumoMessage: msg,
    ));
  }

  void wrongAnswer(String unit) {
    final newWeak = Map<String, int>.from(_state.weakSkills);
    newWeak[unit] = (newWeak[unit] ?? 0) + 1;
    final errors = _state.practiceErrors + 1;
    update(_state.copyWith(
      weakSkills: newWeak,
      practiceErrors: errors,
      mood: errors >= 3 ? LumoMood.comfort : LumoMood.think,
      lumoMessage: errors >= 3
          ? 'Ganz ruhig.\nIch zeige dir\nden Weg.'
          : 'Fast!\nWir schauen\nnochmal hin.',
    ));
  }
}
