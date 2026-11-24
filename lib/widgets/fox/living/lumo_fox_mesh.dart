import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'lumo_fox_rig.dart';

/// Momentane Haltung der beweglichen Teile. Winkel im Bogenmaß, Strecken
/// normiert auf die Bildgröße; alles bewusst klein, damit Lumo Lumo bleibt.
class LumoRigFrame {
  const LumoRigFrame({
    this.headTilt = 0,
    this.headNod = 0,
    this.headTurn = 0,
    this.earLeft = 0,
    this.earRight = 0,
    this.tail = 0,
    this.breath = 0,
    this.gazeX = 0,
    this.gazeY = 0,
    this.blink = 0,
  });

  /// Kopfneigung um den Hals, positiv im Uhrzeigersinn.
  final double headTilt;

  /// Nicken nach unten (positiv) und Kopfdrehung zur Seite, normiert.
  final double headNod;
  final double headTurn;

  /// Ohren: positiv klappt die Spitze nach außen, negativ richtet sie auf.
  final double earLeft;
  final double earRight;

  /// Schweifspitze: positiv nach oben.
  final double tail;

  /// Atmung von -1 (aus) bis 1 (ein).
  final double breath;

  /// Blickrichtung der Pupillen, je -1..1.
  final double gazeX;
  final double gazeY;

  /// 0 offen, 1 geschlossen.
  final double blink;

  static const rest = LumoRigFrame();

  LumoRigFrame withBlink(double value) => LumoRigFrame(
        headTilt: headTilt,
        headNod: headNod,
        headTurn: headTurn,
        earLeft: earLeft,
        earRight: earRight,
        tail: tail,
        breath: breath,
        gazeX: gazeX,
        gazeY: gazeY,
        blink: value,
      );

  static LumoRigFrame lerp(LumoRigFrame a, LumoRigFrame b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    return LumoRigFrame(
      headTilt: l(a.headTilt, b.headTilt),
      headNod: l(a.headNod, b.headNod),
      headTurn: l(a.headTurn, b.headTurn),
      earLeft: l(a.earLeft, b.earLeft),
      earRight: l(a.earRight, b.earRight),
      tail: l(a.tail, b.tail),
      breath: l(a.breath, b.breath),
      gazeX: l(a.gazeX, b.gazeX),
      gazeY: l(a.gazeY, b.gazeY),
      blink: l(a.blink, b.blink),
    );
  }
}

/// Gitterverformung eines Original-Renderings.
///
/// Alle Funktionen arbeiten in normierten Bildkoordinaten (0..1). Die
/// Körperverformung ist stetig: außerhalb von Ohren, Kopf, Schweif und
/// Rumpf bleibt jeder Punkt exakt an seiner Stelle.
class LumoFoxMesh {
  const LumoFoxMesh._();

  /// Wohin der Bildpunkt [p] bei Haltung [f] wandert (ohne Augen).
  static Offset deform(LumoFoxRig rig, LumoRigFrame f, Offset p) {
    // Ohren drehen um ihren Ansatz; die Spitze bewegt sich am meisten.
    var q = _rotateEar(rig, rig.leftEar, p, f.earLeft);
    q = _rotateEar(rig, rig.rightEar, q, f.earRight);
    // Kopf samt Ohren dreht um den Hals.
    final headWeight = _headWeight(rig, p);
    if (headWeight > 0) {
      q = _rotate(q, rig.neck, f.headTilt * headWeight) +
          Offset(f.headTurn, f.headNod) * headWeight;
    }
    // Der Schweif biegt sich zur Spitze hin immer stärker.
    q = _rotateLimb(rig.tail, q, f.tail, exponent: 2, membershipOf: p);
    // Atmen hebt Rumpf und Kopf; Beine und Füße bleiben stehen.
    final span = rig.hipY - rig.neck.dy;
    final lift = ((rig.hipY - p.dy) / span).clamp(0.0, 1.0);
    return q.translate(0, -f.breath * .009 * lift);
  }

  /// Ein Augenpunkt: erst Blick und Lidschlag im Auge, dann der Kopf.
  static Offset deformEye(
      LumoFoxRig rig, LumoEyeRig eye, LumoRigFrame f, Offset p) {
    var q = p;
    final u = (p.dx - eye.cx) / eye.rx;
    final v = (p.dy - eye.cy) / eye.ry;
    final r2 = u * u + v * v;
    if (r2 < 1) {
      final falloff = (1 - r2) * (1 - r2);
      q = q.translate(
          f.gazeX * .24 * eye.rx * falloff, f.gazeY * .16 * eye.ry * falloff);
    }
    final pinch = .62 * _smooth(0, .6, f.blink);
    if (pinch > 0) q = Offset(q.dx, _pinchY(eye, p.dx, q.dy, pinch));
    return deform(rig, f, q);
  }

  /// Deckkraft des Original-Lids beim Blinzeln.
  static double lidOpacity(double blink) => _smooth(.42, .8, blink);

  /// Senkrechte Abbildung beim Blinzeln: Fell über und unter dem Auge
  /// schiebt sich zur Lidlinie, das Auge selbst wird schmaler.
  static double _pinchY(LumoEyeRig eye, double x, double y, double c) {
    final rx = eye.rx * 1.22, ry = eye.ry * 1.24;
    final u = (x - eye.cx) / rx;
    if (u.abs() >= 1) return y;
    final w = math.sqrt(1 - u * u);
    final top = eye.cy - ry * w, bottom = eye.cy + ry * w;
    final lid = (eye.cy + .25 * ry).clamp(top, bottom);
    final above = 1.5 * ry * w, below = 1.1 * ry * w;
    if (above <= 0 || y < top - above || y > bottom + below) return y;
    final newTop = top + (lid - top) * c;
    final newBottom = bottom - (bottom - lid) * c;
    if (y <= top) {
      return (top - above) +
          (y - (top - above)) * (newTop - (top - above)) / above;
    }
    if (y <= lid) {
      return lid == top
          ? lid
          : newTop + (y - top) * (lid - newTop) / (lid - top);
    }
    if (y <= bottom) {
      return bottom == lid
          ? lid
          : lid + (y - lid) * (newBottom - lid) / (bottom - lid);
    }
    return newBottom + (y - bottom) * ((bottom + below) - newBottom) / below;
  }

  static Offset _rotateEar(
      LumoFoxRig rig, LumoEarRig ear, Offset p, double flick) {
    if (flick == 0) return p;
    final member = _earMembership(ear, p);
    if (member <= 0) return p;
    final base = ear.base;
    final axis = ear.tip - base;
    final rel = p - base;
    final along = ((rel.dx * axis.dx + rel.dy * axis.dy) /
            (axis.dx * axis.dx + axis.dy * axis.dy))
        .clamp(0.0, 1.0);
    final h = rig.head - base;
    final cross = axis.dx * h.dy - axis.dy * h.dx;
    // Positiver Winkel dreht im Bild im Uhrzeigersinn (y zeigt nach unten).
    final angle = cross > 0 ? -flick : flick;
    return _rotate(p, base, angle * math.pow(along, 1.2) * member);
  }

  /// 1 im Ohr-Umriss, weicher Saum nach außen.
  static double _earMembership(LumoEarRig ear, Offset p) {
    final distance = _polygonDistance(p, ear.outline);
    return 1 - _smooth(.015, .075, distance);
  }

  /// Vorzeichenbehafteter Abstand zu einem konvexen Vieleck: negativ innen.
  static double _polygonDistance(Offset p, List<Offset> points) {
    var positive = true, negative = true;
    var distance = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      final side =
          (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);
      if (side < 0) positive = false;
      if (side > 0) negative = false;
      distance = math.min(distance, _segmentDistance(p, a, b));
    }
    return positive || negative ? -distance : distance;
  }

  static double _segmentDistance(Offset p, Offset a, Offset b) {
    final d = b - a;
    final t =
        (((p - a).dx * d.dx + (p - a).dy * d.dy) / (d.dx * d.dx + d.dy * d.dy))
            .clamp(0.0, 1.0);
    return (p - (a + d * t)).distance;
  }

  static double _headWeight(LumoFoxRig rig, Offset p) {
    final u = (p.dx - rig.head.dx) / rig.headRadius.width;
    final v = (p.dy - rig.head.dy) / rig.headRadius.height;
    final face = 1 - _smooth(1.0, rig.headFalloff, math.sqrt(u * u + v * v));
    final ears = math.max(
        _earMembership(rig.leftEar, p), _earMembership(rig.rightEar, p));
    final neck = 1 - _smooth(rig.neck.dy - .09, rig.neck.dy + .04, p.dy);
    return math.max(face, ears) * neck;
  }

  static Offset _rotateLimb(LumoLimbRig limb, Offset p, double angle,
      {required double exponent, Offset? membershipOf}) {
    if (angle == 0) return p;
    final (along, member) = _membership(limb, membershipOf ?? p);
    if (member <= 0) return p;
    final weight = math.pow(along, exponent) * member;
    return _rotate(p, limb.base, angle * weight);
  }

  /// (Lage entlang des Glieds 0..1, Zugehörigkeit 0..1).
  static (double, double) _membership(LumoLimbRig limb, Offset p) {
    final d = limb.tip - limb.base;
    final length2 = d.dx * d.dx + d.dy * d.dy;
    final rel = p - limb.base;
    final t = (rel.dx * d.dx + rel.dy * d.dy) / length2;
    final along = t.clamp(0.0, 1.0);
    final distance = (p - (limb.base + d * along)).distance;
    final radius = limb.width / 2;
    final member = 1 - _smooth(radius * .9, radius * 1.7, distance);
    return (t < -.05 ? 0 : along, t < -.05 ? 0 : member);
  }

  static Offset _rotate(Offset p, Offset pivot, double angle) {
    if (angle == 0) return p;
    final c = math.cos(angle), s = math.sin(angle);
    final x = p.dx - pivot.dx, y = p.dy - pivot.dy;
    return Offset(pivot.dx + c * x - s * y, pivot.dy + s * x + c * y);
  }

  static double _smooth(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  // ── Gitter → Vertices ─────────────────────────────────────────────────

  static final Map<(int, int), Uint16List> _indexCache = {};

  static Uint16List _indices(int columns, int rows) =>
      _indexCache.putIfAbsent((columns, rows), () {
        final list = Uint16List(columns * rows * 6);
        var k = 0;
        for (var y = 0; y < rows; y++) {
          for (var x = 0; x < columns; x++) {
            final i = y * (columns + 1) + x;
            list[k++] = i;
            list[k++] = i + 1;
            list[k++] = i + columns + 1;
            list[k++] = i + 1;
            list[k++] = i + columns + 2;
            list[k++] = i + columns + 1;
          }
        }
        return list;
      });

  /// Gitter über [source] (normiert) im Bild, abgebildet über [map] auf
  /// normierte Zielpunkte und dann auf [canvas] skaliert.
  static Vertices grid({
    required Rect source,
    required Size imagePixels,
    required Size canvas,
    required Offset Function(Offset p) map,
    int columns = 40,
    int rows = 40,
    double Function(Offset p)? opacity,
  }) {
    final count = (columns + 1) * (rows + 1);
    final positions = Float32List(count * 2);
    final texture = Float32List(count * 2);
    final colors = opacity == null ? null : Int32List(count);
    var k = 0;
    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= columns; x++) {
        final p = Offset(source.left + source.width * x / columns,
            source.top + source.height * y / rows);
        final q = map(p);
        positions[k * 2] = q.dx * canvas.width;
        positions[k * 2 + 1] = q.dy * canvas.height;
        texture[k * 2] = p.dx * imagePixels.width;
        texture[k * 2 + 1] = p.dy * imagePixels.height;
        if (colors != null) {
          final a = (opacity!(p).clamp(0.0, 1.0) * 255).round();
          colors[k] = (a << 24) | 0x00FFFFFF;
        }
        k++;
      }
    }
    return Vertices.raw(VertexMode.triangles, positions,
        textureCoordinates: texture,
        colors: colors,
        indices: _indices(columns, rows));
  }
}
