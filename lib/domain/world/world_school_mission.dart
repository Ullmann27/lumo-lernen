import '../../core/school_exercise_generator.dart';
import '../../core/task_quality_guard.dart';

/// Versioned local bridge from Lumo World to an assessed school lesson.
class WorldSchoolMissionRequest {
  WorldSchoolMissionRequest._({required this.requestId, required this.grade});

  factory WorldSchoolMissionRequest({
    required String requestId,
    required int grade,
  }) {
    if (!_validRequestId(requestId) || grade < 1 || grade > 4) {
      throw ArgumentError('Invalid world school mission request.');
    }
    return WorldSchoolMissionRequest._(requestId: requestId, grade: grade);
  }

  static const version = 1;
  static const missionId = 'school_numbers';
  static const subject = 'Mathematik';
  static const returnGame = 'world';

  final String requestId;
  final int grade;
  String get id => missionId;

  static bool _validRequestId(String value) =>
      value.length >= 8 &&
      value.length <= 160 &&
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

  static WorldSchoolMissionRequest? tryParse(Object? raw) {
    if (raw is! Map ||
        raw['version'] != version ||
        raw['id'] != missionId ||
        raw['subject'] != subject ||
        raw['returnGame'] != returnGame ||
        raw['requestId'] is! String ||
        raw['grade'] is! int) {
      return null;
    }
    final requestId = raw['requestId'] as String;
    final grade = raw['grade'] as int;
    if (!_validRequestId(requestId) || grade < 1 || grade > 4) return null;
    return WorldSchoolMissionRequest._(requestId: requestId, grade: grade);
  }

  Map<String, Object> toJson() => {
        'version': version,
        'id': missionId,
        'requestId': requestId,
        'subject': subject,
        'grade': grade,
        'returnGame': returnGame,
      };
}

/// Created only after all three assessed tasks have been accepted as saved.
class WorldSchoolMissionReceipt {
  const WorldSchoolMissionReceipt._(this.request);
  final WorldSchoolMissionRequest request;

  Map<String, Object> toJson() => {
        'version': WorldSchoolMissionRequest.version,
        'requestId': request.requestId,
        'missionId': WorldSchoolMissionRequest.missionId,
        'completed': true,
        'subject': WorldSchoolMissionRequest.subject,
        'grade': request.grade,
        'returnGame': WorldSchoolMissionRequest.returnGame,
      };
}

/// Three real tasks from the existing learning-app generator and quality gate.
///
/// Reopening a pending request generates the same work. The seed changes
/// content, never rewards or success. Only the UI's durable learning writer may
/// call [acceptSavedAnswer], after its original profile lease is still current.
class WorldSchoolLesson {
  WorldSchoolLesson._(this.request, this.ownerId, Iterable<LumoTask> tasks)
      : tasks = List<LumoTask>.unmodifiable(tasks);

  factory WorldSchoolLesson.start({
    required WorldSchoolMissionRequest request,
    required String ownerId,
  }) {
    if (ownerId.trim().isEmpty) throw ArgumentError.value(ownerId, 'ownerId');
    final factory = ExerciseFactory(seed: _stableHash(request.requestId));
    final tasks = <LumoTask>[];
    for (final unit in _units[request.grade - 1]) {
      LumoTask? accepted;
      for (var attempt = 0; attempt < 40; attempt++) {
        final task = factory.nextExact(
          grade: request.grade,
          subject: WorldSchoolMissionRequest.subject,
          unit: unit,
          currentGradeOnly: true,
        );
        if (_quality.validate(task) &&
            task.choices.length >= 2 &&
            !task.handwriting) {
          accepted = task;
          break;
        }
      }
      if (accepted == null) {
        throw StateError('No checked school task for ${request.grade}/$unit.');
      }
      tasks.add(accepted);
    }
    return WorldSchoolLesson._(request, ownerId, tasks);
  }

  static const _quality = TaskQualityGuard();
  static const _units = [
    ['Plus bis 10', 'Minus bis 10', 'Plus bis 20'],
    ['Plus bis 100', 'Minus bis 100', 'Einmaleins'],
    ['Plus bis 1000', 'Minus bis 1000', 'Division einstellig'],
    ['Plus bis 10000', 'Schriftliche Multiplikation', 'Schriftliche Division'],
  ];

  final WorldSchoolMissionRequest request;
  final String ownerId;
  final List<LumoTask> tasks;
  int _solved = 0;
  bool _cancelled = false;

  int get solved => _solved;
  bool get complete => !_cancelled && _solved == tasks.length;
  bool get cancelled => _cancelled;

  bool accepts(int index, String answer) =>
      !_cancelled &&
      index >= 0 &&
      index < tasks.length &&
      _quality.matchesAnswer(tasks[index], answer);

  String problemIdentity(int index) {
    final task = tasks[index];
    return 'world-school-${_stableHash('${task.grade}|${task.unit}|${task.prompt}|${task.answer}')}';
  }

  /// A persisted answer may advance only its original owner's next task.
  bool acceptSavedAnswer({
    required int index,
    required String answer,
    required String currentOwnerId,
  }) {
    if (_cancelled || currentOwnerId != ownerId || index != _solved) {
      return false;
    }
    if (!accepts(index, answer)) return false;
    _solved++;
    return true;
  }

  WorldSchoolMissionReceipt? receiptForOwner(String currentOwnerId) =>
      complete && currentOwnerId == ownerId
          ? WorldSchoolMissionReceipt._(request)
          : null;

  void cancel() => _cancelled = true;

  static int _stableHash(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
