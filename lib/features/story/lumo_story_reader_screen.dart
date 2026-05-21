// ════════════════════════════════════════════════════════════════════════
// LUMO STORY READER — Lese-Heft mit Live-Bildern + Lern-Stops
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_image_generator.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_story_generator.dart';
import '../../core/lumo_story_library.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/premium/lumo_magic_background.dart';
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
    with SingleTickerProviderStateMixin {
  int _pageIdx = 0;
  bool _exerciseDone = false;
  String? _selectedAnswer;
  late final PageController _pageCtrl;
  // Zusammenfassungs-Phase nach der letzten Seite (Heinz' Wunsch:
  // "Am Schluss wird gefragt um was es geht und das Kind kann erklaeren,
  //  dann bewertet Lumo die Zusammenfassung").
  bool _inSummaryMode = false;
  final TextEditingController _summaryCtrl = TextEditingController();
  final LumoSpeechListener _speech = LumoSpeechListener();
  bool _summaryEvaluated = false;
  int _summaryHits = 0;
  int _summaryStars = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _summaryCtrl.dispose();
    _speech.cancel();
    _speech.dispose();
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
      if (widget.story.keyPoints.isNotEmpty) {
        setState(() => _inSummaryMode = true);
        try {
          LumoVoice.instance.speak(
              'Schön! Erzähl mir, worum es in der Geschichte ging. Was ist alles passiert?');
        } catch (_) {}
      } else {
        _showFinish();
      }
      return;
    }
    setState(() {
      _pageIdx++;
      _exerciseDone = false;
      _selectedAnswer = null;
    });
    _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);
    _speak();
  }

  void _startListeningSummary() async {
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
        LumoVoice.instance.speak('Erzaehl mir doch ein paar Sätze, ich hör dir gerne zu!');
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
      _exerciseDone = true;
    });
    if (correct) {
      widget.appState.addStars(1);
      widget.appState.addXp(5);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) showLumoRewardBurst(context, stars: 1, xp: 5);
    }
  }

  void _showFinish() {
    // Bei abgeschlossener Story: auto in Bibliothek speichern wenn neu
    if (widget.storyId == null) {
      LumoStoryLibrary.instance.addStory(widget.story);
    }
    showDialog(
      context: context,
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
                Icon(Icons.save_rounded,
                    color: LumoTokens.colors.successDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Heft in deine Bibliothek gespeichert!',
                      style: LumoTokens.typo.bodyMedium.copyWith(
                          color: LumoTokens.colors.successDeep)),
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
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Reader
              Navigator.push(
                context,
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
              Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        intensity: 0.6,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _inSummaryMode
                    ? _buildSummaryPage()
                    : _buildPage(page),
              ),
              _inSummaryMode ? _buildSummaryBottomNav() : _buildBottomNav(page),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LumoTokens.space12,
          LumoTokens.space8,
          LumoTokens.space12,
          LumoTokens.space8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(widget.story.title,
                    style: LumoTokens.typo.titleLarge,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_pageIdx + 1) / widget.story.pages.length,
                    minHeight: 6,
                    backgroundColor: LumoTokens.colors.outline,
                    valueColor: AlwaysStoppedAnimation(
                        LumoTokens.colors.lumoOrange),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.volume_up_rounded,
                color: LumoTokens.colors.lumoOrange),
            onPressed: _speak,
          ),
        ],
      ),
    );
  }

  Widget _buildPage(LumoStoryPage page) {
    final imgUrl =
        LumoImageGenerator.instance.buildSafeImageUrl(page.imagePrompt);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: Column(
        children: [
          // Bild
          AspectRatio(
            aspectRatio: 1,
            child: LumoPremiumCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: LumoTokens.brLarge,
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) {
                          if (p == null) return child;
                          // Vorher: kleines Indicator-Spin in cremeDeep
                          // Container - sah aus wie leerer weisser Bereich
                          // (Heinz' Screenshot). Jetzt: deutlicher Gradient
                          // mit grossem Buch-Emoji + Text "Lumo malt das Bild".
                          return Container(
                            decoration: BoxDecoration(
                                gradient: LumoTokens.colors.bgMagic),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📖',
                                    style: TextStyle(fontSize: 64)),
                                const SizedBox(height: 12),
                                Text('Lumo malt das Bild...',
                                    style: LumoTokens.typo.titleMedium
                                        .copyWith(color: Colors.white)),
                                const SizedBox(height: 12),
                                const CircularProgressIndicator(
                                    color: Colors.white),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                              gradient: LumoTokens.colors.bgMagic),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📖',
                                  style: TextStyle(fontSize: 80)),
                              const SizedBox(height: 8),
                              Text('Bild konnte nicht laden',
                                  style: LumoTokens.typo.bodyMedium
                                      .copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                            gradient: LumoTokens.colors.bgMagic),
                        alignment: Alignment.center,
                        child: const Text('📖',
                            style: TextStyle(fontSize: 80)),
                      ),
              ),
            ),
          ),
          const SizedBox(height: LumoTokens.space16),
          // Seitenzahl
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: LumoTokens.colors.lumoOrange.withOpacity(0.15),
              borderRadius: LumoTokens.brPill,
            ),
            child: Text('Seite ${page.pageNum} / ${widget.story.pages.length}',
                style: LumoTokens.typo.labelMedium.copyWith(
                    color: LumoTokens.colors.lumoOrangeDeep)),
          ),
          const SizedBox(height: LumoTokens.space12),
          // Lese-Text
          LumoPremiumCard(
            child: Text(
              page.text,
              style: LumoTokens.typo.bodyLarge.copyWith(
                fontSize: 18,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Lern-Stop nach jeder 2. Seite
          if (page.exercise != null) ...[
            const SizedBox(height: LumoTokens.space16),
            _buildExerciseCard(page.exercise!),
          ],
          // Neues Wort hervorgehoben
          if (page.newWord != null) ...[
            const SizedBox(height: LumoTokens.space12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LumoTokens.colors.heroLila,
                borderRadius: LumoTokens.brPill,
              ),
              child: Text('Neues Wort: ${page.newWord!}',
                  style: LumoTokens.typo.labelLarge.copyWith(
                      color: Colors.white)),
            ),
          ],
        ],
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
              style: LumoTokens.typo.titleLarge.copyWith(
                  color: Colors.white, fontSize: 20),
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
                if (_exerciseDone && isSel) {
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
                        style: LumoTokens.typo.titleLarge.copyWith(
                            color: LumoTokens.colors.textDark)),
                  ),
                );
              }).toList(),
            )
          else
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
          onPressed: canContinue ? _nextPage : null,
          icon: Icon(_pageIdx + 1 >= widget.story.pages.length
              ? Icons.celebration_rounded
              : Icons.arrow_forward_rounded),
          label: Text(_pageIdx + 1 >= widget.story.pages.length
              ? 'Erzähl mir die Geschichte!'
              : 'Weiterlesen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LumoTokens.colors.lumoOrange,
            foregroundColor: Colors.white,
            textStyle: LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
            shape: RoundedRectangleBorder(
                borderRadius: LumoTokens.brLarge),
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
                    hintText: 'Tipp hier deine Zusammenfassung ein oder drück "Sprechen"...',
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
                onPressed: _showFinish,
                icon: const Icon(Icons.celebration_rounded),
                label: const Text('Fertig!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoTokens.colors.lumoOrange,
                  foregroundColor: Colors.white,
                  textStyle:
                      LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: LumoTokens.brLarge),
                ),
              )
            : ElevatedButton.icon(
                onPressed: _evaluateSummary,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Bewertung holen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoTokens.colors.lumoLila,
                  foregroundColor: Colors.white,
                  textStyle:
                      LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: LumoTokens.brLarge),
                ),
              ),
      ),
    );
  }
}
