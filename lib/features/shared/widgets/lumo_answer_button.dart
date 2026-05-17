import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';

/// Zustand eines LumoAnswerButton.
enum LumoAnswerState {
  /// Standard - noch nicht gewaehlt.
  normal,

  /// Aktuell gedrueckt (visuell, kurz).
  pressed,

  /// Vom Kind ausgewaehlt (vor Aufloesung).
  selected,

  /// Aufgeloest - richtig (gruener Glow + Check).
  correct,

  /// Aufgeloest - falsch (Pfirsich-Outline + X).
  wrong,

  /// Deaktiviert (z.B. nach 50:50 versteckt).
  disabled,
}

/// Zentraler Antwort-Button fuer alle Aufgaben in der App.
///
/// Eine Stelle - alle Zustaende. Ersetzt die inline-Buttons in
/// learning_content.dart und quiz_show_content.dart schrittweise.
///
/// Groesse: min 56px hoch (Material-Touchminimum), 72px wenn isPrimary.
/// Schatten: weich, mit Status-Color tint.
/// Hapti: light bei normal-tap, medium bei correct, heavy bei wrong.
class LumoAnswerButton extends StatefulWidget {
  const LumoAnswerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.state = LumoAnswerState.normal,
    this.isPrimary = false,
    this.icon,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onTap;
  final LumoAnswerState state;
  final bool isPrimary;
  final IconData? icon;
  final String? tooltip;

  @override
  State<LumoAnswerButton> createState() => _LumoAnswerButtonState();
}

class _LumoAnswerButtonState extends State<LumoAnswerButton> {
  bool _pressed = false;

  // ─── Farben pro Zustand ───
  Color _fg(BuildContext context) {
    switch (widget.state) {
      case LumoAnswerState.correct: return Colors.white;
      case LumoAnswerState.wrong: return const Color(0xFF7C2D12);
      case LumoAnswerState.selected: return Colors.white;
      case LumoAnswerState.disabled: return LumoColors.ink400;
      default: return LumoColors.ink900;
    }
  }

  Color _bg(BuildContext context) {
    switch (widget.state) {
      case LumoAnswerState.correct: return const Color(0xFF10B981);
      case LumoAnswerState.wrong: return const Color(0xFFFED7AA);
      case LumoAnswerState.selected: return LumoColors.orange;
      case LumoAnswerState.disabled: return const Color(0xFFF5F5F5);
      default: return Colors.white;
    }
  }

  Color _border() {
    switch (widget.state) {
      case LumoAnswerState.correct: return const Color(0xFF059669);
      case LumoAnswerState.wrong: return const Color(0xFFEA580C);
      case LumoAnswerState.selected: return const Color(0xFFD97706);
      case LumoAnswerState.disabled: return const Color(0xFFE0E0E0);
      default: return LumoColors.ink100;
    }
  }

  List<BoxShadow> _shadow() {
    if (widget.state == LumoAnswerState.disabled) return const <BoxShadow>[];
    if (widget.state == LumoAnswerState.correct) {
      return [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -2)];
    }
    if (widget.state == LumoAnswerState.wrong) {
      return [BoxShadow(color: const Color(0xFFEA580C).withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 4))];
    }
    if (widget.state == LumoAnswerState.selected) {
      return [BoxShadow(color: LumoColors.orange.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -2)];
    }
    return [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))];
  }

  IconData? _statusIcon() {
    switch (widget.state) {
      case LumoAnswerState.correct: return Icons.check_circle_rounded;
      case LumoAnswerState.wrong: return Icons.cancel_outlined;
      case LumoAnswerState.disabled: return Icons.block_rounded;
      default: return null;
    }
  }

  void _handleTap() {
    if (widget.state == LumoAnswerState.disabled || widget.onTap == null) return;
    switch (widget.state) {
      case LumoAnswerState.correct:
        HapticFeedback.mediumImpact();
        break;
      case LumoAnswerState.wrong:
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.lightImpact();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final minHeight = widget.isPrimary ? 72.0 : 56.0;
    final fontSize = widget.isPrimary ? 19.0 : 16.0;
    final scale = _pressed && widget.state != LumoAnswerState.disabled ? 0.97 : 1.0;
    final btn = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: _bg(context),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: _border(), width: 2),
          boxShadow: _shadow(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: _fg(context), size: 22),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: _fg(context),
                ),
              ),
            ),
            if (_statusIcon() != null) ...[
              const SizedBox(width: 8),
              Icon(_statusIcon(), color: _fg(context), size: 22),
            ],
          ],
        ),
      ),
    );

    final tappable = Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: btn,
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: tappable);
    }
    return tappable;
  }
}
