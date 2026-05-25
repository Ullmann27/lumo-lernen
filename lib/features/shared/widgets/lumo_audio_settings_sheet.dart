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
                  color: Color(0xFF1F2937),
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
              activeColor: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 4),
            _AudioRow(
              icon: Icons.volume_up_rounded,
              label: 'Sound-Effekte',
              sublabel: 'Klick, Karten-Whoosh, Sieg-Fanfare',
              value: _sfxOn,
              onChanged: _toggleSfx,
              activeColor: const Color(0xFFFF7A2F),
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
                    color: Color(0xFFFF7A2F),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF7A2F).withOpacity(0.18),
          width: 1.4,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activeColor.withOpacity(value ? 1.0 : 0.35),
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
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          sublabel,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      ),
    );
  }
}
