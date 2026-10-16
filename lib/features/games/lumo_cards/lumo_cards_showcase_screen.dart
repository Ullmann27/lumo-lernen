import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive entry to Lumo Cards built on the ORIGINAL approved key artwork.
/// The artwork is shown without recolouring or replacing the animal cast.
/// Gameplay stays in LumoCardsScreen and retains its real card rules and data.
class LumoCardsShowcaseScreen extends StatelessWidget {
  const LumoCardsShowcaseScreen({
    super.key,
    required this.onSolo,
    required this.onLocal,
  });

  final VoidCallback onSolo;
  final VoidCallback onLocal;

  static const referenceArt =
      'docs/lumo_game_specs/2026-10-05/03_cards/lumo_cards_key_art.webp';

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF031329),
      body: LayoutBuilder(
        builder: (context, box) {
          final landscape = box.maxWidth > box.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              // This asset was already part of the approved production
              // reference board; include it in Flutter's asset manifest,
              // rather than shipping an unrelated approximate illustration.
              RepaintBoundary(
                child: Image.asset(
                  referenceArt,
                  key: const ValueKey('cards-approved-reference-art'),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  semanticLabel:
                      'Lumo Cards: Lumo und seine Tierfreunde an einem magisch beleuchteten Kartentisch',
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF061D4A),
                          Color(0xFF064C80),
                          Color(0xFF061832),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/lumo_design/fox/fox_cards_welcome.png',
                        width: 200,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.style_rounded,
                                size: 100, color: Color(0xFF78EBFF)),
                      ),
                    ),
                  ),
                ),
              ),
              // The menu buttons are real widgets, never dead labels
              // embedded in a static background image.
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .65, .85, 1],
                        colors: [
                          Color(0x50011229),
                          Colors.transparent,
                          Color(0xD9031435),
                          Color(0xFC03122B),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 12,
                      child: Material(
                        color: const Color(0xD9082C55),
                        shape: const CircleBorder(
                          side: BorderSide(color: Color(0xFF65DFFF)),
                        ),
                        child: IconButton(
                          key: const ValueKey('cards-hub-back'),
                          tooltip: 'Zur Spielwelt zurück',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          landscape ? 22 : 15,
                          12,
                          landscape ? 22 : 15,
                          landscape ? 10 : 18,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'DEIN MAGISCHES KARTENABENTEUER',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Color(0xFFDBF8FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 7,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: landscape ? 7 : 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StartButton(
                                      key: const ValueKey('cards-hub-solo'),
                                      label: 'Solo spielen',
                                      icon: Icons.play_arrow_rounded,
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        onSolo();
                                      },
                                      primary: true,
                                      reduceMotion: reduceMotion,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StartButton(
                                      key: const ValueKey('cards-hub-local'),
                                      label: 'Mit Freunden',
                                      icon: Icons.groups_rounded,
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        onLocal();
                                      },
                                      primary: false,
                                      reduceMotion: reduceMotion,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StartButton extends StatefulWidget {
  const _StartButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.primary,
    required this.reduceMotion,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  final bool reduceMotion;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.primary
        ? const Color(0xFFFFC35C)
        : const Color(0xFF6FECFF);
    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedScale(
        duration: widget.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        scale: _pressed ? .97 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {
              setState(() => _pressed = false);
              widget.onPressed();
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: widget.primary
                      ? const [Color(0xFFFFCF64), Color(0xFFFF922D)]
                      : const [Color(0xFF0B609A), Color(0xFF07345D)],
                ),
                border: Border.all(color: accent, width: 1.7),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .32),
                    blurRadius: 17,
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 58),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon,
                          size: 23,
                          color: widget.primary
                              ? const Color(0xFF3C220A)
                              : Colors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: widget.primary
                                ? const Color(0xFF3C220A)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
