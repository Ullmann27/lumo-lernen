import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/widgets/fox/living/lumo_fox_mesh.dart';
import 'package:lumo_lernen/widgets/fox/living/lumo_fox_rig.dart';
import 'package:lumo_lernen/widgets/fox/living/lumo_living_character.dart';

/// Largest values the living states use, in both directions.
const _extremes = [
  LumoRigFrame(
      headTilt: .12,
      headNod: .01,
      earLeft: .15,
      earRight: .15,
      tail: .30,
      breath: 1,
      gazeX: 1,
      gazeY: 1,
      blink: 1),
  LumoRigFrame(
      headTilt: -.12,
      headTurn: -.01,
      earLeft: -.15,
      earRight: -.15,
      tail: -.30,
      breath: -1,
      gazeX: -1,
      gazeY: -1,
      blink: .5),
];

Iterable<LumoFoxRig> get _rigs =>
    LumoDesignFoxPose.values.map(LumoFoxRig.of).whereType<LumoFoxRig>();

void main() {
  test('nine original poses are rigged; ears, eyes and tail lie in the image',
      () {
    expect(_rigs.length, 9);
    bool inside(Offset p) => p.dx >= 0 && p.dx <= 1 && p.dy >= 0 && p.dy <= 1;
    for (final rig in _rigs) {
      for (final p in [
        rig.neck,
        rig.head,
        rig.hand,
        rig.tail.base,
        rig.tail.tip,
        rig.leftEar.tip,
        rig.leftEar.base,
        rig.rightEar.tip,
        rig.rightEar.base,
      ]) {
        expect(inside(p), isTrue, reason: '${rig.pose} $p');
      }
      expect(rig.leftEye != null || rig.rightEye != null, isTrue);
    }
  });

  test('the rest frame leaves every point exactly in place', () {
    for (final rig in _rigs) {
      for (var y = 0.0; y <= 1; y += .1) {
        for (var x = 0.0; x <= 1; x += .1) {
          final p = Offset(x, y);
          expect(LumoFoxMesh.deform(rig, LumoRigFrame.rest, p), p);
        }
      }
    }
  });

  test('feet stay planted and the gesture hand stays put', () {
    for (final rig in _rigs) {
      for (final f in _extremes) {
        final foot = Offset(.5, .97);
        expect(
            (LumoFoxMesh.deform(rig, f, foot) - foot).distance, lessThan(1e-9),
            reason: '${rig.pose} foot');
        // Breathing may lift the torso a little; nothing else moves the hand.
        final hand = LumoFoxMesh.deform(rig, f, rig.hand);
        expect((hand - rig.hand).distance, lessThan(.012),
            reason: '${rig.pose} hand ${rig.hand} -> $hand');
      }
    }
  });

  test('ear and tail tips move more than their bases', () {
    for (final rig in _rigs) {
      final f = _extremes.first;
      double moved(Offset p) => (LumoFoxMesh.deform(rig, f, p) - p).distance;
      expect(moved(rig.tail.tip), greaterThan(moved(rig.tail.base) + .02),
          reason: '${rig.pose} tail');
      expect(moved(rig.leftEar.tip), greaterThan(.01), reason: '${rig.pose}');
      expect(moved(rig.rightEar.tip), greaterThan(.01), reason: '${rig.pose}');
    }
  });

  testWidgets('no tearing where Lumo is visible, in every living state',
      (tester) async {
    // A tear shows up as a large local stretch between visible neighbours.
    // Each state is sampled with its real motion over twelve seconds.
    const n = 80;
    final alphas = <LumoDesignFoxPose, List<int>>{};
    final worstByState = <LumoLivingState, double>{};
    for (final state in LumoLivingState.values) {
      final rig = LumoFoxRig.of(state.pose)!;
      final alpha = alphas[state.pose] ??= (await tester.runAsync(() async {
        final data = await rootBundle.load(rig.pose.assetPath);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
            targetWidth: n + 1, targetHeight: n + 1);
        final image = (await codec.getNextFrame()).image;
        final bytes = await image.toByteData();
        return bytes!.buffer.asUint8List().toList();
      }))!;
      bool visible(int x, int y) => alpha[(y * (n + 1) + x) * 4 + 3] > 25;
      var worst = 0.0;
      for (var t = .05; t < 12; t += .5) {
        final f = lumoLivingFrame(state, t);
        for (var y = 0; y < n; y++) {
          for (var x = 0; x < n; x++) {
            if (!visible(x, y)) continue;
            final q = LumoFoxMesh.deform(rig, f, Offset(x / n, y / n));
            for (final (nx, ny) in [(x + 1, y), (x, y + 1)]) {
              if (!visible(nx, ny)) continue;
              final r = LumoFoxMesh.deform(rig, f, Offset(nx / n, ny / n));
              final stretch = (r - q).distance * n;
              if (stretch > worst) worst = stretch;
            }
          }
        }
      }
      worstByState[state] = worst;
    }
    final report = worstByState.entries
        .map((e) => '${e.key.name} ${e.value.toStringAsFixed(2)}')
        .join(', ');
    debugPrint('stretch report: $report');
    for (final worst in worstByState.values) {
      expect(worst, lessThan(1.6), reason: report);
    }
  });

  test('the blink pinch stays inside the eye region and is continuous', () {
    for (final rig in _rigs) {
      for (final eye in [rig.leftEye, rig.rightEye].whereType<LumoEyeRig>()) {
        const f = LumoRigFrame(blink: 1);
        final outside = Offset(eye.cx + eye.rx * 2, eye.cy);
        expect(LumoFoxMesh.deformEye(rig, eye, f, outside), outside);
        var worst = 0.0;
        const step = .002;
        for (var y = eye.cy - eye.ry * 2.6;
            y < eye.cy + eye.ry * 2.4;
            y += step) {
          final q = LumoFoxMesh.deformEye(rig, eye, f, Offset(eye.cx, y));
          final r =
              LumoFoxMesh.deformEye(rig, eye, f, Offset(eye.cx, y + step));
          final stretch = (r - q).distance / step;
          if (stretch > worst) worst = stretch;
        }
        expect(worst, lessThan(3.2), reason: '${rig.pose}');
        expect(LumoFoxMesh.lidOpacity(1), 1);
        expect(LumoFoxMesh.lidOpacity(0), 0);
      }
    }
  });
}
