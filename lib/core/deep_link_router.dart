// Deep-Link-Router fuer das Schema "lumolernen://".
//
// Die separate Godot-3D-Hub-App (dev.ullmann.lumo3d) startet diese App via
// Android-Intent mit einer URI wie `lumolernen://open?section=learn`. Auf
// Cold-Start landet diese URI in WidgetsBinding.instance.platformDispatcher
// .defaultRouteName. Wir parsen sie hier ohne neues Plugin und mappen den
// section-Parameter auf eine LumoSection.
//
// Warm-Start / running-process Deep-Links sind nicht implementiert
// (brauechten ein natives Plugin wie app_links). Da der typische Flow
// vom Godot-Hub aus ohnehin cold-startet, reicht das hier.

import '../app/app_state.dart';

class DeepLinkRouter {
  const DeepLinkRouter._();

  /// Liefert null wenn die Route nicht zu unserem Schema passt oder kein
  /// section-Parameter angegeben war.
  static LumoSection? parseInitialSection(String? routeName) {
    if (routeName == null || routeName.isEmpty || routeName == '/') {
      return null;
    }
    final uri = Uri.tryParse(routeName);
    if (uri == null) return null;
    if (uri.scheme != 'lumolernen') return null;
    final section = uri.queryParameters['section'];
    if (section == null || section.isEmpty) return null;
    return _mapSection(section);
  }

  /// Übersetzt einen vom Godot-Hub gesendeten section-Key auf eine echte
  /// LumoSection. Unbekannte Keys ergeben null (App startet normal am Home).
  ///
  /// Vertraglich (zwischen Godot FlutterBridge und uns):
  ///   "learn"   -> Lernen-Bereich (Fach-Auswahl)
  ///   "cards"   -> Spiele (in denen Lumo Cards lebt)
  ///   "reading" -> Lese-Bereich
  ///   "" / unbekannt -> Home (null returnen)
  static LumoSection? _mapSection(String key) {
    switch (key.toLowerCase()) {
      case 'learn':
      case 'lernen':
        return LumoSection.learn;
      case 'cards':
      case 'spiele':
      case 'games':
        return LumoSection.games;
      case 'reading':
      case 'lesen':
        return LumoSection.reading;
      case 'tests':
        return LumoSection.tests;
      case 'home':
        return LumoSection.home;
      default:
        return null;
    }
  }
}
