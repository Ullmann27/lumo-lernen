import 'dart:ui';

import '../../design/lumo_design_system.dart';

/// Augapfel als Ellipse, normiert auf die Bildgröße (0..1).
class LumoEyeRig {
  const LumoEyeRig(this.cx, this.cy, this.rx, this.ry);
  final double cx, cy, rx, ry;
  Offset get center => Offset(cx, cy);
}

/// Ohr als Dreieck: Spitze und die beiden Ansatzpunkte am Kopf, normiert.
class LumoEarRig {
  const LumoEarRig(this.tip, this.baseA, this.baseB,
      {this.shoulderA, this.shoulderB});
  final Offset tip;
  final Offset baseA;
  final Offset baseB;

  /// Rundliche Ohrkanten: optionaler Punkt zwischen Spitze und Ansatz.
  final Offset? shoulderA;
  final Offset? shoulderB;
  Offset get base => (baseA + baseB) / 2;

  /// Umriss als konvexes Vieleck in Reihenfolge.
  List<Offset> get outline => [
        tip,
        if (shoulderB != null) shoulderB!,
        baseB,
        baseA,
        if (shoulderA != null) shoulderA!,
      ];
}

/// Schweif: Ansatz, Spitze und Breite, normiert.
class LumoLimbRig {
  const LumoLimbRig(this.base, this.tip, this.width);
  final Offset base;
  final Offset tip;
  final double width;
}

/// Bewegungs-Rig auf einem fertigen Original-Rendering von Lumo.
///
/// Die Posen sind gerenderte Einzelbilder ohne Skelett. Das Rig beschreibt,
/// wo Kopf, Ohren, Augen, Schweif und die zeigende Hand im Bild liegen
/// (am Original vermessen, siehe docs/visual/2026-10-29-living-world). Ein
/// Gitter verformt nur diese Bereiche (2D-Gitterverformung nach dem
/// Live2D-Prinzip); eine 3D-Skelettanimation ist mit den Originalen nicht
/// möglich und wird nicht behauptet.
class LumoFoxRig {
  const LumoFoxRig({
    required this.pose,
    required this.neck,
    required this.head,
    required this.headRadius,
    required this.leftEar,
    required this.rightEar,
    required this.tail,
    required this.hand,
    required this.hipY,
    this.leftEye,
    this.rightEye,
    this.leftLidTint = const [1, 1, 1],
    this.rightLidTint = const [1, 1, 1],
    this.headFalloff = 1.18,
  });

  final LumoDesignFoxPose pose;

  /// Drehpunkt des Kopfes.
  final Offset neck;

  /// Mitte und Halbachsen des Gesichts.
  final Offset head;
  final Size headRadius;
  final LumoEarRig leftEar;
  final LumoEarRig rightEar;
  final LumoLimbRig tail;

  /// Geschlossene Augen (Zwinkern im Original) haben kein Rig.
  final LumoEyeRig? leftEye;
  final LumoEyeRig? rightEye;

  /// Farbabgleich des Original-Lids zum Fell dieser Pose (R, G, B).
  final List<double> leftLidTint;
  final List<double> rightLidTint;

  /// Zeigefinger, Daumen, Stabspitze oder Pokal: Ursprung von Gesten.
  final Offset hand;

  /// Unterhalb dieser Linie bleiben Beine und Füße beim Atmen stehen.
  final double hipY;

  /// Wie weit (relativ zur Gesichtsellipse) der Kopf weich ausläuft. Kleiner,
  /// wenn eine Hand oder ein Gegenstand dicht an der Wange liegt.
  final double headFalloff;

  static LumoFoxRig? of(LumoDesignFoxPose pose) => _rigs[pose];
  static bool supports(LumoDesignFoxPose pose) => _rigs.containsKey(pose);
}

/// Herkunft der geschlossenen Original-Augen für das Blinzeln.
class LumoLidSource {
  const LumoLidSource(this.pose, this.eye);
  final LumoDesignFoxPose pose;
  final LumoEyeRig eye;

  /// Linkes Auge geschlossen: Lumo mit Pokal (zwinkert links).
  static const left = LumoLidSource(
      LumoDesignFoxPose.trophyWink, LumoEyeRig(.432, .348, .044, .043));

  /// Rechtes Auge geschlossen: Lumo mit Daumen hoch (zwinkert rechts).
  static const right = LumoLidSource(
      LumoDesignFoxPose.thumbWink, LumoEyeRig(.636, .292, .042, .044));
}

const Map<LumoDesignFoxPose, LumoFoxRig> _rigs = {
  LumoDesignFoxPose.armsOpen: LumoFoxRig(
    pose: LumoDesignFoxPose.armsOpen,
    neck: Offset(.52, .46),
    head: Offset(.51, .28),
    headRadius: Size(.22, .20),
    leftEar:
        LumoEarRig(Offset(0.16, 0.135), Offset(0.27, 0.35), Offset(0.35, 0.16)),
    rightEar: LumoEarRig(
        Offset(0.586, 0.008), Offset(0.5, 0.11), Offset(0.675, 0.25)),
    tail: LumoLimbRig(Offset(.38, .72), Offset(.11, .76), .22),
    leftEye: LumoEyeRig(.4243, .3408, .0406, .0443),
    rightEye: LumoEyeRig(.5947, .2925, .0411, .0459),
    leftLidTint: [.999, .918, .859],
    rightLidTint: [1.024, .936, .893],
    hand: Offset(.86, .45),
    hipY: .70,
  ),
  LumoDesignFoxPose.bookWelcome: LumoFoxRig(
    pose: LumoDesignFoxPose.bookWelcome,
    neck: Offset(.52, .47),
    head: Offset(.505, .29),
    headRadius: Size(.245, .19),
    leftEar: LumoEarRig(
        Offset(0.17, 0.105), Offset(0.265, 0.37), Offset(0.345, 0.155),
        shoulderA: Offset(0.155, 0.22)),
    rightEar: LumoEarRig(
        Offset(0.672, 0.02), Offset(0.54, 0.11), Offset(0.73, 0.29),
        shoulderB: Offset(0.735, 0.1)),
    tail: LumoLimbRig(Offset(.33, .70), Offset(.07, .68), .26),
    leftEye: LumoEyeRig(.4179, .3533, .0482, .0456),
    rightEye: LumoEyeRig(.5965, .3146, .0448, .0478),
    leftLidTint: [1.125, 1.057, .967],
    rightLidTint: [1.045, .994, .957],
    hand: Offset(.86, .50),
    hipY: .74,
  ),
  LumoDesignFoxPose.bookPoint: LumoFoxRig(
    pose: LumoDesignFoxPose.bookPoint,
    neck: Offset(.51, .47),
    head: Offset(.50, .28),
    headRadius: Size(.22, .20),
    leftEar: LumoEarRig(
        Offset(0.155, 0.142), Offset(0.275, 0.37), Offset(0.335, 0.155)),
    rightEar: LumoEarRig(
        Offset(0.567, 0.008), Offset(0.48, 0.105), Offset(0.672, 0.25),
        shoulderB: Offset(0.665, 0.1)),
    tail: LumoLimbRig(Offset(.30, .72), Offset(.06, .72), .22),
    leftEye: LumoEyeRig(.415, .3389, .0422, .0443),
    rightEye: LumoEyeRig(.5854, .2891, .0417, .0454),
    leftLidTint: [1.06, .982, .901],
    rightLidTint: [1.048, 1.008, .942],
    hand: Offset(.78, .31),
    hipY: .70,
  ),
  LumoDesignFoxPose.pointSide: LumoFoxRig(
    pose: LumoDesignFoxPose.pointSide,
    neck: Offset(.48, .45),
    head: Offset(.465, .27),
    headRadius: Size(.215, .19),
    leftEar: LumoEarRig(
        Offset(0.12, 0.157), Offset(0.27, 0.38), Offset(0.31, 0.165)),
    rightEar: LumoEarRig(
        Offset(0.526, 0.009), Offset(0.445, 0.1), Offset(0.63, 0.245)),
    tail: LumoLimbRig(Offset(.33, .68), Offset(.05, .71), .22),
    leftEye: LumoEyeRig(.3921, .3398, .0406, .0432),
    rightEye: LumoEyeRig(.5522, .2876, .0396, .0427),
    leftLidTint: [1.066, .997, .883],
    rightLidTint: [1.03, .984, .906],
    hand: Offset(.96, .36),
    hipY: .68,
  ),
  LumoDesignFoxPose.thumbWink: LumoFoxRig(
    pose: LumoDesignFoxPose.thumbWink,
    neck: Offset(.53, .46),
    head: Offset(.525, .275),
    headRadius: Size(.235, .195),
    leftEar:
        LumoEarRig(Offset(0.204, 0.12), Offset(0.32, 0.37), Offset(0.38, 0.16)),
    rightEar: LumoEarRig(
        Offset(0.654, 0.019), Offset(0.54, 0.12), Offset(0.72, 0.255)),
    tail: LumoLimbRig(Offset(.37, .72), Offset(.11, .73), .22),
    leftEye: LumoEyeRig(.4556, .3374, .0374, .0396),
    leftLidTint: [.986, .939, .883],
    hand: Offset(.79, .38),
    headFalloff: 1.07,
    hipY: .70,
  ),
  LumoDesignFoxPose.tabletThumb: LumoFoxRig(
    pose: LumoDesignFoxPose.tabletThumb,
    neck: Offset(.56, .45),
    head: Offset(.535, .27),
    headRadius: Size(.22, .19),
    leftEar: LumoEarRig(
        Offset(0.204, 0.11), Offset(0.33, 0.335), Offset(0.365, 0.157)),
    rightEar:
        LumoEarRig(Offset(0.64, 0.0), Offset(0.50, 0.12), Offset(0.74, 0.255)),
    tail: LumoLimbRig(Offset(.39, .72), Offset(.13, .75), .22),
    leftEye: LumoEyeRig(.4492, .3208, .0422, .0417),
    rightEye: LumoEyeRig(.6147, .2856, .0385, .0427),
    leftLidTint: [1.081, 1.007, .922],
    rightLidTint: [1.046, .995, .944],
    hand: Offset(.30, .41),
    hipY: .70,
  ),
  LumoDesignFoxPose.teacherStick: LumoFoxRig(
    pose: LumoDesignFoxPose.teacherStick,
    neck: Offset(.50, .46),
    head: Offset(.485, .275),
    headRadius: Size(.215, .195),
    leftEar: LumoEarRig(
        Offset(0.13, 0.16), Offset(0.275, 0.385), Offset(0.31, 0.17)),
    rightEar: LumoEarRig(
        Offset(0.54, 0.011), Offset(0.455, 0.105), Offset(0.64, 0.24)),
    tail: LumoLimbRig(Offset(.36, .72), Offset(.08, .74), .24),
    leftEye: LumoEyeRig(.3975, .3398, .039, .0443),
    rightEye: LumoEyeRig(.5596, .2866, .0411, .0438),
    leftLidTint: [1.045, 1.001, .957],
    rightLidTint: [1.034, .994, .95],
    hand: Offset(.90, .13),
    hipY: .70,
  ),
  LumoDesignFoxPose.cheer: LumoFoxRig(
    pose: LumoDesignFoxPose.cheer,
    neck: Offset(.56, .45),
    head: Offset(.54, .27),
    headRadius: Size(.20, .19),
    leftEar:
        LumoEarRig(Offset(0.204, 0.15), Offset(0.27, 0.3), Offset(0.365, 0.17)),
    rightEar: LumoEarRig(
        Offset(0.58, 0.013), Offset(0.51, 0.12), Offset(0.675, 0.25),
        shoulderB: Offset(0.67, 0.1)),
    tail: LumoLimbRig(Offset(.39, .70), Offset(.13, .70), .24),
    leftEye: LumoEyeRig(.4497, .3325, .0417, .0406),
    rightEye: LumoEyeRig(.6016, .2861, .0401, .0422),
    leftLidTint: [1.123, 1.077, 1.025],
    rightLidTint: [1.038, .983, .943],
    hand: Offset(.79, .25),
    headFalloff: 1.06,
    hipY: .68,
  ),
  LumoDesignFoxPose.trophyWink: LumoFoxRig(
    pose: LumoDesignFoxPose.trophyWink,
    neck: Offset(.53, .45),
    head: Offset(.50, .27),
    headRadius: Size(.20, .19),
    leftEar:
        LumoEarRig(Offset(0.155, 0.18), Offset(0.3, 0.395), Offset(0.34, 0.16)),
    rightEar: LumoEarRig(
        Offset(0.545, 0.011), Offset(0.465, 0.12), Offset(0.657, 0.24)),
    tail: LumoLimbRig(Offset(.38, .72), Offset(.10, .74), .24),
    rightEye: LumoEyeRig(.585, .2842, .0401, .0422),
    rightLidTint: [1.033, .987, .929],
    hand: Offset(.81, .22),
    headFalloff: 1.05,
    hipY: .70,
  ),
};
