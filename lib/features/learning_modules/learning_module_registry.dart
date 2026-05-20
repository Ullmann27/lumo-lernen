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
import 'bruchrechnen/bruchrechnen_screen.dart';
import 'einmaleins/einmaleins_screen.dart';
import 'formen/formen_screen.dart';
import 'minus_bis_10/minus_bis_10_screen.dart';
import 'plus_bis_10/plus_bis_10_screen.dart';
import 'tiere/tiere_screen.dart';
import 'uhr_lernen/uhr_lernen_screen.dart';
import 'wort_diktat/wort_diktat_screen.dart';
import 'zahlen_bis_10/zahlen_bis_10_screen.dart';

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
      case 'm1_zahlen10':
        return ZahlenBis10Screen(appState: appState);
      case 'm1_formen':
        return FormenScreen(appState: appState);
      case 's1_tiere':
        return TiereScreen(appState: appState);
      case 'm2_uhr':
        return UhrLernenScreen(appState: appState);
      case 'd2_artikel':
        return ArtikelLernenScreen(appState: appState);
      case 'd1_woerter':
        return WortDiktatScreen(appState: appState);
      case 'm2_einmaleins':
        return EinmaleinsScreen(appState: appState, fullRange: false);
      case 'm3_einmaleins_voll':
        return EinmaleinsScreen(appState: appState, fullRange: true);
      case 'm4_bruch':
        return BruchrechnenScreen(appState: appState);
      default:
        return null;
    }
  }

  static const Set<String> registeredTopicIds = {
    'm1_plus10',
    'm1_minus10',
    'm1_zahlen10',
    'm1_formen',
    's1_tiere',
    'm2_uhr',
    'm2_einmaleins',
    'm3_einmaleins_voll',
    'm4_bruch',
    'd1_woerter',
    'd2_artikel',
  };

  static bool hasModule(String topicId) =>
      registeredTopicIds.contains(topicId);
}
