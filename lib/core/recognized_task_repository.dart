import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/learning/recognized_task.dart';
import 'legacy_learning_data.dart';

/// A single resumable task per child. Writes share the existing learning queue.
class RecognizedTaskRepository {
  RecognizedTaskRepository({required this.ownerId, bool Function()? mayWrite})
      : _mayWrite = mayWrite ?? _allowed;
  static bool _allowed() => true;
  static const storageBase = 'lumo_recognized_task_v1';
  final String ownerId;
  final bool Function() _mayWrite;
  String get storageKey => LearningDataNamespace.keyFor(storageBase, ownerId);

  RecognizedTaskAttempt? _read(SharedPreferences prefs) {
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final value = (jsonDecode(raw) as Map).cast<String, dynamic>();
      if (value['version'] != 1 || value['ownerId'] != ownerId) {
        throw const FormatException();
      }
      final attempt = value['attempt'] == null
          ? null
          : RecognizedTaskAttempt.fromJson(
              (value['attempt'] as Map).cast<String, dynamic>());
      if (attempt != null && attempt.ownerId != ownerId) {
        throw const FormatException();
      }
      return attempt;
    } catch (_) {
      throw const FormatException(
          'Die gespeicherte Aufgabe konnte nicht gelesen werden. Ihre Daten bleiben erhalten.');
    }
  }

  Future<RecognizedTaskAttempt?> load() =>
      LearningStorage.run((prefs) async => _read(prefs));

  Future<RecognizedTaskAttempt?> _change(
          RecognizedTaskAttempt? Function(RecognizedTaskAttempt?) change) =>
      LearningStorage.run((prefs) async {
        if (!_mayWrite()) {
          throw StateError('Das Kinderprofil ist nicht mehr verfügbar.');
        }
        final next = change(_read(prefs));
        if (next != null && next.ownerId != ownerId) {
          throw StateError('Falsches Kinderprofil.');
        }
        if (!_mayWrite()) {
          throw StateError('Das Kinderprofil ist nicht mehr verfügbar.');
        }
        await LearningStorage.write(
            prefs,
            storageKey,
            jsonEncode(
                {'version': 1, 'ownerId': ownerId, 'attempt': next?.toJson()}));
        return next;
      });

  Future<RecognizedTaskAttempt?> begin(RecognizedTask task) => _change(
      (current) => current ?? RecognizedTaskAttempt.begin(ownerId, task));

  Future<RecognizedTaskAttempt?> accept(RecognizedTaskAttempt attempt) =>
      _change((current) {
        if (current == null ||
            current.id != attempt.id ||
            !attempt.answered ||
            jsonEncode(current.task.toJson()) !=
                jsonEncode(attempt.task.toJson()) ||
            current.startedAt != attempt.startedAt) {
          throw StateError('Diese Aufgabe ist nicht mehr geöffnet.');
        }
        return current.answered ? current : attempt;
      });

  Future<RecognizedTaskAttempt?> complete(String id) => _change((current) {
        if (current == null || current.id != id || !current.answered) {
          throw StateError('Das gespeicherte Aufgabenergebnis fehlt.');
        }
        return current.finish();
      });

  Future<RecognizedTaskAttempt?> leave(String id) => _change((current) {
        if (current != null &&
            (current.id != id || (current.answered && !current.completed))) {
          throw StateError(
              'Bitte das offene Ergebnis zuerst fertig speichern.');
        }
        return null;
      });
}
