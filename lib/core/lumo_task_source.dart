import 'school_exercise_generator.dart';

/// Interne Herkunft einer Lernaufgabe.
///
/// Diese Ableitung ist bewusst stabil und rueckwaertskompatibel:
/// - KI-Aufgaben werden aktuell mit id-Praefix `ai_` erzeugt.
/// - sichere Fallback-Aufgaben werden mit id-Praefix `fallback_`
///   oder missionTag `fallback` erzeugt.
/// - alle anderen Aufgaben stammen aus dem lokalen Generator.
///
/// Vorteil: Wir muessen das zentrale LumoTask-Modell nicht sofort
/// breit refactoren, koennen aber im Elternbereich/Debugging sauber
/// erklaeren, woher eine Aufgabe kam.
enum LumoTaskSource {
  localGenerator,
  aiCache,
  safeFallback;

  String get key {
    switch (this) {
      case LumoTaskSource.localGenerator:
        return 'local_generator';
      case LumoTaskSource.aiCache:
        return 'ai_cache';
      case LumoTaskSource.safeFallback:
        return 'safe_fallback';
    }
  }

  String get label {
    switch (this) {
      case LumoTaskSource.localGenerator:
        return 'Lokaler Generator';
      case LumoTaskSource.aiCache:
        return 'Lumo-KI Vorrat';
      case LumoTaskSource.safeFallback:
        return 'Sicherer Fallback';
    }
  }
}

extension LumoTaskSourceX on LumoTask {
  LumoTaskSource get source {
    final normalizedId = id.trim().toLowerCase();
    final normalizedTag = missionTag.trim().toLowerCase();

    if (normalizedId.startsWith('ai_') || normalizedTag == 'ai_cache') {
      return LumoTaskSource.aiCache;
    }
    if (normalizedId.startsWith('fallback_') || normalizedTag == 'fallback') {
      return LumoTaskSource.safeFallback;
    }
    return LumoTaskSource.localGenerator;
  }

  String get sourceKey => source.key;

  String get sourceLabel => source.label;
}
