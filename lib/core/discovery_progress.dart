/// Local voluntary learning fields within the existing ProgressRepository.
/// No school grade, regular skill, daily goal, wallet or online consent here.
enum DiscoveryStepKind { foundation, guided, independent, check }

class DiscoveryLearningTarget {
  const DiscoveryLearningTarget({required this.topicId, required this.grade});
  final String topicId;
  final int grade;

  void validate() {
    if (!RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(topicId) ||
        grade < 1 ||
        grade > 4) {
      throw ArgumentError('Invalid local discovery target');
    }
  }
}

class DiscoveryNotAllowed implements Exception {
  const DiscoveryNotAllowed();
}

/// Immutable counts of real actions, not a diagnosis or a mastery prediction.
class DiscoveryTopicProgress {
  const DiscoveryTopicProgress({
    required this.grade,
    this.interested = false,
    this.introduced = false,
    this.foundationCorrect = 0,
    this.foundationWrong = 0,
    this.guidedCorrect = 0,
    this.guidedWrong = 0,
    this.independentCorrect = 0,
    this.independentWrong = 0,
    this.checkCorrect = 0,
    this.checkWrong = 0,
    this.hintsUsed = 0,
    this.currentMisses = 0,
  });

  final int grade;
  final bool interested;
  final bool introduced;
  final int foundationCorrect;
  final int foundationWrong;
  final int guidedCorrect;
  final int guidedWrong;
  final int independentCorrect;
  final int independentWrong;
  final int checkCorrect;
  final int checkWrong;
  final int hintsUsed;
  final int currentMisses;

  bool get needsFoundationPractice =>
      foundationWrong >= 2 && foundationWrong > foundationCorrect;
  bool get independentlyChecked =>
      independentCorrect > 0 && checkCorrect > 0 && currentMisses < 2;

  DiscoveryTopicProgress introduction() => DiscoveryTopicProgress(
        grade: grade,
        interested: true,
        introduced: true,
        foundationCorrect: foundationCorrect,
        foundationWrong: foundationWrong,
        guidedCorrect: guidedCorrect,
        guidedWrong: guidedWrong,
        independentCorrect: independentCorrect,
        independentWrong: independentWrong,
        checkCorrect: checkCorrect,
        checkWrong: checkWrong,
        hintsUsed: hintsUsed,
        currentMisses: currentMisses,
      );

  DiscoveryTopicProgress answer(
      DiscoveryStepKind step, bool correct, bool hintUsed) {
    int add(int count, bool match) =>
        (count + (match ? 1 : 0)).clamp(0, 10000).toInt();
    return DiscoveryTopicProgress(
      grade: grade,
      interested: true,
      introduced: introduced,
      foundationCorrect: add(
          foundationCorrect, step == DiscoveryStepKind.foundation && correct),
      foundationWrong: add(
          foundationWrong, step == DiscoveryStepKind.foundation && !correct),
      guidedCorrect:
          add(guidedCorrect, step == DiscoveryStepKind.guided && correct),
      guidedWrong:
          add(guidedWrong, step == DiscoveryStepKind.guided && !correct),
      independentCorrect: add(
          independentCorrect, step == DiscoveryStepKind.independent && correct),
      independentWrong: add(
          independentWrong, step == DiscoveryStepKind.independent && !correct),
      checkCorrect:
          add(checkCorrect, step == DiscoveryStepKind.check && correct),
      checkWrong: add(checkWrong, step == DiscoveryStepKind.check && !correct),
      hintsUsed: add(hintsUsed, hintUsed),
      currentMisses: correct ? 0 : add(currentMisses, true),
    );
  }

  Map<String, Object> toJson() => {
        'grade': grade,
        'interested': interested,
        'introduced': introduced,
        'foundationCorrect': foundationCorrect,
        'foundationWrong': foundationWrong,
        'guidedCorrect': guidedCorrect,
        'guidedWrong': guidedWrong,
        'independentCorrect': independentCorrect,
        'independentWrong': independentWrong,
        'checkCorrect': checkCorrect,
        'checkWrong': checkWrong,
        'hintsUsed': hintsUsed,
        'currentMisses': currentMisses,
      };

  factory DiscoveryTopicProgress.fromJson(Object? value) {
    final map = _checkedMap(value, {
      'grade',
      'interested',
      'introduced',
      'foundationCorrect',
      'foundationWrong',
      'guidedCorrect',
      'guidedWrong',
      'independentCorrect',
      'independentWrong',
      'checkCorrect',
      'checkWrong',
      'hintsUsed',
      'currentMisses',
    });
    return DiscoveryTopicProgress(
      grade: _checkedInt(map['grade'], 1, 4),
      interested: _checkedBool(map['interested']),
      introduced: _checkedBool(map['introduced']),
      foundationCorrect: _checkedInt(map['foundationCorrect'], 0, 10000),
      foundationWrong: _checkedInt(map['foundationWrong'], 0, 10000),
      guidedCorrect: _checkedInt(map['guidedCorrect'], 0, 10000),
      guidedWrong: _checkedInt(map['guidedWrong'], 0, 10000),
      independentCorrect: _checkedInt(map['independentCorrect'], 0, 10000),
      independentWrong: _checkedInt(map['independentWrong'], 0, 10000),
      checkCorrect: _checkedInt(map['checkCorrect'], 0, 10000),
      checkWrong: _checkedInt(map['checkWrong'], 0, 10000),
      hintsUsed: _checkedInt(map['hintsUsed'], 0, 10000),
      currentMisses: _checkedInt(map['currentMisses'], 0, 10000),
    );
  }
}

class DiscoveryProgress {
  DiscoveryProgress({
    this.enabled = false,
    this.maxGrade = 1,
    Map<String, DiscoveryTopicProgress> topics = const {},
  }) : topics = Map.unmodifiable(topics) {
    if (maxGrade < 1 || maxGrade > 4) {
      throw ArgumentError('Discovery limit must be school stage 1 to 4');
    }
  }

  final bool enabled;
  final int maxGrade;
  final Map<String, DiscoveryTopicProgress> topics;

  bool allows(int grade) => enabled && grade >= 1 && grade <= maxGrade;

  DiscoveryProgress permission(
          {required bool enabled, required int maxGrade}) =>
      DiscoveryProgress(enabled: enabled, maxGrade: maxGrade, topics: topics);

  DiscoveryProgress withTopic(String id, DiscoveryTopicProgress topic) =>
      DiscoveryProgress(
          enabled: enabled, maxGrade: maxGrade, topics: {...topics, id: topic});

  Map<String, Object> toJson() => {
        'version': 1,
        'enabled': enabled,
        'maxGrade': maxGrade,
        'topics': topics.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory DiscoveryProgress.fromJson(Object? value) {
    final map =
        _checkedMap(value, {'version', 'enabled', 'maxGrade', 'topics'});
    if (map['version'] != 1 || map['topics'] is! Map) {
      throw const FormatException('Unsupported discovery progress format');
    }
    final rawTopics = map['topics'] as Map;
    if (rawTopics.length > 128) {
      throw const FormatException('Unsupported discovery topic collection');
    }
    final topics = <String, DiscoveryTopicProgress>{};
    for (final entry in rawTopics.entries) {
      if (entry.key is! String ||
          !RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(entry.key as String)) {
        throw const FormatException('Invalid discovery topic');
      }
      topics[entry.key as String] =
          DiscoveryTopicProgress.fromJson(entry.value);
    }
    return DiscoveryProgress(
      enabled: _checkedBool(map['enabled']),
      maxGrade: _checkedInt(map['maxGrade'], 1, 4),
      topics: topics,
    );
  }
}

Map _checkedMap(Object? value, Set<String> fields) {
  if (value is! Map ||
      value.length != fields.length ||
      value.keys.any((key) => !fields.contains(key))) {
    // Preserve newer/unknown data instead of silently stripping its fields.
    throw const FormatException('Unsupported discovery progress fields');
  }
  return value;
}

int _checkedInt(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid discovery count or stage');
  }
  return value;
}

bool _checkedBool(Object? value) {
  if (value is! bool) {
    throw const FormatException('Invalid discovery permission or observation');
  }
  return value;
}
