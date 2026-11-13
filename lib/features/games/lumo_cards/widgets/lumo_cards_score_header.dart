import 'package:flutter/material.dart';

class LumoCardsScoreHeader extends StatelessWidget {
  const LumoCardsScoreHeader({
    super.key,
    required this.round,
    required this.totalRounds,
    required this.targetPoints,
    this.onClose,
    this.onEmoji,
    this.onSettings,
    this.onAudioSettings,
    this.onOpponentSettings,
    this.onNativeTable,
  });

  final int round;
  final int totalRounds;
  final int targetPoints;
  final VoidCallback? onClose;
  final VoidCallback? onEmoji;
  final VoidCallback? onSettings;
  final VoidCallback? onAudioSettings;
  final VoidCallback? onOpponentSettings;
  final VoidCallback? onNativeTable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final buttons = actions;
      final availableWidth = constraints.maxWidth - 16;
      final actionWidth = buttons.length * 48.0;
      final narrow = availableWidth < 176 + actionWidth;
      // A short landscape layout places this header in a narrow side column.
      // Keep the score readable instead of squeezing it to a few pixels next
      // to all actions, which pushes the actual turn banner off-screen.
      final separateScore = narrow && availableWidth < actionWidth + 96;
      final titleRow = Row(children: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          visualDensity: VisualDensity.standard,
          tooltip: 'Pausieren / Zurück',
          onPressed: onClose,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Expanded(
            child: Text('Lumo Cards',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        if (!narrow) ...buttons,
      ]);
      final score = Text(
        narrow
            ? 'Runde $round/$totalRounds${separateScore ? ' · ' : '\n'}$targetPoints Sterne'
            : 'Runde $round/$totalRounds · $targetPoints gesammelte Sterne',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      );
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 8, vertical: separateScore ? 2 : 4),
        child: Column(children: [
          titleRow,
          if (separateScore) ...[
            score,
            Wrap(alignment: WrapAlignment.center, children: buttons),
          ] else if (narrow)
            Row(children: [Expanded(child: score), ...buttons])
          else
            score,
        ]),
      );
    });
  }

  List<Widget> get actions => [
        if (onNativeTable != null)
          IconButton(
              key: const ValueKey('cards-native-table'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              visualDensity: VisualDensity.standard,
              tooltip: 'Am 3D-Tisch spielen',
              onPressed: onNativeTable,
              icon: const Text('3D',
                  style: TextStyle(fontWeight: FontWeight.w900))),
        if (onOpponentSettings != null)
          IconButton(
              key: const ValueKey('cards-opponent-settings'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              visualDensity: VisualDensity.standard,
              tooltip: 'Lumos Spielstärke',
              onPressed: onOpponentSettings,
              icon: const Icon(Icons.psychology_rounded)),
        if (onEmoji != null)
          IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              visualDensity: VisualDensity.standard,
              tooltip: 'Avatar',
              onPressed: onEmoji,
              icon: const Icon(Icons.emoji_emotions_rounded)),
        if (onAudioSettings != null)
          IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              visualDensity: VisualDensity.standard,
              tooltip: 'Ton einstellen',
              onPressed: onAudioSettings,
              icon: const Icon(Icons.volume_up_rounded)),
        if (onSettings != null)
          IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              visualDensity: VisualDensity.standard,
              tooltip: 'Pause und Neustart',
              onPressed: onSettings,
              icon: const Icon(Icons.pause_rounded)),
      ];
}
