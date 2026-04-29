import 'package:flutter/material.dart';
import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../widgets/shell/left_navigation.dart';
import '../widgets/shell/lumo_stage_panel.dart';
import '../features/home/home_content.dart';
import '../features/learning/learning_content.dart';
import '../widgets/scan_screen.dart';
import '../widgets/profile_screen.dart';
import '../widgets/parental_gate.dart';
import '../core/lumo_voice.dart';
import '../core/user_profile.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.profile});

  final UserProfile? profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _appState.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _navigateTo(LumoSection section) async {
    if (_appState.state.section == section) return;
    if (section == LumoSection.profile) {
      final ok = await ParentalGate.show(context);
      if (!mounted || !ok) return;
    }
    await _fadeCtrl.reverse();
    _appState.setSection(section);
    LumoVoice.instance.speak(_appState.state.lumoMessage.replaceAll('\n', ' '));
    if (mounted) await _fadeCtrl.forward();
  }

  Widget _buildContent() {
    final section = _appState.state.section;
    switch (section) {
      case LumoSection.home:
        return HomeContent(appState: _appState, onSection: _navigateTo);
      case LumoSection.learn:
      case LumoSection.exercises:
        return LearningContent(appState: _appState);
      case LumoSection.scanner:
        return ScanScreen(
          onTextDetected: (text) {
            _appState.update(_appState.state.copyWith(
              lumoMessage: 'Ich hab die\nAufgabe gelesen!\nLos gehts!',
              mood: LumoMood.celebrate,
            ));
            LumoVoice.instance.speak('Super! Ich habe deine Aufgabe gelesen. Lass uns gemeinsam üben.');
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
      default:
        return _PlaceholderContent(section: section);
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
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LeftNavigation(appState: _appState, onSelect: _navigateTo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(LumoRadius.xl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: LumoColors.appBg,
                          borderRadius: BorderRadius.circular(LumoRadius.xl),
                        ),
                        child: FadeTransition(opacity: _fadeCtrl, child: _buildContent()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  LumoStagePanel(
                    appState: _appState,
                    onFoxTap: () => LumoVoice.instance.speak(_appState.state.lumoMessage.replaceAll('\n', ' ')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.section});
  final LumoSection section;

  String get _title {
    switch (section) {
      case LumoSection.progress:
        return 'Fortschritt';
      case LumoSection.rewards:
        return 'Belohnungen';
      default:
        return section.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 34, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
          const SizedBox(height: 14),
          Container(
            height: 300,
            decoration: lumoCard(),
            child: const Center(
              child: Text('Kommt bald! 🚀', style: TextStyle(fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w900, color: LumoColors.ink300)),
            ),
          ),
        ],
      ),
    );
  }
}
