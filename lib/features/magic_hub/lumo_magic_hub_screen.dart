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
import '../../widgets/design/lumo_design_system.dart';
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
  LearningProfileLease? _owner;
  int? _loadingGeneration;
  int _loadSerial = 0;
  String _childName = 'Freund';

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_profileChanged);
    _loadCompanion();
  }

  @override
  void didUpdateWidget(covariant LumoMagicHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      oldWidget.appState.removeListener(_profileChanged);
      widget.appState.addListener(_profileChanged);
      _loadSerial++;
      _loadingGeneration = null;
      _owner = null;
      _profileChanged();
    }
  }

  void _profileChanged() {
    if (!mounted) return;
    final owner = _owner;
    if (owner != null && widget.appState.isCurrentLearningLease(owner)) {
      _applyCompanion(owner);
      return;
    }
    setState(() {
      _owner = null;
      _greeting = 'Hallo! Ich lade deinen Lernstand.';
      _mood = LumoMirrorMood.happy;
      _streakDays = _correctToday = 0;
    });
    _loadCompanion();
  }

  void _applyCompanion(LearningProfileLease owner) {
    if (owner.profile.hasUnsavedChanges) return;
    final state = LumoCompanionState.fromProfile(
        profile: owner.profile, childName: _childName);
    setState(() {
      _greeting = state.smartGreeting();
      _mood = state.smartMood();
      _streakDays = state.streakDays;
      _correctToday = state.correctToday;
    });
  }

  Future<void> _loadCompanion() async {
    final app = widget.appState;
    final generation = app.profileGeneration;
    if (_loadingGeneration == generation) return;
    _loadingGeneration = generation;
    final serial = ++_loadSerial;
    try {
      final owner = await app.captureLearningProfile();
      final local = app.school.cachedActiveStudentId == null;
      final name = local
          ? app.state.childName
          : await app.school.studentName(owner.studentId) ?? 'Freund';
      await app.prepareLearningLease(owner);
      if (!mounted ||
          serial != _loadSerial ||
          !app.isCurrentLearningLease(owner)) return;
      _owner = owner;
      _childName = name;
      _applyCompanion(owner);
    } catch (_) {
      if (mounted && serial == _loadSerial) {
        setState(() =>
            _greeting = 'Dein Lernstand konnte noch nicht geladen werden.');
      }
    } finally {
      if (serial == _loadSerial) _loadingGeneration = null;
    }
  }

  @override
  void dispose() {
    _loadSerial++;
    widget.appState.removeListener(_profileChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return Scaffold(
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LumoTokens.space16,
                LumoTokens.space8, LumoTokens.space16, LumoTokens.space32),
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
              // Der 3D-Lumo bleibt die visuelle Hauptfigur. Der kleine
              // Reaktionsspiegel zeigt die bestehenden acht Emotionen weiter,
              // statt die Mood-Logik beim Umbau zu verlieren.
              Center(
                child: SizedBox(
                  width: 184,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const LumoFoxPose(
                        pose: LumoDesignFoxPose.armsOpen,
                        size: 176,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Semantics(
                          label: 'Lumos aktuelle Stimmung',
                          child: LumoMirror(mood: _mood, size: 58),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LumoTokens.space12),
              // Smarte Begruessung
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(_greeting,
                      style: LumoTokens.typo.headlineSmall
                          .copyWith(color: LumoTokens.colors.textDark),
                      textAlign: TextAlign.center),
                ),
              ),
              // Streak Pill
              if (_streakDays >= 2) ...[
                const SizedBox(height: LumoTokens.space12),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            style: LumoTokens.typo.titleMedium
                                .copyWith(color: Colors.white)),
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
                    builder: (_) => LumoStoryLibraryScreen(appState: appState),
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
                    builder: (_) => LumoCosmosScreen(appState: widget.appState),
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

/// Public, stable route to the existing 1992 Mirror studio.
/// Keep the original stateful interaction and its eight emotion variants.
class LumoMirrorShowcaseScreen extends StatelessWidget {
  const LumoMirrorShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LumoMirrorShowcase();
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
    final moodLabel = _moodLabel(_mood);
    return Scaffold(
      backgroundColor: const Color(0xFF102841),
      body: LumoMagicBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 380;
            final cols = constraints.maxWidth >= 700 ? 4 : 2;
            return ListView(
              key: const PageStorageKey<String>('lumo-mirror-studio'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    tooltip: 'Zurück',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lumo Mirror',
                        style: TextStyle(color: Colors.white,
                            fontFamily: 'Nunito', fontSize: 22,
                            fontWeight: FontWeight.w900)),
                      Text('Entdecke Lumos Gefühle',
                        style: TextStyle(color: Color(0xFFD6EAF4),
                            fontFamily: 'Nunito', fontSize: 13)),
                    ],
                  )),
                ]),
                const SizedBox(height: 14),
                Container(
                  key: const ValueKey('mirror-avatar-stage'),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF153B69), Color(0xFF5B3887)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF85DBF8).withOpacity(.65)),
                  ),
                  child: Column(children: [
                    SizedBox(
                      height: narrow ? 205 : 240,
                      child: Stack(alignment: Alignment.center, children: [
                        LumoFoxPose(
                          pose: LumoDesignFoxPose.armsOpen,
                          size: narrow ? 160 : 192,
                        ),
                        Positioned(
                          bottom: 0,
                          right: narrow ? 12 : 45,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              final pos = details.localPosition;
                              setState(() => _lookAt = Offset(
                                ((pos.dx - 60) / 60).clamp(-1.0, 1.0),
                                ((pos.dy - 60) / 60).clamp(-1.0, 1.0),
                              ));
                            },
                            child: LumoMirror(
                              mood: _mood,
                              size: 116,
                              isSpeaking: _speaking,
                              lookAt: _lookAt,
                              onTap: () => setState(
                                () => _speaking = !_speaking),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Text(moodLabel,
                      key: const ValueKey('mirror-active-mood'),
                      style: const TextStyle(color: Colors.white,
                          fontFamily: 'Nunito', fontWeight: FontWeight.w900,
                          fontSize: 21)),
                    const SizedBox(height: 6),
                    Text(_moodHint(_mood),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFE0EAF7),
                          fontFamily: 'Nunito', fontSize: 14)),
                  ]),
                ),
                const SizedBox(height: 18),
                const Text('Wie soll Lumo reagieren?',
                    style: TextStyle(fontFamily: 'Nunito',
                        color: Colors.white, fontSize: 19,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text('Wähle eine Stimmung. Die Animation reagiert sofort.',
                    style: TextStyle(fontFamily: 'Nunito',
                        color: Color(0xFFD6EAF4), fontSize: 13)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, width) {
                  const gap = 10.0;
                  final itemWidth = (width.maxWidth - (cols - 1) * gap) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final mood in LumoMirrorMood.values)
                        SizedBox(
                          width: itemWidth,
                          height: 56,
                          child: Semantics(
                            selected: mood == _mood,
                            child: Material(
                              color: mood == _mood
                                  ? const Color(0xFFF27632)
                                  : const Color(0xFF173858),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                key: ValueKey('mirror-mood-${mood.name}'),
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(() {
                                  _mood = mood;
                                  _lookAt = null;
                                }),
                                child: Center(
                                  child: Text(_moodLabel(mood),
                                    style: const TextStyle(
                                      fontFamily: 'Nunito', color: Colors.white,
                                      fontWeight: FontWeight.w900, fontSize: 15)),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _moodHint(LumoMirrorMood mood) {
    switch (mood) {
      case LumoMirrorMood.idle:
        return 'Ganz ruhig. Wir können in deinem Tempo starten.';
      case LumoMirrorMood.happy:
        return 'Lumo freut sich mit dir.';
      case LumoMirrorMood.think:
        return 'Zeit, gemeinsam nachzudenken.';
      case LumoMirrorMood.cheer:
        return 'Ein guter Grund zum Jubeln!';
      case LumoMirrorMood.sad:
        return 'Auch traurige Gefühle dürfen da sein.';
      case LumoMirrorMood.curious:
        return 'Neugierig? Es gibt noch viel zu entdecken.';
      case LumoMirrorMood.proud:
        return 'Du kannst stolz auf deine Fortschritte sein.';
      case LumoMirrorMood.sleepy:
        return 'Eine Pause ist manchmal genau richtig.';
    }
  }

  String _moodLabel(LumoMirrorMood m) {
    switch (m) {
      case LumoMirrorMood.idle:
        return 'Ruhig';
      case LumoMirrorMood.happy:
        return 'Glücklich';
      case LumoMirrorMood.think:
        return 'Denkt';
      case LumoMirrorMood.cheer:
        return 'Jubel!';
      case LumoMirrorMood.sad:
        return 'Traurig';
      case LumoMirrorMood.curious:
        return 'Neugierig';
      case LumoMirrorMood.proud:
        return 'Stolz';
      case LumoMirrorMood.sleepy:
        return 'Müde';
    }
  }
}
