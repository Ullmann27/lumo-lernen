import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/design/lumo_motion.dart';
import '../../../widgets/fox/lumo_character.dart';
import 'iq_boards.dart';
import 'iq_figure_painter.dart';
import 'iq_puzzle_view.dart';
import 'iq_style.dart';
import 'iq_widgets.dart';

bool _isWide(BoxConstraints c) =>
    c.maxWidth >= 720 && c.maxWidth >= c.maxHeight * 1.1;

/// Startseite: Lumo, Titel, die sechs Bereiche, der ehrliche Elternhinweis.
class IqStartView extends StatelessWidget {
  const IqStartView({
    super.key,
    required this.onStart,
    required this.onBack,
    this.lastPoints,
  });

  final VoidCallback onStart;
  final VoidCallback onBack;

  /// Denkpunkte des letzten echten Ergebnisses (null: noch keins).
  final int? lastPoints;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final wide = _isWide(c);
        final reduced = LumoMotion.reduced(context);
        final hero = _Hero(reduced: reduced, scale: c.maxWidth >= 600 ? 1.2 : 1);
        final details = _Details(lastPoints: lastPoints);
        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
                child: IqRoundButton(
                  key: const ValueKey('iq-back'),
                  icon: Icons.arrow_back_rounded,
                  label: 'Zurück',
                  onPressed: onBack,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1000 : 560),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: hero),
                              const SizedBox(width: 24),
                              Expanded(child: details),
                            ],
                          )
                        : Column(children: [hero, const SizedBox(height: 14), details]),
                  ),
                ),
              ),
            ),
            IqBottomBar(
              child: IqPrimaryButton(
                key: const ValueKey('iq-start-button'),
                label: 'Test starten',
                icon: Icons.play_arrow_rounded,
                height: 62,
                onPressed: onStart,
              ),
            ),
          ],
        );
      });
}

class _Hero extends StatelessWidget {
  const _Hero({required this.reduced, this.scale = 1});

  final bool reduced;

  /// Größer auf breiten Bildschirmen.
  final double scale;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320 * scale,
            height: 232 * scale,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Lichthof hinter Lumo.
                Container(
                  width: 270 * scale,
                  height: 270 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        LumoVisualTokens.cyan.withValues(alpha: .38),
                        const Color(0xFF8F6BFF).withValues(alpha: .16),
                        const Color(0x0003193F),
                      ],
                      stops: const [0, .55, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 6 * scale,
                  top: 20 * scale,
                  child: _Floating(
                    const IqFigure(IqShape.star, tint: IqTint.gold),
                    size: 52 * scale,
                    period: 2100,
                  ),
                ),
                Positioned(
                  right: 4 * scale,
                  top: 6 * scale,
                  child: _Floating(
                    const IqFigure(IqShape.hexagon, tint: IqTint.violet),
                    size: 56 * scale,
                    period: 2600,
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 34 * scale,
                  child: _Floating(
                    const IqFigure(IqShape.triangle, tint: IqTint.pink, filled: false),
                    size: 54 * scale,
                    period: 2300,
                  ),
                ),
                Positioned(
                  right: 8 * scale,
                  bottom: 26 * scale,
                  child: _Floating(
                    const IqFigure(IqShape.diamond, tint: IqTint.orange),
                    size: 46 * scale,
                    period: 1900,
                  ),
                ),
                LumoCharacter(
                  pose: LumoDesignFoxPose.thumbWink,
                  size: 204 * scale,
                  reduceMotion: reduced,
                  intro: !reduced,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Lumo Knobel-Test',
                style: iqText(
                  34,
                  weight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: LumoVisualTokens.cyan, blurRadius: 18),
                    Shadow(color: Color(0xE603122E), blurRadius: 10),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Der IQ-Test für Kinder',
            textAlign: TextAlign.center,
            style: iqText(17,
                color: LumoVisualTokens.cyanBright, shadows: iqScrim),
          ),
        ],
      );
}

/// Eine kleine Form, die langsam auf und ab schwebt (ruhig bei reduzierter
/// Bewegung).
class _Floating extends StatelessWidget {
  const _Floating(this.figure, {required this.size, required this.period});

  final IqFigure figure;
  final double size;
  final int period;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IqPulse(
          period: Duration(milliseconds: period),
          builder: (context, t) => Transform.translate(
            offset: Offset(0, (t - .5) * 12),
            child: IqFigureView(figure, size: size),
          ),
        ),
      );
}

class _Details extends StatelessWidget {
  const _Details({required this.lastPoints});

  final int? lastPoints;

  @override
  Widget build(BuildContext context) {
    final points = lastPoints;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LumoEntrance(
          child: IqPanel(
            strong: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sechs Knobel-Bereiche', style: iqText(16, weight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final area in IqArea.values) _AreaChip(area)],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        LumoEntrance(
          index: 1,
          child: Align(
            alignment: Alignment.center,
            child: IqChip(
              label: '24 Rätsel · ca. 10 Minuten · ohne Zeitdruck',
              icon: Icons.schedule_rounded,
            ),
          ),
        ),
        if (points != null) ...[
          const SizedBox(height: 8),
          LumoEntrance(
            index: 2,
            child: Align(
              alignment: Alignment.center,
              child: IqChip(
                key: const ValueKey('iq-last-points'),
                label: 'Letztes Mal: $points Denkpunkte',
                icon: Icons.emoji_events_rounded,
                color: LumoVisualTokens.gold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const LumoEntrance(index: 3, child: IqParentNote()),
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip(this.area);

  final IqArea area;

  @override
  Widget build(BuildContext context) {
    final style = iqAreaStyle(area);
    return Semantics(
      label: '${area.title}: ${area.skill}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: style.color.withValues(alpha: .12),
          border: Border.all(color: style.color.withValues(alpha: .5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IqAreaMedallion(area, size: 32, glow: false),
              const SizedBox(width: 8),
              Text(area.title, style: iqText(13.5, weight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der ehrliche Hinweis für Eltern (Start- und Ergebnisseite).
class IqParentNote extends StatelessWidget {
  const IqParentNote({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Hinweis für Eltern: $iqParentNote',
        excludeSemantics: true,
        child: IqPanel(
          key: const ValueKey('iq-parent-note'),
          radius: 22,
          padding: const EdgeInsets.all(14),
          accent: LumoVisualTokens.muted,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.family_restroom_rounded,
                  color: LumoVisualTokens.cyanBright, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hinweis für Eltern', style: iqText(14, weight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      iqParentNote,
                      style: iqText(12.5,
                          weight: FontWeight.w700,
                          color: LumoVisualTokens.muted,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Anleitung vor jedem Bereich
// ---------------------------------------------------------------------------

/// Kurze Anleitung vor dem ersten Rätsel eines Bereichs.
class IqAreaIntroView extends StatelessWidget {
  const IqAreaIntroView({
    super.key,
    required this.area,
    required this.areaNumber,
    required this.index,
    required this.total,
    required this.itemsPerArea,
    required this.onGo,
    required this.onBack,
  });

  final IqArea area;
  final int areaNumber;
  final int index;
  final int total;
  final int itemsPerArea;
  final VoidCallback onGo;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final wide = _isWide(c);
        final style = iqAreaStyle(area);
        final title = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IqAreaMedallion(area, size: 92),
            const SizedBox(height: 12),
            Text(
              'Bereich $areaNumber von ${IqArea.values.length}',
              style: iqText(13.5,
                  color: Color.lerp(style.color, Colors.white, .35)!,
                  letterSpacing: .6,
                  shadows: iqScrim),
            ),
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  area.title,
                  style: iqText(
                    32,
                    weight: FontWeight.w900,
                    shadows: [
                      Shadow(color: style.color, blurRadius: 16),
                      const Shadow(color: Color(0xE603122E), blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            IqChip(
              label: 'Hier übst du: ${area.skill}',
              icon: Icons.psychology_rounded,
              color: style.color,
              dense: true,
            ),
          ],
        );
        final instruction = IqPanel(
          strong: true,
          accent: style.color,
          child: Text(
            area.instruction,
            style: iqText(17.5, weight: FontWeight.w700, height: 1.42),
          ),
        );
        final example = IqPanel(
          accent: style.color,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('So sieht das aus', style: iqText(14, weight: FontWeight.w900)),
              const SizedBox(height: 10),
              IqSolutionView(iqExamplePuzzle(area)),
              const SizedBox(height: 10),
              Text(
                iqExampleCaption(area),
                style: iqText(13, color: LumoVisualTokens.muted, height: 1.35),
              ),
            ],
          ),
        );
        return Column(
          children: [
            IqProgressHeader(
              index: index,
              total: total,
              areaNumber: areaNumber,
              itemsPerArea: itemsPerArea,
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1000 : 560),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LumoEntrance(child: title),
                                    const SizedBox(height: 16),
                                    LumoEntrance(index: 1, child: instruction),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(child: LumoEntrance(index: 2, child: example)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LumoEntrance(child: title),
                              const SizedBox(height: 16),
                              LumoEntrance(index: 1, child: instruction),
                              const SizedBox(height: 12),
                              LumoEntrance(index: 2, child: example),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            IqBottomBar(
              child: IqPrimaryButton(
                key: const ValueKey('iq-area-go'),
                label: 'Los geht’s',
                icon: Icons.play_arrow_rounded,
                height: 62,
                color: Color.lerp(LumoVisualTokens.cyan, style.color, .35)!,
                onPressed: onGo,
              ),
            ),
          ],
        );
      });
}

/// Ein kleines, festes Beispielrätsel je Bereich (mit gezeichneter Lösung).
IqPuzzle iqExamplePuzzle(IqArea area) {
  const circle = IqFigure(IqShape.circle, tint: IqTint.cyan);
  const square = IqFigure(IqShape.square, tint: IqTint.orange);
  switch (area) {
    case IqArea.matrix:
      return const IqMatrixPuzzle(
        id: 'beispiel',
        level: 1,
        question: '',
        explanation: '',
        answer: 0,
        columns: 2,
        cells: [circle, circle, square, null],
        options: [square],
      );
    case IqArea.series:
      return const IqSeriesPuzzle(
        id: 'beispiel',
        level: 1,
        question: '',
        explanation: '',
        answer: 0,
        shown: [
          IqFigure(IqShape.triangle, tint: IqTint.violet),
          IqFigure(IqShape.triangle, tint: IqTint.violet, count: 2),
          IqFigure(IqShape.triangle, tint: IqTint.violet, count: 3),
        ],
        options: [IqFigure(IqShape.triangle, tint: IqTint.violet, count: 4)],
      );
    case IqArea.oddOneOut:
      const pink = IqFigure(IqShape.circle, tint: IqTint.pink);
      return const IqOddOnePuzzle(
        id: 'beispiel',
        level: 1,
        question: '',
        explanation: '',
        answer: 2,
        figures: [
          pink,
          pink,
          IqFigure(IqShape.square, tint: IqTint.pink),
          pink,
        ],
      );
    case IqArea.rotation:
      final piece = IqPolyomino(const [(0, 0), (0, 1), (0, 2), (1, 2)]);
      return IqRotationPuzzle(
        id: 'beispiel',
        level: 1,
        question: '',
        explanation: '',
        answer: 0,
        target: piece,
        options: [piece.rotated(1)],
        tint: IqTint.green,
      );
    case IqArea.numbers:
      return const IqNumberPuzzle(
        id: 'beispiel',
        level: 1,
        question: '',
        explanation: '',
        answer: 0,
        numbers: [2, 4, 6, null],
        options: [8],
      );
    case IqArea.memory:
      return const IqMemoryPuzzle(
        id: 'beispiel',
        level: 1,
        question: '',
        explanation: '',
        gridSize: 3,
        sequence: [1, 5, 6],
        showMs: 700,
        gapMs: 250,
      );
  }
}

String iqExampleCaption(IqArea area) => switch (area) {
      IqArea.matrix =>
        'Unten links steht ein Quadrat. Also gehört unten rechts auch eins hin.',
      IqArea.series =>
        'Bei jedem Schritt kommt ein Dreieck dazu. Als Nächstes sind es vier.',
      IqArea.oddOneOut =>
        'Drei Kreise und ein Quadrat: Das Quadrat passt nicht dazu.',
      IqArea.rotation =>
        'Das rechte Bauteil ist das linke – nur gedreht, nicht umgeklappt.',
      IqArea.numbers => 'Jede Zahl ist um 2 größer. Nach der 6 kommt die 8.',
      IqArea.memory =>
        'Erst leuchtet Feld 1, dann Feld 2, dann Feld 3. Tippe sie genauso an.',
    };
