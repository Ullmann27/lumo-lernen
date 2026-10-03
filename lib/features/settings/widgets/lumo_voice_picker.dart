import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/lumo_voice.dart';

/// Liste der auf dem Geraet installierten deutschen Stimmen.
///
/// Heinz' Kinder fanden die automatisch gewaehlte Stimme nicht schoen.
/// Hier koennen Kind oder Eltern jede Stimme antippen: sie wird sofort
/// ausgewaehlt, Lumo spricht einen Probesatz, und die Wahl bleibt nach
/// einem Neustart erhalten. "Automatisch" nimmt wieder die beste Stimme.
class LumoVoicePicker extends StatefulWidget {
  const LumoVoicePicker({
    super.key,
    this.enabled = true,
    this.loadVoices,
    this.loadSavedVoiceName,
    this.onChoose,
  });

  /// Wenn false (Lumo-Stimme aus), ist die Liste sichtbar aber nicht tippbar.
  final bool enabled;

  /// Standard: [LumoVoice.germanVoices].
  final Future<List<LumoVoiceOption>> Function()? loadVoices;

  /// Standard: [LumoVoice.savedVoiceName].
  final Future<String?> Function()? loadSavedVoiceName;

  /// Wird mit der gewaehlten Stimme aufgerufen, `null` fuer "Automatisch".
  /// Liefert false, wenn das Geraet die Stimme nicht setzen konnte.
  /// Standard: Stimme setzen und bei Erfolg einen Probesatz sprechen.
  final Future<bool> Function(LumoVoiceOption? option)? onChoose;

  @override
  State<LumoVoicePicker> createState() => _LumoVoicePickerState();
}

class _LumoVoicePickerState extends State<LumoVoicePicker> {
  late Future<List<LumoVoiceOption>> _voices;
  String? _selectedName;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _voices = (widget.loadVoices ?? LumoVoice.instance.germanVoices)();
    (widget.loadSavedVoiceName ?? LumoVoice.instance.savedVoiceName)().then((name) {
      if (mounted) setState(() => _selectedName = name);
    });
  }

  Future<void> _choose(LumoVoiceOption? option) async {
    if (_busy) return;
    final previous = _selectedName;
    setState(() {
      _busy = true;
      _selectedName = option?.name;
    });
    var applied = false;
    try {
      applied = await (widget.onChoose ?? _chooseAndPreview)(option);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (!applied) _selectedName = previous;
        });
      }
    }
    if (!applied && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Diese Stimme kann das Gerät gerade nicht verwenden.')),
      );
    }
  }

  static Future<bool> _chooseAndPreview(LumoVoiceOption? option) async {
    final applied = await LumoVoice.instance.chooseVoice(option);
    if (applied) await LumoVoice.instance.test();
    return applied;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stimme aussuchen',
          style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900, color: LumoColors.ink900),
        ),
        const SizedBox(height: 2),
        Text(
          'Tippe auf eine Stimme: Lumo spricht sie dir vor und merkt sie sich.',
          style: LumoTextStyles.caption.copyWith(color: LumoColors.ink500),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<LumoVoiceOption>>(
          future: _voices,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
              );
            }
            final voices = snapshot.data ?? const <LumoVoiceOption>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VoiceTile(
                  key: const ValueKey('voice-auto'),
                  title: 'Automatisch',
                  subtitle: 'Lumo nimmt die beste installierte Stimme.',
                  selected: _selectedName == null,
                  enabled: widget.enabled && !_busy,
                  onTap: () => _choose(null),
                ),
                for (var i = 0; i < voices.length; i++)
                  _VoiceTile(
                    key: ValueKey('voice-${voices[i].name}'),
                    title: 'Stimme ${i + 1}',
                    subtitle: _describe(voices[i]),
                    detail: voices[i].name,
                    selected: _selectedName == voices[i].name,
                    enabled: widget.enabled && !_busy,
                    onTap: () => _choose(voices[i]),
                  ),
                if (voices.length < 2) ...[
                  const SizedBox(height: 6),
                  Text(
                    voices.isEmpty
                        ? 'Auf diesem Gerät wurden keine deutschen Stimmen gefunden.'
                        : 'Auf diesem Gerät ist nur eine deutsche Stimme installiert.',
                    style: LumoTextStyles.caption.copyWith(color: LumoColors.ink600),
                  ),
                  Text(
                    'Mehr Stimmen: In den Geräte-Einstellungen unter Sprache bzw. '
                    'Bedienungshilfen → Text-in-Sprache weitere deutsche Stimmen herunterladen.',
                    style: LumoTextStyles.caption.copyWith(color: LumoColors.ink500),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  static String _describe(LumoVoiceOption v) {
    final parts = <String>[
      v.regionLabel,
      if (v.qualityLabel.isNotEmpty) v.qualityLabel,
      if (v.networkRequired) 'braucht Internet',
    ];
    return parts.join(' · ');
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.detail,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? LumoColors.orange : LumoColors.ink300;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? LumoColors.orangeSurface : Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(LumoRadius.sm),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LumoRadius.sm),
              border: Border.all(color: selected ? LumoColors.orange : LumoColors.ink100, width: selected ? 1.6 : 1.0),
            ),
            child: Row(
              children: [
                Icon(selected ? Icons.record_voice_over_rounded : Icons.play_circle_outline_rounded, color: accent, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: LumoTextStyles.body.copyWith(
                          fontWeight: FontWeight.w900,
                          color: selected ? LumoColors.orange : LumoColors.ink900,
                        ),
                      ),
                      Text(subtitle, style: LumoTextStyles.caption.copyWith(color: LumoColors.ink600)),
                      if (detail != null)
                        Text(
                          detail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LumoTextStyles.caption.copyWith(fontSize: 10),
                        ),
                    ],
                  ),
                ),
                if (selected) const Icon(Icons.check_circle_rounded, color: LumoColors.orange, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
