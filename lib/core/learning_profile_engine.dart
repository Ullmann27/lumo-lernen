import 'progress_repository.dart';
import 'recommendation_engine.dart';
import 'weakness_detection_engine.dart';

class LearningHintRecord {
  const LearningHintRecord({
    required this.subject,
    required this.unit,
    required this.createdAt,
  });

  final String subject;
  final String unit;
  final DateTime createdAt;

  String get skillId => SkillRecord.makeId(subject, unit);
}

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
  final List<LearningHintRecord> _hintHistory = <LearningHintRecord>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Map<String, SkillRecord> get skills => Map.unmodifiable(_skills);
  Map<String, int> get daily => Map.unmodifiable(_daily);
  Map<String, String> get lastTopics => Map.unmodifiable(_lastTopics);
  List<LearningHintRecord> get hintHistory => List.unmodifiable(_hintHistory);

  Future<void> load() async {
    _skills = await _repo.loadSkills();
    _daily = await _repo.loadDaily();
    _lastTopics = await _repo.loadLastTopics();
    _loaded = true;
  }

  Future<SkillRecord> recordAnswer({
    required String subject,
    required String unit,
    required bool isCorrect,
    bool hintUsed = false,
  }) async {
    final id = SkillRecord.makeId(subject, unit);
    final existing = _skills[id] ?? SkillRecord(skillId: id, subject: subject, unit: unit);

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

    await _persist();
    return existing;
  }

  Future<SkillRecord> recordHintRequested({
    required String subject,
    required String unit,
  }) async {
    final id = SkillRecord.makeId(subject, unit);
    final existing = _skills[id] ?? SkillRecord(skillId: id, subject: subject, unit: unit);

    existing.hintCount++;
    existing.lastSeen = DateTime.now();
    existing.difficulty = _detector.suggestDifficulty(existing);

    _skills[id] = existing;
    _lastTopics[subject] = unit;
    _hintHistory.add(LearningHintRecord(
      subject: subject,
      unit: unit,
      createdAt: existing.lastSeen,
    ));

    await _persist();
    return existing;
  }

  int dailyDone() => _daily[_todayKey()] ?? 0;

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

  Recommendation? topRecommendation({
    int dailyGoalTarget = 5,
  }) =>
      _recommender.topRecommendation(
        _skills,
        dailyGoalDone: dailyDone(),
        dailyGoalTarget: dailyGoalTarget,
      );

  String lumoMessage({int dailyGoalTarget = 5}) {
    final r = topRecommendation(dailyGoalTarget: dailyGoalTarget);
    if (r != null) return r.message;
    return 'Schön, dass du da bist! Womit wollen wir starten?';
  }

  Map<String, List<String>> weaknessesBySubject() => _detector.weaknessesBySubject(_skills);

  Future<void> reset() async {
    await _repo.resetAll();
    _skills = {};
    _daily = {};
    _lastTopics = {};
    _hintHistory.clear();
  }

  Future<void> _persist() async {
    await _repo.saveSkills(_skills);
    await _repo.saveDaily(_daily);
    await _repo.saveLastTopics(_lastTopics);
  }

  String _todayKey() => _formatDay(DateTime.now());

  String _formatDay(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
