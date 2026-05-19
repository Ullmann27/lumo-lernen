import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../widgets/shell/left_navigation.dart';
import '../widgets/fox/lumo_free_companion.dart';
import '../features/agent/lumo_agent_content.dart';
import '../features/games/games_content.dart';
import '../features/home/home_content.dart';
import '../features/learning/learning_content.dart';
import '../features/reading/reading_content.dart';
import '../features/shared/widgets/lumo_section_transition.dart';
import '../features/sections/section_content.dart';
import '../features/settings/settings_content.dart';
import '../features/shared/widgets/lumo_premium_effects.dart';
import '../widgets/scan_screen.dart';
import '../widgets/profile_screen.dart';
import '../widgets/parental_gate.dart';
import '../core/lumo_voice.dart';
import '../core/settings_repository.dart';
import '../core/user_profile.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.profile});

  final UserProfile? profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  final _appState = LumoAppState();

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    if (profile != null) {
      _appState.update(_appState.state.copyWith(
        childName: profile.name,
        grade: profile.grade,
        lumoMessage: 'Hallo ${profile.name}!\nWomit wollen wir\nheute lernen?',
      ));
    }
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsRepository.load();
    if (!mounted) return;
    _appState.updateSettings(settings);
    await LumoVoice.instance.configure(
      enabled: settings.voiceEnabled,
      rate: settings.voiceRate,
      pitch: settings.voicePitch,
    );
    try {
      await _appState.loadLearningProfile();
    } catch (_) {}
  }

  @override
  void dispose() {
    _appState.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  bool _isReadingMode() {
    final st = _appState.state;
    final subject = st.subject.trim().toLowerCase();
    final unit = st.unit.trim().toLowerCase();
    return subject == 'lesen' || unit == 'aktives lesen' || unit == 'vorlesen';
  }

  Future<void> _navigateTo(LumoSection section) async {
    if (_appState.state.section == section) return;
    if (section == LumoSection.profile || section == LumoSection.settings) {
      final ok = await ParentalGate.show(context);
      if (!mounted || !ok) return;
    }
    if (!mounted) return;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    _appState.setSection(section);
    final settings = _appState.state.settings;
    if (settings.voiceEnabled && settings.autoReadEnabled) {
      LumoVoice.instance.speak(_appState.state.lumoMessage.replaceAll('\n', ' '));
    }
    if (mounted) await _fadeCtrl.forward();
  }

  Future<void> _openParentSettings() async {
    final ok = await ParentalGate.show(context);
    if (!mounted || !ok) return;
    await _navigateTo(LumoSection.settings);
  }

  Future<void> _handleScannedText(String text) async {
    if (!mounted) return;
    _appState.update(_appState.state.copyWith(
      lumoMessage: 'Ich analysiere\ndeine Aufgabe\nkurz und ruhig.',
      mood: LumoMood.think,
    ));

    final analysis = await _appState.analyzeScannedWork(text);
    if (!mounted) return;

    if (_appState.state.settings.voiceEnabled) {
      LumoVoice.instance.speak(analysis.childSummary, style: analysis.hasWeaknesses ? VoiceStyle.comfort : VoiceStyle.explain);
    }

    await _fadeCtrl.reverse();
    if (!mounted) return;
    if (mounted) await _fadeCtrl.forward();
  }

  Widget _buildContent() {
    final section = _appState.state.section;
    switch (section) {
      case LumoSection.home:
        return HomeContent(appState: _appState, onSection: _navigateTo);
      case LumoSection.games:
        return GamesContent(appState: _appState);
      case LumoSection.learn:
        return SectionContent(appState: _appState, section: LumoSection.learn, onSection: _navigateTo);
      case LumoSection.exercises:
        if (_isReadingMode()) {
          return ReadingContent(appState: _appState, onBack: () => _navigateTo(LumoSection.learn));
        }
        return LearningContent(appState: _appState);
      case LumoSection.reading:
        return ReadingContent(appState: _appState, onBack: () => _navigateTo(LumoSection.learn));
      case LumoSection.agent:
        return LumoAgentContent(appState: _appState, onSection: _navigateTo);
      case LumoSection.scanner:
        if (!_appState.state.settings.scannerEnabled) {
          return _FeatureDisabledContent(
            title: 'Foto-Hilfe ist ausgeschaltet',
            message: 'Diese Funktion kann nur im Elternbereich wieder aktiviert werden.',
            icon: Icons.no_photography_rounded,
            onBack: () => _navigateTo(LumoSection.home),
            onParentSettings: _openParentSettings,
          );
        }
        return ScanScreen(
          onTextDetected: _handleScannedText,
          onCancel: () => _navigateTo(LumoSection.home),
        );
      case LumoSection.profile:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ProfileScreen(
            childName: _appState.state.childName,
            stars: _appState.state.stars,
            xp: _appState.state.xp,
            level: _appState.state.level,
            progress: _appState.state.progressPercent,
            solved: _appState.state.solved,
            practice: _appState.state.weakSkills,
            lastGrade: _appState.state.lastGrade,
          ),
        );
      case LumoSection.settings:
        return SettingsContent(appState: _appState);
      default:
        return SectionContent(appState: _appState, section: section, onSection: _navigateTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: LumoColors.appBg,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final mobile = width < 720;
                final showNav = width >= 720;
                final navWidth = width < 980 ? 160.0 : 200.0;
                final gap = width < 980 ? 6.0 : 10.0;

                if (mobile) {
                  return Column(children: [
                    _MobileLumoHeader(appState: _appState, onFoxTap: () {
                      if (_appState.state.settings.voiceEnabled) {
                        LumoVoice.instance.speak(_appState.state.lumoMessage.replaceAll('\n', ' '));
                      }
                    }),
                    Expanded(
                      child: Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(LumoRadius.lg),
                          child: FadeTransition(
                            opacity: _fadeCtrl,
                            child: LumoSectionTransition(
                              sectionKey: _appState.state.section.name,
                              child: _buildContent(),
                            ),
                          ),
                        ),
                        // Free-Companion-Overlay (Heinz: 'Lumo soll frei
                        // beweglich sein, nicht in einem Kasten gefangen.')
                        // NICHT im Lesemodus / Reading-Section anzeigen
                        // (Heinz: 'Im Lesemodus ueberdeckt Lumo die Schriften').
                        if (_appState.state.section != LumoSection.reading &&
                            !_isReadingMode())
                          const Positioned.fill(child: LumoFreeCompanion()),
                      ]),
                    ),
                    _MobileBottomNavigation(active: _appState.state.section, onSelect: _navigateTo),
                  ]);
                }

                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showNav) ...[
                        LeftNavigation(appState: _appState, onSelect: _navigateTo, width: navWidth),
                        SizedBox(width: gap),
                      ],
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(LumoRadius.xl),
                          child: Container(
                            decoration: BoxDecoration(color: LumoColors.appBg, borderRadius: BorderRadius.circular(LumoRadius.xl)),
                            // ── Stack: Content + Free-Companion-Overlay ──
                            // Heinz: 'Der rechte feste Kasten muss weg.
                            // Lumo soll frei beweglich sein.'
                            // NICHT im Lesemodus (ueberdeckt Schriften)
                            child: Stack(
                              children: [
                                FadeTransition(
                                  opacity: _fadeCtrl,
                                  child: LumoSectionTransition(
                                    sectionKey: _appState.state.section.name,
                                    child: _buildContent(),
                                  ),
                                ),
                                if (_appState.state.section !=
                                        LumoSection.reading &&
                                    !_isReadingMode())
                                  const Positioned.fill(
                                      child: LumoFreeCompanion()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FeatureDisabledContent extends StatelessWidget {
  const _FeatureDisabledContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.onBack,
    required this.onParentSettings,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onBack;
  final VoidCallback onParentSettings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFF8ED), Color(0xFFFFFFFF)])),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.lg)),
                child: Icon(icon, color: LumoColors.orange, size: 34),
              ),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: LumoTextStyles.heading2),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
              const SizedBox(height: 18),
              Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(onPressed: onBack, icon: const Icon(Icons.home_rounded), label: const Text('Zurück')),
                OutlinedButton.icon(onPressed: onParentSettings, icon: const Icon(Icons.lock_rounded), label: const Text('Elternbereich')),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MobileLumoHeader extends StatelessWidget {
  const _MobileLumoHeader({required this.appState, required this.onFoxTap});

  final LumoAppState appState;
  final VoidCallback onFoxTap;

  @override
  Widget build(BuildContext context) {
    final st = appState.state;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [LumoColors.stageBg1, LumoColors.stageBg2]),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: Colors.white.withOpacity(.72)),
        boxShadow: LumoShadow.card,
      ),
      child: Row(children: [
        // Heinz' Premium-Sprung: Lumo schwebt sanft + pulsiert mit Glow.
        // Tap startet Voice. Wirkt jetzt wie ein echter Begleiter.
        LumoFloating(
          amplitude: 3,
          duration: const Duration(milliseconds: 2800),
          child: LumoGlowPulse(
            color: LumoColors.orange,
            minBlur: 6,
            maxBlur: 18,
            child: GestureDetector(
              onTap: onFoxTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]),
                ),
                child: const Center(child: Text('🦊', style: TextStyle(fontSize: 28))),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(st.childName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
            const SizedBox(height: 2),
            Text(st.lumoMessage.replaceAll('\n', ' '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: LumoColors.ink600, height: 1.2)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('⭐ ${st.stars}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.ink700)),
          Text('Lv ${st.level}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.orange)),
        ]),
      ]),
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({required this.active, required this.onSelect});

  final LumoSection active;
  final ValueChanged<LumoSection> onSelect;

  static const _items = <_MobileNavItem>[
    _MobileNavItem(LumoSection.home, Icons.home_rounded, 'Start'),
    _MobileNavItem(LumoSection.games, Icons.sports_esports_rounded, 'Spiele'),
    _MobileNavItem(LumoSection.learn, Icons.menu_book_rounded, 'Lernen'),
    _MobileNavItem(LumoSection.reading, Icons.record_voice_over_rounded, 'Lesen'),
    _MobileNavItem(LumoSection.profile, Icons.sentiment_satisfied_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        // Premium-Look: leichter Gradient statt einfaches Weiss.
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFBF0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        border: Border.all(color: LumoColors.orange.withOpacity(.25), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.map((item) {
          final selected = item.section == active;
          return Expanded(
            child: LumoTapBounce(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(item.section);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(LumoRadius.pill),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: LumoColors.orange.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.elasticOut,
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: selected ? Colors.white : LumoColors.ink500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : LumoColors.ink500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MobileNavItem {
  const _MobileNavItem(this.section, this.icon, this.label);
  final LumoSection section;
  final IconData icon;
  final String label;
}
