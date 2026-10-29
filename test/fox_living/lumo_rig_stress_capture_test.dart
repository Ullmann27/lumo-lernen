import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/widgets/fox/living/lumo_fox_mesh.dart';
import 'package:lumo_lernen/widgets/fox/living/lumo_fox_rig.dart';

/// Visual review tool: renders every rigged pose at rest and at the largest
/// head, ear and tail values. Runs only with LUMO_RIG_STRESS=<dir>; the
/// automatic tear check lives in lumo_fox_mesh_test.dart.
final _dir = Platform.environment['LUMO_RIG_STRESS'];

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.image, this.rig, this.frame);
  final ui.Image image;
  final LumoFoxRig rig;
  final LumoRigFrame frame;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.ImageShader(
          image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage);
    final pixels = Size(image.width.toDouble(), image.height.toDouble());
    canvas.drawVertices(
        LumoFoxMesh.grid(
            source: const Rect.fromLTWH(0, 0, 1, 1),
            imagePixels: pixels,
            canvas: size,
            map: (p) => LumoFoxMesh.deform(rig, frame, p)),
        BlendMode.srcOver,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

void main() {
  testWidgets('exaggerated head, ears and tail stay connected', (tester) async {
    for (final pose in LumoDesignFoxPose.values) {
      final rig = LumoFoxRig.of(pose);
      if (rig == null) continue;
      final image = (await tester.runAsync(() async {
        final data = await rootBundle.load(pose.assetPath);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
            targetWidth: 512);
        return (await codec.getNextFrame()).image;
      }))!;
      for (final (label, frame) in [
        ('rest', LumoRigFrame.rest),
        // Largest values the living states actually use.
        (
          'stress-a',
          const LumoRigFrame(
              headTilt: .12,
              headNod: .01,
              earLeft: .15,
              earRight: .15,
              tail: .30)
        ),
        (
          'stress-b',
          const LumoRigFrame(
              headTilt: -.12,
              headTurn: -.01,
              earLeft: -.15,
              earRight: -.15,
              tail: -.30)
        ),
      ]) {
        const key = ValueKey('stress');
        await tester.binding.setSurfaceSize(const Size(400, 400));
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: Container(
                color: const Color(0xFF151A2A),
                child: CustomPaint(
                    size: const Size(400, 400),
                    painter: _MeshPainter(image, rig, frame)))));
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
        await tester.runAsync(() async {
          final shot = await boundary.toImage();
          final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$_dir/${pose.assetName}-$label.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
    }
    await tester.binding.setSurfaceSize(null);
  }, skip: _dir == null);
}
