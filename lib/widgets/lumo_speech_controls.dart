import 'dart:async';

import 'package:flutter/material.dart';

import '../core/lumo_voice.dart';

/// Controls the existing central Sulafat player, never another audio path.
/// Pausing preserves the native source/position. Stop intentionally does not.
class LumoSpeechControls extends StatelessWidget {
  const LumoSpeechControls({
    super.key,
    this.onRead,
    this.showUnavailableNotice = false,
    this.showStopWhenIdle = false,
  });

  final VoidCallback? onRead;
  final bool showUnavailableNotice;
  final bool showStopWhenIdle;

  @override
  Widget build(BuildContext context) {
    final voice = LumoVoice.instance;
    final touchStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
    );
    return ValueListenableBuilder<VoiceStatus>(
      valueListenable: voice.status,
      builder: (_, status, __) {
        final active = status == VoiceStatus.speaking ||
            status == VoiceStatus.paused ||
            status == VoiceStatus.preparing;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (onRead != null && !active)
                  OutlinedButton.icon(
                    style: touchStyle,
                    onPressed: onRead,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Vorlesen'),
                  ),
                if (status == VoiceStatus.speaking)
                  OutlinedButton.icon(
                    style: touchStyle,
                    onPressed: () => unawaited(voice.pause()),
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Pause'),
                  ),
                if (status == VoiceStatus.paused)
                  FilledButton.icon(
                    style: touchStyle,
                    onPressed: () => unawaited(voice.resume()),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Fortsetzen'),
                  ),
                if (active || showStopWhenIdle)
                  OutlinedButton.icon(
                    style: touchStyle,
                    onPressed: () => unawaited(voice.stop()),
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stopp'),
                  ),
              ],
            ),
            if (showUnavailableNotice)
              ValueListenableBuilder<String?>(
                valueListenable: voice.lastError,
                builder: (_, error, __) => error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          voice.cloudVoiceEnabled
                              ? 'Vorlesen klappt gerade nicht. '
                                  'Du kannst hier weiterlesen.'
                              : 'Dieser Text ist zum Lesen da. '
                                  'Eine passende Lumo-Aufnahme ist noch nicht verfügbar.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}
