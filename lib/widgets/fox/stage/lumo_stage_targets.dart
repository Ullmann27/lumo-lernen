import 'package:flutter/widgets.dart';

/// Wie ein Aufgabenteil auf der Bühne zählt.
enum LumoStageRegionKind {
  /// Darf gezeigt werden und wird nie verdeckt (z. B. die Rechnung).
  target,

  /// Wird nie verdeckt (Bild, Arbeitsfläche).
  obstacle,

  /// Antworten: nie verdeckt; ein Tipp darauf bricht Lumos Weg freundlich ab.
  answers,
}

class _Region {
  _Region(this.key, this.kind);
  final GlobalKey key;
  final LumoStageRegionKind kind;
}

/// Kleine Registrierung der sichtbaren Aufgabenteile für Lumos Bühne.
class LumoStageTargets extends ChangeNotifier {
  final Map<String, _Region> _regions = <String, _Region>{};
  int _answerTouches = 0;

  /// Zählt jeden Fingerdruck auf eine Antwort (keine Koordinaten, kein Inhalt).
  int get answerTouches => _answerTouches;

  void _register(String id, GlobalKey key, LumoStageRegionKind kind) {
    _regions[id] = _Region(key, kind);
  }

  void _unregister(String id, GlobalKey key) {
    if (identical(_regions[id]?.key, key)) _regions.remove(id);
  }

  void _answerTouched() {
    _answerTouches++;
    notifyListeners();
  }

  bool has(String id) => _regions[id]?.key.currentContext != null;

  /// Rechteck eines Teils in den Koordinaten von [stage].
  /// Mit [visibleOnly] nur, solange der Teil die Bühne berührt.
  Rect? rectOf(String id, RenderBox stage, {bool visibleOnly = true}) =>
      _rectFor(_regions[id]?.key, stage, visibleOnly: visibleOnly);

  /// Alle Teile, die Lumo nie verdecken darf.
  List<Rect> protectedRects(RenderBox stage) => [
        for (final region in _regions.values)
          if (_rectFor(region.key, stage) case final Rect rect) rect,
      ];

  static Rect? _rectFor(GlobalKey? key, RenderBox stage,
      {bool visibleOnly = true}) {
    final object = key?.currentContext?.findRenderObject();
    if (object is! RenderBox ||
        !object.attached ||
        !object.hasSize ||
        !stage.attached) {
      return null;
    }
    final topLeft = object.localToGlobal(Offset.zero, ancestor: stage);
    final rect = topLeft & object.size;
    final bounds = Offset.zero & stage.size;
    return !visibleOnly || rect.overlaps(bounds) ? rect : null;
  }

  BuildContext? contextOf(String id) => _regions[id]?.key.currentContext;
}

/// Stellt die Registrierung den Aufgabenteilen darunter bereit.
class LumoStageScope extends InheritedWidget {
  const LumoStageScope(
      {super.key, required this.targets, required super.child});

  final LumoStageTargets targets;

  static LumoStageTargets? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LumoStageScope>()?.targets;

  @override
  bool updateShouldNotify(LumoStageScope oldWidget) =>
      !identical(targets, oldWidget.targets);
}

/// Meldet einen Aufgabenteil bei der Bühne an. Ohne Bühne wirkungslos.
class LumoStageTarget extends StatefulWidget {
  const LumoStageTarget({
    super.key,
    required this.id,
    required this.child,
    this.kind = LumoStageRegionKind.target,
  });

  final String id;
  final LumoStageRegionKind kind;
  final Widget child;

  @override
  State<LumoStageTarget> createState() => _LumoStageTargetState();
}

class _LumoStageTargetState extends State<LumoStageTarget> {
  final GlobalKey _key = GlobalKey();
  LumoStageTargets? _targets;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = LumoStageScope.maybeOf(context);
    if (!identical(next, _targets)) {
      _targets?._unregister(widget.id, _key);
      _targets = next;
    }
    _targets?._register(widget.id, _key, widget.kind);
  }

  @override
  void didUpdateWidget(covariant LumoStageTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.kind != widget.kind) {
      _targets?._unregister(oldWidget.id, _key);
      _targets?._register(widget.id, _key, widget.kind);
    }
  }

  @override
  void dispose() {
    _targets?._unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = KeyedSubtree(key: _key, child: widget.child);
    if (widget.kind == LumoStageRegionKind.answers && _targets != null) {
      final targets = _targets!;
      // Passiv: der Tipp erreicht die Antwort unverändert.
      child = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => targets._answerTouched(),
        child: child,
      );
    }
    return child;
  }
}
