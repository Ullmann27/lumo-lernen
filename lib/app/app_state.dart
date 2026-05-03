import 'package:flutter/foundation.dart';

import '../core/app_settings.dart';
import '../core/learning_profile_engine.dart';
import '../core/progress_repository.dart';
import '../core/recommendation_engine.dart';
import '../core/scanned_work_analysis.dart';

enum LumoSection {
  home,
  learn,
  exercises,
  reading,
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

enum LumoSessionKind {
  quickPractice,
  exerciseSet,
  test,
  schoolwork,
  tutoring,
}

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
    this.learningRecommendationText,
    this.learningRecommendationSubject,
    this.learningRecommendationUnit,
    this.sessionKind = LumoSessionKind.quickPractice,
    this.lastScanAnalysis,
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
  String? learningRecommendationText;
  String? learningRecommendationSubject;
  String? learningRecommendationUnit;
  LumoSessionKind sessionKind;
  ScannedWorkAnalysis? lastScanAnalysis;

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
    String? learningRecommendationText,
    String? learningRecommendationSubject,
    String? learningRecommendationUnit,
    LumoSessionKind? sessionKind,
    ScannedWorkAnalysis? lastScanAnalysis,
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
      learningRecommendationText: learningRecommendationText ?? this.learningRecommendationText,
      learningRecommendationSubject: learningRecommendationSubject ?? this.learningRecommendationSubject,
      learningRecommendationUnit: learningRecommendationUnit ?? this.learningRecommendationUnit,
      sessionKind: sessionKind ?? this.sessionKind,
      lastScanAnalysis: lastScanAnalysis ?? this.lastScanAnalysis,
    );
  }
}

class LumoAppState extends ChangeNotifier {
  LumoSessionState _state = LumoSessionState();
  LumoSessionState get state => _state;

  final LearningProfileEngine _learningProfile = LearningProfileEngine();
  final ScannedWorkAnalysisEngine _scanAnalysis = const ScannedWorkAnalysisEngine();
  bool _learningProfileLoaded = false;

  LearningProfileEngine get learningProfile => _learningProfile;
  bool get learningProfileLoaded => _learningProfileLoaded;

  Future<void> loadLearningProfile() async {
    if (_learningProfileLoaded) return;
    await _learningProfile.load();
    _learningProfileLoaded = true;
    _syncLearningRecommendation();
    notifyListeners();
  }

  Future<void> recordLearningAnswer({
    required String subject,
    required String unit,
    required bool correct,
    bool hintUsed = false,
  }) async {
    if (!_learningProfileLoaded) {
      await _learningProfile.load();
      _learningProfileLoaded = true;
    }
    await _learningProfile.recordAnswer(
      subject: subject,
      unit: unit,
      isCorrect: correct,
      hintUsed: hintUsed,
    );
    _syncLearningRecommendation();
    notifyListeners();
  }

  Future<ScannedWorkAnalysis> analyzeScannedWork(String rawText) async {
    if (!_learningProfileLoaded) {
      await _learningProfile.load();
      _learningProfileLoaded = true;
    }
    final analysis = _scanAnalysis.analyze(
      rawText: rawText,
      grade: _state.grade,
      existingSkills: _learningProfile.skills,
    );

    final newWeak = Map<String, int>.from(_state.weakSkills);
    for (final unit in analysis.weakUnits) {
      newWeak[unit] = (newWeak[unit] ?? 0) + 1;
      await _learningProfile.recordAnswer(
        subject: analysis.nextPracticeSubject,
        unit: unit,
        isCorrect: false,
        hintUsed: false,
      );
    }
    for (final unit in analysis.strengthUnits) {
      await _learningProfile.recordAnswer(
        subject: analysis.nextPracticeSubject,
        unit: unit,
        isCorrect: true,
        hintUsed: false,
      );
    }

    _syncLearningRecommendation();
    _state = _state.copyWith(
      section: LumoSection.exercises,
      subject: analysis.nextPracticeSubject,
      unit: analysis.nextPracticeUnit,
      weakSkills: newWeak,
      mood: analysis.hasWeaknesses ? LumoMood.comfort : LumoMood.point,
      lumoMessage: analysis.childSummary,
      sessionKind: analysis.workType == ScannedWorkType.schoolwork || analysis.workType == ScannedWorkType.test
          ? LumoSessionKind.test
          : LumoSessionKind.quickPractice,
      lastScanAnalysis: analysis,
    );
    notifyListeners();
    return analysis;
  }

  Recommendation? topLearningRecommendation() {
    if (!_learningProfileLoaded) return null;
    return _learningProfile.topRecommendation(
      dailyGoalTarget: _state.settings.dailyGoal,
    );
  }

  void _syncLearningRecommendation() {
    final recommendation = topLearningRecommendation();
    if (recommendation == null) return;
    _state = _state.copyWith(
      learningRecommendationText: recommendation.message,
      learningRecommendationSubject: recommendation.subject,
      learningRecommendationUnit: recommendation.unit,
    );
  }

  int learningDailyDone() => _learningProfileLoaded ? _learningProfile.dailyDone() : 0;

  int learningStreakDays() => _learningProfileLoaded ? _learningProfile.currentStreakDays() : 0;

  Map<String, List<String>> learningWeaknessesBySubject() => _learningProfileLoaded ? _learningProfile.weaknessesBySubject() : <String, List<String>>{};

  Map<String, SkillRecord> learningSkills() => _learningProfileLoaded ? _learningProfile.skills : <String, SkillRecord>{};

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
    _syncLearningRecommendation();
    notifyListeners();
  }

  void setSection(LumoSection section) {
    final messages = {
      LumoSection.home: 'Hallo!\nWomit wollen wir\nheute lernen?',
      LumoSection.learn: 'Such dir ein\nFach aus. Ich\nbegleite dich!',
      LumoSection.exercises: 'Los gehts!\nEine kleine Übung\nreicht schon.',
      LumoSection.reading: 'Ich höre dir\nbeim Lesen zu.\nGanz ruhig!',
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
      LumoSection.reading: LumoMood.think,
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
      lumoMessage: errors >= 3 ? 'Ganz ruhig.\nIch zeige dir\nden Weg.' : 'Fast!\nWir schauen\nnochmal hin.',
    ));
  }
}
