import 'discovery_progress.dart';
import '../domain/learning_intelligence/scene_memory.dart';
import '../domain/learning_intelligence/lesson_scene_engine.dart';
import '../domain/learning_intelligence/learning_scene_contract.dart';
import 'learning_journey.dart';
import 'progress_repository.dart';
import 'recommendation_engine.dart';
import 'weakness_detection_engine.dart';

/// Zentraler Lern-Engine-Service, der den Fortschritt eines Kindes verwaltet.
///
/// Diese Engine ist der einzige Schreib-Pfad für Lernfortschritt. Sie
/// koordiniert:
///
///   - ProgressRepository (lokale Persistenz)
///   - WeaknessDetectionEngine (Erkennung schwacher Themen)
///   - RecommendationEngine (kindgerechte Empfehlungen)
///
/// Verwendung im App-State:
///
///     final engine = LearningProfileEngine();
///     await engine.load();
///     await engine.recordAnswer(
///       subject: 'Mathematik',
///       unit: 'Plus bis 20',
///       isCorrect: true,
///       hintUsed: false,
///     );
///     final hint = engine.lumoMessage(dailyGoalDone: 3, dailyGoalTarget: 5);
class LearningProfileEngine {
  LearningProfileEngine({
    ProgressRepository? repository,
    WeaknessDetectionEngine? detector,
    RecommendationEngine? recommender,
  })  : _repo = repository ?? ProgressRepository(),
        _detector = detector ?? const WeaknessDetectionEngine(),
        _recommender = recommender ?? RecommendationEngine();

  final ProgressRepository _repo;
  final WeaknessDetectionEngine _detector;
  final RecommendationEngine _recommender;

  Map<String, SkillRecord> _skills = {};
  Map<String, int> _daily = {};
  Map<String, String> _lastTopics = {};
  bool _loaded = false;
  Future<void>? _loading;
  bool _dirty = false;
  DiscoveryProgress _discovery = DiscoveryProgress();
  bool _discoveryLoaded = false;
  Future<void>? _discoveryLoading;
  bool _discoveryDirty = false;
  int _discoveryRevision = 0;
  bool _discoveryPermissionPending = false;
  LearningJourney _journey = LearningJourney();
  bool _journeyLoaded = false;
  Future<void>? _journeyLoading;
  bool _journeyDirty = false;
  int _journeyRevision = 0;
  SceneMemory _sceneMemory = SceneMemory();
  bool _sceneLoaded = false, _sceneDirty = false;
  Future<void>? _sceneLoading;
  int _sceneRevision = 0;
  SceneMemory get sceneMemory => _sceneMemory;
  bool get isSceneMemoryLoaded => _sceneLoaded;

  Future<void> loadSceneMemory() {
    if (_sceneLoaded) return Future.value();
    return _sceneLoading ??= () async {
      try {
        final loaded = await _repo.loadSceneMemory();
        _sceneMemory = loaded;
        _sceneLoaded = true;
      } finally { _sceneLoading = null; }
    }();
  }

  Future<void> recordSceneObservation(SceneObservation observation) async {
    await loadSceneMemory();
    final next = _sceneMemory.record(observation);
    if (!identical(next, _sceneMemory)) {
      _sceneMemory = next; _sceneRevision++; _sceneDirty = true;
    }
    await _persistScenes();
  }

  Future<void> recordSceneCompletion({required String subject, required String unit,
      required SceneCompletion proof, required ExplanationMethod method}) async {
    // Validate/load both stores before either mutation. A retry keeps the same
    // immutable receipt in both existing journals, even after a partial write.
    await loadSceneMemory();
    await loadJourney();
    await recordJourneyEvidence(subject: subject, unit: unit, evidence: proof.evidence, now: proof.completedAt);
    await recordSceneObservation(SceneObservation.completed(proof: proof, method: method, at: proof.completedAt));
  }

  Future<void> _persistScenes() => _enqueueSave(() async {
    if (!_sceneLoaded || !_sceneDirty) return;
    final revision = _sceneRevision;
    await _repo.saveSceneMemory(_sceneMemory);
    if (revision == _sceneRevision) _sceneDirty = false;
  });

  Future<String> get studentId => _repo.studentId;
  bool get hasUnsavedChanges => _dirty || _discoveryDirty || _journeyDirty || _sceneDirty;
  Future<void> _saveTail = Future<void>.value();

  bool get isLoaded => _loaded;
  Map<String, SkillRecord> get skills => Map.unmodifiable(_skills);
  Map<String, int> get daily => Map.unmodifiable(_daily);
  Map<String, String> get lastTopics => Map.unmodifiable(_lastTopics);
  bool get isDiscoveryLoaded => _discoveryLoaded;
  DiscoveryProgress get discovery => _discovery;
  bool get discoveryPermissionPending => _discoveryPermissionPending;
  bool get isJourneyLoaded => _journeyLoaded;
  LearningJourney get journey => _journey;

  Future<void> loadJourney() {
    if (_journeyLoaded) return Future<void>.value();
    return _journeyLoading ??= _loadJourney();
  }

  Future<void> _loadJourney() async {
    try {
      final loaded = await _repo.loadJourney();
      _journey = loaded;
      _journeyLoaded = true;
    } finally {
      _journeyLoading = null;
    }
  }

  /// Accept once in memory, then queue an immutable snapshot. On save failure,
  /// retry [flushJourney] rather than submitting a new attempt identity.
  Future<JourneySkill> recordJourneyEvidence({
    required String subject,
    required String unit,
    required LearningEvidence evidence,
    DateTime? now,
  }) async {
    await loadJourney();
    final updated = _journey.recordEvidence(
      subject: subject,
      unit: unit,
      evidence: evidence,
      now: now ?? DateTime.now(),
    );
    if (!identical(updated, _journey)) {
      _journey = updated;
      _journeyRevision++;
      _journeyDirty = true;
    }
    await _persistJourney();
    return _journey.records[SkillRecord.makeId(subject, unit)]!;
  }

  Future<void> flushJourney() => _persistJourney();

  Future<void> _persistJourney() => _enqueueSave(() async {
        if (!_journeyLoaded || !_journeyDirty) return;
        final revision = _journeyRevision;
        final snapshot = _journey;
        await _repo.saveJourney(snapshot);
        if (revision == _journeyRevision) _journeyDirty = false;
      });

  /// An in-memory grant after a rejected native write is not an effective
  /// permission. A pending revocation blocks immediately as well.
  bool canDiscover(int grade) =>
      _discoveryLoaded &&
      !_discoveryPermissionPending &&
      _discovery.allows(grade);

  Future<void> loadDiscovery() {
    if (_discoveryLoaded) return Future<void>.value();
    return _discoveryLoading ??= _loadDiscovery();
  }

  Future<void> _loadDiscovery() async {
    try {
      final loaded = await _repo.loadDiscovery();
      _discovery = loaded;
      _discoveryLoaded = true;
      _discoveryPermissionPending = false;
    } finally {
      _discoveryLoading = null;
    }
  }

  void requireDiscoveryAllowed(DiscoveryLearningTarget target) {
    target.validate();
    if (!canDiscover(target.grade)) {
      throw const DiscoveryNotAllowed();
    }
    final existing = _discovery.topics[target.topicId];
    if (existing != null && existing.grade != target.grade) {
      throw const FormatException('Discovery topic stage changed');
    }
  }

  Future<void> setDiscoveryPermission(
      {required bool enabled, required int maxGrade}) async {
    if (maxGrade < 1 || maxGrade > 4) {
      throw ArgumentError('Invalid discovery limit');
    }
    await loadDiscovery();
    _discovery = _discovery.permission(enabled: enabled, maxGrade: maxGrade);
    _discoveryRevision++;
    _discoveryDirty = true;
    _discoveryPermissionPending = true;
    await _persistDiscovery();
  }

  Future<void> introduceDiscovery(DiscoveryLearningTarget target) async {
    await loadDiscovery();
    requireDiscoveryAllowed(target);
    final previous = _discovery.topics[target.topicId] ??
        DiscoveryTopicProgress(grade: target.grade);
    _discovery = _discovery.withTopic(target.topicId, previous.introduction());
    _discoveryRevision++;
    _discoveryDirty = true;
    await _persistDiscovery();
  }

  Future<void> recordDiscoveryAnswer({
    required DiscoveryLearningTarget target,
    required DiscoveryStepKind step,
    required bool correct,
    bool hintUsed = false,
  }) async {
    await loadDiscovery();
    requireDiscoveryAllowed(target);
    final previous = _discovery.topics[target.topicId] ??
        DiscoveryTopicProgress(grade: target.grade);
    _discovery = _discovery.withTopic(
        target.topicId, previous.answer(step, correct, hintUsed));
    _discoveryRevision++;
    _discoveryDirty = true;
    await _persistDiscovery();
  }

  /// Retry the same accepted discovery write, without counting an answer again.
  /// Does not write uninitialized regular skills, daily goals or last topics.
  Future<void> flushDiscovery() => _persistDiscovery();

  Future<void> _persistDiscovery() => _enqueueSave(() async {
        if (!_discoveryLoaded || !_discoveryDirty) return;
        final revision = _discoveryRevision;
        final snapshot = _discovery;
        await _repo.saveDiscovery(snapshot);
        if (revision == _discoveryRevision) {
          _discoveryDirty = false;
          _discoveryPermissionPending = false;
        }
      });

  /// Lädt alle Daten aus dem lokalen Speicher.
  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final skills = await _repo.loadSkills();
      final daily = await _repo.loadDaily();
      final lastTopics = await _repo.loadLastTopics();
      _skills = skills;
      _daily = daily;
      _lastTopics = lastTopics;
      _loaded = true;
    } finally {
      _loading = null;
    }
  }

  /// Erfasst eine beantwortete Aufgabe und schreibt sofort weg.
  /// Liefert den aktualisierten SkillRecord zurück.
  Future<SkillRecord> recordAnswer({
    required String subject,
    required String unit,
    required bool isCorrect,
    bool hintUsed = false,
  }) async {
    await load();
    final id = SkillRecord.makeId(subject, unit);
    final existing =
        _skills[id] ?? SkillRecord(skillId: id, subject: subject, unit: unit);

    if (isCorrect) {
      existing.correct++;
      existing.currentStreak++;
      existing.currentMisses = 0;
    } else {
      existing.wrong++;
      existing.currentMisses++;
      existing.currentStreak = 0;
    }
    if (hintUsed) {
      existing.hintCount++;
    }
    existing.lastSeen = DateTime.now();
    existing.difficulty = _detector.suggestDifficulty(existing);

    _skills[id] = existing;
    _lastTopics[subject] = unit;

    if (isCorrect) {
      final today = _todayKey();
      _daily[today] = (_daily[today] ?? 0) + 1;
    }

    _dirty = true;
    await _persist();
    return existing;
  }

  /// Anzahl heute richtig beantworteter Aufgaben.
  int dailyDone() => _daily[_todayKey()] ?? 0;

  /// Streak: aufeinanderfolgende Tage mit mindestens einer richtigen Antwort.
  int currentStreakDays() {
    var streak = 0;
    var d = DateTime.now();
    while (true) {
      final key = _formatDay(d);
      if ((_daily[key] ?? 0) > 0) {
        streak++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Liefert die wichtigste aktuelle Empfehlung.
  Recommendation? topRecommendation({
    int dailyGoalTarget = 5,
  }) =>
      _recommender.topRecommendation(
        _skills,
        dailyGoalDone: dailyDone(),
        dailyGoalTarget: dailyGoalTarget,
      );

  /// Liefert eine Lumo-Sprechtext-Variante. Wenn nichts spezifisches
  /// vorliegt, gibt eine motivierende Default-Nachricht zurück.
  String lumoMessage({int dailyGoalTarget = 5}) {
    final r = topRecommendation(dailyGoalTarget: dailyGoalTarget);
    if (r != null) return r.message;
    return 'Schön, dass du da bist! Womit wollen wir starten?';
  }

  /// Gibt eine Schwächen-Übersicht für den Eltern-Bereich.
  Map<String, List<String>> weaknessesBySubject() =>
      _detector.weaknessesBySubject(_skills);

  /// Setzt alle Lerndaten zurück. Vorher ausdrücklich bestätigen lassen.
  Future<void> reset() async {
    if (_loading != null) await _loading;
    if (_discoveryLoading != null) await _discoveryLoading;
    if (_journeyLoading != null) await _journeyLoading;
    if (_sceneLoading != null) await _sceneLoading;
    try {
      await _saveTail;
    } catch (_) {}
    await _repo.resetAll();
    _skills = {};
    _daily = {};
    _lastTopics = {};
    _dirty = false;
    _loaded = true;
    _discovery = DiscoveryProgress();
    _discoveryLoaded = true;
    _discoveryDirty = false;
    _discoveryPermissionPending = false;
    _discoveryRevision++;
    _journey = LearningJourney();
    _journeyLoaded = true;
    _journeyDirty = false;
    _journeyRevision++;
    _sceneMemory = SceneMemory(); _sceneLoaded = true; _sceneDirty = false; _sceneRevision++;
  }

  // ── interne helpers ───────────────────────────────────────
  Future<void> flush() async {
    // A discovery-only engine must not overwrite unloaded school progress.
    if (_loaded || _dirty) await _persist();
    await _persistDiscovery();
    await _persistJourney();
    await _persistScenes();
  }

  Future<void> _persist() {
    Future<void> save() async {
      await _repo.saveSkills(_skills);
      await _repo.saveDaily(_daily);
      await _repo.saveLastTopics(_lastTopics);
      _dirty = false;
    }

    // A failed write remains visible to its caller but does not poison retry.
    // Serialize all three writes so concurrent answers cannot overwrite a
    // newer daily/skill entry with an older, late completion.
    return _enqueueSave(save);
  }

  Future<void> _enqueueSave(Future<void> Function() save) {
    final pending = _saveTail.then((_) => save(),
        onError: (Object _, StackTrace __) => save());
    _saveTail = pending;
    return pending;
  }

  String _todayKey() => _formatDay(DateTime.now());

  String _formatDay(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
