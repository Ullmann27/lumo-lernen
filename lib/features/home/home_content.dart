import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/app_update_service.dart';
import '../../core/reading_progress_repository.dart';
import '../../domain/analysis/daily_recommendation_engine.dart';
import '../../domain/analysis/lumo_analysis_domain.dart';
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
            const SizedBox(height: 16),
            const _UpdateCheckerCard(),
            const SizedBox(height: 16),
            _DailyPlanCard(appState: appState, onSection: onSection),
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

class _DailyPlanCard extends StatefulWidget {
  const _DailyPlanCard({required this.appState, required this.onSection});

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  @override
  State<_DailyPlanCard> createState() => _DailyPlanCardState();
}

class _DailyPlanCardState extends State<_DailyPlanCard> {
  final _readingRepo = ReadingProgressRepository();
  final _engine = const DailyRecommendationEngine();
  late Future<DailyRecommendationPlan> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildPlan();
  }

  Future<DailyRecommendationPlan> _buildPlan() async {
    if (!widget.appState.learningProfileLoaded) {
      try {
        await widget.appState.loadLearningProfile();
      } catch (_) {}
    }
    final reading = await _readingRepo.loadReadingSummaries();
    return _engine.buildPlan(
      childId: 'local_${widget.appState.state.childName.toLowerCase()}_${widget.appState.state.grade}',
      skills: widget.appState.learningSkills(),
      readingSummaries: reading,
      dailyGoalTarget: widget.appState.state.settings.dailyGoal,
    );
  }

  void _startBlock(DailyRecommendationBlock block) {
    widget.appState.update(widget.appState.state.copyWith(
      subject: block.subject,
      unit: block.unit,
      mood: LumoMood.point,
      lumoMessage: block.description,
      sessionKind: block.kind == RecommendationKind.tutoring ? LumoSessionKind.tutoring : LumoSessionKind.quickPractice,
    ));
    if (block.kind == RecommendationKind.reading) {
      widget.onSection(LumoSection.reading);
    } else {
      widget.onSection(LumoSection.exercises);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DailyRecommendationPlan>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: lumoCard(),
            child: const Text('Lumo erstellt deinen Tagesplan …', style: LumoTextStyles.heading3),
          );
        }
        final plan = snapshot.data!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFFFF7ED)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(.84), borderRadius: BorderRadius.circular(LumoRadius.lg)), child: const Center(child: Text('🦊', style: TextStyle(fontSize: 30)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan.headline, style: LumoTextStyles.heading2),
                const SizedBox(height: 4),
                Text(plan.lumoMessage, style: LumoTextStyles.body.copyWith(color: LumoColors.ink700)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(.76), borderRadius: BorderRadius.circular(LumoRadius.pill)), child: Text('${plan.totalMinutes} Min.', style: LumoTextStyles.label.copyWith(color: LumoColors.orange))),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: plan.blocks.map((block) {
              return GestureDetector(
                onTap: () => _startBlock(block),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.82), borderRadius: BorderRadius.circular(LumoRadius.lg), border: Border.all(color: LumoColors.orange.withOpacity(.16))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(block.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.heading3.copyWith(color: _colorFor(block.kind))),
                    const SizedBox(height: 5),
                    Text(block.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: LumoTextStyles.caption.copyWith(color: LumoColors.ink700)),
                    const SizedBox(height: 8),
                    Text('Starten →', style: LumoTextStyles.cta.copyWith(color: _colorFor(block.kind))),
                  ]),
                ),
              );
            }).toList()),
          ]),
        );
      },
    );
  }

  Color _colorFor(RecommendationKind kind) {
    return switch (kind) {
      RecommendationKind.reading => LumoColors.blue,
      RecommendationKind.tutoring => LumoColors.purple,
      RecommendationKind.success => LumoColors.teal,
      RecommendationKind.review => LumoColors.gold,
      RecommendationKind.practice => LumoColors.orange,
    };
  }
}

class _UpdateCheckerCard extends StatefulWidget {
  const _UpdateCheckerCard();

  @override
  State<_UpdateCheckerCard> createState() => _UpdateCheckerCardState();
}

class _UpdateCheckerCardState extends State<_UpdateCheckerCard> {
  final _service = const AppUpdateService();
  late Future<AppUpdateInfo> _future;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _future = _service.checkLatest();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return FutureBuilder<AppUpdateInfo>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _UpdateShell(
            icon: Icons.sync_rounded,
            title: 'Lumo prüft Updates …',
            message: 'Ich schaue kurz, ob eine neue APK bereitsteht.',
            actionLabel: null,
            onAction: null,
            onClose: () => setState(() => _dismissed = true),
          );
        }
        final info = snapshot.data;
        if (info == null || !info.available || !info.hasUsableDownload) {
          return const SizedBox.shrink();
        }
        return _UpdateShell(
          icon: Icons.system_update_alt_rounded,
          title: 'Neue Lumo-Version verfügbar',
          message: 'Tippe auf „Update laden“. Danach fragt Android: App aktualisieren?',
          actionLabel: 'Update laden',
          onAction: () => _service.openUpdate(info),
          onClose: () => setState(() => _dismissed = true),
        );
      },
    );
  }
}

class _UpdateShell extends StatelessWidget {
  const _UpdateShell({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFFFF7ED)]),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.orange.withOpacity(.18)),
        boxShadow: LumoShadow.card,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: Icon(icon, color: LumoColors.orange, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
            const SizedBox(height: 3),
            Text(message, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: LumoColors.ink600, height: 1.25)),
          ]),
        ),
        const SizedBox(width: 8),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: LumoColors.orange,
                borderRadius: BorderRadius.circular(LumoRadius.pill),
              ),
              child: Text(actionLabel!, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: LumoColors.ink400)),
      ]),
    );
  }
}
