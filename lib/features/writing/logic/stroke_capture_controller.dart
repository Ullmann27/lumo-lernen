// ════════════════════════════════════════════════════════════════════════
//                  SCHREIBCOACH - STROKE CAPTURE CONTROLLER
// ════════════════════════════════════════════════════════════════════════
//
// Sammelt Pointer-Events vom Canvas in CoachStroke-Objekten. Bietet
// Undo, Clear und Snapshot-Listener fuer das UI.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/coach_writing_models.dart';

class StrokeCaptureController extends ChangeNotifier {
  StrokeCaptureController();

  final List<CoachStroke> _committed = <CoachStroke>[];
  final List<CoachStrokePoint> _activePoints = <CoachStrokePoint>[];
  int? _activeStartedAtMs;
  int _strokeCounter = 0;

  /// Maximale Anzahl Punkte pro Stroke - schuetzt vor Speicher-Lecks bei
  /// extrem langen Strichen.
  static const int maxPointsPerStroke = 2000;

  /// Liste aller fertigen Strokes (in Zeichen-Reihenfolge).
  List<CoachStroke> get strokes => List<CoachStroke>.unmodifiable(_committed);

  /// Anzahl bereits commiteter Strokes.
  int get committedStrokeCount => _committed.length;

  /// Hat der Controller momentan einen offenen Stroke?
  bool get hasActiveStroke => _activePoints.isNotEmpty;

  /// Live-Snapshot der aktiven Punkte (waehrend der Spieler zeichnet).
  /// Nicht verlaengerbar.
  List<CoachStrokePoint> get activePoints =>
      List<CoachStrokePoint>.unmodifiable(_activePoints);

  /// Beginnt einen neuen Stroke.
  void beginStroke(double x, double y, {int? timestampMs}) {
    final ts = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    // Falls noch ein alter Stroke offen ist (z.B. nach abgebrochenem
    // PointerCancel) -> erst sauber abschliessen.
    if (_activePoints.isNotEmpty) {
      _commitActive(ts);
    }
    _activeStartedAtMs = ts;
    _activePoints.add(CoachStrokePoint(x: x, y: y, timestampMs: ts));
    notifyListeners();
  }

  /// Fuegt einen Punkt zum aktiven Stroke hinzu.
  void appendPoint(double x, double y, {int? timestampMs}) {
    if (_activeStartedAtMs == null) {
      // Falls beginStroke vergessen wurde, beginne implizit.
      beginStroke(x, y, timestampMs: timestampMs);
      return;
    }
    if (_activePoints.length >= maxPointsPerStroke) return;
    final ts = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    _activePoints.add(CoachStrokePoint(x: x, y: y, timestampMs: ts));
    notifyListeners();
  }

  /// Beendet den aktiven Stroke und legt ihn auf die Stroke-Liste.
  /// Strokes mit weniger als 2 Punkten werden verworfen.
  void endStroke({int? timestampMs}) {
    final ts = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    _commitActive(ts);
    notifyListeners();
  }

  /// Abbruch des aktiven Strokes (z.B. PointerCancel).
  void cancelActiveStroke() {
    _activePoints.clear();
    _activeStartedAtMs = null;
    notifyListeners();
  }

  /// Letzten Stroke entfernen.
  void undo() {
    if (_committed.isEmpty) return;
    _committed.removeLast();
    notifyListeners();
  }

  /// Alle Strokes loeschen.
  void clear() {
    _committed.clear();
    _activePoints.clear();
    _activeStartedAtMs = null;
    notifyListeners();
  }

  /// Snapshot fuer Analyse: enthaelt nur committed Strokes (laufender
  /// Stroke wird vorher implizit beendet, falls vorhanden).
  List<CoachStroke> snapshotForAnalysis() {
    if (_activePoints.isNotEmpty) {
      _commitActive(DateTime.now().millisecondsSinceEpoch);
    }
    return List<CoachStroke>.unmodifiable(_committed);
  }

  void _commitActive(int endTs) {
    if (_activePoints.length < 2) {
      _activePoints.clear();
      _activeStartedAtMs = null;
      return;
    }
    final stroke = CoachStroke(
      id: 'stroke_${_strokeCounter++}',
      points: List<CoachStrokePoint>.from(_activePoints),
      startedAtMs: _activeStartedAtMs ?? endTs,
      endedAtMs: endTs,
    );
    _committed.add(stroke);
    _activePoints.clear();
    _activeStartedAtMs = null;
  }
}
