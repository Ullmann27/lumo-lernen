// ════════════════════════════════════════════════════════════════════════
// LUMO STORY SETUP — Kind waehlt Held + Ort + Thema fuer eigene Geschichte
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_story_generator.dart';
import '../../core/reading_story_memory_repository.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import 'lumo_story_library_screen.dart';
import 'lumo_story_reader_screen.dart';

class LumoStorySetupScreen extends StatefulWidget {
  const LumoStorySetupScreen({
    super.key,
    required this.appState,
    this.initialGrade,
  });
  final LumoAppState appState;
  final int? initialGrade;

  @override
  State<LumoStorySetupScreen> createState() => _LumoStorySetupScreenState();
}

class _LumoStorySetupScreenState extends State<LumoStorySetupScreen> {
  final _storyMemory = ReadingStoryMemoryRepository();
  String? _hero;
  String? _location;
  String? _theme;
  String _companion = 'Lumo';
  String _magicItem = 'Sternenkompass';
  late int _gradeLevel;

  @override
  void initState() {
    super.initState();
    _gradeLevel = (widget.initialGrade ?? widget.appState.state.grade)
        .clamp(1, 4)
        .toInt();
  }

  bool get _canStart => _hero != null && _location != null && _theme != null;

  Future<void> _startStory() async {
    // Re-use the established child/grade-isolated memory store.
    final childId = widget.appState.state.childName.trim().toLowerCase();
    final signature = [_hero!, _location!, _theme!, _companion, _magicItem]
        .map((part) => part.trim().toLowerCase())
        .join('|');
    final recent = await _storyMemory.loadRecent(
      childId: childId, grade: _gradeLevel);
    if (!mounted) return;
    final variants = recent.where((key) => key.startsWith('$signature|v'));
    final lastVariant = variants.isEmpty
        ? -1
        : int.tryParse(variants.last.split('|v').last) ?? -1;
    final variationSeed = (lastVariant + 1) % 6;
    final story = LumoStoryGenerator.instance.generateReadingAdventure(
      hero: _hero!,
      location: _location!,
      theme: _theme!,
      gradeLevel: _gradeLevel,
      companion: _companion,
      magicItem: _magicItem,
      variationSeed: variationSeed,
    );
    await _storyMemory.remember(
      childId: childId,
      grade: _gradeLevel,
      signature: '$signature|v$variationSeed',
    );
    if (!mounted) return;
    await _openReader(story);
  }

  Future<void> _surprise() async {
    final story =
        LumoStoryGenerator.instance.generateReadingAdventure(
          hero: 'Fuchs', location: 'Zauberwald', theme: 'Geheimnis',
          gradeLevel: _gradeLevel,
          variationSeed: DateTime.now().millisecondsSinceEpoch % 6);
    await _openReader(story);
  }

  Future<void> _openReader(LumoStory story) async {
    final navigator = Navigator.of(context);
    final setupRoute = ModalRoute.of(context);
    final completed = await navigator.push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LumoStoryReaderScreen(
          story: story,
          appState: widget.appState,
        ),
      ),
    );
    if (completed == true &&
        mounted &&
        setupRoute != null &&
        setupRoute.isActive) {
      // Remove only this setup route. The reader may already have opened its
      // writing coach; popping the top route would incorrectly close that.
      navigator.removeRoute(setupRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.library,
        dimmed: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(LumoTokens.space16),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: LumoVisualTokens.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Lumos Bücher und Leseabenteuer',
                        style: const TextStyle(color: LumoVisualTokens.white,
                            fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: LumoTokens.space12),
              LumoGlassCard(
                key: const ValueKey('lumo-story-creation-hero'),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      const LumoFoxPose(
                          pose: LumoDesignFoxPose.bookWelcome, size: 88),
                      const SizedBox(width: 10),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dein nächstes Abenteuer',
                            style: TextStyle(color: LumoVisualTokens.white,
                              fontSize: 18, fontWeight: FontWeight.w900)),
                          SizedBox(height: 5),
                          Text('Wähle Held, Ort und Abenteuer. Oder starte gleich ein Buch.',
                            style: TextStyle(color: LumoVisualTokens.muted,
                              fontSize: 12.5)),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      key: const ValueKey('lumo-story-surprise'),
                      onPressed: _surprise,
                      icon: const Icon(Icons.casino_rounded),
                      label: const Text('Überraschung!'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: LumoVisualTokens.cyanBright,
                        foregroundColor: LumoVisualTokens.navigation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LumoGlassCard(
                padding: const EdgeInsets.all(10),
                child: ListTile(
                  key: const ValueKey('lumo-story-open-library'),
                  leading: const Icon(Icons.auto_stories_rounded,
                      color: LumoVisualTokens.cyanBright),
                  title: const Text('Geschichten lesen',
                      style: TextStyle(color: LumoVisualTokens.white,
                          fontWeight: FontWeight.w900)),
                  subtitle: const Text('Deine gespeicherten Abenteuer öffnen',
                      style: TextStyle(color: LumoVisualTokens.muted)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: LumoVisualTokens.cyanBright),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LumoStoryLibraryScreen(
                        appState: widget.appState,
                        gradeLevel: _gradeLevel,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space24),
              // Klassenstufe
              _SectionLabel('Welche Klasse?'),
              const SizedBox(height: 8),
              _buildGradeSelector(),
              const SizedBox(height: LumoTokens.space20),
              // Held
              _SectionLabel('1. Wer ist der Held?'),
              const SizedBox(height: 8),
              _buildChips(
                LumoStoryGenerator.instance.heroOptions,
                _hero,
                (v) => setState(() => _hero = v),
                LumoTokens.colors.lumoOrange,
              ),
              const SizedBox(height: LumoTokens.space20),
              // Ort
              _SectionLabel('2. Wo passiert es?'),
              const SizedBox(height: 8),
              _buildChips(
                LumoStoryGenerator.instance.locationOptions,
                _location,
                (v) => setState(() => _location = v),
                LumoTokens.colors.lumoLila,
              ),
              const SizedBox(height: LumoTokens.space20),
              // Thema
              _SectionLabel('3. Was erleben sie?'),
              const SizedBox(height: 8),
              _buildChips(
                LumoStoryGenerator.instance.themeOptions,
                _theme,
                (v) => setState(() => _theme = v),
                LumoTokens.colors.gold,
              ),
              const SizedBox(height: LumoTokens.space20),
              const SizedBox(height: 6),
              LumoGlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: const [
                  Icon(Icons.menu_book_rounded,
                    color: LumoVisualTokens.cyanBright),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Du liest zwölf Buchseiten, löst zwei Rätsel und '
                    'beantwortest am Schluss Fragen zur ganzen Geschichte. '
                    'Lumo liest nur vor, wenn du auf den Lautsprecher tippst.',
                    style: TextStyle(color: LumoVisualTokens.white,
                      height: 1.4, fontSize: 14),
                  )),
                ]),
              ),
              const SizedBox(height: LumoTokens.space32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  key: const ValueKey('lumo-story-generate'),
                  onPressed: _canStart ? _startStory : null,
                  icon: const Icon(Icons.auto_stories_rounded, size: 28),
                  label: const Text('Geschichte starten!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumoVisualTokens.cyanBright,
                    foregroundColor: LumoVisualTokens.navigation,
                    textStyle: LumoTokens.typo.headlineSmall,
                    shape: RoundedRectangleBorder(
                        borderRadius: LumoTokens.brLarge),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeSelector() {
    final pinned = widget.initialGrade != null;
    final grades = pinned ? [_gradeLevel] : [1, 2, 3, 4];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final g in grades)
          Semantics(
            button: !pinned,
            selected: _gradeLevel == g,
            child: InkWell(
              onTap: pinned ? null : () => setState(() => _gradeLevel = g),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _gradeLevel == g
                      ? LumoVisualTokens.lessonAnswer
                      : LumoVisualTokens.navigation,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gradeLevel == g
                      ? LumoVisualTokens.cyanBright
                      : LumoVisualTokens.cyan.withValues(alpha: .5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$g. Klasse', style: const TextStyle(
                    color: LumoVisualTokens.white,
                    fontWeight: FontWeight.w800)),
                  if (pinned) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock_outline_rounded,
                        size: 18, color: LumoVisualTokens.white),
                  ],
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChips(List<String> options, String? selected,
      ValueChanged<String> onTap, Color accent) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final sel = o == selected;
        return GestureDetector(
          onTap: () => onTap(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? accent : LumoVisualTokens.navigation,
              borderRadius: LumoTokens.brPill,
              border: Border.all(
                  color: sel ? accent : accent.withOpacity(0.3), width: 2),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(o,
                style: LumoTokens.typo.titleMedium.copyWith(
                    color: LumoVisualTokens.white)),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: LumoTokens.typo.titleLarge
            .copyWith(color: LumoVisualTokens.white));
  }
}
