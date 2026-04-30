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
    final hasNewRealReadingScore = completedSentences > previousCompleted || latestAlignmentScore > 0;

    double average = previousScore;
    if (hasNewRealReadingScore) {
      if (previousCompleted <= 0) {
        average = latestAlignmentScore;
      } else {
        average = ((previousScore * previousCompleted) + latestAlignmentScore) / (previousCompleted + 1);
      }
    }

    final mergedWordSet = <String>{};
    for (final word in existing?.problemWords ?? const <String>[]) {
      final clean = word.trim();
      if (clean.isNotEmpty) mergedWordSet.add(clean);
    }
    for (final word in problemWords) {
      final clean = word.trim();
      if (clean.isNotEmpty) mergedWordSet.add(clean);
    }

    final now = DateTime.now();
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
      problemWords: mergedWordSet.toList(growable: false),
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
