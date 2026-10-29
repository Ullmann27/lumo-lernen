import 'package:flutter/material.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../scenes/learning_scene_contract.dart';
import '../scenes/place_value/place_value_scene_director.dart';
import 'lumo_place_value_blocks.dart';

export '../scenes/place_value/place_value_scene_director.dart'
    show LumoPlaceValueTransfer;

/// Voluntary offline workshop. Exploring the worked example is never a score.
/// A different number must be built AND explained before emitting evidence.
/// The rules live in [PlaceValueSceneDirector]; this widget only renders its
/// requests and reports the child's actions back as scene events.
class LumoPlaceValueWorkshop extends StatefulWidget {
  const LumoPlaceValueWorkshop(
      {super.key,
      required this.number,
      this.reduceMotion = false,
      this.onTransferChecked})
      : assert(number >= 10 && number <= 99);
  final int number;
  final bool reduceMotion;
  final ValueChanged<LumoPlaceValueTransfer>? onTransferChecked;

  static int? numberForPrompt(String prompt) {
    final normalized = prompt.toLowerCase();
    if (!normalized.contains('zehner') && !normalized.contains('einer')) {
      return null;
    }
    final matches = RegExp(r'\b\d{2}\b').allMatches(normalized).toList();
    if (matches.length != 1) return null;
    return int.tryParse(matches.single.group(0)!);
  }

  @override
  State<LumoPlaceValueWorkshop> createState() => _LumoPlaceValueWorkshopState();
}

class _LumoPlaceValueWorkshopState extends State<LumoPlaceValueWorkshop> {
  final _fox = LumoCharacterController();
  late PlaceValueSceneDirector _director = _newDirector();

  PlaceValueSceneDirector _newDirector() => PlaceValueSceneDirector(
      number: widget.number,
      onTransferChecked: (result) => widget.onTransferChecked?.call(result))
    ..addListener(_onScene);

  void _onScene() {
    switch (_director.request.lumo) {
      case LumoPerformanceIntent.think:
      case LumoPerformanceIntent.encourage
          when _director.request.stage != LearningSceneStage.done:
        _fox.think();
      case LumoPerformanceIntent.approve
          when _director.request.fact('bundled') == 1:
        _fox.talk();
      case LumoPerformanceIntent.celebrate:
        _fox.cheer();
      case LumoPerformanceIntent.encourage:
        _fox.comfort();
      default:
        break;
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant LumoPlaceValueWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _director.dispose();
      _director = _newDirector();
    }
  }

  @override
  void dispose() {
    _director.dispose();
    _fox.dispose();
    super.dispose();
  }

  void _send(LearningSceneInput input, {String? objectId, int? value}) {
    final request = _director.request;
    _director.handle(LearningSceneEvent(
        sceneId: request.sceneId,
        revision: request.revision,
        input: input,
        objectId: objectId,
        value: value));
  }

  VoidCallback? _action(LearningSceneInput input) =>
      _director.request.allows(input) ? () => _send(input) : null;

  @override
  Widget build(BuildContext context) {
    final calm = widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final scene = _director.request;
    final tens = scene.fact('tens');
    final ones = scene.fact('ones');
    final counted = scene.fact('counted');
    final complete = counted == tens;
    final bundleMode = scene.fact('bundleMode') == 1;
    final bundled = scene.fact('bundled') == 1;
    final rods = scene.objects.where((o) => o.type == 'ten_rod').toList();
    final cubes = scene.objects.where((o) => o.type == 'unit_cube').toList();
    Set<int> marked(List<LearningSceneObject> objects) => {
          for (var i = 0; i < objects.length; i++)
            if (objects[i].marked) i
        };
    return Container(
        key: const ValueKey('lumo-place-value-workshop'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xF00A3768), Color(0xF0071B3E)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xB04EDCFF), width: 1.4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x2500D7FF),
                  blurRadius: 18,
                  offset: Offset(0, 6))
            ]),
        child: DefaultTextStyle(
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.35),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                    child: Text('Lumos Zehner-Werkstatt',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900))),
                ExcludeSemantics(
                    child: LumoCharacter(
                        pose: scene.stage == LearningSceneStage.done &&
                                scene.fact('independent') == 1
                            ? LumoDesignFoxPose.cheer
                            : LumoDesignFoxPose.bookPoint,
                        size: 65,
                        reduceMotion: calm,
                        idleHops: false,
                        intro: false,
                        controller: _fox)),
              ]),
              const SizedBox(height: 8),
              Text(
                  switch (scene.stage) {
                    LearningSceneStage.explore => '1 · Gemeinsam entdecken',
                    LearningSceneStage.construct => '2 · Selbst bauen',
                    LearningSceneStage.explain => '3 · Erklär es Lumo',
                    LearningSceneStage.done => 'Dein Lernschritt'
                  },
                  style: const TextStyle(color: Color(0xFF8DEBFF))),
              const SizedBox(height: 12),
              if (scene.stage == LearningSceneStage.explore) ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _button('lumo-place-value-count-mode', 'Stangen zählen',
                      _action(LearningSceneInput.startCounting)),
                  _button('lumo-place-value-bundle-mode', 'Selbst bündeln',
                      _action(LearningSceneInput.startBundling)),
                ]),
                const SizedBox(height: 12),
                if (!bundleMode) ...[
                  Text(scene.instruction),
                  const SizedBox(height: 14),
                  LumoPlaceValueBlocks(
                      tens: rods.length,
                      ones: cubes.length,
                      selectedTens: marked(rods),
                      reduceMotion: calm,
                      onTenTap: (i) => _send(LearningSceneInput.countObject,
                          objectId: rods[i].id)),
                  const SizedBox(height: 14),
                  Text(
                      complete
                          ? 'Geschafft! Du hast $counted volle Zehner und $ones Einer gezählt.'
                          : 'Du hast $counted volle Zehner gezählt. Zähle weiter – in jeder Stange stecken zehn.',
                      key: const ValueKey('lumo-place-value-feedback')),
                  if (complete)
                    Text('${scene.fact('number')} = ${tens * 10} + $ones'),
                  if (scene.allows(LearningSceneInput.resetCount))
                    _button('lumo-place-value-reset', 'Noch einmal zählen',
                        _action(LearningSceneInput.resetCount)),
                ] else ...[
                  Text(scene.instruction),
                  const SizedBox(height: 14),
                  LumoPlaceValueBlocks(
                      tens: rods.length,
                      ones: cubes.length,
                      selectedOnes: marked(cubes),
                      reduceMotion: calm,
                      oneKeyPrefix: 'lumo-loose-cube',
                      onOneTap: scene.allows(LearningSceneInput.selectObject)
                          ? (i) => _send(LearningSceneInput.selectObject,
                              objectId: cubes[i].id)
                          : null),
                  if (!bundled) ...[
                    Text('${scene.fact('selected')} Würfel ausgewählt'),
                    _button('lumo-bundle-ten', 'Zehner bündeln',
                        _action(LearningSceneInput.bundleTen)),
                  ],
                ],
                if (scene.allows(LearningSceneInput.startConstruction)) ...[
                  const SizedBox(height: 12),
                  const Text('Jetzt eine andere Zahl – ohne Lumos Hilfe.'),
                  _button('lumo-place-value-build-next', 'Neue Zahl bauen',
                      _action(LearningSceneInput.startConstruction)),
                ],
              ],
              if (scene.stage == LearningSceneStage.construct) ...[
                Text(scene.instruction),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _button('lumo-build-add-ten', '+ Zehner',
                      _action(LearningSceneInput.addTen)),
                  _button('lumo-build-remove-ten', '− Zehner',
                      _action(LearningSceneInput.removeTen)),
                  _button('lumo-build-add-one', '+ Einer',
                      _action(LearningSceneInput.addOne)),
                  _button('lumo-build-remove-one', '− Einer',
                      _action(LearningSceneInput.removeOne)),
                ]),
                const SizedBox(height: 12),
                LumoPlaceValueBlocks(
                    tens: scene.fact('builtTens'),
                    ones: scene.fact('builtOnes'),
                    reduceMotion: calm),
                _button('lumo-build-check', 'Meine Zahl prüfen',
                    _action(LearningSceneInput.submitConstruction)),
              ],
              if (scene.stage == LearningSceneStage.explain) ...[
                Text(scene.instruction),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final choice in scene.choices)
                    _button(
                        'lumo-comprehension-$choice',
                        '$choice',
                        () => _send(LearningSceneInput.answerChoice,
                            value: choice))
                ]),
              ],
              if (scene.feedback != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(scene.feedback!)),
              if (scene.stage == LearningSceneStage.done)
                Text(scene.instruction),
            ])));
  }

  Widget _button(String key, String label, VoidCallback? action) =>
      OutlinedButton(
          key: ValueKey(key),
          onPressed: action,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: const Color(0xFFE3F7FF),
              disabledForegroundColor: const Color(0xFF93AAC5),
              side: const BorderSide(color: Color(0xAA65DEFF)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
          child: Text(label));
}
