import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_voice.dart';
import '../../core/reading_text_cleaner.dart';
import '../../core/reading_progress_repository.dart';
import '../../core/reading_v2_pronunciation_analyzer.dart';
import '../../core/reading_story_memory_repository.dart';
import '../../domain/agent/lumo_agent_domain.dart';
import '../../domain/reading/reading_attempt_history.dart';
import '../../domain/reading/reading_domain.dart';
import 'widgets/reading_active_sentence_view.dart';

class ReadingContent extends StatefulWidget {
  const ReadingContent({super.key, required this.appState, required this.onBack});

  final LumoAppState appState;
  final VoidCallback onBack;

  @override
  State<ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends State<ReadingContent> {
  final _storyEngine = const StoryEngine();
  final _textCleaner = const ReadingTextCleaner();
  final _monitor = ReadingMonitor(
    analyzer: const ReadingV2PronunciationAnalyzer(),
  );
  final _speech = LumoSpeechListener();
  final _readingRepo = ReadingProgressRepository();
  final _storyMemoryRepo = ReadingStoryMemoryRepository();
  final _attemptLedger = ReadingAttemptLedger();

  static const String _unclearReadingMessage =
      'Ich habe dich nicht gut verstanden. Das war kein Fehler. Lies bitte nochmal langsam.';

  ReadingSessionProgress? _progress;
  late String _readingSessionId;
  String _lastTranscript = '';
  String _processedTranscript = '';
  String _lumoLine = 'Bereit? Lumo hört dir Satz für Satz zu.';
  double? _lastScore;
  int _interventionCount = 0;
  int _activeWordIndex = 0;
  String? _liveProblemWord;
  bool _finished = false;
  bool _showNotHeardHint = false;
  bool _processing = false;
  bool _loadingStory = true;
  Timer? _listenTimer;

  @override
  void initState() {
    super.initState();
    _prepareStorySession();
  }

  Future<void> _prepareStorySession() async {
    final grade = widget.appState.state.grade;
    final childId = _childId;
    final recentSignatures = await _storyMemoryRepo.loadRecent(childId: childId, grade: grade);
    final rawStory = _storyEngine.pickStory(
      grade: grade,
      weakWords: const <String>[],
      avoidSignatures: recentSignatures.toSet(),
    );
    final story = _textCleaner.cleanStory(rawStory);
    await _storyMemoryRepo.remember(childId: childId, grade: grade, signature: story.signature);
    if (!mounted) return;

    _readingSessionId = 'reading_${story.id}_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _progress = ReadingSessionProgress(
        story: story,
        currentSentenceIndex: 0,
        attemptNumber: 1,
        problemWords: const <String>[],
        completedSentenceIds: const <String>[],
      );
      _activeWordIndex = 0;
      _liveProblemWord = null;
      _loadingStory = false;
    });

    if (widget.appState.state.settings.microphoneEnabled) {
      _speech.initialize();
    }
    await _speakOnly('Wir lesen jetzt ${story.title}. Wenn du bereit bist, drück auf das Mikrofon und lies den Satz vor.');
    await _persistReadingProgress(latestScore: 0);
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    _speech.cancel();
    _speech.dispose();
    super.dispose();
  }

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty ? 'kind' : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  ReadingSessionProgress get _safeProgress {
    final progress = _progress;
    if (progress == null) {
      final story = const Story(
        id: 'loading',
        title: 'Lade Lesetext',
        grade: 1,
        level: 1,
        targetSkills: <String>['reading.loading'],
        sentences: <StorySentence>[
          StorySentence(id: 'loading.s1', index: 0, text: 'Lumo sucht eine neue Geschichte', words: <WordToken>[]),
        ],
      );
      return ReadingSessionProgress(
        story: story,
        currentSentenceIndex: 0,
        attemptNumber: 1,
        problemWords: const <String>[],
        completedSentenceIds: const <String>[],
      );
    }
    return progress;
  }

  Future<void> _speakOnly(String message) async {
    if (_loadingStory) return;
    _listenTimer?.cancel();
    setState(() => _lumoLine = message);
    widget.appState.update(widget.appState.state.copyWith(
      mood: LumoMood.point,
      lumoMessage: message,
    ));
    await LumoVoice.instance.speak(message);
  }

  Future<void> _toggleListening() async {
    if (_speech.listening) {
      await _speech.stopListening();
      return;
    }
    setState(() => _showNotHeardHint = false);
    await _startListening();
  }

  Future<void> _startListening() async {
    if (_progress == null) return;
    if (!widget.appState.state.settings.microphoneEnabled) {
      setState(() => _lumoLine = 'Das Mikrofon ist im Elternbereich ausgeschaltet.');
      return;
    }
    if (_finished || _processing || _speech.listening) return;

    _listenTimer?.cancel();
    await LumoVoice.instance.stop();

    setState(() {
      _lastTranscript = '';
      _processedTranscript = '';
      _activeWordIndex = 0;
      _liveProblemWord = null;
      _lumoLine = 'Ich höre zu. Lies den Satz ruhig bis zum Ende.';
    });

    await _speech.startListening(
      onResult: (words) {
        if (!mounted) return;
        final sentence = _safeProgress.currentSentence;
        final live = _liveReadingPosition(sentence: sentence, transcript: words);
        setState(() {
          _lastTranscript = words;
          _activeWordIndex = live.activeIndex;
          _liveProblemWord = live.problemWord;
        });
        if (_looksLikeSentenceComplete(words)) {
          _speech.stopListening();
        }
      },
      onFinalResult: (words) {
        if (!mounted) return;
        _processTranscript(words);
      },
      onNoMatch: () {
        if (!mounted) return;
        _handleNoMatch();
      },
    );
  }

  bool _looksLikeSentenceComplete(String words) {
    final spoken = _normalizeTokens(words);
    final expected = _normalizeTokens(_safeProgress.currentSentence.text);
    if (spoken.isEmpty || expected.isEmpty) return false;
    final lastExpected = expected.last;
    final containsLastWord = spoken.contains(lastExpected) || _similarTokenExists(lastExpected, spoken);
    final enoughWords = spoken.length >= (expected.length - 1).clamp(1, expected.length);
    return containsLastWord && enoughWords;
  }

  bool _similarTokenExists(String expected, List<String> spoken) {
    return spoken.any((token) {
      if (token == expected) return true;
      if (expected == 'lumo' && <String>{'limo', 'luna', 'luno', 'lumos', 'lu'}.contains(token)) return true;
      return token.length > 3 && expected.length > 3 && token.substring(0, 2) == expected.substring(0, 2);
    });
  }

  _LiveReadingPosition _liveReadingPosition({required StorySentence sentence, required String transcript}) {
    final expected = _normalizeTokens(sentence.text);
    final spoken = _normalizeTokens(transcript);
    if (expected.isEmpty || spoken.isEmpty) return const _LiveReadingPosition(activeIndex: 0);

    var expectedIndex = 0;
    String? problemWord;
    for (final spokenToken in spoken) {
      if (expectedIndex >= expected.length) break;
      final expectedToken = expected[expectedIndex];
      final score = _tokenSimilarity(expectedToken, spokenToken);
      if (expectedToken == spokenToken || _isLumoVariant(expectedToken, spokenToken) || score >= .58) {
        expectedIndex++;
        continue;
      }
      if (score < .34) {
        problemWord = expectedToken;
        break;
      }
    }

    final active = expectedIndex.clamp(0, expected.length - 1).toInt();
    return _LiveReadingPosition(activeIndex: active, problemWord: problemWord);
  }

  double _tokenSimilarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final distance = _levenshtein(a, b);
    final longest = a.length > b.length ? a.length : b.length;
    return (1 - distance / longest).clamp(0.0, 1.0).toDouble();
  }

  bool _isLumoVariant(String expected, String spoken) {
    if (expected != 'lumo') return false;
    const variants = <String>{'lumo', 'limo', 'loma', 'luna', 'luno', 'loom', 'lumen', 'lumos', 'humo', 'lu'};
    return variants.contains(spoken) || _tokenSimilarity(expected, spoken) >= .50;
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

  List<String> _normalizeTokens(String value) {
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

  void _handleNoMatch() {
    if (_lastTranscript.trim().isNotEmpty) {
      _processTranscript(_lastTranscript);
      return;
    }
    const calm = _unclearReadingMessage;
    setState(() {
      _lastScore = null;
      _lumoLine = calm;
      _showNotHeardHint = true;
    });
    widget.appState.update(widget.appState.state.copyWith(
      mood: LumoMood.comfort,
      lumoMessage: calm,
    ));
  }

  void _processTranscript(String transcript) {
    final progress = _progress;
    if (progress == null) return;
    final text = transcript.trim();
    if (text.isEmpty) {
      _handleNoMatch();
      return;
    }
    if (_processedTranscript == text || _processing) return;
    _processedTranscript = text;
    _processing = true;

    final result = _monitor.processSentence(childId: _childId, progress: progress, transcript: text);
    final attemptDecision = _attemptLedger.recordAnalysis(
      sentence: progress.currentSentence,
      attemptNumber: progress.attemptNumber,
      analysis: result.analysis,
    );
    final adjustedProgress = _progressAfterDecision(
      previous: progress,
      monitorProgress: result.nextProgress,
      decision: attemptDecision,
    );
    final childMessage =
        attemptDecision.outcome == ReadingAttemptOutcome.retryBecauseRecognitionWasUnclear
            ? _unclearReadingMessage
            : attemptDecision.childMessage;

    if (attemptDecision.shouldCountAsIntervention) {
      _interventionCount++;
    }

    setState(() {
      _lastTranscript = text;
      _showNotHeardHint = false;
      _progress = adjustedProgress;
      _lastScore = result.analysis.alignmentScore;
      if (adjustedProgress.currentSentenceIndex != progress.currentSentenceIndex || adjustedProgress.isComplete) {
        _activeWordIndex = 0;
        _liveProblemWord = null;
      } else {
        final live = _liveReadingPosition(sentence: progress.currentSentence, transcript: text);
        _activeWordIndex = live.activeIndex;
        _liveProblemWord = result.analysis.problemWord ?? live.problemWord;
      }
      _lumoLine = adjustedProgress.isComplete
          ? 'Geschafft! Du hast die Geschichte gelesen. Lumo merkt sich deine starken Sätze und Übungswörter.'
          : childMessage;
      _finished = adjustedProgress.isComplete;
    });

    _persistReadingProgress(latestScore: result.analysis.alignmentScore);

    widget.appState.update(widget.appState.state.copyWith(
      mood: adjustedProgress.isComplete
          ? LumoMood.celebrate
          : attemptDecision.outcome == ReadingAttemptOutcome.retryBecauseRecognitionWasUnclear
              ? LumoMood.comfort
              : _moodFor(result.decision.primary.tone),
      lumoMessage: _lumoLine,
    ));

    final nextMessage = adjustedProgress.isComplete ? _lumoLine : childMessage;
    LumoVoice.instance.speak(nextMessage).whenComplete(() {
      _processing = false;
    });
  }

  ReadingSessionProgress _progressAfterDecision({
    required ReadingSessionProgress previous,
    required ReadingSessionProgress monitorProgress,
    required ReadingAttemptDecision decision,
  }) {
    if (decision.shouldKeepSameAttempt) {
      return previous.copyWith(problemWords: _attemptLedger.persistentProblemWords);
    }
    if (!decision.shouldAdvanceControlled) {
      return monitorProgress.copyWith(problemWords: _attemptLedger.persistentProblemWords);
    }

    final completed = <String>{...previous.completedSentenceIds, previous.currentSentence.id};
    final isComplete = completed.length >= previous.story.sentences.length;
    final nextIndex = isComplete
        ? previous.currentSentenceIndex
        : (previous.currentSentenceIndex + 1).clamp(0, previous.story.sentences.length - 1).toInt();
    final words = <String>{..._attemptLedger.persistentProblemWords};
    final confirmed = decision.confirmedProblemWord;
    if (confirmed != null && confirmed.trim().isNotEmpty) words.add(confirmed.trim().toLowerCase());

    return previous.copyWith(
      currentSentenceIndex: nextIndex,
      attemptNumber: 1,
      completedSentenceIds: completed.toList(growable: false),
      problemWords: words.toList(growable: false),
      isComplete: isComplete,
    );
  }

  Future<void> _persistReadingProgress({required double latestScore}) async {
    final progress = _progress;
    if (progress == null) return;
    await _readingRepo.updateLatest(
      id: _readingSessionId,
      childId: _childId,
      storyTitle: progress.story.title,
      completedSentences: progress.completedSentenceIds.length,
      totalSentences: progress.story.sentences.length,
      latestAlignmentScore: latestScore,
      interventionCount: _interventionCount,
      problemWords: progress.problemWords,
    );
  }

  LumoMood _moodFor(AgentTone tone) {
    return switch (tone) {
      AgentTone.celebrating => LumoMood.celebrate,
      AgentTone.calming => LumoMood.comfort,
      AgentTone.coaching => LumoMood.think,
      AgentTone.focused => LumoMood.point,
      AgentTone.parentNeutral => LumoMood.idle,
      AgentTone.warm => LumoMood.greet,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _speech,
      builder: (context, _) {
        if (_loadingStory) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: LumoColors.orange),
            ),
          );
        }
        final progress = _safeProgress;
        final story = progress.story;
        final sentence = progress.currentSentence;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ReadingHeader(title: story.title, onBack: widget.onBack),
                const SizedBox(height: 16),
                _StoryProgressBar(current: progress.completedSentenceIds.length, total: story.sentences.length),
                const SizedBox(height: 18),
                _StoryTextCard(
                  story: story,
                  currentIndex: progress.currentSentenceIndex,
                  activeWordIndex: _activeWordIndex,
                  liveProblemWord: _liveProblemWord,
                  listening: _speech.listening,
                  problemWords: progress.problemWords,
                ),
                const SizedBox(height: 16),
                _ActiveSentenceCard(
                  sentence: sentence,
                  attemptNumber: progress.attemptNumber,
                  lastScore: _lastScore,
                  lumoLine: _lumoLine,
                  activeWordIndex: _activeWordIndex,
                  liveProblemWord: _liveProblemWord,
                  listening: _speech.listening,
                ),
                const SizedBox(height: 14),
                _MicrophonePanel(
                  listening: _speech.listening,
                  enabled: widget.appState.state.settings.microphoneEnabled,
                  lastTranscript: _lastTranscript,
                  error: _speech.error,
                  showNotHeardHint: _showNotHeardHint,
                  onTap: _finished ? null : _toggleListening,
                ),
                if (progress.problemWords.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ProblemWordsCard(words: progress.problemWords),
                ],
                if (_finished) ...[
                  const SizedBox(height: 18),
                  _FinishedReadingCard(onBack: widget.onBack),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _LiveReadingPosition {
  const _LiveReadingPosition({required this.activeIndex, this.problemWord});

  final int activeIndex;
  final String? problemWord;
}

class _ReadingHeader extends StatelessWidget {
  const _ReadingHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFFFF7ED)])),
      child: Row(children: [
        Container(width: 58, height: 58, decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.lg)), child: const Center(child: Text('📖', style: TextStyle(fontSize: 32)))),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Aktiver Lesemodus', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: LumoColors.orange)),
            const SizedBox(height: 4),
            Text(title, style: LumoTextStyles.heading2.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text('Lumo hört Satz für Satz zu und hilft sofort freundlich.', style: LumoTextStyles.body.copyWith(fontSize: 14)),
          ]),
        ),
        IconButton(onPressed: onBack, icon: const Icon(Icons.close_rounded, color: LumoColors.ink500)),
      ]),
    );
  }
}

class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeCurrent = current.clamp(0, safeTotal).toInt();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Satz $safeCurrent von $total gelesen', style: LumoTextStyles.heading3),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(LumoRadius.pill),
          child: LinearProgressIndicator(value: safeCurrent / safeTotal, minHeight: 8, color: LumoColors.orange, backgroundColor: LumoColors.orange.withOpacity(.14)),
        ),
      ]),
    );
  }
}

class _StoryTextCard extends StatelessWidget {
  const _StoryTextCard({
    required this.story,
    required this.currentIndex,
    required this.activeWordIndex,
    required this.liveProblemWord,
    required this.listening,
    required this.problemWords,
  });

  final Story story;
  final int currentIndex;
  final int activeWordIndex;
  final String? liveProblemWord;
  final bool listening;
  final List<String> problemWords;

  @override
  Widget build(BuildContext context) {
    final problemSet = problemWords.map((w) => w.toLowerCase()).toSet();
    final liveProblem = liveProblemWord?.toLowerCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(color: const Color(0xFFFFFEFA)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final sentence in story.sentences) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: sentence.index == currentIndex ? LumoColors.orangeSurface : Colors.transparent, borderRadius: BorderRadius.circular(LumoRadius.md)),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: sentence.words.asMap().entries.map((entry) {
                final normalized = entry.value.text.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');
                final isProblem = problemSet.contains(normalized) || normalized == liveProblem || entry.value.isProblemWord;
                final isCurrent = sentence.index == currentIndex && entry.key == activeWordIndex;
                return _SyllableWord(
                  word: entry.value,
                  active: sentence.index == currentIndex,
                  current: isCurrent,
                  listening: listening,
                  problem: isProblem,
                );
              }).toList(),
            ),
          ),
        ],
      ]),
    );
  }
}

class _SyllableWord extends StatelessWidget {
  const _SyllableWord({
    required this.word,
    required this.active,
    required this.current,
    required this.listening,
    required this.problem,
  });

  final WordToken word;
  final bool active;
  final bool current;
  final bool listening;
  final bool problem;

  @override
  Widget build(BuildContext context) {
    final highlight = current && active;
    final bg = problem
        ? LumoColors.goldSurface
        : highlight
            ? Colors.white
            : Colors.transparent;
    final border = problem
        ? Border.all(color: LumoColors.gold.withOpacity(.48), width: 1.4)
        : highlight
            ? Border.all(color: listening ? LumoColors.teal : LumoColors.orange, width: 2)
            : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.symmetric(horizontal: highlight || problem ? 8 : 0, vertical: highlight || problem ? 5 : 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        border: border,
        boxShadow: highlight ? [BoxShadow(color: LumoColors.orange.withOpacity(.16), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: RichText(
        text: TextSpan(
          children: word.syllables.asMap().entries.map((entry) {
            return TextSpan(
              text: entry.value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: highlight ? 32 : active ? 26 : 20,
                fontWeight: FontWeight.w900,
                color: problem
                    ? LumoColors.orange
                    : highlight
                        ? LumoColors.ink900
                        : entry.key.isEven
                            ? LumoColors.blue
                            : LumoColors.practice,
                decoration: active && !highlight ? TextDecoration.underline : TextDecoration.none,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActiveSentenceCard extends StatelessWidget {
  const _ActiveSentenceCard({
    required this.sentence,
    required this.attemptNumber,
    required this.lastScore,
    required this.lumoLine,
    required this.activeWordIndex,
    required this.liveProblemWord,
    required this.listening,
  });

  final StorySentence sentence;
  final int attemptNumber;
  final double? lastScore;
  final String lumoLine;
  final int activeWordIndex;
  final String? liveProblemWord;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFF8ED), Color(0xFFFFFFFF)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Jetzt lesen · Versuch ${attemptNumber.clamp(1, 3)} von 3', style: LumoTextStyles.label.copyWith(color: LumoColors.orange)),
        const SizedBox(height: 8),
        ReadingActiveSentenceView(
          sentence: sentence,
          activeWordIndex: activeWordIndex,
          problemWord: liveProblemWord,
          listening: listening,
        ),
        const SizedBox(height: 12),
        Text(lumoLine, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700, fontWeight: FontWeight.w900)),
        if (lastScore != null) ...[
          const SizedBox(height: 10),
          Text('Lesesicherheit: ${(lastScore! * 100).round()}%', style: LumoTextStyles.caption.copyWith(color: LumoColors.ink500)),
        ],
      ]),
    );
  }
}

class _MicrophonePanel extends StatelessWidget {
  const _MicrophonePanel({
    required this.listening,
    required this.enabled,
    required this.lastTranscript,
    required this.error,
    required this.showNotHeardHint,
    required this.onTap,
  });

  final bool listening;
  final bool enabled;
  final String lastTranscript;
  final String? error;
  final bool showNotHeardHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String headline;
    final String subline;
    final Color accent;
    if (!enabled) {
      headline = 'Mikrofon ausgeschaltet';
      subline = 'Im Elternbereich kann das Mikrofon eingeschaltet werden.';
      accent = LumoColors.ink500;
    } else if (listening) {
      headline = 'Ich höre zu …';
      subline = 'Lies den Satz ruhig bis zum Ende. Tippe zum Stoppen.';
      accent = LumoColors.teal;
    } else if (showNotHeardHint) {
      headline = 'Ich habe dich nicht gut gehört.';
      subline = 'Das war kein Fehler. Drück nochmal auf das Mikrofon, wenn du bereit bist.';
      accent = LumoColors.purple;
    } else {
      headline = 'Bereit zum Lesen';
      subline = 'Drück auf das Mikrofon, wenn du bereit bist.';
      accent = LumoColors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(headline, style: LumoTextStyles.heading3.copyWith(color: accent)),
              const SizedBox(height: 4),
              Text(subline, style: LumoTextStyles.body.copyWith(color: LumoColors.ink500)),
            ]),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !enabled ? LumoColors.ink300 : listening ? LumoColors.practice : LumoColors.orange,
                boxShadow: enabled ? LumoShadow.pill : null,
              ),
              child: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 36),
            ),
          ),
        ]),
        if (lastTranscript.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Gehört: $lastTranscript', style: LumoTextStyles.body.copyWith(color: LumoColors.ink600)),
        ],
        if (error != null && error != 'error_no_match') ...[
          const SizedBox(height: 8),
          Text('Mikrofon-Hinweis: $error', style: LumoTextStyles.caption.copyWith(color: LumoColors.practice)),
        ],
      ]),
    );
  }
}

class _ProblemWordsCard extends StatelessWidget {
  const _ProblemWordsCard({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFFFFFF)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Übungswörter für später', style: LumoTextStyles.heading3),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: words.map((word) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(LumoRadius.pill), border: Border.all(color: LumoColors.gold.withOpacity(.35))),
            child: Text(word, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: LumoColors.ink700)),
          );
        }).toList()),
      ]),
    );
  }
}

class _FinishedReadingCard extends StatelessWidget {
  const _FinishedReadingCard({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFDCFCE7), Color(0xFFFFFFFF)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Leserunde geschafft!', style: TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF14532D))),
        const SizedBox(height: 8),
        Text('Lumo hat deine Sätze und Übungswörter gespeichert. Morgen kann daraus eine neue Empfehlung entstehen.', style: LumoTextStyles.body.copyWith(color: const Color(0xFF166534))),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: onBack, icon: const Icon(Icons.home_rounded), label: const Text('Zurück')),
      ]),
    );
  }
}
