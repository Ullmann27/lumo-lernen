import 'package:flutter/material.dart';

import '../lumo_cards_bot_policy.dart';

/// Real opponent controls. The owner pauses the current round while open.
class LumoCardsOpponentSettings extends StatefulWidget {
  const LumoCardsOpponentSettings({
    super.key,
    required this.difficulty,
    required this.style,
    required this.onChanged,
  });

  final LumoCardsDifficulty difficulty;
  final LumoCardsStyle style;
  final void Function(LumoCardsDifficulty, LumoCardsStyle) onChanged;

  @override
  State<LumoCardsOpponentSettings> createState() =>
      _LumoCardsOpponentSettingsState();
}

class _LumoCardsOpponentSettingsState
    extends State<LumoCardsOpponentSettings> {
  late LumoCardsDifficulty _difficulty = widget.difficulty;
  late LumoCardsStyle _style = widget.style;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Spiele mit Lumo',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Wie knifflig darf es sein?'),
              const SizedBox(height: 8),
              for (final level in LumoCardsDifficulty.values)
                _choice(
                  key: ValueKey('cards-level-${level.name}'),
                  title: level.label,
                  description: level.description,
                  selected: _difficulty == level,
                  onTap: () => setState(() => _difficulty = level),
                ),
              const SizedBox(height: 16),
              const Text('Lumos Spielweise'),
              const SizedBox(height: 8),
              for (final style in LumoCardsStyle.values)
                _choice(
                  key: ValueKey('cards-style-${style.name}'),
                  title: style.label,
                  description: style.description,
                  selected: _style == style,
                  onTap: () => setState(() => _style = style),
                ),
              const SizedBox(height: 12),
              const Text(
                'Deine Karten bleiben gleich. Die Lernfragen passen weiter zu deiner Klasse.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('cards-opponent-apply'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 52),
                ),
                onPressed: () {
                  widget.onChanged(_difficulty, _style);
                  Navigator.of(context).pop();
                },
                child: const Text('Übernehmen'),
              ),
            ],
          ),
        ),
      );

  Widget _choice({
    required Key key,
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: selected
                ? const Color(0xFFE0F3FF)
                : const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: key,
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
