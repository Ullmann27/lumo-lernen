import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'iq_boards.dart';
import 'iq_style.dart';
import 'iq_widgets.dart';

/// Rückblick: alle Rätsel der Reihe nach. Was nicht gelöst wurde, zeigt die
/// richtige Lösung gezeichnet und die Regel in Kindersprache.
class IqReviewView extends StatelessWidget {
  const IqReviewView({super.key, required this.answered, required this.onBack});

  /// Die gestellten Rätsel mit der gegebenen Antwort (siehe
  /// `IqTestSession.answered`).
  final List<(IqPuzzle, List<int>)> answered;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final solved = answered.where((a) => a.$1.isCorrect(a.$2)).length;
    return LayoutBuilder(builder: (context, c) {
      final children = <Widget>[];
      IqArea? lastArea;
      for (var i = 0; i < answered.length; i++) {
        final (puzzle, response) = answered[i];
        if (puzzle.area != lastArea) {
          lastArea = puzzle.area;
          final inArea = answered.where((a) => a.$1.area == puzzle.area).toList();
          children.add(_AreaHeader(
            area: puzzle.area,
            solved: inArea.where((a) => a.$1.isCorrect(a.$2)).length,
            total: inArea.length,
          ));
        }
        children.add(_ReviewRow(index: i, puzzle: puzzle, response: response));
      }
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
            child: Row(
              children: [
                IqRoundButton(
                  key: const ValueKey('iq-back'),
                  icon: Icons.arrow_back_rounded,
                  label: 'Zurück zum Ergebnis',
                  onPressed: onBack,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text('Rückblick',
                            style: iqText(24,
                                weight: FontWeight.w900, shadows: iqScrim)),
                      ),
                      Text(
                        '$solved von ${answered.length} Rätseln gelöst',
                        style: iqText(13.5,
                            color: const Color(0xFFDCE8F8), shadows: iqScrim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('iq-review-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _AreaHeader extends StatelessWidget {
  const _AreaHeader({required this.area, required this.solved, required this.total});

  final IqArea area;
  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final style = iqAreaStyle(area);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          IqAreaMedallion(area, size: 34, glow: false),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              area.title,
              style: iqText(17,
                  weight: FontWeight.w900,
                  color: Color.lerp(style.color, Colors.white, .25)!,
                  shadows: iqScrim),
            ),
          ),
          Text('$solved von $total gelöst',
              style: iqText(12.5,
                  color: const Color(0xFFDCE8F8), shadows: iqScrim)),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.index,
    required this.puzzle,
    required this.response,
  });

  final int index;
  final IqPuzzle puzzle;
  final List<int> response;

  @override
  Widget build(BuildContext context) {
    final correct = puzzle.isCorrect(response);
    final style = iqAreaStyle(puzzle.area);
    const good = Color(0xFF5BE39A);
    const open = Color(0xFFFFB067);
    final head = Row(
      children: [
        IqAreaMedallion(puzzle.area, size: 38, glow: false),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rätsel ${index + 1}',
                  style: iqText(15, weight: FontWeight.w900)),
              Text(puzzle.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: iqText(12.5, color: LumoVisualTokens.muted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IqChip(
          label: correct ? 'Gelöst' : 'Das üben wir noch',
          icon: correct ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
          color: correct ? good : open,
          dense: true,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        container: true,
        label: 'Rätsel ${index + 1}, ${puzzle.area.title}: '
            '${correct ? 'gelöst' : 'noch nicht gelöst'}',
        child: IqPanel(
          key: ValueKey('iq-review-row-$index'),
          radius: 20,
          accent: correct ? style.color : open,
          padding: const EdgeInsets.all(12),
          child: correct
              ? head
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    head,
                    const SizedBox(height: 12),
                    Text('Die richtige Lösung',
                        style: iqText(13.5, weight: FontWeight.w900, color: LumoVisualTokens.gold)),
                    const SizedBox(height: 8),
                    KeyedSubtree(
                      key: ValueKey('iq-review-solution-$index'),
                      child: IqSolutionView(puzzle),
                    ),
                    if (puzzle is IqNumberPuzzle || puzzle is IqMemoryPuzzle) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Du hattest: ${puzzle.describeResponse(response)}',
                        textAlign: TextAlign.center,
                        style: iqText(13, color: LumoVisualTokens.muted),
                      ),
                    ],
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: .06),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_rounded,
                                size: 20, color: LumoVisualTokens.gold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                puzzle.explanation,
                                style: iqText(13.5,
                                    weight: FontWeight.w700, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
