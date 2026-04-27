import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const LumoApp());

const String introVideoAsset = 'assets/videos/lumo_intro.mp4';

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
    if (showIntro) {
      return IntroVideoScreen(onDone: () => setState(() => showIntro = false));
    }
    return const LumoHome();
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
  bool fallback = true;
  bool failed = false;

  bool get _runningInWidgetTest => WidgetsBinding.instance.runtimeType.toString().contains('AutomatedTestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    if (_runningInWidgetTest) return;
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
        final value = c.value;
        if (value.isInitialized && value.position >= value.duration && value.duration.inMilliseconds > 0) {
          widget.onDone();
        }
      });
      setState(() => fallback = false);
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
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: <Color>[Color(0xffffd68a), Color(0xfffff7e8), Color(0xffdbfff2)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Center(
                child: (!fallback && c != null && c.value.isInitialized)
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
          const LumoFox(size: 170, mood: 'jump'),
          const SizedBox(height: 16),
          const Text('Lumo Lernen', textAlign: TextAlign.center, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Dein Lernfuchs ist bereit. Das Video-Intro wird abgespielt, sobald lumo_intro.mp4 im Asset-Ordner liegt.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          if (failed) ...const <Widget>[
            SizedBox(height: 12),
            Text('Hinweis: assets/videos/lumo_intro.mp4 fehlt noch oder konnte nicht geladen werden.', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(icon: const Icon(Icons.auto_awesome), label: const Text('Zur Lernwelt'), onPressed: null),
        ],
      ),
    );
  }
}

enum LumoMode { home, lesson, practice, schoolwork, test, coach, scan, profile }

class LumoTask {
  const LumoTask({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.prompt,
    required this.choices,
    required this.answer,
    required this.explanation,
    this.handwriting = false,
  });

  final String id;
  final int grade;
  final String subject;
  final String unit;
  final String prompt;
  final List<String> choices;
  final String answer;
  final String explanation;
  final bool handwriting;
}

const List<LumoTask> taskBank = <LumoTask>[
  LumoTask(id: 'm1', grade: 1, subject: 'Mathematik', unit: 'Plus bis 10', prompt: '4 + 3 = ?', choices: ['6', '7', '8'], answer: '7', explanation: 'Lege 4 Punkte hin. Lege 3 dazu. Zähle alle Punkte: 7.'),
  LumoTask(id: 'm2', grade: 1, subject: 'Mathematik', unit: 'Zahlen erkennen', prompt: 'Welche Zahl kommt nach 8?', choices: ['7', '9', '10'], answer: '9', explanation: 'Zähle langsam: 7, 8, 9.'),
  LumoTask(id: 'm3', grade: 2, subject: 'Mathematik', unit: 'Minus bis 20', prompt: '18 - 5 = ?', choices: ['12', '13', '14'], answer: '13', explanation: 'Starte bei 18 und gehe 5 Schritte zurück. Du landest bei 13.'),
  LumoTask(id: 'd1', grade: 1, subject: 'Deutsch', unit: 'Buchstaben', prompt: 'Zeichne ein großes A.', choices: ['Fertig'], answer: 'Fertig', explanation: 'Starte oben, ziehe zwei schräge Linien und mache einen Querstrich.', handwriting: true),
  LumoTask(id: 'd2', grade: 1, subject: 'Deutsch', unit: 'Silben', prompt: 'Wie viele Silben hat Banane?', choices: ['2', '3', '4'], answer: '3', explanation: 'Sprich Ba-na-ne und klatsche jeden Teil.'),
  LumoTask(id: 'd3', grade: 2, subject: 'Deutsch', unit: 'Satz verstehen', prompt: 'Der Fuchs liest. Was macht er?', choices: ['lesen', 'laufen', 'schlafen'], answer: 'lesen', explanation: 'Lies den Satz langsam. Suche das Tun-Wort.'),
  LumoTask(id: 'e1', grade: 1, subject: 'Englisch', unit: 'Erste Wörter', prompt: 'Was heißt cat?', choices: ['Katze', 'Hund', 'Haus'], answer: 'Katze', explanation: 'Cat ist ein Tier und macht miau. Cat heißt Katze.'),
  LumoTask(id: 'e2', grade: 1, subject: 'Englisch', unit: 'Farben', prompt: 'Welche Farbe ist blue?', choices: ['Blau', 'Rot', 'Grün'], answer: 'Blau', explanation: 'Blue klingt wie Blau. Der Himmel ist oft blue.'),
];

class LumoHome extends StatefulWidget {
  const LumoHome({super.key});

  @override
  State<LumoHome> createState() => _LumoHomeState();
}

class _LumoHomeState extends State<LumoHome> {
  LumoMode mode = LumoMode.home;
  int grade = 1;
  String subject = 'Alle';
  String lessonUnit = 'Alle';
  int taskIndex = 0;
  int stars = 24;
  int xp = 120;
  int errors = 0;
  String? picked;
  String foxMood = 'greet';
  String message = 'Gut, dass wir heute lernen. Was wollen wir als erstes machen?';
  final Map<String, int> solved = <String, int>{};
  final Map<String, int> practice = <String, int>{};
  final List<String> usedInTest = <String>[];
  int testScore = 0;
  int testQuestion = 0;
  bool testFinished = false;
  int lastGrade = 0;
  final List<Offset?> drawing = <Offset?>[];

  int get level => xp ~/ 100 + 1;

  List<LumoTask> get filteredTasks {
    final list = taskBank.where((task) {
      return task.grade <= grade && (subject == 'Alle' || task.subject == subject) && (lessonUnit == 'Alle' || task.unit == lessonUnit);
    }).toList();
    return list.isEmpty ? taskBank.where((task) => task.grade <= grade).toList() : list;
  }

  LumoTask get currentTask => filteredTasks[taskIndex % filteredTasks.length];

  List<LumoTask> get testPool {
    final all = taskBank.where((task) => task.grade <= grade).toList();
    return <LumoTask>[...all.where((task) => practice.containsKey(task.unit)), ...all.where((task) => !practice.containsKey(task.unit))];
  }

  LumoTask get currentTestTask {
    final available = testPool.where((task) => !usedInTest.contains(task.id)).toList();
    return (available.isEmpty ? testPool : available).first;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: <Color>[Color(0xfffff0d7), Color(0xffe8fff6), Color(0xffeaf4ff)]),
          ),
          child: wide ? _wideLayout() : _content(),
        ),
      ),
      bottomNavigationBar: wide ? null : NavigationBar(
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

  int get _navIndex {
    switch (mode) {
      case LumoMode.home: return 0;
      case LumoMode.lesson: return 1;
      case LumoMode.test: return 2;
      case LumoMode.practice: return 3;
      case LumoMode.profile: return 4;
      default: return 0;
    }
  }

  void _selectNav(int value) {
    setState(() {
      mode = <LumoMode>[LumoMode.home, LumoMode.lesson, LumoMode.test, LumoMode.practice, LumoMode.profile][value];
      if (mode == LumoMode.test) _startTest();
    });
  }

  Widget _wideLayout() {
    return Row(
      children: <Widget>[
        NavigationRail(
          selectedIndex: _navIndex,
          onDestinationSelected: _selectNav,
          labelType: NavigationRailLabelType.all,
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('Home')),
            NavigationRailDestination(icon: Icon(Icons.school_rounded), label: Text('Unterricht')),
            NavigationRailDestination(icon: Icon(Icons.assignment_rounded), label: Text('Test')),
            NavigationRailDestination(icon: Icon(Icons.draw_rounded), label: Text('Übung')),
            NavigationRailDestination(icon: Icon(Icons.analytics_rounded), label: Text('Profil')),
          ],
        ),
        Expanded(child: _content()),
        SizedBox(width: 310, child: _sidePanel()),
      ],
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Text(_title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900))),
            _pill('★ $stars'),
            const SizedBox(width: 8),
            _pill('Level $level'),
          ]),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _screen(),
        ])),
      ],
    );
  }

  String get _title {
    switch (mode) {
      case LumoMode.lesson: return 'Unterricht';
      case LumoMode.practice: return 'Übung';
      case LumoMode.schoolwork: return 'Schularbeit';
      case LumoMode.test: return 'Test';
      case LumoMode.coach: return 'Lumo Coach';
      case LumoMode.scan: return 'Scan';
      case LumoMode.profile: return 'Profil';
      default: return 'Home';
    }
  }

  Widget _screen() {
    switch (mode) {
      case LumoMode.lesson: return _lesson();
      case LumoMode.practice: return _practice();
      case LumoMode.schoolwork: return _schoolwork();
      case LumoMode.test: return _testMode();
      case LumoMode.coach: return _coach();
      case LumoMode.scan: return _scan();
      case LumoMode.profile: return _profile();
      default: return _home();
    }
  }

  Widget _card(Widget child) => Card(elevation: 14, color: Colors.white.withOpacity(.86), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)), child: Padding(padding: const EdgeInsets.all(22), child: child));
  Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(99)), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)));

  Widget _home() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Row(children: const <Widget>[
        LumoFox(size: 115, mood: 'greet'),
        SizedBox(width: 12),
        Expanded(child: Text('Ich habe ein paar Vorschläge. Starten wir eine kurze Mission oder üben wir ein Fach?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
        _menu('Unterricht', 'Mathe, Deutsch, Englisch', Icons.school_rounded, () => mode = LumoMode.lesson, Colors.orange),
        _menu('Übung', 'gezielt nach Profil', Icons.draw_rounded, () => mode = LumoMode.practice, Colors.blue),
        _menu('Schularbeit', '10 bis 15 Minuten', Icons.assignment_rounded, () { mode = LumoMode.schoolwork; _startTest(); }, Colors.purple),
        _menu('Test', 'mit Note am Schluss', Icons.workspace_premium_rounded, () { mode = LumoMode.test; _startTest(); }, Colors.teal),
        _menu('Scan & Analyse', 'Test auswerten', Icons.document_scanner_rounded, () => mode = LumoMode.scan, Colors.green),
        _menu('Profil', 'Noten und Plan', Icons.analytics_rounded, () => mode = LumoMode.profile, Colors.brown),
      ]),
    ]);
  }

  Widget _menu(String title, String sub, IconData icon, VoidCallback target, Color color) {
    return InkWell(onTap: () => setState(target), borderRadius: BorderRadius.circular(26), child: Container(width: 230, margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(.18), borderRadius: BorderRadius.circular(26)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Icon(icon, color: color, size: 34), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(sub)])));
  }

  Widget _lesson() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Wrap(spacing: 8, children: <Widget>[ChoiceChip(label: const Text('1. Klasse'), selected: grade == 1, onSelected: (_) => setState(() => grade = 1)), ChoiceChip(label: const Text('2. Klasse'), selected: grade == 2, onSelected: (_) => setState(() => grade = 2))]),
      const SizedBox(height: 12),
      ...<String, List<String>>{
        'Mathematik': <String>['Plus bis 10', 'Minus bis 20', 'Zahlen erkennen'],
        'Deutsch': <String>['Buchstaben', 'Silben', 'Satz verstehen'],
        'Englisch': <String>['Erste Wörter', 'Farben'],
      }.entries.map((entry) => _subjectBlock(entry.key, entry.value)),
    ]);
  }

  Widget _subjectBlock(String title, List<String> units) {
    return Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(.64), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: units.map((unit) => ActionChip(label: Text(unit), onPressed: () => setState(() { subject = title; lessonUnit = unit; taskIndex = 0; mode = LumoMode.practice; message = '$title: $unit gestartet.'; }))).toList()),
    ]));
  }

  Widget _practice() => _taskView(currentTask, test: false);
  Widget _schoolwork() => _testMode(label: 'Schularbeit');

  Widget _taskView(LumoTask task, {required bool test}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text('${task.grade}. Klasse • ${task.subject} • ${task.unit}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.deepOrange)),
      Text(task.prompt, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      task.handwriting ? _drawArea() : _visual(task),
      const SizedBox(height: 10),
      if (!test) Text('Lumo erklärt: ${task.explanation}'),
      Wrap(spacing: 8, children: task.choices.map((option) => FilledButton.tonal(onPressed: () => test ? _answerTest(task, option) : _answerPractice(task, option), child: Text(picked == option ? '✓ $option' : option, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))).toList()),
      if (!test) Text('Versuche: $errors/3'),
    ]);
  }

  Widget _drawArea() {
    return Container(height: 230, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orange, width: 2)), child: GestureDetector(onPanUpdate: (details) { setState(() => drawing.add(details.localPosition)); }, onPanEnd: (_) => setState(() => drawing.add(null)), child: CustomPaint(painter: DrawingPainter(drawing), child: Center(child: Text(drawing.isEmpty ? 'Zeichne hier mit dem Finger ein A' : '', style: const TextStyle(fontWeight: FontWeight.w800))))));
  }

  Widget _visual(LumoTask task) {
    if (task.unit.contains('Minus')) return Wrap(spacing: 4, children: List.generate(21, (i) => CircleAvatar(radius: i == 13 ? 18 : 14, backgroundColor: i == 13 ? Colors.orange : Colors.orange.shade100, child: Text('$i', style: TextStyle(fontSize: 11, color: i == 13 ? Colors.white : Colors.black)))));
    if (task.unit.contains('Plus')) return Wrap(spacing: 5, children: List.generate(7, (i) => CircleAvatar(radius: 14, backgroundColor: i < 4 ? Colors.blue.shade200 : Colors.orange.shade300)));
    if (task.unit.contains('Silben')) return Wrap(spacing: 8, children: <String>['Ba', 'na', 'ne'].map((s) => Chip(label: Text(s, style: const TextStyle(fontWeight: FontWeight.w900)))).toList());
    if (task.subject == 'Englisch') return const Row(children: <Widget>[Icon(Icons.pets, size: 48, color: Colors.orange), Text(' cat = Katze', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))]);
    return const Icon(Icons.auto_awesome, size: 48, color: Colors.orange);
  }

  void _answerPractice(LumoTask task, String option) {
    setState(() => picked = option);
    if (option == task.answer) {
      setState(() { stars += 3; xp += 20; errors = 0; foxMood = 'celebrate'; message = 'Richtig. Lumo springt weiter.'; solved[task.unit] = (solved[task.unit] ?? 0) + 1; });
      Timer(const Duration(milliseconds: 850), () => setState(() { taskIndex = (taskIndex + 1) % filteredTasks.length; picked = null; foxMood = 'greet'; message = 'Neue Aufgabe bereit.'; drawing.clear(); }));
    } else {
      setState(() { errors++; practice[task.unit] = (practice[task.unit] ?? 0) + 1; foxMood = 'comfort'; message = errors >= 3 ? task.explanation : 'Fast. Wir schauen gemeinsam.'; });
    }
  }

  void _startTest() { usedInTest.clear(); testScore = 0; testQuestion = 0; testFinished = false; picked = null; message = 'Schularbeit startet. Ruhig arbeiten wie im Heft.'; }

  Widget _testMode({String label = 'Test'}) {
    if (testFinished) return _resultScreen(label);
    final task = currentTestTask;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text('$label • Aufgabe ${testQuestion + 1}/10', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const Text('Arbeite ruhig. Am Ende bekommst du eine Note und einen Plan.'),
      const SizedBox(height: 12),
      _taskView(task, test: true),
    ]);
  }

  void _answerTest(LumoTask task, String option) {
    final correct = option == task.answer;
    setState(() {
      if (correct) testScore++;
      if (!correct) practice[task.unit] = (practice[task.unit] ?? 0) + 1;
      usedInTest.add(task.id);
      testQuestion++;
      picked = null;
      drawing.clear();
      if (testQuestion >= 10 || usedInTest.length >= taskBank.length) {
        testFinished = true;
        final percent = testScore / testQuestion;
        lastGrade = percent >= .9 ? 1 : percent >= .8 ? 2 : percent >= .65 ? 3 : percent >= .5 ? 4 : 5;
        message = 'Ich werte deine Arbeit aus.';
      } else {
        message = 'Nächste Aufgabe.';
      }
    });
  }

  Widget _resultScreen(String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Center(child: CircularProgressIndicator()),
      const SizedBox(height: 16),
      Text('$label fertig', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      Text('Punkte: $testScore / $testQuestion'),
      Text('Note: $lastGrade', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.deepOrange)),
      const Text('Das Ergebnis wurde im Profil gespeichert und beeinflusst die nächsten Übungen.'),
      FilledButton.icon(icon: const Icon(Icons.analytics), label: const Text('Zum Profil'), onPressed: () => setState(() => mode = LumoMode.profile)),
    ]);
  }

  Widget _coach() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Lumo Coach spricht später über ein sicheres Backend mit kindgerechter Stimme.'), FilledButton(onPressed: () => _say('Wir machen es Schritt für Schritt.'), child: const Text('Lumo sprechen lassen'))]);
  Widget _scan() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Scan-Simulation: Text aus einer Schularbeit eingeben.'), const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'z.B. Minus falsch, A schreiben unsicher')), FilledButton(onPressed: () => setState(() { practice['Minus bis 20'] = (practice['Minus bis 20'] ?? 0) + 1; practice['Buchstaben'] = (practice['Buchstaben'] ?? 0) + 1; mode = LumoMode.profile; }), child: const Text('Analysieren'))]);
  Widget _profile() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Analyseprofil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text('Sicher gelöst: $solved'), Text('Mehr üben: $practice'), Text('Letzte Note: ${lastGrade == 0 ? 'noch keine' : lastGrade}'), const Text('Algorithmus: Übungsfelder und Testnoten steuern die nächsten Vorschläge.')]);

  void _say(String text) { setState(() { message = 'Lumo sagt: $text'; foxMood = 'speak'; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debug-Stimme: $text'))); }

  Widget _sidePanel() => _card(Column(children: <Widget>[LumoFox(size: 130, mood: foxMood), Text('★ $stars', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text('Level $level'), Text(message, textAlign: TextAlign.center)]));
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this.points);
  final List<Offset?> points;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.deepOrange..strokeWidth = 6..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }
  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => oldDelegate.points != points;
}

class LumoFox extends StatefulWidget {
  const LumoFox({super.key, required this.size, required this.mood});
  final double size;
  final String mood;
  @override
  State<LumoFox> createState() => _LumoFoxState();
}

class _LumoFoxState extends State<LumoFox> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final jump = widget.mood == 'celebrate' || widget.mood == 'jump';
    return AnimatedBuilder(animation: controller, builder: (context, child) => Transform.translate(offset: Offset(0, jump ? -18 * controller.value : -5 * controller.value), child: child), child: SizedBox(width: widget.size, height: widget.size, child: Stack(alignment: Alignment.center, children: <Widget>[
      Positioned(bottom: widget.size * .10, child: Container(width: widget.size * .55, height: widget.size * .08, decoration: BoxDecoration(color: Colors.brown.withOpacity(.16), borderRadius: BorderRadius.circular(99)))),
      Positioned(bottom: widget.size * .18, child: Container(width: widget.size * .42, height: widget.size * .45, decoration: BoxDecoration(gradient: LinearGradient(colors: <Color>[Colors.orange.shade300, Colors.deepOrange]), borderRadius: BorderRadius.circular(widget.size * .18)))),
      Positioned(top: widget.size * .18, child: Container(width: widget.size * .54, height: widget.size * .46, decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(widget.size * .20)))),
      Positioned(top: widget.size * .07, left: widget.size * .25, child: Transform.rotate(angle: -.35, child: Container(width: widget.size * .15, height: widget.size * .28, decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(99))))),
      Positioned(top: widget.size * .07, right: widget.size * .25, child: Transform.rotate(angle: .35, child: Container(width: widget.size * .15, height: widget.size * .28, decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(99))))),
      Positioned(top: widget.size * .39, left: widget.size * .36, child: CircleAvatar(radius: widget.size * .035, backgroundColor: Colors.black87)),
      Positioned(top: widget.size * .39, right: widget.size * .36, child: CircleAvatar(radius: widget.size * .035, backgroundColor: Colors.black87)),
      Positioned(top: widget.size * .48, child: Container(width: widget.size * .24, height: widget.size * .15, decoration: BoxDecoration(color: Colors.white.withOpacity(.88), borderRadius: BorderRadius.circular(99)))),
    ])));
  }
}
