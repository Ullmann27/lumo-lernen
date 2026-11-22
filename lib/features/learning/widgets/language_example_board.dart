import 'package:flutter/material.dart';

import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../widgets/design/lumo_task_object_art.dart';

/// Each example models the requested language operation with a separate example.
/// The scored answer stays in the owning lesson.
class LanguageExample {
  const LanguageExample(
      this.picture, this.icon, this.front, this.back, this.action,
      {this.beats = const [], this.counts = const []});

  final String? picture;
  final IconData icon;
  final String front, back, action;
  final List<String> beats;
  final List<int> counts;

  /// Each beat demonstrates a sound, transformation or turn in a separate example.
  List<String> get sequence => beats.isNotEmpty ? beats : [front, back];

  static LanguageExample? forUnit(String unit, LearningSubject subject) {
    if (subject == LearningSubject.englisch) {
      return _english[unit];
    }
    if (subject != LearningSubject.deutsch) {
      return null;
    }
    return _german[unit];
  }

  static const _sounds = LanguageExample('Maus', Icons.hearing, 'Maus',
      'M · aus', 'Sprich das Wort langsam. Höre auf den ersten Laut.',
      beats: ['Maus', 'M–aus', 'M']);
  static const _last = LanguageExample('Hund', Icons.hearing, 'Hund', 'Hun · d',
      'Sprich Hunde. Jetzt hörst du, wie das Wort am Ende geschrieben wird.',
      beats: ['Hund', 'Hun-de', 'Hund → d']);
  static const _syllables = LanguageExample('Banane', Icons.pan_tool_alt,
      'Banane', 'Ba · na · ne', 'Klatsche mit jedem Wortteil einmal.',
      beats: ['Ba', 'na', 'ne']);
  static const _sentence = LanguageExample(
      'Hase',
      Icons.view_week,
      'Der Hase   •   hüpft',
      'Der Hase hüpft.',
      'Wer tut etwas? Setze das Wort für die Handlung hinter den Namen.',
      beats: ['Der Hase', 'hüpft', 'Der Hase hüpft.']);
  static const _compound = LanguageExample(
      'Baum',
      Icons.join_inner,
      'Apfel + Baum',
      'Apfelbaum',
      'Verbinde die Wörter. Das letzte Wort sagt, worum es sich handelt.',
      beats: ['Apfel', 'Baum', 'Apfelbaum']);
  static const _article = LanguageExample('Buch', Icons.book, 'ein Buch',
      'das Buch', 'Nenne das Ding mit seinem Begleiter.',
      beats: ['Buch', 'ein Buch', 'das Buch']);
  static const _kind = LanguageExample(
      'Fuchs',
      Icons.category,
      'Fuchs · läuft · leise',
      'Tier · Tätigkeit · Eigenschaft',
      'Frage bei jedem Wort: Was ist es, was tut es oder wie ist es?',
      beats: ['Fuchs → Tier', 'läuft → Tätigkeit', 'leise → Eigenschaft']);
  static const _opposite = LanguageExample(
      'Sonne',
      Icons.compare_arrows,
      'Der Tee ist heiß.',
      'Das Eis ist kalt.',
      'Tausche die Eigenschaft gegen ihr Gegenteil.');
  static const _reading = LanguageExample(
      'Bus',
      Icons.menu_book,
      'Mia fährt mit dem Bus.',
      'Wer? Mia.  Womit? Mit dem Bus.',
      'Finde im Satz die Stelle, die zur Frage passt.',
      beats: ['Wer fährt?', 'Mia fährt.', 'Womit? Mit dem Bus.']);
  static const _writing = LanguageExample(
      'Ball',
      Icons.edit,
      'Ball',
      'B · a · l · l',
      'Schau auf den Anfang. Schreibe das Wort und prüfe jeden Buchstaben.',
      beats: ['B', 'Ba', 'Bal', 'Ball']);
  static const _upper = LanguageExample(
      'Mond',
      Icons.text_fields,
      'Der Mond scheint.',
      'Mond ist ein Namenwort.',
      'Setze einen Artikel vor das Wort. Namenwörter beginnen groß.');
  static const _verb = LanguageExample(
      'Hase',
      Icons.directions_run,
      'ich hüpfe',
      'du hüpfst · wir hüpfen',
      'Wechsle die Person und sprich das Verb dazu.',
      beats: ['ich hüpfe', 'du hüpfst', 'wir hüpfen']);
  static const _german = <String, LanguageExample>{
    'Buchstaben-Lautierung': _sounds,
    'Anfangslaute': _sounds,
    'Buchstaben': _sounds,
    'Endlaute': LanguageExample('Bus', Icons.hearing, 'Bus', 'Bu · s',
        'Sprich das Wort. Welchen Laut hörst du zuletzt?'),
    'Wortende': _last,
    'Wort-Bild-Zuordnung': LanguageExample(
        'Birne',
        Icons.image,
        'Schau auf das Bild.',
        'Birne',
        'Benenne das Bild und vergleiche den ersten Laut mit den Wörtern.'),
    'Silben': _syllables,
    'Silbenrätsel': _syllables,
    'Reime': LanguageExample('Maus', Icons.hearing, 'Maus', 'Haus',
        'Sprich beide Wörter. Ihr Ende klingt gleich.'),
    'Erste Sätze': _sentence,
    'Satz bauen': _sentence,
    'Satzbaustelle': _sentence,
    'Artikel': _article,
    'Begleiter-Rätsel': _article,
    'Wortfamilien': LanguageExample(
        'Spielzeug',
        Icons.account_tree,
        'spielen',
        'Spielplatz · Spieler · Spielzeug',
        'Suche in jedem Wort den gemeinsamen Wortstamm.'),
    'Einzahl und Mehrzahl': LanguageExample('Apfel', Icons.filter_2, '1 Apfel',
        '3 Äpfel', 'Sprich die Wörter zu einer Sache und zu mehreren Sachen.'),
    'Verkleinerungsform': LanguageExample('Haus', Icons.zoom_in, 'Haus',
        'Häuschen', 'Achte auf den Vokal und die neue Endung.'),
    'Gegenteile': _opposite,
    'Gegenteil-Geschichten': _opposite,
    'Oberbegriffe': LanguageExample(
        'Birne',
        Icons.category,
        'Birne · Apfel · Banane',
        'Obst',
        'Finde einen Namen, unter dem alle drei Dinge zusammenpassen.'),
    'Synonyme': LanguageExample(
        'Hase',
        Icons.swap_horiz,
        'Der Hase hüpft.',
        'Der Hase springt.',
        'Ersetze ein Wort. Prüfe, ob der Satz dasselbe meint.'),
    'Wortarten': _kind,
    'Wortarten-Jagd': _kind,
    'Namenwoerter': _upper,
    'Tunwoerter': _verb,
    'Wiewoerter': LanguageExample('Apfel', Icons.palette, 'Wie ist der Apfel?',
        'rund · rot · süß', 'Beschreibe eine Eigenschaft.'),
    'Zeitformen': LanguageExample(
        'Bus',
        Icons.history,
        'Heute fährt der Bus.',
        'Gestern fuhr der Bus.',
        'Ändere die Zeit. Vergleiche die Form des Verbs.',
        beats: ['heute → fährt', 'gestern → fuhr', 'Gestern fuhr der Bus.']),
    'Vorvergangenheit': LanguageExample(
        null,
        Icons.history,
        'Mia hatte schon gegessen.',
        'Danach kam Ben.',
        'Was geschah zuerst? Setze dieses Ereignis ins Plusquamperfekt.'),
    'Verbformen': _verb,
    'Steigerung': LanguageExample(
        null,
        Icons.stairs,
        'klein',
        'kleiner · am kleinsten',
        'Vergleiche zwei Dinge und dann die ganze Gruppe.'),
    'Satzglieder': LanguageExample(
        'Fuchs',
        Icons.swap_horiz,
        'Am Morgen schläft der Fuchs.',
        'Der Fuchs schläft am Morgen.',
        'Stelle Satzteile um. Welche Wörter bleiben beieinander?',
        beats: [
          'Am Morgen | schläft | der Fuchs.',
          'Der Fuchs | schläft | am Morgen.'
        ]),
    'Direkte Rede': LanguageExample(
        null,
        Icons.forum,
        'Mia fragt',
        'Mia fragt: „Wer kommt mit?“',
        'Rahme die tatsächlich gesprochenen Wörter mit Anführungszeichen ein.'),
    'Kommas in Aufzählungen': LanguageExample(
        'Birne',
        Icons.list,
        'Äpfel · Birnen · Nüsse',
        'Äpfel, Birnen und Nüsse',
        'Trenne die ersten gleichrangigen Teile mit Kommas.'),
    'Zusammensetzungen': _compound,
    'Wörter zusammensetzen': _compound,
    'St oder Sp': LanguageExample(
        'Stern',
        Icons.hearing,
        'Stern · Spatz',
        'St + ern · Sp + atz',
        'Höre auf den zweiten Laut und vergleiche die Schreibweise.'),
    'Wort-Bild schreiben': _writing,
    'Wortdetektiv': _writing,
    'Wer-Fall und Wen-Fall': LanguageExample(
        'Hund',
        Icons.person_search,
        'Der Hund sieht den Igel.',
        'Wer sieht? Der Hund.   Wen? Den Igel.',
        'Frage nach dem Handelnden und danach, wen er sieht.'),
    'Großschreibung': _upper,
    'Gross und klein': _upper,
    'ie oder i': LanguageExample(
        'Biene',
        Icons.hearing,
        'Biene · Mitte',
        'langes i · kurzes i',
        'Sprich beide Wörter, vergleiche die Vokallänge und die Schreibweise.'),
    'Die 4 Fälle': LanguageExample(
        'Hund',
        Icons.person_search,
        'Mia hilft dem Hund.',
        'Wem hilft Mia? Dem Hund.',
        'Stelle die Fallfrage und prüfe den Artikel.',
        beats: ['Mia hilft dem Hund.', 'Wem hilft Mia?', 'dem Hund → Dativ']),
    'dass oder das': LanguageExample(
        null,
        Icons.find_replace,
        'Das Bild, das du siehst, ist alt.',
        'Das Bild, welches du siehst, ist alt.',
        'Probiere dieses, jenes oder welches für das markierte Wort.',
        beats: [
          'Das Bild, das du siehst …',
          'das → welches',
          'Das Bild, welches du siehst …'
        ]),
    'Umstandswörter': LanguageExample(
        'Haus',
        Icons.place,
        'Wir spielen draußen.',
        'Wo spielen wir? Draußen.',
        'Frage nach Ort, Zeit oder Art und Weise.'),
    'Wortschatz': _reading,
    'Satz verstehen': _reading,
    'Woerter lesen': _reading,
    'Sätze lesen': _reading,
    'Lesesinn': _reading,
    'Reihenfolge': LanguageExample('Baum', Icons.timeline, 'Samen → Keimling',
        'Keimling → Baum', 'Ordne die Ereignisse zeitlich.'),
    'Bild und Wort': LanguageExample(
        'Frosch',
        Icons.image,
        'Schau auf das Bild.',
        'Frosch',
        'Sprich zuerst das Wort und lies es dann.'),
    'Haeufige Woerter': _writing,
    'Doppelmitlaut': LanguageExample('Ball', Icons.short_text, 'Ball', 'Bälle',
        'Vergleiche den kurzen Vokal mit den folgenden Mitlauten.'),
    'Dehnungen': LanguageExample(
        null,
        Icons.hearing,
        'Zahn · Zähne',
        'Das h bleibt erhalten.',
        'Vergleiche verwandte Wörter und markiere die Dehnungsstelle.'),
    'Satzzeichen': LanguageExample(
        null,
        Icons.question_mark,
        'Wo ist mein Heft',
        'Wo ist mein Heft?',
        'Sprich den Satz. Hörst du eine Frage?'),
    'Buchstaben nachspuren': _writing,
    'Wort schreiben': _writing,
    'Satz abschreiben': _sentence,
    'Schwunguebung': LanguageExample(null, Icons.gesture, '∩  ∩  ∩', '∪  ∪  ∪',
        'Fahre zuerst mit deinem Finger über die Bögen.'),
    'Zahlen schreiben': LanguageExample(null, Icons.looks_3, '3', 'Drei',
        'Fahre die Form langsam mit deinem Finger nach.'),
  };

  static const _english = <String, LanguageExample>{
    'Farben': LanguageExample('Banane', Icons.palette, 'Which colour?',
        'yellow', 'Zeige auf etwas Gelbes und sprich die Farbe.',
        beats: ['Banane', 'gelb', 'yellow']),
    'Zahlen': LanguageExample(null, Icons.filter_3, 'Zähle die Punkte.',
        '3 · three', 'Zeige auf jeden Punkt und zähle auf Englisch.',
        beats: ['one', 'two', 'three'], counts: [1, 2, 3]),
    'Tiere': LanguageExample('Hase', Icons.pets, 'Which animal?', 'rabbit',
        'Zeige auf das Tier und sprich sein englisches Wort.',
        beats: ['Hase', 'rabbit', 'a rabbit']),
    'Schulsachen': LanguageExample(
        'Buch',
        Icons.school,
        'In my school bag',
        'a book',
        'Zeige einen Gegenstand und sage, was in deiner Schultasche ist.'),
    'Begruessung': LanguageExample(null, Icons.waving_hand, 'Hello!',
        'Hi, Mia!', 'Spiele eine Begrüßung mit zwei Stimmen.',
        beats: ['Mia: Hello!', 'Ben: Hi, Mia!']),
    'Familie': LanguageExample(
        null,
        Icons.family_restroom,
        'Das ist meine Familie.',
        'This is my family.',
        'Zeige auf ein Familienbild und stelle jemanden vor.'),
    'Körper': LanguageExample(null, Icons.hearing, 'Touch your ear.', 'Ohr',
        'Zeige auf den genannten Körperteil.'),
    'Spielzeug': LanguageExample('Ball', Icons.sports_soccer, 'I play with a …',
        'ball', 'Benenne etwas, mit dem du spielen kannst.'),
    'Wetter': LanguageExample('Sonne', Icons.wb_sunny, 'The sun is shining.',
        'It is sunny.', 'Beschreibe das Wetter vor deinem Fenster.',
        beats: ['sun', 'sunny', 'It is sunny.']),
    'Essen': LanguageExample(
        'Apfel',
        Icons.restaurant,
        'Can I have an apple?',
        'Here you are.',
        'Spiele das Bestellen und Überreichen mit zwei Stimmen.',
        beats: ['Can I have an apple?', 'Here you are.', 'Thank you!']),
    'Tageszeit': LanguageExample('Mond', Icons.nightlight, 'The moon is up.',
        'Good night!', 'Wähle einen Gruß, der zur Tageszeit passt.'),
    'Verben': LanguageExample('Buch', Icons.directions_run, 'I read.',
        'Ich lese.', 'Stelle die Handlung mit deinen Händen dar.'),
    'Wochentage': LanguageExample(
        null,
        Icons.calendar_month,
        'Monday → Tuesday',
        'Tuesday → Wednesday',
        'Finde heraus, welcher Tag als Nächstes kommt.',
        beats: ['Monday', 'Tuesday', 'Wednesday']),
    'Hobbys': LanguageExample(
        'Ball',
        Icons.sports_soccer,
        'What do you like doing?',
        'I like playing football.',
        'Antworte mit einem Hobby, das zu dir passt.',
        beats: [
          'What do you like doing?',
          'playing football',
          'I like playing football.'
        ]),
    'Länder': LanguageExample(
        null,
        Icons.public,
        'Where are you from?',
        'I am from Austria.',
        'Antworte mit einem Land in einem vollständigen Satz.',
        beats: ['Where are you from?', 'Austria', 'I am from Austria.']),
    'Alltagssätze': LanguageExample(
        null,
        Icons.forum,
        'Could you help me?',
        'Of course. What do you need?',
        'Spiele beide Rollen und ändere die zweite Antwort.',
        beats: [
          'Could you help me?',
          'Of course. What do you need?',
          'I need a pencil.'
        ]),
  };
}

class LanguageExampleBoard extends StatefulWidget {
  const LanguageExampleBoard(
      {super.key,
      required this.example,
      required this.grade,
      required this.initiallyOpen,
      required this.options,
      this.reduceMotion = false,
      this.slow = false,
      required this.onExplore});

  final LanguageExample example;
  final int grade;
  final bool initiallyOpen;
  final bool reduceMotion, slow;
  final List<AnswerOption> options;
  final VoidCallback? onExplore;

  @override
  State<LanguageExampleBoard> createState() => _LanguageExampleBoardState();
}

class _LanguageExampleBoardState extends State<LanguageExampleBoard> {
  bool expanded = false;
  bool flipped = false;
  int? openPicture;

  void _explore(VoidCallback change) {
    if (widget.onExplore == null) {
      return;
    }
    setState(change);
    widget.onExplore!();
  }

  static const _colors = <String, Color>{
    'rot': Colors.red,
    'gelb': Colors.yellow,
    'blau': Colors.blue,
    'grün': Colors.green,
    'orange': Colors.orange,
    'schwarz': Colors.black,
    'weiß': Colors.white,
    'rosa': Colors.pinkAccent,
    'lila': Colors.purple,
    'braun': Colors.brown,
    'grau': Colors.grey,
  };
  static const _numbers = [
    'null',
    'eins',
    'zwei',
    'drei',
    'vier',
    'fünf',
    'sechs',
    'sieben',
    'acht',
    'neun',
    'zehn',
    'elf',
    'zwölf',
    'dreizehn',
    'vierzehn',
    'fünfzehn',
    'sechzehn',
    'siebzehn',
    'achtzehn',
    'neunzehn',
    'zwanzig'
  ];
  static const _names = {'kaninchen': 'Hase', 'äpfel': 'Apfel', 'kuh': 'Kuh'};

  Widget? _pictureFor(String word) {
    final lower = word.trim().toLowerCase();
    final object = _names[lower] ?? word;
    if (LumoTaskObjectArt.assetForName(object) != null) {
      return LumoTaskObjectArt(name: object, size: 50);
    }
    final color = _colors[lower];
    if (color != null) {
      return CircleAvatar(radius: 20, backgroundColor: color);
    }
    final number = _numbers.indexOf(lower);
    if (number < 0) {
      return null;
    }
    if (number > 10 || number == 0) {
      return Text('$number',
          style: const TextStyle(fontSize: 25, color: Colors.white));
    }
    return SizedBox(
        width: 50,
        child: Wrap(
            spacing: 2,
            runSpacing: 4,
            children: List.generate(
                number,
                (_) => const DecoratedBox(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xffffce76)),
                    child: SizedBox.square(dimension: 8)))));
  }

  Widget? _choicePictures() {
    if (widget.grade > 2 ||
        widget.options.length < 2 ||
        widget.options.length > 5) {
      return null;
    }
    final pictures =
        widget.options.map((option) => _pictureFor(option.label)).toList();
    // Give every possible answer the same treatment.
    if (pictures.any((picture) => picture == null)) {
      return null;
    }
    return Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: List.generate(pictures.length, (i) {
          final label = widget.options[i].label;
          final wordVisible = widget.grade == 2 || openPicture == i;
          return Semantics(
              button: true,
              label: 'Bildkarte ${i + 1}: $label',
              child: Material(
                  color: openPicture == i
                      ? const Color(0xff365e69)
                      : const Color(0xff244257),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                      onTap: widget.onExplore == null
                          ? null
                          : () => _explore(
                              () => openPicture = openPicture == i ? null : i),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(
                                width: 52,
                                height: 52,
                                child: Center(child: pictures[i])),
                            if (wordVisible)
                              Text(label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))
                            else
                              const Icon(Icons.touch_app_rounded,
                                  size: 15, color: Color(0xffbfe4ef)),
                          ])))));
        }));
  }

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyOpen;
  }

  @override
  void didUpdateWidget(covariant LanguageExampleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.initiallyOpen && widget.initiallyOpen) {
      expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.example;
    final early = widget.grade <= 2;
    final choices = _choicePictures();
    final walkthrough = LanguageStepSequence(
      key: ValueKey(ex),
      steps: ex.sequence,
      counts: ex.counts,
      picture: ex.picture,
      symbol: ex.icon,
      enabled: widget.onExplore != null,
      grade: widget.grade,
      reduceMotion: widget.reduceMotion,
      slow: widget.slow,
      onExplore: widget.onExplore,
    );
    if (choices != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        choices,
        walkthrough,
      ]);
    }
    final picture = ex.picture;
    final art = LumoTaskObjectArt.assetForName(picture);
    if (!expanded) {
      return Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
              onPressed: widget.onExplore == null
                  ? null
                  : () => _explore(() => expanded = true),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Beispiel erkunden'),
              style: TextButton.styleFrom(foregroundColor: Colors.white)));
    }
    final text = Text(flipped ? ex.back : ex.front,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: early ? 23 : 18,
            height: 1.18,
            fontWeight: FontWeight.w700));
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Material(
              color: early ? const Color(0xff244257) : const Color(0xff243446),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.onExplore == null
                      ? null
                      : () => _explore(() => flipped = !flipped),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DefaultTextStyle(
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.3),
                          child: Column(children: [
                            Row(children: [
                              if (early && art != null)
                                LumoTaskObjectArt(
                                    name: picture,
                                    size: widget.grade == 1 ? 70 : 50)
                              else
                                Icon(ex.icon,
                                    size: early ? 40 : 26,
                                    color: const Color(0xffffcf82)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                    Text(
                                        widget.grade == 2
                                            ? 'Beispiel · ${flipped ? 2 : 1} von 2'
                                            : 'Beispiel',
                                        style: const TextStyle(
                                            color: Color(0xffbfe4ef),
                                            fontSize: 13)),
                                    const SizedBox(height: 3),
                                    text,
                                  ])),
                              Icon(
                                  flipped
                                      ? Icons.replay_rounded
                                      : Icons.touch_app_rounded,
                                  color: const Color(0xffbfe4ef),
                                  semanticLabel: flipped
                                      ? 'Vorderseite zeigen'
                                      : 'Beispiel umdrehen'),
                            ]),
                            if (flipped) ...[
                              const SizedBox(height: 7),
                              Text(ex.action, textAlign: TextAlign.center)
                            ],
                          ]))))),
          walkthrough,
        ]));
  }
}

/// A single, replayable pass through the sounds, word forms or speaker turns.
/// Later steps stay readable until the child starts another example.
class LanguageStepSequence extends StatefulWidget {
  const LanguageStepSequence({
    super.key,
    required this.steps,
    this.picture,
    this.symbol,
    this.stepPictures = const [],
    this.counts = const [],
    this.enabled = true,
    required this.grade,
    required this.reduceMotion,
    this.slow = false,
    this.onExplore,
  });
  final List<String> steps;
  final String? picture;
  final IconData? symbol;
  final List<String> stepPictures;
  final List<int> counts;
  final bool enabled;
  final int grade;
  final bool reduceMotion, slow;
  final VoidCallback? onExplore;

  @override
  State<LanguageStepSequence> createState() => _LanguageStepSequenceState();
}

class _LanguageStepSequenceState extends State<LanguageStepSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playback;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _playback = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant LanguageStepSequence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_opened && (widget.reduceMotion || !widget.enabled)) {
      _playback.value = 1;
    }
  }

  void _play() {
    setState(() => _opened = true);
    widget.onExplore?.call();
    if (widget.reduceMotion) {
      _playback.value = 1;
      return;
    }
    // Give a sentence enough reading time while keeping individual sounds brief.
    final sentence = widget.steps.any((step) => step.length > 12);
    final ms = sentence ? 1700 : 850;
    _playback.duration = Duration(
        milliseconds:
            (widget.steps.length * ms * (widget.slow ? 1.6 : 1.0)).round());
    _playback.forward(from: 0);
  }

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final early = widget.grade < 3;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton.icon(
        key: const ValueKey('language-play-steps'),
        onPressed: !widget.enabled ? null : _play,
        icon: Icon(_opened ? Icons.replay_rounded : Icons.play_circle_outline),
        label: Text(widget.reduceMotion
            ? 'Beispielschritte zeigen'
            : _opened
                ? 'Noch einmal vormachen'
                : 'Schritt für Schritt vormachen'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xffffda92)),
      ),
      if (_opened)
        AnimatedBuilder(
          animation: _playback,
          builder: (context, _) {
            final current = (_playback.value * steps.length)
                .floor()
                .clamp(0, steps.length - 1);
            final picture = widget.stepPictures.length == steps.length
                ? widget.stepPictures[current]
                : widget.picture;
            return Wrap(
              spacing: 5,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (early && LumoTaskObjectArt.assetForName(picture) != null)
                  LumoTaskObjectArt(
                      name: picture, size: widget.grade == 1 ? 64 : 44)
                else if (early && widget.symbol != null)
                  Icon(widget.symbol, size: 35, color: const Color(0xffffd594)),
                for (var i = 0; i < steps.length; i++)
                  if (widget.reduceMotion || i <= current)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('language-beat-$i'),
                      tween: Tween(
                          begin: widget.reduceMotion ? 1.0 : 0.0, end: 1.0),
                      duration:
                          Duration(milliseconds: widget.reduceMotion ? 0 : 230),
                      curve: Curves.easeOut,
                      builder: (context, arrival, chip) => Transform.translate(
                        offset: Offset((1 - arrival) * 12, 0),
                        child: Opacity(opacity: arrival, child: chip),
                      ),
                      child: Semantics(
                        label: 'Schritt ${i + 1} von ${steps.length}',
                        child: AnimatedContainer(
                          duration: Duration(
                              milliseconds: widget.reduceMotion ? 0 : 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.reduceMotion || i == current
                                ? const Color(0xffffdda0)
                                : const Color(0xffcbe2df),
                            borderRadius: BorderRadius.circular(early ? 10 : 5),
                          ),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            if (widget.counts.length == steps.length)
                              Wrap(spacing: 3, children: [
                                for (var dot = 0; dot < widget.counts[i]; dot++)
                                  const DecoratedBox(
                                      decoration: BoxDecoration(
                                          color: Color(0xff28465e),
                                          shape: BoxShape.circle),
                                      child: SizedBox.square(dimension: 8)),
                              ]),
                            Text(
                                widget.grade == 2
                                    ? '${i + 1} · ${steps[i]}'
                                    : steps[i],
                                style: TextStyle(
                                    fontSize: early ? 20 : 16,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xff16323c))),
                          ]),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
    ]);
  }
}
