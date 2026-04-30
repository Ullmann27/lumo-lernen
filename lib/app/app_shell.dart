import 'package:flutter/material.dart';
import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../widgets/shell/left_navigation.dart';
import '../widgets/shell/lumo_stage_panel.dart';
import '../features/home/home_content.dart';
import '../features/learning/learning_content.dart';
import '../features/learning/subject_selection_content.dart';
import '../features/sections/section_content.dart';
import '../features/settings/settings_content.dart';
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

  void _navigateTo(LumoSection section) async {
    if (_appState.state.section == section) return;
    if (section == LumoSection.profile || section == LumoSection.settings) {
      final ok = await ParentalGate.show(context);
      if (!mounted || !ok) return;
    }
    await _fadeCtrl.reverse();
    _appState.setSection(section);
    final settings = _appState.state.settings;
    if (settings.voiceEnabled && settings.autoReadEnabled) {
      LumoVoice.instance.speak(_appState.state.lumoMessage.replaceAll('\n', ' '));
    }
    if (mounted) await _fadeCtrl.forward();
  }

  Widget _buildContent() {
    final section = _appState.state.section;
    switch (section) {
      case LumoSection.home:
        return HomeContent(appState: _appState, onSection: _navigateTo);
      case LumoSection.learn:
        return SubjectSelectionContent(appState: _appState, onSection: _navigateTo);
      case LumoSection.exercises:
        return LearningContent(appState: _appState);
      case LumoSection.scanner:
        if (!_appState.state.settings.scannerEnabled) {
          return SettingsContent(appState: _appState);
        }
        return ScanScreen(
          onTextDetected: (text) {
            _appState.update(_appState.state.copyWith(
              lumoMessage: 'Ich hab die\nAufgabe gelesen!\nLos gehts!',
              mood: LumoMood.celebrate,
            ));
            if (_appState.state.settings.voiceEnabled) {
              LumoVoice.instance.speak('Super! Ich habe deine Aufgabe gelesen. Lass uns gemeinsam üben.');
            }
            _navigateTo(LumoSection.exercises);
          },
          onCancel: () => _navigateTo(LumoSection.home),
        );
      case LumoSection.profile:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ProfileScreen(
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
                final showNav = width >= 720;
                final showStage = width >= 860;
                final navWidth = width < 980 ? 160.0 : 200.0;
                final gap = width < 980 ? 6.0 : 10.0;

                return Padding(
                  padding: EdgeInsets.all(width < 720 ? 6 : 10),
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
                            child: FadeTransition(opacity: _fadeCtrl, child: _buildContent()),
                          ),
                        ),
                      ),
                      if (showStage) ...[
                        SizedBox(width: gap),
                        LumoStagePanel(
                          appState: _appState,
                          onFoxTap: () {
                            if (_appState.state.settings.voiceEnabled) {
                              LumoVoice.instance.speak(_appState.state.lumoMessage.replaceAll('\n', ' '));
                            }
                          },
                        ),
                      ],
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
