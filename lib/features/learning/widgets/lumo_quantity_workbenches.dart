import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_quantity_art.dart';

const _title = TextStyle(
    fontFamily: 'Nunito',
    color: LumoVisualTokens.white,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w900);
const _caption = TextStyle(
    fontFamily: 'Nunito',
    color: LumoVisualTokens.muted,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w700);

/// A child-controlled subtraction model. Marking a candy never submits an
/// answer, advances the task, or changes a stored observation.
class LumoSubtractionWorkbench extends StatelessWidget {
  const LumoSubtractionWorkbench({
    super.key,
    required this.start,
    required this.takeAway,
    required this.removed,
    required this.onChanged,
    this.enabled = true,
  })  : assert(start >= 0 && start <= 20),
        assert(takeAway >= 0 && takeAway <= start);

  final int start, takeAway;
  final Set<int> removed;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = removed.where((i) => i >= 0 && i < start).toSet();
    return _QuantitySurface(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Selbst wegnehmen', style: _title),
        const SizedBox(height: 6),
        Text(
            'Hier liegen $start Bonbons. Nimm $takeAway weg. '
            'Tippe noch einmal, um einen zurückzulegen.',
            style: _caption),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 10,
          children: List.generate(start, (index) {
            final taken = selected.contains(index);
            return Semantics(
              label:
                  'Bonbon ${index + 1}, ${taken ? 'weggenommen, zurücklegen' : 'wegnehmen'}',
              selected: taken,
              child: SizedBox(
                width: 52,
                height: 56,
                child: TextButton(
                  key: ValueKey('minus-quantity-$index'),
                  onPressed: enabled
                      ? () {
                          final next = {...selected};
                          if (!next.add(index)) next.remove(index);
                          onChanged(next);
                        }
                      : null,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(48, 48),
                      backgroundColor:
                          LumoVisualTokens.navigation.withValues(alpha: .5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: taken
                                  ? LumoVisualTokens.gold
                                  : LumoVisualTokens.cyan,
                              width: taken ? 2 : 1))),
                  child: ExcludeSemantics(
                      child: Stack(alignment: Alignment.center, children: [
                    Opacity(
                        opacity: taken ? .25 : 1,
                        child: const LumoQuantityArt.candy()),
                    if (taken)
                      const Icon(Icons.close_rounded,
                          color: LumoVisualTokens.white, size: 34),
                  ])),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Semantics(
            liveRegion: true,
            child: Text('Weggenommen: ${selected.length} · Auftrag: $takeAway',
                key: const ValueKey('minus-workbench-status'),
                textAlign: TextAlign.center,
                style: _title)),
        if (selected.length > takeAway) ...[
          const SizedBox(height: 6),
          const Text(
              'Du hast mehr weggenommen als im Auftrag. '
              'Du kannst Bonbons zurücklegen.',
              style: _caption),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('minus-workbench-reset'),
          onPressed:
              enabled && selected.isNotEmpty ? () => onChanged({}) : null,
          style: _buttonStyle,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Alle zurücklegen'),
        ),
      ],
    ));
  }
}

/// Every multiplication factor has a visible group, including 10 × 10.
/// Selecting a group marks the child's counting position, not correctness.
class LumoEqualGroupsWorkbench extends StatelessWidget {
  const LumoEqualGroupsWorkbench({
    super.key,
    required this.groups,
    required this.perGroup,
    required this.counted,
    required this.onChanged,
    this.enabled = true,
  })  : assert(groups >= 1 && groups <= 10),
        assert(perGroup >= 1 && perGroup <= 10);

  final int groups, perGroup;
  final Set<int> counted;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = counted.where((i) => i >= 0 && i < groups).toSet();
    return _QuantitySurface(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Gleich große Gruppen', style: _title),
        const SizedBox(height: 6),
        Text(
            '$groups Gruppen mit je $perGroup Steinen. '
            'Markiere jede Gruppe, die du schon gezählt hast.',
            style: _caption),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560
              ? 3
              : constraints.maxWidth >= 256
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(spacing: 10, runSpacing: 12, children: [
            for (var group = 0; group < groups; group++)
              SizedBox(
                width: width,
                child: Semantics(
                  label:
                      'Gruppe ${group + 1}, $perGroup Steine${selected.contains(group) ? ', gezählt' : ''}',
                  selected: selected.contains(group),
                  child: OutlinedButton(
                    key: ValueKey('times-group-$group'),
                    onPressed: enabled
                        ? () {
                            final next = {...selected};
                            if (!next.add(group)) next.remove(group);
                            onChanged(next);
                          }
                        : null,
                    style: _buttonStyle.copyWith(
                      backgroundColor: WidgetStatePropertyAll(
                          selected.contains(group)
                              ? const Color(0xFF285D70)
                              : const Color(0xFF0C2A48)),
                      side: WidgetStatePropertyAll(BorderSide(
                          color: selected.contains(group)
                              ? Colors.white
                              : LumoVisualTokens.cyan.withValues(alpha: .6),
                          width: selected.contains(group) ? 2 : 1)),
                    ),
                    child: ExcludeSemantics(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                              child:
                                  Text('Gruppe ${group + 1}', style: _caption)),
                          if (selected.contains(group))
                            const Icon(Icons.check_rounded,
                                size: 22, color: Colors.white),
                        ]),
                        const SizedBox(height: 10),
                        Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var stone = 0; stone < perGroup; stone++)
                                Container(
                                    key: ValueKey(
                                        'times-group-$group-stone-$stone'),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const RadialGradient(
                                            center: Alignment(-.5, -.6),
                                            radius: 1.2,
                                            colors: [
                                              Color(0xFFFFEDB0),
                                              Color(0xFFFFBD59),
                                              Color(0xFFB97026)
                                            ]),
                                        border: Border.all(
                                            color: const Color(0xFFFFE3A4)),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Color(0x88010A16),
                                              blurRadius: 2,
                                              offset: Offset(0, 2))
                                        ])),
                            ]),
                        const SizedBox(height: 10),
                        Text('je $perGroup',
                            textAlign: TextAlign.center, style: _caption),
                      ],
                    )),
                  ),
                ),
              ),
          ]);
        }),
        const SizedBox(height: 14),
        Semantics(
            liveRegion: true,
            child: Text('${selected.length} von $groups Gruppen markiert',
                key: const ValueKey('times-workbench-status'),
                textAlign: TextAlign.center,
                style: _caption)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
            key: const ValueKey('times-workbench-reset'),
            onPressed:
                enabled && selected.isNotEmpty ? () => onChanged({}) : null,
            style: _buttonStyle,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Markierungen lösen')),
      ],
    ));
  }
}

final _buttonStyle = OutlinedButton.styleFrom(
  minimumSize: const Size(48, 52),
  padding: const EdgeInsets.all(12),
  foregroundColor: LumoVisualTokens.white,
  disabledForegroundColor: LumoVisualTokens.muted.withValues(alpha: .55),
  side: BorderSide(color: LumoVisualTokens.cyan.withValues(alpha: .55)),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
);

class _QuantitySurface extends StatelessWidget {
  const _QuantitySurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF153D61),
                  Color(0xFF092645),
                  Color(0xFF071C35)
                ]),
            border:
                Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .45)),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66010A18), offset: Offset(0, 5), blurRadius: 8)
            ]),
        child: child,
      );
}
