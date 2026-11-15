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
//     validiert (Schema, eindeutige Optionen und geprüfte Antwortregel).
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
import '../../../core/math_task_templates.dart';
import '../../../core/choice_question_quality.dart';
import '../../../core/school_exercise_generator.dart';
import '../../../core/task_quality_guard.dart';
import 'lumo_cards_models.dart';

class LearningQuestionRepository {
  LearningQuestionRepository._();

  static final LearningQuestionRepository instance =
      LearningQuestionRepository._();

  List<LearningQuestion> _all = const [];
  final Map<LearningQuestion, int> _gradeByQuestion = {};
  bool _initialized = false;
  Future<void>? _initializing;

  /// Anzahl geladener Fragen (nach erfolgreichem init).
  int get count => _all.length;

  /// Wahr nachdem init() erfolgreich Daten geladen hat (auch wenn nur 1
  /// Bundle verfuegbar war). Vor init oder bei totalem Lade-Fehler: false.
  bool get isReady => _initialized && _all.isNotEmpty;

  /// Idempotenter Loader. Liest die 4 Bundles aus
  /// LumoAssetPaths.allQuestionBundles, validiert jedes Item, filtert
  /// kaputte raus. Try/catch um jeden Bundle-Load - wenn einer fehlt
  /// bricht der Rest nicht.
  Future<void> init() {
    if (_initialized) return Future.value();
    return _initializing ??= _load();
  }

  Future<void> _load() async {
    final loaded = <LearningQuestion>[];
    for (final path in LumoAssetPaths.allQuestionBundles) {
      try {
        final raw = await rootBundle.loadString(path);
        final parsed = jsonDecode(raw);
        if (parsed is! List) continue;
        for (final item in parsed) {
          if (item is! Map) continue;
          final q = _parseOne(Map<String, dynamic>.from(item));
          if (q != null) {
            loaded.add(q);
            _gradeByQuestion[q] = path.contains('grade2_') ? 2 : 1;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LearningQuestionRepository: $path - $e');
        }
      }
    }
    _all = List<LearningQuestion>.unmodifiable(loaded);
    _initialized = true;
    _initializing = null;
  }

  /// Synchroner Picker. Bei isReady=false (nicht init, oder leerer
  /// Bundle-Stand) kommt die Fallback-Frage.
  LearningQuestion random([Random? rng]) {
    if (_all.isEmpty) return _fallback;
    final r = rng ?? Random();
    return _all[r.nextInt(_all.length)];
  }

  /// A Denkpause belongs to the child's current class. Grades 3/4 use
  /// the same checked local arithmetic templates as the learning app.
  LearningQuestion randomForGrade(int grade, [Random? rng]) {
    final r = rng ?? Random();
    final safeGrade = grade.clamp(1, 4);
    LearningQuestion question;
    if (safeGrade >= 3) {
      final units = safeGrade == 3
          ? [
              'Einmaleins',
              'Plus bis 100',
              'Minus bis 100',
              'Division einstellig'
            ]
          : [
              'Schriftliche Multiplikation',
              'Schriftliche Division',
              'Plus bis 10000',
              'Minus bis 10000',
              'Vergleichen'
            ];
      final unit = units[r.nextInt(units.length)];
      question = _checkedMath(safeGrade, unit, r);
    } else {
      final pool =
          _all.where((q) => (_gradeByQuestion[q] ?? 1) == safeGrade).toList();
      question = pool.isEmpty ? _fallback : pool[r.nextInt(pool.length)];
    }
    // Historical bundles place almost every correct answer first. Shuffle
    // without changing the right answer so guessing position is no shortcut.
    final answer = question.options[question.correctIndex];
    final options = List<String>.of(question.options)..shuffle(r);
    return LearningQuestion(
        prompt: question.prompt,
        options: List<String>.unmodifiable(options),
        correctIndex: options.indexOf(answer),
        hint: question.hint);
  }

  /// Lade-/Filter-Logik fuer ein einzelnes JSON-Item. Gibt null zurueck
  /// wenn das Item nicht dem erwarteten Schema entspricht.
  static LearningQuestion? _parseOne(Map<String, dynamic> m) {
    try {
      final prompt = (m['prompt'] as String?)?.trim();
      if (prompt == null || prompt.isEmpty) return null;
      final optsRaw = m['options'];
      if (optsRaw is! List || optsRaw.length != 4) return null;
      if (optsRaw.any((option) => option is! String)) return null;
      final options = List<String>.unmodifiable(
          optsRaw.cast<String>().map((option) => option.trim()));
      final correctIdxRaw = m['correctIndex'];
      if (correctIdxRaw is! int) return null;
      if (correctIdxRaw < 0 || correctIdxRaw > 3) return null;
      final hint = (m['hint'] as String?)?.trim();
      final question = LearningQuestion(
        prompt: prompt,
        options: options,
        correctIndex: correctIdxRaw,
        hint: (hint == null || hint.isEmpty) ? null : hint,
      );
      return acceptsLearningQuestion(question) ? question : null;
    } catch (_) {
      return null;
    }
  }

  /// Public gate for consumers. The supplied answer index is checked, never
  /// repaired or silently replaced with a different question's answer.
  static bool acceptsLearningQuestion(LearningQuestion question) =>
      problems(question).isEmpty;

  static List<String> problems(LearningQuestion question) =>
      ChoiceQuestionQuality.problems(
          prompt: question.prompt,
          options: question.options,
          correctIndex: question.correctIndex);

  static LearningQuestion _checkedMath(int grade, String unit, Random rng) {
    for (var attempt = 0; attempt < 32; attempt++) {
      final task = MathTaskTemplates.generate(
          grade: grade, unit: unit, seed: rng.nextInt(1 << 30));
      final candidate = LumoTask(
          id: 'cards-quality-check',
          grade: grade,
          subject: 'Mathematik',
          unit: task.unit,
          prompt: task.prompt,
          choices: task.choices,
          answer: task.answer,
          explanation: task.explanation,
          visual: task.visual,
          difficulty: task.difficulty);
      if (!const TaskQualityGuard().validate(candidate)) continue;
      final question = LearningQuestion(
          prompt: task.prompt,
          options: List<String>.unmodifiable(task.choices),
          correctIndex: task.choices.indexOf(task.answer),
          hint: task.explanation);
      if (acceptsLearningQuestion(question)) return question;
    }
    throw StateError('No checked card question for grade $grade / $unit');
  }

  @visibleForTesting
  static LearningQuestion? debugParseQuestion(Map<String, dynamic> item) =>
      _parseOne(item);

  /// NUR fuer Tests: setzt das Repository auf einen bekannten Stand
  /// ohne Bundle-Loads.
  @visibleForTesting
  void debugSetQuestions(List<LearningQuestion> items) {
    for (final question in items) {
      final issues = ChoiceQuestionQuality.problems(
          prompt: question.prompt,
          options: question.options,
          correctIndex: question.correctIndex,
          requireReviewedPrompt: false);
      if (issues.isNotEmpty) throw ArgumentError(issues.join(', '));
    }
    _all = List<LearningQuestion>.unmodifiable(items.map((question) =>
        LearningQuestion(
            prompt: question.prompt,
            options: List<String>.unmodifiable(question.options),
            correctIndex: question.correctIndex,
            hint: question.hint)));
    _gradeByQuestion.clear();
    _initialized = true;
  }

  /// NUR fuer Tests: setzt das Repository auf den uninitialisierten
  /// Zustand zurueck.
  @visibleForTesting
  void debugReset() {
    _all = const [];
    _gradeByQuestion.clear();
    _initialized = false;
    _initializing = null;
  }

  /// Letzte Verteidigungslinie wenn KEIN Bundle ladbar ist. Garantiert
  /// dass die Denkpause-Karte trotzdem eine Frage zeigt statt zu crashen.
  static LearningQuestion get _fallback {
    const question = LearningQuestion(
      prompt: 'Wie viel ist 1 + 1?',
      options: ['1', '2', '3', '4'],
      correctIndex: 1,
      hint: '1 plus 1 ist 2.',
    );
    if (!acceptsLearningQuestion(question)) {
      throw StateError('Invalid built-in card question');
    }
    return question;
  }
}
