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
  });

  final Story story;
  final int currentSentenceIndex;
  final int attemptNumber;
  final List<String> problemWords;
  final List<String> completedSentenceIds;

  StorySentence get currentSentence => story.sentences[currentSentenceIndex.clamp(0, story.sentences.length - 1)];

  ReadingSessionProgress copyWith({
    int? currentSentenceIndex,
    int? attemptNumber,
    List<String>? problemWords,
    List<String>? completedSentenceIds,
  }) {
    return ReadingSessionProgress(
      story: story,
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      problemWords: problemWords ?? this.problemWords,
      completedSentenceIds: completedSentenceIds ?? this.completedSentenceIds,
    );
  }
}

class StoryEngine {
  const StoryEngine();

  Story pickStory({required int grade, List<String> weakWords = const <String>[]}) {
    final story = grade <= 1 ? _foxSchoolStory : _forestMathStory;
    return _markProblemWords(story, weakWords);
  }

  Story _markProblemWords(Story story, List<String> weakWords) {
    if (weakWords.isEmpty) return story;
    final lower = weakWords.map((w) => w.toLowerCase()).toSet();
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

  static final Story _foxSchoolStory = Story(
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
    ]),
  );

  static final Story _forestMathStory = Story(
    id: 'story.forest_math.2',
    title: 'Die Beeren im Wald',
    grade: 2,
    level: 2,
    targetSkills: const <String>['reading.fluency', 'math.word_problem'],
    sentences: _sentences(<String>[
      'Lumo sammelt Beeren im Wald.',
      'Zuerst findet er zehn rote Beeren.',
      'Dann kommen noch fuenf blaue Beeren dazu.',
      'Lumo zaehlt langsam und macht keinen Stress.',
      'Am Ende teilt er die Beeren mit Mia.',
    ]),
  );

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
    final problemSet = problemWords.map((w) => w.toLowerCase()).toSet();
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
    final events = <PronunciationEvent>[];
    var matches = 0;
    var spokenCursor = 0;

    for (final expectedToken in expected) {
      if (spokenCursor >= spoken.length) {
        events.add(PronunciationEvent(type: PronunciationEventType.omittedWord, expectedToken: expectedToken, confidence: confidence));
        continue;
      }
      final spokenToken = spoken[spokenCursor];
      if (expectedToken == spokenToken) {
        matches++;
        spokenCursor++;
        continue;
      }
      if (spokenCursor + 1 < spoken.length && spoken[spokenCursor + 1] == expectedToken) {
        events.add(PronunciationEvent(type: PronunciationEventType.substitutedWord, expectedToken: expectedToken, spokenToken: spokenToken, confidence: confidence));
        spokenCursor += 2;
        continue;
      }
      events.add(PronunciationEvent(type: PronunciationEventType.substitutedWord, expectedToken: expectedToken, spokenToken: spokenToken, confidence: confidence));
      spokenCursor++;
    }

    final score = expected.isEmpty ? 0.0 : (matches / expected.length).clamp(0.0, 1.0).toDouble();
    final problem = events.isEmpty ? null : events.first.expectedToken;
    return SentenceReadingAnalysis(
      expectedText: expectedSentence,
      spokenText: spokenTranscript,
      alignmentScore: score,
      correctEnough: score >= .78 && events.length <= 1,
      events: events,
      problemWord: problem,
    );
  }

  List<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zäöüß\s]'), '')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }
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
    final action = orchestrator.handle(AgentEvent(
      type: analysis.correctEnough ? AgentEventType.readingSentenceHeard : AgentEventType.readingErrorDetected,
      childId: childId,
      occurredAt: DateTime.now(),
      correct: analysis.correctEnough,
      payload: <String, Object?>{
        'sentence': sentence.text,
        'word': analysis.problemWord,
        'attemptNumber': progress.attemptNumber,
        'alignmentScore': analysis.alignmentScore,
      },
    ));

    final nextProgress = analysis.correctEnough
        ? progress.copyWith(
            currentSentenceIndex: (progress.currentSentenceIndex + 1).clamp(0, progress.story.sentences.length - 1).toInt(),
            attemptNumber: 1,
            completedSentenceIds: <String>[...progress.completedSentenceIds, sentence.id],
          )
        : progress.copyWith(
            attemptNumber: progress.attemptNumber + 1,
            problemWords: analysis.problemWord == null ? progress.problemWords : <String>{...progress.problemWords, analysis.problemWord!}.toList(growable: false),
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
