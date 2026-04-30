import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../core/user_profile.dart';

class LumoOnboardingScreen extends StatefulWidget {
  const LumoOnboardingScreen({super.key, required this.onFinished});

  final ValueChanged<UserProfile> onFinished;

  @override
  State<LumoOnboardingScreen> createState() => _LumoOnboardingScreenState();
}

class _LumoOnboardingScreenState extends State<LumoOnboardingScreen> {
  final _nameController = TextEditingController();
  int _step = 0;
  int _age = 7;
  int _grade = 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    final now = DateTime.now();
    final name = _nameController.text.trim().isEmpty ? 'Kind' : _nameController.text.trim();
    widget.onFinished(UserProfile(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      age: _age,
      grade: _grade,
      createdAt: now,
      lastActiveAt: now,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 720;
    return Scaffold(
      backgroundColor: LumoColors.appBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 18),
          child: Container(
            width: double.infinity,
            decoration: lumoCard(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8EF), Color(0xFFFFE5C5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: isCompact
                ? _buildCompactLayout()
                : Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: KeyedSubtree(
                              key: ValueKey(_step),
                              child: _buildStep(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _LumoIntroStage(step: _step),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Mobile-Layout: kompakter Lumo-Header oben, Step-Inhalt darunter,
  /// scrollbar fuer kleine Bildschirme.
  Widget _buildCompactLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _LumoIntroHeaderCompact(step: _step),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _IntroStep(onStart: _next);
      case 1:
        return _NameStep(controller: _nameController, onNext: _next);
      case 2:
        return _AgeStep(age: _age, onChanged: (v) => setState(() => _age = v), onNext: _next);
      default:
        return _GradeStep(grade: _grade, onChanged: (v) => setState(() => _grade = v), onNext: _next);
    }
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Lumo Lernen', style: LumoTextStyles.heading1),
        const SizedBox(height: 12),
        const Text(
          'Willkommen! Zuerst richten wir dein Lernprofil ein. Danach erzeugt Lumo Aufgaben passend zu Klasse, Alter und Lernstand.',
          style: LumoTextStyles.body,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start drücken')),
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, required this.onNext});
  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Wie heißt du?', style: LumoTextStyles.heading1),
        const SizedBox(height: 12),
        const Text('Lumo spricht dich dann persönlich an.', style: LumoTextStyles.body),
        const SizedBox(height: 20),
        TextField(controller: controller, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Dein Name')),
        const SizedBox(height: 24),
        FilledButton(onPressed: onNext, child: const Text('Weiter')),
      ],
    );
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({required this.age, required this.onChanged, required this.onNext});
  final int age;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Wie alt bist du?', style: LumoTextStyles.heading1),
        const SizedBox(height: 12),
        const Text('So kann Lumo die Aufgaben freundlich und passend erklären.', style: LumoTextStyles.body),
        const SizedBox(height: 22),
        Wrap(spacing: 12, runSpacing: 12, children: [5, 6, 7, 8, 9, 10].map((v) => _SelectPill(label: '$v Jahre', selected: age == v, onTap: () => onChanged(v))).toList()),
        const SizedBox(height: 24),
        FilledButton(onPressed: onNext, child: const Text('Weiter')),
      ],
    );
  }
}

class _GradeStep extends StatelessWidget {
  const _GradeStep({required this.grade, required this.onChanged, required this.onNext});
  final int grade;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('In welche Klasse gehst du?', style: LumoTextStyles.heading1),
        const SizedBox(height: 12),
        const Text('Der Aufgaben-Generator nutzt diese Klasse als Grundlage.', style: LumoTextStyles.body),
        const SizedBox(height: 22),
        Wrap(spacing: 12, runSpacing: 12, children: [1, 2, 3, 4].map((v) => _SelectPill(label: '$v. Klasse', selected: grade == v, onTap: () => onChanged(v))).toList()),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: onNext, icon: const Icon(Icons.check_rounded), label: const Text('Profil speichern')),
      ],
    );
  }
}

class _SelectPill extends StatelessWidget {
  const _SelectPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]) : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(LumoRadius.pill),
          border: Border.all(color: selected ? Colors.transparent : LumoColors.ink100, width: 1.4),
          boxShadow: selected ? LumoShadow.pill : LumoShadow.card,
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: selected ? Colors.white : LumoColors.ink700)),
      ),
    );
  }
}

class _LumoIntroHeaderCompact extends StatelessWidget {
  const _LumoIntroHeaderCompact({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final text = switch (step) {
      0 => 'Hallo! Ich bin Lumo.',
      1 => 'Wie darf ich dich nennen?',
      2 => 'Ich passe die Erklärung an dich an.',
      _ => 'Jetzt wähle ich den richtigen Stoff.',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LumoColors.stageBg1, LumoColors.stageBg2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: Colors.white.withOpacity(.8), width: 1.4),
        boxShadow: LumoShadow.stage,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/lumo_fox.png',
            height: 78,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Text('🦊', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Text(
                text,
                key: ValueKey(step),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.ink900,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LumoIntroStage extends StatelessWidget {
  const _LumoIntroStage({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final text = switch (step) {
      0 => 'Hallo!\nIch bin Lumo.',
      1 => 'Wie darf ich\ndich nennen?',
      2 => 'Ich passe die\nErklärung an dich an.',
      _ => 'Jetzt wähle ich\nden richtigen Stoff.',
    };
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [LumoColors.stageBg1, LumoColors.stageBg2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(LumoRadius.xl),
        border: Border.all(color: Colors.white.withOpacity(.7), width: 1.5),
        boxShadow: LumoShadow.stage,
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(LumoRadius.lg)),
            child: Text(text, textAlign: TextAlign.center, style: LumoTextStyles.heading3),
          ),
          const Spacer(),
          Image.asset('assets/images/lumo_fox.png', height: 250, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('🦊', style: TextStyle(fontSize: 120))),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text('Sicher • freundlich • altersgerecht', style: LumoTextStyles.caption),
          ),
        ],
      ),
    );
  }
}
