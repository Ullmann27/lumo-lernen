import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A stationary writing surface inside an otherwise scrollable lesson.
///
/// Flutter's regular pan recognizer competes with the parent's vertical
/// ScrollView on straight up/down letter strokes (I, l, t, ...).
/// An eager recognizer reserves pointers that start inside this surface,
/// while the Listener forwards their exact local coordinates. The rest of
/// the page remains scrollable with gestures that start OUTSIDE the canvas.
///
/// There is exactly one active writing pointer. A second finger cannot
/// corrupt a letter, and cancel never saves an incomplete stroke.
class LumoInkSurface extends StatefulWidget {
  const LumoInkSurface({
    super.key,
    required this.child,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final Widget child;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  State<LumoInkSurface> createState() => _LumoInkSurfaceState();
}

class _LumoInkSurfaceState extends State<LumoInkSurface> {
  int? _activePointer;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
          () => EagerGestureRecognizer(),
          (_) {},
        ),
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (_activePointer != null) return;
          _activePointer = event.pointer;
          widget.onStart(event.localPosition);
        },
        onPointerMove: (event) {
          if (event.pointer == _activePointer) {
            widget.onUpdate(event.localPosition);
          }
        },
        onPointerUp: (event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          widget.onEnd();
        },
        onPointerCancel: (event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          widget.onCancel();
        },
        child: widget.child,
      ),
    );
  }
}
