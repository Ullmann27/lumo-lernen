// ════════════════════════════════════════════════════════════════════════
// LUMO STORY READER — Lese-Heft mit Live-Bildern + Lern-Stops
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_feature_permissions.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_story_generator.dart';
import '../../core/lumo_story_library.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/premium/lumo_premium_card.dart';
import '../../widgets/premium/lumo_reward_burst.dart';
import '../writing/lumo_writing_coach_screen.dart';

class LumoStoryReaderScreen extends StatefulWidget {
  const LumoStoryReaderScreen({
    super.key,
    required this.story,
    required this.appState,
    this.storyId,
  });

  final LumoStory story;
  final LumoAppState appState;

  /// Wenn null: Story ist neu und wird beim Beenden gespeichert.
  /// Wenn gesetzt: Story kommt schon aus der Bibliothek.
  final String? storyId;

  @override
  State<LumoStoryReaderScreen> createState() => _LumoStoryReaderScreenState();
}

class _LumoStoryReaderScreenState extends State<LumoStoryReaderScreen>
    with WidgetsBindingObserver {
  int _pageIdx = 0;
  bool _exerciseDone = false;
  String? _selectedAnswer;
  // Zusammenfassungs-Phase nach der letzten Seite (Heinz' Wunsch:
  // "Am Schluss wird gefragt um was es geht und das Kind kann erklaeren,
  //  dann bewertet Lumo die Zusammenfassung").
  bool _inSummaryMode = false;
  bool _inBookQuiz = false;
  bool _fullBookView = false;
  int _bookQuestionIndex = 0;
  String? _bookQuizSelected;
  int _bookQuestionsCorrectFirstTry = 0;
  bool _bookQuestionHadMistake = false;
  final TextEditingController _summaryCtrl = TextEditingController();
  final LumoSpeechListener _speech = LumoSpeechListener();
  bool _summaryEvaluated = false;
  int _summaryHits = 0;
  int _summaryStars = 0;
  bool _finishing = false;
  String? _savedStoryId;

  @override
  void initState() {
    super.initState();
    _savedStoryId = widget.storyId;
    WidgetsBinding.instance.addObserver(this);
    // Reading comes first. The loudspeaker remains available on demand.
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _speech.cancel();
    _speech.dispose();
    WidgetsBinding.instance.removeObserver(this);
    LumoVoice.instance.stop();
    super.dispose();
  }

  void _speak() {
    try {
      LumoVoice.instance.speak(widget.story.pages[_pageIdx].text);
    } catch (_) {}
  }

  void _nextPage() {
    if (_pageIdx + 1 >= widget.story.pages.length) {
      // Letzte Seite fertig: wenn die Geschichte keyPoints hat, starten wir
      // die Zusammenfassungs-Phase. Sonst direkt zu Finish.
      if (widget.story.bookQuestions.isNotEmpty) {
        LumoVoice.instance.stop();
        setState(() => _inBookQuiz = true);
      } else {
        _enterSummaryOrFinish();
      }
      return;
    }
    setState(() {
      _pageIdx++;
      _exerciseDone = false;
      _selectedAnswer = null;
    });
    // Pages are rendered directly by _buildPage, not by a PageView.
    // The page index above is the actual navigation state.
    // Page changes never trigger automatic speech. The child reads first.
  }

  void _enterSummaryOrFinish() {
    if (widget.story.keyPoints.isNotEmpty) {
      setState(() {
        _inBookQuiz = false;
        _inSummaryMode = true;
      });
    } else {
      _showFinish();
    }
  }

  void _chooseBookAnswer(String option) {
    final question = widget.story.bookQuestions[_bookQuestionIndex];
    if (_bookQuizSelected == question.correctAnswer) return;
    final isCorrect = option == question.correctAnswer;
    setState(() {
      _bookQuizSelected = option;
      if (!isCorrect) {
        _bookQuestionHadMistake = true;
      } else if (!_bookQuestionHadMistake) {
        _bookQuestionsCorrectFirstTry++;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _nextBookQuestion() {
    if (_bookQuizSelected !=
        widget.story.bookQuestions[_bookQuestionIndex].correctAnswer) {
      return;
    }
    if (_bookQuestionIndex + 1 == widget.story.bookQuestions.length) {
      _enterSummaryOrFinish();
      return;
    }
    setState(() {
      _bookQuestionIndex++;
      _bookQuizSelected = null;
      _bookQuestionHadMistake = false;
    });
  }

  void _startListeningSummary() async {
    if (!await LumoFeaturePermissions.microphone(context, widget.appState) ||
        !mounted) {
      return;
    }
    try {
      _summaryCtrl.text = '';
      await _speech.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() => _summaryCtrl.text = text);
        },
        onFinalResult: (text) {
          if (!mounted) return;
          setState(() => _summaryCtrl.text = text);
        },
      );
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _speech.cancel();
      LumoVoice.instance.stop();
    }
  }

  void _stopListeningSummary() async {
    try {
      await _speech.stopListening();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  /// Bewertung: zaehlt, wie viele keyPoints (oder einfache Wort-Stamm-Treffer)
  /// im Kind-Text vorkommen. Jeder Treffer = 1 Punkt. >=70% -> 5 Sterne,
  /// >=50% -> 4, >=30% -> 3, sonst 2 (Kind hat es zumindest versucht).
  void _evaluateSummary() {
    final raw = _summaryCtrl.text.trim();
    final lower = raw.toLowerCase();
    if (lower.isEmpty) {
      try {
        LumoVoice.instance
            .speak('Erzaehl mir doch ein paar Sätze, ich hör dir gerne zu!');
      } catch (_) {}
      return;
    }
    var hits = 0;
    for (final kp in widget.story.keyPoints) {
      // Stamm-Matching: erste 4 Buchstaben des keypoints in lower suchen.
      final stem = kp.toLowerCase().length >= 4
          ? kp.toLowerCase().substring(0, 4)
          : kp.toLowerCase();
      if (lower.contains(stem)) hits++;
    }
    final total = widget.story.keyPoints.length.clamp(1, 99);
    final ratio = hits / total;
    final stars = ratio >= 0.7
        ? 5
        : ratio >= 0.5
            ? 4
            : ratio >= 0.3
                ? 3
                : 2;
    setState(() {
      _summaryEvaluated = true;
      _summaryHits = hits;
      _summaryStars = stars;
    });
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 10);
    final msg = stars >= 5
        ? 'Super! Du hast die Geschichte fast komplett erzaehlt! $stars Sterne fuer dich!'
        : stars >= 4
            ? 'Sehr gut! Du hast viele wichtige Punkte erwischt. $stars Sterne!'
            : stars >= 3
                ? 'Schon gut! Lies die Geschichte nochmal, dann faellt dir mehr ein. $stars Sterne!'
                : 'Du hast es probiert - das ist mutig! Versuch nochmal, mehr Details zu erzaehlen.';
    try {
      LumoVoice.instance.speak(msg);
    } catch (_) {}
    if (stars >= 4) {
      showLumoRewardBurst(context, stars: stars, xp: stars * 10);
    }
  }

  void _onAnswer(String answer, StoryExercise ex) async {
    HapticFeedback.lightImpact();
    final correct = answer == ex.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _exerciseDone = ex.type == StoryExerciseType.wordChoice
          ? correct
          : true;
    });
    if (correct) {
      widget.appState.addStars(1);
      widget.appState.addXp(5);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) showLumoRewardBurst(context, stars: 1, xp: 5);
    }
  }

  Future<void> _showFinish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      if (_savedStoryId == null) {
        final saved = await LumoStoryLibrary.instance.addStory(widget.story);
        _savedStoryId = saved.id;
      }
      if (!mounted) return;
      await _showFinishDialog();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 88),
        content: Text(
            'Dein Heft konnte nicht gespeichert werden. Bitte versuche es noch einmal.'),
      ));
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _showFinishDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: LumoTokens.colors.surface,
        title: Text('🎉 ${widget.story.title} — Geschafft!',
            style: LumoTokens.typo.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Du hast die ganze Geschichte gelesen!',
                style: LumoTokens.typo.bodyLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LumoTokens.colors.successLight,
                borderRadius: LumoTokens.brMedium,
              ),
              child: Row(children: [
                Icon(Icons.save_rounded, color: LumoTokens.colors.successDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Heft in deine Bibliothek gespeichert!',
                      style: LumoTokens.typo.bodyMedium
                          .copyWith(color: LumoTokens.colors.successDeep)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text('Neue Wörter aus dem Heft:',
                style: LumoTokens.typo.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: widget.story.newWords
                  .map((w) => Chip(
                        label: Text(w),
                        backgroundColor:
                            LumoTokens.colors.lumoLila.withOpacity(0.15),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop(); // Dialog
              navigator.pop(true); // Reader: successfully saved completion
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => LumoWritingCoachScreen(
                    appState: widget.appState,
                    customWords: widget.story.newWords,
                    sourceTitle: widget.story.title,
                  ),
                ),
              );
            },
            child: const Text('Wörter im Schreibcoach üben!'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.story.pages[_pageIdx];
    return PopScope(
      canPop: !_finishing,
      child: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        body: LumoSceneBackground(
          scene: LumoScene.library,
          dimmed: true,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _fullBookView
                      ? _buildFullBook()
                      : _inSummaryMode
                          ? _buildSummaryPage()
                      : _inBookQuiz
                          ? _buildBookQuiz()
                          : _buildPage(page),
                ),
                _fullBookView
                    ? _buildFullBookBottomNav()
                    : _inSummaryMode
                        ? _buildSummaryBottomNav()
                    : _inBookQuiz
                        ? _buildBookQuizNavigation()
                        : _buildBottomNav(page),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(LumoTokens.space12, LumoTokens.space8,
          LumoTokens.space12, LumoTokens.space8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: LumoVisualTokens.white),
            onPressed: _finishing ? null : () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(widget.story.title,
                    style: LumoTokens.typo.titleLarge.copyWith(color: LumoVisualTokens.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_pageIdx + 1) / widget.story.pages.length,
                    minHeight: 6,
                    backgroundColor: LumoVisualTokens.glassRow,
                    valueColor:
                        AlwaysStoppedAnimation(LumoVisualTokens.cyanBright),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('lumo-full-book-toggle'),
            tooltip: _fullBookView
                ? 'Zurück zum Leseabenteuer'
                : 'Gesamtes Buch im Volltext lesen',
            icon: Icon(_fullBookView
                ? Icons.menu_book_rounded
                : Icons.chrome_reader_mode_rounded,
                color: LumoVisualTokens.cyanBright),
            onPressed: () => setState(() => _fullBookView = !_fullBookView),
          ),
          IconButton(
            tooltip: 'Seite vorlesen',
            icon: const Icon(Icons.volume_up_rounded,
                color: LumoVisualTokens.cyanBright),
            onPressed: _fullBookView ? null : _speak,
          ),
        ],
      ),
    );
  }

  Widget _buildFullBook() {
    return ListView(
      key: const ValueKey('lumo-story-complete-book'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.story.title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                )),
              const SizedBox(height: 8),
              const Text(
                'Dein ganzes Buch – ohne Unterbrechung. '
                'Wenn du miträtseln möchtest, kehre zur Leseansicht zurück.',
                style: TextStyle(
                  color: LumoVisualTokens.muted,
                  height: 1.4,
                  fontSize: 15,
                )),
              const SizedBox(height: 18),
              for (final page in widget.story.pages) ...[
                LumoGlassCard(
                  key: ValueKey('full-book-page-${page.pageNum}'),
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kapitel ${((page.pageNum - 1) ~/ 3) + 1} '
                          '· Seite ${page.pageNum}',
                        style: const TextStyle(
                          color: LumoVisualTokens.cyanBright,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        )),
                      const SizedBox(height: 12),
                      Text(page.text,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          height: 1.65,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        )),
                    ],
                  ),
                ),
                if (page.pageNum % 3 == 0) ...[
                  const SizedBox(height: 12),
                  LumoGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      const LumoFoxPose(
                        pose: LumoDesignFoxPose.bookPoint, size: 78),
                      const SizedBox(width: 14),
                      const Expanded(child: Text(
                        'Bildpause: Lumo überlegt, was als Nächstes geschieht.',
                        style: TextStyle(
                          color: LumoVisualTokens.white,
                          fontWeight: FontWeight.w800, fontSize: 15),
                      )),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
              ],
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFullBookBottomNav() => Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        key: const ValueKey('lumo-return-from-full-book'),
        onPressed: () => setState(() => _fullBookView = false),
        icon: const Icon(Icons.auto_stories_rounded),
        label: const Text('Zurück zum Leseabenteuer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: LumoVisualTokens.cyanBright,
          foregroundColor: LumoVisualTokens.navigation,
        ),
      ),
    ),
  );

  /// The child's words come first; illustration is secondary to reading.
  Widget _buildPage(LumoStoryPage page) {
    return SingleChildScrollView(
      key: const ValueKey('lumo-story-reader-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LumoGlassCard(
                key: const ValueKey('lumo-story-visible-page-text'),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.auto_stories_rounded,
                          color: LumoVisualTokens.cyanBright, size: 21),
                      const SizedBox(width: 9),
                      Expanded(child: Text(
                        'Kapitel ${(_pageIdx ~/ 3) + 1} · Seite ${page.pageNum} von ${widget.story.pages.length}',
                        style: const TextStyle(
                          color: LumoVisualTokens.cyanBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Text(page.text,
                      key: const ValueKey('lumo-story-actual-page-text'),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LumoGlassCard(
                key: const ValueKey('lumo-story-original-fox-art'),
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  const LumoFoxPose(
                    pose: LumoDesignFoxPose.bookPoint,
                    size: 94,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Du liest – Lumo hilft dir',
                        style: TextStyle(
                          color: LumoVisualTokens.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text('Lies selbst. Bei Bedarf tippe oben auf den Lautsprecher.',
                        style: TextStyle(
                          color: LumoVisualTokens.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  )),
                ]),
              ),
              if (page.exercise != null) ...[
                const SizedBox(height: 16),
                _buildExerciseCard(page.exercise!),
              ],
              if (page.newWord != null) ...[
                const SizedBox(height: 12),
                LumoGlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.lightbulb_rounded,
                      color: LumoVisualTokens.gold),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Neues Wort: ${page.newWord!}',
                      style: const TextStyle(
                        color: LumoVisualTokens.white,
                        fontWeight: FontWeight.w800,
                      ),
                    )),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(StoryExercise ex) {
    return LumoPremiumCard(
      gradient: LinearGradient(
        colors: [LumoTokens.colors.gold, LumoTokens.colors.goldDeep],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Lumo-Mini-Aufgabe:',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(ex.prompt,
              style: LumoTokens.typo.titleLarge
                  .copyWith(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (ex.options != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ex.options!.map((o) {
                final isSel = _selectedAnswer == o;
                final isCorrect = o == ex.correctAnswer;
                Color bg = Colors.white;
                if (isSel) {
                  bg = isCorrect
                      ? LumoTokens.colors.success
                      : LumoTokens.colors.errorSoft;
                } else if (_exerciseDone && isCorrect) {
                  bg = LumoTokens.colors.successLight;
                }
                return GestureDetector(
                  onTap: _exerciseDone ? null : () => _onAnswer(o, ex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: LumoTokens.brMedium,
                    ),
                    child: Text(o,
                        style: LumoTokens.typo.titleLarge
                            .copyWith(color: LumoTokens.colors.textDark)),
                  ),
                );
              }).toList(),
            ),
          if (ex.type == StoryExerciseType.wordChoice &&
              _selectedAnswer != null && !_exerciseDone)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Noch nicht. Lies die Hinweise der vorherigen Seiten '
                'noch einmal und versuche es erneut.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (ex.options == null)
            // Wort-Schreib-Aufgabe: einfacher Button "Im Schreibcoach üben"
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _exerciseDone = true);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Wort merken!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: LumoTokens.colors.lumoOrangeDeep,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(LumoStoryPage page) {
    final canContinue = page.exercise == null || _exerciseDone;
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: canContinue && !_finishing ? _nextPage : null,
          icon: Icon(_pageIdx + 1 >= widget.story.pages.length
              ? Icons.celebration_rounded
              : Icons.arrow_forward_rounded),
          label: Text(_pageIdx + 1 >= widget.story.pages.length
              ? widget.story.bookQuestions.isNotEmpty
                  ? 'Fragen zum ganzen Buch'
                  : 'Erzähl mir die Geschichte!'
              : 'Weiterlesen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LumoVisualTokens.cyanBright,
            foregroundColor: LumoVisualTokens.navigation,
            textStyle: LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: LumoTokens.brLarge),
          ),
        ),
      ),
    );
  }

  Widget _buildBookQuiz() {
    final question = widget.story.bookQuestions[_bookQuestionIndex];
    final correct = _bookQuizSelected == question.correctAnswer;
    return SingleChildScrollView(
      key: const ValueKey('lumo-book-reading-quiz'),
      padding: const EdgeInsets.all(16),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Was hast du dir aus dem Buch gemerkt?',
              style: TextStyle(
                color: LumoVisualTokens.white,
                fontFamily: 'Nunito',
                fontSize: 23,
                fontWeight: FontWeight.w900,
              )),
            const SizedBox(height: 8),
            Text('Frage ${_bookQuestionIndex + 1} von ${widget.story.bookQuestions.length} '
                '· Es geht jetzt nicht um die beiden Rätsel.',
              style: const TextStyle(
                color: LumoVisualTokens.muted,
                height: 1.4,
                fontSize: 15)),
            const SizedBox(height: 16),
            LumoGlassCard(
              key: ValueKey('lumo-book-question-$_bookQuestionIndex'),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(question.prompt,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 21,
                      height: 1.4,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                    )),
                  const SizedBox(height: 16),
                  for (final option in question.options) ...[
                    Material(
                      color: _bookQuizSelected == option
                          ? option == question.correctAnswer
                              ? const Color(0xFF184C46)
                              : const Color(0xFF58373B)
                          : const Color(0xFF122F50),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: ValueKey('book-answer-${question.options.indexOf(option)}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: correct ? null : () => _chooseBookAnswer(option),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          alignment: Alignment.centerLeft,
                          child: Text(option, style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  if (_bookQuizSelected != null) ...[
                    const SizedBox(height: 10),
                    Text(correct
                        ? 'Richtig erinnert! Du hast aufmerksam gelesen.'
                        : 'Schau noch einmal auf die Antworten. '
                          'Du darfst es erneut versuchen.',
                      key: const ValueKey('lumo-book-answer-feedback'),
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildBookQuizNavigation() {
    final question = widget.story.bookQuestions[_bookQuestionIndex];
    final solved = _bookQuizSelected == question.correctAnswer;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const ValueKey('lumo-book-quiz-next'),
          onPressed: solved ? _nextBookQuestion : null,
          icon: const Icon(Icons.auto_stories_rounded),
          label: Text(_bookQuestionIndex + 1 == widget.story.bookQuestions.length
              ? 'Zum Buchrückblick'
              : 'Nächste Buchfrage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LumoVisualTokens.cyanBright,
            foregroundColor: LumoVisualTokens.navigation,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // ZUSAMMENFASSUNGS-PHASE
  // ──────────────────────────────────────────────────────────────────

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aufgaben-Karte mit Frage
          LumoPremiumCard(
            gradient: LinearGradient(
              colors: [LumoTokens.colors.gold, LumoTokens.colors.goldDeep],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.auto_stories_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Worum ging es in der Geschichte?',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Erzähl Lumo mit deinen eigenen Worten, was passiert ist. '
                  'Du kannst sprechen oder tippen.',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4),
                ),
              ],
            ),
          ),
          if (widget.story.bookQuestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Buchfragen: $_bookQuestionsCorrectFirstTry von '
              '${widget.story.bookQuestions.length} sofort gewusst. '
              'Wichtiger als Punkte ist, dass du den Text verstanden hast.',
              style: const TextStyle(
                color: LumoVisualTokens.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: LumoTokens.space12),
          // Eingabefeld
          LumoPremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _summaryCtrl,
                  enabled: !_summaryEvaluated,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Tipp hier deine Zusammenfassung ein oder drück "Sprechen"...',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _speech,
                  builder: (_, __) {
                    final listening = _speech.listening;
                    return ElevatedButton.icon(
                      onPressed: _summaryEvaluated
                          ? null
                          : (listening
                              ? _stopListeningSummary
                              : _startListeningSummary),
                      icon: Icon(
                          listening ? Icons.stop_rounded : Icons.mic_rounded),
                      label: Text(listening ? 'Stopp' : 'Sprechen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: listening
                            ? LumoTokens.colors.errorSoft
                            : LumoTokens.colors.lumoLila,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_summaryEvaluated) ...[
            const SizedBox(height: LumoTokens.space12),
            _buildSummaryFeedback(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryFeedback() {
    final total = widget.story.keyPoints.length;
    return LumoPremiumCard(
      gradient: LinearGradient(
        colors: _summaryStars >= 4
            ? [LumoTokens.colors.success, LumoTokens.colors.successDeep]
            : [LumoTokens.colors.lumoOrange, LumoTokens.colors.lumoOrangeDeep],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star_rounded,
                  color: i < _summaryStars
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Du hast $_summaryHits von $total wichtigen Punkten erzählt!',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _summaryStars >= 5
                ? 'Spitze! Du hast die Geschichte fast komplett erzählt.'
                : _summaryStars >= 4
                    ? 'Sehr gut! Du hast viele wichtige Details.'
                    : _summaryStars >= 3
                        ? 'Schon gut! Versuch beim nächsten Mal noch mehr Details.'
                        : 'Versuch nochmal, dir mehr aus der Geschichte zu merken.',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: _summaryEvaluated
            ? ElevatedButton.icon(
                onPressed: _finishing ? null : _showFinish,
                icon: const Icon(Icons.celebration_rounded),
                label: const Text('Fertig!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoTokens.colors.lumoOrange,
                  foregroundColor: Colors.white,
                  textStyle: LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
                  shape:
                      RoundedRectangleBorder(borderRadius: LumoTokens.brLarge),
                ),
              )
            : ElevatedButton.icon(
                onPressed: _evaluateSummary,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Bewertung holen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoTokens.colors.lumoLila,
                  foregroundColor: Colors.white,
                  textStyle: LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
                  shape:
                      RoundedRectangleBorder(borderRadius: LumoTokens.brLarge),
                ),
              ),
      ),
    );
  }
}
