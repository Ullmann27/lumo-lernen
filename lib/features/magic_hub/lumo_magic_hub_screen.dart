// ════════════════════════════════════════════════════════════════════════
// LUMO MAGIC HUB — Entry-Point fuer alle 4 Premium-Features
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: alle 4 Vorschlaege erreichbar in einem zentralen Menue.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/lumo_mirror.dart';
import '../../widgets/premium/lumo_hero_card.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../cosmos/lumo_cosmos_screen.dart';
import '../live/lumo_live_screen.dart';
import '../story/lumo_story_setup_screen.dart';

class LumoMagicHubScreen extends StatelessWidget {
  const LumoMagicHubScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                LumoTokens.space16,
                LumoTokens.space8,
                LumoTokens.space16,
                LumoTokens.space32),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Lumo Magic ✨',
                        style: LumoTokens.typo.headlineLarge),
                  ),
                ],
              ),
              const SizedBox(height: LumoTokens.space8),
              // Featured Lumo-Mirror Showcase
              Center(
                child: LumoMirror(
                  mood: LumoMirrorMood.happy,
                  size: 140,
                ),
              ),
              const SizedBox(height: LumoTokens.space8),
              Center(
                child: Text(
                    'Vier Wege wie ich dir helfe!',
                    style: LumoTokens.typo.headlineSmall.copyWith(
                        color: LumoTokens.colors.textDark)),
              ),
              const SizedBox(height: LumoTokens.space24),

              // 1. LUMO STORY
              LumoHeroCard(
                title: 'Lumo Story',
                subtitle: 'Lumo schreibt eine Geschichte fuer dich',
                icon: Icons.auto_stories_rounded,
                gradient: LumoTokens.colors.heroLila,
                glowColor: LumoTokens.colors.lumoLila,
                badge: 'NEU',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LumoStorySetupScreen(appState: appState),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space12),

              // 2. LUMO COSMOS
              LumoHeroCard(
                title: 'Meine Welt',
                subtitle: 'Lerne und sieh deine Welt wachsen!',
                icon: Icons.eco_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                glowColor: const Color(0xFF10B981),
                badge: 'NEU',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LumoCosmosScreen(),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space12),

              // 3. LUMO LIVE
              LumoHeroCard(
                title: 'Lumo LIVE',
                subtitle: 'Sprich oder fotografiere - Lumo lernt mit!',
                icon: Icons.mic_rounded,
                gradient: LumoTokens.colors.heroOrange,
                glowColor: LumoTokens.colors.lumoOrange,
                badge: 'NEU',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LumoLiveScreen(appState: appState),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space12),

              // 4. LUMO MIRROR (Showcase)
              LumoHeroCard(
                title: 'Lumo Mirror',
                subtitle: 'Schau mit mir wie ich reagiere!',
                icon: Icons.face_rounded,
                gradient: LumoTokens.colors.heroGold,
                glowColor: LumoTokens.colors.gold,
                badge: 'BETA',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _LumoMirrorShowcase(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirror-Showcase: alle 8 Moods anschauen + interagieren.
class _LumoMirrorShowcase extends StatefulWidget {
  const _LumoMirrorShowcase();

  @override
  State<_LumoMirrorShowcase> createState() => _LumoMirrorShowcaseState();
}

class _LumoMirrorShowcaseState extends State<_LumoMirrorShowcase> {
  LumoMirrorMood _mood = LumoMirrorMood.idle;
  Offset? _lookAt;
  bool _speaking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(LumoTokens.space12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text('Lumo Mirror',
                          style: LumoTokens.typo.headlineMedium),
                    ),
                  ],
                ),
              ),
              // Lumo zentral - reagiert auf Finger
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final size = box.size;
                      final center = Offset(size.width / 2, size.height / 2);
                      final delta = d.globalPosition - center;
                      setState(() {
                        _lookAt = Offset(
                            (delta.dx / size.width * 2).clamp(-1.0, 1.0),
                            (delta.dy / size.height * 2).clamp(-1.0, 1.0));
                      });
                    }
                  },
                  child: Center(
                    child: LumoMirror(
                      mood: _mood,
                      size: 240,
                      isSpeaking: _speaking,
                      lookAt: _lookAt,
                      onTap: () {
                        setState(() => _speaking = !_speaking);
                      },
                    ),
                  ),
                ),
              ),
              // Mood-Picker
              Padding(
                padding: const EdgeInsets.all(LumoTokens.space16),
                child: Column(
                  children: [
                    Text('Tippe einen Mood, ich reagiere!',
                        style: LumoTokens.typo.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: LumoMirrorMood.values.map((m) {
                        final active = _mood == m;
                        return GestureDetector(
                          onTap: () => setState(() => _mood = m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? LumoTokens.colors.lumoOrange
                                  : Colors.white,
                              borderRadius: LumoTokens.brPill,
                              border: Border.all(
                                  color: active
                                      ? LumoTokens.colors.lumoOrange
                                      : LumoTokens.colors.outline,
                                  width: 2),
                            ),
                            child: Text(_moodLabel(m),
                                style: LumoTokens.typo.titleMedium.copyWith(
                                    color: active
                                        ? Colors.white
                                        : LumoTokens.colors.textDark)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _moodLabel(LumoMirrorMood m) {
    switch (m) {
      case LumoMirrorMood.idle: return 'Ruhig';
      case LumoMirrorMood.happy: return 'Glücklich';
      case LumoMirrorMood.think: return 'Denkt';
      case LumoMirrorMood.cheer: return 'Jubel!';
      case LumoMirrorMood.sad: return 'Traurig';
      case LumoMirrorMood.curious: return 'Neugierig';
      case LumoMirrorMood.proud: return 'Stolz';
      case LumoMirrorMood.sleepy: return 'Müde';
    }
  }
}
