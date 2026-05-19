import 'package:flutter/foundation.dart';

import '../core/app_settings.dart';
import '../core/learning_profile_engine.dart';
import '../core/progress_repository.dart';
import '../core/recommendation_engine.dart';
import '../core/reward_wallet_repository.dart';
import '../core/scanned_work_analysis.dart';

enum LumoSection { home, learn, exercises, reading, games, tests, schoolwork, scanner, missions, progress, rewards, agent, profile, settings }
enum LumoMood { greet, point, celebrate, comfort, think, wave, idle }
enum LumoSessionKind { quickPractice, exerciseSet, test, schoolwork, tutoring }

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
  }) => LumoSessionState(
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

class LumoAppState extends ChangeNotifier {
  LumoSessionState _state = LumoSessionState();
  LumoSessionState get state => _state;

  final LearningProfileEngine _learningProfile = LearningProfileEngine();
  final ScannedWorkAnalysisEngine _scanAnalysis = const ScannedWorkAnalysisEngine();
  bool _learningProfileLoaded = false;
  bool _disposed = false;

  LearningProfileEngine get learningProfile => _learningProfile;
  bool get learningProfileLoaded => _learningProfileLoaded;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Belohne Sterne (z.B. nach Mini-Spiel / Kart-Lauf).
  /// Stoesst notifyListeners aus damit HUD/Dashboard sich aktualisieren.
  /// Schreibt sofort in die persistente RewardWallet -> bleibt nach Neustart.
  void addStars(int delta) {
    if (_disposed || delta == 0) return;
    _state = _state.copyWith(stars: (_state.stars + delta).clamp(0, 999999));
    _safeNotify();
    // Persistent in Wallet schreiben (fire-and-forget)
    RewardWalletRepository.instance.addStars(delta).catchError((_) {});
  }

  /// Belohne XP nach erfolgreichem Mini-Spiel / Kart-Lauf.
  /// Schreibt sofort in die persistente RewardWallet.
  void addXp(int delta) {
    if (_disposed || delta == 0) return;
    final newXp = (_state.xp + delta).clamp(0, 9999999);
    _state = _state.copyWith(xp: newXp);
    _safeNotify();
    RewardWalletRepository.instance.addXp(delta).catchError((_) {});
  }

  /// Beim App-Start aufgerufen: laedt die Wallet und schreibt
  /// Sterne/XP in den State zurueck.
  Future<void> hydrateFromWallet() async {
    if (_disposed) return;
    try {
      final wallet = await RewardWalletRepository.instance.load();
      if (_disposed) return;
      _state = _state.copyWith(
        stars: wallet.stars > 0 ? wallet.stars : _state.stars,
        xp: wallet.xp > 0 ? wallet.xp : _state.xp,
      );
      _safeNotify();
    } catch (_) {
      // Wallet-Fehler ist nicht App-kritisch
    }
  }

  Future<void> loadLearningProfile() async {
    if (_learningProfileLoaded || _disposed) return;
    try {
      await _learningProfile.load();
      if (_disposed) return;
      _learningProfileLoaded = true;
      _syncLearningRecommendation();
    } catch (_) {
      if (_disposed) return;
      _state = _state.copyWith(mood: LumoMood.comfort, lumoMessage: 'Ich starte sicher.\nGleich geht es weiter.');
    }
    _safeNotify();
  }

  Future<void> recordLearningAnswer({required String subject, required String unit, required bool correct, bool hintUsed = false}) async {
    if (_disposed) return;
    try {
      if (!_learningProfileLoaded) {
        await _learningProfile.load();
        _learningProfileLoaded = true;
      }
      await _learningProfile.recordAnswer(subject: subject, unit: unit, isCorrect: correct, hintUsed: hintUsed);
      _syncLearningRecommendation();
      _safeNotify();
    } catch (_) {}
  }

  Future<ScannedWorkAnalysis> analyzeScannedWork(String rawText) async {
    if (!_learningProfileLoaded) {
      try {
        await _learningProfile.load();
        _learningProfileLoaded = true;
      } catch (_) {}
    }
    final analysis = _scanAnalysis.analyze(
      rawText: rawText,
      grade: _state.grade,
      existingSkills: _learningProfileLoaded ? _learningProfile.skills : <String, SkillRecord>{},
    );
    final newWeak = Map<String, int>.from(_state.weakSkills);
    for (final unit in analysis.weakUnits) {
      newWeak[unit] = (newWeak[unit] ?? 0) + 1;
      await recordLearningAnswer(subject: analysis.nextPracticeSubject, unit: unit, correct: false);
    }
    for (final unit in analysis.strengthUnits) {
      await recordLearningAnswer(subject: analysis.nextPracticeSubject, unit: unit, correct: true);
    }
    update(_state.copyWith(
      section: LumoSection.exercises,
      subject: analysis.nextPracticeSubject,
      unit: analysis.nextPracticeUnit,
      weakSkills: newWeak,
      mood: analysis.hasWeaknesses ? LumoMood.comfort : LumoMood.point,
      lumoMessage: analysis.childSummary,
      sessionKind: analysis.workType == ScannedWorkType.schoolwork || analysis.workType == ScannedWorkType.test ? LumoSessionKind.test : LumoSessionKind.quickPractice,
      lastScanAnalysis: analysis,
    ));
    return analysis;
  }

  Recommendation? topLearningRecommendation() => _learningProfileLoaded ? _learningProfile.topRecommendation(dailyGoalTarget: _state.settings.dailyGoal) : null;

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
    try {
      await _learningProfile.reset();
    } catch (_) {}
    _safeNotify();
  }

  void update(LumoSessionState next) {
    if (_disposed) return;
    _state = next;
    _safeNotify();
  }

  void updateSettings(AppSettings settings) {
    _state = _state.copyWith(settings: settings);
    _syncLearningRecommendation();
    _safeNotify();
  }

  void setSection(LumoSection section) {
    final messages = <LumoSection, String>{
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
    final moods = <LumoSection, LumoMood>{
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
    update(_state.copyWith(section: section, mood: moods[section], lumoMessage: messages[section]));
  }

  void correctAnswer(String unit) {
    final solved = Map<String, int>.from(_state.solved);
    solved[unit] = (solved[unit] ?? 0) + 1;
    update(_state.copyWith(stars: _state.stars + 3, xp: _state.xp + 20, solved: solved, practiceErrors: 0, mood: LumoMood.celebrate, lumoMessage: 'Juhu!\nDas war richtig.\nWeiter so! ⭐'));
  }

  void wrongAnswer(String unit) {
    final weak = Map<String, int>.from(_state.weakSkills);
    weak[unit] = (weak[unit] ?? 0) + 1;
    final errors = _state.practiceErrors + 1;
    update(_state.copyWith(
      weakSkills: weak,
      practiceErrors: errors,
      mood: errors >= 2 ? LumoMood.comfort : LumoMood.think,
      lumoMessage: errors >= 2 ? 'Ganz ruhig.\nIch zeige dir\nden Weg.' : 'Fast!\nWir schauen\nnochmal hin.',
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
