import 'package:flutter/material.dart';

import '../../../core/curriculum/primary_activity_catalog.dart';
import '../../../widgets/design/lumo_task_object_art.dart';

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
        'Begründe deine Meinung. Überlege, wer die Pflanzen in den Ferien pflegen würde.'
      ]
    ),
    'g4_en_message': (
      [],
      [
        'You are inviting your friend to a picnic.',
        'Include the day and the place. Ask your friend to bring one thing.'
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

  static bool supports(String id) => _material.containsKey(id);

  @override
  Widget build(BuildContext context) {
    final (pictures, lines) = _material[activity.id]!;
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
    ]);
  }
}
