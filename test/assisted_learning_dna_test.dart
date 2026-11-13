import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/domain/learning/independent_evidence.dart';
import 'package:lumo_lernen/domain/learning/learning_dna_engine.dart';
import 'package:lumo_lernen/features/parents/widgets/lumo_insight_heatmap.dart';

const _engine = LearningDnaEngine();
const _captureKey = ValueKey('assisted-dna-render');

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.ci-results/assisted-learning/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

SkillRecord _mixed({required bool independentCorrect}) {
  final record = SkillRecord(
      skillId: 'math',
      subject: 'Mathematik',
      unit: 'Plus',
      correct: independentCorrect ? 10 : 30,
      wrong: independentCorrect ? 30 : 10,
      hintCount: 30,
      independentEvidence: IndependentEvidence(
          correct: independentCorrect ? 10 : 0,
          wrong: independentCorrect ? 0 : 10));
  return SkillRecord.fromJson(jsonDecode(jsonEncode(record.toJson())));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  test('guided history remains visible without DNA strength or weakness',
      () async {
    final repository = ProgressRepository(studentId: 'dna-guided');
    final profile = LearningProfileEngine(repository: repository);
    for (var i = 0; i < 10; i++) {
      await profile.recordAnswer(
          subject: 'Mathematik', unit: 'Plus', isCorrect: true, hintUsed: true);
      await profile.recordAnswer(
          subject: 'Deutsch',
          unit: 'Artikel',
          isCorrect: false,
          hintUsed: true);
    }
    final dna = _engine.compute(
        state: LumoSessionState(), skills: await repository.loadSkills());
    expect(dna.totalCorrect, 10);
    expect(dna.totalIncorrect, 10);
    expect(dna.strengths, isEmpty);
    expect(dna.weaknesses, isEmpty);
    expect(dna.skillObservations, hasLength(2));
    for (final entry in dna.skillObservations) {
      expect(entry.answerCount, 10);
      expect(entry.independentEvidence.attempts, 0);
      expect(entry.hasEnoughAnswersForGrouping, isFalse);
      expect(entry.sampleNote, contains('Mit Hilfe oder nicht zuordenbar'));
    }
    expect(dna.nextRecommendation!.suggestedUnit, isNull);
    expect(
        dna.parentAnalysisPrompt(grade: 2), contains('noch keine Einordnung'));
  });

  test(
      'guided successes cannot disguise independent difficulties after restore',
      () {
    final dna = _engine.compute(
        state: LumoSessionState(),
        skills: {'math': _mixed(independentCorrect: false)});
    final entry = dna.skillObservations.single;
    expect(entry.score, .75);
    expect(entry.answerSummary, 'Gesamt: 75% · 30 von 40 Antworten richtig');
    expect(entry.assessmentScore, 0);
    expect(entry.sampleNote, contains('0 von 10 selbstständigen Antworten'));
    expect(dna.strengths, isEmpty);
    expect(dna.weaknesses.single, same(entry));
    expect(dna.nextRecommendation!.priority, 'hoch');
    expect(dna.nextRecommendation!.reason, contains('0 von 10'));
    expect(dna.parentAnalysisPrompt(grade: 2), contains(entry.sampleNote));
    expect(dna.totalCorrect, 30);
    expect(dna.totalIncorrect, 10);
  });

  test('guided mistakes cannot hide later independent capability after restore',
      () {
    final dna = _engine.compute(
        state: LumoSessionState(),
        skills: {'math': _mixed(independentCorrect: true)});
    final entry = dna.skillObservations.single;
    expect(entry.score, .25);
    expect(entry.assessmentScore, 1);
    expect(dna.strengths.single, same(entry));
    expect(dna.weaknesses, isEmpty);
    expect(entry.sampleNote, contains('10 von 10 selbstständigen Antworten'));
    expect(dna.totalCorrect, 10);
    expect(dna.totalIncorrect, 30);
  });

  test('mixed legacy counts cannot be attributed to independent evidence', () {
    final raw = SkillRecord(
            skillId: 'legacy',
            subject: 'Mathematik',
            unit: 'Plus',
            correct: 15,
            wrong: 5,
            hintCount: 1)
        .toJson()
      ..remove('independentEvidence');
    final dna = _engine.compute(
        state: LumoSessionState(),
        skills: {'legacy': SkillRecord.fromJson(jsonDecode(jsonEncode(raw)))});
    expect(dna.totalCorrect + dna.totalIncorrect, 20);
    expect(dna.strengths, isEmpty);
    expect(dna.weaknesses, isEmpty);
    expect(dna.skillObservations.single.sampleNote,
        contains('Mit Hilfe oder nicht zuordenbar'));
  });

  test('a mixed small sample names the independent denominator', () {
    final record = SkillRecord(
        skillId: 'mixed',
        subject: 'Mathematik',
        unit: 'Plus',
        correct: 20,
        wrong: 1,
        hintCount: 20,
        independentEvidence: const IndependentEvidence(wrong: 1));
    final entry = _engine
        .compute(state: LumoSessionState(), skills: {'mixed': record})
        .skillObservations
        .single;
    expect(entry.answerCount, 21);
    expect(entry.isSmallSample, isTrue);
    expect(entry.sampleNote, contains('(1 selbstständige Antwort)'));
    expect(entry.isStrength, isFalse);
    expect(entry.isWeakness, isFalse);
  });

  testWidgets('heatmap color follows independent evidence, not raw practice',
      (tester) async {
    for (final correct in [true, false]) {
      final dna = _engine.compute(
          state: LumoSessionState(),
          skills: {'math': _mixed(independentCorrect: correct)});
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: RepaintBoundary(
                  key: _captureKey,
                  child: LumoInsightHeatmap(entries: dna.skillObservations)))));
      final cell = tester.widget<GestureDetector>(find.ancestor(
          of: find.text(dna.skillObservations.single.answerSummary),
          matching: find.byType(GestureDetector)));
      final decoration =
          (cell.child! as Container).decoration! as BoxDecoration;
      expect(decoration.color,
          correct ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5));
      expect(
          find.text(dna.skillObservations.single.sampleNote), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(
          tester, correct ? 'independent-strength' : 'independent-review');
    }
  });
}
