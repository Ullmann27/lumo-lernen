import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/lumo_sound.dart';
import '../../../../theme/lumo_visual_tokens.dart';
import '../../../../widgets/design/lumo_answer_crystal.dart';
import '../../../../widgets/design/lumo_glass_optics.dart';
import '../../../../widgets/fox/living/lumo_living_character.dart';
import '../learning_scene_contract.dart';
import '../learning_scene_motion.dart';
import 'place_value_material.dart';

/// Lumos Zehner-Werkstatt: die Darstellung einer Stellenwert-Szene.
///
/// Zeigt genau, was der [LearningSceneDirector] anfordert, und meldet jede
/// Handlung als [LearningSceneEvent] zurück. Bewertet nichts selbst.
/// Lumo begleitet jede Handlung: Er schaut auf die gezählte Stange, zeigt
/// das Bündeln mit einem Lichtstrahl vor, macht nach Fehlern Mut und feiert
/// nur einen echten, selbstständigen Lernschritt.
class ZehnerWerkstattView extends StatefulWidget {
  const ZehnerWerkstattView({
    super.key,
    required this.director,
    this.reduceMotion = false,
    this.sounds = false,
  });

  final LearningSceneDirector director;
  final bool reduceMotion;

  /// Dezente Werkstatt-Töne (nur wenn die App Töne erlaubt).
  final bool sounds;

  @override
  State<ZehnerWerkstattView> createState() => _ZehnerWerkstattViewState();
}

/// Ein Würfel auf dem Weg: Bündeln, Öffnen oder Lumos Vorführung.
class _Flight {
  const _Flight(this.from, this.to, this.fromTone, this.toTone);
  final Rect from;
  final Rect to;
  final PlaceValueTone fromTone;
  final PlaceValueTone toTone;
}

class _ZehnerWerkstattViewState extends State<ZehnerWerkstattView>
    with TickerProviderStateMixin {
  final _lumo = LumoLivingController(state: LumoLivingState.greet);
  final _stageKey = GlobalKey();
  final _lumoKey = GlobalKey();
  final Map<String, GlobalKey> _objectKeys = {};
  late final AnimationController _transform = AnimationController(
      vsync: this, duration: LearningSceneMotion.objectTransform);
  late final AnimationController _demo = AnimationController(
      vsync: this, duration: LearningSceneMotion.demonstration);
  late final AnimationController _wobble =
      AnimationController(vsync: this, duration: LearningSceneMotion.feedback);
  late final AnimationController _celebrate = AnimationController(
      vsync: this, duration: LearningSceneMotion.completion);

  List<_Flight> _flights = const [];
  List<_Flight> _demoFlights = const [];
  Set<String> _hidden = const {};
  Set<String> _demoHidden = const {};
  final List<int> _countOrder = [];
  final List<int> _selectOrder = [];
  late LearningSceneRequest _previous;
  Timer? _greeting;
  bool _started = false;

  /// Kantenlänge eines Würfels in einer Stange, je nach Breite.
  double _cube = 12;

  LearningSceneRequest get _scene => widget.director.request;

  bool get _calm => widget.reduceMotion || LearningSceneMotion.reduced(context);

  /// Lose Würfel sind größer, damit jeder einzeln antippbar ist.
  double get _looseCube => _cube * 1.35;

  @override
  void initState() {
    super.initState();
    widget.director.addListener(_onScene);
    _previous = _scene;
    _transform.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _flights = const [];
          _hidden = const {};
        });
      }
    });
    _demo.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _demoFlights = const [];
          _demoHidden = const {};
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_calm) {
      _perform(_scene);
    } else {
      // Erst begrüßt Lumo das Kind, dann folgt er der Lern-Engine.
      _greeting = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) _perform(_scene);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ZehnerWerkstattView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.director != widget.director) {
      oldWidget.director.removeListener(_onScene);
      widget.director.addListener(_onScene);
      _greeting?.cancel();
      _interrupt();
      _countOrder.clear();
      _selectOrder.clear();
      _objectKeys.clear();
      _previous = _scene;
      _perform(_scene);
    }
  }

  @override
  void dispose() {
    _greeting?.cancel();
    widget.director.removeListener(_onScene);
    _transform.dispose();
    _demo.dispose();
    _wobble.dispose();
    _celebrate.dispose();
    _lumo.dispose();
    super.dispose();
  }

  // ── Szene → Darstellung ──────────────────────────────────────────────

  void _onScene() {
    final now = _scene;
    final before = _previous;
    _previous = now;
    _trackOrder(now);
    _greeting?.cancel();
    _perform(now);
    _react(before, now);
    if (mounted) setState(() {});
  }

  /// Lumo spielt die Absicht der Engine und schaut danach auf ihren Fokus.
  void _perform(LearningSceneRequest scene) {
    _lumo.perform(LearningSceneMotion.lumoFor(scene.lumo),
        lookAt: _lumo.lookAt);
    _afterLayout(() => _lumo.look(_gazeAt(scene.lumoFocus)));
  }

  /// Blickrichtung (-1..1) von Lumos Augen zum Fokus der Szene.
  Offset? _gazeAt(String? focus) {
    if (focus == null || focus == 'child') return null;
    final lumo = _boxOf(_lumoKey);
    final target = switch (focus) {
      'loose' => _unionOf('loose-'),
      'build' => _boxOf(_stageKey),
      _ => _rectOf(focus),
    };
    if (lumo == null || target == null) return null;
    final eye = lumo.topLeft + Offset(lumo.width * .5, lumo.height * .3);
    final toward = target.center - eye;
    final distance = toward.distance;
    if (distance < 1) return Offset.zero;
    return toward / distance * math.min(1, distance / (lumo.width * .8));
  }

  void _trackOrder(LearningSceneRequest now) {
    int index(LearningSceneObject o) => int.parse(o.id.split('-').last);
    final counted = {
      for (final o in now.objects)
        if (o.type == 'ten_rod' && o.marked) index(o)
    };
    _countOrder
      ..removeWhere((i) => !counted.contains(i))
      ..addAll(counted.where((i) => !_countOrder.contains(i)));
    final selected = {
      for (final o in now.objects)
        if (o.id.startsWith('loose-') && o.marked) index(o)
    };
    _selectOrder
      ..removeWhere((i) => !selected.contains(i))
      ..addAll(selected.where((i) => !_selectOrder.contains(i)));
  }

  void _react(LearningSceneRequest before, LearningSceneRequest now) {
    if (now.feedback != null && now.feedback != before.feedback && !_calm) {
      _wobble.forward(from: 0);
    }
    if (now.stage == LearningSceneStage.done &&
        before.stage != LearningSceneStage.done &&
        now.lumo == LumoPerformanceIntent.celebrate) {
      if (!_calm) _celebrate.forward(from: 0);
      _sound(SoundEffect.win);
    }
    if (now.fact('demonstrations') > before.fact('demonstrations')) {
      _startDemonstration();
    }
  }

  void _sound(SoundEffect effect) {
    if (widget.sounds) unawaited(LumoSound.instance.play(effect));
  }

  // ── Handlungen des Kindes ────────────────────────────────────────────

  void _send(LearningSceneInput input, {String? objectId, int? value}) {
    final before = _scene;
    // Positionen vor der Handlung merken, damit Würfel sichtbar wandern.
    final opening = input == LearningSceneInput.startBundling &&
        before.fact('bundleMode') == 0 &&
        before.fact('bundled') == 0;
    final openFrom = opening ? _rectOf('ten-${before.fact('tens') - 1}') : null;
    final bundleFrom = input == LearningSceneInput.bundleTen
        ? [
            for (final o in before.objects)
              if (o.id.startsWith('loose-') && o.marked) _rectOf(o.id)
          ].whereType<Rect>().toList()
        : const <Rect>[];
    // Während das Modell seine Objekte neu baut, werden die transportierten
    // Originalwürfel sofort unsichtbar. Das verhindert ein sichtbares
    // Doppelbild im ersten Frame vor dem post-frame Flight-Painter.
    if (input != LearningSceneInput.selectObject &&
        input != LearningSceneInput.replayDemonstration) {
      _interrupt();
    }
    if (!_calm && openFrom != null) {
      _hidden = {
        for (var i = 0; i < 10; i++) 'loose-${before.fact('ones') + i}',
      };
    } else if (!_calm && bundleFrom.length == 10) {
      _hidden = {'ten-${before.fact('tens') - 1}'};
    }
    final accepted = widget.director.handle(LearningSceneEvent(
      sceneId: before.sceneId,
      revision: before.revision,
      input: input,
      objectId: objectId,
      value: value,
    ));
    if (!accepted) {
      _hidden = const {};
      return;
    }
    switch (input) {
      case LearningSceneInput.bundleTen:
      case LearningSceneInput.replayDemonstration:
        _sound(SoundEffect.cardPlay);
      case LearningSceneInput.startBundling when opening:
        _sound(SoundEffect.cardPlay);
      case LearningSceneInput.submitConstruction:
      case LearningSceneInput.answerChoice:
        break;
      default:
        _sound(SoundEffect.click);
    }
    if (_calm) return;
    if (openFrom != null) _afterLayout(() => _startOpening(openFrom));
    if (bundleFrom.length == 10) {
      _afterLayout(() => _startBundling(bundleFrom));
    }
  }

  void _interrupt() {
    _transform.stop();
    _demo.stop();
    _flights = const [];
    _demoFlights = const [];
    _hidden = const {};
    _demoHidden = const {};
  }

  void _afterLayout(VoidCallback action) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });

  // ── Geometrie der Bühne ──────────────────────────────────────────────

  String _slotId(String id) => '${_scene.sceneId}/$id';

  GlobalKey _keyFor(String id) =>
      _objectKeys.putIfAbsent(_slotId(id), GlobalKey.new);

  /// Rechteck eines Widgets relativ zur Bühne.
  Rect? _boxOf(GlobalKey key) {
    final stage = _stageKey.currentContext?.findRenderObject();
    final box = key.currentContext?.findRenderObject();
    if (stage is! RenderBox || box is! RenderBox) return null;
    if (!stage.attached || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: stage) & box.size;
  }

  Rect? _rectOf(String id) {
    final key = _objectKeys[_slotId(id)];
    return key == null ? null : _boxOf(key);
  }

  Rect? _unionOf(String prefix) {
    Rect? union;
    for (final o in _scene.objects) {
      if (!o.id.startsWith(prefix)) continue;
      final rect = _rectOf(o.id);
      if (rect != null) union = union?.expandToInclude(rect) ?? rect;
    }
    return union;
  }

  /// Malfläche des Würfels in einem Einerwürfel-Widget.
  static Rect _cubeArea(Rect widgetRect, double cube) => widgetRect
      .deflate(math.max(0, (widgetRect.shortestSide - cube * 1.45) / 2));

  /// Platz [index] (0 = oben) in einer Zehnerstange.
  static Rect _rodSlot(Rect rodRect, int index) {
    final paintArea = Rect.fromLTRB(
        rodRect.left, rodRect.top + 22, rodRect.right, rodRect.bottom);
    return PlaceValueCubePainter.slot(paintArea.size, 10, index)
        .shift(paintArea.topLeft);
  }

  /// Eine Stange öffnet sich: Zehn Würfel springen zu den losen Würfeln.
  void _startOpening(Rect rod) {
    final ones = _scene.fact('ones');
    final flights = <_Flight>[];
    final hide = <String>{};
    for (var k = 0; k < 10; k++) {
      final id = 'loose-${ones + k}';
      final to = _rectOf(id);
      if (to == null) {
        setState(() => _hidden = const {});
        return;
      }
      hide.add(id);
      flights.add(_Flight(_rodSlot(rod, 9 - k), _cubeArea(to, _looseCube),
          PlaceValueTone.tens, PlaceValueTone.ones));
    }
    setState(() {
      _flights = flights;
      _hidden = hide;
    });
    _transform.forward(from: 0);
  }

  /// Zehn ausgewählte Würfel springen zusammen und werden eine Stange.
  void _startBundling(List<Rect> cubes) {
    final id = 'ten-${_scene.fact('tens') - 1}';
    final rod = _rectOf(id);
    if (rod == null) {
      setState(() => _hidden = const {});
      return;
    }
    setState(() {
      _flights = [
        for (var k = 0; k < cubes.length; k++)
          _Flight(_cubeArea(cubes[k], _looseCube), _rodSlot(rod, 9 - k),
              PlaceValueTone.ones, PlaceValueTone.tens)
      ];
      _hidden = {id};
    });
    _transform.forward(from: 0);
  }

  /// Lumo zeigt vor: Zehn lose Würfel formen eine Stange und lösen sich
  /// wieder. Nur eine Vorführung; das Kind bündelt danach selbst.
  void _startDemonstration() {
    if (_calm) return;
    _afterLayout(() {
      final cubes = <Rect>[];
      for (var k = 0; k < 10; k++) {
        final rect = _rectOf('loose-$k');
        if (rect == null) return;
        cubes.add(_cubeArea(rect, _looseCube));
      }
      final center =
          cubes.fold<Offset>(Offset.zero, (sum, r) => sum + r.center) / 10;
      final size = PlaceValueRod.sizeFor(_cube);
      final stage = _stageKey.currentContext?.findRenderObject();
      final stageWidth = stage is RenderBox ? stage.size.width : 0.0;
      final source = cubes.reduce((a, b) => a.expandToInclude(b));
      // Wird neben den Würfeln genug Platz frei, erscheint die Zielstange
      // dort. Auf schmalen Displays schwebt sie innerhalb der Bühne.
      final right = source.right + size.width + 12 <= stageWidth;
      final left = source.left >= size.width + 12;
      final x = right
          ? source.right + 12 + size.width / 2
          : left
              ? source.left - 12 - size.width / 2
              : center.dx;
      final safeX = stageWidth > size.width + 16
          ? x.clamp(size.width / 2 + 8, stageWidth - size.width / 2 - 8)
          : center.dx;
      final column = Rect.fromCenter(
          center: Offset(safeX.toDouble(),
              math.max(size.height / 2 + 8, center.dy - size.height * .35)),
          width: size.width,
          height: size.height);
      setState(() {
        _demoFlights = [
          for (var k = 0; k < 10; k++)
            _Flight(cubes[k], _rodSlot(column, 9 - k), PlaceValueTone.ones,
                PlaceValueTone.tens)
        ];
        _demoHidden = {for (var k = 0; k < 10; k++) 'loose-$k'};
      });
      _demo.forward(from: 0);
    });
  }

  Offset? _handInStage() {
    final lumo = _boxOf(_lumoKey);
    if (lumo == null) return null;
    return lumo.topLeft +
        LumoLivingCharacter.handOf(LumoLivingState.demonstrate, lumo.width);
  }

  // ── Aufbau ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final calm = _calm;
    final scene = _scene;
    final textScale = MediaQuery.textScalerOf(context).scale(15) / 15;
    Widget view = LayoutBuilder(builder: (context, constraints) {
      final width =
          constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
      // Nur ab 800dp kann die Werkbank sinnvoll neben der Figur stehen.
      // Auf dem offenen Fold um 690dp gehört die ganze Werkbank unter Lumo.
      final wide = width >= 800;
      final foldInside = width >= 600 && !wide;
      final narrow = width < 340;
      final lumoSize = wide
          ? 164.0
          : foldInside
              ? 132.0
              : narrow
                  ? 96.0
                  : 108.0;
      _cube = narrow ? 10 : (width >= 600 ? 14 : 12);
      final padding = narrow ? 12.0 : 16.0;
      final besideBubble = width - 2 * padding - lumoSize - 8;
      final stacked = wide || foldInside || besideBubble / textScale < 150;
      final lumo = _lumoAndBubble(scene, lumoSize, stacked: stacked);
      final stage = _stage(scene, calm);
      return Container(
        key: const ValueKey('lumo-place-value-workshop'),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF20C3E78), Color(0xF2061B40)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xB04EDCFF), width: 1.4),
          boxShadow: const [
            BoxShadow(
                color: Color(0x3300D7FF), blurRadius: 26, offset: Offset(0, 8)),
            BoxShadow(
                color: Color(0x66000814),
                blurRadius: 18,
                offset: Offset(0, 10)),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: const LumoGlassOptics(radius: 28),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: DefaultTextStyle(
              style: const TextStyle(
                  color: LumoVisualTokens.white,
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(scene, calm),
                  const SizedBox(height: 12),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: math.min(320, width * .36), child: lumo),
                        const SizedBox(width: 16),
                        Expanded(child: stage),
                      ],
                    )
                  else ...[
                    lumo,
                    const SizedBox(height: 12),
                    stage,
                  ],
                  const SizedBox(height: 14),
                  _controls(scene, textScale),
                ],
              ),
            ),
          ),
        ),
      );
    });
    // Erklärungsbeginn: Die Werkstatt schwebt einmal sanft herein.
    view = TweenAnimationBuilder<double>(
      tween: Tween(begin: calm ? 1 : 0, end: 1),
      duration: calm ? Duration.zero : LearningSceneMotion.explanationStart,
      curve: LearningSceneMotion.settle,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: view,
    );
    if (widget.reduceMotion && !MediaQuery.disableAnimationsOf(context)) {
      // Alle Bausteine der Szene folgen der Einstellung der Werkstatt.
      view = MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: view);
    }
    return view;
  }

  Widget _header(LearningSceneRequest scene, bool calm) {
    final step = switch (scene.stage) {
      LearningSceneStage.explore => 0,
      LearningSceneStage.construct => 1,
      LearningSceneStage.explain => 2,
      LearningSceneStage.done => 3,
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        const Text('Lumos Zehner-Werkstatt',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        Semantics(
          label: step < 3
              ? 'Schritt ${step + 1} von 3'
              : 'Alle Schritte geschafft',
          excludeSemantics: true,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration:
                    calm ? Duration.zero : LearningSceneMotion.methodChange,
                curve: LearningSceneMotion.settle,
                margin: const EdgeInsets.only(right: 4),
                width: i == step ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: i < step
                      ? LumoVisualTokens.gold
                      : i == step
                          ? LumoVisualTokens.cyanBright
                          : const Color(0x5553DDFD),
                ),
              ),
          ]),
        ),
        Text(
          switch (scene.stage) {
            LearningSceneStage.explore => '1 · Gemeinsam entdecken',
            LearningSceneStage.construct => '2 · Selbst bauen',
            LearningSceneStage.explain => '3 · Erklär es Lumo',
            LearningSceneStage.done => 'Dein Lernschritt',
          },
          style: const TextStyle(color: Color(0xFF8DEBFF)),
        ),
      ],
    );
  }

  /// Lumo mit Sprechblase: Arbeitsauftrag und Rückmeldung der Engine.
  Widget _lumoAndBubble(LearningSceneRequest scene, double size,
      {required bool stacked}) {
    final character = SizedBox.square(
      key: _lumoKey,
      dimension: size,
      child: LumoLivingCharacter(
          controller: _lumo, size: size, reduceMotion: _calm),
    );
    final bubble = _SpeechBubble(
      instruction: scene.instruction,
      feedback: scene.feedback,
      tailTop: stacked,
      calm: _calm,
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(left: 4), child: character),
          const SizedBox(height: 6),
          bubble,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [character, const SizedBox(width: 8), Expanded(child: bubble)],
    );
  }

  Widget _stage(LearningSceneRequest scene, bool calm) {
    final content = switch (scene.stage) {
      LearningSceneStage.explore => scene.fact('bundleMode') == 1
          ? _bundleStage(scene, calm)
          : _countStage(scene, calm),
      LearningSceneStage.construct => _buildStage(scene, calm),
      LearningSceneStage.explain => _explainStage(scene),
      LearningSceneStage.done => _doneStage(scene, calm),
    };
    return Stack(
      key: _stageKey,
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _HoloFloorPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: AnimatedSwitcher(
            duration: calm ? Duration.zero : LearningSceneMotion.methodChange,
            switchInCurve: LearningSceneMotion.settle,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: KeyedSubtree(
              key: ValueKey('${scene.sceneId}-${scene.stage.name}'),
              child: content,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_transform, _demo, _celebrate]),
              builder: (context, _) => CustomPaint(
                painter: _FlightPainter(
                  flights: _flights,
                  progress: _transform.value,
                  demo: _demoFlights,
                  demoProgress: _demo.value,
                  beamFrom: _demoFlights.isEmpty ? null : _handInStage(),
                  celebrate: _celebrate.value,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rods(LearningSceneRequest scene, {required bool countable}) {
    final rods = scene.objects.where((o) => o.type == 'ten_rod').toList();
    final canCount = countable && scene.allows(LearningSceneInput.countObject);
    return LayoutBuilder(builder: (context, constraints) {
      // Acht Zehner werden auf Handybreite in zwei vollständigen Reihen
      // zu je vier angeordnet (statt 5+3). Breite Tablets behalten die
      // größere Werkbank und zeigen die Einer nach Möglichkeit daneben.
      final maxWidth = constraints.maxWidth;
      const gap = 6.0;
      final rodWidth = PlaceValueRod.sizeFor(_cube).width;
      final maxColumns = maxWidth < 560 ? 4 : rods.length;
      final columns = math.min(rods.length, maxColumns);
      final desired = columns == 0 ? 0.0 : columns * rodWidth + (columns - 1) * gap;
      return SizedBox(
        width: math.min(maxWidth, desired),
        child: Wrap(
          spacing: gap,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (var i = 0; i < rods.length; i++)
              KeyedSubtree(
                key: _keyFor(rods[i].id),
                child: PlaceValueRod(
                  cube: _cube,
                  label:
                      'Zehnerstange ${i + 1}${rods[i].marked ? ', gezählt' : ''}',
                  buttonKey: ValueKey('lumo-tens-block-$i'),
                  counted: rods[i].marked,
                  badge: rods[i].marked
                      ? '${10 * (_countOrder.indexOf(i) + 1)}'
                      : null,
                  focus: !countable && scene.lumoFocus == rods[i].id,
                  hidden: _hidden.contains(rods[i].id),
                  onTap: canCount
                      ? () => _send(LearningSceneInput.countObject,
                          objectId: rods[i].id)
                      : null,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _cubes(List<LearningSceneObject> cubes,
      {required String keyPrefix, required bool tappable}) {
    if (cubes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Text('Keine einzelnen Würfel übrig',
            style: TextStyle(color: Color(0xFFFFE5B4))),
      );
    }
    final cube = tappable ? _looseCube : _cube * 1.2;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: tappable ? 6 * 48 + 5 * 2 : 120),
      child: Wrap(
        spacing: tappable ? 2 : 0,
        runSpacing: tappable ? 2 : 0,
        children: [
          for (var i = 0; i < cubes.length; i++)
            KeyedSubtree(
              key: _keyFor(cubes[i].id),
              child: PlaceValueCube(
                cube: cube,
                label:
                    'Einzelwürfel ${i + 1}${cubes[i].marked ? ', ausgewählt' : ''}',
                buttonKey: ValueKey('$keyPrefix-$i'),
                selected: cubes[i].marked,
                badge:
                    cubes[i].marked ? '${_selectOrder.indexOf(i) + 1}' : null,
                hidden: _hidden.contains(cubes[i].id) ||
                    _demoHidden.contains(cubes[i].id),
                onTap: tappable
                    ? () => _send(LearningSceneInput.selectObject,
                        objectId: cubes[i].id)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _countStage(LearningSceneRequest scene, bool calm) {
    final tens = scene.fact('tens');
    final ones = scene.fact('ones');
    final counted = scene.fact('counted');
    final complete = counted == tens;
    final cubes = scene.objects.where((o) => o.type == 'unit_cube').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _rods(scene, countable: true),
            _cubes(cubes, keyPrefix: 'lumo-one-block', tappable: false),
          ],
        ),
        const SizedBox(height: 12),
        _CountingRail(tens: tens, counted: counted, ones: ones),
        const SizedBox(height: 8),
        Text(
          complete
              ? 'Geschafft! Du hast $counted volle Zehner und $ones Einer gezählt.'
              : 'Du hast $counted volle Zehner gezählt. Zähle weiter – in jeder Stange stecken zehn.',
          key: const ValueKey('lumo-place-value-feedback'),
        ),
        if (complete) ...[
          const SizedBox(height: 10),
          _Decomposition(
              number: scene.fact('number'), tens: tens, ones: ones, calm: calm),
        ],
      ],
    );
  }

  Widget _bundleStage(LearningSceneRequest scene, bool calm) {
    final cubes = scene.objects.where((o) => o.type == 'unit_cube').toList();
    final bundled = scene.fact('bundled') == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _rods(scene, countable: false),
            _cubes(cubes,
                keyPrefix: 'lumo-loose-cube',
                tappable: scene.allows(LearningSceneInput.selectObject)),
          ],
        ),
        const SizedBox(height: 10),
        if (bundled)
          _Decomposition(
              number: scene.fact('number'),
              tens: scene.fact('tens'),
              ones: scene.fact('ones'),
              calm: calm)
        else ...[
          _SelectionMeter(selected: scene.fact('selected')),
          // Ersatz für die Vorführung, wenn Animationen reduziert sind.
          if (calm && scene.fact('demonstrations') > 0) ...[
            const SizedBox(height: 10),
            _StillDemonstration(cube: _cube),
          ],
        ],
      ],
    );
  }

  Widget _buildStage(LearningSceneRequest scene, bool calm) {
    final tens = scene.fact('builtTens');
    final ones = scene.fact('builtOnes');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NumberPlate(label: 'Ziel', number: scene.fact('target')),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _wobble,
          builder: (context, child) {
            final t = _wobble.value;
            final dx = t == 0 || t == 1
                ? 0.0
                : math.sin(t * math.pi * 4) * 4 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Wrap(
            spacing: 6,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (var i = 0; i < tens; i++)
                _PopIn(
                  key: ValueKey('built-ten-$i'),
                  calm: calm,
                  child: PlaceValueRod(
                      cube: _cube, label: 'Gebaute Zehnerstange ${i + 1}'),
                ),
              for (var i = 0; i < ones; i++)
                _PopIn(
                  key: ValueKey('built-one-$i'),
                  calm: calm,
                  child: PlaceValueCube(
                      cube: _cube * 1.2, label: 'Gebauter Einer ${i + 1}'),
                ),
              if (ones == 0 && tens == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Noch leer – baue mit + Zehner und + Einer.',
                      style: TextStyle(color: Color(0xFFB8D8F0))),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// „Erklär es Lumo“: Lumo hört zu, die gebaute Zahl steht im Licht.
  Widget _explainStage(LearningSceneRequest scene) => Center(
      child: _NumberPlate(label: 'Deine Zahl', number: scene.fact('target')));

  Widget _doneStage(LearningSceneRequest scene, bool calm) {
    final target = scene.fact('target');
    return _Decomposition(
        number: target, tens: target ~/ 10, ones: target % 10, calm: calm);
  }

  Widget _controls(LearningSceneRequest scene, double textScale) {
    final children = <Widget>[];
    VoidCallback? act(LearningSceneInput input) =>
        scene.allows(input) ? () => _send(input) : null;
    switch (scene.stage) {
      case LearningSceneStage.explore:
        final bundleMode = scene.fact('bundleMode') == 1;
        children.add(Wrap(spacing: 8, runSpacing: 8, children: [
          _HoloButton(
              buttonKey: const ValueKey('lumo-place-value-count-mode'),
              label: 'Stangen zählen',
              icon: Icons.touch_app_rounded,
              selected: !bundleMode,
              onPressed: act(LearningSceneInput.startCounting)),
          _HoloButton(
              buttonKey: const ValueKey('lumo-place-value-bundle-mode'),
              label: 'Selbst bündeln',
              icon: Icons.view_module_rounded,
              selected: bundleMode,
              onPressed: act(LearningSceneInput.startBundling)),
        ]));
        final row = <Widget>[
          if (scene.allows(LearningSceneInput.resetCount))
            _HoloButton(
                buttonKey: const ValueKey('lumo-place-value-reset'),
                label: 'Noch einmal zählen',
                icon: Icons.replay_rounded,
                onPressed: act(LearningSceneInput.resetCount)),
          if (bundleMode && scene.fact('bundled') == 0) ...[
            _HoloButton(
                buttonKey: const ValueKey('lumo-place-value-demo'),
                label: 'Lumo zeigt es mir',
                icon: Icons.auto_awesome_rounded,
                onPressed: act(LearningSceneInput.replayDemonstration)),
            Text('${scene.fact('selected')} Würfel ausgewählt'),
            _HoloButton(
                buttonKey: const ValueKey('lumo-bundle-ten'),
                label: 'Zehner bündeln',
                icon: Icons.link_rounded,
                accent: LumoVisualTokens.gold,
                onPressed: act(LearningSceneInput.bundleTen)),
          ],
        ];
        if (row.isNotEmpty) {
          children.add(Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: row));
        }
        if (scene.allows(LearningSceneInput.startConstruction)) {
          children
              .add(const Text('Jetzt eine andere Zahl – ohne Lumos Hilfe.'));
          children.add(_GoldButton(
              buttonKey: const ValueKey('lumo-place-value-build-next'),
              label: 'Neue Zahl bauen',
              icon: Icons.construction_rounded,
              onPressed: act(LearningSceneInput.startConstruction)));
        }
      case LearningSceneStage.construct:
        children.add(Wrap(spacing: 8, runSpacing: 8, children: [
          _HoloButton(
              buttonKey: const ValueKey('lumo-build-add-ten'),
              label: '+ Zehner',
              onPressed: act(LearningSceneInput.addTen)),
          _HoloButton(
              buttonKey: const ValueKey('lumo-build-remove-ten'),
              label: '− Zehner',
              onPressed: act(LearningSceneInput.removeTen)),
          _HoloButton(
              buttonKey: const ValueKey('lumo-build-add-one'),
              label: '+ Einer',
              accent: LumoVisualTokens.gold,
              onPressed: act(LearningSceneInput.addOne)),
          _HoloButton(
              buttonKey: const ValueKey('lumo-build-remove-one'),
              label: '− Einer',
              accent: LumoVisualTokens.gold,
              onPressed: act(LearningSceneInput.removeOne)),
        ]));
        children.add(_GoldButton(
            buttonKey: const ValueKey('lumo-build-check'),
            label: 'Meine Zahl prüfen',
            icon: Icons.check_rounded,
            onPressed: act(LearningSceneInput.submitConstruction)));
      case LearningSceneStage.explain:
        final side = 58.0 * textScale.clamp(1.0, 1.8);
        children.add(Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final choice in scene.choices)
              SizedBox(
                width: side,
                height: side * 1.12,
                child: LumoAnswerCrystal(
                  label: '$choice',
                  buttonKey: ValueKey('lumo-comprehension-$choice'),
                  fontSize: 24,
                  semanticLabel: '$choice Einer',
                  onPressed: () =>
                      _send(LearningSceneInput.answerChoice, value: choice),
                ),
              ),
          ],
        ));
      case LearningSceneStage.done:
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          children[i],
        ],
      ],
    );
  }
}

// ── Bausteine ─────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.instruction,
    required this.feedback,
    required this.tailTop,
    required this.calm,
  });
  final String instruction;
  final String? feedback;
  final bool tailTop;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    final bubble = _bubble();
    // AnimatedSize verträgt keine Dauer null; ruhig heißt hier: sofort.
    if (calm) return bubble;
    return AnimatedSize(
      duration: LearningSceneMotion.interaction,
      curve: LearningSceneMotion.settle,
      alignment: Alignment.topLeft,
      child: bubble,
    );
  }

  Widget _bubble() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xE0103A70), Color(0xE0082650)]),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(tailTop ? 6 : 20),
            topRight: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
            bottomLeft: Radius.circular(tailTop ? 20 : 6),
          ),
          border: Border.all(color: const Color(0x8853DDFD)),
          boxShadow: const [
            BoxShadow(color: Color(0x2253DDFD), blurRadius: 14),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(instruction),
            if (feedback != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2, right: 6),
                        child: Icon(Icons.lightbulb_rounded,
                            size: 18, color: LumoVisualTokens.goldLight),
                      ),
                      Expanded(
                        child: Text(feedback!,
                            style: const TextStyle(
                                color: LumoVisualTokens.goldLight)),
                      ),
                    ]),
              ),
            ],
          ],
        ),
      );
}

/// Zählband: zehn, zwanzig, dreißig … und die Einer.
class _CountingRail extends StatelessWidget {
  const _CountingRail(
      {required this.tens, required this.counted, required this.ones});
  final int tens;
  final int counted;
  final int ones;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Gezählt: ${counted * 10}',
        excludeSemantics: true,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < tens; i++)
              _RailChip(text: '${(i + 1) * 10}', lit: i < counted),
            if (ones > 0)
              _RailChip(text: '+ $ones', lit: counted == tens, warm: true),
          ],
        ),
      );
}

class _RailChip extends StatelessWidget {
  const _RailChip({required this.text, required this.lit, this.warm = false});
  final String text;
  final bool lit;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final accent = warm ? LumoVisualTokens.gold : LumoVisualTokens.cyanBright;
    return AnimatedContainer(
      duration:
          LearningSceneMotion.of(context, LearningSceneMotion.interaction),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: lit ? accent.withValues(alpha: .22) : const Color(0x22000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: lit ? accent : const Color(0x4453DDFD), width: 1.2),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: lit ? LumoVisualTokens.white : const Color(0xFF8FB3D3))),
    );
  }
}

/// Zahlzerlegung: Stellenwerttafel und 84 = 80 + 4.
class _Decomposition extends StatelessWidget {
  const _Decomposition(
      {required this.number,
      required this.tens,
      required this.ones,
      required this.calm});
  final int number;
  final int tens;
  final int ones;
  final bool calm;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: calm ? 1 : 0, end: 1),
        duration: calm ? Duration.zero : LearningSceneMotion.explanationStart,
        curve: LearningSceneMotion.settle,
        builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 12 * (1 - t)), child: child)),
        child: Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _PlaceValueChart(tens: tens, ones: ones),
            Text('$number = ${tens * 10} + $ones',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.goldLight)),
          ],
        ),
      );
}

/// Stellenwerttafel Z | E.
class _PlaceValueChart extends StatelessWidget {
  const _PlaceValueChart({required this.tens, required this.ones});
  final int tens;
  final int ones;

  @override
  Widget build(BuildContext context) {
    Widget cell(String head, int value, Color accent) => Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            border: Border.all(color: accent.withValues(alpha: .7), width: 1.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(head,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900, color: accent)),
            Text('$value',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white)),
          ]),
        );
    return Semantics(
      label: '$tens Zehner und $ones Einer',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        cell('Z', tens, LumoVisualTokens.cyanBright),
        const SizedBox(width: 6),
        cell('E', ones, LumoVisualTokens.gold),
      ]),
    );
  }
}

/// Leuchtendes Zahlenschild für die Zahl, um die es gerade geht.
class _NumberPlate extends StatelessWidget {
  const _NumberPlate({required this.label, required this.number});
  final String label;
  final int number;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 16, 6),
        decoration: BoxDecoration(
          color: const Color(0x2253DDFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xAA53DDFD), width: 1.3),
          boxShadow: const [
            BoxShadow(color: Color(0x3353DDFD), blurRadius: 12)
          ],
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF8DEBFF))),
            Text('$number',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white)),
          ],
        ),
      );
}

class _SelectionMeter extends StatelessWidget {
  const _SelectionMeter({required this.selected});
  final int selected;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$selected von 10 Würfeln ausgewählt',
        excludeSemantics: true,
        child: Row(children: [
          for (var i = 0; i < 10; i++)
            Expanded(
              child: AnimatedContainer(
                duration: LearningSceneMotion.of(
                    context, LearningSceneMotion.interaction),
                height: 8,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: i < selected
                      ? (selected == 10
                          ? LumoVisualTokens.gold
                          : LumoVisualTokens.cyanBright)
                      : const Color(0x3353DDFD),
                ),
              ),
            ),
        ]),
      );
}

/// Ruhige Vorführung: Zehn Einer ergeben eine Zehnerstange.
class _StillDemonstration extends StatelessWidget {
  const _StillDemonstration({required this.cube});
  final double cube;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x1A53DDFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x6653DDFD)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: cube * 1.6 * 5,
              child: Wrap(children: [
                for (var i = 0; i < 10; i++)
                  PlaceValueCube(cube: cube, label: 'Einer ${i + 1}'),
              ]),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: LumoVisualTokens.cyanBright),
            PlaceValueRod(cube: cube * .8, label: 'eine Zehnerstange'),
            const Text('Lumo zeigt: 10 Einer = 1 Zehner'),
          ],
        ),
      );
}

/// Hologlas-Schaltfläche, mindestens 48 × 48 dp.
class _HoloButton extends StatelessWidget {
  const _HoloButton({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
    this.accent = LumoVisualTokens.cyanBright,
  });
  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: LumoVisualTokens.white,
      disabledForegroundColor: const Color(0xFF8AA3C2),
      backgroundColor:
          selected ? accent.withValues(alpha: .22) : const Color(0x1A53DDFD),
      side: BorderSide(
          color: onPressed == null
              ? const Color(0x4453DDFD)
              : accent.withValues(alpha: selected ? 1 : .7),
          width: selected ? 1.8 : 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      textStyle:
          const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
    );
    final iconData = icon;
    return iconData == null
        ? OutlinedButton(
            key: buttonKey,
            onPressed: onPressed,
            style: style,
            child: Text(label))
        : OutlinedButton.icon(
            key: buttonKey,
            onPressed: onPressed,
            style: style,
            icon: Icon(iconData, size: 20),
            label: Text(label));
  }
}

/// Goldene Hauptaktion eines Schritts.
class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final Key buttonKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          key: buttonKey,
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            backgroundColor: LumoVisualTokens.gold,
            foregroundColor: const Color(0xFF2B1A00),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w900),
          ),
          icon: Icon(icon),
          label: Text(label),
        ),
      );
}

/// Neu gebautes Objekt wächst mit kleinem Federn auf.
class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child, required this.calm});
  final Widget child;
  final bool calm;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: calm ? 1 : .2, end: 1),
        duration: calm ? Duration.zero : LearningSceneMotion.feedback,
        curve: LearningSceneMotion.pop,
        builder: (context, s, child) => Transform.scale(
            scale: s, alignment: Alignment.bottomCenter, child: child),
        child: child,
      );
}

/// Holografischer Werktisch mit Tiefenraster und Lichtkegel.
class _HoloFloorPainter extends CustomPainter {
  const _HoloFloorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    canvas.drawRRect(
        rrect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x330A4C8F), Color(0x5507315E)],
          ).createShader(rect));
    canvas.save();
    canvas.clipRRect(rrect);
    final light = Offset(size.width * .55, size.height * .2);
    final reach = size.longestSide * .6;
    canvas.drawCircle(
        light,
        reach,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x2453DDFD), Color(0x0053DDFD)])
              .createShader(Rect.fromCircle(center: light, radius: reach)));
    final grid = Paint()
      ..color = const Color(0x1C53DDFD)
      ..strokeWidth = 1;
    final horizon = size.height * .2;
    for (var i = 1; i <= 7; i++) {
      final t = i / 7;
      final y = horizon + (size.height - horizon) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final vanishing = Offset(size.width * .5, horizon - size.height * .5);
    for (var i = -7; i <= 7; i++) {
      final bottom =
          Offset(size.width * .5 + i * size.width * .11, size.height);
      final direction = bottom - vanishing;
      final start =
          vanishing + direction * ((horizon - vanishing.dy) / direction.dy);
      canvas.drawLine(start, bottom, grid);
    }
    canvas.restore();
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x4453DDFD));
  }

  @override
  bool shouldRepaint(covariant _HoloFloorPainter oldDelegate) => false;
}

/// Wandernde Würfel, Lumos Lichtstrahl und der Glanz am Ende.
class _FlightPainter extends CustomPainter {
  _FlightPainter({
    required this.flights,
    required this.progress,
    required this.demo,
    required this.demoProgress,
    required this.beamFrom,
    required this.celebrate,
  });

  final List<_Flight> flights;
  final double progress;
  final List<_Flight> demo;
  final double demoProgress;
  final Offset? beamFrom;
  final double celebrate;

  @override
  void paint(Canvas canvas, Size size) {
    if (flights.isNotEmpty) _paintFlights(canvas, flights, progress);
    if (demo.isNotEmpty) _paintDemonstration(canvas);
    if (celebrate > 0 && celebrate < 1) _paintCelebration(canvas, size);
  }

  /// Hin (0–45 %), als Stange leuchten (45–70 %), zurück (70–100 %).
  void _paintDemonstration(Canvas canvas) {
    final t = demoProgress;
    final beam = beamFrom;
    final column = demo.map((f) => f.to).reduce((a, b) => a.expandToInclude(b));
    if (beam != null && t < .92) {
      final strength = math.sin(t / .92 * math.pi);
      final target = column.center;
      canvas.drawLine(
          beam,
          target,
          Paint()
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..color =
                LumoVisualTokens.cyanBright.withValues(alpha: .2 * strength)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawLine(
          beam,
          target,
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = LumoVisualTokens.white.withValues(alpha: .65 * strength));
      canvas.drawCircle(
          beam,
          6 * strength,
          Paint()
            ..color = LumoVisualTokens.white.withValues(alpha: .8 * strength)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    final back = ((t - .7) / .3).clamp(0.0, 1.0);
    if (back > 0) {
      _paintFlights(canvas, demo, back, reverse: true, opacity: .9);
      return;
    }
    _paintFlights(canvas, demo, (t / .45).clamp(0.0, 1.0), opacity: .9);
    if (t > .45) {
      final glow = math.sin(((t - .45) / .25).clamp(0.0, 1.0) * math.pi);
      canvas.drawRRect(
          RRect.fromRectAndRadius(column.inflate(5), const Radius.circular(10)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = LumoVisualTokens.gold.withValues(alpha: .9 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
  }

  void _paintCelebration(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .45);
    final spread = Curves.easeOutCubic.transform(celebrate);
    for (var i = 0; i < 16; i++) {
      final angle = i / 16 * 2 * math.pi;
      final radius =
          size.shortestSide * (.12 + .5 * spread) * (i.isEven ? 1 : .8);
      canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * radius,
          3.5 * (1 - celebrate) + 1,
          Paint()
            ..color =
                (i.isEven ? LumoVisualTokens.gold : LumoVisualTokens.cyanBright)
                    .withValues(alpha: 1 - celebrate));
    }
  }

  void _paintFlights(Canvas canvas, List<_Flight> list, double progress,
      {bool reverse = false, double opacity = 1}) {
    const lag = .045;
    final n = list.length;
    final span = 1 - lag * (n - 1);
    for (var k = 0; k < n; k++) {
      final f = list[k];
      final local = ((progress - k * lag) / span).clamp(0.0, 1.0);
      final e = LearningSceneMotion.transform.transform(local);
      final from = reverse ? f.to : f.from;
      final to = reverse ? f.from : f.to;
      final rect = Rect.lerp(from, to, e)!;
      final hop = -math.sin(e * math.pi) * rect.height * 1.1;
      final tone = PlaceValueTone.lerp(reverse ? f.toTone : f.fromTone,
          reverse ? f.fromTone : f.toTone, Curves.easeIn.transform(e));
      canvas.save();
      canvas.translate(rect.left, rect.top + hop);
      PlaceValueCubePainter(
              count: 1,
              tone: tone,
              glow: math.sin(e * math.pi),
              opacity: opacity,
              shadow: false)
          .paint(canvas, rect.size);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FlightPainter old) =>
      old.progress != progress ||
      old.demoProgress != demoProgress ||
      old.flights != flights ||
      old.demo != demo ||
      old.celebrate != celebrate ||
      old.beamFrom != beamFrom;
}
