import 'package:flutter/foundation.dart';

/// Welcher Bereich aktiv ist (Menüpunkt links)
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

/// Was Lumo gerade tut (steuert Animation + Sprechblase)
enum LumoMood { greet, point, celebrate, comfort, think, wave, idle }

/// Einzelne Lern-Session
class LumoSessionState {
  LumoSessionState({
    this.section = LumoSection.home,
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
    this.focusedAccent,
  });

  LumoSection section;
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

  /// Wenn das Kind über eine Karte hovert/tippt - überschreibt die Aura-Farbe.
  /// `null` = Lumo nutzt seine Standard-Mood-Farbe.
  int? focusedAccent;

  int get level => xp ~/ 400 + 1;
  int get levelXpPercent => ((xp % 400) / 4).round().clamp(0, 100);
  int get progressPercent => ((solved.values.fold(0, (a, b) => a + b) / 30) * 100).round().clamp(0, 100);
  int get weeklyProgress => 62;

  LumoSessionState copyWith({
    LumoSection? section,
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
    int? focusedAccent,
    bool clearFocusedAccent = false,
  }) {
    return LumoSessionState(
      section: section ?? this.section,
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
      focusedAccent: clearFocusedAccent ? null : (focusedAccent ?? this.focusedAccent),
    );
  }
}

/// Zentraler StateNotifier – alle Widgets hören hier zu
class LumoAppState extends ChangeNotifier {
  LumoSessionState _state = LumoSessionState();
  LumoSessionState get state => _state;

  void update(LumoSessionState next) {
    _state = next;
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

  /// Lumo schaut zu einer Karte und übernimmt deren Akzentfarbe für die Aura.
  void focusCard(int accentArgb, String? hint) {
    update(_state.copyWith(
      focusedAccent: accentArgb,
      mood: LumoMood.point,
      lumoMessage: hint ?? _state.lumoMessage,
    ));
  }

  /// Hebt den Karten-Fokus auf.
  void unfocusCard() {
    update(_state.copyWith(
      clearFocusedAccent: true,
      mood: LumoMood.greet,
    ));
  }
}
