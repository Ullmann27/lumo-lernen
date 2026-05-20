// Tests fuer StrokeCaptureController.
//
// Mindesttests aus Auftrag:
//   1. Punkte werden gespeichert
//   2. Clear loescht Strokes
//   3. Undo entfernt letzten Stroke

import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/features/writing/logic/stroke_capture_controller.dart';

void main() {
  group('StrokeCaptureController', () {
    test('beginStroke + appendPoint + endStroke commitet einen Stroke', () {
      final c = StrokeCaptureController();
      c.beginStroke(10, 10, timestampMs: 0);
      c.appendPoint(20, 20, timestampMs: 50);
      c.appendPoint(30, 30, timestampMs: 100);
      c.endStroke(timestampMs: 150);
      expect(c.committedStrokeCount, 1);
      expect(c.strokes.first.points.length, 3);
      expect(c.strokes.first.points.first.x, 10);
      expect(c.strokes.first.points.last.x, 30);
    });

    test('Stroke mit nur einem Punkt wird verworfen', () {
      final c = StrokeCaptureController();
      c.beginStroke(10, 10, timestampMs: 0);
      c.endStroke(timestampMs: 10);
      expect(c.committedStrokeCount, 0);
    });

    test('Undo entfernt letzten Stroke', () {
      final c = StrokeCaptureController();
      // erster Stroke
      c.beginStroke(0, 0, timestampMs: 0);
      c.appendPoint(10, 10, timestampMs: 10);
      c.endStroke(timestampMs: 20);
      // zweiter Stroke
      c.beginStroke(50, 50, timestampMs: 30);
      c.appendPoint(60, 60, timestampMs: 40);
      c.endStroke(timestampMs: 50);
      expect(c.committedStrokeCount, 2);
      c.undo();
      expect(c.committedStrokeCount, 1);
      expect(c.strokes.first.points.first.x, 0);
    });

    test('Clear loescht alle Strokes inkl. aktivem', () {
      final c = StrokeCaptureController();
      c.beginStroke(0, 0, timestampMs: 0);
      c.appendPoint(10, 10, timestampMs: 10);
      c.endStroke(timestampMs: 20);
      c.beginStroke(50, 50, timestampMs: 30);
      c.appendPoint(60, 60, timestampMs: 40);
      // ohne endStroke -> aktiv
      expect(c.committedStrokeCount, 1);
      expect(c.hasActiveStroke, isTrue);
      c.clear();
      expect(c.committedStrokeCount, 0);
      expect(c.hasActiveStroke, isFalse);
    });

    test('cancelActiveStroke verwirft den aktiven Stroke', () {
      final c = StrokeCaptureController();
      c.beginStroke(0, 0, timestampMs: 0);
      c.appendPoint(10, 10, timestampMs: 10);
      expect(c.hasActiveStroke, isTrue);
      c.cancelActiveStroke();
      expect(c.hasActiveStroke, isFalse);
      expect(c.committedStrokeCount, 0);
    });

    test('snapshotForAnalysis commitet aktive Punkte vor Rueckgabe', () {
      final c = StrokeCaptureController();
      c.beginStroke(0, 0, timestampMs: 0);
      c.appendPoint(10, 10, timestampMs: 10);
      c.appendPoint(20, 20, timestampMs: 20);
      // kein endStroke
      final snap = c.snapshotForAnalysis();
      expect(snap.length, 1);
      expect(snap.first.points.length, 3);
    });
  });
}
