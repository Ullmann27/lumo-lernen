// ════════════════════════════════════════════════════════════════════════
// LEARNING QUESTION REPOSITORY — laedt 200 Fragen aus assets/learning_questions/
// ════════════════════════════════════════════════════════════════════════
// PR F aus dem Asset-Integrations-Plan (Heinz 2026-05-23).
//
// Loest die hardcoded 12-Fragen-Liste in lumo_cards_rules.dart ab.
//
// Architektur:
//   - Singleton mit asynchroner init() - laedt alle 4 JSON-Bundles
//     einmalig in den Speicher.
//   - random(rng) gibt synchron eine Frage zurueck. Wenn init() noch
//     nicht gelaufen ist ODER alle Bundles kaputt sind, kommt eine
//     hardcoded Fallback-Frage. Kein Crash, kein App-Hang.
//   - Robust gegen kaputte JSON-Eintraege - jedes Item wird einzeln
//     validiert (prompt da, options genau 4, correctIndex 0-3).
//
// Verwendung:
//   await LearningQuestionRepository.instance.init();  // in main()
//   final q = LearningQuestionRepository.instance.random();
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/lumo_asset_paths.dart';
import 'lumo_cards_models.dart';

class LearningQuestionRepository {
  LearningQuestionRepository._();

  static final LearningQuestionRepository instance =
      LearningQuestionRepository._();

  List<LearningQuestion> _all = const [];
  bool _initialized = false;

  /// Anzahl geladener Fragen (nach erfolgreichem init).
  int get count => _all.length;

  /// Wahr nachdem init() erfolgreich Daten geladen hat (auch wenn nur 1
  /// Bundle verfuegbar war). Vor init oder bei totalem Lade-Fehler: false.
  bool get isReady => _initialized && _all.isNotEmpty;

  /// Idempotenter Loader. Liest die 4 Bundles aus
  /// LumoAssetPaths.allQuestionBundles, validiert jedes Item, filtert
  /// kaputte raus. Try/catch um jeden Bundle-Load - wenn einer fehlt
  /// bricht der Rest nicht.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final loaded = <LearningQuestion>[];
    for (final path in LumoAssetPaths.allQuestionBundles) {
      try {
        final raw = await rootBundle.loadString(path);
        final parsed = jsonDecode(raw);
        if (parsed is! List) continue;
        for (final item in parsed) {
          if (item is! Map) continue;
          final q = _parseOne(Map<String, dynamic>.from(item));
          if (q != null) loaded.add(q);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LearningQuestionRepository: $path - $e');
        }
      }
    }
    _all = List<LearningQuestion>.unmodifiable(loaded);
  }

  /// Synchroner Picker. Bei isReady=false (nicht init, oder leerer
  /// Bundle-Stand) kommt die Fallback-Frage.
  LearningQuestion random([Random? rng]) {
    if (_all.isEmpty) return _fallback;
    final r = rng ?? Random();
    return _all[r.nextInt(_all.length)];
  }

  /// Lade-/Filter-Logik fuer ein einzelnes JSON-Item. Gibt null zurueck
  /// wenn das Item nicht dem erwarteten Schema entspricht.
  static LearningQuestion? _parseOne(Map<String, dynamic> m) {
    try {
      final prompt = (m['prompt'] as String?)?.trim();
      if (prompt == null || prompt.isEmpty) return null;
      final optsRaw = m['options'];
      if (optsRaw is! List || optsRaw.length != 4) return null;
      final options = optsRaw.map((e) => e.toString()).toList(growable: false);
      final correctIdxRaw = m['correctIndex'];
      if (correctIdxRaw is! int) return null;
      if (correctIdxRaw < 0 || correctIdxRaw > 3) return null;
      final hint = (m['hint'] as String?)?.trim();
      return LearningQuestion(
        prompt: prompt,
        options: options,
        correctIndex: correctIdxRaw,
        hint: (hint == null || hint.isEmpty) ? null : hint,
      );
    } catch (_) {
      return null;
    }
  }

  /// NUR fuer Tests: setzt das Repository auf einen bekannten Stand
  /// ohne Bundle-Loads.
  @visibleForTesting
  void debugSetQuestions(List<LearningQuestion> items) {
    _all = List<LearningQuestion>.unmodifiable(items);
    _initialized = true;
  }

  /// NUR fuer Tests: setzt das Repository auf den uninitialisierten
  /// Zustand zurueck.
  @visibleForTesting
  void debugReset() {
    _all = const [];
    _initialized = false;
  }

  /// Letzte Verteidigungslinie wenn KEIN Bundle ladbar ist. Garantiert
  /// dass die Denkpause-Karte trotzdem eine Frage zeigt statt zu crashen.
  static const LearningQuestion _fallback = LearningQuestion(
    prompt: 'Wie viel ist 1 + 1?',
    options: ['1', '2', '3', '4'],
    correctIndex: 1,
    hint: '1 plus 1 ist 2.',
  );
}
