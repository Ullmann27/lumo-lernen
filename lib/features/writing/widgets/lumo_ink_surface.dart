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
  final _scrollPositions = <ScrollPosition>{};
  final _scrollHolds = <ScrollPosition, ScrollHoldController>{};

  @override
  void initState() {
    super.initState();
    _InkContacts.attach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final positions = <ScrollPosition>{};
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      positions.add(scrollable.position);
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    for (final position in _scrollPositions.difference(positions)) {
      _scrollHolds.remove(position)?.cancel();
      _InkScrollHosts.detach(position);
    }
    for (final position in positions.difference(_scrollPositions)) {
      _InkScrollHosts.attach(position);
    }
    _scrollPositions
      ..clear()
      ..addAll(positions);
  }

  void _stopScrolling() {
    for (final position in _scrollPositions) {
      if (position.isScrollingNotifier.value) {
        _scrollHolds[position] = position.hold(() {
          _scrollHolds.remove(position);
        });
      }
    }
  }

  void _releaseScrollHolds() {
    final holds = _scrollHolds.values.toList();
    _scrollHolds.clear();
    for (final hold in holds) {
      hold.cancel();
    }
  }

  @override
  void dispose() {
    _activePointer = null;
    _strokeSize = null;
    _strokeTransform = null;
    _releaseScrollHolds();
    for (final position in _scrollPositions) {
      _InkScrollHosts.detach(position);
    }
    _scrollPositions.clear();
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
    _releaseScrollHolds();
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
          _stopScrolling();
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

/// Scrollable normally removes its children from hit testing during a drag or
/// ballistic animation. A writing page must still let the first pen contact
/// reach the paper. Keep only ancestors of mounted ink surfaces hittable, using
/// the public ScrollContext contract; restore their ordinary policy when the
/// last surface leaves. No pointer is synthesized or sent around hit testing.
class _InkScrollHosts {
  static final _hosts = <ScrollPosition, _InkScrollHost>{};

  static void attach(ScrollPosition position) {
    final host = _hosts.putIfAbsent(position, () => _InkScrollHost(position));
    host.surfaces++;
  }

  static void detach(ScrollPosition position) {
    final host = _hosts[position]!;
    if (--host.surfaces == 0) {
      _hosts.remove(position);
      host.dispose();
    }
  }
}

class _InkScrollHost {
  _InkScrollHost(this.position) {
    position.isScrollingNotifier.addListener(_allowInkHitTesting);
    position.addListener(_allowInkHitTesting);
    _allowInkHitTesting();
  }

  final ScrollPosition position;
  int surfaces = 0;

  void _allowInkHitTesting() => position.context.setIgnorePointer(false);

  void dispose() {
    position.isScrollingNotifier.removeListener(_allowInkHitTesting);
    position.removeListener(_allowInkHitTesting);
    position.context.setIgnorePointer(position.shouldIgnorePointer);
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
