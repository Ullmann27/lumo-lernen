import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_voice.dart';
import '../../core/reading_progress_repository.dart';
import '../../core/reading_story_memory_repository.dart';
import '../../domain/agent/lumo_agent_domain.dart';
import '../../domain/reading/reading_attempt_history.dart';
import '../../domain/reading/reading_domain.dart';

class ReadingContent extends StatefulWidget {
  const ReadingContent({super.key, required this.appState, required this.onBack});

  final LumoAppState appState;
  final VoidCallback onBack;

  @override
  State<ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends State<ReadingContent> {
  final _storyEngine = const StoryEngine();
  final _monitor = ReadingMonitor();
  final _speech = LumoSpeechListener();
  final _readingRepo = ReadingProgressRepository();
  final _storyMemoryRepo = ReadingStoryMemoryRepository();
  final _attemptLedger = ReadingAttemptLedger();

  ReadingSessionProgress? _progress;
  late String _readingSessionId;
  String _lastTranscript = '';
  String _processedTranscript = '';
  String _lumoLine = 'Bereit? Lumo hoert dir Satz fuer Satz zu.';
  double? _lastScore;
  int _interventionCount = 0;
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
    final story = _storyEngine.pickStory(
      grade: grade,
      weakWords: const <String>[],
      avoidSignatures: recentSignatures.toSet(),
    );
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
      _loadingStory = false;
    });

    if (widget.appState.state.settings.microphoneEnabled) {
      _speech.initialize();
    }
    await _speakOnly('Wir lesen jetzt ${story.title}. Wenn du bereit bist, drueck auf das Mikrofon und lies den Satz vor.');
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
          StorySentence(id: 'loading.s1', index: 0, text: 'Lumo sucht eine neue Geschichte.', words: <WordToken>[]),
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
      _lumoLine = 'Ich hoere zu. Lies den Satz ruhig bis zum Ende.';
    });

    await _speech.startListening(
      onResult: (words) {
        if (!mounted) return;
        setState(() => _lastTranscript = words);
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

  List<String> _normalizeTokens(String value) {
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

  void _handleNoMatch() {
    if (_lastTranscript.trim().isNotEmpty) {
      _processTranscript(_lastTranscript);
      return;
    }
    const calm = 'Ich habe dich nicht gut gehoert. Das war kein Fehler. Drueck nochmal auf das Mikrofon, wenn du bereit bist.';
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

    if (attemptDecision.shouldCountAsIntervention) {
      _interventionCount++;
    }

    setState(() {
      _lastTranscript = text;
      _showNotHeardHint = false;
      _progress = adjustedProgress;
      _lastScore = result.analysis.alignmentScore;
      _lumoLine = adjustedProgress.isComplete
          ? 'Geschafft! Du hast die Geschichte gelesen. Lumo merkt sich deine starken Saetze und Uebungswoerter.'
          : attemptDecision.childMessage;
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

    final nextMessage = adjustedProgress.isComplete ? _lumoLine : attemptDecision.childMessage;
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
                _StoryTextCard(story: story, currentIndex: progress.currentSentenceIndex, problemWords: progress.problemWords),
                const SizedBox(height: 16),
                _ActiveSentenceCard(sentence: sentence, attemptNumber: progress.attemptNumber, lastScore: _lastScore, lumoLine: _lumoLine),
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
            const Text('Aktiver Lesemodus', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: LumoColors.orange)),
            const SizedBox(height: 3),
            Text(title, style: LumoTextStyles.heading2),
            const SizedBox(height: 4),
            Text('Lumo hoert Satz fuer Satz zu und hilft sofort freundlich.', style: LumoTextStyles.body.copyWith(fontSize: 13)),
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
  const _StoryTextCard({required this.story, required this.currentIndex, required this.problemWords});

  final Story story;
  final int currentIndex;
  final List<String> problemWords;

  @override
  Widget build(BuildContext context) {
    final problemSet = problemWords.map((w) => w.toLowerCase()).toSet();
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
              children: sentence.words.map((word) {
                final isProblem = problemSet.contains(word.text.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '')) || word.isProblemWord;
                return _SyllableWord(word: word, active: sentence.index == currentIndex, problem: isProblem);
              }).toList(),
            ),
          ),
        ],
      ]),
    );
  }
}

class _SyllableWord extends StatelessWidget {
  const _SyllableWord({required this.word, required this.active, required this.problem});

  final WordToken word;
  final bool active;
  final bool problem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: problem ? 4 : 0, vertical: 2),
      decoration: BoxDecoration(
        color: problem ? LumoColors.goldSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        border: problem ? Border.all(color: LumoColors.gold.withOpacity(.35)) : null,
      ),
      child: RichText(
        text: TextSpan(
          children: word.syllables.asMap().entries.map((entry) {
            return TextSpan(
              text: entry.value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: active ? 22 : 18,
                fontWeight: FontWeight.w900,
                color: entry.key.isEven ? LumoColors.blue : LumoColors.practice,
                decoration: active ? TextDecoration.underline : TextDecoration.none,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActiveSentenceCard extends StatelessWidget {
  const _ActiveSentenceCard({required this.sentence, required this.attemptNumber, required this.lastScore, required this.lumoLine});

  final StorySentence sentence;
  final int attemptNumber;
  final double? lastScore;
  final String lumoLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFF8ED), Color(0xFFFFFFFF)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Jetzt lesen · Versuch ${attemptNumber.clamp(1, 3)} von 3', style: LumoTextStyles.label.copyWith(color: LumoColors.orange)),
        const SizedBox(height: 8),
        Text(sentence.text, style: const TextStyle(fontFamily: 'Nunito', fontSize: 27, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.25)),
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
        const Text('Uebungswoerter fuer spaeter', style: LumoTextStyles.heading3),
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
        Text('Lumo hat deine Saetze und Uebungswoerter gespeichert. Morgen kann daraus eine neue Empfehlung entstehen.', style: LumoTextStyles.body.copyWith(color: const Color(0xFF166534))),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: onBack, icon: const Icon(Icons.home_rounded), label: const Text('Zurueck')),
      ]),
    );
  }
}
