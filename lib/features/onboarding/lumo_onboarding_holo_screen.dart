import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/user_profile.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

class LumoOnboardingScreen extends StatefulWidget {
  const LumoOnboardingScreen({super.key, required this.onFinished});
  final ValueChanged<UserProfile> onFinished;

  @override
  State<LumoOnboardingScreen> createState() => _LumoOnboardingScreenState();
}

class _LumoOnboardingScreenState extends State<LumoOnboardingScreen> {
  final _name = TextEditingController();
  int _step = 0;
  int _age = 7;
  int _grade = 1;
  bool _parentSetup = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    final now = DateTime.now();
    widget.onFinished(UserProfile(
      id: now.microsecondsSinceEpoch.toString(),
      name: _name.text.trim().isEmpty ? 'Kind' : _name.text.trim(),
      age: _age,
      grade: _grade,
      createdAt: now,
      lastActiveAt: now,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031229),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 760;
                return Padding(
                  padding: EdgeInsets.all(wide ? 24 : 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        children: [
                          _Header(
                            step: _step,
                            onBack: _step == 0 ? null : () => setState(() => _step--),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _Glass(
                              child: wide
                                  ? Row(
                                      children: [
                                        Expanded(flex: 5, child: _Hero(step: _step)),
                                        const SizedBox(width: 16),
                                        Expanded(flex: 6, child: _stepBody()),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        SizedBox(
                                          height: c.maxHeight < 700 ? 150 : 190,
                                          child: _Hero(step: _step, compact: true),
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: _stepBody(),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _Dots(current: _step),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() {
    final content = switch (_step) {
      0 => _Panel(
          eyebrow: 'Willkommen',
          title: 'Bereit für dein\nLernabenteuer?',
          subtitle: 'Lumo richtet dein Profil ein und passt Aufgaben an dich an.',
          body: const Column(
            children: [
              _Info(Icons.auto_awesome_rounded, 'Aufgaben passend zu dir'),
              SizedBox(height: 10),
              _Info(Icons.sports_esports_rounded, 'Lernen schaltet Spiele frei'),
              SizedBox(height: 10),
              _Info(Icons.star_rounded, 'Sterne, Belohnungen und Fortschritt'),
            ],
          ),
          button: "Los geht's!",
          onTap: _next,
        ),
      1 => _Panel(
          eyebrow: 'Wer richtet Lumo ein?',
          title: _parentSetup ? 'Wie heißt dein Kind?' : 'Wie heißt du?',
          subtitle: _parentSetup
              ? 'Du richtest jetzt das Kinderprofil ein. Eltern-Einstellungen bleiben später geschützt im Elternbereich.'
              : 'Lumo spricht dich dann persönlich an.',
          body: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _RoleChoice(
                      icon: Icons.child_care_rounded,
                      label: 'Ich bin ein Kind',
                      selected: !_parentSetup,
                      onTap: () => setState(() => _parentSetup = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RoleChoice(
                      icon: Icons.family_restroom_rounded,
                      label: 'Ich bin ein Elternteil',
                      selected: _parentSetup,
                      onTap: () => setState(() => _parentSetup = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                decoration: _inputDecoration(
                  hint: _parentSetup ? 'Name des Kindes' : 'Dein Name',
                ),
              ),
            ],
          ),
          button: 'Weiter',
          onTap: _next,
        ),
      2 => _Panel(
          eyebrow: 'Fast geschafft',
          title: 'Wie alt bist du?',
          subtitle: 'So erklärt Lumo freundlich und passend zu deinem Alter.',
          body: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [5, 6, 7, 8, 9, 10]
                .map((v) => _Choice(
                      label: '$v',
                      sub: 'Jahre',
                      selected: _age == v,
                      onTap: () => setState(() => _age = v),
                    ))
                .toList(),
          ),
          button: 'Weiter',
          onTap: _next,
        ),
      _ => _Panel(
          eyebrow: 'Dein Lernweg',
          title: 'In welche Klasse gehst du?',
          subtitle: 'Die Klasse bestimmt den Startpunkt. Du kannst sie später ändern.',
          body: LayoutBuilder(
            builder: (context, box) {
              const colors = [
                Color(0xFF35E8B5),
                Color(0xFF39C7FF),
                Color(0xFFFFA13E),
                Color(0xFFA66BFF),
              ];
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(4, (i) {
                  final v = i + 1;
                  return SizedBox(
                    width: (box.maxWidth - 10) / 2,
                    child: _GradeChoice(
                      grade: v,
                      color: colors[i],
                      selected: _grade == v,
                      onTap: () => setState(() => _grade = v),
                    ),
                  );
                }),
              );
            },
          ),
          button: 'Profil speichern',
          onTap: _next,
          finish: true,
        ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Padding(
        key: ValueKey(_step),
        padding: const EdgeInsets.all(8),
        child: content,
      ),
    );
  }

  InputDecoration _inputDecoration({String hint = 'Dein Name'}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF7DA4C8),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF6FEAFF)),
        filled: true,
        fillColor: const Color(0x66133E6E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x885BE7FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF75F2FF), width: 2),
        ),
      );
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF020D21),
                Color(0xFF082A55),
                Color(0xFF07183D),
                Color(0xFF020C20),
              ],
            ),
          ),
        ),
        ...List.generate(
          18,
          (i) => Positioned(
            left: ((i * 67) % 97) / 100 * size.width,
            top: ((i * 113) % 89) / 100 * size.height,
            child: Icon(
              Icons.circle,
              size: i % 3 == 0 ? 3 : 2,
              color: Colors.white.withOpacity(i % 4 == 0 ? .72 : .34),
            ),
          ),
        ),
        const Positioned(left: -100, top: 70, child: _Glow(Color(0x553FE4FF), 290)),
        const Positioned(right: -90, bottom: 70, child: _Glow(Color(0x444E72FF), 260)),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.color, this.size);
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.step, this.onBack});
  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? const SizedBox.shrink()
                : IconButton.filledTonal(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x66123E70),
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'LUMO',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Colors.white,
                    shadows: [Shadow(color: Color(0xFF42DFFF), blurRadius: 18)],
                  ),
                ),
                Text(
                  'DEIN LERNABENTEUER  •  ${step + 1}/4',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                    color: Color(0xFF76E9FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      );
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0x8859E0FF), width: 1.2),
              gradient: const LinearGradient(
                colors: [
                  Color(0xD0092855),
                  Color(0xBE071A3E),
                  Color(0xCB0C244B),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x552EDBFF),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.step, this.compact = false});
  final int step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const messages = [
      'Hallo! Ich bin Lumo.\nWir machen Lernen zum Abenteuer.',
      'Wie darf ich dich nennen?\nIch merke mir deinen Namen.',
      'Ich passe meine Erklärungen\nan dein Alter an.',
      'Jetzt finden wir den Stoff,\nder zu deiner Klasse passt.',
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x4459E0FF)),
        gradient: const RadialGradient(
          radius: 1.15,
          colors: [
            Color(0x4439DBFF),
            Color(0x221A5CFF),
            Color(0x00020A1C),
          ],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: compact ? Alignment.centerLeft : Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                right: compact ? 150 : 10,
                top: 6,
                bottom: 4,
              ),
              child: LumoCharacter(
                key: ValueKey('onboarding-lumo-$step'),
                pose: switch (step) {
                  0 => LumoDesignFoxPose.armsOpen,
                  1 => LumoDesignFoxPose.pointSide,
                  2 => LumoDesignFoxPose.bookPoint,
                  _ => LumoDesignFoxPose.teacherStick,
                },
                ambientPoses: const <LumoDesignFoxPose>[
                  LumoDesignFoxPose.thumbWink,
                  LumoDesignFoxPose.pointSide,
                ],
                size: compact ? 145 : 260,
                intro: true,
                idleHops: true,
              ),
            ),
          ),
          Positioned(
            left: compact ? null : 14,
            right: compact ? 10 : 14,
            bottom: 12,
            width: compact ? 145 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xCC0B2C59),
                border: Border.all(color: const Color(0x885BE7FF)),
                boxShadow: const [
                  BoxShadow(color: Color(0x443BE7FF), blurRadius: 16),
                ],
              ),
              child: Text(
                messages[step],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.button,
    required this.onTap,
    this.finish = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget body;
  final String button;
  final VoidCallback onTap;
  final bool finish;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: const Color(0x5522B9FF),
                border: Border.all(color: const Color(0x7756DFFF)),
              ),
              child: Text(
                eyebrow,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Color(0xFF8EF1FF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x7739DFFF), blurRadius: 16)],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC1E2FA),
            ),
          ),
          const SizedBox(height: 20),
          body,
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onTap,
            icon: Icon(finish ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded),
            label: Text(button),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor:
                  finish ? const Color(0xFF12C89B) : const Color(0xFF277EED),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
                side: const BorderSide(color: Color(0xAAFFFFFF)),
              ),
            ),
          ),
        ],
      );
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0x55144070),
          border: Border.all(color: const Color(0x4457DFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF33E4FF), Color(0xFF586CFF)],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xDD1686D9), Color(0xDD1745A1)],
                  )
                : const LinearGradient(
                    colors: [Color(0x88163867), Color(0x77203F72)],
                  ),
            border: Border.all(
              color: selected
                  ? const Color(0xFF75F2FF)
                  : const Color(0x555ABDE8),
              width: selected ? 1.7 : 1,
            ),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x5539E8FF), blurRadius: 16)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFF8EF1FF) : const Color(0xFF8DAAC7),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : const Color(0xFFB8D2E8),
                ),
              ),
            ],
          ),
        ),
      );
}


class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 86,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? const Color(0xFF71F0FF)
                  : const Color(0x445ABDE8),
              width: selected ? 1.7 : 1,
            ),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xCC00BFCB), Color(0xCC4168FF)],
                  )
                : const LinearGradient(
                    colors: [Color(0x66163867), Color(0x55203F72)],
                  ),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x5539E8FF), blurRadius: 18)]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC8E8FF),
                ),
              ),
            ],
          ),
        ),
      );
}

class _GradeChoice extends StatelessWidget {
  const _GradeChoice({
    required this.grade,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final int grade;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : const Color(0x4456CFFF),
              width: selected ? 1.8 : 1,
            ),
            gradient: LinearGradient(
              colors: selected
                  ? [color.withOpacity(.72), const Color(0xCC142B70)]
                  : const [Color(0x66172F5C), Color(0x55234070)],
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withOpacity(.30), blurRadius: 20)]
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: color.withOpacity(.22),
                child: Text(
                  '$grade',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$grade. Klasse',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          4,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: i == current ? 28 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: i == current
                  ? const Color(0xFF58E8FF)
                  : i < current
                      ? const Color(0xFF3A8BFF)
                      : const Color(0x445FBFEF),
            ),
          ),
        ),
      );
}
