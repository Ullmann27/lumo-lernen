import 'dart:math' as math;

import '../agent/lumo_agent_domain.dart';
import '../agent/lumo_orchestrator.dart';

class Story {
  const Story({
    required this.id,
    required this.title,
    required this.grade,
    required this.level,
    required this.sentences,
    required this.targetSkills,
  });

  final String id;
  final String title;
  final int grade;
  final int level;
  final List<StorySentence> sentences;
  final List<String> targetSkills;
}

class StorySentence {
  const StorySentence({required this.id, required this.index, required this.text, required this.words});

  final String id;
  final int index;
  final String text;
  final List<WordToken> words;
}

class WordToken {
  const WordToken({required this.text, required this.syllables, this.isProblemWord = false});

  final String text;
  final List<String> syllables;
  final bool isProblemWord;
}

enum PronunciationEventType {
  omittedWord,
  substitutedWord,
  repeatedWord,
  longPause,
  lowConfidence,
  sentenceBreak,
}

class PronunciationEvent {
  const PronunciationEvent({
    required this.type,
    required this.expectedToken,
    this.spokenToken,
    this.confidence = 1,
  });

  final PronunciationEventType type;
  final String expectedToken;
  final String? spokenToken;
  final double confidence;
}

class SentenceReadingAnalysis {
  const SentenceReadingAnalysis({
    required this.expectedText,
    required this.spokenText,
    required this.alignmentScore,
    required this.correctEnough,
    required this.events,
    required this.problemWord,
  });

  final String expectedText;
  final String spokenText;
  final double alignmentScore;
  final bool correctEnough;
  final List<PronunciationEvent> events;
  final String? problemWord;
}

class ReadingSessionProgress {
  const ReadingSessionProgress({
    required this.story,
    required this.currentSentenceIndex,
    required this.attemptNumber,
    required this.problemWords,
    required this.completedSentenceIds,
    this.isComplete = false,
  });

  final Story story;
  final int currentSentenceIndex;
  final int attemptNumber;
  final List<String> problemWords;
  final List<String> completedSentenceIds;
  final bool isComplete;

  StorySentence get currentSentence {
    if (story.sentences.isEmpty) {
      return const StorySentence(id: 'empty', index: 0, text: 'Keine Geschichte geladen.', words: <WordToken>[]);
    }
    final safeIndex = currentSentenceIndex.clamp(0, story.sentences.length - 1).toInt();
    return story.sentences[safeIndex];
  }

  ReadingSessionProgress copyWith({
    int? currentSentenceIndex,
    int? attemptNumber,
    List<String>? problemWords,
    List<String>? completedSentenceIds,
    bool? isComplete,
  }) {
    return ReadingSessionProgress(
      story: story,
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      problemWords: problemWords ?? this.problemWords,
      completedSentenceIds: completedSentenceIds ?? this.completedSentenceIds,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class StoryEngine {
  const StoryEngine();

  Story pickStory({required int grade, List<String> weakWords = const <String>[]}) {
    final pool = grade <= 1 ? _gradeOneStories : _gradeTwoStories;
    final nowKey = DateTime.now().day + DateTime.now().month + DateTime.now().year;
    final story = pool[nowKey % pool.length];
    return _markProblemWords(story, weakWords);
  }

  Story _markProblemWords(Story story, List<String> weakWords) {
    if (weakWords.isEmpty) return story;
    final lower = weakWords.map(_normalize).toSet();
    return Story(
      id: story.id,
      title: story.title,
      grade: story.grade,
      level: story.level,
      targetSkills: story.targetSkills,
      sentences: story.sentences.map((sentence) {
        return StorySentence(
          id: sentence.id,
          index: sentence.index,
          text: sentence.text,
          words: sentence.words
              .map((word) => WordToken(
                    text: word.text,
                    syllables: word.syllables,
                    isProblemWord: lower.contains(_normalize(word.text)),
                  ))
              .toList(growable: false),
        );
      }).toList(growable: false),
    );
  }

  static final List<Story> _gradeOneStories = <Story>[
    Story(
      id: 'story.fox_school.1',
      title: 'Lumo geht zur Schule',
      grade: 1,
      level: 1,
      targetSkills: const <String>['reading.sentences', 'reading.syllables', 'reading.fluency'],
      sentences: _sentences(<String>[
        'Lumo steht am Morgen auf.',
        'Er nimmt seine Tasche mit.',
        'In der Schule liest er ein Wort.',
        'Das Wort ist lang, aber Lumo bleibt ruhig.',
        'Dann liest er den Satz noch einmal.',
        'Jetzt klappt es schon viel besser.',
        'Lumo freut sich und lernt weiter.',
      ]),
    ),
    Story(
      id: 'story.nature_leaf.1',
      title: 'Das Blatt am Baum',
      grade: 1,
      level: 1,
      targetSkills: const <String>['reading.sentences', 'science.nature', 'reading.fluency'],
      sentences: _sentences(<String>[
        'Mia findet ein gruenes Blatt.',
        'Das Blatt haengt an einem Baum.',
        'Der Baum braucht Licht und Wasser.',
        'Im Blatt macht die Pflanze ihre Nahrung.',
        'Lumo schaut genau hin.',
        'Natur kann man lesen und sehen.',
        'Mia sammelt nur Blätter vom Boden.',
      ]),
    ),
    Story(
      id: 'story.bee_flower.1',
      title: 'Die Biene und die Blume',
      grade: 1,
      level: 1,
      targetSkills: const <String>['reading.sentences', 'science.animals', 'reading.expression'],
      sentences: _sentences(<String>[
        'Eine Biene fliegt zur Blume.',
        'Sie sucht suessen Nektar.',
        'Dabei nimmt sie Pollen mit.',
        'Pollen hilft neuen Blumen beim Wachsen.',
        'Lumo bleibt leise stehen.',
        'Er stoert die kleine Biene nicht.',
        'So hilft die Biene der Natur.',
      ]),
    ),
  ];

  static final List<Story> _gradeTwoStories = <Story>[
    Story(
      id: 'story.forest_math.2',
      title: 'Die Beeren im Wald',
      grade: 2,
      level: 2,
      targetSkills: const <String>['reading.fluency', 'math.word_problem', 'science.nature'],
      sentences: _sentences(<String>[
        'Lumo sammelt Beeren im Wald.',
        'Zuerst findet er zehn rote Beeren.',
        'Dann kommen noch fuenf blaue Beeren dazu.',
        'Lumo zaehlt langsam und macht keinen Stress.',
        'Nicht jede Beere darf man essen.',
        'Man fragt vorher einen Erwachsenen.',
        'Am Ende teilt er die sicheren Beeren mit Mia.',
      ]),
    ),
    Story(
      id: 'story.water_cycle.2',
      title: 'Der kleine Wassertropfen',
      grade: 2,
      level: 2,
      targetSkills: const <String>['reading.fluency', 'science.weather', 'science.water_cycle'],
      sentences: _sentences(<String>[
        'Ein Tropfen liegt auf einem Blatt.',
        'Die Sonne macht ihn warm.',
        'Der Tropfen steigt als Dampf nach oben.',
        'Oben wird es kuehler.',
        'Viele Tropfen bilden eine Wolke.',
        'Spaeter faellt Regen auf die Erde.',
        'So reist Wasser immer wieder im Kreis.',
      ]),
    ),
    Story(
      id: 'story.hedgehog_winter.2',
      title: 'Der Igel im Herbst',
      grade: 2,
      level: 2,
      targetSkills: const <String>['reading.fluency', 'science.animals', 'science.seasons'],
      sentences: _sentences(<String>[
        'Im Herbst sucht der Igel Futter.',
        'Er frisst sich ein kleines Polster an.',
        'Bald wird es draussen kalt.',
        'Der Igel baut ein Nest aus Laub.',
        'Dort schlaeft er im Winter viel.',
        'Man nennt das Winterschlaf.',
        'Lumo laesst das Nest in Ruhe.',
      ]),
    ),
  ];

  static List<StorySentence> _sentences(List<String> lines) {
    return List<StorySentence>.generate(lines.length, (index) {
      final text = lines[index];
      return StorySentence(
        id: 's${index + 1}',
        index: index,
        text: text,
        words: text
            .split(RegExp(r'\s+'))
            .where((word) => word.trim().isNotEmpty)
            .map((word) => WordToken(text: word, syllables: SyllableWordColorizer.simpleSyllables(word)))
            .toList(growable: false),
      );
    });
  }
}

class SyllableWordColorizer {
  const SyllableWordColorizer();

  List<WordToken> tokenize(String text, {List<String> problemWords = const <String>[]}) {
    final problemSet = problemWords.map(_normalize).toSet();
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .map((word) => WordToken(
              text: word,
              syllables: simpleSyllables(word),
              isProblemWord: problemSet.contains(_normalize(word)),
            ))
        .toList(growable: false);
  }

  static List<String> simpleSyllables(String rawWord) {
    final cleaned = rawWord.replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß]'), '');
    if (cleaned.length <= 3) return <String>[cleaned.isEmpty ? rawWord : cleaned];
    final parts = <String>[];
    final buffer = StringBuffer();
    const vowels = 'aeiouäöüyAEIOUÄÖÜY';
    for (var i = 0; i < cleaned.length; i++) {
      buffer.write(cleaned[i]);
      final isVowel = vowels.contains(cleaned[i]);
      final nextIsConsonant = i + 1 < cleaned.length && !vowels.contains(cleaned[i + 1]);
      if (isVowel && nextIsConsonant && buffer.length >= 2 && i < cleaned.length - 2) {
        parts.add(buffer.toString());
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) parts.add(buffer.toString());
    return parts.isEmpty ? <String>[cleaned] : parts;
  }
}

class PronunciationAnalyzer {
  const PronunciationAnalyzer();

  SentenceReadingAnalysis analyze({required String expectedSentence, required String spokenTranscript, double confidence = 1}) {
    final expected = _tokens(expectedSentence);
    final spoken = _tokens(spokenTranscript);

    if (expected.isEmpty || spoken.isEmpty) {
      return SentenceReadingAnalysis(
        expectedText: expectedSentence,
        spokenText: spokenTranscript,
        alignmentScore: 0,
        correctEnough: false,
        events: const <PronunciationEvent>[],
        problemWord: null,
      );
    }

    final matchedExpected = <int>{};
    final usedSpoken = <int>{};
    final events = <PronunciationEvent>[];
    var weightedMatches = 0.0;

    for (var expectedIndex = 0; expectedIndex < expected.length; expectedIndex++) {
      final expectedToken = expected[expectedIndex];
      final match = _bestSpokenMatch(expectedToken, spoken, expectedIndex, usedSpoken);
      if (match != null && _isAcceptedMatch(expectedToken, spoken[match.index], match.score)) {
        matchedExpected.add(expectedIndex);
        usedSpoken.add(match.index);
        weightedMatches += match.score.clamp(.70, 1.0).toDouble();
      }
    }

    for (var expectedIndex = 0; expectedIndex < expected.length; expectedIndex++) {
      if (matchedExpected.contains(expectedIndex)) continue;
      final expectedToken = expected[expectedIndex];
      if (_isSoftOptionalToken(expectedToken)) continue;
      final nearby = _bestSpokenMatch(expectedToken, spoken, expectedIndex, usedSpoken, window: 3);
      events.add(PronunciationEvent(
        type: nearby == null ? PronunciationEventType.omittedWord : PronunciationEventType.substitutedWord,
        expectedToken: expectedToken,
        spokenToken: nearby == null ? null : spoken[nearby.index],
        confidence: confidence,
      ));
    }

    final score = (weightedMatches / expected.length).clamp(0.0, 1.0).toDouble();
    final sentenceStartOk = _sentenceBoundaryOk(expected.first, spoken.first);
    final sentenceEndOk = _sentenceBoundaryOk(expected.last, spoken.last) || score >= .82;
    final meaningfulEvents = events.where((event) => !_isForgivableEvent(event)).toList(growable: false);
    final problem = meaningfulEvents.isEmpty ? null : meaningfulEvents.first.expectedToken;
    final requiredScore = expected.length <= 4 ? .62 : .66;

    return SentenceReadingAnalysis(
      expectedText: expectedSentence,
      spokenText: spokenTranscript,
      alignmentScore: score,
      correctEnough: score >= requiredScore && sentenceStartOk && sentenceEndOk && meaningfulEvents.length <= math.max(1, expected.length ~/ 3),
      events: meaningfulEvents,
      problemWord: problem,
    );
  }

  _TokenMatch? _bestSpokenMatch(String expectedToken, List<String> spoken, int expectedIndex, Set<int> used, {int window = 2}) {
    _TokenMatch? best;
    final center = expectedIndex.clamp(0, spoken.length - 1).toInt();
    final start = (center - window).clamp(0, spoken.length - 1).toInt();
    final end = (center + window).clamp(0, spoken.length - 1).toInt();
    for (var i = start; i <= end; i++) {
      if (used.contains(i)) continue;
      final score = _tokenSimilarity(expectedToken, spoken[i]);
      if (best == null || score > best.score) best = _TokenMatch(index: i, score: score);
    }
    return best;
  }

  bool _isAcceptedMatch(String expected, String spoken, double similarity) {
    if (expected == spoken) return true;
    if (_isLumoVariant(expected, spoken)) return true;
    if (expected.length <= 3) return similarity >= .78;
    return similarity >= .60;
  }

  bool _sentenceBoundaryOk(String expected, String spoken) {
    if (expected == spoken) return true;
    if (_isLumoVariant(expected, spoken)) return true;
    return _tokenSimilarity(expected, spoken) >= .55;
  }

  bool _isForgivableEvent(PronunciationEvent event) {
    final spoken = event.spokenToken;
    if (spoken != null && _isLumoVariant(event.expectedToken, spoken)) return true;
    return _isSoftOptionalToken(event.expectedToken);
  }

  bool _isSoftOptionalToken(String token) {
    return token == 'der' || token == 'die' || token == 'das' || token == 'ein' || token == 'eine';
  }

  bool _isLumoVariant(String expected, String spoken) {
    if (expected != 'lumo') return false;
    const variants = <String>{'lumo', 'limo', 'loma', 'luna', 'luno', 'loom', 'lumen', 'lumos', 'humo', 'lu'};
    return variants.contains(spoken) || _tokenSimilarity(expected, spoken) >= .50;
  }

  double _tokenSimilarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final distance = _levenshtein(a, b);
    final longest = a.length > b.length ? a.length : b.length;
    return (1 - (distance / longest)).clamp(0.0, 1.0).toDouble();
  }

  int _levenshtein(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final insertCost = current[j] + 1;
        final deleteCost = previous[j + 1] + 1;
        final replaceCost = previous[j] + (a[i] == b[j] ? 0 : 1);
        current[j + 1] = math.min(math.min(insertCost, deleteCost), replaceCost);
      }
      for (var j = 0; j < previous.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }

  List<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll('ü', 'ue')
        .replaceAll('ö', 'oe')
        .replaceAll('ä', 'ae')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }
}

class _TokenMatch {
  const _TokenMatch({required this.index, required this.score});
  final int index;
  final double score;
}

class ReadingMonitor {
  ReadingMonitor({LumoOrchestrator? orchestrator, PronunciationAnalyzer? analyzer})
      : orchestrator = orchestrator ?? LumoOrchestrator(),
        analyzer = analyzer ?? const PronunciationAnalyzer();

  final LumoOrchestrator orchestrator;
  final PronunciationAnalyzer analyzer;

  ReadingStepResult processSentence({
    required String childId,
    required ReadingSessionProgress progress,
    required String transcript,
    double confidence = 1,
  }) {
    final sentence = progress.currentSentence;
    final analysis = analyzer.analyze(expectedSentence: sentence.text, spokenTranscript: transcript, confidence: confidence);
    final shouldStoreProblem = !analysis.correctEnough && progress.attemptNumber >= 2 && analysis.problemWord != null;
    final safeProblemWord = shouldStoreProblem ? analysis.problemWord : null;
    final action = orchestrator.handle(AgentEvent(
      type: analysis.correctEnough ? AgentEventType.readingSentenceHeard : AgentEventType.readingErrorDetected,
      childId: childId,
      occurredAt: DateTime.now(),
      correct: analysis.correctEnough,
      payload: <String, Object?>{
        'sentence': sentence.text,
        'word': safeProblemWord,
        'attemptNumber': progress.attemptNumber,
        'alignmentScore': analysis.alignmentScore,
      },
    ));

    final completed = <String>{...progress.completedSentenceIds};
    if (analysis.correctEnough && sentence.id != 'empty') completed.add(sentence.id);

    final isNowComplete = progress.story.sentences.isEmpty || completed.length >= progress.story.sentences.length;
    final nextIndex = isNowComplete
        ? progress.currentSentenceIndex
        : (progress.currentSentenceIndex + 1).clamp(0, progress.story.sentences.length - 1).toInt();

    final nextProgress = analysis.correctEnough
        ? progress.copyWith(
            currentSentenceIndex: nextIndex,
            attemptNumber: 1,
            completedSentenceIds: completed.toList(growable: false),
            isComplete: isNowComplete,
          )
        : progress.copyWith(
            attemptNumber: (progress.attemptNumber + 1).clamp(1, 3).toInt(),
            problemWords: safeProblemWord == null ? progress.problemWords : <String>{...progress.problemWords, safeProblemWord}.toList(growable: false),
          );

    return ReadingStepResult(analysis: analysis, decision: action, nextProgress: nextProgress);
  }
}

class ReadingStepResult {
  const ReadingStepResult({required this.analysis, required this.decision, required this.nextProgress});

  final SentenceReadingAnalysis analysis;
  final AgentDecision decision;
  final ReadingSessionProgress nextProgress;
}

String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');
