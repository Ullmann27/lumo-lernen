import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'app/app_theme.dart';
import 'core/lumo_companion_agent.dart';
import 'core/lumo_voice.dart';
import 'core/school_exercise_generator.dart';
import 'widgets/drawing_pad.dart';
import 'widgets/embedded_lumo_fox.dart';
import 'widgets/free_lumo_fox.dart';
import 'widgets/parental_gate.dart';
import 'widgets/profile_screen.dart';
import 'widgets/scan_screen.dart';
import 'widgets/stable_lumo_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LumoApp());
}

const String introVideoAsset = 'assets/videos/lumo_intro.mp4';
const String lumoFoxAsset = 'assets/images/lumo_fox.png';

class LumoApp extends StatelessWidget {
  const LumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumo Lernen',
      theme: LumoAppTheme.light(),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool showIntro = true;
  @override
  Widget build(BuildContext context) => showIntro ? IntroScreen(onDone: () => setState(() => showIntro = false)) : const LumoHome();
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  VideoPlayerController? controller;
  bool ready = false;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = VideoPlayerController.asset(introVideoAsset);
    controller = c;
    try {
      await c.initialize();
      if (!mounted) return;
      c.addListener(() {
        if (c.value.isInitialized && c.value.duration.inMilliseconds > 0 && c.value.position >= c.value.duration) {
          widget.onDone();
        }
      });
      setState(() => ready = true);
      unawaited(c.play());
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment.topCenter, radius: 1.2, colors: [Color(0xffffd68a), Color(0xfffff7e8), Color(0xffdbfff2)]),
        ),
        child: SafeArea(
          child: Stack(children: [
            Center(
              child: ready && c != null && c.value.isInitialized
                  ? AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const LumoFox(size: 190, mood: 'jump'),
                      const SizedBox(height: 12),
                      const Text('Lumo Lernen', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(failed ? 'Video fehlt noch: assets/videos/lumo_intro.mp4' : 'Dein Lernfuchs ist bereit.', textAlign: TextAlign.center),
                    ]),
            ),
            Positioned(right: 16, bottom: 16, child: FilledButton.tonalIcon(onPressed: widget.onDone, icon: const Icon(Icons.skip_next_rounded), label: const Text('Intro überspringen'))),
          ]),
        ),
      ),
    );
  }
}

enum LumoMode { home, lesson, practice, test, coach, scan, profile }

class LumoHome extends StatefulWidget {
  const LumoHome({super.key});
  @override
  State<LumoHome> createState() => _LumoHomeState();
}

class _LumoHomeState extends State<LumoHome> {
  final factory = ExerciseFactory();
  final agent = const LumoCompanionAgent();
  LumoMode mode = LumoMode.home;
  int grade = 1;
  String subject = 'Alle';
  String lessonUnit = 'Alle';
  int stars = 24;
  int xp = 840;
  int errors = 0;
  int testScore = 0;
  int testQuestion = 0;
  int lastGrade = 0;
  bool testFinished = false;
  String message = 'Hallo! Womit wollen wir heute lernen?';
  String foxMood = 'greet';
  final Map<String, int> solved = {};
  final Map<String, int> practice = {};
  final Set<String> usedUnits = {};
  final List<LumoTask> testTasks = [];
  late LumoTask currentTask;

  int get level => xp ~/ 400 + 1;
  int get progressPercent => ((xp % 1000) / 10).round().clamp(1, 99);

  @override
  void initState() {
    super.initState();
    currentTask = _newTask();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await LumoVoice.instance.speak('Hallo Lena! Schoen, dass du da bist. Womit wollen wir heute lernen?');
    });
  }

  Future<void> _testVoice() async => LumoVoice.instance.test();

  Future<void> _openProfileSecured() async {
    final ok = await ParentalGate.show(context);
    if (!mounted) return;
    if (ok) setState(() => mode = LumoMode.profile);
  }

  LumoTask _newTask() {
    final task = factory.next(grade: grade, subject: subject, unit: lessonUnit, weakSkills: practice, avoidUnits: usedUnits);
    usedUnits.add(task.unit);
    if (usedUnits.length > 12) usedUnits.clear();
    return task;
  }

  void _startSubject(String s) {
    subject = s;
    lessonUnit = 'Alle';
    mode = LumoMode.practice;
    currentTask = _newTask();
    message = 'Ich suche dir passende Aufgaben in $s aus.';
    foxMood = 'point';
  }

  void _startLesson() {
    mode = LumoMode.lesson;
    message = 'Such dir ein Fach und ein Thema aus. Ich begleite dich.';
    foxMood = 'greet';
  }

  void _startPractice() {
    mode = LumoMode.practice;
    currentTask = _newTask();
    message = agent.reactToEvent('mission_start', practice: practice);
    foxMood = 'greet';
  }

  void _startTest() {
    testTasks
      ..clear()
      ..addAll(factory.buildSession(grade: grade, count: 10, subject: subject, weakSkills: practice));
    testScore = 0;
    testQuestion = 0;
    testFinished = false;
    mode = LumoMode.test;
    message = agent.reactToEvent('test_start', practice: practice);
    foxMood = 'think';
    LumoVoice.instance.speak(message);
  }

  void _goHome() {
    mode = LumoMode.home;
    message = 'Hallo! Womit wollen wir heute lernen?';
    foxMood = 'greet';
  }

  int get _activeIndex {
    if (mode == LumoMode.lesson) return 1;
    if (mode == LumoMode.profile) return 5;
    return mode == LumoMode.home ? 0 : 2;
  }

  Widget _lumoWidget(double size) => FreeLumoFox(
        size: size,
        mood: foxMood,
        message: message,
        onTap: () => LumoVoice.instance.speak(message),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StableLumoShell(
          activeIndex: _activeIndex,
          title: _title,
          subtitle: message,
          body: _screen(),
          lumo: _lumoWidget(235),
          stars: stars,
          xp: xp,
          level: level,
          progress: progressPercent,
          onHome: () => setState(_goHome),
          onLearn: () => setState(_startLesson),
          onPractice: () => setState(_startPractice),
          onTest: () => setState(_startTest),
          onScan: () => setState(() => mode = LumoMode.scan),
          onProfile: _openProfileSecured,
          onVoice: _testVoice,
        ),
      ),
    );
  }

  String get _title {
    if (mode == LumoMode.lesson) return 'Unterricht';
    if (mode == LumoMode.practice) return 'Was möchtest du lernen?';
    if (mode == LumoMode.test) return 'Test';
    if (mode == LumoMode.coach) return 'Lumo-KI';
    if (mode == LumoMode.scan) return 'Aufgabe fotografieren';
    if (mode == LumoMode.profile) return 'Profil';
    return 'Was möchtest du lernen?';
  }

  Widget _screen() {
    if (mode == LumoMode.lesson) return _lesson();
    if (mode == LumoMode.practice) return _taskView(currentTask, false);
    if (mode == LumoMode.test) return _test();
    if (mode == LumoMode.coach) return _coach();
    if (mode == LumoMode.scan) return _scan();
    if (mode == LumoMode.profile) return _profile();
    return _homeGrid();
  }

  Widget _homeGrid() => Wrap(spacing: 16, runSpacing: 16, children: [
        _learningCard('Mathematik', 'Zahlen, Rechnen,\nGeometrie & mehr', '1²', const Color(0xffff8700), () => _startSubject('Mathematik')),
        _learningCard('Deutsch', 'Lesen, Schreiben,\nGrammatik', 'A', const Color(0xff8b5cf6), () => _startSubject('Deutsch')),
        _learningCard('Englisch', 'Wörter, Sätze,\nVerstehen', 'Hi!', const Color(0xff10a894), () => _startSubject('Englisch')),
        _learningCard('Übung', 'Interaktive Übungen\nund Spiele', '🎮', const Color(0xffff625d), _startPractice),
        _learningCard('Test', 'Teste dein Wissen\nund sammle Sterne', '📋', const Color(0xff3a86e8), _startTest),
        _learningCard('Schularbeit', 'Gemischter Test\nmit Note', 'A+', const Color(0xffff9800), _startTest),
        _learningCard('Aufgabe fotografieren', 'Mach ein Foto deiner Aufgabe\nund lass dir helfen!', '📷', const Color(0xff9c55e8), () => mode = LumoMode.scan, wide: true),
        _learningCard('Weiterlernen', 'Setze da weiter, wo du\naufgehört hast', '📖', const Color(0xff08a892), _startPractice, wide: true),
      ]);

  Widget _learningCard(String title, String sub, String object, Color accent, VoidCallback tap, {bool wide = false}) {
    return InkWell(
      onTap: () => setState(tap),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: wide ? 330 : 245,
        height: wide ? 145 : 165,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent.withOpacity(.15), Colors.white.withOpacity(.86)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(.78), width: 1.2),
          boxShadow: [BoxShadow(color: accent.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 13))],
        ),
        child: Stack(children: [
          Positioned(right: 4, bottom: 0, child: Text(object, style: TextStyle(fontSize: object.length > 2 ? 34 : 45, fontWeight: FontWeight.w900, color: accent, shadows: const [Shadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accent)),
            const SizedBox(height: 8),
            Text(sub, style: const TextStyle(fontSize: 13, height: 1.15, fontWeight: FontWeight.w700, color: Color(0xff635850))),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), decoration: BoxDecoration(color: Colors.white.withOpacity(.74), borderRadius: BorderRadius.circular(99)), child: Text('Weiterlernen →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accent))),
          ]),
        ]),
      ),
    );
  }

  Widget _lesson() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('1. Klasse'), selected: grade == 1, onSelected: (_) => setState(() { grade = 1; currentTask = _newTask(); })),
          ChoiceChip(label: const Text('2. Klasse'), selected: grade == 2, onSelected: (_) => setState(() { grade = 2; currentTask = _newTask(); })),
        ]),
        const SizedBox(height: 12),
        ...Curriculum.subjects.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _glass(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: e.value.map((u) => ActionChip(label: Text(u), onPressed: () => setState(() { subject = e.key; lessonUnit = u; currentTask = _newTask(); mode = LumoMode.practice; message = 'Wir ueben jetzt $u.'; }))).toList()),
        ])))),
      ]);

  Widget _taskView(LumoTask task, bool test) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Chip(label: Text('${task.grade}. Klasse • ${task.subject} • ${task.unit}')),
        Text(task.prompt, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        task.handwriting ? const DrawingPad(hint: 'Schreibe hier mit dem Finger.') : _visual(task),
        const SizedBox(height: 12),
        if (!test) Text('Lumo erklärt: ${task.explanation}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: task.choices.map((o) => FilledButton.tonal(onPressed: () => test ? _answerTest(task, o) : _answerPractice(task, o), child: Text(o, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))).toList()),
        if (!test) Text('Versuche: $errors/3'),
      ]);

  Widget _visual(LumoTask task) {
    if (task.visual == 'line' || task.unit.contains('Minus')) return Wrap(spacing: 4, children: List.generate(21, (i) => CircleAvatar(radius: 13, backgroundColor: Colors.orange.shade100, child: Text('$i', style: const TextStyle(fontSize: 10)))));
    if (task.visual == 'dots' || task.unit.contains('Plus')) return Wrap(spacing: 5, children: List.generate(10, (i) => CircleAvatar(radius: 12, backgroundColor: i < 5 ? Colors.blue.shade200 : Colors.orange.shade300)));
    return const Icon(Icons.auto_awesome, size: 54, color: Colors.orange);
  }

  void _answerPractice(LumoTask task, String option) {
    if (option == task.answer) {
      setState(() { stars += 3; xp += 20; errors = 0; foxMood = 'celebrate'; solved[task.unit] = (solved[task.unit] ?? 0) + 1; message = agent.reactToEvent('correct', practice: practice); });
      LumoVoice.instance.speak(message);
      Timer(const Duration(milliseconds: 850), () => setState(() { currentTask = _newTask(); foxMood = 'greet'; }));
    } else {
      setState(() { errors++; practice[task.unit] = (practice[task.unit] ?? 0) + 1; foxMood = 'comfort'; message = agent.reactToEvent(errors >= 3 ? 'wrong_3' : 'wrong_1', practice: practice); if (errors >= 3) currentTask = _newTask(); });
      LumoVoice.instance.speak(message);
    }
  }

  Widget _test() {
    if (testFinished) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircularProgressIndicator(), const SizedBox(height: 14), const Text('Test fertig', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text('Punkte: $testScore / ${testTasks.length}'), Text('Note: $lastGrade', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.deepOrange)), FilledButton(onPressed: () => setState(() => mode = LumoMode.profile), child: const Text('Zum Profil'))]);
    final task = testTasks.isEmpty ? currentTask : testTasks[testQuestion.clamp(0, testTasks.length - 1)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Aufgabe ${testQuestion + 1}/${testTasks.isEmpty ? 10 : testTasks.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), _taskView(task, true)]);
  }

  void _answerTest(LumoTask task, String option) => setState(() {
        if (option == task.answer) testScore++;
        if (option != task.answer) practice[task.unit] = (practice[task.unit] ?? 0) + 1;
        testQuestion++;
        if (testQuestion >= testTasks.length) {
          testFinished = true;
          final p = testTasks.isEmpty ? 0.0 : testScore / testTasks.length;
          lastGrade = p >= .9 ? 1 : p >= .8 ? 2 : p >= .65 ? 3 : p >= .5 ? 4 : 5;
          message = agent.reactToEvent('test_finished', practice: practice);
          LumoVoice.instance.speak(message);
        }
      });

  Widget _coach() {
    final c = TextEditingController();
    return Column(children: [TextField(controller: c, decoration: const InputDecoration(labelText: 'Frag Lumo etwas zum Lernen')), const SizedBox(height: 10), FilledButton(onPressed: () => setState(() { message = agent.answerChild(c.text); LumoVoice.instance.speak(message); }), child: const Text('Lumo antworten lassen')), Text(message)]);
  }

  Widget _scan() => ScanScreen(
        onCancel: () => setState(_goHome),
        onTextDetected: (text) {
          setState(() { message = text.length > 200 ? 'Ich hab das gelesen. Lass uns die Aufgabe gemeinsam loesen!' : 'Ich hab das gelesen: "$text"'; foxMood = 'celebrate'; mode = LumoMode.coach; });
          LumoVoice.instance.speak('Super, ich habe deine Aufgabe gelesen. Lass uns gemeinsam ueben.');
        },
      );

  Widget _profile() => ProfileScreen(stars: stars, xp: xp, level: level, progress: progressPercent, solved: solved, practice: practice, lastGrade: lastGrade);

  Widget _glass(Widget child) => Container(decoration: _box(Colors.white.withOpacity(.82)), padding: const EdgeInsets.all(22), child: child);
  BoxDecoration _box(Color color) => BoxDecoration(color: color, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white70), boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(.10), blurRadius: 22, offset: const Offset(0, 12))]);
}

class LumoFox extends StatefulWidget {
  const LumoFox({super.key, required this.size, required this.mood});
  final double size;
  final String mood;
  @override
  State<LumoFox> createState() => _LumoFoxState();
}

class _LumoFoxState extends State<LumoFox> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))..repeat(reverse: true);
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final jump = widget.mood == 'celebrate' || widget.mood == 'jump';
    return AnimatedBuilder(animation: controller, builder: (context, child) => Transform.translate(offset: Offset(0, jump ? -18 * controller.value : -5 * controller.value), child: Transform.scale(scale: 1 + (jump ? .035 : .012) * controller.value, child: child)), child: SizedBox(width: widget.size, height: widget.size * 1.42, child: Image.asset(lumoFoxAsset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => EmbeddedLumoFox(size: widget.size))));
  }
}
