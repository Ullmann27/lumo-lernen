import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Large tactile orange CTA inspired by the modern Lumo reference design.
///
/// Presentation-only widget. It does not own learning state or navigation.
class LumoPrimaryCta extends StatefulWidget {
  const LumoPrimaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.enabled = true,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool enabled;
  final bool expand;
  final EdgeInsetsGeometry padding;

  @override
  State<LumoPrimaryCta> createState() => _LumoPrimaryCtaState();
}

class _LumoPrimaryCtaState extends State<LumoPrimaryCta> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null;
    final button = AnimatedScale(
      scale: _pressed ? .97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: active ? 1 : .55,
        duration: const Duration(milliseconds: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[LumoColors.orangeLight, LumoColors.orange],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            border: Border.all(color: Colors.white.withOpacity(.60), width: 1.3),
            boxShadow: LumoShadow.pill,
          ),
          child: Padding(
            padding: widget.padding,
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: .15,
                    ),
                  ),
                ),
                if (widget.trailingIcon != null) ...<Widget>[
                  const SizedBox(width: 10),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.28),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.trailingIcon, color: Colors.white, size: 22),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: active ? (_) => _setPressed(true) : null,
      onTapCancel: active ? () => _setPressed(false) : null,
      onTapUp: active
          ? (_) {
              _setPressed(false);
              widget.onPressed?.call();
            }
          : null,
      child: widget.expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
