import 'package:flutter/widgets.dart';

import '../../../widgets/design/lumo_motion.dart';
import '../../../widgets/fox/living/lumo_living_character.dart';
import 'learning_scene_contract.dart';

/// Einheitliche Bewegungsregeln für Lernszenen.
///
/// Jede Bewegung hat einen Zweck: Sie lenkt den Blick, zeigt eine echte
/// mathematische Handlung (zehn Würfel werden eine Stange) oder bestätigt
/// eine Eingabe. Animationen laufen neben der Handlung her, verzögern keine
/// Eingabe, lassen sich jederzeit unterbrechen und wiederholen. Mit
/// „Animationen reduzieren“ zeigt die Szene sofort den Endzustand; die
/// Handlung bleibt durch Text, Farbe und Anordnung verständlich.
abstract final class LearningSceneMotion {
  /// Erklärungsbeginn: Lumo und die Bühne erscheinen.
  static const Duration explanationStart = Duration(milliseconds: 420);

  /// Objekttransformation: Würfel werden zur Stange, Stange zu Würfeln.
  static const Duration objectTransform = Duration(milliseconds: 950);

  /// Versatz zwischen gleichartigen Objekten einer Transformation.
  static const Duration stagger = LumoMotion.stagger;

  /// Interaktion: Antippen, Anheben, Markieren.
  static const Duration interaction = Duration(milliseconds: 220);

  /// Rückmeldung zu einer Prüfung.
  static const Duration feedback = Duration(milliseconds: 380);

  /// Methodenwechsel (Zählen ↔ Bündeln, Abschnittswechsel).
  static const Duration methodChange = LumoMotion.page;

  /// Abschluss eines Lernschritts.
  static const Duration completion = Duration(milliseconds: 1100);

  /// Lumos Vorführung des Bündelns.
  static const Duration demonstration = Duration(milliseconds: 2400);

  static const Curve transform = Curves.easeInOutCubic;
  static const Curve pop = Curves.easeOutBack;
  static const Curve settle = Curves.easeOutCubic;

  static bool reduced(BuildContext context) => LumoMotion.reduced(context);

  /// Dauer oder null, je nach „Animationen reduzieren“.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// Lumos Auftritt zu einer Absicht der Lern-Engine.
  static LumoLivingState lumoFor(LumoPerformanceIntent intent) =>
      switch (intent) {
        LumoPerformanceIntent.greet => LumoLivingState.greet,
        LumoPerformanceIntent.listen => LumoLivingState.listen,
        LumoPerformanceIntent.think => LumoLivingState.think,
        LumoPerformanceIntent.explain => LumoLivingState.explain,
        LumoPerformanceIntent.demonstrate => LumoLivingState.demonstrate,
        LumoPerformanceIntent.encourage => LumoLivingState.encourage,
        LumoPerformanceIntent.approve => LumoLivingState.approve,
        LumoPerformanceIntent.idea => LumoLivingState.idea,
        LumoPerformanceIntent.celebrate => LumoLivingState.celebrate,
        LumoPerformanceIntent.pause => LumoLivingState.pause,
        LumoPerformanceIntent.wait => LumoLivingState.wait,
      };
}
