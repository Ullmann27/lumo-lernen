import 'package:flutter/material.dart';

/// Additive presentation component. The caller retains all game state,
/// actions, card validation, animation controllers and app navigation.
/// Not integrated or visually approved by runtime comparison yet.
class ApprovedCardsBoard extends StatelessWidget {
  const ApprovedCardsBoard({
    super.key,
    required this.background,
    required this.opponents,
    required this.drawPile,
    required this.discardPile,
    required this.lumo,
    required this.status,
    required this.hand,
    required this.actions,
  });

  final Widget background;
  final Widget opponents;
  final Widget drawPile;
  final Widget discardPile;
  final Widget lumo;
  final Widget status;
  final Widget hand;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final short = constraints.maxHeight < 480;
      final padding = short ? 8.0 : 16.0;
      final board = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          opponents,
          SizedBox(height: padding),
          status,
          SizedBox(height: padding),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(flex: compact ? 2 : 3, child: lumo),
              SizedBox(width: padding),
              Expanded(
                flex: 7,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: drawPile),
                    SizedBox(width: padding),
                    Expanded(child: discardPile),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: padding),
          hand,
          SizedBox(height: padding),
          actions,
        ],
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: background)),
            SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: board,
            ),
          ],
        ),
      );
    });
  }
}
