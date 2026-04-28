import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'core/lumo_companion_agent.dart';
import 'core/school_exercise_generator.dart';
import 'widgets/drawing_pad.dart';
import 'widgets/embedded_lumo_fox.dart';
import 'widgets/profile_screen.dart';
import 'widgets/reference_home_dashboard.dart';

void main() => runApp(const LumoApp());

const String introVideoAsset = 'assets/videos/lumo_intro.mp4';
const String lumoFoxAsset = 'assets/images/lumo_fox.png';

class LumoApp extends StatelessWidget {
  const LumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumo Lernen',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
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
  String? picked;
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
  }

  void _startTest() {
    testTasks
      ..clear()
      ..addAll(factory.buildSession(grade: grade, count: 10, subject: subject, weakSkills: practice));
    testScore = 0;
    testQuestion = 0;
    testFinished = false;
    picked = null;
    mode = LumoMode.test;
    message = agent.reactToEvent('test_start', practice: practice);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    if (wide && mode == LumoMode.home) {
      return Scaffold(
        body: SafeArea(
          child: ReferenceHomeDashboard(
            stars: stars,
            xp: xp,
            level: level,
            progress: progressPercent,
            lumo: const LumoFox(size: 230, mood: 'greet'),
            onMath: () => setState(() => _startSubject('Mathematik')),
            onGerman: () => setState(() => _startSubject('Deutsch')),
            onEnglish: () => setState(() => _startSubject('Englisch')),
            onPractice: () => setState(() { mode = LumoMode.practice; currentTask = _newTask(); }),
            onTest: () => setState(_startTest),
            onSchoolwork: () => setState(_startTest),
            onPhoto: () => setState(() => mode = LumoMode.scan),
            onContinue: () => setState(() { mode = LumoMode.practice; currentTask = _newTask(); }),
            onProfile: () => setState(() => mode = LumoMode.profile),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xfffff0d7), Color(0xfffffaf4), Color(0xffe8fff6)])),
          child: Stack(children: [
            Row(children: [if (wide) _rail(), Expanded(child: _page()), if (wide) _lumoPanel()]),
            if (!wide) _floatingLumo(),
          ]),
        ),
      ),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _selectNav,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Lernen'),
          NavigationDestination(icon: Icon(Icons.assignment_rounded), label: 'Test'),
          NavigationDestination(icon: Icon(Icons.draw_rounded), label: 'Übung'),
          NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  int get _navIndex {
    if (mode == LumoMode.lesson) return 1;
    if (mode == LumoMode.test) return 2;
    if (mode == LumoMode.practice) return 3;
    if (mode == LumoMode.profile) return 4;
    return 0;
  }

  void _selectNav(int i) => setState(() {
        mode = [LumoMode.home, LumoMode.lesson, LumoMode.test, LumoMode.practice, LumoMode.profile][i];
        if (mode == LumoMode.test) _startTest();
      });

  Widget _rail() => NavigationRail(
        selectedIndex: _navIndex,
        onDestinationSelected: _selectNav,
        labelType: NavigationRailLabelType.all,
        destinations: const [
          NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('Home')),
          NavigationRailDestination(icon: Icon(Icons.school_rounded), label: Text('Lernen')),
          NavigationRailDestination(icon: Icon(Icons.assignment_rounded), label: Text('Test')),
          NavigationRailDestination(icon: Icon(Icons.draw_rounded), label: Text('Übung')),
          NavigationRailDestination(icon: Icon(Icons.analytics_rounded), label: Text('Profil')),
        ],
      );

  Widget _page() => ListView(padding: const EdgeInsets.all(18), children: [_glass(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), Text(message, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 16), _screen()]))]);

  String get _title {
    if (mode == LumoMode.lesson) return 'Unterricht';
    if (mode == LumoMode.practice) return 'Übung';
    if (mode == LumoMode.test) return 'Test';
    if (mode == LumoMode.coach) return 'Lumo-KI';
    if (mode == LumoMode.scan) return 'Aufgabe fotografieren';
    if (mode == LumoMode.profile) return 'Profil';
    return 'Home';
  }

  Widget _screen() {
    if (mode == LumoMode.lesson) return _lesson();
    if (mode == LumoMode.practice) return _taskView(currentTask, false);
    if (mode == LumoMode.test) return _test();
    if (mode == LumoMode.coach) return _coach();
    if (mode == LumoMode.scan) return _scan();
    if (mode == LumoMode.profile) return _profile();
    return _mobileHome();
  }

  Widget _mobileHome() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [LumoFox(size: 120, mood: 'greet'), SizedBox(width: 12), Expanded(child: Text('Hallo, Lena! Bereit für ein neues Lernabenteuer?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))]),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _homeButton('Mathematik', Icons.calculate_rounded, Colors.orange, () => _startSubject('Mathematik')),
          _homeButton('Deutsch', Icons.menu_book_rounded, Colors.purple, () => _startSubject('Deutsch')),
          _homeButton('Englisch', Icons.language_rounded, Colors.teal, () => _startSubject('Englisch')),
          _homeButton('Test', Icons.assignment_rounded, Colors.blue, _startTest),
          _homeButton('Foto', Icons.camera_alt_rounded, Colors.deepPurple, () => mode = LumoMode.scan),
          _homeButton('Profil', Icons.analytics_rounded, Colors.brown, () => mode = LumoMode.profile),
        ]),
      ]);

  Widget _homeButton(String t, IconData i, Color c, VoidCallback tap) => InkWell(onTap: () => setState(tap), child: Container(width: 160, height: 130, padding: const EdgeInsets.all(16), decoration: _box(c.withOpacity(.16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 34), const Spacer(), Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))])));

  Widget _lesson() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, children: [ChoiceChip(label: const Text('1. Klasse'), selected: grade == 1, onSelected: (_) => setState(() { grade = 1; currentTask = _newTask(); })), ChoiceChip(label: const Text('2. Klasse'), selected: grade == 2, onSelected: (_) => setState(() { grade = 2; currentTask = _newTask(); }))]),
        const SizedBox(height: 12),
        ...Curriculum.subjects.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _glass(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: e.value.map((u) => ActionChip(label: Text(u), onPressed: () => setState(() { subject = e.key; lessonUnit = u; currentTask = _newTask(); mode = LumoMode.practice; }))).toList())])))),
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
      Timer(const Duration(milliseconds: 850), () => setState(() { currentTask = _newTask(); foxMood = 'greet'; }));
    } else {
      setState(() { errors++; practice[task.unit] = (practice[task.unit] ?? 0) + 1; foxMood = 'comfort'; message = agent.reactToEvent(errors >= 3 ? 'wrong_3' : 'wrong_1', practice: practice); if (errors >= 3) currentTask = _newTask(); });
    }
  }

  Widget _test() {
    if (testFinished) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircularProgressIndicator(), const SizedBox(height: 14), Text('Test fertig', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text('Punkte: $testScore / ${testTasks.length}'), Text('Note: $lastGrade', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.deepOrange)), FilledButton(onPressed: () => setState(() => mode = LumoMode.profile), child: const Text('Zum Profil'))]);
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
        }
      });

  Widget _coach() {
    final c = TextEditingController();
    return Column(children: [TextField(controller: c, decoration: const InputDecoration(labelText: 'Frag Lumo etwas zum Lernen')), const SizedBox(height: 10), FilledButton(onPressed: () => setState(() => message = agent.answerChild(c.text)), child: const Text('Lumo antworten lassen')), Text(message)]);
  }

  Widget _scan() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Scan-Simulation'), const TextField(maxLines: 3), FilledButton(onPressed: () => setState(() { practice['Minus bis 20'] = (practice['Minus bis 20'] ?? 0) + 1; mode = LumoMode.profile; }), child: const Text('Analysieren'))]);
  Widget _profile() => ProfileScreen(
        stars: stars,
        xp: xp,
        level: level,
        progress: progressPercent,
        solved: solved,
        practice: practice,
        lastGrade: lastGrade,
      );

  Widget _lumoPanel() => Container(width: 320, margin: const EdgeInsets.all(14), child: _glass(Column(children: [LumoFox(size: 190, mood: foxMood), Text('★ $stars', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text(message, textAlign: TextAlign.center)])));
  Widget _floatingLumo() => Positioned(right: 10, bottom: 10, child: IgnorePointer(child: Container(padding: const EdgeInsets.all(8), decoration: _box(Colors.white.withOpacity(.8)), child: LumoFox(size: 90, mood: foxMood))));
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.translate(offset: Offset(0, jump ? -18 * controller.value : -5 * controller.value), child: Transform.scale(scale: 1 + (jump ? .035 : .012) * controller.value, child: child)),
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.42,
        child: Image.asset(
          lumoFoxAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => EmbeddedLumoFox(size: widget.size),
        ),
      ),
    );
  }
}
