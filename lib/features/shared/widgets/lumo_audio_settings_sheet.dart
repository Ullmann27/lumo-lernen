// ════════════════════════════════════════════════════════════════════════
// LUMO AUDIO SETTINGS SHEET — Music + SFX Toggles als Bottom-Sheet
// ════════════════════════════════════════════════════════════════════════
// PR I (Heinz 2026-05-23). Erste sichtbare User-Kontrolle ueber die
// Audio-Pipeline aus PR #94 (LumoSound) + PR H3 (LumoMusic).
//
// Verwendung:
//   showModalBottomSheet(
//     context: context,
//     showDragHandle: true,
//     builder: (_) => LumoAudioSettingsSheet(
//       onMusicEnabled: () =>
//           LumoMusic.instance.play(LumoMusicTrack.chillLoop),
//     ),
//   );
//
// Verhalten:
//   - Music-Toggle aus -> LumoMusic.muted=true -> stop() ist intern
//     im setter, Audio sofort still.
//   - Music-Toggle an -> LumoMusic.muted=false, dann onMusicEnabled-
//     Callback (Caller kennt den richtigen Track fuer den aktuellen
//     Screen).
//   - SFX-Toggle wirkt auf LumoSound.muted; persistiert beides via
//     SharedPreferences.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../../core/lumo_music.dart';
import '../../../core/lumo_sound.dart';
import '../../../theme/lumo_visual_tokens.dart';

class LumoAudioSettingsSheet extends StatefulWidget {
  const LumoAudioSettingsSheet({
    super.key,
    this.onMusicEnabled,
  });

  /// Wird aufgerufen wenn der Music-Toggle von muted -> unmuted wechselt.
  /// Caller entscheidet welcher Track jetzt starten soll (chillLoop
  /// auf Lumo Cards, energeticLoop in einem Action-Spiel, etc.).
  final VoidCallback? onMusicEnabled;

  @override
  State<LumoAudioSettingsSheet> createState() =>
      _LumoAudioSettingsSheetState();
}

class _LumoAudioSettingsSheetState extends State<LumoAudioSettingsSheet> {
  late bool _musicOn;
  late bool _sfxOn;

  @override
  void initState() {
    super.initState();
    _musicOn = !LumoMusic.instance.muted;
    _sfxOn = !LumoSound.instance.muted;
  }

  void _toggleMusic(bool on) {
    setState(() => _musicOn = on);
    LumoMusic.instance.muted = !on;
    if (on) widget.onMusicEnabled?.call();
  }

  void _toggleSfx(bool on) {
    setState(() => _sfxOn = on);
    LumoSound.instance.muted = !on;
    // Kurzer Klick als Bestaetigung (nur wenn SFX gerade aktiviert wurde).
    if (on) LumoSound.instance.play(SoundEffect.click);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'Ton',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: LumoVisualTokens.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _AudioRow(
              icon: Icons.music_note_rounded,
              label: 'Musik',
              sublabel: 'Ruhige Hintergrund-Musik im Spiel',
              value: _musicOn,
              onChanged: _toggleMusic,
              activeColor: LumoVisualTokens.cyanBright,
            ),
            const SizedBox(height: 4),
            _AudioRow(
              icon: Icons.volume_up_rounded,
              label: 'Sound-Effekte',
              sublabel: 'Klick, Karten-Whoosh, Sieg-Fanfare',
              value: _sfxOn,
              onChanged: _toggleSfx,
              activeColor: LumoVisualTokens.cyan,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fertig',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.cyanBright,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    // 2026-06-05 Bugfix (Heinz Tablet-Screenshot): vorher Container ->
    // direkt SwitchListTile. Flutter warnte 'ListTile background color or
    // ink splashes may be invisible'. Fix: Material-Layer zwischen Container
    // und SwitchListTile damit Ink-Effekte sichtbar bleiben + Warnings
    // verschwinden. ClipRRect haelt die rounded corners sichtbar.
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF103B6A), Color(0xFF05254B)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LumoVisualTokens.cyan.withOpacity(0.42),
          width: 1.4,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activeColor.withOpacity(value ? 0.80 : 0.24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: LumoVisualTokens.white,
          ),
        ),
        subtitle: Text(
          sublabel,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LumoVisualTokens.muted,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      ),
      ), // close Material
      ), // close Container
    ); // close ClipRRect
  }
}
