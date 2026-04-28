import 'package:flutter/foundation.dart';

/// Welcher Bereich aktiv ist (Menüpunkt links)
enum LumoSection { home, learn, exercises, progress, rewards, profile, scanner }

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

  int get level => xp ~/ 400 + 1;
  int get levelXpPercent => ((xp % 400) / 4).round().clamp(0, 100);
  int get progressPercent => ((solved.values.fold(0, (a, b) => a + b) / 30) * 100)
      .round().clamp(0, 100);
  int get weeklyProgress => 62; // TODO: persist weekly

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
      LumoSection.home:     'Hallo!\nWomit wollen wir\nheute lernen?',
      LumoSection.learn:    'Was möchtest\ndu heute\nlernen?',
      LumoSection.exercises:'Los gehts!\nÜbe fleißig –\ndu schaffst das!',
      LumoSection.progress: 'Schau wie weit\ndu schon\ngekommen bist!',
      LumoSection.rewards:  'Du hast so viel\nverdient –\nschau mal!',
      LumoSection.profile:  'Das bist du –\nsuperstark!',
      LumoSection.scanner:  'Mach ein Foto\ndeiner Aufgabe –\nich helfe dir!',
    };
    final moods = {
      LumoSection.home:     LumoMood.greet,
      LumoSection.learn:    LumoMood.point,
      LumoSection.exercises:LumoMood.wave,
      LumoSection.progress: LumoMood.think,
      LumoSection.rewards:  LumoMood.celebrate,
      LumoSection.profile:  LumoMood.idle,
      LumoSection.scanner:  LumoMood.point,
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
    update(_state.copyWith(
      stars: _state.stars + 3,
      xp: _state.xp + 20,
      solved: newSolved,
      practiceErrors: 0,
      mood: LumoMood.celebrate,
      lumoMessage: 'Super gemacht!\nDu bist der\nHammer! ⭐',
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
          ? 'Nicht so schlimm!\nZusammen schaffen\nwir das!'
          : 'Hmm, fast!\nNoch einmal\nprobieren?',
    ));
  }
}
