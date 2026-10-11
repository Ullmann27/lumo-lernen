import 'dart:convert';
import 'dart:io';

import 'package:lumo_lernen/core/lumo_voice_policy.dart';
import 'package:lumo_lernen/features/learning_modules/lumo_phrases.dart';

/// Public app content only. No child profile, database or microphone input.
void main(List<String> args) {
  if (args.length != 1) {
    throw ArgumentError('Pass the generated public inventory output path.');
  }
  final entries = <String, Map<String, String>>{};
  void add(String text, String style, String origin) {
    final key =
        text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ').trim();
    var spoken = LumoVoicePolicy.prepare(text);
    // Pronunciation-only expansions. The visible question, its answer,
    // scoring and learning history are not modified.
    if (text == 'Probier es so:') {
      spoken = 'Probiere es so.';
    } else if (text == 'Ist "Haus" ein Nomen, Verb oder Adjektiv?') {
      spoken = 'Ist das Wort Haus ein Nomen, ein Verb oder ein Adjektiv?';
    }
    entries.putIfAbsent(
        key,
        () => {
              'text': text,
              'spoken_text': spoken,
              if (text == 'Ist "Haus" ein Nomen, Verb oder Adjektiv?')
                // Model-specific spelling aid, not a displayed vocabulary
                // item or replacement of the actual German word "Verb".
                'phonetic_input': spoken.replaceAll('Verb', 'Werb'),
              'style': style,
              'origin': origin,
            });
  }

  add('Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues!',
      'greeting', 'central voice preview');
  add('Super! Das hast du toll gemacht!', 'celebrate', 'public audition');
  add('Du schaffst das! Wir probieren es gemeinsam. Zuerst schauen wir genau hin.',
      'comfort', 'public audition');
  add('Von sieben bis zehn fehlen drei. Von den fünf bleiben dann zwei übrig. Zehn plus zwei ist zwölf.',
      'explain', 'deterministically correct public explanation');
  for (var i = 0; i < 12; i++) {
    add(LumoPhrases.correct(), 'celebrate', 'existing correct phrase bag');
  }
  for (var i = 0; i < 7; i++) {
    add(LumoPhrases.wrongGentle(), 'comfort', 'existing gentle phrase bag');
  }
  for (var i = 0; i < 5; i++) {
    add(LumoPhrases.hint(), 'explain', 'existing hint phrase bag');
    add(LumoPhrases.greeting(), 'greeting', 'existing greeting phrase bag');
    add(LumoPhrases.celebrate(), 'celebrate', 'existing completion phrase bag');
    add(LumoPhrases.comfort(), 'comfort', 'existing comfort phrase bag');
  }
  for (var a = 1; a <= 5; a++) {
    for (var b = 1; b <= 10 - a; b++) {
      add('$a plus $b - wie viel ist das?', 'question',
          'existing Plus bis 10 generator');
    }
  }
  for (var a = 3; a <= 10; a++) {
    for (var b = 1; b < a; b++) {
      add('$a minus $b. Wie viele bleiben?', 'question',
          'existing Minus bis 10 generator');
    }
  }
  for (final text in [
    'Wie viele Punkte siehst du?',
    'Welche Form ist das?',
    'Wie spät ist es?',
    'Wie viel Geld siehst du?',
    '3 mal 2. Wie viel ist das?',
    'Welcher Bruch wurde gegessen?',
    'Welcher Artikel passt zu Sonne?',
    'Wie heißt die Mehrzahl von Haus?',
    'Ist "Haus" ein Nomen, Verb oder Adjektiv?',
    'In welcher Zeit steht der Satz?',
    'Schreib ein A!',
    'Welches Tier ist das?',
    'Welche Jahreszeit zeigt das Bild?',
    'Welches Wetter siehst du?',
    'Welche Farbe ist das?',
    'Welches Verkehrszeichen ist das?',
  ]) {
    add(text, 'question', 'existing module / fifty-situation speech matrix');
  }
  for (var number = 1; number <= 10; number++) {
    add('Welche Zahl kommt nach $number?', 'question',
        'existing Zahlen bis 10 generator');
  }
  for (final text in [
    'Ein Kreis ist rund. Er hat keine Ecken.',
    'Ein Dreieck hat drei Ecken.',
    'Ein Quadrat hat vier gleich lange Seiten.',
    'Der kurze Zeiger zeigt die Stunden. Der lange Zeiger zeigt die Minuten.',
    'Hier sind drei Gruppen. In jeder Gruppe liegen zwei Äpfel. Wie viele Äpfel sind es zusammen?',
    'Von acht bis zehn fehlen zwei. Wie viele bleiben von sechs übrig?',
    'Wir können zuerst bis zehn rechnen. Dann wird der zweite Schritt leichter.',
  ]) {
    add(text, 'explain', 'checked public didactic explanation');
  }
  final ordered = entries.values.toList()
    ..sort((a, b) => a['text']!.compareTo(b['text']!));
  final output = File(args.single);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(ordered)}\n');
  stdout
      .writeln('Generated ${ordered.length} public utterances, no child data.');
}
