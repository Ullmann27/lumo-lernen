import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'core/school_exercise_generator.dart';
import 'core/lumo_companion_agent.dart';
import 'widgets/drawing_pad.dart';
import 'widgets/premium_lumo_ui.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
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
  Widget build(BuildContext context) {
    return showIntro ? IntroVideoScreen(onDone: () => setState(() => showIntro = false)) : const LumoHome();
  }
}

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? controller;
  bool ready = false;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final c = VideoPlayerController.asset(introVideoAsset);
    controller = c;
    try {
      await c.initialize();
      if (!mounted) return;
      c.setLooping(false);
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
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: <Color>[Color(0xffffd68a), Color(0xfffff7e8), Color(0xffdbfff2)],
              ),
            ),
          ),
          const PremiumBackdrop(),
          SafeArea(
            child: Stack(
              children: <Widget>[
                Center(
                  child: ready && c != null && c.value.isInitialized
                      ? AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))
                      : _FallbackIntro(failed: failed),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Intro überspringen'),
                    onPressed: widget.onDone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackIntro extends StatelessWidget {
  const _FallbackIntro({required this.failed});
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const LumoFox(size: 190, mood: 'jump'),
          const SizedBox(height: 16),
          const Text('Lumo Lernen', textAlign: TextAlign.center, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Dein Lernfuchs ist bereit. Das Video-Intro wird abgespielt, sobald lumo_intro.mp4 im Asset-Ordner liegt.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (failed) ...const <Widget>[
            SizedBox(height: 12),
            Text('Video fehlt noch: assets/videos/lumo_intro.mp4', textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

enum LumoMode { home, lesson, practice, schoolwork, test, coach, scan, profile }

class LumoHome extends StatefulWidget {
  const LumoHome({super.key});

  @override
  State<LumoHome> createState() => _LumoHomeState();
}

class _LumoHomeState extends State<LumoHome> {
  final ExerciseFactory factory = ExerciseFactory();
  final LumoCompanionAgent agent = const LumoCompanionAgent();

  LumoMode mode = LumoMode.home;
  int grade = 1;
  String subject = 'Alle';
  String lessonUnit = 'Alle';
  int stars = 24;
  int xp = 120;
  int errors = 0;
  String? picked;
  String foxMood = 'greet';
  String message = 'Hallo, ich bin Lumo. Heute reicht eine kleine Mission.';
  final Map<String, int> solved = <String, int>{};
  final Map<String, int> practice = <String, int>{};
  final Set<String> usedTaskUnits = <String>{};
  final List<LumoTask> testTasks = <LumoTask>[];
  int testScore = 0;
  int testQuestion = 0;
  bool testFinished = false;
  int lastGrade = 0;
  late LumoTask currentTask;

  int get level => xp ~/ 100 + 1;
  double get progress => ((xp % 100) / 100).clamp(0, 1).toDouble();

  @override
  void initState() {
    super.initState();
    currentTask = _newTask();
  }

  LumoTask _newTask() {
    final task = factory.next(grade: grade, subject: subject, unit: lessonUnit, weakSkills: practice, avoidUnits: usedTaskUnits);
    usedTaskUnits.add(task.unit);
    if (usedTaskUnits.length > 12) usedTaskUnits.clear();
    return task;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xfffff0d7), Color(0xfffffaf4), Color(0xffe8fff6), Color(0xffeaf4ff)],
                ),
              ),
            ),
            const PremiumBackdrop(),
            wide ? _wideLayout() : Stack(children: <Widget>[_content(), _floatingLumo()]),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: _selectNav,
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Unterricht'),
                NavigationDestination(icon: Icon(Icons.assignment_rounded), label: 'Test'),
                NavigationDestination(icon: Icon(Icons.draw_rounded), label: 'Übung'),
                NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'Profil'),
              ],
            ),
    );
  }

  int get _navIndex => switch (mode) {
        LumoMode.home => 0,
        LumoMode.lesson => 1,
        LumoMode.test => 2,
        LumoMode.practice => 3,
        LumoMode.profile => 4,
        _ => 0,
      };

  void _selectNav(int value) {
    setState(() {
      mode = <LumoMode>[LumoMode.home, LumoMode.lesson, LumoMode.test, LumoMode.practice, LumoMode.profile][value];
      if (mode == LumoMode.test) _startTest();
    });
  }

  Widget _wideLayout() {
    return Row(
      children: <Widget>[
        _premiumRail(),
        Expanded(child: _content()),
        SizedBox(width: 320, child: _sidePanel()),
      ],
    );
  }

  Widget _premiumRail() {
    return Container(
      width: 96,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _glassDecoration(),
      child: Column(
        children: <Widget>[
          const LumoFox(size: 58, mood: 'idle'),
          const SizedBox(height: 18),
          _railIcon(Icons.home_rounded, LumoMode.home),
          _railIcon(Icons.school_rounded, LumoMode.lesson),
          _railIcon(Icons.draw_rounded, LumoMode.practice),
          _railIcon(Icons.assignment_rounded, LumoMode.test),
          _railIcon(Icons.smart_toy_rounded, LumoMode.coach),
          _railIcon(Icons.analytics_rounded, LumoMode.profile),
        ],
      ),
    );
  }

  Widget _railIcon(IconData icon, LumoMode target) {
    final selected = mode == target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(backgroundColor: selected ? const Color(0xffffc15d) : Colors.white.withOpacity(.65)),
        icon: Icon(icon, color: selected ? Colors.brown.shade900 : Colors.deepOrange),
        onPressed: () => setState(() {
          mode = target;
          if (target == LumoMode.test) _startTest();
        }),
      ),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: <Widget>[
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(_title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xff1f163a)))),
                  _pill('★ $stars'),
                  const SizedBox(width: 8),
                  _pill('Level $level'),
                ],
              ),
              Text(message, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff5a506d))),
              const SizedBox(height: 16),
              _screen(),
            ],
          ),
        ),
      ],
    );
  }

  String get _title => switch (mode) {
        LumoMode.lesson => 'Unterricht',
        LumoMode.practice => 'Übung',
        LumoMode.schoolwork => 'Schularbeit',
        LumoMode.test => 'Test',
        LumoMode.coach => 'Lumo Coach',
        LumoMode.scan => 'Scan',
        LumoMode.profile => 'Profil',
        _ => 'Home',
      };

  Widget _screen() => switch (mode) {
        LumoMode.lesson => _lesson(),
        LumoMode.practice => _practice(),
        LumoMode.schoolwork => _testMode(label: 'Schularbeit'),
        LumoMode.test => _testMode(),
        LumoMode.coach => _coach(),
        LumoMode.scan => _scan(),
        LumoMode.profile => _profile(),
        _ => _home(),
      };

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(99), boxShadow: _softShadow),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      );

  BoxDecoration _glassDecoration() => BoxDecoration(
        color: Colors.white.withOpacity(.78),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withOpacity(.75)),
        boxShadow: _softShadow,
      );

  List<BoxShadow> get _softShadow => <BoxShadow>[BoxShadow(color: Colors.deepOrange.withOpacity(.10), blurRadius: 22, offset: const Offset(0, 12))];

  Widget _home() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PremiumHeroBanner(
          title: 'Heute reicht eine kleine Mission.',
          subtitle: agent.nextSuggestion(practice),
          actionLabel: 'Mission starten',
          lumo: const LumoFox(size: 126, mood: 'greet'),
          onAction: () => setState(() {
            mode = LumoMode.practice;
            currentTask = _newTask();
          }),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            LearningWorldCard(title: 'Zahleninsel', subtitle: 'Mathe mit Punkten und Zahlenstrahl', icon: Icons.calculate_rounded, color: Colors.orange, badge: 'Mathe', onTap: () => setState(() => _startSubject('Mathematik'))),
            LearningWorldCard(title: 'Buchstabenwald', subtitle: 'Deutsch, Silben, Reime, Sätze', icon: Icons.menu_book_rounded, color: Colors.purple, badge: 'Deutsch', onTap: () => setState(() => _startSubject('Deutsch'))),
            LearningWorldCard(title: 'Schreib-Zaubertisch', subtitle: 'Finger schreiben im Heftfeld', icon: Icons.draw_rounded, color: Colors.teal, badge: 'Touch', onTap: () => setState(() => _startSubject('Schreiben'))),
            LearningWorldCard(title: 'Schularbeit', subtitle: 'Gemischter Test mit Note', icon: Icons.assignment_rounded, color: Colors.blue, badge: 'Test', onTap: () => setState(() { mode = LumoMode.test; _startTest(); })),
            LearningWorldCard(title: 'Lumo-KI', subtitle: 'Sicherer Lernfreund', icon: Icons.smart_toy_rounded, color: Colors.deepOrange, badge: 'Offline', onTap: () => setState(() => mode = LumoMode.coach)),
            LearningWorldCard(title: 'Lernprofil', subtitle: 'Plan aus Fehlern und Erfolgen', icon: Icons.analytics_rounded, color: Colors.brown, badge: 'Profil', onTap: () => setState(() => mode = LumoMode.profile)),
          ],
        ),
        const SizedBox(height: 16),
        _progressPanel(),
      ],
    );
  }

  void _startSubject(String newSubject) {
    subject = newSubject;
    lessonUnit = 'Alle';
    mode = LumoMode.practice;
    currentTask = _newTask();
  }

  Widget _progressPanel() {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Lernwelt-Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              PremiumStatCard(title: 'Sterne', value: '$stars', icon: Icons.star_rounded, color: Colors.amber),
              PremiumStatCard(title: 'Level', value: '$level', icon: Icons.workspace_premium_rounded, color: Colors.deepOrange),
              PremiumStatCard(title: 'Letzte Note', value: lastGrade == 0 ? '-' : '$lastGrade', icon: Icons.school_rounded, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress, minHeight: 12, borderRadius: BorderRadius.circular(99), color: Colors.deepOrange, backgroundColor: Colors.deepOrange.withOpacity(.12)),
          const SizedBox(height: 10),
          Text('XP bis zum nächsten Level: ${(progress * 100).round()} %'),
        ],
      ),
    );
  }

  Widget _lesson() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(label: const Text('1. Klasse'), selected: grade == 1, onSelected: (_) => setState(() { grade = 1; currentTask = _newTask(); })),
            ChoiceChip(label: const Text('2. Klasse'), selected: grade == 2, onSelected: (_) => setState(() { grade = 2; currentTask = _newTask(); })),
          ],
        ),
        const SizedBox(height: 12),
        ...Curriculum.subjects.entries.map((entry) => _subjectBlock(entry.key, entry.value)),
      ],
    );
  }

  Widget _subjectBlock(String title, List<String> units) {
    final colors = <Color>[Colors.orange, Colors.purple, Colors.teal, Colors.blue, Colors.green, Colors.deepOrange, Colors.brown];
    final color = colors[title.length % colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(28), border: Border.all(color: color.withOpacity(.18)), boxShadow: _softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: units.map((unit) => ActionChip(label: Text(unit), avatar: Icon(Icons.auto_awesome, size: 16, color: color), onPressed: () => setState(() { subject = title; lessonUnit = unit; currentTask = _newTask(); mode = LumoMode.practice; message = '$title: $unit gestartet.'; }))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _practice() => _taskView(currentTask, test: false);

  Widget _taskView(LumoTask task, {required bool test}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(.12), borderRadius: BorderRadius.circular(99)),
          child: Text('${task.grade}. Klasse • ${task.subject} • ${task.unit}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.deepOrange)),
        ),
        const SizedBox(height: 14),
        Text(task.prompt, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xff20143d))),
        const SizedBox(height: 12),
        task.handwriting ? _drawArea() : _visual(task),
        const SizedBox(height: 12),
        if (!test) Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.lightBlue.shade50, borderRadius: BorderRadius.circular(20)), child: Text('Lumo erklärt: ${task.explanation}', style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: task.choices.map((option) => FilledButton.tonal(onPressed: () => test ? _answerTest(task, option) : _answerPractice(task, option), child: Text(picked == option ? '✓ $option' : option, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))).toList(),
        ),
        if (!test) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Versuche: $errors/3')),
      ],
    );
  }

  Widget _drawArea() => const DrawingPad(hint: 'Schreibe hier mit dem Finger. Das Feld reagiert jetzt auf Touch-Bewegungen.');

  Widget _visual(LumoTask task) {
    if (task.visual == 'line' || task.unit.contains('Minus')) return Wrap(spacing: 4, children: List.generate(21, (i) => CircleAvatar(radius: 13, backgroundColor: Colors.orange.shade100, child: Text('$i', style: const TextStyle(fontSize: 10)))));
    if (task.visual == 'dots' || task.unit.contains('Plus')) return Wrap(spacing: 5, children: List.generate(10, (i) => CircleAvatar(radius: 12, backgroundColor: i < 5 ? Colors.blue.shade200 : Colors.orange.shade300)));
    if (task.visual == 'syllables') return const Text('👏 Klatsche das Wort langsam in Silben.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
    if (task.visual == 'writing') return _drawArea();
    return const Icon(Icons.auto_awesome, size: 56, color: Colors.orange);
  }

  void _answerPractice(LumoTask task, String option) {
    setState(() => picked = option);
    if (option == task.answer) {
      setState(() {
        stars += 3;
        xp += 20;
        errors = 0;
        foxMood = 'celebrate';
        solved[task.unit] = (solved[task.unit] ?? 0) + 1;
        message = agent.reactToEvent('correct', practice: practice);
      });
      Timer(const Duration(milliseconds: 850), () => setState(() { currentTask = _newTask(); picked = null; foxMood = 'greet'; }));
    } else {
      setState(() {
        errors++;
        practice[task.unit] = (practice[task.unit] ?? 0) + 1;
        foxMood = 'comfort';
        message = agent.reactToEvent(errors >= 3 ? 'wrong_3' : errors == 2 ? 'wrong_2' : 'wrong_1', practice: practice);
        if (errors >= 3) currentTask = _newTask();
      });
    }
  }

  void _startTest() {
    testTasks
      ..clear()
      ..addAll(factory.buildSession(grade: grade, count: 10, subject: subject, weakSkills: practice));
    testScore = 0;
    testQuestion = 0;
    testFinished = false;
    picked = null;
    message = agent.reactToEvent('test_start', practice: practice);
  }

  Widget _testMode({String label = 'Test'}) {
    if (testFinished) return _resultScreen(label);
    final task = testTasks.isEmpty ? currentTask : testTasks[testQuestion.clamp(0, testTasks.length - 1)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text('$label • Aufgabe ${testQuestion + 1}/${testTasks.isEmpty ? 10 : testTasks.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const Text('Gemischte Aufgaben ohne reine Wiederholung.'), const SizedBox(height: 12), _taskView(task, test: true)]);
  }

  void _answerTest(LumoTask task, String option) {
    setState(() {
      if (option == task.answer) testScore++;
      if (option != task.answer) practice[task.unit] = (practice[task.unit] ?? 0) + 1;
      testQuestion++;
      picked = null;
      if (testQuestion >= testTasks.length) {
        testFinished = true;
        final percent = testTasks.isEmpty ? 0.0 : testScore / testTasks.length;
        lastGrade = percent >= .9 ? 1 : percent >= .8 ? 2 : percent >= .65 ? 3 : percent >= .5 ? 4 : 5;
        message = agent.reactToEvent('test_finished', practice: practice);
      } else {
        message = 'Nächste Aufgabe.';
      }
    });
  }

  Widget _resultScreen(String label) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Center(child: CircularProgressIndicator()), const SizedBox(height: 16), Text('$label fertig', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text('Punkte: $testScore / ${testTasks.length}'), Text('Note: $lastGrade', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.deepOrange)), Text(agent.nextSuggestion(practice)), FilledButton.icon(icon: const Icon(Icons.analytics), label: const Text('Zum Profil'), onPressed: () => setState(() => mode = LumoMode.profile))]);

  Widget _coach() {
    final controller = TextEditingController();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Lokale sichere Lumo-KI: offline, kindgerecht, kein offener Chat.'), TextField(controller: controller, decoration: const InputDecoration(labelText: 'Frag Lumo etwas zum Lernen')), const SizedBox(height: 10), FilledButton(onPressed: () => setState(() => message = agent.answerChild(controller.text)), child: const Text('Lumo antworten lassen')), const SizedBox(height: 10), Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]);
  }

  Widget _scan() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Scan-Simulation: Text aus einer Schularbeit eingeben.'), const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'z.B. Minus falsch, A schreiben unsicher')), FilledButton(onPressed: () => setState(() { practice['Minus bis 20'] = (practice['Minus bis 20'] ?? 0) + 1; practice['Buchstaben'] = (practice['Buchstaben'] ?? 0) + 1; mode = LumoMode.profile; message = agent.nextSuggestion(practice); }), child: const Text('Analysieren'))]);

  Widget _profile() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Analyseprofil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text('Sicher gelöst: $solved'), Text('Mehr üben: $practice'), Text('Letzte Note: ${lastGrade == 0 ? 'noch keine' : lastGrade}'), Text(agent.nextSuggestion(practice))]);

  Widget _sidePanel() => Container(
        margin: const EdgeInsets.fromLTRB(0, 14, 14, 14),
        child: GlassPanel(
          child: Column(
            children: <Widget>[
              LumoFox(size: 190, mood: foxMood),
              Text('★ $stars', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              Text('Level $level'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 9, borderRadius: BorderRadius.circular(99)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );

  Widget _floatingLumo() => Positioned(
        right: 10,
        bottom: 10,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.76), borderRadius: BorderRadius.circular(28), boxShadow: _softShadow),
            child: LumoFox(size: 92, mood: foxMood),
          ),
        ),
      );
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
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jump = widget.mood == 'celebrate' || widget.mood == 'jump';
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, jump ? -18 * controller.value : -5 * controller.value),
          child: Transform.scale(scale: 1 + (jump ? .035 : .012) * controller.value, child: child),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.25,
        child: Image.asset(
          lumoFoxAsset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _FallbackFox(size: widget.size),
        ),
      ),
    );
  }
}

class _FallbackFox extends StatelessWidget {
  const _FallbackFox({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(bottom: size * .10, child: Container(width: size * .55, height: size * .08, decoration: BoxDecoration(color: Colors.brown.withOpacity(.16), borderRadius: BorderRadius.circular(99)))),
          Positioned(bottom: size * .18, child: Container(width: size * .42, height: size * .45, decoration: BoxDecoration(gradient: LinearGradient(colors: <Color>[Colors.orange.shade300, Colors.deepOrange]), borderRadius: BorderRadius.circular(size * .18)))),
          Positioned(top: size * .18, child: Container(width: size * .54, height: size * .46, decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(size * .20)))),
          Positioned(top: size * .07, left: size * .25, child: Transform.rotate(angle: -.35, child: Container(width: size * .15, height: size * .28, decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(99))))),
          Positioned(top: size * .07, right: size * .25, child: Transform.rotate(angle: .35, child: Container(width: size * .15, height: size * .28, decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(99))))),
          Positioned(top: size * .39, left: size * .36, child: CircleAvatar(radius: size * .035, backgroundColor: Colors.black87)),
          Positioned(top: size * .39, right: size * .36, child: CircleAvatar(radius: size * .035, backgroundColor: Colors.black87)),
          Positioned(top: size * .48, child: Container(width: size * .24, height: size * .15, decoration: BoxDecoration(color: Colors.white.withOpacity(.88), borderRadius: BorderRadius.circular(99)))),
        ],
      ),
    );
  }
}
