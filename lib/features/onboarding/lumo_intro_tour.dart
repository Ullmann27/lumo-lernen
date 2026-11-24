import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/lumo_voice.dart';

/// Schul-Demo 24.11.2026 – Lumo-Intro.
///
/// PROTOTYP: Eine animierte Flutter-Sequenz (kein echtes Video). Sie nutzt
/// nur Lumo-Grafiken, die schon im Repo liegen (assets/lumo_design/fox/,
/// assets/lumo_design/bg/), und die vorhandene lokale Stimme
/// [LumoVoice.speak]. Kein neuer Cloud- oder Bezahldienst.
///
/// Erscheint einmal beim ersten Start, lässt sich jederzeit überspringen
/// und ist über die Startseite ("Lumo-Intro ansehen") und den
/// Elternbereich erneut erreichbar.
class LumoIntroTour extends StatefulWidget {
  const LumoIntroTour({super.key, this.speak = true});

  /// Lokale Stimme vorlesen lassen (in Tests aus).
  final bool speak;

  static const seenKey = 'lumo_intro_tour_seen_v1';

  static const steps = <LumoIntroStep>[
    LumoIntroStep(
      image: 'assets/lumo_design/fox/fox_arms_open.png',
      background: 'assets/lumo_design/bg/bg_home.png',
      title: 'Hallo, ich bin Lumo!',
      text: 'Ich bin dein Lernfreund. Ich zeige dir kurz, was wir zusammen '
          'machen können.',
    ),
    LumoIntroStep(
      image: 'assets/lumo_design/fox/fox_book_point.png',
      background: 'assets/lumo_design/bg/bg_learn.png',
      title: 'Wähle ein Fach',
      text: 'Auf der Startseite findest du Mathematik, Deutsch, Englisch und '
          'Sachkunde. Tippe auf ein Fach und dann auf ein Thema.',
    ),
    LumoIntroStep(
      image: 'assets/lumo_design/fox/fox_teacher_stick.png',
      background: 'assets/lumo_design/bg/bg_library.png',
      title: 'Ich helfe dir',
      text: 'Weißt du nicht weiter? Frag mich! Ich gebe dir zuerst einen '
          'kleinen Tipp und erkläre es dann Schritt für Schritt.',
    ),
    LumoIntroStep(
      image: 'assets/lumo_design/fox/fox_trophy_wink.png',
      background: 'assets/lumo_design/bg/bg_tests.png',
      title: 'Sammle Sterne',
      text: 'Für jede richtige Aufgabe bekommst du Sterne. Damit schaltest du '
          'Belohnungen und Lumo Cards frei.',
    ),
    LumoIntroStep(
      image: 'assets/lumo_design/fox/fox_kart_wave.png',
      background: 'assets/lumo_design/bg/bg_kart.png',
      title: 'Und dann: Spielen!',
      text: 'Unter Spiele warten Lumo Kart, Memory und mehr. Los geht’s!',
    ),
  ];

  /// Erster Start: Intro zeigen, wenn es noch nie gesehen wurde.
  /// In Widget-Tests (FLUTTER_TEST) bleibt es aus, damit bestehende
  /// Prüfungen ihre Startseite unverändert vorfinden.
  static Future<void> maybeShowFirstRun(BuildContext context) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(seenKey) ?? false) return;
    if (!context.mounted) return;
    await show(context);
  }

  /// Intro öffnen (auch erneut aus Startseite/Elternbereich).
  static Future<void> show(BuildContext context, {bool speak = true}) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => LumoIntroTour(speak: speak),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKey, true);
  }

  @override
  State<LumoIntroTour> createState() => _LumoIntroTourState();
}

class LumoIntroStep {
  const LumoIntroStep({
    required this.image,
    required this.background,
    required this.title,
    required this.text,
  });

  final String image;
  final String background;
  final String title;
  final String text;
}

class _LumoIntroTourState extends State<LumoIntroTour>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (!reduce) _bounce.repeat(reverse: true);
      _speakCurrent();
    });
  }

  @override
  void dispose() {
    _bounce.dispose();
    if (widget.speak) unawaited(LumoVoice.instance.stop());
    super.dispose();
  }

  void _speakCurrent() {
    if (!widget.speak) return;
    final step = LumoIntroTour.steps[_index];
    unawaited(LumoVoice.instance
        .speak('${step.title} ${step.text}')
        .catchError((Object _) {}));
  }

  void _next() {
    if (_index >= LumoIntroTour.steps.length - 1) {
      _close();
      return;
    }
    setState(() => _index++);
    _speakCurrent();
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
    _speakCurrent();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final step = LumoIntroTour.steps[_index];
    final last = _index == LumoIntroTour.steps.length - 1;
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final foxHeight =
        (landscape ? size.height * .48 : size.height * .32).clamp(120.0, 320.0);

    final fox = AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -10 * Curves.easeInOut.transform(_bounce.value)),
        child: child,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Image.asset(
          step.image,
          key: ValueKey(step.image),
          height: foxHeight,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Text('🦊', style: TextStyle(fontSize: foxHeight * .6)),
        ),
      ),
    );

    final card = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween(begin: const Offset(.15, 0), end: Offset.zero)
            .animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey('intro-card-$_index'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xEE0A2852),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6FE3FF), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(step.text,
                style: const TextStyle(
                    color: Color(0xFFE6F4FF), fontSize: 18, height: 1.35)),
          ],
        ),
      ),
    );

    return Scaffold(
      key: const ValueKey('lumo-intro-tour'),
      body: Stack(fit: StackFit.expand, children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Image.asset(step.background,
              key: ValueKey(step.background),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0A2852))),
        ),
        const ColoredBox(color: Color(0x66000000)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Semantics(
                  label: 'Schritt ${_index + 1} von '
                      '${LumoIntroTour.steps.length}',
                  child: Row(children: [
                    for (var i = 0; i < LumoIntroTour.steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _index ? 26 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? const Color(0xFFFFD54F)
                              : Colors.white54,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                  ]),
                ),
                const Spacer(),
                TextButton(
                  key: const ValueKey('intro-skip'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(96, 48),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _close,
                  child: const Text('Überspringen',
                      style: TextStyle(fontSize: 17)),
                ),
              ]),
              Expanded(
                child: landscape
                    ? Row(children: [
                        Expanded(flex: 2, child: Center(child: fox)),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: Center(child: card)),
                      ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [fox, const SizedBox(height: 16), card],
                      ),
              ),
              Row(children: [
                if (_index > 0)
                  OutlinedButton.icon(
                    key: const ValueKey('intro-back'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 56),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Zurück'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('intro-next'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 56),
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: const Color(0xFF1A1A1A),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _next,
                  icon: Icon(
                      last ? Icons.check_rounded : Icons.arrow_forward_rounded),
                  label: Text(last ? 'Los geht’s' : 'Weiter'),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
