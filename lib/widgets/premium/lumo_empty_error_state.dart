// ════════════════════════════════════════════════════════════════════════
// LUMO EMPTY/ERROR STATE — Freundliche Leer-/Fehler-UI
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';
import 'lumo_premium_card.dart';

class LumoEmptyErrorState extends StatelessWidget {
  const LumoEmptyErrorState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.cloud_off_rounded,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  /// Kuerzere Vorlage fuer Inline-Fehler.
  const LumoEmptyErrorState.cloud({
    super.key,
    this.title = 'Cloud gerade nicht erreichbar',
    this.message =
        'Mein Online-Lehrer ist gerade weg. Wir koennen aber offline weiter ueben!',
    this.icon = Icons.cloud_off_rounded,
    this.iconColor,
    this.actionLabel = 'Nochmal versuchen',
    this.onAction,
    this.compact = false,
  });

  const LumoEmptyErrorState.empty({
    super.key,
    this.title = 'Hier ist noch nichts',
    this.message = 'Sobald du loslegst, fuelle ich diesen Bereich!',
    this.icon = Icons.auto_awesome_rounded,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? LumoTokens.colors.lumoOrange;
    return LumoPremiumCard(
      padding: EdgeInsets.all(compact ? LumoTokens.space16 : LumoTokens.space24),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 56,
            height: compact ? 40 : 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: compact ? 20 : 28),
          ),
          const SizedBox(width: LumoTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: (compact
                          ? LumoTokens.typo.titleMedium
                          : LumoTokens.typo.headlineSmall)
                      .copyWith(color: LumoTokens.colors.textDark),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: LumoTokens.typo.bodyMedium.copyWith(
                      color: LumoTokens.colors.textMuted,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: LumoTokens.space8),
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(actionLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      textStyle: LumoTokens.typo.labelLarge,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
