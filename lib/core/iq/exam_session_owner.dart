import 'package:flutter/foundation.dart';

import '../../app/app_state.dart';

/// Binds a test to the profile visible before its first asynchronous operation.
/// A profile change retires the entire attempt instead of moving its answers.
class ExamSessionOwner extends ChangeNotifier {
  ExamSessionOwner(this.app)
      : grade = app.state.grade,
        childName = app.state.childName,
        generation = app.profileGeneration {
    _capture();
    app.addListener(_changed);
  }

  final LumoAppState app;
  final int grade, generation;
  final String childName;
  Future<String>? _identity;
  bool _retired = false;

  bool get retired =>
      _retired ||
      app.resetting ||
      app.profileGeneration != generation ||
      app.state.grade != grade ||
      app.state.childName != childName;

  String get _fallback {
    final name = childName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), '_');
    return 'local_${name.isEmpty ? 'kind' : name}_$grade';
  }

  void _capture() {
    _identity = app.school.activeStudentId().then((id) => id ?? _fallback);
    // Identity may resolve before the child presses Start. Keep an error
    // available for the explicit save retry without an unhandled future.
    _identity!.then<void>((_) {}, onError: (Object _, StackTrace __) {});
  }

  Future<String> studentId() async {
    if (retired) throw StateError('The test profile changed');
    if (_identity == null) _capture();
    try {
      final id = await _identity!;
      if (retired) throw StateError('The test profile changed');
      return id;
    } catch (_) {
      _identity = null;
      rethrow;
    }
  }

  void _changed() {
    if (!_retired && retired) {
      _retired = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    app.removeListener(_changed);
    _retired = true;
    super.dispose();
  }
}
