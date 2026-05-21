// ════════════════════════════════════════════════════════════════════════
// LUMO MAGIC HUB — Entry-Point fuer alle 4 Premium-Features
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: alle 4 Vorschlaege erreichbar in einem zentralen Menue.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_companion_state.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/lumo_mirror.dart';
import '../../widgets/premium/lumo_hero_card.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../../widgets/premium/lumo_premium_card.dart';
import '../cosmos/lumo_cosmos_screen.dart';
import '../live/lumo_live_pro_screen.dart';
import '../story/lumo_story_library_screen.dart';

class LumoMagicHubScreen extends StatefulWidget {
  const LumoMagicHubScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoMagicHubScreen> createState() => _LumoMagicHubScreenState();
}

class _LumoMagicHubScreenState extends State<LumoMagicHubScreen> {
  String _greeting = 'Hallo!';
  LumoMirrorMood _mood = LumoMirrorMood.happy;
  int _streakDays = 0;
  int _correctToday = 0;

  @override
  void initState() {
    super.initState();
    _loadCompanion();
  }

  Future<void> _loadCompanion() async {
    final state = LumoCompanionState.instance;
    // Set child name from app state if not yet set
    if (state.childName == 'Freund' &&
        widget.appState.state.childName.isNotEmpty) {
      await state.setChildName(widget.appState.state.childName);
    }
    await state.load();
    if (mounted) {
      setState(() {
        _greeting = state.smartGreeting();
        _mood = state.smartMood();
        _streakDays = state.streakDays;
        _correctToday = state.correctToday;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
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
              // Featured Lumo-Mirror Showcase mit smartem Mood
              Center(
                child: LumoMirror(
                  mood: _mood,
                  size: 140,
                ),
              ),
              const SizedBox(height: LumoTokens.space12),
              // Smarte Begruessung
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(_greeting,
                      style: LumoTokens.typo.headlineSmall.copyWith(
                          color: LumoTokens.colors.textDark),
                      textAlign: TextAlign.center),
                ),
              ),
              // Streak Pill
              if (_streakDays >= 2) ...[
                const SizedBox(height: LumoTokens.space12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LumoTokens.colors.heroGold,
                      borderRadius: LumoTokens.brPill,
                      boxShadow: [
                        BoxShadow(
                          color: LumoTokens.colors.gold.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 6),
                        Text('$_streakDays Tage Streak!',
                            style: LumoTokens.typo.titleMedium.copyWith(
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: LumoTokens.space24),

              // 1. LUMO STORY
              LumoHeroCard(
                title: 'Lumo Story',
                subtitle: 'Deine Geschichten - Bibliothek + neue erstellen',
                icon: Icons.auto_stories_rounded,
                gradient: LumoTokens.colors.heroLila,
                glowColor: LumoTokens.colors.lumoLila,
                badge: 'PRO',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LumoStoryLibraryScreen(appState: appState),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space12),

              // 2. LUMO COSMOS
              LumoHeroCard(
                title: 'Meine Welt',
                subtitle: 'Tag/Nacht + 4 Jahreszeiten + dein Garten waechst',
                icon: Icons.eco_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                glowColor: const Color(0xFF10B981),
                badge: 'PRO',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LumoCosmosScreen(),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space12),

              // 3. LUMO LIVE PRO
              LumoHeroCard(
                title: 'Lumo LIVE',
                subtitle: 'Wort-Magie · Foto-Quiz · Tier-Safari',
                icon: Icons.mic_rounded,
                gradient: LumoTokens.colors.heroOrange,
                glowColor: LumoTokens.colors.lumoOrange,
                badge: 'PRO',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LumoLiveProScreen(appState: appState),
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space12),

              // 4. LUMO MIRROR (Showcase)
              LumoHeroCard(
                title: 'Lumo Mirror',
                subtitle: '8 Emotionen + reagiert auf dich',
                icon: Icons.face_rounded,
                gradient: LumoTokens.colors.heroGold,
                glowColor: LumoTokens.colors.gold,
                badge: 'PRO',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _LumoMirrorShowcase(),
                  ),
                ),
              ),

              // Heutige Stats
              if (_correctToday > 0) ...[
                const SizedBox(height: LumoTokens.space20),
                LumoPremiumCard(
                  child: Row(children: [
                    const Icon(Icons.today_rounded,
                        color: Color(0xFF10B981), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Heute schon $_correctToday richtig!',
                              style: LumoTokens.typo.titleLarge),
                          Text('Weiter so!',
                              style: LumoTokens.typo.bodyMedium.copyWith(
                                  color: LumoTokens.colors.textMuted)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
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
