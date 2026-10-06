import 'package:flutter/material.dart';

import '../../../../theme/lumo_visual_tokens.dart';
import '../../../../widgets/design/lumo_design_system.dart';
import '../lumo_cards_assets.dart';

/// Uses the existing four player portraits. The dialog stays bounded and
/// scrollable when a Fold changes size or a phone is held in landscape.
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

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? currentAvatarPath,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withAlpha(190),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: LumoAvatarPicker(
              title: title,
              currentAvatarPath: currentAvatarPath,
              onPick: (path) => Navigator.of(dialogContext).pop(path),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LumoVisualTokens.glass, LumoVisualTokens.night],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LumoVisualTokens.cyan, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x4037D2FD), blurRadius: 24),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Image.asset(
                LumoDesignFoxPose.avatar.assetPath,
                width: 48,
                height: 48,
                cacheWidth: 192,
                cacheHeight: 192,
                semanticLabel: 'Lumo',
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline_rounded,
                  color: LumoVisualTokens.cyan,
                  size: 40,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Auswahl schließen',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded,
                    color: LumoVisualTokens.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tippe auf dein Bild. Deine Karten bleiben erhalten.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: LumoVisualTokens.muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: [
              for (final path in LumoCardsAssets.allPlayerAvatars)
                _AvatarChoice(
                  key: ValueKey('cards-avatar-$path'),
                  assetPath: path,
                  label: 'Avatar ${LumoCardsAssets.allPlayerAvatars.indexOf(path) + 1}',
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
    super.key,
    required this.assetPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          // Portrait source files are 512px. Decode for the actual tile/DPR,
          // without requesting oversized textures on tablets or folded phones.
          final pixels = (constraints.maxWidth *
                  MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(128, 512);
          return Semantics(
            label: label,
            button: true,
            selected: selected,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LumoVisualTokens.glassRow,
                    border: Border.all(
                      color: selected
                          ? LumoVisualTokens.gold
                          : LumoVisualTokens.cyan,
                      width: selected ? 4 : 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      cacheWidth: pixels,
                      cacheHeight: pixels,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_outline_rounded,
                        color: LumoVisualTokens.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
