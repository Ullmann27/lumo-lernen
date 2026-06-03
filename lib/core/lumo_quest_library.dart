// ════════════════════════════════════════════════════════════════════════
// LUMO QUEST LIBRARY — vorgefertigte narrative Lern-Abenteuer.
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-06-03: "echtes neues Level gegenueber LernMax". LernMax bietet
// nur trockenen Drill (Aufgabe-fuer-Aufgabe-Listen). Lumo Quest verpackt
// Lehrplan-Aufgaben in fortlaufende Mini-Abenteuer mit Lumo als Held.
//
// Vier handgemachte Quests (eine pro Klassenstufe), alle aufgebaut auf das
// existierende LumoStory-Modell (lumo_story_generator.dart) -> abspielbar
// im bestehenden LumoStoryReaderScreen ohne Code-Doppelung.
//
// Jede Quest hat 5-7 Pages, 3-4 davon mit StoryExercise eingebettet,
// klassengerecht nach AT-Lehrplan VS.

import 'lumo_story_generator.dart';

class LumoQuest {
  const LumoQuest({
    required this.id,
    required this.title,
    required this.summary,
    required this.emoji,
    required this.story,
  });

  final String id;
  final String title;
  final String summary;
  final String emoji;
  final LumoStory story;

  int get gradeLevel => story.gradeLevel;
}

class LumoQuestLibrary {
  const LumoQuestLibrary._();

  /// Alle vorgefertigten Quests, sortiert nach Klassenstufe.
  static List<LumoQuest> all() => <LumoQuest>[
        _grade1Apfelgarten(),
        _grade2Baeckerei(),
        _grade3Schatzhoehle(),
        _grade4Sternenflug(),
      ];

  /// Filter fuer den Hub: zeige nur Quests passend zur Klasse + die der
  /// vorigen Klasse (Wiederholung) + naechsten (Vorausschau).
  static List<LumoQuest> forGrade(int grade) {
    final all = LumoQuestLibrary.all();
    return all.where((q) => (q.gradeLevel - grade).abs() <= 1).toList();
  }

  // ────────────────────────────────────────────────────────────────────
  // KLASSE 1: Lumo und der Apfelgarten (Plus bis 10, Mengenvergleich)
  // ────────────────────────────────────────────────────────────────────
  static LumoQuest _grade1Apfelgarten() => LumoQuest(
        id: 'q1_apfelgarten',
        title: 'Lumo und der Apfelgarten',
        summary: 'Hilf Lumo, die Apfelernte zu zaehlen!',
        emoji: '🍎',
        story: LumoStory(
          title: 'Lumo und der Apfelgarten',
          heroName: 'Lumo',
          location: 'Apfelgarten',
          theme: 'Ernte',
          gradeLevel: 1,
          keyPoints: const ['Plus bis 10', 'Mengen zaehlen'],
          newWords: const ['Apfel', 'Korb', 'Baum'],
          pages: const <LumoStoryPage>[
            LumoStoryPage(
              pageNum: 1,
              text: 'Lumo steht im grossen Apfelgarten. Die Aeste haengen voller roter Aepfel. "So viele!", staunt Lumo. "Heute brauche ich Hilfe beim Zaehlen."',
              imagePrompt: 'Fuchs Lumo in einem sonnigen Apfelgarten, viele rote Aepfel an den Baeumen',
              newWord: 'Apfel',
            ),
            LumoStoryPage(
              pageNum: 2,
              text: 'Im ersten Korb liegen 3 Aepfel. Lumo legt 4 weitere dazu. Wie viele Aepfel sind jetzt im Korb?',
              imagePrompt: 'Holzkorb mit roten Aepfeln, daneben Fuchs Lumo',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '3 Aepfel + 4 Aepfel = ?',
                correctAnswer: '7',
                options: <String>['6', '7', '8'],
              ),
            ),
            LumoStoryPage(
              pageNum: 3,
              text: 'Super! 7 Aepfel sind im ersten Korb. Lumo trifft jetzt Hasi den Hasen. Hasi hat 2 Aepfel. Lumo gibt ihm 5 dazu. Wie viele hat Hasi nun?',
              imagePrompt: 'Hase Hasi mit Aepfeln, Fuchs Lumo gibt mehr Aepfel',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '2 + 5 = ?',
                correctAnswer: '7',
                options: <String>['6', '7', '8'],
              ),
            ),
            LumoStoryPage(
              pageNum: 4,
              text: 'Hasi und Lumo schauen auf zwei Baeume. Am linken Baum haengen 8 Aepfel, am rechten 5. Wo sind MEHR Aepfel?',
              imagePrompt: 'Zwei Apfelbaeume, links viele Aepfel, rechts weniger',
              exercise: StoryExercise(
                type: StoryExerciseType.wordChoice,
                prompt: '8 Aepfel oder 5 Aepfel - wo sind mehr?',
                correctAnswer: 'links',
                options: <String>['links', 'rechts', 'gleich viel'],
              ),
            ),
            LumoStoryPage(
              pageNum: 5,
              text: 'Toll! Die Ernte ist geschafft. Lumo und Hasi setzen sich in den Schatten und essen jeder einen Apfel. "Zaehlen macht Spass!", sagt Lumo.',
              imagePrompt: 'Fuchs und Hase essen Aepfel im Schatten unter einem Baum',
            ),
          ],
        ),
      );

  // ────────────────────────────────────────────────────────────────────
  // KLASSE 2: Lumo in der Baeckerei (Plus/Minus bis 20, Geld bis 20€)
  // ────────────────────────────────────────────────────────────────────
  static LumoQuest _grade2Baeckerei() => LumoQuest(
        id: 'q2_baeckerei',
        title: 'Lumo in der Baeckerei',
        summary: 'Backen und rechnen mit Lumo!',
        emoji: '🥨',
        story: LumoStory(
          title: 'Lumo in der Baeckerei',
          heroName: 'Lumo',
          location: 'Baeckerei',
          theme: 'Backen',
          gradeLevel: 2,
          keyPoints: const ['Plus/Minus bis 20', 'Geld bis 20 Euro'],
          newWords: const ['Semmel', 'Wechselgeld', 'Brezel'],
          pages: const <LumoStoryPage>[
            LumoStoryPage(
              pageNum: 1,
              text: 'Lumo arbeitet heute in Baecker Brunos Baeckerei. Bruno backt 12 frische Semmeln und 8 Brezeln. Wie viele Backwaren sind das insgesamt?',
              imagePrompt: 'Baeckerei mit Semmeln und Brezeln auf einem Holztisch, Fuchs Lumo mit Schuerze',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '12 + 8 = ?',
                correctAnswer: '20',
                options: <String>['18', '20', '22'],
              ),
            ),
            LumoStoryPage(
              pageNum: 2,
              text: 'Frau Maier kommt herein und kauft 7 Semmeln. Wie viele Semmeln bleiben noch in der Auslage?',
              imagePrompt: 'Frau am Tresen kauft Semmeln, Lumo gibt sie ihr',
              exercise: StoryExercise(
                type: StoryExerciseType.mathMinus,
                prompt: '12 Semmeln - 7 verkauft = ?',
                correctAnswer: '5',
                options: <String>['4', '5', '6'],
              ),
            ),
            LumoStoryPage(
              pageNum: 3,
              text: 'Jede Semmel kostet 1 Euro. Frau Maier zahlt mit einem 10-Euro-Schein. Wie viel Wechselgeld bekommt sie zurueck?',
              imagePrompt: 'Geldschein und Muenzen auf einem Holztresen',
              newWord: 'Wechselgeld',
              exercise: StoryExercise(
                type: StoryExerciseType.mathMinus,
                prompt: '10 Euro - 7 Euro = ?',
                correctAnswer: '3',
                options: <String>['2', '3', '4'],
              ),
            ),
            LumoStoryPage(
              pageNum: 4,
              text: 'Am Nachmittag backt Bruno 6 neue Brezeln und 4 Krapfen. Wie viele neue Stuecke sind das?',
              imagePrompt: 'Baeckerei mit frischen Brezeln und Krapfen',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '6 + 4 = ?',
                correctAnswer: '10',
                options: <String>['8', '10', '12'],
              ),
            ),
            LumoStoryPage(
              pageNum: 5,
              text: 'Was fuer ein Tag! Lumo ist stolz. "Rechnen hilft uns, dass Bruno die richtige Menge backt und die Kunden zufrieden sind."',
              imagePrompt: 'Fuchs Lumo zufrieden in der Baeckerei am Abend',
            ),
          ],
        ),
      );

  // ────────────────────────────────────────────────────────────────────
  // KLASSE 3: Lumo's Schatzhoehle (Einmaleins, Division einstellig)
  // ────────────────────────────────────────────────────────────────────
  static LumoQuest _grade3Schatzhoehle() => LumoQuest(
        id: 'q3_schatzhoehle',
        title: 'Lumo und die Schatzhoehle',
        summary: 'Edelsteine zaehlen und teilen!',
        emoji: '💎',
        story: LumoStory(
          title: 'Lumo und die Schatzhoehle',
          heroName: 'Lumo',
          location: 'Schatzhoehle',
          theme: 'Abenteuer',
          gradeLevel: 3,
          keyPoints: const ['Einmaleins', 'Division einstellig', 'Sachrechnen'],
          newWords: const ['Edelstein', 'Truhe', 'Schatz'],
          pages: const <LumoStoryPage>[
            LumoStoryPage(
              pageNum: 1,
              text: 'Lumo findet im Wald eine geheime Hoehle. Drinnen funkelt eine alte Truhe. Lumo oeffnet sie - und sieht Edelsteine. In 4 Reihen liegen je 6 blaue Steine. Wie viele Steine sind das?',
              imagePrompt: 'Fuchs Lumo in einer Schatzhoehle mit funkelnden Edelsteinen in einer Truhe',
              newWord: 'Edelstein',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '4 Reihen mit je 6 Steinen = ?',
                correctAnswer: '24',
                options: <String>['18', '24', '30'],
              ),
            ),
            LumoStoryPage(
              pageNum: 2,
              text: 'Lumo will die 24 Steine fair auf 4 Beutel verteilen. Wie viele Steine kommen in jeden Beutel?',
              imagePrompt: 'Vier kleine Stoffbeutel, Lumo zaehlt Edelsteine',
              exercise: StoryExercise(
                type: StoryExerciseType.mathMinus,
                prompt: '24 : 4 = ?',
                correctAnswer: '6',
                options: <String>['5', '6', '8'],
              ),
            ),
            LumoStoryPage(
              pageNum: 3,
              text: 'In einer kleineren Schachtel findet Lumo 8 rote Edelsteine. Sie sind 5-mal so wertvoll wie die blauen. Was waere ihr Wert in blauen Steinen?',
              imagePrompt: 'Kleine Schachtel mit roten Edelsteinen',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '8 mal 5 = ?',
                correctAnswer: '40',
                options: <String>['35', '40', '45'],
              ),
            ),
            LumoStoryPage(
              pageNum: 4,
              text: 'Lumo will von den 24 blauen Steinen die Haelfte zurueck in die Hoehle legen, damit andere Tiere auch noch etwas finden. Wie viele Steine bleiben fuer Lumo?',
              imagePrompt: 'Lumo legt Edelsteine zurueck in die Hoehle',
              exercise: StoryExercise(
                type: StoryExerciseType.mathMinus,
                prompt: 'Haelfte von 24 = ?',
                correctAnswer: '12',
                options: <String>['10', '12', '14'],
              ),
            ),
            LumoStoryPage(
              pageNum: 5,
              text: 'Mit 12 blauen Steinen geht Lumo nach Hause. "Teilen ist auch eine Form von Reichtum", sagt Lumo zufrieden und schliesst die Truhe.',
              imagePrompt: 'Lumo verlaesst die Hoehle mit einem kleinen Beutel Edelsteine',
            ),
          ],
        ),
      );

  // ────────────────────────────────────────────────────────────────────
  // KLASSE 4: Lumo's Sternenflug (Dezimal, ZR 1 Mio, Sachaufgaben 3-Schritt)
  // ────────────────────────────────────────────────────────────────────
  static LumoQuest _grade4Sternenflug() => LumoQuest(
        id: 'q4_sternenflug',
        title: 'Lumo und der Sternenflug',
        summary: 'Mit der Rakete durchs Weltall rechnen!',
        emoji: '🚀',
        story: LumoStory(
          title: 'Lumo und der Sternenflug',
          heroName: 'Lumo',
          location: 'Weltall',
          theme: 'Raumfahrt',
          gradeLevel: 4,
          keyPoints: const ['Dezimalzahlen', 'Zahlenraum bis 1 Million', 'Mehrstufige Sachaufgaben'],
          newWords: const ['Treibstoff', 'Planet', 'Lichtjahr'],
          pages: const <LumoStoryPage>[
            LumoStoryPage(
              pageNum: 1,
              text: 'Lumo sitzt in der Rakete "Sternblitz". Der Tank fasst 250 Liter Treibstoff. Bisher sind 175 Liter eingefuellt. Wie viele Liter fehlen noch?',
              imagePrompt: 'Fuchs Lumo im Astronautenanzug in einer Rakete am Cockpit',
              newWord: 'Treibstoff',
              exercise: StoryExercise(
                type: StoryExerciseType.mathMinus,
                prompt: '250 Liter - 175 Liter = ?',
                correctAnswer: '75',
                options: <String>['65', '75', '85'],
              ),
            ),
            LumoStoryPage(
              pageNum: 2,
              text: 'Die Rakete fliegt mit 1.250 Kilometern pro Minute. In 4 Minuten - wie weit kommt Lumo?',
              imagePrompt: 'Rakete fliegt durchs Weltall, Sterne und Planeten',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '1.250 mal 4 = ?',
                correctAnswer: '5000',
                options: <String>['4500', '5000', '5500'],
              ),
            ),
            LumoStoryPage(
              pageNum: 3,
              text: 'Lumos Bordcomputer zeigt: Planet Zorglax ist 7,8 Lichtjahre entfernt, Planet Bingo nur 5,4 Lichtjahre. Wie viele Lichtjahre weiter ist Zorglax?',
              imagePrompt: 'Holografischer Bordcomputer im Cockpit mit Planeten-Diagramm',
              newWord: 'Lichtjahr',
              exercise: StoryExercise(
                type: StoryExerciseType.wordChoice,
                prompt: '7,8 - 5,4 = ?',
                correctAnswer: '2,4',
                options: <String>['2,2', '2,4', '3,4'],
              ),
            ),
            LumoStoryPage(
              pageNum: 4,
              text: 'Auf Bingo gibt es 6 Krater. Drei davon sind je 12.000 Meter tief, die anderen drei je 9.500 Meter. Wie tief sind alle Krater zusammen?',
              imagePrompt: 'Planet Bingo mit Kratern, Lumos Rakete landet',
              exercise: StoryExercise(
                type: StoryExerciseType.mathPlus,
                prompt: '3 mal 12.000 + 3 mal 9.500 = ?',
                correctAnswer: '64500',
                options: <String>['60500', '64500', '70500'],
              ),
            ),
            LumoStoryPage(
              pageNum: 5,
              text: 'Lumo macht ein Foto vom Sternenhimmel und kehrt zur Erde zurueck. "Mathe macht Raumfahrt erst moeglich", denkt Lumo. Was fuer ein Tag im All!',
              imagePrompt: 'Rakete landet sanft auf der Erde, Lumo steigt zufrieden aus',
            ),
          ],
        ),
      );
}
