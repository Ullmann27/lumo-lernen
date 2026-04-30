import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';

/// Grosser glaenzender Haupt-CTA-Button nach Referenzbild.
///
/// "Deutsch Aufgabe starten" / "Mathe Aufgabe starten" / "Naechste Aufgabe"
/// Mit:
///   - linkem Icon (Rakete fuer Start, Pfeil fuer naechste)
///   - grosser fetter Text in der Mitte
///   - rechtem Pfeil-Indikator in heller Pille
///   - sanftem Glow drum herum
///   - leichten Stern-Sparkle links und rechts
class LumoBigCtaButton extends StatefulWidget {
  const LumoBigCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingEmoji = '🚀',
    this.color = LumoColors.orange,
    this.showSparkles = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final String leadingEmoji;
  final Color color;
  final bool showSparkles;

  @override
  State<LumoBigCtaButton> createState() => _LumoBigCtaButtonState();
}

class _LumoBigCtaButtonState extends State<LumoBigCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final reduced = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final t = reduced ? 0.5 : Curves.easeInOutSine.transform(_glow.value);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (widget.showSparkles) ...[
              Positioned(
                left: -6,
                top: -2,
                child: Opacity(
                  opacity: 0.5 + t * 0.5,
                  child: const Text('✨', style: TextStyle(fontSize: 16)),
                ),
              ),
              Positioned(
                right: -6,
                bottom: -2,
                child: Opacity(
                  opacity: 0.5 + (1 - t) * 0.5,
                  child: const Text('✨', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: disabled
                        ? null
                        : LinearGradient(
                            colors: [
                              widget.color,
                              Color.lerp(widget.color, Colors.black, 0.10)!,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    color: disabled ? const Color(0xFFE5DCD3) : null,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: disabled
                        ? null
                        : [
                            BoxShadow(
                              color: widget.color.withOpacity(0.45),
                              blurRadius: 22 + t * 8,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.leadingEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
