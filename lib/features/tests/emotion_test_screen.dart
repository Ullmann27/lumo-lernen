import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/iq/exam_session_owner.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';
import 'emotion_scenarios.dart';
import 'iq/exam_companion_scope.dart';

const _ink = Color(0xff142c36);
const _mint = Color(0xffa5ded0);
const _paper = Color(0xfff6f4e9);

class EmotionTestScreen extends StatefulWidget {
  const EmotionTestScreen({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<EmotionTestScreen> createState() => _EmotionTestScreenState();
}

class _EmotionTestScreenState extends State<EmotionTestScreen> {
  late final ExamSessionOwner _owner;
  late final List<EmotionScene> _scenes;
  final _scroll = ScrollController();
  final _answers = <int?>[];
  int _page = 0;
  int? _choice;

  @override
  void initState() {
    super.initState();
    _owner = ExamSessionOwner(widget.appState)..addListener(_retire);
    _scenes = emotionScenesFor(_owner.grade);
  }

  void _retire() {
    if (mounted) setState(_answers.clear);
  }

  @override
  void dispose() {
    _owner.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _next() {
    if (_owner.retired || _page >= _scenes.length) return;
    setState(() {
      _answers.add(_choice);
      _page++;
      _choice = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.state.settings;
    final calm = settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
    if (_owner.retired) {
      return Scaffold(
          appBar: AppBar(title: const Text('Gefühls-Kompass')),
          body: const SafeArea(
              child: Center(
                  child: Text(
                      'Das Profil wurde gewechselt. Öffne eine neue Runde in den Tests.'))));
    }
    final finished = _page == _scenes.length;
    final scene = finished ? null : _scenes[_page];
    final selected = _choice;
    final content = SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 570),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
                color: _ink, fontFamily: 'Nunito', fontSize: 18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (scene != null) ...[
                    Row(children: [
                      Expanded(
                          child: Text(
                              'Geschichte ${_page + 1} von ${_scenes.length}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 78,
                          child: LinearProgressIndicator(
                            value: _page / _scenes.length,
                            minHeight: 6,
                            color: const Color(0xff227263),
                            backgroundColor: const Color(0xffcadcd4),
                          )),
                    ]),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                          color: _ink, borderRadius: BorderRadius.circular(22)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(scene.title,
                                        style: const TextStyle(
                                            color: _mint,
                                            fontSize: 25,
                                            height: 1.15,
                                            fontWeight: FontWeight.w900))),
                                LumoCharacter(
                                    size: 68,
                                    pose: LumoDesignFoxPose.armsOpen,
                                    reduceMotion: calm,
                                    idleHops: false),
                              ]),
                              const SizedBox(height: 8),
                              Text(scene.story,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      height: 1.4)),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(scene.prompt,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (int i = 0; i < scene.choices.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          key: ValueKey('emotion-choice-$i'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            foregroundColor: _ink,
                            disabledForegroundColor: _ink,
                            backgroundColor:
                                selected == i ? _mint : Colors.white,
                            side: BorderSide(
                                color: selected == i
                                    ? const Color(0xff267367)
                                    : const Color(0xffb1c2b9)),
                          ),
                          onPressed: selected == null
                              ? () => setState(() => _choice = i)
                              : null,
                          child: Text(scene.choices[i].text,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (selected != null)
                      Semantics(
                          liveRegion: true,
                          child: Container(
                            key: ValueKey('emotion-reflection-$_page'),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: const Color(0xffe5eade),
                                borderRadius: BorderRadius.circular(14)),
                            child: Text(scene.choices[selected].feedback),
                          )),
                    const SizedBox(height: 10),
                    if (selected == null)
                      TextButton(
                          onPressed: _next,
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xff285d53),
                              minimumSize: const Size(0, 48)),
                          child: const Text('Diese Geschichte überspringen'))
                    else
                      _action(
                          _page + 1 == _scenes.length
                              ? 'Rückblick öffnen'
                              : 'Nächste Geschichte',
                          _next),
                  ] else ...[
                    Center(
                        child: LumoCharacter(
                            size: 112,
                            pose: LumoDesignFoxPose.bookWelcome,
                            reduceMotion: calm,
                            idleHops: false)),
                    const Text('Dein Rückblick',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                        'Du hast bei ${_answers.whereType<int>().length} von ${_scenes.length} Geschichten eine Antwort gewählt.'),
                    const SizedBox(height: 16),
                    for (int i = 0; i < _scenes.length; i++)
                      Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_scenes[i].title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  if (_answers[i] case final int chosen) ...[
                                    Text(_scenes[i].choices[chosen].text),
                                    const SizedBox(height: 4),
                                    Text(_scenes[i].choices[chosen].feedback),
                                  ] else
                                    const Text('Übersprungen'),
                                ]),
                          )),
                    const SizedBox(height: 12),
                    _action('Zurück zu den Tests',
                        () => Navigator.of(context).pop()),
                  ],
                ]),
          ),
        ),
      ),
    );
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        title: const Text('Gefühls-Kompass'),
      ),
      body: SafeArea(
        top: false,
        child: scene == null
            ? content
            : ExamCompanionScope(
                appState: widget.appState,
                generation: _owner.generation,
                taskId: 'emotion-${_owner.grade}-$_page',
                subject: 'Soziales Lernen',
                unit: 'Gefühls-Kompass',
                prompt: scene.story,
                instruction: [
                  scene.prompt,
                  ...scene.choices.map((option) => option.text)
                ].join(' '),
                child: content,
              ),
      ),
    );
  }

  Widget _action(String label, VoidCallback onPressed) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: _ink,
            foregroundColor: Colors.white),
        child: Text(label),
      );
}
