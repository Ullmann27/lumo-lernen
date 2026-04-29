import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../widgets/cards/kpi_card.dart';
import '../../widgets/cards/learning_module_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.appState,
    required this.onSection,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  Widget build(BuildContext context) {
    final st = appState.state;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cardW = ((w - 32) / 3).clamp(190.0, 260.0);
      final wideW = ((w - 16) / 2).clamp(280.0, 400.0);

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 26, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hallo, ${st.childName}! 👋',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.ink900,
                  height: 1.1,
                )),
            const SizedBox(height: 4),
            const Text('Bereit für ein neues Lernabenteuer?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LumoColors.ink500,
                )),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                KpiCard(label: 'Sterne', value: '${st.stars}', sub: '/50', icon: '⭐', accent: LumoColors.purple, percent: st.stars / 50),
                const SizedBox(width: 14),
                KpiCard(label: 'XP Punkte', value: '${st.xp}', sub: '', icon: '🏅', accent: LumoColors.gold, percent: (st.xp % 1000) / 1000),
                const SizedBox(width: 14),
                KpiCard(label: 'Level', value: '${st.level}', sub: 'Einsteiger', icon: '💎', accent: LumoColors.teal, percent: st.levelXpPercent / 100),
                const SizedBox(width: 14),
                KpiCircularCard(label: 'Lernfortschritt', value: '${st.weeklyProgress}%', sub: 'Diese Woche', accent: LumoColors.blue, percent: st.weeklyProgress / 100),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Was möchtest du lernen?',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                LearningModuleCard(width: cardW, height: 162, title: 'Mathematik', description: 'Zahlen, Rechnen,\nGeometrie & mehr', ctaLabel: 'Weiterlernen', objectEmoji: '🔢', icon: Icons.calculate_rounded, accent: LumoColors.math, surfaceColors: const [Color(0xFFFFF4BD), Color(0xFFFFDFA2)], onTap: () => onSection(LumoSection.learn)),
                LearningModuleCard(width: cardW, height: 162, title: 'Deutsch', description: 'Lesen, Schreiben,\nGrammatik', ctaLabel: 'Weiterlernen', objectEmoji: '📚', icon: Icons.menu_book_rounded, accent: LumoColors.german, surfaceColors: const [Color(0xFFFFE8FB), Color(0xFFF0DCFF)], onTap: () => onSection(LumoSection.learn)),
                LearningModuleCard(width: cardW, height: 162, title: 'Englisch', description: 'Wörter, Sätze,\nVerstehen', ctaLabel: 'Weiterlernen', objectEmoji: '🌍', icon: Icons.language_rounded, accent: LumoColors.english, surfaceColors: const [Color(0xFFDFFFF6), Color(0xFFC8F5ED)], onTap: () => onSection(LumoSection.learn)),
                LearningModuleCard(width: cardW, height: 162, title: 'Übung', description: 'Interaktive Übungen\nund Spiele', ctaLabel: 'Üben', objectEmoji: '🎮', icon: Icons.edit_rounded, accent: LumoColors.practice, surfaceColors: const [Color(0xFFFFE6E2), Color(0xFFFFD2CE)], onTap: () => onSection(LumoSection.exercises)),
                LearningModuleCard(width: cardW, height: 162, title: 'Test', description: 'Teste dein Wissen\nund sammle Sterne', ctaLabel: 'Test starten', objectEmoji: '📋', icon: Icons.assignment_turned_in_rounded, accent: LumoColors.testColor, surfaceColors: const [Color(0xFFEAF3FF), Color(0xFFDBEAFF)], onTap: () => onSection(LumoSection.exercises)),
                LearningModuleCard(width: cardW, height: 162, title: 'Schularbeit', description: 'Gemischter Test\nmit Note', ctaLabel: 'Starten', objectEmoji: '🏆', icon: Icons.description_rounded, accent: LumoColors.schoolwork, surfaceColors: const [Color(0xFFFFF2C9), Color(0xFFFFE0A8)], onTap: () => onSection(LumoSection.exercises)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                WideModuleCard(width: wideW, title: 'Aufgabe fotografieren', description: 'Mach ein Foto deiner Aufgabe\nund lass dir helfen!', ctaLabel: 'Foto machen', objectEmoji: '📸', icon: Icons.photo_camera_rounded, accent: LumoColors.scanner, surfaceColors: const [Color(0xFFFFE8FF), Color(0xFFF2D7FF)], onTap: () => onSection(LumoSection.scanner)),
                WideModuleCard(width: wideW, title: 'Weiterlernen', description: 'Setze da weiter, wo du\naufgehört hast', ctaLabel: 'Anzeigen', objectEmoji: '📖', icon: Icons.play_circle_rounded, accent: LumoColors.continueColor, surfaceColors: const [Color(0xFFE5FFF6), Color(0xFFCFFFF0)], onTap: () => onSection(LumoSection.exercises)),
              ],
            ),
          ],
        ),
      );
    });
  }
}
