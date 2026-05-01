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
    this.signature = '',
  });

  final String id;
  final String title;
  final int grade;
  final int level;
  final List<StorySentence> sentences;
  final List<String> targetSkills;
  final String signature;
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

  static const int estimatedVariantCount = 23040;

  Story pickStory({
    required int grade,
    List<String> weakWords = const <String>[],
    Set<String> avoidSignatures = const <String>{},
  }) {
    final baseSeed = DateTime.now().microsecondsSinceEpoch ^ (grade * 7919) ^ weakWords.join('|').hashCode;
    Story? fallback;
    for (var attempt = 0; attempt < 80; attempt++) {
      final story = _generateStory(grade: grade, seed: baseSeed + attempt * 104729);
      fallback ??= story;
      if (!avoidSignatures.contains(story.signature)) {
        return _markProblemWords(story, weakWords);
      }
    }
    return _markProblemWords(fallback!, weakWords);
  }

  Story _generateStory({required int grade, required int seed}) {
    final random = math.Random(seed);
    final topicIndex = random.nextInt(_topics.length);
    final heroIndex = random.nextInt(_heroes.length);
    final helperIndex = random.nextInt(_helpers.length);
    final placeIndex = random.nextInt(_places.length);
    final actionIndex = random.nextInt(_actions.length);
    final topic = _topics[topicIndex];
    final objectIndex = random.nextInt(topic.objects.length);
    final observationIndex = random.nextInt(topic.observations.length);
    final factIndex = random.nextInt(topic.facts.length);
    final safeRuleIndex = random.nextInt(topic.safeRules.length);
    final feelingIndex = random.nextInt(_feelings.length);
    final endingIndex = random.nextInt(_endings.length);
    final hero = _heroes[heroIndex];
    final helper = _helpers[helperIndex];
    final place = _places[placeIndex];
    final action = _actions[actionIndex];
    final object = topic.objects[objectIndex];
    final observation = topic.observations[observationIndex];
    final fact = topic.facts[factIndex];
    final safeRule = topic.safeRules[safeRuleIndex];
    final feeling = _feelings[feelingIndex];
    final ending = _endings[endingIndex];
    final signature = [
      grade,
      topicIndex,
      heroIndex,
      helperIndex,
      placeIndex,
      objectIndex,
      observationIndex,
      factIndex,
      safeRuleIndex,
      feelingIndex,
      actionIndex,
      endingIndex,
    ].join('.');
    final title = '${topic.title}: $object';

    final lines = grade <= 1
        ? _gradeOneLines(
            hero: hero,
            helper: helper,
            place: place,
            action: action,
            object: object,
            observation: observation,
            fact: fact,
            safeRule: safeRule,
            feeling: feeling,
            ending: ending,
          )
        : _gradeTwoLines(
            hero: hero,
            helper: helper,
            place: place,
            action: action,
            object: object,
            observation: observation,
            fact: fact,
            safeRule: safeRule,
            feeling: feeling,
            ending: ending,
          );

    return Story(
      id: 'generated.$signature',
      title: title,
      grade: grade,
      level: grade <= 1 ? 1 : 2,
      targetSkills: <String>['reading.flüncy', 'reading.sentences', topic.skill],
      sentences: _sentences(lines),
      signature: signature,
    );
  }

  List<String> _gradeOneLines({
    required String hero,
    required String helper,
    required String place,
    required String action,
    required String object,
    required String observation,
    required String fact,
    required String safeRule,
    required String feeling,
    required String ending,
  }) {
    return <String>[
      '$hero geht mit $helper zum $place.',
      'Dort sieht $hero $object.',
      '$hero schaut ganz genau hin.',
      observation,
      fact,
      '$helper sagt: Lies langsam weiter.',
      safeRule,
      '$hero bleibt $feeling und liest den Satz nochmal.',
      ending,
    ];
  }

  List<String> _gradeTwoLines({
    required String hero,
    required String helper,
    required String place,
    required String action,
    required String object,
    required String observation,
    required String fact,
    required String safeRule,
    required String feeling,
    required String ending,
  }) {
    return <String>[
      '$hero und $helper gehen heute zum $place.',
      'Sie wollen etwas Neüs lernen.',
      'Auf dem Weg entdeckt $hero $object.',
      '$helper bleibt stehen und beobachtet es ruhig.',
      observation,
      fact,
      '$hero liest den Satz langsam und deutlich.',
      'Dann erklärt $helper das neue Wissen mit eigenen Worten.',
      safeRule,
      '$hero ist $feeling, aber er bleibt ruhig.',
      'Beim zweiten Lesen klingt der Satz schon flüssiger.',
      action,
      ending,
    ];
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
      signature: story.signature,
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

  static const List<String> _heroes = <String>['Lumo', 'Mia', 'Alina', 'Ben', 'Lina', 'Emil', 'Nora', 'Leo'];
  static const List<String> _helpers = <String>['Lumo', 'Mia', 'Oma', 'Papa', 'Mama', 'Frau Hase'];
  static const List<String> _places = <String>['Schulgarten', 'Wald', 'Teich', 'Park', 'Baürnhof', 'Klassenraum', 'Wiesenrand', 'Fensterbrett'];
  static const List<String> _feelings = <String>['mutig', 'ruhig', 'neugierig', 'stolz', 'konzentriert', 'geduldig'];
  static const List<String> _actions = <String>[
    'Danach malt das Kind ein kleines Bild dazu.',
    'Danach zählen sie drei wichtige Dinge auf.',
    'Danach erklären sie die Idee noch einmal.',
    'Danach suchen sie ein passendes Wort im Text.',
    'Danach klatschen sie die Silben langsam mit.',
    'Danach lesen sie den schwersten Satz noch einmal.',
  ];
  static const List<String> _endings = <String>[
    'Am Ende weiß das Kind wieder ein bisschen mehr.',
    'Am Ende freut sich Lumo über das gute Lesen.',
    'Am Ende merkt sich Lumo das neue Wissen.',
    'Am Ende sagt Lumo: Lernen braucht Zeit.',
    'Am Ende ist der Text geschafft.',
    'Am Ende fühlt sich der Satz leichter an.',
    'Am Ende wird aus Lesen neues Wissen.',
    'Am Ende ist das Kind stolz auf sich.',
  ];

  static const List<_ReadingTopic> _topics = <_ReadingTopic>[
    _ReadingTopic(
      title: 'Naturwissen',
      skill: 'science.nature',
      objects: <String>['ein grünes Blatt', 'eine kleine Wurzel', 'einen starken Baum', 'eine gelbe Blume'],
      observations: <String>[
        'Das Blatt hat feine Linien.',
        'Die Wurzel hält die Pflanze fest.',
        'Der Baum hat Rinde und viele Äste.',
        'Die Blume dreht sich zum Licht.',
      ],
      facts: <String>[
        'Pflanzen brauchen Licht, Wasser und Luft.',
        'Wurzeln holen Wasser aus der Erde.',
        'Bäume geben vielen Tieren ein Zuhause.',
        'Aus manchen Blüten werden später Samen.',
      ],
      safeRules: <String>[
        'Man reisst keine Pflanze ohne Grund aus.',
        'Man schaut genau, aber man zerstört nichts.',
        'Man sammelt nur Dinge, die schon am Boden liegen.',
      ],
    ),
    _ReadingTopic(
      title: 'Tierwissen',
      skill: 'science.animals',
      objects: <String>['eine Biene', 'einen Igel', 'einen Regenwurm', 'einen Marienkäfer'],
      observations: <String>[
        'Die Biene fliegt von Blume zu Blume.',
        'Der Igel schnuppert am Laub.',
        'Der Regenwurm bewegt sich durch die Erde.',
        'Der Marienkäfer krabbelt langsam weiter.',
      ],
      facts: <String>[
        'Bienen tragen Pollen weiter.',
        'Igel suchen im Herbst viel Futter.',
        'Regenwürmer lockern den Boden.',
        'Marienkäfer fressen kleine Blattläuse.',
      ],
      safeRules: <String>[
        'Man fasst kleine Tiere nur sehr vorsichtig an.',
        'Man lässt wilde Tiere in Ruhe.',
        'Man beobachtet Tiere leise und mit Abstand.',
      ],
    ),
    _ReadingTopic(
      title: 'Wetterwissen',
      skill: 'science.weather',
      objects: <String>['eine Wolke', 'einen Regentropfen', 'einen Sonnenstrahl', 'einen kalten Wind'],
      observations: <String>[
        'Die Wolke zieht langsam weiter.',
        'Der Regentropfen liegt auf dem Blatt.',
        'Der Sonnenstrahl macht den Stein warm.',
        'Der Wind bewegt die Blätter.',
      ],
      facts: <String>[
        'Wolken bestehen aus vielen kleinen Tropfen.',
        'Regen hilft den Pflanzen beim Wachsen.',
        'Die Sonne gibt Licht und Wärme.',
        'Wind ist bewegte Luft.',
      ],
      safeRules: <String>[
        'Bei Gewitter geht man ins Haus.',
        'Bei starker Sonne braucht man Schutz.',
        'Bei Regen achtet man auf rutschige Wege.',
      ],
    ),
    _ReadingTopic(
      title: 'Körperwissen',
      skill: 'science.body',
      objects: <String>['seine Hand', 'sein Ohr', 'sein Auge', 'seinen Atem'],
      observations: <String>[
        'Die Hand kann greifen und fühlen.',
        'Das Ohr hört laute und leise Töne.',
        'Das Auge sieht Farben und Formen.',
        'Der Atem geht langsam ein und aus.',
      ],
      facts: <String>[
        'Hände helfen beim Schreiben und Bauen.',
        'Ohren helfen beim Zuhören.',
        'Augen brauchen Pausen beim Lesen.',
        'Ruhiges Atmen hilft beim Konzentrieren.',
      ],
      safeRules: <String>[
        'Man wäscht die Hände vor dem Essen.',
        'Man schützt die Augen vor hellem Licht.',
        'Man hört auf den Körper, wenn er Pause braucht.',
      ],
    ),
    _ReadingTopic(
      title: 'Wasserwissen',
      skill: 'science.water',
      objects: <String>['einen Bach', 'einen Tropfen', 'eine Pfütze', 'eine kleine Quelle'],
      observations: <String>[
        'Der Bach fließt über Steine.',
        'Der Tropfen glänzt im Licht.',
        'Die Pfütze wird in der Sonne kleiner.',
        'Aus der Quelle kommt klares Wasser.',
      ],
      facts: <String>[
        'Wasser kann fließen, gefrieren und verdampfen.',
        'Alle Menschen, Tiere und Pflanzen brauchen Wasser.',
        'Die Sonne kann Wasser langsam verdunsten lassen.',
        'Sauberes Wasser ist wichtig für das Leben.',
      ],
      safeRules: <String>[
        'Man trinkt nur Wasser, das sicher sauber ist.',
        'Am Wasser passt man gut auf.',
        'Man verschwendet Wasser nicht.',
      ],
    ),
    _ReadingTopic(
      title: 'Alltagswissen',
      skill: 'science.daily_life',
      objects: <String>['eine Brotdose', 'einen Schulweg', 'ein Verkehrsschild', 'einen Stundenplan'],
      observations: <String>[
        'Die Brotdose ist ordentlich gepackt.',
        'Der Schulweg hat helle Streifen auf der Straße.',
        'Das Verkehrsschild hat eine klare Form.',
        'Der Stundenplan zeigt den Tag.',
      ],
      facts: <String>[
        'Ein Plan hilft beim Erinnern.',
        'Verkehrsschilder helfen allen Menschen.',
        'Ordnung macht den Morgen leichter.',
        'Pausen helfen beim Lernen.',
      ],
      safeRules: <String>[
        'Auf dem Schulweg schaut man links und rechts.',
        'Man bleibt an der Ampel stehen.',
        'Man fragt, wenn man sich nicht sicher ist.',
      ],
    ),
    _ReadingTopic(
      title: 'Zahlenwissen',
      skill: 'math.word_problem',
      objects: <String>['fünf Kastanien', 'zehn Beeren', 'drei Federn', 'acht kleine Steine'],
      observations: <String>[
        'Die Dinge liegen in einer Reihe.',
        'Man kann sie gut zählen.',
        'Erst sind es wenige, dann werden es mehr.',
        'Zwei Dinge liegen etwas weiter weg.',
      ],
      facts: <String>[
        'Beim Zählen hilft langsames Zeigen.',
        'Eine Reihe macht Mengen sichtbar.',
        'Zehn Dinge kann man gut in zwei Gruppen teilen.',
        'Rechnen beginnt oft mit genaüm Schaün.',
      ],
      safeRules: <String>[
        'Man zählt ruhig und ohne Hektik.',
        'Bei Fehlern fängt man freundlich nochmal an.',
        'Man kann Dinge ordnen, bevor man rechnet.',
      ],
    ),
    _ReadingTopic(
      title: 'Weltraumwissen',
      skill: 'science.space',
      objects: <String>['den Mond', 'einen hellen Stern', 'die Erde', 'eine kleine Rakete'],
      observations: <String>[
        'Der Mond leuchtet am Abend.',
        'Der Stern sieht wie ein kleiner Punkt aus.',
        'Die Erde ist unser Zuhause.',
        'Die Rakete zeigt nach oben.',
      ],
      facts: <String>[
        'Der Mond kreist um die Erde.',
        'Sterne sind sehr weit weg.',
        'Die Erde dreht sich jeden Tag.',
        'Im Weltall gibt es keinen normalen Wind.',
      ],
      safeRules: <String>[
        'Beim Schaün in den Himmel achtet man auf den Weg.',
        'In die Sonne schaut man nie direkt.',
        'Fragen machen Wissenschaft spannend.',
      ],
    ),
  ];
}

class _ReadingTopic {
  const _ReadingTopic({
    required this.title,
    required this.skill,
    required this.objects,
    required this.observations,
    required this.facts,
    required this.safeRules,
  });

  final String title;
  final String skill;
  final List<String> objects;
  final List<String> observations;
  final List<String> facts;
  final List<String> safeRules;
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
    const vowels = 'äiouäöüyÄIOUÄÖÜY';
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
        .replaceAll('ü', 'ü')
        .replaceAll('ö', 'ö')
        .replaceAll('ä', 'ä')
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
