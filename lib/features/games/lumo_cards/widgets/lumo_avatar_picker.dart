// ════════════════════════════════════════════════════════════════════════
// LUMO AVATAR PICKER — waehle deinen Spieler-Avatar
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-05-22: 'Hauptspieler unten bekommt Avatar, Avatar-Picker
// am Spielstart'. Zeigt die 4 Avatare aus Heinz' Sub-Asset-Pack als
// runde Bilder zur Auswahl.
//
// Wird als Modal-Bottom-Sheet oder Overlay gezeigt. Auswahl wird in
// SharedPreferences gespeichert damit das Kind beim naechsten Start
// nicht nochmal waehlen muss.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_assets.dart';

class LumoAvatarPicker extends StatelessWidget {
  const LumoAvatarPicker({
    super.key,
    required this.title,
    required this.onPick,
    this.currentAvatarPath,
  });

  final String title;
  final String? currentAvatarPath;
  final void Function(String assetPath) onPick;

  /// Komfort-Wrapper: zeigt den Picker als Voll-Overlay-Dialog.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? currentAvatarPath,
  }) async {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: LumoAvatarPicker(
          title: title,
          currentAvatarPath: currentAvatarPath,
          onPick: (path) => Navigator.of(dialogContext).pop(path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E7), Color(0xFFFFE0B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF7A2F), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🦊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7C2D12),
            ),
          ),
          const SizedBox(height: 18),
          // 2x2 Grid der vier Avatare.
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.0,
            children: [
              for (final path in LumoCardsAssets.allPlayerAvatars)
                _AvatarChoice(
                  assetPath: path,
                  selected: path == currentAvatarPath,
                  onTap: () => onPick(path),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ringColor =
        selected ? const Color(0xFFFCD34D) : const Color(0xFFFF7A2F);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: selected ? 4 : 2.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFCD34D).withOpacity(0.6),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFFFE0B8),
              alignment: Alignment.center,
              child: const Text('🙂', style: TextStyle(fontSize: 32)),
            ),
          ),
        ),
      ),
    );
  }
}
