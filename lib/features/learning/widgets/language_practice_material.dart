import 'package:flutter/material.dart';

import '../../../core/curriculum/primary_activity_catalog.dart';
import '../../../widgets/design/lumo_task_object_art.dart';
import '../../../widgets/design/lumo_motion.dart';
import 'language_example_board.dart';

/// Ready-to-use local material for listening, speaking and open-ended writing.
class LanguagePracticeMaterial extends StatelessWidget {
  const LanguagePracticeMaterial(this.activity, {super.key});

  final CurriculumActivity activity;

  static const _material = <String, (List<String>, List<String>)>{
    'g1_de_listen': (
      ['Hase', 'Ball', 'Bus'],
      [
        'Zum Vorlesen: Ein Hase findet einen Ball. Er rollt ihn zur Haltestelle. Ein Bus hält an.',
        'Zeige beim Nacherzählen auf die drei Bilder.',
      ]
    ),
    'g1_en_listen': (
      ['Katze', 'Buch', 'Apfel', 'Hund', 'Ball'],
      [
        'Zum Vorlesen in beliebiger Reihenfolge: cat · book · apple · dog · ball.',
      ]
    ),
    'g1_en_speak': (['Fuchs'], ['Hello!', 'I am …', 'Goodbye!']),
    'g2_de_retell': (
      ['Maus', 'Birne', 'Haus'],
      [
        '1. Eine Maus findet eine Birne.',
        '2. Sie rollt die Birne nach Hause.',
        '3. Sie teilt die Birne mit ihrer Schwester.',
      ]
    ),
    'g2_en_commands': (
      [],
      [
        '1. Stand up.',
        '2. Clap twice.',
        '3. Point to your nose.',
        '4. Sit down.'
      ]
    ),
    'g2_en_dialogue': (
      [],
      ['1. Hello!', '2. How are you? — I am fine, thank you.', '3. Goodbye!']
    ),
    'g3_de_explain': (
      [],
      [
        'Dein Versuch: Wie faltest du ein Blatt zu einer Karte?',
        'Gib einem Partner nur deine Anleitung. Vergleiche am Ende beide Karten.'
      ]
    ),
    'g3_en_info': (
      [],
      [
        'My name is Emma. I have a red bike and two cats.',
        'Find the name, the colour and the number.'
      ]
    ),
    'g3_en_talk': (
      [],
      [
        'My favourite animal is …',
        'It lives …',
        'It can …',
        'I like it because …'
      ]
    ),
    'g4_de_discuss': (
      [],
      [
        'Soll die Schule einen eigenen Garten bekommen?',
        'Nenne zwei Gründe für deine Meinung. Welchen Einwand könnte ein anderes Kind haben?'
      ]
    ),
    'g4_en_message': (
      [],
      [
        'Write a short note to your new pen pal.',
        'Say hello, share two things about yourself, then say goodbye.'
      ]
    ),
    'g4_en_roleplay': (
      [],
      [
        'At the market: apples €1, bread €2, cheese €3.',
        'One person sells the food. The other has €4. Change roles after the first purchase.'
      ]
    ),
  };

  // A short model for each oral or written assignment in the primary catalog.
  static const _examples = <String, (List<String>, List<String>)>{
    'g1_de_listen': (
      ['Hase', 'rollt den Ball', 'zum Bus'],
      ['Hase', 'Ball', 'Bus']
    ),
    'g1_en_listen': (['cat', 'book', 'ball'], ['Katze', 'Buch', 'Ball']),
    'g1_en_speak': (['Hello!', 'I am Mia.', 'Goodbye!'], []),
    'g2_de_retell': (
      ['Zuerst: eine Maus', 'Dann: die Birne', 'Am Ende: zu Hause'],
      ['Maus', 'Birne', 'Haus']
    ),
    'g2_en_commands': (['Stand up.', 'Clap twice.', 'Sit down.'], []),
    'g2_en_dialogue': (['Hello!', 'How are you?', 'I am fine.'], []),
    'g3_de_explain': (
      [
        'Lege das Blatt quer.',
        'Falte die linke Kante zur rechten.',
        'Streiche den Falz glatt.'
      ],
      []
    ),
    'g3_en_info': (
      [
        'Ben has three green pens.',
        'Who? Ben.',
        'How many? Three.',
        'Which colour? Green.'
      ],
      []
    ),
    'g3_en_talk': (
      [
        'My favourite animal is a fox.',
        'It lives in the forest.',
        'It can run fast.'
      ],
      []
    ),
    'g4_de_discuss': (
      [
        'Ich bin für einen Schulgarten.',
        'Wir könnten Gemüse ernten und Insekten beobachten.',
        'Ein Einwand: In den Ferien muss jemand gießen.'
      ],
      []
    ),
    'g4_en_message': (
      ['Dear Sam,', 'I live in Vienna. I love swimming.', 'Best wishes, Mia'],
      []
    ),
    'g4_en_roleplay': (
      ['Can I have two apples?', 'That is two euros.', 'Here you are.'],
      []
    ),
  };

  static bool supports(String id) => _material.containsKey(id);

  @override
  Widget build(BuildContext context) {
    final (pictures, lines) = _material[activity.id]!;
    final (steps, stepPictures) = _examples[activity.id]!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (pictures.isNotEmpty)
        Wrap(spacing: 8, runSpacing: 5, children: [
          for (final name in pictures)
            LumoTaskObjectArt(name: name, size: activity.grade == 1 ? 52 : 42),
        ]),
      for (final line in lines)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(line,
                style: TextStyle(
                    fontSize: activity.grade <= 2 ? 16 : 15,
                    height: 1.4,
                    color: Colors.white))),
      LanguageStepSequence(
        steps: steps,
        stepPictures: stepPictures,
        symbol: activity.id.endsWith('commands')
            ? Icons.accessibility_new
            : Icons.record_voice_over,
        picture: pictures.isEmpty ? null : pictures.first,
        grade: activity.grade,
        reduceMotion: LumoMotion.reduced(context),
      ),
    ]);
  }
}
