import 'logic_games.dart';

/// One resumable puzzle. Help and mistakes belong to this attempt and survive
/// app restarts. The session identifies a visit to Logikspiele, not a grid cell.
class LogicPuzzleSession {
  LogicPuzzleSession({
    required this.attemptId,
    required this.puzzleId,
    required this.contentVersion,
    required this.kind,
    required this.grade,
    required this.level,
    required this.sessionId,
    required this.startedAt,
    Map<int, String> answers = const {},
    this.hints = 0,
    this.errors = 0,
    this.solutionRevealed = false,
    this.isReplay = false,
    this.revision = 0,
  }) : answers = Map.unmodifiable(answers);

  final String attemptId;
  final String puzzleId;
  final String contentVersion;
  final LogicGameKind kind;
  final int grade;
  final int level;
  final String sessionId;
  final DateTime startedAt;
  final Map<int, String> answers;
  final int hints;
  final int errors;
  final bool solutionRevealed;
  final bool isReplay;
  final int revision;

  LogicPuzzleSession copyWith({
    Map<int, String>? answers,
    int? hints,
    int? errors,
    bool? solutionRevealed,
  }) =>
      LogicPuzzleSession(
        attemptId: attemptId,
        puzzleId: puzzleId,
        contentVersion: contentVersion,
        kind: kind,
        grade: grade,
        level: level,
        sessionId: sessionId,
        startedAt: startedAt,
        answers: answers ?? this.answers,
        hints: hints ?? this.hints,
        errors: errors ?? this.errors,
        solutionRevealed: solutionRevealed ?? this.solutionRevealed,
        isReplay: isReplay,
        revision: revision + 1,
      );

  /// A late write cannot erase assistance recorded by an earlier write.
  LogicPuzzleSession preservingEvidenceFrom(LogicPuzzleSession earlier) =>
      LogicPuzzleSession(
        attemptId: attemptId,
        puzzleId: puzzleId,
        contentVersion: contentVersion,
        kind: kind,
        grade: grade,
        level: level,
        sessionId: sessionId,
        startedAt: startedAt,
        answers: answers,
        hints: hints > earlier.hints ? hints : earlier.hints,
        errors: errors > earlier.errors ? errors : earlier.errors,
        solutionRevealed: solutionRevealed || earlier.solutionRevealed,
        isReplay: isReplay || earlier.isReplay,
        revision: revision,
      );

  Map<String, Object?> toJson() => {
        'attemptId': attemptId,
        'puzzleId': puzzleId,
        'contentVersion': contentVersion,
        'kind': kind.name,
        'grade': grade,
        'level': level,
        'sessionId': sessionId,
        'startedAt': startedAt.toIso8601String(),
        'answers': {for (final e in answers.entries) '${e.key}': e.value},
        'hints': hints,
        'errors': errors,
        'solutionRevealed': solutionRevealed,
        'isReplay': isReplay,
        'revision': revision,
      };

  factory LogicPuzzleSession.fromJson(Object? value) {
    final json = _map(value);
    final rawAnswers = _map(json['answers']);
    final answers = <int, String>{};
    for (final entry in rawAnswers.entries) {
      final index = int.tryParse(entry.key);
      if (index == null || index < 0 || entry.value is! String) {
        throw const FormatException('Invalid logic puzzle answer');
      }
      answers[index] = entry.value as String;
    }
    return LogicPuzzleSession(
      attemptId: _text(json, 'attemptId'),
      puzzleId: _text(json, 'puzzleId'),
      contentVersion: _text(json, 'contentVersion'),
      kind: _kind(json),
      grade: _integer(json, 'grade', min: 1, max: 4),
      level: _integer(json, 'level', min: 1, max: 12),
      sessionId: _text(json, 'sessionId'),
      startedAt: _date(json, 'startedAt'),
      answers: answers,
      hints: _integer(json, 'hints'),
      errors: _integer(json, 'errors'),
      solutionRevealed: _boolean(json, 'solutionRevealed'),
      isReplay: _boolean(json, 'isReplay'),
      revision: _integer(json, 'revision'),
    );
  }
}

/// The first completed attempt is immutable evidence. Replaying a puzzle may
/// advance practice, but cannot manufacture another independent observation.
class LogicPuzzleResult {
  const LogicPuzzleResult({
    required this.attemptId,
    required this.puzzleId,
    required this.contentVersion,
    required this.kind,
    required this.grade,
    required this.level,
    required this.sessionId,
    required this.startedAt,
    required this.completedAt,
    required this.hints,
    required this.errors,
    required this.solutionRevealed,
    required this.isReplay,
  });

  factory LogicPuzzleResult.fromSession(
    LogicPuzzleSession session,
    DateTime completedAt,
  ) =>
      LogicPuzzleResult(
        attemptId: session.attemptId,
        puzzleId: session.puzzleId,
        contentVersion: session.contentVersion,
        kind: session.kind,
        grade: session.grade,
        level: session.level,
        sessionId: session.sessionId,
        startedAt: session.startedAt,
        completedAt: completedAt,
        hints: session.hints,
        errors: session.errors,
        solutionRevealed: session.solutionRevealed,
        isReplay: session.isReplay,
      );

  final String attemptId;
  final String puzzleId;
  final String contentVersion;
  final LogicGameKind kind;
  final int grade;
  final int level;
  final String sessionId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int hints;
  final int errors;
  final bool solutionRevealed;
  final bool isReplay;

  bool get independent => !isReplay && hints == 0 && !solutionRevealed;

  Map<String, Object?> toJson() => {
        'attemptId': attemptId,
        'puzzleId': puzzleId,
        'contentVersion': contentVersion,
        'kind': kind.name,
        'grade': grade,
        'level': level,
        'sessionId': sessionId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'hints': hints,
        'errors': errors,
        'solutionRevealed': solutionRevealed,
        'isReplay': isReplay,
      };

  factory LogicPuzzleResult.fromJson(Object? value) {
    final json = _map(value);
    return LogicPuzzleResult(
      attemptId: _text(json, 'attemptId'),
      puzzleId: _text(json, 'puzzleId'),
      contentVersion: _text(json, 'contentVersion'),
      kind: _kind(json),
      grade: _integer(json, 'grade', min: 1, max: 4),
      level: _integer(json, 'level', min: 1, max: 12),
      sessionId: _text(json, 'sessionId'),
      startedAt: _date(json, 'startedAt'),
      completedAt: _date(json, 'completedAt'),
      hints: _integer(json, 'hints'),
      errors: _integer(json, 'errors'),
      solutionRevealed: _boolean(json, 'solutionRevealed'),
      isReplay: _boolean(json, 'isReplay'),
    );
  }
}

class LogicProgress {
  static const preferencePrefix = 'lumo.logic_progress.v1.';

  LogicProgress({
    required this.profileId,
    this.selectedGrade = 1,
    Map<String, LogicPuzzleSession> drafts = const {},
    Map<String, LogicPuzzleResult> results = const {},
  })  : drafts = Map.unmodifiable(drafts),
        results = Map.unmodifiable(results);

  final String profileId;
  final int selectedGrade;
  final Map<String, LogicPuzzleSession> drafts;
  final Map<String, LogicPuzzleResult> results;

  bool isCompleted(String puzzleId) => results.containsKey(puzzleId);

  int completedCount(LogicGameKind kind, int grade) =>
      results.values.where((r) => r.kind == kind && r.grade == grade).length;

  bool isUnlocked(LogicGameKind kind, int grade, int level) {
    if (grade < 1 || grade > 4 || level < 1 || level > 12) return false;
    return level == 1 ||
        results.values.any(
          (r) => r.kind == kind && r.grade == grade && r.level == level - 1,
        );
  }

  LogicProgress copyWith({
    int? selectedGrade,
    Map<String, LogicPuzzleSession>? drafts,
    Map<String, LogicPuzzleResult>? results,
  }) =>
      LogicProgress(
        profileId: profileId,
        selectedGrade: selectedGrade ?? this.selectedGrade,
        drafts: drafts ?? this.drafts,
        results: results ?? this.results,
      );

  Map<String, Object?> toJson() => {
        'schema': 1,
        'profileId': profileId,
        'selectedGrade': selectedGrade,
        'drafts': {for (final e in drafts.entries) e.key: e.value.toJson()},
        'results': {for (final e in results.entries) e.key: e.value.toJson()},
      };

  factory LogicProgress.fromJson(Object? value) {
    final json = _map(value);
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported logic progress version');
    }
    final drafts = {
      for (final e in _map(json['drafts']).entries)
        e.key: LogicPuzzleSession.fromJson(e.value),
    };
    final results = {
      for (final e in _map(json['results']).entries)
        e.key: LogicPuzzleResult.fromJson(e.value),
    };
    if (drafts.entries.any((e) => e.key != e.value.puzzleId) ||
        results.entries.any((e) => e.key != e.value.puzzleId)) {
      throw const FormatException('Logic progress identity mismatch');
    }
    return LogicProgress(
      profileId: _text(json, 'profileId'),
      selectedGrade: _integer(json, 'selectedGrade', min: 1, max: 4),
      drafts: drafts,
      results: results,
    );
  }
}

enum LogicEvidenceStage { exploring, practicing, independent, challenge }

class LogicSkillReport {
  const LogicSkillReport({
    required this.kind,
    required this.stage,
    required this.title,
    required this.summary,
    required this.nextStep,
    required this.distinctPuzzles,
    required this.sessions,
    required this.days,
  });

  final LogicGameKind kind;
  final LogicEvidenceStage stage;
  final String title;
  final String summary;
  final String nextStep;
  final int distinctPuzzles;
  final int sessions;
  final int days;
}

/// Task-specific observations, never an IQ/EQ/AQ or personality score.
///
/// Six different first attempts, three visits and two local days are a cautious
/// product rule, not a validated psychometric threshold. Time is not scored.
class LogicLearningProfile {
  const LogicLearningProfile(this.reports);

  final List<LogicSkillReport> reports;

  static const explanation =
      'Hier siehst du, was dir in deinen Lumo-Rätseln schon gelingt. '
      'Wir vergleichen dich nicht mit anderen Kindern. '
      'Das ist ein Lernprofil und keine Messung von IQ, EQ oder Persönlichkeit.';

  factory LogicLearningProfile.fromProgress(
    LogicProgress progress, {
    required int grade,
    required String contentVersion,
  }) {
    final reports = <LogicSkillReport>[];
    for (final kind in LogicGameKind.values) {
      final observed = progress.results.values
          .where(
            (r) =>
                r.kind == kind &&
                r.grade == grade &&
                r.contentVersion == contentVersion &&
                !r.isReplay,
          )
          .toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      final sessions = observed.map((r) => r.sessionId).toSet().length;
      final days = observed
          .map((r) {
            final date = r.completedAt.toLocal();
            return '${date.year}-${date.month}-${date.day}';
          })
          .toSet()
          .length;
      final enough = observed.length >= 6 && sessions >= 3 && days >= 2;
      final recent = observed.length > 6
          ? observed.sublist(observed.length - 6)
          : observed;
      final independent = recent.where((r) => r.independent).length;
      final advanced = observed
          .where((r) => r.independent && r.level >= 9)
          .map((r) => r.level)
          .toSet();
      final stage = !enough
          ? LogicEvidenceStage.exploring
          : independent >= 5
              ? advanced.contains(11) && advanced.contains(12)
                  ? LogicEvidenceStage.challenge
                  : LogicEvidenceStage.independent
              : LogicEvidenceStage.practicing;
      final (title, puzzleName, tip) = switch (kind) {
        LogicGameKind.sudoku => (
            'Logisches Kombinieren',
            'Sudoku-Rätsel',
            'Schau dir eine Reihe, eine Spalte und einen Block nacheinander an.',
          ),
        LogicGameKind.words => (
            'Wörter und Rechtschreiben',
            'Wort-Kreuzrätsel',
            'Sprich ein Wort langsam und prüfe die Buchstaben an den Kreuzungen.',
          ),
        LogicGameKind.maths => (
            'Rechnen und Prüfen',
            'Mathe-Kreuzrätsel',
            'Prüfe deine Zahl in der waagerechten und der senkrechten Rechnung.',
          ),
      };
      final summary = switch (stage) {
        LogicEvidenceStage.exploring =>
          'Wir entdecken deine Lernstärken. Jedes neue Rätsel zeigt uns mehr.',
        LogicEvidenceStage.practicing =>
          'Du hast verschiedene $puzzleName geschafft. Lumo hilft dir beim nächsten Schritt.',
        LogicEvidenceStage.independent =>
          'Mehrere neue $puzzleName hast du ohne Lumo-Hilfe gelöst.',
        LogicEvidenceStage.challenge =>
          'Auch die beiden höchsten Stufen dieser $puzzleName hast du selbstständig gelöst.',
      };
      reports.add(
        LogicSkillReport(
          kind: kind,
          stage: stage,
          title: title,
          summary: summary,
          nextStep: tip,
          distinctPuzzles: observed.length,
          sessions: sessions,
          days: days,
        ),
      );
    }
    return LogicLearningProfile(List.unmodifiable(reports));
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Invalid logic progress object');
  }
  return Map<String, Object?>.from(value);
}

String _text(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Invalid logic progress $key');
  }
  return value;
}

int _integer(Map<String, Object?> map, String key, {int min = 0, int? max}) {
  final value = map[key];
  if (value is! int || value < min || (max != null && value > max)) {
    throw FormatException('Invalid logic progress $key');
  }
  return value;
}

bool _boolean(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) throw FormatException('Invalid logic progress $key');
  return value;
}

DateTime _date(Map<String, Object?> map, String key) {
  final value = DateTime.tryParse(_text(map, key));
  if (value == null) throw FormatException('Invalid logic progress $key');
  return value;
}

LogicGameKind _kind(Map<String, Object?> map) {
  final name = _text(map, 'kind');
  for (final kind in LogicGameKind.values) {
    if (kind.name == name) return kind;
  }
  throw const FormatException('Invalid logic game kind');
}
