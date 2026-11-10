import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive Cards entry with the original goggled, jacketed Lumo.
/// Every title and action is a native widget; the character art is decoration.
/// Gameplay stays in LumoCardsScreen and retains its real card rules and data.
class LumoCardsShowcaseScreen extends StatelessWidget {
  const LumoCardsShowcaseScreen({
    super.key,
    required this.onSolo,
    required this.onLocal,
  });

  final VoidCallback onSolo;
  final VoidCallback onLocal;

  static const referenceArt = 'assets/lumo_design/fox/fox_cards_welcome.png';

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
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -.25),
                    radius: 1.1,
                    colors: [
                      Color(0xFF155A80),
                      Color(0xFF082C53),
                      Color(0xFF031329),
                    ],
                  ),
                ),
              ),
              RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    76,
                    24,
                    landscape ? 108 : 236,
                  ),
                  child: Image.asset(
                    referenceArt,
                    key: const ValueKey('cards-approved-reference-art'),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    semanticLabel:
                        'Original-Lumo mit blauer Brille, Jacke und Spielkarten',
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.style_rounded,
                        size: 100,
                        color: Color(0xFF78EBFF),
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
                    const Positioned(
                      top: 18,
                      left: 76,
                      right: 20,
                      child: Text(
                        'LUMO CARDS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Color(0xFFFFD174),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
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
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
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
                                    Shadow(color: Colors.black, blurRadius: 7),
                                  ],
                                ),
                              ),
                              SizedBox(height: landscape ? 7 : 10),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xE0082455),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: const Color(0xAA53DDFD),
                                    width: 1.6,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x99010A22),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(landscape ? 10 : 12),
                                  child: landscape
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: _StartButton(
                                                key: const ValueKey(
                                                    'cards-hub-solo'),
                                                label: 'Solo spielen',
                                                icon: Icons.play_arrow_rounded,
                                                onPressed: () {
                                                  HapticFeedback.mediumImpact();
                                                  onSolo();
                                                },
                                                primary: true,
                                                reduceMotion: reduceMotion,
                                                compact: true,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _StartButton(
                                                key: const ValueKey(
                                                    'cards-hub-local'),
                                                label: 'Mit Freunden',
                                                icon: Icons.groups_rounded,
                                                onPressed: () {
                                                  HapticFeedback.mediumImpact();
                                                  onLocal();
                                                },
                                                primary: false,
                                                reduceMotion: reduceMotion,
                                                compact: true,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: _StartButton(
                                              key: const ValueKey(
                                                  'cards-hub-solo'),
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
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              child: _StartButton(
                                              key: const ValueKey(
                                                  'cards-hub-local'),
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
                                ),
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
    this.compact = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  final bool reduceMotion;
  final bool compact;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.primary
        ? const Color(0xFFFFE08A)
        : const Color(0xFF9AF2FF);
    final ink = widget.primary
        ? const Color(0xFF3C220A)
        : Colors.white;
    final minH = widget.compact ? 60.0 : 66.0;
    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedContainer(
        duration: widget.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.primary
                ? const [Color(0xFFFFE08A), Color(0xFFFFC35C), Color(0xFFFF8A1F)]
                : const [Color(0xFF1A8AD0), Color(0xFF0B609A), Color(0xFF062845)],
          ),
          border: Border.all(color: accent, width: 2),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                    color: Color(0x66010A22),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x99010A22),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: .42),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0x88FFFFFF),
            highlightColor: const Color(0x33FFFFFF),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onTap: widget.onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: Stack(alignment: Alignment.center, children: [
                const Positioned(
                  top: 0,
                  left: 8,
                  right: 8,
                  height: 20,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: widget.compact ? 24 : 28, color: ink),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: widget.compact ? 16 : 18,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                      ),
                      if (!widget.compact) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.play_arrow_rounded, size: 26, color: ink),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
