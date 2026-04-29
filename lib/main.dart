import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_shell.dart';
import 'app/app_theme.dart';
import 'core/profile_repository.dart';
import 'core/user_profile.dart';
import 'features/onboarding/lumo_onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const LumoApp());
}

class LumoApp extends StatefulWidget {
  const LumoApp({super.key});

  @override
  State<LumoApp> createState() => _LumoAppState();
}

class _LumoAppState extends State<LumoApp> {
  final _repo = ProfileRepository();
  bool _loading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _repo.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _finishOnboarding(UserProfile profile) async {
    await _repo.saveProfile(profile);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_loading) {
      home = const Scaffold(
        backgroundColor: Color(0xFFFFF6EE),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_profile == null) {
      home = LumoOnboardingScreen(onFinished: _finishOnboarding);
    } else {
      home = AppShell(profile: _profile);
    }

    return MaterialApp(
      title: 'Lumo Lernen',
      debugShowCheckedModeBanner: false,
      theme: LumoAppTheme.light(),
      home: home,
    );
  }
}
