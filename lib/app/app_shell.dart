import 'dart:async';

import 'package:flutter/material.dart';
import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../widgets/shell/left_navigation.dart';
import 'lumo_companion_host.dart';
import '../widgets/fox/lumo_companion_requests.dart';
import '../core/lumo_asset_paths.dart';
import '../features/companion/lumo_lottie.dart';
import '../features/agent/lumo_agent_content.dart';
import '../features/games/games_content.dart';
import '../features/home/home_content.dart';
import '../features/teacher_mode/lumo_akademie_screen.dart';
import '../features/tests/lumo_tests_screen.dart';
import '../features/learning/learning_content.dart';
import '../features/reading/reading_content.dart';
import '../features/shared/widgets/lumo_section_transition.dart';
import '../features/sections/section_content.dart';
import '../features/settings/settings_content.dart';
import '../widgets/scan_screen.dart';
import '../widgets/profile_screen.dart';
import '../core/achievements/achievement_tracker.dart';
import '../core/achievements/lumo_achievement.dart';
import '../core/lumo_ai_proxy_client.dart';
import '../core/lumo_companion_agent.dart';
import '../core/lumo_voice.dart';
import '../core/user_profile.dart';
import '../core/embedded_game_service.dart';
import '../widgets/design/lumo_design_system.dart';
import '../theme/lumo_visual_tokens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.profile, this.initialSection});

  final UserProfile? profile;

  /// Optionale Start-Sektion. Wenn die App ueber einen Deep-Link vom
  /// Godot-3D-Hub (lumolernen://open?section=...) cold-startet, landet
  /// hier z.B. LumoSection.learn - der Shell oeffnet dann direkt den
  /// Lern-Bereich statt das Home.
  final LumoSection? initialSection;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _appState = LumoAppState();
  late final _embeddedGames = EmbeddedGameService(
    appState: _appState,
    onDestination: (section) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      _navigateTo(section);
    },
  );

  // Aggressiver Warmup-Layer (Heinz Screenshot 2026-05-21:
  // 'Verbindung zum KI-Server nicht moeglich'). Render Free-Tier
  // schlaeft nach 15min ein. Wir halten ihn wach solange die App
  // im Vordergrund ist.
  final _proxyClient = const LumoAiProxyClient();
  Timer? _keepAliveTimer;
  StreamSubscription<LumoAchievement>? _achievementSubscription;

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final profile = widget.profile;
    if (profile != null) {
      // 2026-06-04: LumoCompanionAgent angeschlossen. Vorher war die Greeting
      // statisch ('Hallo X! Womit wollen wir heute lernen?'). Jetzt nutzt
      // Lumo seine event-basierte Persoenlichkeits-Engine (12+ Reaktionen
      // wie 'mission_start', 'success_streak', 'wrong_3'). Greeting kommt
      // aus reactToEvent('app_opened') + Personalisierung mit Kindernamen.
      const agent = LumoCompanionAgent();
      final greeting =
          'Hallo ${profile.name}!\n${agent.reactToEvent('app_opened')}';
      _appState.update(
        _appState.state.copyWith(
          childName: profile.name,
          grade: profile.grade,
          lumoMessage: greeting,
        ),
      );
    }
    // Deep-Link vom Godot-Hub: direkt in die angefragte Section springen.
    final deepSection = widget.initialSection;
    if (deepSection != null && deepSection != _appState.state.section) {
      if (_requiresLoadedSettings(deepSection)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigateTo(deepSection);
        });
      } else {
        _appState.update(_appState.state.copyWith(section: deepSection));
      }
    }
    _loadSettings();
    _embeddedGames.start();
    // 2026-06-04: Achievement-Tracker hydrieren + Unlock-Toast-Listener.
    _hydrateAchievements();
    _appState.addListener(_syncAchievementMetrics);
  }

  /// 2026-06-04: Lumo Achievements Live-System. Tracker laed Persistence
  /// und bindet einen Unlock-Stream-Listener, der bei jedem freigeschalteten
  /// Achievement einen prominenten Toast/Burst zeigt.
  Future<void> _hydrateAchievements() async {
    await AchievementTracker.instance.hydrate();
    if (!mounted) return;
    _achievementSubscription =
        AchievementTracker.instance.unlockStream.listen(_onAchievementUnlock);
    // Initialen Sterne-Counter syncen (sofort beim Start damit Stars-Achievements
    // greifen wenn das Kind ohne Aktion schon X Sterne im Wallet hat).
    _syncAchievementMetrics();
  }

  void _syncAchievementMetrics() {
    final stars = _appState.state.stars;
    AchievementTracker.instance.setMetric(AchievementMetric.starsTotal, stars);
  }

  void _onAchievementUnlock(LumoAchievement a) {
    if (!mounted) return;
    // 2026-06-05 Iter 16/A2: Full-screen Star-Burst-Lottie als visueller Pop.
    // Wird ueber Navigator.push als transparente Page-Route gepusht und
    // automatisch nach 1500 ms wieder gepoppt. Lottie + Emoji + Achievement-
    // Titel zusammen = befriedigendes Belohnungs-Feedback.
    _showAchievementBurstOverlay(a);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF7C2D12),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LumoRadius.lg),
        ),
        content: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(a.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 Achievement!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFCD34D),
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    a.title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.30),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '+${a.rewardStars} ★',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    await _appState.ensureSettingsLoaded();
    if (!mounted) return;
    final settings = _appState.state.settings;
    await LumoVoice.instance.configure(
      enabled: settings.voiceEnabled,
      rate: settings.voiceRate,
      pitch: settings.voicePitch,
    );
    try {
      await _appState.loadLearningProfile();
    } catch (_) {}
    // Persistente Sterne/XP laden (Heinz: 'bleibt nach Neustart')
    try {
      await _appState.hydrateFromWallet();
    } catch (_) {}
    // Sofortiger Warmup beim App-Start. Render Free-Tier schlaeft
    // nach 15min ein und braucht 30-45s zum Aufwachen - wenn das
    // Kind direkt in einen Lernmodus geht, wartet es sonst.
    _proxyClient.warmup(settings);
    _startKeepAlive();
  }

  /// Pingt den Proxy alle 14 Minuten solange die App im Vordergrund
  /// ist. Render schlaeft erst nach 15min, also bleibt der Server
  /// immer warm. Best-effort - Fehler werden geschluckt.
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 14), (_) {
      final settings = _appState.state.settings;
      if (settings.aiProxyEnabled) {
        _proxyClient.warmup(settings);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Wenn App aus Background zurueckkommt: sofort warmup +
    // Keep-Alive-Timer neu starten (im Background war er pausiert).
    if (state == AppLifecycleState.resumed) {
      final settings = _appState.state.settings;
      if (settings.aiProxyEnabled) {
        _proxyClient.warmup(settings);
      }
      _startKeepAlive();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _keepAliveTimer?.cancel();
      unawaited(LumoVoice.instance.stop());
    }
  }

  /// 2026-06-05 Iter 16/A2: Vollbild-Overlay mit Star-Burst-Lottie bei
  /// Achievement-Unlock. Halbtransparenter schwarzer Hintergrund + grosse
  /// Lottie-Animation 240px + Badge-Emoji + Titel. Automatisch nach 1.6s
  /// gepoppt - synchron mit der SnackBar.
  void _showAchievementBurstOverlay(LumoAchievement a) {
    if (!mounted) return;
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator == null) return;
    navigator.push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => _AchievementBurstOverlay(achievement: a),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (navigator.canPop()) navigator.pop();
    });
  }

  @override
  void dispose() {
    _embeddedGames.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _keepAliveTimer?.cancel();
    _achievementSubscription?.cancel();
    _appState.removeListener(_syncAchievementMetrics);
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
    if (_requiresLoadedSettings(section)) {
      await _appState.ensureSettingsLoaded();
      if (!mounted || !_appState.settingsLoaded) return;
    }
    if (!mounted) return;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    _appState.setSection(section);
    final settings = _appState.state.settings;
    if (settings.voiceEnabled && settings.autoReadEnabled) {
      LumoVoice.instance.speak(
        _appState.state.lumoMessage.replaceAll('\n', ' '),
      );
    }
    if (mounted) await _fadeCtrl.forward();
  }

  bool _requiresLoadedSettings(LumoSection section) =>
      section == LumoSection.profile || section == LumoSection.settings;

  Future<void> _openParentSettings() => _navigateTo(LumoSection.settings);

  Future<void> _handleScannedText(String text) async {
    if (!mounted) return;
    _appState.update(
      _appState.state.copyWith(
        lumoMessage: 'Ich analysiere\ndeine Aufgabe\nkurz und ruhig.',
        mood: LumoMood.think,
      ),
    );

    final analysis = await _appState.analyzeScannedWork(text);
    if (!mounted) return;

    if (_appState.state.settings.voiceEnabled) {
      LumoVoice.instance.speak(
        analysis.childSummary,
        style: analysis.hasWeaknesses ? VoiceStyle.comfort : VoiceStyle.explain,
      );
    }

    await _fadeCtrl.reverse();
    if (!mounted) return;
    if (mounted) await _fadeCtrl.forward();
  }

  /// Bildschirme, die schon wie Heinz' Zielbilder aufgebaut sind: Die Szene
  /// liegt auf dem Handy vollflächig hinter Kopfzeile, Inhalt und Leiste.
  static LumoScene? _fullBleedScene(LumoSection section) => switch (section) {
        LumoSection.home => LumoScene.home,
        LumoSection.learn => LumoScene.learning,
        LumoSection.tests => LumoScene.tests,
        LumoSection.profile => LumoScene.profile,
        LumoSection.games => LumoScene.games,
        _ => null,
      };

  Widget _buildContent({bool fullBleed = false}) {
    final section = _appState.state.section;
    switch (section) {
      case LumoSection.home:
        return HomeContent(
            appState: _appState,
            onSection: _navigateTo,
            drawBackground: !fullBleed);
      case LumoSection.games:
        return GamesContent(
          appState: _appState,
          onSection: _navigateTo,
          onGameReturn: _embeddedGames.synchronize,
          drawBackground: !fullBleed,
        );
      case LumoSection.tests:
        return LumoTestsScreen(
            appState: _appState,
            onSection: _navigateTo,
            drawBackground: !fullBleed);
      case LumoSection.learn:
        return LumoAkademieScreen(
            appState: _appState, drawBackground: !fullBleed);
      case LumoSection.exercises:
        if (_isReadingMode()) {
          return ReadingContent(
            appState: _appState,
            onBack: () => _navigateTo(LumoSection.learn),
          );
        }
        final state = _appState.state;
        return LearningContent(
          key: ValueKey(
              '${state.grade}:${state.subject}:${state.unit}:${state.sessionKind.name}'),
          appState: _appState,
        );
      case LumoSection.reading:
        return ReadingContent(
          appState: _appState,
          onBack: () => _navigateTo(LumoSection.learn),
        );
      case LumoSection.agent:
        return LumoAgentContent(appState: _appState, onSection: _navigateTo);
      case LumoSection.scanner:
        if (!_appState.state.settings.scannerEnabled) {
          return _FeatureDisabledContent(
            title: 'Foto-Hilfe ist ausgeschaltet',
            message:
                'Diese Funktion kann nur im Elternbereich wieder aktiviert werden.',
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
        return ProfileScreen(
          appState: _appState,
          onSection: _navigateTo,
          childName: _appState.state.childName,
          grade: _appState.state.grade,
          stars: _appState.state.stars,
          xp: _appState.state.xp,
          level: _appState.state.level,
          drawBackground: !fullBleed,
        );
      case LumoSection.settings:
        return SettingsContent(appState: _appState);
      default:
        return SectionContent(
          appState: _appState,
          section: section,
          onSection: _navigateTo,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        if (!_appState.settingsLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return PopScope(
            canPop: _appState.state.section == LumoSection.home,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _navigateTo(LumoSection.home);
            },
            child: Scaffold(
              backgroundColor: LumoVisualTokens.night,
              body: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) => LumoCompanionRequests.instance
                    .requestMoveTo(event.position),
                child: LayoutBuilder(builder: (context, outer) {
                  final fullBleedScene = outer.maxWidth < 720
                      ? _fullBleedScene(_appState.state.section)
                      : null;
                  return Stack(children: [
                    if (fullBleedScene != null)
                      Positioned.fill(
                        child: LumoSceneBackground(
                          scene: fullBleedScene,
                          showPlaceholderLabel: false,
                          dimmed: true,
                        ),
                      ),
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final mobile = width < 720;
                          final showNav = width >= 720;
                          final showProgressSidebar = width >= 900 &&
                              _appState.state.section == LumoSection.home;
                          final navWidth = width < 980 ? 160.0 : 200.0;
                          final gap = width < 980 ? 6.0 : 10.0;

                          if (mobile) {
                            final fullBleed = fullBleedScene != null;
                            final content = FadeTransition(
                              opacity: _fadeCtrl,
                              child: LumoSectionTransition(
                                sectionKey: _appState.state.section.name,
                                child: _buildContent(fullBleed: fullBleed),
                              ),
                            );
                            return Column(children: [
                              _MobileLumoHeader(
                                  appState: _appState,
                                  onFoxTap: () => showLumoConversation(context,
                                      appState: _appState,
                                      onSection: _navigateTo)),
                              Expanded(
                                  child: fullBleed
                                      // Zielbild-Seiten: Lumo steht als kleiner
                                      // Fuchs in der Szene; sein Menü bietet
                                      // dieselben Hilfen wie die Leiste.
                                      ? Stack(children: [
                                          Positioned.fill(child: content),
                                          Positioned(
                                            right: 6,
                                            bottom: 4,
                                            child: LumoCompanionHost(
                                                appState: _appState,
                                                onSection: _navigateTo,
                                                floating: true),
                                          ),
                                        ])
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              LumoRadius.lg),
                                          child: content,
                                        )),
                              if (!fullBleed)
                                LumoCompanionHost(
                                    appState: _appState,
                                    onSection: _navigateTo,
                                    compact: constraints.maxHeight < 650),
                              LumoBottomNavigation(
                                  active: _appState.state.section,
                                  onSelect: _navigateTo),
                            ]);
                          }

                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showNav) ...[
                                  LeftNavigation(
                                    appState: _appState,
                                    onSelect: _navigateTo,
                                    width: navWidth,
                                  ),
                                  SizedBox(width: gap),
                                ],
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(LumoRadius.xl),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: LumoVisualTokens.night,
                                        borderRadius: BorderRadius.circular(
                                          LumoRadius.xl,
                                        ),
                                      ),
                                      child: Column(children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 10, 16, 6),
                                          child: LumoTopBar(
                                            appState: _appState,
                                            onTapStatus: () =>
                                                showLumoConversation(
                                              context,
                                              appState: _appState,
                                              onSection: _navigateTo,
                                            ),
                                            onTapFox: () =>
                                                showLumoConversation(
                                              context,
                                              appState: _appState,
                                              onSection: _navigateTo,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: FadeTransition(
                                                  opacity: _fadeCtrl,
                                                  child: LumoSectionTransition(
                                                    sectionKey: _appState
                                                        .state.section.name,
                                                    child: _buildContent(),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 10,
                                                bottom: 10,
                                                child: LumoCompanionHost(
                                                  appState: _appState,
                                                  onSection: _navigateTo,
                                                  compact: true,
                                                  floating: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                ),
                                if (showProgressSidebar) ...[
                                  SizedBox(width: gap),
                                  LumoFoldProgressPanel(
                                    appState: _appState,
                                    onOpenRewards: () =>
                                        _navigateTo(LumoSection.rewards),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ]);
                }),
              ),
            ));
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
            decoration: lumoCard(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8ED), Color(0xFFFFFFFF)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: LumoColors.orangeSurface,
                    borderRadius: BorderRadius.circular(LumoRadius.lg),
                  ),
                  child: Icon(icon, color: LumoColors.orange, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: LumoTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: LumoTextStyles.body.copyWith(color: LumoColors.ink700),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Zurück'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onParentSettings,
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('Elternbereich'),
                    ),
                  ],
                ),
              ],
            ),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: LumoTopBar(
          appState: appState,
          onTapStatus: onFoxTap,
          onTapFox: onFoxTap,
        ),
      );
}

// 2026-06-05 Iter 16/A2: Achievement-Burst-Overlay
// Vollbild-transparente Page mit Lottie + Emoji + Titel als Belohnungs-Pop.
class _AchievementBurstOverlay extends StatelessWidget {
  const _AchievementBurstOverlay({required this.achievement});

  final LumoAchievement achievement;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LumoLottie(asset: LumoAssetPaths.lottieStarBurst, size: 260),
                  Text(achievement.emoji, style: const TextStyle(fontSize: 92)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                achievement.title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
