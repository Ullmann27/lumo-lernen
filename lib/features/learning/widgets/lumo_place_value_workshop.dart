import 'package:flutter/material.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../../widgets/design/lumo_design_system.dart';
import 'lumo_place_value_blocks.dart';
import '../../../domain/learning_intelligence/lesson_scene_engine.dart';

class LumoPlaceValueTransfer {
  const LumoPlaceValueTransfer(
      {required this.number,
      required this.correct,
      required this.independent,
      this.proof});
  final int number;
  final bool correct;
  final bool independent;
  final SceneCompletion? proof;
}

enum _Stage { explore, construct, explain, done }

/// Voluntary offline workshop. Exploring the worked example is never a score.
/// A different number must be built AND explained before emitting evidence.
class LumoPlaceValueWorkshop extends StatefulWidget {
  const LumoPlaceValueWorkshop(
      {super.key,
      required this.number,
      this.reduceMotion = false,
      this.onTransferChecked,
      this.lesson})
      : assert(number >= 10 && number <= 99);
  final int number;
  final PlaceValueLessonSession? lesson;
  final bool reduceMotion;
  final ValueChanged<LumoPlaceValueTransfer>? onTransferChecked;

  static int? numberForPrompt(String prompt) {
    final normalized = prompt.toLowerCase();
    if (!normalized.contains('zehner') && !normalized.contains('einer'))
      return null;
    final matches = RegExp(r'\b\d{2}\b').allMatches(normalized).toList();
    if (matches.length != 1) return null;
    return int.tryParse(matches.single.group(0)!);
  }

  @override
  State<LumoPlaceValueWorkshop> createState() => _LumoPlaceValueWorkshopState();
}

class _LumoPlaceValueWorkshopState extends State<LumoPlaceValueWorkshop> {
  final Set<int> _counted = {};
  final Set<int> _selected = {};
  final _fox = LumoCharacterController();
  _Stage _stage = _Stage.explore;
  bool _bundleMode = false;
  bool _bundled = false;
  bool _independent = true;
  int _builtTens = 0;
  int _builtOnes = 0;
  String? _feedback;
  PlaceValueLessonSession? _localLesson;
  PlaceValueLessonSession get _lesson =>
      widget.lesson ??
      (_localLesson ??= PlaceValueLessonSession(
          sourceNumber: widget.number,
          targetNumber:
              widget.number > 55 ? widget.number - 27 : widget.number + 27,
          sourceProblemId: 'place-value:${widget.number}'));
  int get _target => _lesson.targetNumber;

  @override
  void didUpdateWidget(covariant LumoPlaceValueWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _localLesson = null;
      _counted.clear();
      _selected.clear();
      _stage = _Stage.explore;
      _bundleMode = false;
      _bundled = false;
      _independent = true;
      _builtTens = 0;
      _builtOnes = 0;
      _feedback = null;
    }
  }

  @override
  void dispose() {
    _fox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calm = widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final tens = widget.number ~/ 10;
    final ones = widget.number % 10;
    final complete = _counted.length == tens;
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
              _header(context, calm),
              const SizedBox(height: 8),
              Text(
                  switch (_stage) {
                    _Stage.explore => '1 · Gemeinsam entdecken',
                    _Stage.construct => '2 · Selbst bauen',
                    _Stage.explain => '3 · Erklär es Lumo',
                    _Stage.done => 'Dein Lernschritt'
                  },
                  style: const TextStyle(color: Color(0xFF8DEBFF))),
              const SizedBox(height: 12),
              if (_stage == _Stage.explore) ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _button('lumo-place-value-count-mode', 'Stangen zählen',
                      () => setState(() => _bundleMode = false)),
                  _button('lumo-place-value-bundle-mode', 'Selbst bündeln', () {
                    _fox.think();
                    setState(() => _bundleMode = true);
                  }),
                ]),
                const SizedBox(height: 12),
                if (!_bundleMode) ...[
                  Text(
                      'Wir bauen ${widget.number}. Tippe jede blaue Zehnerstange einmal an und zähle die vollen Zehner.'),
                  const SizedBox(height: 14),
                  LumoPlaceValueBlocks(
                      tens: tens,
                      ones: ones,
                      selectedTens: _counted,
                      reduceMotion: calm,
                      onTenTap: (i) => setState(() {
                            if (!_counted.add(i)) _counted.remove(i);
                          })),
                  const SizedBox(height: 14),
                  Text(
                      complete
                          ? 'Geschafft! Du hast ${_counted.length} volle Zehner und $ones Einer gezählt.'
                          : 'Du hast ${_counted.length} volle Zehner gezählt. Zähle weiter – in jeder Stange stecken zehn.',
                      key: const ValueKey('lumo-place-value-feedback')),
                  if (complete) Text('${widget.number} = ${tens * 10} + $ones'),
                  if (_counted.isNotEmpty)
                    _button('lumo-place-value-reset', 'Noch einmal zählen',
                        () => setState(_counted.clear)),
                ] else ...[
                  Text(_bundled
                      ? 'Die Zahl bleibt gleich: $tens Zehner und $ones Einer.'
                      : 'Wir öffnen eine Stange. Wähle genau zehn lose Würfel und bündle sie wieder. Die Zahl bleibt ${widget.number}.'),
                  const SizedBox(height: 14),
                  LumoPlaceValueBlocks(
                      tens: _bundled ? tens : tens - 1,
                      ones: _bundled ? ones : ones + 10,
                      selectedOnes: _selected,
                      reduceMotion: calm,
                      oneKeyPrefix: 'lumo-loose-cube',
                      onOneTap: _bundled
                          ? null
                          : (i) => setState(() {
                                if (!_selected.add(i)) _selected.remove(i);
                              })),
                  if (!_bundled) ...[
                    Text('${_selected.length} Würfel ausgewählt'),
                    _button(
                        'lumo-bundle-ten',
                        'Zehner bündeln',
                        _selected.length != 10
                            ? null
                            : () {
                                setState(() {
                                  _bundled = true;
                                  _selected.clear();
                                });
                                _fox.talk();
                              }),
                  ],
                ],
                if (complete || _bundled) ...[
                  const SizedBox(height: 12),
                  const Text('Jetzt eine andere Zahl – ohne Lumos Hilfe.'),
                  _button(
                      'lumo-place-value-build-next',
                      'Neue Zahl bauen',
                      () => setState(() {
                            _lesson.beginTransfer();
                            _stage = _Stage.construct;
                            _feedback = null;
                          })),
                ],
              ],
              if (_stage == _Stage.construct) ...[
                Text('Baue $_target mit Zehnerstangen und einzelnen Würfeln.'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _button(
                      'lumo-build-add-ten',
                      '+ Zehner',
                      _builtTens == 9
                          ? null
                          : () => setState(() => _builtTens++)),
                  _button(
                      'lumo-build-remove-ten',
                      '− Zehner',
                      _builtTens == 0
                          ? null
                          : () => setState(() => _builtTens--)),
                  _button(
                      'lumo-build-add-one',
                      '+ Einer',
                      _builtOnes == 9
                          ? null
                          : () => setState(() => _builtOnes++)),
                  _button(
                      'lumo-build-remove-one',
                      '− Einer',
                      _builtOnes == 0
                          ? null
                          : () => setState(() => _builtOnes--)),
                ]),
                const SizedBox(height: 12),
                LumoPlaceValueBlocks(
                    tens: _builtTens, ones: _builtOnes, reduceMotion: calm),
                _button('lumo-build-check', 'Meine Zahl prüfen', () {
                  if (_lesson
                      .submitConstruction(tens: _builtTens, ones: _builtOnes)
                      .processCorrect) {
                    setState(() {
                      _stage = _Stage.explain;
                      _feedback = null;
                    });
                  } else {
                    _fox.think();
                    setState(() {
                      _independent = false;
                      _feedback =
                          'Schau noch einmal: Jede Stange zählt zehn. Du darfst umbauen.';
                    });
                  }
                }),
              ],
              if (_stage == _Stage.explain) ...[
                Text(
                    'Du hast $_target gebaut. Wie viele Einer bleiben außerhalb der vollen Zehner?'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < 10; i++)
                    _button('lumo-comprehension-$i', '$i', () {
                      final proof = _lesson.submitComprehension(i);
                      if (proof != null) {
                        _independent = proof.independent;
                        setState(() {
                          _stage = _Stage.done;
                          _feedback = null;
                        });
                        if (_independent)
                          _fox.cheer();
                        else
                          _fox.comfort();
                        widget.onTransferChecked?.call(LumoPlaceValueTransfer(
                            number: _target,
                            correct: true,
                            independent: _independent,
                            proof: proof));
                      } else {
                        _fox.think();
                        setState(() {
                          _independent = false;
                          _feedback =
                              'Zehner sind volle Bündel. Überlege, was einzeln übrig bleibt.';
                        });
                      }
                    })
                ]),
              ],
              if (_feedback != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_feedback!)),
              if (_stage == _Stage.done)
                Text(_independent
                    ? 'Du hast eine neue Zahl selbst gebaut und Lumo erklärt. Das ist ein zusätzlicher Hinweis auf dein Verständnis.'
                    : 'Mit Übung geschafft! Beim nächsten Mal probieren wir wieder eine neue Zahl selbstständig.'),
            ])));
  }

  Widget _header(BuildContext context, bool calm) {
    const title = Text('Lumos Zehner-Werkstatt',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900));
    final fox = ExcludeSemantics(
        child: LumoCharacter(
            pose: _stage == _Stage.done && _independent
                ? LumoDesignFoxPose.cheer
                : LumoDesignFoxPose.bookPoint,
            size: 65,
            reduceMotion: calm,
            idleHops: false,
            intro: false,
            controller: _fox));
    return LayoutBuilder(
        builder: (context, bounds) => bounds.maxWidth < 260 &&
                MediaQuery.textScalerOf(context).scale(1) > 1.3
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                title,
                Align(alignment: Alignment.centerRight, child: fox)
              ])
            : Row(children: [const Expanded(child: title), fox]));
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
