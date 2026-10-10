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
  });

  final int round;
  final int totalRounds;
  final int targetPoints;
  final VoidCallback? onClose;
  final VoidCallback? onEmoji;
  final VoidCallback? onSettings;
  final VoidCallback? onAudioSettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 320;
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
        if (!narrow) ...actions,
      ]);
      final score = Text(
        narrow
            ? 'Runde $round/$totalRounds\n$targetPoints Sterne'
            : 'Runde $round/$totalRounds · $targetPoints gesammelte Sterne',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(children: [
          titleRow,
          if (narrow)
            Row(children: [Expanded(child: score), ...actions])
          else
            score,
        ]),
      );
    });
  }

  List<Widget> get actions => [
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
