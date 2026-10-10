import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_settings.dart';
import '../core/learning_profile_engine.dart';
import '../core/legacy_learning_data.dart';
import '../core/lumo_cosmos.dart';
import '../core/progress_repository.dart';
import '../core/recommendation_engine.dart';
import '../core/attempt_log_repository.dart';
import '../core/lumo_error_log.dart';
import '../core/reward_wallet_repository.dart';
import '../core/school_repository.dart';
import '../domain/school/attempt.dart';
import '../domain/school/competency.dart';
import '../core/scanned_work_analysis.dart';
import '../core/settings_repository.dart';

enum LumoSection {
  home,
  learn,
  exercises,
  reading,
  games,
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

class _PendingRewardWrite {
  const _PendingRewardWrite({this.stars = 0, this.xp = 0, this.cardsWon});
  final int stars;
  final int xp;
  final bool? cardsWon;

  Future<RewardWallet> persist(RewardWalletRepository wallet) =>
      cardsWon == null
          ? wallet.applyRewardDelta(starsDelta: stars, xpDelta: xp)
          : wallet.awardLumoCardsResult(won: cardsWon!);
}

enum LumoSessionKind { quickPractice, exerciseSet, test, schoolwork, tutoring }

class LumoSessionState {
  LumoSessionState({
    this.section = LumoSection.home,
    this.childName = 'Lena',
    this.grade = 1,
    this.subject = 'Alle',
    this.unit = 'Alle',
    this.stars = 0,
    this.xp = 0,
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
    this.testLevel = 0,
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

  /// Schwierigkeit eines Tests: -1 leicht (Aufgaben eine Klasse darunter),
  /// 0 mittel (eigene Klasse), 1 schwer (eine Klasse darüber).
  int testLevel;
  ScannedWorkAnalysis? lastScanAnalysis;

  int get level => xp ~/ 400 + 1;
  int get levelXpPercent => ((xp % 400) / 4).round().clamp(0, 100);
  int get progressPercent =>
      ((solved.values.fold(0, (a, b) => a + b) / 30) * 100).round().clamp(
            0,
            100,
          );

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
    int? testLevel,
    ScannedWorkAnalysis? lastScanAnalysis,
  }) =>
      LumoSessionState(
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
        learningRecommendationText:
            learningRecommendationText ?? this.learningRecommendationText,
        learningRecommendationSubject:
            learningRecommendationSubject ?? this.learningRecommendationSubject,
        learningRecommendationUnit:
            learningRecommendationUnit ?? this.learningRecommendationUnit,
        sessionKind: sessionKind ?? this.sessionKind,
        testLevel: testLevel ?? this.testLevel,
        lastScanAnalysis: lastScanAnalysis ?? this.lastScanAnalysis,
      );
}

/// An accepted learning action keeps this owner through every asynchronous
/// write. A selection change invalidates UI continuations, not its ownership.
class LearningProfileLease {
  LearningProfileLease._(
    this._session,
    this.generation,
    this._resetEpoch,
    this._sessionEpoch,
    this.logStudentId,
  );

  final _LearningSession _session;
  final int generation;
  final int _resetEpoch;
  final int _sessionEpoch;
  final String logStudentId;
  String get studentId => _session.studentId;
  LearningProfileEngine get profile => _session.profile;
  CosmosWorld get cosmos => _session.cosmos;
}

class _LearningSession {
  _LearningSession(this.studentId, this.profile)
    : cosmos = CosmosWorld(studentId: studentId);
  final String studentId;
  final LearningProfileEngine profile;
  final CosmosWorld cosmos;
  int epoch = 0;
}

/// An accepted module action keeps its original selection across storage
/// retries and reserves that child's destination until the action settles.
class LearningProfileAction {
  LearningProfileAction._(this._app)
    : _generation = _app._profileGeneration,
      _resetEpoch = _app._learningResetEpoch,
      _selection = _app.school.activeStudentId(),
      _selectionKnown = _app.school.hasLoadedSelection,
      _schoolStudentId = _app.school.cachedActiveStudentId;

  final LumoAppState _app;
  final int _generation;
  final int _resetEpoch;
  Future<String?>? _selection;
  bool _selectionKnown;
  String? _schoolStudentId;
  LearningProfileLease? _lease;
  Future<LearningProfileLease>? _resolving;
  bool _closed = false;

  bool get invalidated =>
      _closed ||
      _app._resetting ||
      _resetEpoch != _app._learningResetEpoch ||
      (_lease != null && !_app.canUseLearningLease(_lease!)) ||
      (!_selectionKnown &&
          _selection == null &&
          _generation != _app._profileGeneration);

  bool _mayBelongTo(String id) => _lease != null
      ? _lease!.studentId == id
      : !_selectionKnown || _schoolStudentId == null || _schoolStudentId == id;

  Future<LearningProfileLease> resolve() {
    if (invalidated) {
      return Future.error(StateError('Learning action was reset'));
    }
    if (_lease != null) return Future.value(_lease);
    return _resolving ??= _app._trackLearning(_resolve());
  }

  Future<LearningProfileLease> _resolve() async {
    try {
      if (!_selectionKnown) {
        try {
          _schoolStudentId = await (_selection ??= _app.school
              .activeStudentId());
          _selectionKnown = true;
        } catch (_) {
          _selection = null;
          rethrow;
        }
      }
      final lease = await _app._captureLearningProfile(
        Future.value(_schoolStudentId),
        _generation,
        _resetEpoch,
      );
      if (invalidated) throw StateError('Learning action was reset');
      _lease = lease;
      return lease;
    } finally {
      // A failed local-ID/platform read may be retried, without selecting the
      // child who happened to become visible during the failed write.
      _resolving = null;
    }
  }

  void close() {
    _closed = true;
    _app._learningActions.remove(this);
  }
}

class LumoAppState extends ChangeNotifier {
  LumoAppState(
      {RewardWalletRepository? walletRepository,
      LearningProfileEngine? learningProfile,
      LearningProfileEngine Function(String studentId)? learningProfileFactory,
      AttemptLogRepository? attemptLog})
      : _walletRepository = walletRepository ?? RewardWalletRepository.instance,
        _learningProfile = learningProfile ?? LearningProfileEngine(),
        _learningProfileFactory = learningProfileFactory,
        attemptLog = attemptLog ?? AttemptLogRepository() {
    _localProfileSeed = _learningProfile;
    school.addListener(_schoolSelectionChanged);
  }

  /// Aufgabenprotokoll des Kindes (Grundlage für Lernbericht und Lehrerbereich).
  final AttemptLogRepository attemptLog;

  /// Schulstruktur (Klassen, Gruppen, Aufgaben) und das Kind dieses Geräts.
  final SchoolRepository school = SchoolRepository();
  int _attemptSerial = 0;

  final RewardWalletRepository _walletRepository;
  LumoSessionState _state = LumoSessionState();
  LumoSessionState get state => _state;

  LearningProfileEngine _learningProfile;
  late LearningProfileEngine _localProfileSeed;
  final LearningProfileEngine Function(String)? _learningProfileFactory;
  final LegacyLearningDataRepository legacyLearningData = LegacyLearningDataRepository();
  final Map<String, _LearningSession> _learningSessions = {};
  final Set<Future<dynamic>> _learningOperations = {};
  final Set<LearningProfileAction> _learningActions = {};
  final Set<String> _resolvingLegacy = {};
  _LearningSession? _activeLearningSession;
  int _learningResetEpoch = 0;

  final ScannedWorkAnalysisEngine _scanAnalysis =
      const ScannedWorkAnalysisEngine();
  bool _learningProfileLoaded = false;
  bool _disposed = false;
  bool _resetting = false;
  int _profileGeneration = 0;
  bool _settingsLoaded = false;
  Future<void>? _settingsLoad;

  bool get settingsLoaded => _settingsLoaded;
  int get profileGeneration => _profileGeneration;
  bool get resetting => _resetting;

  Future<void> ensureSettingsLoaded() => _settingsLoad ??= _loadSettings();

  Future<void> _loadSettings() async {
    final generation = _profileGeneration;
    final settings = await SettingsRepository.load();
    if (_disposed || generation != _profileGeneration) return;
    _settingsLoaded = true;
    updateSettings(settings);
    try {
      final wallet = await _walletRepository.load();
      if (_disposed || generation != _profileGeneration) return;
      _lumoCardsWinStreak = wallet.lumoCardsWinStreak;
      _safeNotify();
    } catch (_) {
      // A rewards read failure must not block the parent's explicit settings.
    }
  }

  Future<void> _pendingRewards = Future<void>.value();
  Future<void>? _rewardDrain;
  final _rewardWrites = Queue<_PendingRewardWrite>();
  String? _rewardSaveError;

  String? get rewardSaveError => _rewardSaveError;
  bool get hasPendingRewards => _rewardWrites.isNotEmpty;

  Future<void> flushRewards() {
    if (_rewardDrain != null) return _rewardDrain!;
    if (_rewardWrites.isNotEmpty) return _beginRewardDrain();
    return _pendingRewards;
  }

  Future<void> retryRewards() => flushRewards();

  void _persistRewards({int stars = 0, int xp = 0}) {
    if (stars == 0 && xp == 0) return;
    _rewardWrites.add(_PendingRewardWrite(stars: stars, xp: xp));
    _beginRewardDrain();
  }

  Future<void> _beginRewardDrain() {
    if (_rewardDrain != null) return _rewardDrain!;
    final pending = _drainRewardWrites();
    _rewardDrain = pending;
    _pendingRewards = pending;
    // Void UI callers have an error handler, while flush/retry callers still
    // receive the original failure and cannot acknowledge an unsaved reward.
    unawaited(pending.then<void>((_) {
      _rewardDrain = null;
    }, onError: (Object _, StackTrace __) {
      _rewardDrain = null;
    }));
    return pending;
  }

  Future<void> _drainRewardWrites() async {
    try {
      do {
        while (_rewardWrites.isNotEmpty) {
          final wallet = await _rewardWrites.first.persist(_walletRepository);
          _rewardWrites.removeFirst();
          _lumoCardsWinStreak = wallet.lumoCardsWinStreak;
        }
        final saved = _walletRepository.snapshot;
        final hadError = _rewardSaveError != null;
        _rewardSaveError = null;
        _state = _state.copyWith(
          stars: saved.stars,
          xp: saved.xp,
          lumoMessage: hadError
              ? 'Deine Sterne sind jetzt gespeichert. Weiter geht’s!'
              : _state.lumoMessage,
        );
        _safeNotify();
        // A listener may award another lesson while refreshing its UI. That
        // reward belongs to this flush too, rather than waiting for another one.
      } while (_rewardWrites.isNotEmpty);
    } catch (_) {
      _rewardSaveError = 'Deine Sterne warten noch aufs Speichern. '
          'Sobald dein Gerät wieder speichern kann, versuchen wir es erneut.';
      _state = _state.copyWith(
          lumoMessage: _rewardSaveError, mood: LumoMood.comfort);
      _safeNotify();
      rethrow;
    }
  }

  int get weeklyProgressPercent {
    final daily = learningProfileDailyMap();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final goal = _state.settings.dailyGoal;
    var completed = 0;
    for (var offset = 0; offset < 7; offset++) {
      final day = DateTime(monday.year, monday.month, monday.day + offset);
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      completed += (daily[key] ?? 0).clamp(0, goal);
    }
    return (completed * 100 / (goal * 7)).round();
  }

  LearningProfileEngine get learningProfile => _learningProfile;
  bool get learningProfileLoaded => _learningProfileLoaded;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Belohne Sterne (z.B. nach Mini-Spiel / Kart-Lauf).
  /// Stoesst notifyListeners aus damit HUD/Dashboard sich aktualisieren.
  /// Schreibt sofort in die persistente RewardWallet -> bleibt nach Neustart.
  void addStars(int delta) {
    if (_disposed || _resetting || delta == 0) return;
    _state = _state.copyWith(stars: (_state.stars + delta).clamp(0, 999999));
    _persistRewards(stars: delta);
    _safeNotify();
  }

  /// Belohne XP nach erfolgreichem Mini-Spiel / Kart-Lauf.
  /// Schreibt sofort in die persistente RewardWallet.
  void addXp(int delta) {
    if (_disposed || _resetting || delta == 0) return;
    final newXp = (_state.xp + delta).clamp(0, 9999999);
    _state = _state.copyWith(xp: newXp);
    _persistRewards(xp: delta);
    _safeNotify();
  }

  /// Books a game reward's stars and XP in one persisted wallet transaction.
  void addRewards({required int stars, required int xp}) {
    if (_disposed || _resetting || (stars == 0 && xp == 0)) return;
    _state = _state.copyWith(
      stars: (_state.stars + stars).clamp(0, 999999),
      xp: (_state.xp + xp).clamp(0, 9999999),
    );
    _persistRewards(stars: stars, xp: xp);
    _safeNotify();
  }

  /// Beim App-Start aufgerufen: laedt die Wallet und schreibt
  /// Sterne/XP in den State zurueck.
  Future<void> hydrateFromWallet() async {
    if (_disposed || _resetting) return;
    final generation = _profileGeneration;
    try {
      while (!_disposed && generation == _profileGeneration) {
        final pending = flushRewards();
        await pending;
        final wallet = await _walletRepository.load();
        if (_disposed || generation != _profileGeneration) return;
        // Rewards can arrive while disk loading is in progress. Only install
        // a snapshot once every reward queued during that load is persisted.
        if (!identical(pending, _pendingRewards)) continue;
        _state = _state.copyWith(stars: wallet.stars, xp: wallet.xp);
        _lumoCardsWinStreak = wallet.lumoCardsWinStreak;
        _safeNotify();
        return;
      }
    } catch (_) {
      // Wallet-Fehler ist nicht App-kritisch
    }
  }

  _LearningSession _sessionFor(String studentId, {required bool local}) =>
      _learningSessions.putIfAbsent(
        studentId,
        () => _LearningSession(
          studentId,
          _learningProfileFactory?.call(studentId) ??
              (local
                  ? _localProfileSeed
                  : LearningProfileEngine(
                      repository: ProgressRepository(studentId: studentId),
                    )),
        ),
      );

  /// Starts identity capture synchronously, before the caller's first await.
  Future<LearningProfileLease> captureLearningProfile() {
    final selected = school.activeStudentId();
    final generation = _profileGeneration;
    final epoch = _learningResetEpoch;
    return _trackLearning(_captureLearningProfile(selected, generation, epoch));
  }

  LearningProfileAction beginLearningAction() {
    final action = LearningProfileAction._(this);
    _learningActions.add(action);
    return action;
  }

  Future<LearningProfileLease> _captureLearningProfile(
    Future<String?> selected,
    int generation,
    int epoch,
  ) async {
    final schoolId = await selected;
    final id = schoolId ?? await legacyLearningData.localStudentId();
    if (_resolvingLegacy.contains(id)) {
      throw LegacyLearningDataException('assignment-busy');
    }
    final session = _sessionFor(id, local: schoolId == null);
    return LearningProfileLease._(
      session,
      generation,
      epoch,
      session.epoch,
      schoolId ?? 'self',
    );
  }

  bool canUseLearningLease(LearningProfileLease lease) =>
      !_resetting &&
      lease._resetEpoch == _learningResetEpoch &&
      lease._sessionEpoch == lease._session.epoch &&
      !_resolvingLegacy.contains(lease.studentId);

  bool isCurrentLearningLease(LearningProfileLease lease) =>
      !_disposed &&
      canUseLearningLease(lease) &&
      lease.generation == _profileGeneration &&
      identical(_activeLearningSession, lease._session);

  Future<T> _trackLearning<T>(Future<T> operation) {
    _learningOperations.add(operation);
    unawaited(
      operation.then<void>(
        (_) => _learningOperations.remove(operation),
        onError: (Object _, StackTrace __) {
          _learningOperations.remove(operation);
        },
      ),
    );
    return operation;
  }

  Future<void> _drainLearningOperations() async {
    while (_learningOperations.isNotEmpty) {
      final pending = List<Future<dynamic>>.of(_learningOperations);
      await Future.wait(
        pending.map(
          (operation) => operation.then<void>(
            (_) {},
            onError: (Object _, StackTrace __) {},
          ),
        ),
      );
    }
  }

  void _clearLearningDisplay() {
    _state = _state.copyWith(
      solved: {},
      weakSkills: {},
      practiceErrors: 0,
      lastGrade: 0,
    );
    _state.learningRecommendationText = null;
    _state.learningRecommendationSubject = null;
    _state.learningRecommendationUnit = null;
    _state.lastScanAnalysis = null;
  }

  void _schoolSelectionChanged() {
    if (_disposed || _resetting) return;
    _profileGeneration++;
    _activeLearningSession = null;
    _learningProfileLoaded = false;
    final selected = school.cachedActiveStudentId;
    _learningProfile = selected == null
        ? _localProfileSeed
        : _sessionFor(selected, local: false).profile;
    _clearLearningDisplay();
    _safeNotify();
    unawaited(loadLearningProfile());
  }

  void _installLearningLease(LearningProfileLease lease) {
    if (_disposed ||
        !canUseLearningLease(lease) ||
        lease.generation != _profileGeneration) {
      return;
    }
    if (!identical(_activeLearningSession, lease._session)) {
      _clearLearningDisplay();
    }
    _activeLearningSession = lease._session;
    _learningProfile = lease.profile;
    _learningProfileLoaded = lease.profile.isLoaded;
  }

  Future<void> prepareLearningLease(LearningProfileLease lease) =>
      _trackLearning(_prepareLearningLease(lease));

  Future<void> _prepareLearningLease(LearningProfileLease lease) async {
    if (!canUseLearningLease(lease)) {
      throw StateError('Learning profile was reset or is being assigned');
    }
    _installLearningLease(lease);
    await lease.profile.load();
    if (isCurrentLearningLease(lease)) {
      _learningProfileLoaded = true;
      _syncLearningRecommendation();
      _safeNotify();
    }
  }

  Future<void> loadLearningProfile() {
    if (_disposed || _resetting) return Future<void>.value();
    final lease = captureLearningProfile();
    return _trackLearning(_loadActiveLearningProfile(lease));
  }

  Future<void> _loadActiveLearningProfile(
    Future<LearningProfileLease> source,
  ) async {
    LearningProfileLease? lease;
    try {
      lease = await source;
      await _prepareLearningLease(lease);
    } catch (_) {
      if (_disposed ||
          (lease != null && lease.generation != _profileGeneration)) {
        return;
      }
      _state = _state.copyWith(
        mood: LumoMood.comfort,
        lumoMessage: 'Ich starte sicher.\nGleich geht es weiter.',
      );
      _safeNotify();
    }
  }

  Future<void> recordLearningAnswer({
    required String subject,
    required String unit,
    required bool correct,
    bool hintUsed = false,
    bool requireSaved = false,
    String prompt = '',
    String given = '',
    String expected = '',
    int? durationMs,
    double? score,
    LearningProfileLease? lease,
  }) {
    if (_disposed || _resetting) return Future<void>.value();
    final source = lease == null
        ? captureLearningProfile()
        : Future<LearningProfileLease>.value(lease);
    Future<void> record() async {
      LearningProfileLease? owner;
      try {
        owner = await source;
        await _prepareLearningLease(owner);
        if (!canUseLearningLease(owner)) return;
        try {
          await owner.profile.recordAnswer(
            subject: subject,
            unit: unit,
            isCorrect: correct,
            hintUsed: hintUsed,
          );
        } finally {
          // A failed progress write is retried without counting again. Keep
          // this accepted attempt's original owner in its log during retry.
          await _logAttempt(
            studentId: owner.logStudentId,
            subject: subject,
            unit: unit,
            correct: correct,
            hintUsed: hintUsed,
            prompt: prompt,
            given: given,
            expected: expected,
            durationMs: durationMs,
            score: score,
          );
        }
        if (isCurrentLearningLease(owner)) {
          _syncLearningRecommendation();
          _safeNotify();
        }
      } catch (_) {
        if (requireSaved) rethrow;
      }
    }

    return _trackLearning(record());
  }

  Future<void> grantCosmosReward({
    required String subjectId,
    required bool isMath,
    required bool isPerfect,
    LearningProfileLease? lease,
    bool requireSaved = false,
  }) {
    if (_disposed || _resetting) return Future<void>.value();
    final source = lease == null
        ? captureLearningProfile()
        : Future<LearningProfileLease>.value(lease);
    Future<void> grant() async {
      LearningProfileLease? owner;
      try {
        owner = await source;
        if (!canUseLearningLease(owner)) return;
        await owner.cosmos.load();
        if (!canUseLearningLease(owner)) return;
        await owner.cosmos.grantReward(
          subjectId: subjectId,
          isMath: isMath,
          isPerfect: isPerfect,
        );
        if (isCurrentLearningLease(owner)) _safeNotify();
      } catch (_) {
        if (owner != null && isCurrentLearningLease(owner)) {
          _state = _state.copyWith(
            mood: LumoMood.comfort,
            lumoMessage: 'Deine Lernwelt wartet noch aufs Speichern.',
          );
          _safeNotify();
        }
        if (requireSaved) rethrow;
      }
    }

    return _trackLearning(grant());
  }

  Future<void> flushCosmos({LearningProfileLease? lease}) {
    final source = lease == null
        ? captureLearningProfile()
        : Future<LearningProfileLease>.value(lease);
    return _trackLearning(() async {
      final owner = await source;
      if (!canUseLearningLease(owner)) return;
      await owner.cosmos.flush();
      if (isCurrentLearningLease(owner)) _safeNotify();
    }());
  }

  Future<void> loadCosmos({required LearningProfileLease lease}) =>
      _trackLearning(() async {
        await _prepareLearningLease(lease);
        if (!canUseLearningLease(lease)) return;
        await lease.cosmos.load();
      }());

  /// Called only after the parent's explicit destination confirmation.
  Future<void> resolveLegacyLearningData(String studentId) async {
    final id = studentId.trim();
    if (_learningActions.any((action) => action._mayBelongTo(id))) {
      throw LegacyLearningDataException('assignment-busy');
    }
    if (_resetting || !_resolvingLegacy.add(id)) {
      throw LegacyLearningDataException('assignment-busy');
    }
    try {
      await _drainLearningOperations();
      if (_learningActions.any((action) => action._mayBelongTo(id))) {
        throw LegacyLearningDataException('assignment-busy');
      }
      final existing = _learningSessions[id];
      if ((existing?.profile.hasUnsavedChanges ?? false) ||
          (existing?.cosmos.hasPendingSave ?? false)) {
        throw LegacyLearningDataException('destination-not-empty');
      }
      await legacyLearningData.assignTo(id);
      if (existing != null) existing.epoch++;
      _learningSessions.remove(id);
      if (id == await legacyLearningData.localStudentId()) {
        _localProfileSeed = LearningProfileEngine();
      }
      if (_activeLearningSession?.studentId == id) {
        _activeLearningSession = null;
        _learningProfileLoaded = false;
        _profileGeneration++;
        _clearLearningDisplay();
      }
    } finally {
      _resolvingLegacy.remove(id);
    }
    await loadLearningProfile();
    _safeNotify();
  }

  /// Einträge, die noch nicht gespeichert werden konnten. Sie gehen nicht
  /// verloren: Beim nächsten Eintrag (oder [flushAttemptLog]) wird erneut
  /// geschrieben. Die Oberfläche kann [unsavedAttempts] anzeigen.
  final List<Attempt> _unsavedAttempts = <Attempt>[];
  int get unsavedAttempts => _unsavedAttempts.length;

  /// Schreibt die Antwort ins Aufgabenprotokoll. Ein Fehler hier verhindert
  /// nie den Lernfortschritt, wird aber gemerkt und erneut versucht.
  Future<void> _logAttempt({
    required String studentId,
    required String subject,
    required String unit,
    required bool correct,
    required bool hintUsed,
    required String prompt,
    required String given,
    required String expected,
    int? durationMs,
    double? score,
  }) async {
    final now = DateTime.now();
    _unsavedAttempts.add(Attempt(
      id: '${now.microsecondsSinceEpoch}-${_attemptSerial++}',
      studentId: studentId,
      subject: subject,
      unit: unit,
      competency: const CompetencyClassifier()
          .classify(subject: subject, unit: unit, prompt: prompt),
      correct: correct,
      at: now,
      hintUsed: hintUsed,
      prompt: prompt,
      given: given,
      expected: expected,
      durationMs: durationMs,
      score: score,
    ));
    await flushAttemptLog();
  }

  /// Versucht, alle noch offenen Protokolleinträge zu speichern.
  /// Liefert true, wenn nichts mehr offen ist.
  Future<bool> flushAttemptLog() async {
    if (_unsavedAttempts.isEmpty) return true;
    final batch = List<Attempt>.of(_unsavedAttempts);
    try {
      await attemptLog.appendAll(batch);
      _unsavedAttempts.removeWhere(batch.contains);
      return _unsavedAttempts.isEmpty;
    } catch (error, stack) {
      // Keine Kinderdaten ins Fehlerprotokoll, nur Art und Anzahl.
      unawaited(LumoErrorLog.instance.record(FlutterErrorDetails(
        exception: StateError(
            'Aufgabenprotokoll: ${batch.length} Einträge warten aufs Speichern'),
        stack: stack,
        library: 'attempt_log',
      )));
      _safeNotify();
      return false;
    }
  }

  /// Retries the existing learning state without counting the answer again.
  Future<void> flushLearningProgress({LearningProfileLease? lease}) {
    final source = lease == null
        ? captureLearningProfile()
        : Future<LearningProfileLease>.value(lease);
    return _trackLearning(() async {
      final owner = await source;
      if (!canUseLearningLease(owner)) return;
      await owner.profile.flush();
      await flushAttemptLog();
      if (isCurrentLearningLease(owner)) {
        _syncLearningRecommendation();
        _safeNotify();
      }
    }());
  }

  Future<ScannedWorkAnalysis> analyzeScannedWork(String rawText) async {
    final lease = await captureLearningProfile();
    try {
      await prepareLearningLease(lease);
    } catch (_) {}
    final analysis = _scanAnalysis.analyze(
      rawText: rawText,
      grade: _state.grade,
      existingSkills: lease.profile.isLoaded
          ? lease.profile.skills
          : <String, SkillRecord>{},
    );
    final newWeak = Map<String, int>.from(_state.weakSkills);
    for (final unit in analysis.weakUnits) {
      newWeak[unit] = (newWeak[unit] ?? 0) + 1;
      await recordLearningAnswer(
        subject: analysis.nextPracticeSubject,
        unit: unit,
        correct: false,
        lease: lease,
      );
    }
    for (final unit in analysis.strengthUnits) {
      await recordLearningAnswer(
        subject: analysis.nextPracticeSubject,
        unit: unit,
        correct: true,
        lease: lease,
      );
    }
    if (!isCurrentLearningLease(lease)) return analysis;
    update(
      _state.copyWith(
        section: LumoSection.exercises,
        subject: analysis.nextPracticeSubject,
        unit: analysis.nextPracticeUnit,
        weakSkills: newWeak,
        mood: analysis.hasWeaknesses ? LumoMood.comfort : LumoMood.point,
        lumoMessage: analysis.childSummary,
        sessionKind:
            analysis.workType == ScannedWorkType.schoolwork ||
                analysis.workType == ScannedWorkType.test
            ? LumoSessionKind.test
            : LumoSessionKind.quickPractice,
        lastScanAnalysis: analysis,
      ),
    );
    return analysis;
  }

  Recommendation? topLearningRecommendation() => _learningProfileLoaded
      ? _learningProfile.topRecommendation(
          dailyGoalTarget: _state.settings.dailyGoal,
        )
      : null;

  void _syncLearningRecommendation() {
    final recommendation = topLearningRecommendation();
    if (recommendation == null) {
      _state.learningRecommendationText = null;
      _state.learningRecommendationSubject = null;
      _state.learningRecommendationUnit = null;
      return;
    }
    _state = _state.copyWith(
      learningRecommendationText: recommendation.message,
      learningRecommendationSubject: recommendation.subject,
      learningRecommendationUnit: recommendation.unit,
    );
  }

  int learningDailyDone() =>
      _learningProfileLoaded ? _learningProfile.dailyDone() : 0;
  int learningStreakDays() =>
      _learningProfileLoaded ? _learningProfile.currentStreakDays() : 0;

  /// 2026-06-06 Iter 27: ganzer Daily-Map fuer Streak-Wochen-Kalender.
  Map<String, int> learningProfileDailyMap() =>
      _learningProfileLoaded ? _learningProfile.daily : const <String, int>{};
  Map<String, List<String>> learningWeaknessesBySubject() =>
      _learningProfileLoaded
          ? _learningProfile.weaknessesBySubject()
          : <String, List<String>>{};
  Map<String, SkillRecord> learningSkills() => _learningProfileLoaded
      ? _learningProfile.skills
      : <String, SkillRecord>{};

  /// Heinz 2026-05-21: 'Lumo Cards ist zu langweilig'. Streak-Counter
  /// fuer aufeinanderfolgende Siege gegen Lumo - gibt Bonus-Sterne und
  /// macht Wiederspielen attraktiver. Wallet speichert Serie und Belohnung atomar.
  int _lumoCardsWinStreak = 0;
  int get lumoCardsWinStreak => _lumoCardsWinStreak;

  /// Wird nach einem Lumo-Cards-Spiel aufgerufen. Bei Sieg: Streak +1,
  /// Bonus-Sterne nach Streak-Hoehe. Bei Niederlage: Streak auf 0,
  /// kleiner Trost-Stern.
  Future<void> recordLumoCardsResult({required bool won}) {
    if (_disposed || _resetting) return Future<void>.value();
    _rewardWrites.add(_PendingRewardWrite(cardsWon: won));
    return _beginRewardDrain();
  }

  Future<void> resetLearningProfile() async {
    if (_disposed || _resetting) return;
    final owner = await captureLearningProfile();
    if (!canUseLearningLease(owner)) return;
    final id = owner.studentId;
    if (!_resolvingLegacy.add(id)) return;
    owner._session.epoch++;
    try {
      await _drainLearningOperations();
      await owner.profile.reset();
      await owner.cosmos.reset();
      await attemptLog.clear(studentId: owner.logStudentId);
      _unsavedAttempts.removeWhere(
        (attempt) => attempt.studentId == owner.logStudentId,
      );
      if (_activeLearningSession?.studentId == id) {
        _profileGeneration++;
        _activeLearningSession = null;
        _learningProfileLoaded = false;
        _clearLearningDisplay();
      }
    } finally {
      _resolvingLegacy.remove(id);
    }
    await loadLearningProfile();
    _safeNotify();
  }

  /// Heinz 2026-05-21: 'Mann muss immer die Moeglichkeit haben das Profil
  /// auf neu zurueckzusetzen - extra Option bei den Eltern.' Loescht das
  /// gespeicherte Kind-Profil, Sterne/XP, Cosmos, Reading- und Writing-
  /// Progress, Companion-State, Settings - im Grunde alle SharedPreferences-
  /// Keys der App. Danach startet die App wie beim ersten Mal mit dem
  /// Onboarding-Flow.
  Future<void> resetAllProfile() async {
    if (_disposed || _resetting) return;
    _resetting = true;
    _profileGeneration++;
    _learningResetEpoch++;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await const MethodChannel('lumo_lernen/bridge')
            .invokeMethod<bool>('clearGameEvents');
      }
    } on MissingPluginException {
      // Widget previews do not contain the native engine host.
    } catch (_) {
      _resetting = false;
      rethrow;
    }
    try {
      // Drain old writes before deleting their storage, then reset the cached
      // singleton too; otherwise the next earned star restores the old balance.
      await _pendingRewards;
      await school.pauseSelectionForReset();
      await _drainLearningOperations();
      if (_settingsLoad != null) await _settingsLoad;
      await _walletRepository.reset();
      for (final session in _learningSessions.values) {
        try { await session.profile.reset(); } catch (_) {}
        try { await session.cosmos.reset(); } catch (_) {}
        session.epoch++;
      }
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.clear()) throw StateError('Profile reset was not saved');
      school.resetSelectionCache();
      _learningSessions.clear();
      for (final action in _learningActions.toList()) {
        action.close();
      }
      _activeLearningSession = null;
      _localProfileSeed = LearningProfileEngine();
      _learningProfile = _localProfileSeed;
      _unsavedAttempts.clear();
      _state = LumoSessionState();
      _lumoCardsWinStreak = 0;
      _learningProfileLoaded = false;
      _settingsLoaded = false;
      _settingsLoad = null;
    } finally {
      school.resumeSelectionAfterReset();
      _resetting = false;
    }
    await ensureSettingsLoaded();
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
      LumoSection.games:
          'Wähle ein Spiel.\nSonnenhafen wartet\nauf unser Kart!',
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
      LumoSection.games: LumoMood.celebrate,
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
    update(
      _state.copyWith(
        section: section,
        mood: moods[section],
        lumoMessage: messages[section],
      ),
    );
  }

  void correctAnswer(String unit, {int stars = 3, int xp = 20}) {
    if (_disposed || _resetting) return;
    final earnedStars = stars.clamp(0, 12);
    final earnedXp = xp.clamp(0, 70);
    final solved = Map<String, int>.from(_state.solved);
    solved[unit] = (solved[unit] ?? 0) + 1;
    _persistRewards(stars: earnedStars, xp: earnedXp);
    update(
      _state.copyWith(
        stars: _state.stars + earnedStars,
        xp: _state.xp + earnedXp,
        solved: solved,
        practiceErrors: 0,
        mood: LumoMood.celebrate,
        lumoMessage: 'Juhu!\nDas war richtig.\nWeiter so! ⭐',
      ),
    );
  }

  void wrongAnswer(String unit) {
    final weak = Map<String, int>.from(_state.weakSkills);
    weak[unit] = (weak[unit] ?? 0) + 1;
    final errors = _state.practiceErrors + 1;
    update(
      _state.copyWith(
        weakSkills: weak,
        practiceErrors: errors,
        mood: errors >= 2 ? LumoMood.comfort : LumoMood.think,
        lumoMessage: errors >= 2
            ? 'Ganz ruhig.\nIch zeige dir\nden Weg.'
            : 'Fast!\nWir schauen\nnochmal hin.',
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    school.removeListener(_schoolSelectionChanged);
    school.dispose();
    super.dispose();
  }
}
