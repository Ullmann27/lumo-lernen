/// Local observations, never raw answers, audio, child names or a diagnosis.
/// Callers provide opaque attempt IDs, curriculum problem IDs and error codes.
class LearningEvidence {
  const LearningEvidence({
    required this.taskId,
    required this.correct,
    this.problemId,
    this.helpLevel = 0,
    this.transferCheck = false,
    this.errorTag,
  });

  /// Unique attempt identity. Reusing it retries the same accepted observation.
  final String taskId;

  /// Stable curriculum problem identity, independent of retries/sessions.
  /// Older callers may omit it; then [taskId] is the problem identity as well.
  final String? problemId;
  final bool correct;

  /// 0 = independent; 1..5 = increasing support. Any support stays assisted.
  final int helpLevel;
  final bool transferCheck;
  final String? errorTag;

  void validate() {
    if (!_validIdentity(taskId) ||
        (problemId != null && !_validIdentity(problemId!)) ||
        helpLevel < 0 ||
        helpLevel > 5 ||
        (errorTag != null && !_validErrorTag(errorTag!))) {
      throw ArgumentError('Invalid local learning evidence metadata');
    }
  }
}

enum JourneyStatus { practicing, independentlyChecked, retained }

/// Immutable evidence summary for one curriculum skill.
///
/// Review intervals of 1/3/7/14 days are conservative, transparent scheduling
/// heuristics. They are not a validated diagnostic or mastery model.
class JourneySkill {
  JourneySkill._({
    required this.subject,
    required this.unit,
    required this.attempts,
    required this.independentCorrect,
    required this.assistedCorrect,
    required this.transferCorrect,
    required Map<String, int> errorCounts,
    required this.dueAt,
    required this.lastSeen,
    required this.reviewStage,
    required this.needsPractice,
    required List<String> recentTaskIds,
    required List<String> independentProblemIds,
  })  : errorCounts = Map.unmodifiable(errorCounts),
        recentTaskIds = List.unmodifiable(recentTaskIds),
        independentProblemIds = List.unmodifiable(independentProblemIds);

  final String subject;
  final String unit;
  final int attempts;
  final int independentCorrect;
  final int assistedCorrect;
  final int transferCorrect;
  final Map<String, int> errorCounts;
  final DateTime dueAt;
  final DateTime lastSeen;
  final int reviewStage;
  final bool needsPractice;

  /// Exact retry deduplication covers the last 128 accepted attempt IDs per
  /// skill, including across restarts. Older IDs are evicted FIFO; callers must
  /// use fresh attempt IDs for new work, rather than replay old sessions.
  final List<String> recentTaskIds;

  /// Bounded distinct problem evidence; repeated attempts at the same problem
  /// cannot by themselves establish independent transfer.
  final List<String> independentProblemIds;

  bool get _independentlyChecked =>
      independentCorrect >= 2 &&
      independentProblemIds.length >= 2 &&
      transferCorrect > 0;

  JourneyStatus get status {
    if (needsPractice || !_independentlyChecked) {
      return JourneyStatus.practicing;
    }
    return reviewStage > 0
        ? JourneyStatus.retained
        : JourneyStatus.independentlyChecked;
  }

  String get statusLabel => switch (status) {
        JourneyStatus.practicing => 'In Übung',
        JourneyStatus.independentlyChecked => 'Selbstständig geprüft',
        JourneyStatus.retained => 'Später erinnert',
      };

  String get explanation {
    final evidence = '$independentCorrect selbstständig richtig, '
        '$assistedCorrect mit Hilfe, $attempts Versuche. ';
    final reason = switch (status) {
      JourneyStatus.practicing =>
        'Wir üben weiter. Für eine selbstständige Prüfung brauchen wir '
            'verschiedene Aufgaben und eine Übertragung ohne Hilfe.',
      JourneyStatus.independentlyChecked =>
        'Verschiedene Aufgaben und eine Übertragung gelangen ohne Hilfe. '
            'Eine spätere Erinnerung prüfen wir noch.',
      JourneyStatus.retained =>
        'Auch bei einer späteren Wiederholung gelang eine Aufgabe ohne Hilfe.',
    };
    return '$evidence$reason Die Abstände von 1, 3, 7 und 14 Tagen sind eine '
        'vorsichtige Faustregel, keine Diagnose.';
  }

  String recommendationReason(DateTime now) {
    if (!now.toUtc().isBefore(dueAt)) {
      return 'Eine kurze Wiederholung ist jetzt fällig. $explanation';
    }
    if (needsPractice) return 'Mit passender Hilfe weiterüben. $explanation';
    return 'Eine kurze Wiederholung ist später vorgesehen. $explanation';
  }

  JourneySkill _record(LearningEvidence evidence, DateTime now) {
    if (recentTaskIds.contains(evidence.taskId)) return this;
    // A device clock moving backwards must not move stored observations back.
    final seenAt = now.isBefore(lastSeen) ? lastSeen : now;
    final independent = evidence.correct && evidence.helpLevel == 0;
    final countable = attempts < _maxCount;
    final independentCount =
        independentCorrect + (countable && independent ? 1 : 0);
    final transferCount = transferCorrect +
        (countable && independent && evidence.transferCheck ? 1 : 0);
    final problems = independent
        ? _remember(
                independentProblemIds, evidence.problemId ?? evidence.taskId)
            .take(independentCount)
            .toList(growable: false)
        : independentProblemIds;
    final nowChecked =
        independentCount >= 2 && problems.length >= 2 && transferCount > 0;
    var stage = reviewStage;
    var due = dueAt;
    if (!independent) {
      stage = 0;
      due = seenAt.add(const Duration(days: 1));
    } else if (_independentlyChecked &&
        !needsPractice &&
        !seenAt.isBefore(dueAt)) {
      stage = (reviewStage + 1).clamp(0, 3);
      due = seenAt.add(Duration(days: _reviewDays[stage]));
    } else if ((!_independentlyChecked && nowChecked) || needsPractice) {
      // First qualification/recovery starts a fresh delay. Success at the same
      // instant cannot also count as a later retained recall.
      stage = 0;
      due = seenAt.add(const Duration(days: 1));
    } else if (due.isBefore(seenAt)) {
      due = seenAt.add(const Duration(days: 1));
    }
    final errors = {...errorCounts};
    if (countable && !evidence.correct && evidence.errorTag != null) {
      var tag = evidence.errorTag!;
      if (!errors.containsKey(tag) && errors.length >= _maxErrorTags - 1) {
        tag = 'other';
      }
      errors[tag] = (errors[tag] ?? 0) + 1;
    }
    return JourneySkill._(
      subject: subject,
      unit: unit,
      attempts: attempts + (countable ? 1 : 0),
      independentCorrect: independentCount,
      assistedCorrect: assistedCorrect +
          (countable && evidence.correct && !independent ? 1 : 0),
      transferCorrect: transferCount,
      errorCounts: errors,
      dueAt: due,
      lastSeen: seenAt,
      reviewStage: stage,
      needsPractice: !independent,
      recentTaskIds: _remember(recentTaskIds, evidence.taskId),
      independentProblemIds: problems,
    );
  }

  Map<String, Object> toJson() => {
        'subject': subject,
        'unit': unit,
        'attempts': attempts,
        'independentCorrect': independentCorrect,
        'assistedCorrect': assistedCorrect,
        'transferCorrect': transferCorrect,
        'errorCounts': errorCounts,
        'dueAt': dueAt.toIso8601String(),
        'lastSeen': lastSeen.toIso8601String(),
        'reviewStage': reviewStage,
        'needsPractice': needsPractice,
        'recentTaskIds': recentTaskIds,
        'independentProblemIds': independentProblemIds,
      };

  factory JourneySkill.fromJson(Object? value) {
    final map = _checkedMap(value, {
      'subject',
      'unit',
      'attempts',
      'independentCorrect',
      'assistedCorrect',
      'transferCorrect',
      'errorCounts',
      'dueAt',
      'lastSeen',
      'reviewStage',
      'needsPractice',
      'recentTaskIds',
      'independentProblemIds',
    });
    final subject = _checkedLabel(map['subject']);
    final unit = _checkedLabel(map['unit']);
    final attempts = _checkedInt(map['attempts'], 1, _maxCount);
    final independent = _checkedInt(map['independentCorrect'], 0, attempts);
    final assisted = _checkedInt(map['assistedCorrect'], 0, attempts);
    final transfer = _checkedInt(map['transferCorrect'], 0, independent);
    final stage = _checkedInt(map['reviewStage'], 0, 3);
    final due = _checkedDate(map['dueAt']);
    final seen = _checkedDate(map['lastSeen']);
    final tasks = _checkedIdentities(map['recentTaskIds']);
    final problems = _checkedIdentities(map['independentProblemIds']);
    final rawErrors = map['errorCounts'];
    final needsPractice = map['needsPractice'];
    if (rawErrors is! Map ||
        rawErrors.length > _maxErrorTags ||
        needsPractice is! bool ||
        independent + assisted > attempts ||
        tasks.isEmpty ||
        tasks.length > attempts ||
        problems.length > independent ||
        due.isBefore(seen) ||
        (stage > 0 &&
            (needsPractice ||
                independent < 2 ||
                problems.length < 2 ||
                transfer == 0))) {
      throw const FormatException('Inconsistent learning journey evidence');
    }
    final errors = <String, int>{};
    for (final entry in rawErrors.entries) {
      if (entry.key is! String || !_validErrorTag(entry.key as String)) {
        throw const FormatException('Invalid learning journey error code');
      }
      errors[entry.key as String] = _checkedInt(entry.value, 1, _maxCount);
    }
    if (errors.values.fold<int>(0, (sum, n) => sum + n) >
        attempts - independent - assisted) {
      throw const FormatException('Inconsistent learning journey error counts');
    }
    return JourneySkill._(
      subject: subject,
      unit: unit,
      attempts: attempts,
      independentCorrect: independent,
      assistedCorrect: assisted,
      transferCorrect: transfer,
      errorCounts: errors,
      dueAt: due,
      lastSeen: seen,
      reviewStage: stage,
      needsPractice: needsPractice,
      recentTaskIds: tasks,
      independentProblemIds: problems,
    );
  }
}

class LearningJourney {
  LearningJourney() : records = const {};
  LearningJourney._(Map<String, JourneySkill> values)
      : records = Map.unmodifiable(values);

  /// The key uses the existing SkillRecord.makeId(subject, unit) convention.
  final Map<String, JourneySkill> records;

  LearningJourney recordEvidence({
    required String subject,
    required String unit,
    required LearningEvidence evidence,
    required DateTime now,
  }) {
    evidence.validate();
    if (!_validLabel(subject) ||
        !_validLabel(unit) ||
        now.year < 2000 ||
        now.year > 2200) {
      throw ArgumentError('Invalid local learning target or observation time');
    }
    final id = _skillId(subject, unit);
    final previous = records[id];
    if (previous == null && records.length >= _maxSkills) {
      throw StateError('Local learning journey skill capacity reached');
    }
    final at = now.toUtc();
    final initial = previous ??
        JourneySkill._(
          subject: subject,
          unit: unit,
          attempts: 0,
          independentCorrect: 0,
          assistedCorrect: 0,
          transferCorrect: 0,
          errorCounts: const {},
          dueAt: at.add(const Duration(days: 1)),
          lastSeen: at,
          reviewStage: 0,
          needsPractice: false,
          recentTaskIds: const [],
          independentProblemIds: const [],
        );
    final updated = initial._record(evidence, at);
    if (identical(updated, previous)) return this;
    return LearningJourney._({...records, id: updated});
  }

  Map<String, Object> toJson() => {
        'version': 1,
        'records': records.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory LearningJourney.fromJson(Object? value) {
    final map = _checkedMap(value, {'version', 'records'});
    final raw = map['records'];
    if (map['version'] is! int ||
        map['version'] != 1 ||
        raw is! Map ||
        raw.length > _maxSkills) {
      throw const FormatException('Unsupported learning journey format');
    }
    final records = <String, JourneySkill>{};
    for (final entry in raw.entries) {
      final skill = JourneySkill.fromJson(entry.value);
      if (entry.key is! String ||
          entry.key != _skillId(skill.subject, skill.unit)) {
        throw const FormatException('Invalid learning journey skill identity');
      }
      records[entry.key as String] = skill;
    }
    return LearningJourney._(records);
  }
}

const _maxCount = 10000;
const _maxSkills = 512;
const _windowSize = 128;
const _maxErrorTags = 32;
const _reviewDays = [1, 3, 7, 14];

String _skillId(String subject, String unit) =>
    '${subject.toLowerCase()}::${unit.toLowerCase()}';

bool _validLabel(String value) =>
    value.trim().isNotEmpty &&
    value.length <= 128 &&
    !value.contains('::') &&
    !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value);

bool _validIdentity(String value) =>
    RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:/-]{0,127}$').hasMatch(value);

bool _validErrorTag(String value) =>
    RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(value);

List<String> _remember(List<String> previous, String value) {
  if (previous.contains(value)) return previous;
  return [...previous.skip(previous.length >= _windowSize ? 1 : 0), value];
}

Map _checkedMap(Object? value, Set<String> fields) {
  if (value is! Map ||
      value.length != fields.length ||
      value.keys.any((key) => !fields.contains(key))) {
    throw const FormatException('Unsupported learning journey fields');
  }
  return value;
}

int _checkedInt(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid learning journey counter');
  }
  return value;
}

String _checkedLabel(Object? value) {
  if (value is! String || !_validLabel(value)) {
    throw const FormatException('Invalid learning journey curriculum label');
  }
  return value;
}

List<String> _checkedIdentities(Object? value) {
  if (value is! List ||
      value.length > _windowSize ||
      value.any((id) => id is! String || !_validIdentity(id)) ||
      value.toSet().length != value.length) {
    throw const FormatException('Invalid learning journey identity window');
  }
  return List<String>.from(value);
}

DateTime _checkedDate(Object? value) {
  if (value is! String || value.length > 32) {
    throw const FormatException('Invalid learning journey date');
  }
  final parsed = DateTime.tryParse(value);
  // Round-trip validation rejects normalized overflow dates and missing zones.
  if (parsed == null ||
      !parsed.isUtc ||
      parsed.year < 2000 ||
      parsed.year > 2200 ||
      parsed.toIso8601String() != value) {
    throw const FormatException('Invalid learning journey date');
  }
  return parsed;
}
