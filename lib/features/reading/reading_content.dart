import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_voice.dart';
import '../../core/reading_progress_repository.dart';
import '../../domain/agent/lumo_agent_domain.dart';
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

  late ReadingSessionProgress _progress;
  late String _readingSessionId;
  String _lastTranscript = '';
  String _processedTranscript = '';
  String _lumoLine = 'Bereit? Lumo hoert dir Satz fuer Satz zu.';
  double? _lastScore;
  int _interventionCount = 0;
  bool _finished = false;
  bool _autoListening = true;
  bool _processing = false;
  Timer? _listenTimer;

  @override
  void initState() {
    super.initState();
    final story = _storyEngine.pickStory(grade: widget.appState.state.grade);
    _readingSessionId = 'reading_${story.id}_${DateTime.now().millisecondsSinceEpoch}';
    _progress = ReadingSessionProgress(
      story: story,
      currentSentenceIndex: 0,
      attemptNumber: 1,
      problemWords: const <String>[],
      completedSentenceIds: const <String>[],
    );
    if (widget.appState.state.settings.microphoneEnabled) {
      _speech.initialize();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakThenListen('Wir lesen jetzt ${story.title}. Lies den ersten Satz langsam vor.');
      _persistReadingProgress(latestScore: 0);
    });
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

  Future<void> _speakThenListen(String message) async {
    _listenTimer?.cancel();
    setState(() => _lumoLine = message);
    widget.appState.update(widget.appState.state.copyWith(
      mood: LumoMood.point,
      lumoMessage: message,
    ));
    await LumoVoice.instance.speak(message);
    if (!mounted || _finished || !_autoListening) return;
    final delayMs = (message.length * 55).clamp(850, 2600).toInt();
    _listenTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || _finished || _speech.listening) return;
      _startListening(auto: true);
    });
  }

  Future<void> _toggleListening() async {
    if (_speech.listening) {
      await _speech.stopListening();
      return;
    }
    _autoListening = true;
    await _startListening(auto: false);
  }

  Future<void> _startListening({required bool auto}) async {
    if (!widget.appState.state.settings.microphoneEnabled) {
      setState(() => _lumoLine = 'Das Mikrofon ist im Elternbereich ausgeschaltet.');
      return;
    }
    if (_finished || _processing || _speech.listening) return;

    setState(() {
      _lastTranscript = '';
      _processedTranscript = '';
      _lumoLine = auto ? 'Ich hoere jetzt zu. Lies den markierten Satz.' : 'Ich hoere zu. Lies den markierten Satz.';
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
    final expected = _normalizeTokens(_progress.currentSentence.text);
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
    setState(() {
      _lastScore = null;
      _lumoLine = 'Ich habe dich nicht gut verstanden. Wir zaehlen das nicht als Fehler.';
    });
    _speakThenListen('Ich habe dich nicht gut verstanden. Wir versuchen denselben Satz noch einmal langsam.');
  }

  void _processTranscript(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) {
      _handleNoMatch();
      return;
    }
    if (_processedTranscript == text || _processing) return;
    _processedTranscript = text;
    _processing = true;
    final result = _monitor.processSentence(childId: _childId, progress: _progress, transcript: text);
    final action = result.decision.primary;
    if (!result.analysis.correctEnough && result.analysis.problemWord != null && _progress.attemptNumber >= 2) {
      _interventionCount++;
    }

    setState(() {
      _lastTranscript = text;
      _progress = result.nextProgress;
      _lastScore = result.analysis.alignmentScore;
      _lumoLine = _progress.isComplete
          ? 'Geschafft! Du hast die Geschichte gelesen. Lumo merkt sich deine starken Saetze und Uebungswoerter.'
          : action.message;
      _finished = _progress.isComplete;
    });

    _persistReadingProgress(latestScore: result.analysis.alignmentScore);

    widget.appState.update(widget.appState.state.copyWith(
      mood: _progress.isComplete ? LumoMood.celebrate : _moodFor(action.tone),
      lumoMessage: _lumoLine,
    ));

    final nextMessage = _progress.isComplete
        ? _lumoLine
        : result.analysis.correctEnough
            ? 'Gut gelesen. Jetzt kommt der naechste Satz. Lies ihn laut vor.'
            : _lumoLine;

    LumoVoice.instance.speak(nextMessage).whenComplete(() {
      _processing = false;
      if (!mounted || _finished || !_autoListening) return;
      final delayMs = (nextMessage.length * 55).clamp(850, 2600).toInt();
      _listenTimer?.cancel();
      _listenTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted && !_finished && !_speech.listening) _startListening(auto: true);
      });
    });
  }

  Future<void> _persistReadingProgress({required double latestScore}) async {
    await _readingRepo.updateLatest(
      id: _readingSessionId,
      childId: _childId,
      storyTitle: _progress.story.title,
      completedSentences: _progress.completedSentenceIds.length,
      totalSentences: _progress.story.sentences.length,
      latestAlignmentScore: latestScore,
      interventionCount: _interventionCount,
      problemWords: _progress.problemWords,
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
        final story = _progress.story;
        final sentence = _progress.currentSentence;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ReadingHeader(title: story.title, onBack: widget.onBack),
                const SizedBox(height: 16),
                _StoryProgressBar(current: _progress.completedSentenceIds.length, total: story.sentences.length),
                const SizedBox(height: 18),
                _StoryTextCard(
                  story: story,
                  currentIndex: _progress.currentSentenceIndex,
                  problemWords: _progress.problemWords,
                ),
                const SizedBox(height: 16),
                _ActiveSentenceCard(
                  sentence: sentence,
                  attemptNumber: _progress.attemptNumber,
                  lastScore: _lastScore,
                  lumoLine: _lumoLine,
                ),
                const SizedBox(height: 14),
                _MicrophonePanel(
                  listening: _speech.listening,
                  enabled: widget.appState.state.settings.microphoneEnabled,
                  lastTranscript: _lastTranscript,
                  error: _speech.error,
                  autoListening: _autoListening,
                  onTap: _finished ? null : _toggleListening,
                  onAutoToggle: (value) => setState(() => _autoListening = value),
                ),
                if (_progress.problemWords.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ProblemWordsCard(words: _progress.problemWords),
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
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.lg)),
          child: const Center(child: Text('📖', style: TextStyle(fontSize: 32))),
        ),
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
            decoration: BoxDecoration(
              color: sentence.index == currentIndex ? LumoColors.orangeSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(LumoRadius.md),
            ),
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
    required this.autoListening,
    required this.onTap,
    required this.onAutoToggle,
  });

  final bool listening;
  final bool enabled;
  final String lastTranscript;
  final String? error;
  final bool autoListening;
  final VoidCallback? onTap;
  final ValueChanged<bool> onAutoToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              enabled ? (listening ? 'Lumo hoert zu …' : 'Lumo startet das Mikrofon automatisch') : 'Mikrofon im Elternbereich ausgeschaltet',
              style: LumoTextStyles.heading3,
            ),
          ),
          GestureDetector(
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listening ? LumoColors.practice : LumoColors.orange,
                boxShadow: LumoShadow.pill,
              ),
              child: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 30),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: autoListening,
          onChanged: enabled ? onAutoToggle : null,
          title: const Text('Automatisch zuhoeren', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
          subtitle: const Text('Lumo startet nach seiner Ansage selbst das Mikrofon.', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        ),
        if (lastTranscript.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Gehoert: $lastTranscript', style: LumoTextStyles.body.copyWith(color: LumoColors.ink600)),
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
