import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/school_exercise_generator.dart';

/// Öffnet aus dem Eltern- oder Lehrkräftebereich genau das Lernmodul einer
/// Empfehlung (Fach + Thema) für das aktuell aktive Kinderprofil.
///
/// Ein Thema, das es für die Schulstufe des Profils im Übungsbereich nicht
/// gibt, wird nie stillschweigend durch ein anderes ersetzt: dann bietet die
/// Oberfläche keinen Start an ([canStart] ist false).
class LearningRouteLauncher {
  const LearningRouteLauncher._();

  static bool canStart(LumoAppState app, String subject, String unit) {
    if (subject.trim().isEmpty || unit.trim().isEmpty || unit == 'Alle') {
      return false;
    }
    return Curriculum.unitsForGrade(subject, app.state.grade).contains(unit);
  }

  /// Setzt Fach, Thema und Übungsart und kehrt zur App-Oberfläche zurück,
  /// die dann den Übungsbereich zeigt. [guided]: Nachhilfe-Stunde mit Lumo
  /// statt kurzer Übungsrunde.
  static bool start(
    BuildContext context,
    LumoAppState app, {
    required String subject,
    required String unit,
    bool guided = false,
  }) {
    if (!canStart(app, subject, unit)) return false;
    app.update(app.state.copyWith(
      section: LumoSection.exercises,
      subject: subject,
      unit: unit,
      mood: LumoMood.point,
      sessionKind:
          guided ? LumoSessionKind.tutoring : LumoSessionKind.quickPractice,
      lumoMessage: guided
          ? 'Nachhilfe: Wir schauen uns $unit gemeinsam an, dann probierst du.'
          : 'Wir üben $unit. Ich helfe dir Schritt für Schritt.',
    ));
    Navigator.of(context).popUntil((route) => route.isFirst);
    return true;
  }
}
