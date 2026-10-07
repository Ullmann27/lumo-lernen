import 'dart:math';

import 'game_level_model.dart';

class GameLessonTask {
  const GameLessonTask({required this.prompt, required this.answer,
    required this.choices, required this.explanation, this.cue = '',
    this.speech = '', this.numbers = const [], this.hour, this.minute = 0,
    this.orderWords = false, this.picture = ''});
  final String prompt, answer, explanation, cue, speech, picture;
  final List<String> choices;
  final List<int> numbers;
  final int? hour;
  final int minute;
  final bool orderWords;
}

/// Topic-specific learning tasks for the three formerly unavailable routes.
/// All answers have explanations; listening prompts use spoken whole words.
abstract final class GameLessonTasks {
  static GameLessonTask task(GameLevel level, int index) {
    final i = index % 5;
    GameLessonTask make(String prompt, String answer, List<String> choices,
        String explanation, {String cue = '', String speech = '',
        List<int> numbers = const [], int? hour, int minute = 0,
        bool orderWords = false, String picture = ''}) {
      final options = List<String>.of(choices)..shuffle(Random(level.id * 131 + index));
      return GameLessonTask(prompt: prompt, answer: answer, choices: options,
        explanation: explanation, cue: cue, speech: speech, numbers: numbers,
        hour: hour, minute: minute, orderWords: orderWords, picture: picture);
    }
    GameLessonTask number(String prompt, int answer, String explanation,
        {List<int> numbers = const []}) => make(prompt, '$answer',
      {'$answer', '${answer + 1}', '${max(0, answer - 1)}', '${answer + 3}'}.toList(),
      explanation, numbers: numbers);

    switch (level.id) {
      case 13:
        final start = index % 10;
        return number('Welche Zahl kommt als Nächstes?', start + 1,
          'Beim Zählen kommt nach $start die Zahl ${start + 1}.', numbers: [start]);
      case 14:
        final n = [3, 4, 5, 6, 8][i];
        return number('Welche Zahl fehlt in der Mitte?', n,
          'Zwischen ${n - 1} und ${n + 1} liegt $n.', numbers: [n - 1, -1, n + 1]);
      case 18:
        final a = [8, 12, 15, 7, 20][i], b = [5, 16, 15, 9, 11][i];
        final answer = a > b ? '>' : a < b ? '<' : '=';
        return make('Welches Zeichen passt zwischen $a und $b?', answer,
          ['<', '=', '>'], '$a ist ${a > b ? 'größer als' : a < b ? 'kleiner als' : 'gleich'} $b.', cue: '$a   ?   $b');
      case 36:
        final step = i.isEven ? 2 : 5;
        final start = (i + 1) * step;
        return number('Springe immer $step weiter. Welche Zahl folgt?', start + step * 3,
          'Bei jedem Sprung kommen $step dazu.', numbers: [start, start + step, start + step * 2]);
      case 21:
      case 22:
        final words = level.id == 21 ? ['Maus', 'Sonne', 'Lampe', 'Nase', 'Fisch']
            : ['Maus', 'Ball', 'Baum', 'Stern', 'Schaf'];
        final answers = level.id == 21 ? ['M', 'S', 'L', 'N', 'F'] : ['S', 'L', 'M', 'N', 'F'];
        final word = words[i], answer = answers[i];
        return make('Höre „$word“. Welchen Laut hörst du ${level.id == 21 ? 'am Anfang' : 'am Ende'}?',
          answer, [answer, ...['M', 'S', 'L', 'N', 'F'].where((x) => x != answer).take(3)],
          'Sprich $word langsam. ${level.id == 21 ? 'Der erste' : 'Der letzte'} Laut gehört zum Buchstaben $answer.',
          cue: word, speech: word);
      case 23:
        final words = ['Sonne', 'Banane', 'Elefant', 'Haus', 'Tomate'];
        final syllables = ['Son-ne', 'Ba-na-ne', 'E-le-fant', 'Haus', 'To-ma-te'];
        final counts = [2, 3, 3, 1, 3];
        return make('Klatsche „${words[i]}“. Wie viele Silben sind es?', '${counts[i]}',
          ['1', '2', '3', '4'], '${syllables[i]}: ${counts[i]} Silben. Für jede Silbe klatschst du einmal.',
          cue: words[i], speech: words[i]);
      case 24:
        final words = ['Haus', 'Maus', 'Hut', 'Nase', 'Sonne'];
        final answers = ['Maus', 'Haus', 'Mut', 'Hase', 'Tonne'];
        return make('Was reimt sich auf ${words[i]}?', answers[i],
          [answers[i], 'Baum', 'Fisch', 'Ball'], '${words[i]} und ${answers[i]} klingen am Ende gleich.',
          cue: words[i], speech: words[i]);
      case 26:
        final answers = ['Haus', 'Ball', 'Baum', 'Hut', 'Ei'];
        final pictures = ['house', 'ball', 'tree', 'hat', 'egg'];
        return make('Welches Wort gehört zum Bild?', answers[i],
          [answers[i], ...answers.where((x) => x != answers[i]).take(3)],
          'Das Bild zeigt: ${answers[i]}. Lies die Buchstaben langsam zusammen.', picture: pictures[i]);
      case 27:
        final nouns = ['Baum', 'Sonne', 'Haus', 'Katze', 'Ball'];
        final articles = ['der', 'die', 'das', 'die', 'der'];
        return make('Welcher Artikel passt? … ${nouns[i]}', articles[i],
          ['der', 'die', 'das'], 'Es heißt: ${articles[i]} ${nouns[i]}.', cue: nouns[i]);
      case 28:
        final words = ['Haus', 'Baum', 'Katze', 'Kind', 'Blume'];
        final plural = ['Häuser', 'Bäume', 'Katzen', 'Kinder', 'Blumen'];
        return make('Einzahl: ${words[i]} – Mehrzahl: …?', plural[i],
          [plural[i], '${words[i]}e', words[i], '${words[i]}s'],
          'Die Mehrzahl von ${words[i]} ist ${plural[i]}.', cue: words[i]);
      case 29:
        final roots = ['spielen', 'fahren', 'bauen', 'lesen', 'malen'];
        final related = ['Spielzeug', 'Fahrzeug', 'Bauwerk', 'Lesebuch', 'Malstift'];
        return make('Welches Wort gehört zur Familie von „${roots[i]}“?', related[i],
          [related[i], 'Sonne', 'Wolke', 'Stein'],
          '${roots[i]} und ${related[i]} haben einen gemeinsamen Wortstamm.', cue: roots[i]);
      case 38:
        final words = ['Katze', 'springen', 'fröhlich', 'Baum', 'bauen'];
        final types = ['Nomen', 'Verb', 'Adjektiv', 'Nomen', 'Verb'];
        return make('Welche Wortart ist „${words[i]}“?', types[i], ['Nomen', 'Verb', 'Adjektiv'],
          types[i] == 'Nomen' ? 'Nomen benennen Dinge oder Lebewesen. ${words[i]} ist ein Nomen.'
          : types[i] == 'Verb' ? 'Verben sagen, was jemand tut: ${words[i]}.'
          : 'Adjektive sagen, wie etwas ist: ${words[i]}.', cue: words[i]);
      case 43:
        final words = ['fröhlich', 'schnell', 'klein', 'beginnen', 'schön'];
        final synonyms = ['glücklich', 'flink', 'winzig', 'starten', 'hübsch'];
        return make('Welches Wort bedeutet ähnlich wie „${words[i]}“?', synonyms[i],
          [synonyms[i], 'traurig', 'langsam', 'dunkel'],
          '${words[i]} und ${synonyms[i]} haben eine ähnliche Bedeutung.', cue: words[i]);
      case 44:
        final now = ['Ich spiele.', 'Ich male.', 'Ich baue.', 'Ich lerne.', 'Ich lache.'];
        final past = ['Ich spielte.', 'Ich malte.', 'Ich baute.', 'Ich lernte.', 'Ich lachte.'];
        return make('Wie heißt dieser Satz in der Vergangenheit?', past[i],
          [past[i], now[i], 'Ich werde spielen.', 'Ich bin hier.'],
          '${past[i]} beschreibt etwas, das schon passiert ist.', cue: now[i]);
      case 47:
        final sentences = ['Lumo baut eine Burg.', 'Mia liest ein Buch.', 'Papa pflanzt einen Baum.',
          'Lumo findet einen Schatz.', 'Mia malt eine Sonne.'];
        final words = sentences[i].split(' ');
        return make('Baue den Satz. Beginne mit „${words.first}“.', sentences[i], words,
          'Der vollständige Satz lautet: ${sentences[i]}', orderWords: true);
      case 10:
        final a = [2, 4, 3, 5, 6][i], b = [3, 2, 4, 4, 3][i];
        return number('$a + $b = ?', a + b, '$a und $b zusammen sind ${a + b}.', numbers: [a, b]);
      case 20:
        final a = [8, 12, 15, 19, 20][i], b = [3, 4, 7, 6, 9][i];
        return number('$a − $b = ?', a - b, 'Von $a gehst du $b Schritte zurück zu ${a - b}.', numbers: [a, a - b]);
      case 30:
        final source = [23, 24, 26, 27, 28][i];
        return task(GameLevel(id: source, title: '', gradeFloor: 1,
          miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: ''), i);
      case 31:
        final price = [3, 4, 6, 7, 8][i], paid = [5, 10, 10, 10, 20][i];
        return make('Dein Buch kostet $price €. Du gibst $paid €. Wie viel bekommst du zurück?',
          '${paid - price} €', ['${paid - price} €', '$paid €', '${paid + price} €', '$price €'],
          '$paid € minus $price € sind ${paid - price} € Rückgeld.', picture: 'money', cue: '$paid € − $price €');
      case 32:
        final hour = [3, 7, 10, 4, 8][i], minute = i.isEven ? 0 : 30;
        final answer = '$hour:${minute == 0 ? '00' : '30'} Uhr';
        return make('Welche Uhrzeit zeigt die Uhr?', answer,
          [answer, '$hour:${minute == 0 ? '30' : '00'} Uhr', '${hour + 1}:00 Uhr', '12:00 Uhr'],
          minute == 0 ? 'Der lange Zeiger steht auf 12, der kurze auf $hour: $answer.'
          : 'Der lange Zeiger steht auf 6. Es ist halb ${hour + 1}, also $answer.', hour: hour, minute: minute);
      case 33:
        final animals = ['Fisch', 'Eichhörnchen', 'Frosch', 'Maulwurf', 'Delfin'];
        final homes = ['Wasser', 'Baum', 'Teich', 'Erdboden', 'Meer'];
        final options = [
          ['Wasser', 'Baumkrone', 'Dach', 'trockene Wiese'],
          ['Baum', 'Meer', 'Teich', 'unterirdischer Gang'],
          ['Teich', 'Baumkrone', 'Dach', 'trockener Sand'],
          ['Erdboden', 'Baumkrone', 'Meer', 'Dach'],
          ['Meer', 'Baumkrone', 'Wüste', 'Dach'],
        ];
        final prompt = i == 1 ? 'Wo baut ein Eichhörnchen gewöhnlich sein Nest?'
          : i == 2 ? 'Wo findest du gewöhnlich Froschlaich?'
          : 'Wo lebt ein ${animals[i]}?';
        final explanations = ['Fische leben im Wasser.',
          'Eichhörnchen bauen ihre Nester gewöhnlich in Bäumen.',
          'Froschlaich sind die Eier eines Frosches. Sie liegen gewöhnlich im Wasser eines Teiches.',
          'Maulwürfe graben ihre Gänge im Erdboden.', 'Dieser Delfin schwimmt im Meer.'];
        return make(prompt, homes[i], options[i], explanations[i],
          cue: animals[i], picture: 'animal');
      case 34:
        final prompts = ['Am Himmel fallen Tropfen.', 'Die Sonne scheint ohne Wolken.',
          'Weiße Flocken fallen vom Himmel.', 'Blitz und Donner sind zu hören.', 'Viele Wolken verdecken die Sonne.'];
        final weather = ['Regen', 'Sonnenschein', 'Schnee', 'Gewitter', 'bewölkt'];
        final pictures = ['rain', 'sun', 'snow', 'storm', 'cloud'];
        return make(prompts[i], weather[i],
          [weather[i], ...weather.where((x) => x != weather[i]).take(3)],
          'Dieses Wetter heißt ${weather[i]}.', picture: pictures[i]);
      case 35:
        final prompts = ['Welcher Pflanzenteil nimmt Wasser aus dem Boden auf?',
          'Welcher Teil trägt Blätter und Blüten?', 'Wo bildet die Pflanze mit Sonnenlicht Nahrung?',
          'Welcher Teil lockt oft Insekten an?', 'Woraus kann eine neue Pflanze wachsen?'];
        final parts = ['Wurzel', 'Stängel', 'Blatt', 'Blüte', 'Samen'];
        return make(prompts[i], parts[i],
          [parts[i], ...parts.where((x) => x != parts[i]).take(3)],
          ['Wurzeln nehmen Wasser und Mineralstoffe auf.', 'Der Stängel trägt die Pflanzenteile.',
          'Grüne Blätter bilden mit Licht Nahrung.', 'Blüten können Insekten zur Bestäubung anlocken.',
          'Ein Samen kann keimen und zu einer neuen Pflanze wachsen.'][i], picture: 'plant');
      case 40:
        if (i == 0) return number('2, 4, 6, 8 – welche Zahl folgt?', 10, 'Die Regel lautet: immer 2 dazu.', numbers: [2, 4, 6, 8]);
        if (i == 1) return number('Drei Kinder brauchen je zwei Stifte. Wie viele Stifte sind es?', 6, '2 + 2 + 2 = 6.');
        if (i == 2) return make('Was gehört nicht dazu?', 'Stein', ['Katze', 'Hund', 'Fuchs', 'Stein'], 'Ein Stein ist kein Tier.');
        if (i == 3) return make('Rot, Blau, Rot, Blau – welche Farbe folgt?', 'Rot', ['Rot', 'Blau', 'Grün', 'Gelb'], 'Rot und Blau wechseln sich ab.');
        return number('Eine Woche hat 7 Tage. Wie viele Tage haben zwei Wochen?', 14, '7 + 7 = 14.');
      case 50:
        if (i == 0) return number('23 + 18 = ?', 41, '23 + 10 = 33, dann + 8 = 41.');
        if (i == 1) return number('7 × 4 = ?', 28, '7 + 7 + 7 + 7 = 28.');
        if (i == 2) return task(const GameLevel(id: 43, title: '', gradeFloor: 3,
          miniType: GameMiniType.wordForest, subject: 'Deutsch', learningGoal: ''), 2);
        if (i == 3) return task(const GameLevel(id: 35, title: '', gradeFloor: 2,
          miniType: GameMiniType.mixedQuiz, subject: 'Sachunterricht', learningGoal: ''), 3);
        return number('54 − 27 = ?', 27, '54 − 20 = 34, dann − 7 = 27.');
      default:
        throw ArgumentError('No lesson trail for level ${level.id}');
    }
  }
}
