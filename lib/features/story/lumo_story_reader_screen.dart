// ════════════════════════════════════════════════════════════════════════
// LUMO STORY READER — Lese-Heft mit Live-Bildern + Lern-Stops
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_image_generator.dart';
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

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _speak() {
    try {
      LumoVoice.instance.speak(widget.story.pages[_pageIdx].text);
    } catch (_) {}
  }

  void _nextPage() {
    if (_pageIdx + 1 >= widget.story.pages.length) {
      _showFinish();
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
              Expanded(child: _buildPage(page)),
              _buildBottomNav(page),
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
                          return Container(
                            color: LumoTokens.colors.cremeDeep,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                              gradient: LumoTokens.colors.bgMagic),
                          alignment: Alignment.center,
                          child: const Text('📖',
                              style: TextStyle(fontSize: 80)),
                        ),
                      )
                    : Container(
                        color: LumoTokens.colors.cremeDeep,
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
              ? 'Geschichte beenden!'
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
}
