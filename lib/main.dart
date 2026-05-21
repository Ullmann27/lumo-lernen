import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_shell.dart';
import 'app/app_theme.dart';
import 'core/lumo_error_log.dart';
import 'core/profile_repository.dart';
import 'core/user_profile.dart';
import 'features/onboarding/lumo_onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Globaler Fehler-Logger: faengt jeden Widget-Crash ein, speichert die
  // letzten 20 in SharedPreferences. Heinz kann sie im Eltern-Bereich
  // unter "Fehlerprotokoll" einsehen und an Claude weiterleiten.
  // Statt nur einem nichtssagenden roten Screen sieht das Kind ein
  // freundliches Fallback-Widget mit Zurueck-Knopf.
  await LumoErrorLog.instance.hydrate();
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    LumoErrorLog.instance.record(details);
    if (defaultOnError != null) defaultOnError(details);
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _LumoFallbackErrorWidget(details: details);
  };

  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const LumoApp());
}

/// Kinderfreundliches Fallback-Widget, das den hartcodierten roten
/// Flutter-Crashscreen ersetzt. Zeigt eine ruhige Karte mit Lumo-Emoji
/// und einem kurzen Text. Den vollen Stacktrace gibt es im
/// Eltern-Bereich unter "Fehlerprotokoll".
class _LumoFallbackErrorWidget extends StatelessWidget {
  const _LumoFallbackErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final isDebug = kDebugMode;
    return Material(
      color: const Color(0xFFFFF6EE),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🦊', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 14),
              const Text(
                'Hier hat Lumo eine Pause gebraucht.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tippe oben links zurueck zur Startseite.\nDeine Fortschritte sind sicher.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              if (isDebug) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480, maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
    UserProfile? profile;
    try {
      profile = await _repo.loadProfile();
    } catch (_) {
      // Beschädigte lokale Daten dürfen den App-Start nie blockieren.
      profile = null;
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _finishOnboarding(UserProfile profile) async {
    final cleanProfile = profile.normalized();
    try {
      await _repo.saveProfile(cleanProfile);
    } catch (_) {
      // Auch wenn Speichern fehlschlägt, darf das Kind nicht im Onboarding hängen bleiben.
    }
    if (!mounted) return;
    setState(() => _profile = cleanProfile);
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
