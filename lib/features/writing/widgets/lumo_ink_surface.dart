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
/// move the page beneath it, and cancel never saves an incomplete stroke.
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
  Size? _strokeSize;
  Matrix4? _strokeTransform;

  @override
  void initState() {
    super.initState();
    _InkContacts.attach();
  }

  @override
  void dispose() {
    _activePointer = null;
    _strokeSize = null;
    _strokeTransform = null;
    _InkContacts.release(this);
    _InkContacts.detach();
    super.dispose();
  }

  bool get _geometryUnchanged {
    final box = context.findRenderObject();
    return box is RenderBox &&
        box.attached &&
        box.hasSize &&
        box.size == _strokeSize &&
        MatrixUtils.matrixEquals(box.getTransformTo(null), _strokeTransform);
  }

  void _finish({required bool cancelled}) {
    _activePointer = null;
    _strokeSize = null;
    _strokeTransform = null;
    _InkContacts.release(this);
    if (cancelled) {
      widget.onCancel();
    } else {
      widget.onEnd();
    }
  }

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
          if (_activePointer != null || !_InkContacts.claim(this, event)) {
            return;
          }
          final box = context.findRenderObject()! as RenderBox;
          _activePointer = event.pointer;
          _strokeSize = box.size;
          _strokeTransform = box.getTransformTo(null);
          widget.onStart(event.localPosition);
        },
        onPointerMove: (event) {
          if (event.pointer == _activePointer) {
            // Flutter retains the pointer-down hit-test transform. A resize,
            // rotation or moved viewport makes its local positions stale.
            if (_geometryUnchanged) {
              widget.onUpdate(event.localPosition);
            } else {
              _finish(cancelled: true);
            }
          }
        },
        onPointerUp: (event) {
          if (event.pointer != _activePointer) return;
          _finish(cancelled: !_geometryUnchanged);
        },
        onPointerCancel: (event) {
          if (event.pointer != _activePointer) return;
          _finish(cancelled: true);
        },
        // Preserve the entire bounded canvas as a pointer hit target.
        child: SizedBox.expand(child: widget.child),
      ),
    );
  }
}

/// Observe contacts only while ink surfaces exist. An outside palm may already
/// be down when the pen lands, so observing starts before a stroke does. Only
/// the active stroke claims contacts, and only within its own Flutter view.
class _InkContacts {
  static final _contacts = <int, int>{};
  static int _surfaces = 0;
  static final _owners = <int, ({Object owner, int pointer})>{};

  static void attach() {
    if (_surfaces++ == 0) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_observe);
    }
  }

  static void detach() {
    if (--_surfaces == 0) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_observe);
      _contacts.clear();
      _owners.clear();
    }
  }

  static bool claim(Object owner, PointerDownEvent event) {
    if (_owners.containsKey(event.viewId)) return false;
    _owners[event.viewId] = (owner: owner, pointer: event.pointer);
    for (final contact in _contacts.entries) {
      if (contact.key != event.pointer && contact.value == event.viewId) {
        GestureBinding.instance.cancelPointer(contact.key);
      }
    }
    return true;
  }

  static void release(Object owner) {
    _owners.removeWhere((_, stroke) => identical(stroke.owner, owner));
  }

  static void _observe(PointerEvent event) {
    if (event is PointerDownEvent) {
      _contacts[event.pointer] = event.viewId;
      final stroke = _owners[event.viewId];
      if (stroke != null && event.pointer != stroke.pointer) {
        GestureBinding.instance.cancelPointer(event.pointer);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _contacts.remove(event.pointer);
    }
  }
}
