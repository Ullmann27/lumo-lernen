import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/test_result_repository.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../shared/widgets/lumo_premium_effects.dart' show LumoFloating;

/// Tests wie in Heinz' Bild 05: Kategorie, Schwierigkeit, Test-Karte und das
/// echte letzte Ergebnis mit Bestleistung.
class LumoTestsScreen extends StatefulWidget {
  const LumoTestsScreen({
    super.key,
    required this.appState,
    required this.onSection,
    this.drawBackground = true,
    this.results = const TestResultRepository(),
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;

  /// Im App-Rahmen malt die Shell die Szene vollflächig.
  final bool drawBackground;
  final TestResultRepository results;

  @override
  State<LumoTestsScreen> createState() => _LumoTestsScreenState();
}

class _TestCategory {
  const _TestCategory({
    required this.title,
    required this.subject,
    required this.testTitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.message,
  });

  final String title;
  final String subject;
  final String testTitle;
  final String description;
  final IconData icon;
  final Color color;
  final String message;
}

const _categories = <_TestCategory>[
  _TestCategory(
    title: 'Mathe',
    subject: 'Mathematik',
    testTitle: 'Mathe-Test',
    description: 'Rechnen, Zahlen und kleine Denkaufgaben',
    icon: Icons.calculate_rounded,
    color: Color(0xFFE08A26),
    message: 'Mathe-Test\nist bereit.\nRuhig rechnen.',
  ),
  _TestCategory(
    title: 'Deutsch',
    subject: 'Deutsch',
    testTitle: 'Deutsch-Test',
    description: 'Lesen, Wörter und Satzverständnis',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF7A3FE0),
    message: 'Deutsch-Test\nist bereit.\nLangsam lesen.',
  ),
  _TestCategory(
    title: 'Sachkunde',
    subject: 'Sachunterricht',
    testTitle: 'Sachkunde-Test',
    description: 'Tiere, Natur, Körper und Welt',
    icon: Icons.public_rounded,
    color: Color(0xFF14917F),
    message: 'Sachkunde-Test\nist bereit.\nDu weißt schon viel!',
  ),
  _TestCategory(
    title: 'Englisch',
    subject: 'Englisch',
    testTitle: 'Englisch-Test',
    description: 'Wörter, Farben und Zahlen auf Englisch',
    icon: Icons.chat_bubble_rounded,
    color: Color(0xFFC63A86),
    message: 'Englisch-Test\nist bereit.\nLet’s go!',
  ),
  _TestCategory(
    title: 'Kreatives Denken',
    subject: 'Logik',
    testTitle: 'Denk-Test',
    description: 'Muster, Reihenfolgen und Knobelaufgaben',
    icon: Icons.extension_rounded,
    color: Color(0xFF2B5FD8),
    message: 'Denk-Test\nist bereit.\nSchau genau hin!',
  ),
];

const _mixed = _TestCategory(
  title: 'Gemischt',
  subject: 'Alle',
  testTitle: 'Mini-Test',
  description: 'Gemischte Aufgaben zum Aufwärmen',
  icon: Icons.flash_on_rounded,
  color: Color(0xFF167A84),
  message: 'Mini-Test\nist bereit.\nDu schaffst das!',
);

class _LumoTestsScreenState extends State<LumoTestsScreen> {
  _TestCategory _selected = _categories.first;
  bool _showAll = false;
  TestResultSummary _summary = const TestResultSummary();

  List<_TestCategory> get _visible =>
      _showAll ? const [..._categories, _mixed] : _categories;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final summary = await widget.results.load(widget.appState.state.childName);
    if (mounted) setState(() => _summary = summary);
  }

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  _TestCategory _categoryFor(String subject) => [..._categories, _mixed]
      .firstWhere((c) => c.subject == subject, orElse: () => _mixed);

  void _start(_TestCategory category) {
    final state = widget.appState.state;
    widget.appState.update(state.copyWith(
      subject: category.subject,
      unit: 'Alle',
      mood: LumoMood.point,
      lumoMessage: category.message,
      sessionKind: LumoSessionKind.test,
    ));
    widget.onSection(LumoSection.exercises);
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _buildHero(),
        _buildCategoryCard(),
        _buildTestCard(),
        _buildLastResult(),
      ],
    );
    return widget.drawBackground
        ? LumoSceneBackground(
            scene: LumoScene.tests,
            showPlaceholderLabel: false,
            dimmed: true,
            child: content,
          )
        : content;
  }

  Widget _buildHero() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = (width * .46).clamp(160.0, 260.0);
      final foxSize = height * 1.12;
      Widget fox =
          LumoFoxPose(pose: LumoDesignFoxPose.trophyWink, size: foxSize);
      if (!_reduceMotion) {
        fox = LumoFloating(
          amplitude: 4,
          duration: const Duration(milliseconds: 2600),
          child: fox,
        );
      }
      return SizedBox(
        height: height,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: (width - foxSize) / 2 - width * .02,
            bottom: -foxSize * .06,
            child: RepaintBoundary(child: fox),
          ),
          Positioned(
            left: 12,
            top: height * .1,
            width: width * .32,
            child: Transform.rotate(
              angle: -.06,
              child: const LumoHeroBubble(
                title: 'Teste dein Wissen!',
                text: 'Du kannst das! Schritt für Schritt zum Profi!',
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: height * .1,
            width: width * .24,
            child: Transform.rotate(
              angle: -.12,
              child: const LumoHeroBubble(
                text: 'Wissen macht stärker!',
                handwritten: true,
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _buildCategoryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                child: Text(
                  'Kategorie wählen',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                key: const ValueKey('tests-show-all'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _showAll = !_showAll),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _showAll ? 'Weniger' : 'Alle anzeigen',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                        _showAll
                            ? Icons.expand_less_rounded
                            : Icons.chevron_right_rounded,
                        color: LumoVisualTokens.white,
                        size: 18),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              const gap = 6.0;
              final columns = constraints.maxWidth < 330 ? 3 : 5;
              final width =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;
              final height = width *
                  1.02 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final category in _visible)
                    SizedBox(
                      width: width,
                      height: height,
                      child: _categoryTile(category, width * .5),
                    ),
                ],
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'Schwierigkeit auswählen',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: widget.appState,
              builder: (context, _) => Row(children: [
                for (final level in const [-1, 0, 1]) ...[
                  if (level != -1) const SizedBox(width: 6),
                  Expanded(child: _levelPill(level)),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(_TestCategory category, double iconSize) {
    final selected = identical(category, _selected);
    return Semantics(
      button: true,
      selected: selected,
      label: '${category.title}: ${category.testTitle}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('test-category-${category.subject}'),
        onTap: () => setState(() => _selected = category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(3, 6, 3, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(category.color, Colors.white, .12)!,
                Color.lerp(category.color, Colors.black, .3)!,
              ],
            ),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFD873)
                  : Colors.white.withOpacity(.28),
              width: selected ? 2.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? const Color(0xFFFFC94A) : category.color)
                    .withOpacity(selected ? .6 : .3),
                blurRadius: selected ? 16 : 8,
              ),
            ],
          ),
          child: Column(children: [
            Expanded(
              child: Center(
                child: Icon(category.icon,
                    size: iconSize,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0x88FFFFFF), blurRadius: 10)
                    ]),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 26,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.title.replaceFirst(' ', '\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _levelPill(int level) {
    final state = widget.appState.state;
    final selected = state.testLevel == level;
    final label =
        switch (level) { -1 => 'Leicht', 0 => 'Mittel', _ => 'Schwer' };
    final stars = level + 2;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, Aufgaben aus Klasse ${_gradeFor(level)}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('test-level-$level'),
        onTap: () => widget.appState.update(state.copyWith(testLevel: level)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF0F6B73)
                : LumoVisualTokens.navigation.withOpacity(.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6FF3F0)
                  : LumoVisualTokens.cyan.withOpacity(.25),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: const Color(0xFF3FE6E0).withOpacity(.5),
                        blurRadius: 12)
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < stars; i++)
                  Icon(Icons.star_rounded,
                      size: 18,
                      color: selected
                          ? const Color(0xFF8CF06B)
                          : const Color(0xFF8D9BB8)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  int _gradeFor(int level) =>
      (widget.appState.state.grade + level).clamp(1, 4).toInt();

  Widget _buildTestCard() {
    final category = _selected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LumoGlassCard(
        padding: const EdgeInsets.all(10),
        radius: 22,
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 84,
              height: 66,
              child: category.subject == 'Mathematik'
                  ? Image.asset('assets/lumo_design/cards/test_rechnen.png',
                      fit: BoxFit.cover)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color.lerp(category.color, Colors.white, .2)!,
                          Color.lerp(category.color, Colors.black, .35)!,
                        ]),
                      ),
                      child: Icon(category.icon, color: Colors.white, size: 38),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: widget.appState,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.testTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    category.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Wrap(spacing: 8, runSpacing: 2, children: [
                    _InfoChip(
                        icon: Icons.description_outlined,
                        text: '$kLumoTestQuestions Fragen'),
                    _InfoChip(icon: Icons.schedule_rounded, text: 'ca. 5 Min.'),
                  ]),
                  const SizedBox(height: 2),
                  _InfoChip(
                    icon: Icons.school_rounded,
                    text: 'Klasse ${_gradeFor(widget.appState.state.testLevel)}'
                        ' · ohne Hilfe',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _GlowButton(
            key: const ValueKey('tests-start'),
            label: 'Starten',
            onTap: () => _start(category),
          ),
        ]),
      ),
    );
  }

  Widget _buildLastResult() {
    final last = _summary.last;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: LumoGlassCard(
        padding: const EdgeInsets.all(10),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                child: Text(
                  'Letztes Ergebnis',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (last != null)
                Text(
                  _date(last.finishedAt),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            if (last == null)
              Row(children: [
                Opacity(
                  opacity: .55,
                  child: Image.asset('assets/lumo_design/icons/trophy_gold.png',
                      width: 56, height: 56),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Noch kein Test gemacht. Starte deinen ersten Test – '
                    'Lumo hebt dein Ergebnis hier auf.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ])
            else
              _resultRow(last),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(TestResult last) {
    final category = _categoryFor(last.subject);
    final best = _summary.best[last.subject] ?? last;
    final ratio = last.correct / last.total;
    final praise = ratio >= .8
        ? 'Stark gemacht!'
        : ratio >= .5
            ? 'Gut gemacht!'
            : 'Weiter üben – du schaffst das!';
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 3,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
          decoration: BoxDecoration(
            color: LumoVisualTokens.navigation.withOpacity(.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.3)),
          ),
          child: Row(children: [
            Image.asset('assets/lumo_design/icons/trophy_gold.png',
                width: 62, height: 62),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.title} – ${category.testTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${last.correct} / ${last.total} richtig!',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    praise,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.cyanBright,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: LumoVisualTokens.navigation.withOpacity(.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.3)),
            ),
            child: Row(children: [
              Image.asset('assets/lumo_design/icons/crown.png',
                  width: 26, height: 26),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bestleistung',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${best.correct} / ${best.total}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _GlowButton(
              key: const ValueKey('tests-repeat'),
              label: 'Wiederholen',
              icon: Icons.refresh_rounded,
              outlined: true,
              onTap: () => _start(category),
            ),
          ),
        ]),
      ),
    ]);
  }

  static const _months = [
    'Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', //
    'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  String _date(DateTime d) => '${d.day}. ${_months[d.month - 1]} ${d.year}';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LumoVisualTokens.white, size: 15),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: outlined
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF8BEFFF), LumoVisualTokens.cyan],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              color: outlined ? const Color(0xFF0E3D86) : null,
              border: Border.all(
                color: outlined
                    ? LumoVisualTokens.cyanBright
                    : Colors.white.withOpacity(.8),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: LumoVisualTokens.cyan.withOpacity(.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: outlined ? Colors.white : LumoVisualTokens.night,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (!outlined)
                  const Icon(Icons.chevron_right_rounded,
                      color: LumoVisualTokens.night, size: 20),
              ],
            ),
          ),
        ),
      );
}
