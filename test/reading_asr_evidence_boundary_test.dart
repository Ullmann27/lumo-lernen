import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reading_progress_repository.dart';
import 'package:lumo_lernen/domain/analysis/daily_recommendation_engine.dart';
import 'package:lumo_lernen/domain/analysis/lumo_analysis_domain.dart';
import 'package:lumo_lernen/domain/learning/independent_evidence.dart';

const _sessionsKey = 'lumo_reading_sessions_v1';
const _reports = ParentReportEngine();
const _plans = DailyRecommendationEngine();

ReadingAnalysisSummary _summary({
  String id = 'asr-session',
  String childId = 'reader-a',
  double score = .12,
  int completed = 0,
  int interventions = 0,
  List<String> words = const <String>[],
}) =>
    ReadingAnalysisSummary(
      id: id,
      childId: childId,
      storyTitle: 'Synthetische Leserunde',
      startedAt: DateTime.utc(2026, 11, 14, 10),
      updatedAt: DateTime.utc(2026, 11, 14, 10, 1),
      completedSentences: completed,
      totalSentences: 3,
      averageAlignmentScore: score,
      interventionCount: interventions,
      problemWords: words,
    );

Map<String, Object> _blockData(SubjectAnalysisBlock block) => <String, Object>{
      'subject': block.subject,
      'strengths': block.strengths,
      'weaknesses': block.weaknesses,
      'errorPatterns': block.errorPatterns,
      'recommendedAction': block.recommendedAction,
      'priority': block.priority,
    };

Map<String, Object> _reportData(ParentReportSummary report) => <String, Object>{
      'childName': report.childName,
      'summary': report.summary,
      'reading': _blockData(report.reading),
      'math': _blockData(report.math),
      'german': _blockData(report.german),
      'nextSteps': report.nextSteps,
    };

Map<String, Object> _planData(DailyRecommendationPlan plan) => <String, Object>{
      'childId': plan.childId,
      'headline': plan.headline,
      'lumoMessage': plan.lumoMessage,
      'parentNote': plan.parentNote,
      'blocks': plan.blocks
          .map((block) => <String, Object>{
                'title': block.title,
                'description': block.description,
                'subject': block.subject,
                'unit': block.unit,
                'minutes': block.minutes,
                'kind': block.kind.name,
                'priority': block.priority,
              })
          .toList(growable: false),
    };

void _expectNoReadingDeficit(ParentReportSummary report) {
  expect(report.reading.weaknesses, isEmpty);
  expect(report.reading.errorPatterns, isEmpty);
  expect(report.german.weaknesses, isEmpty);
  expect(report.german.errorPatterns, isEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // These are repository observations, not measured recognizer confidence.
  final observations = <String, ReadingAnalysisSummary>{
    'initial zero score': _summary(score: 0),
    'low alignment and a retained word': _summary(
      score: .12,
      interventions: 2,
      words: const <String>['Rakete'],
    ),
    'repeated mismatches and assistance': _summary(
      score: .63,
      completed: 2,
      interventions: 8,
      words: const <String>['Rakete', 'Zitrone'],
    ),
    'perfect alignment without assessed answers': _summary(
      score: 1,
      completed: 3,
    ),
  };

  for (final entry in observations.entries) {
    test('${entry.key} does not establish reading competence', () {
      final before = jsonEncode(entry.value.toJson());
      final emptyReport = _reports.buildReport(
        childName: 'Kind A',
        skills: const <String, SkillRecord>{},
        readingSummaries: const <ReadingAnalysisSummary>[],
      );
      final observedReport = _reports.buildReport(
        childName: 'Kind A',
        skills: const <String, SkillRecord>{},
        readingSummaries: <ReadingAnalysisSummary>[entry.value],
      );
      _expectNoReadingDeficit(observedReport);
      expect(_reportData(observedReport), _reportData(emptyReport));
      expect(
        jsonEncode(_reportData(observedReport)),
        isNot(contains('Lesesicherheit')),
      );

      final emptyPlan = _plans.buildPlan(
        childId: 'reader-a',
        skills: const <String, SkillRecord>{},
        readingSummaries: const <ReadingAnalysisSummary>[],
      );
      final observedPlan = _plans.buildPlan(
        childId: 'reader-a',
        skills: const <String, SkillRecord>{},
        readingSummaries: <ReadingAnalysisSummary>[entry.value],
      );
      expect(_planData(observedPlan), _planData(emptyPlan));
      expect(
        observedPlan.blocks.where(
          (block) => block.kind == RecommendationKind.tutoring,
        ),
        isEmpty,
      );
      expect(
        observedPlan.blocks.where(
          (block) => block.kind == RecommendationKind.reading,
        ),
        hasLength(1),
      );
      expect(jsonEncode(entry.value.toJson()), before);
    });
  }

  test('another profile ASR history cannot describe the current child', () {
    final otherChild = _summary(
      childId: 'reader-a',
      score: 1,
      completed: 3,
      interventions: 9,
      words: const <String>['Rakete'],
    );
    final report = _reports.buildReport(
      childName: 'Kind B',
      skills: const <String, SkillRecord>{},
      readingSummaries: <ReadingAnalysisSummary>[otherChild],
    );
    final plan = _plans.buildPlan(
      childId: 'reader-b',
      skills: const <String, SkillRecord>{},
      readingSummaries: <ReadingAnalysisSummary>[otherChild],
    );
    expect(report.childName, 'Kind B');
    expect(plan.childId, 'reader-b');
    _expectNoReadingDeficit(report);
    expect(
      _reportData(report),
      _reportData(_reports.buildReport(
        childName: 'Kind B',
        skills: const <String, SkillRecord>{},
        readingSummaries: const <ReadingAnalysisSummary>[],
      )),
    );
    expect(
      _planData(plan),
      _planData(_plans.buildPlan(
        childId: 'reader-b',
        skills: const <String, SkillRecord>{},
        readingSummaries: const <ReadingAnalysisSummary>[],
      )),
    );
  });

  test('accepted positive reading records remain positive and unchanged', () {
    final record = SkillRecord(
      skillId: 'Lesen::Saetze',
      subject: 'Lesen',
      unit: 'Sätze vorlesen',
      correct: 4,
      currentStreak: 4,
      independentEvidence: const IndependentEvidence(
        correct: 4,
        correctStreak: 4,
      ),
    );
    final before = jsonEncode(record.toJson());
    final skills = <String, SkillRecord>{record.skillId: record};
    final observations = <ReadingAnalysisSummary>[
      _summary(interventions: 8, words: const <String>['Rakete']),
    ];
    final report = _reports.buildReport(
      childName: 'Kind A',
      skills: skills,
      readingSummaries: observations,
    );
    final plan = _plans.buildPlan(
      childId: 'reader-a',
      skills: skills,
      readingSummaries: observations,
    );
    _expectNoReadingDeficit(report);
    expect(report.reading.strengths, contains(startsWith('Sätze vorlesen')));
    expect(report.german.strengths, contains(startsWith('Sätze vorlesen')));
    expect(
      plan.blocks.where((block) => block.kind == RecommendationKind.success)
          .map((block) => block.unit),
      contains('Sätze vorlesen'),
    );
    expect(record.correct, 4);
    expect(record.wrong, 0);
    expect(jsonEncode(record.toJson()), before);
  });

  test('genuinely assessed comprehension errors still guide practice', () {
    final record = SkillRecord(
      skillId: 'Lesen::Verstaendnis',
      subject: 'Lesen',
      unit: 'Leseverständnis',
      wrong: 3,
      currentMisses: 3,
      independentEvidence: const IndependentEvidence(
        wrong: 3,
        wrongStreak: 3,
      ),
    );
    final before = jsonEncode(record.toJson());
    final skills = <String, SkillRecord>{record.skillId: record};
    final report = _reports.buildReport(
      childName: 'Kind A',
      skills: skills,
      readingSummaries: <ReadingAnalysisSummary>[
        _summary(score: 1, completed: 3),
      ],
    );
    final plan = _plans.buildPlan(
      childId: 'reader-a',
      skills: skills,
      readingSummaries: const <ReadingAnalysisSummary>[],
    );
    expect(report.reading.weaknesses, contains('Leseverständnis: 3 Fehler'));
    expect(report.reading.errorPatterns, <String>['Leseverständnis']);
    expect(report.german.weaknesses, contains('Leseverständnis: 3 Fehler'));
    expect(report.german.errorPatterns, <String>['Leseverständnis']);
    expect(plan.blocks.first.kind, RecommendationKind.tutoring);
    expect(plan.blocks.first.unit, 'Leseverständnis');
    expect(jsonEncode(record.toJson()), before);
  });

  test('accompanied practice stays separate from assessed deficits', () {
    final record = SkillRecord(
      skillId: 'Lesen::Begleitet',
      subject: 'Lesen',
      unit: 'Sätze vorlesen',
      correct: 1,
      wrong: 3,
      hintCount: 4,
      independentEvidence: const IndependentEvidence(),
    );
    final before = jsonEncode(record.toJson());
    final skills = <String, SkillRecord>{record.skillId: record};
    final summaries = <ReadingAnalysisSummary>[
      _summary(interventions: 4, words: const <String>['Rakete']),
    ];
    final report = _reports.buildReport(
      childName: 'Kind A',
      skills: skills,
      readingSummaries: summaries,
    );
    final plan = _plans.buildPlan(
      childId: 'reader-a',
      skills: skills,
      readingSummaries: summaries,
    );
    _expectNoReadingDeficit(report);
    expect(
      plan.blocks.where((block) => block.kind == RecommendationKind.tutoring),
      isEmpty,
    );
    expect(jsonEncode(record.toJson()), before);
  });

  test('legacy stored summaries are read without migration or deletion',
      () async {
    final originals = <ReadingAnalysisSummary>[
      _summary(
        childId: 'reader-a',
        interventions: 5,
        words: const <String>['Rakete'],
      ),
      _summary(id: 'second', childId: 'reader-b', score: 0),
    ];
    final raw = jsonEncode(originals.map((summary) => summary.toJson()).toList());
    SharedPreferences.setMockInitialValues(<String, Object>{_sessionsKey: raw});
    final loaded = await ReadingProgressRepository().loadReadingSummaries();
    expect(loaded.map((summary) => summary.toJson()).toList(),
        originals.map((summary) => summary.toJson()).toList());

    final report = _reports.buildReport(
      childName: 'Kind B',
      skills: const <String, SkillRecord>{},
      readingSummaries: loaded,
    );
    final plan = _plans.buildPlan(
      childId: 'reader-b',
      skills: const <String, SkillRecord>{},
      readingSummaries: loaded,
    );
    _expectNoReadingDeficit(report);
    expect(plan.parentNote, isNot(contains('Lesesicherheit')));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_sessionsKey), raw);
  });

  test('retained historical words cannot override a later accepted answer',
      () async {
    final repository = ReadingProgressRepository();
    await repository.saveReadingSummary(
      _summary(interventions: 2, words: const <String>['Rakete']),
    );
    await repository.updateLatest(
      id: 'asr-session',
      childId: 'reader-a',
      storyTitle: 'Synthetische Leserunde',
      completedSentences: 1,
      totalSentences: 3,
      latestAlignmentScore: 1,
      interventionCount: 2,
      problemWords: const <String>[],
    );
    final loaded = await repository.loadReadingSummaries();
    expect(loaded.single.problemWords, <String>['Rakete']);
    final prefs = await SharedPreferences.getInstance();
    final rawBeforeReport = prefs.getString(_sessionsKey);
    final record = SkillRecord(
      skillId: 'Lesen::Saetze',
      subject: 'Lesen',
      unit: 'Sätze vorlesen',
      correct: 1,
      hintCount: 1,
      independentEvidence: const IndependentEvidence(),
    );
    final recordBeforeReport = jsonEncode(record.toJson());
    final report = _reports.buildReport(
      childName: 'Kind A',
      skills: <String, SkillRecord>{record.skillId: record},
      readingSummaries: loaded,
    );
    _expectNoReadingDeficit(report);
    expect(record.correct, 1);
    expect(record.wrong, 0);
    expect(jsonEncode(record.toJson()), recordBeforeReport);
    expect(prefs.getString(_sessionsKey), rawBeforeReport);
  });
}
