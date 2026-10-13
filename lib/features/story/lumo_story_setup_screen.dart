// ════════════════════════════════════════════════════════════════════════
// LUMO STORY SETUP — Kind waehlt Held + Ort + Thema fuer eigene Geschichte
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_story_generator.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/premium/lumo_hero_card.dart';
import '../../widgets/premium/lumo_magic_background.dart';
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
  String? _hero;
  String? _location;
  String? _theme;
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
    final story = LumoStoryGenerator.instance.generate(
      hero: _hero!,
      location: _location!,
      theme: _theme!,
      gradeLevel: _gradeLevel,
    );
    await _openReader(story);
  }

  Future<void> _surprise() async {
    final story =
        LumoStoryGenerator.instance.generateRandom(gradeLevel: _gradeLevel);
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
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(LumoTokens.space16),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Lumo erfindet dir eine Geschichte!',
                        style: LumoTokens.typo.headlineMedium),
                  ),
                ],
              ),
              const SizedBox(height: LumoTokens.space12),
              LumoHeroCard(
                title: 'Überraschung!',
                subtitle: 'Lumo wählt für dich',
                icon: Icons.casino_rounded,
                gradient: LumoTokens.colors.heroLila,
                glowColor: LumoTokens.colors.lumoLila,
                onTap: _surprise,
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
              const SizedBox(height: LumoTokens.space32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _canStart ? _startStory : null,
                  icon: const Icon(Icons.auto_stories_rounded, size: 28),
                  label: const Text('Geschichte starten!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumoTokens.colors.lumoOrange,
                    foregroundColor: Colors.white,
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
    return Row(
      children:
          (widget.initialGrade == null ? [1, 2, 3, 4] : [_gradeLevel]).map((g) {
        final active = _gradeLevel == g;
        final isPinned = widget.initialGrade != null;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: isPinned ? null : () => setState(() => _gradeLevel = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: active ? LumoTokens.colors.heroOrange : null,
                  color: active ? null : Colors.white,
                  borderRadius: LumoTokens.brMedium,
                  border: Border.all(
                    color:
                        active ? Colors.transparent : LumoTokens.colors.outline,
                    width: 2,
                  ),
                ),
                child: isPinned
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$g. Klasse',
                            style: LumoTokens.typo.titleMedium
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      )
                    : Text(
                        '$g. Klasse',
                        style: LumoTokens.typo.titleMedium.copyWith(
                          color: active
                              ? Colors.white
                              : LumoTokens.colors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ),
        );
      }).toList(),
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
              color: sel ? accent : Colors.white,
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
                    color: sel ? Colors.white : LumoTokens.colors.textDark)),
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
            .copyWith(color: LumoTokens.colors.textDark));
  }
}
