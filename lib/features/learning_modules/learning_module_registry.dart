// ════════════════════════════════════════════════════════════════════════
// LEARNING MODULE REGISTRY — Mapping Topic-ID -> echtes Lern-Modul
// ════════════════════════════════════════════════════════════════════════
// Heinz Feedback: 'Alle Optionen in Lernen sind nur Chats - keine aktiven
// Lern-Module ausser Buchstaben schreiben.'
//
// Loesung: Registry mit Topic-IDs die echte interaktive Module haben.
// Beim Tap auf ein Topic in der Akademie:
//   1) Pruefe ob Topic-ID hier registriert ist
//   2) Wenn ja -> oeffne echtes Modul
//   3) Wenn nein -> oeffne ChatGPT-Chat (Fallback)
//
// Zukunft: Hier werden alle 26+ Topics als echte Module landen.
// Aktuell aktiv: m1_plus10 (Plus bis 10)
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import 'artikel_lernen/artikel_lernen_screen.dart';
import 'minus_bis_10/minus_bis_10_screen.dart';
import 'plus_bis_10/plus_bis_10_screen.dart';
import 'uhr_lernen/uhr_lernen_screen.dart';

class LearningModuleRegistry {
  LearningModuleRegistry._();

  /// Liefert einen Builder fuer ein echtes Lern-Modul wenn Topic-ID
  /// registriert ist. Sonst null (-> Fallback auf ChatGPT-Chat).
  static Widget? builderFor(String topicId, LumoAppState appState) {
    switch (topicId) {
      case 'm1_plus10':
        return PlusBis10Screen(appState: appState);
      case 'm1_minus10':
        return MinusBis10Screen(appState: appState);
      case 'm2_uhr':
        return UhrLernenScreen(appState: appState);
      case 'd2_artikel':
        return ArtikelLernenScreen(appState: appState);
      // TODO Phase 4+ weitere Module:
      // case 'm1_zahlen10': return Zahlen10Screen(appState: appState);
      // case 'm2_einmaleins': return EinmaleinsScreen(appState: appState);
      // case 'm2_geld': return GeldLernenScreen(appState: appState);
      // case 'm4_bruch': return BruchrechnenScreen(appState: appState);
      // case 'd4_grammatik': return GrammatikFaelleScreen(appState: appState);
      // case 's1_farben': return FarbenLernenScreen(appState: appState);
      // case 's1_tiere': return TiereLernenScreen(appState: appState);
      default:
        return null;
    }
  }

  /// Liste aller Topic-IDs die ein echtes Modul haben.
  /// Wird in der Akademie genutzt um ein Badge "🎮 Übung" anzuzeigen
  /// (statt nur Chat).
  static const Set<String> registeredTopicIds = {
    'm1_plus10',
    'm1_minus10',
    'm2_uhr',
    'd2_artikel',
  };

  static bool hasModule(String topicId) =>
      registeredTopicIds.contains(topicId);
}
