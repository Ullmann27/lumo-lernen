import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/analysis/lumo_analysis_domain.dart';

class ReadingProgressRepository {
  static const _readingSessionsKey = 'lumo_reading_sessions_v1';

  Future<List<ReadingAnalysisSummary>> loadReadingSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readingSessionsKey);
    if (raw == null || raw.isEmpty) return const <ReadingAnalysisSummary>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ReadingAnalysisSummary.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <ReadingAnalysisSummary>[];
    }
  }

  Future<void> saveReadingSummary(ReadingAnalysisSummary summary) async {
    final current = await loadReadingSummaries();
    final updated = <ReadingAnalysisSummary>[
      summary,
      ...current.where((item) => item.id != summary.id),
    ];
    await _save(updated.take(40).toList(growable: false));
  }

  Future<void> updateLatest({
    required String id,
    required String childId,
    required String storyTitle,
    required int completedSentences,
    required int totalSentences,
    required double latestAlignmentScore,
    required int interventionCount,
    required List<String> problemWords,
  }) async {
    final current = await loadReadingSummaries();
    final existing = current.where((item) => item.id == id).firstOrNull;
    final previousCompleted = existing?.completedSentences ?? 0;
    final previousScore = existing?.averageAlignmentScore ?? 0;
    final totalCompletedForAverage = (previousCompleted + 1).clamp(1, 9999).toInt();
    final average = previousCompleted == 0
        ? latestAlignmentScore
        : ((previousScore * previousCompleted) + latestAlignmentScore) / totalCompletedForAverage;
    final now = DateTime.now();
    final mergedWords = <String>{...?existing?.problemWords, ...problemWords}.toList(growable: false);
    final summary = ReadingAnalysisSummary(
      id: id,
      childId: childId,
      storyTitle: storyTitle,
      startedAt: existing?.startedAt ?? now,
      updatedAt: now,
      completedSentences: completedSentences,
      totalSentences: totalSentences,
      averageAlignmentScore: average.clamp(0.0, 1.0).toDouble(),
      interventionCount: interventionCount,
      problemWords: mergedWords,
    );
    await saveReadingSummary(summary);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readingSessionsKey);
  }

  Future<void> _save(List<ReadingAnalysisSummary> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _readingSessionsKey,
      jsonEncode(items.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
