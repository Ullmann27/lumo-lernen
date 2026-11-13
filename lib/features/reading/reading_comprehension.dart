import 'reading_text_library.dart';

/// Reviewed questions about the selected text. Speech-recognition matches are
/// never an assessment: only the child's explicit answer may enter learning.
class ReadingComprehension {
  const ReadingComprehension(
      this.question, this.answers, this.correctIndex, this.evidenceLine);

  final String question;
  final List<String> answers;
  final int correctIndex;
  final String evidenceLine;

  static ReadingComprehension? forText(ReadingText text) {
    final question = _questions[text.id];
    // A later text edit cannot silently leave a question about an older story.
    return question != null && text.lines.contains(question.evidenceLine)
        ? question
        : null;
  }

  static const _questions = <String, ReadingComprehension>{
    'g1_mama_und_tom': ReadingComprehension(
        'Was backt Mama?',
        ['Einen Kuchen', 'Eine Pizza', 'Ein Brot'],
        0,
        'Mama backt einen Kuchen.'),
    'g1_der_garten': ReadingComprehension(
        'Wer summt um die Rose?',
        ['Eine Katze', 'Eine Biene', 'Ein Hund'],
        1,
        'Eine Biene summt um die Rose.'),
    'g1_lumo_fox': ReadingComprehension('Wo lebt Lumo?',
        ['Am Meer', 'Im Schloss', 'Im Wald'], 2, 'Er lebt im Wald.'),
    'g1_kater': ReadingComprehension(
        'Wo schläft Felix gerne?',
        ['Auf dem Sofa', 'Im Boot', 'Auf der Schaukel'],
        0,
        'Er schläft gerne auf dem Sofa.'),
    'g1_ball': ReadingComprehension(
        'Wohin rollt der Ball?',
        ['In den Wald', 'In die Pfütze', 'In das Haus'],
        1,
        'Der Ball rollt in die Pfütze.'),
    'g1_regen': ReadingComprehension('Welche Farbe haben Idas Stiefel?',
        ['Blau', 'Rot', 'Gelb'], 2, 'Ihre Stiefel sind gelb.'),
    'g2_winter': ReadingComprehension(
        'Was bekommt der Schneemann als Nase?',
        ['Eine Karotte', 'Eine Kastanie', 'Eine Kerze'],
        0,
        'Sie geben ihm eine Karotte als Nase.'),
    'g2_baeckerei': ReadingComprehension(
        'Was backt die Bäckerin?',
        ['Nur Torten', 'Brot, Semmeln und Kipferl', 'Nur Kekse'],
        1,
        'Sie backt Brot, Semmeln und Kipferl.'),
    'g2_zoo': ReadingComprehension(
        'Welche Tiere watscheln über das Eis?',
        ['Die Zebras', 'Die Affen', 'Die Pinguine'],
        2,
        'Die Pinguine watscheln über das Eis.'),
    'g2_geburtstag': ReadingComprehension(
        'Wann kommen Lenas Freunde?',
        ['Am Nachmittag', 'Am Morgen', 'In der Nacht'],
        0,
        'Ihre Freunde kommen am Nachmittag.'),
    'g2_herbst': ReadingComprehension(
        'Was sammelt Jonas?',
        ['Münzen', 'Kastanien', 'Muscheln'],
        1,
        'Jonas sammelt Kastanien in seiner Tasche.'),
    'g2_schulweg': ReadingComprehension(
        'Wer hilft den Kindern über die Straße?',
        ['Der Bäcker', 'Der Busfahrer', 'Der Schülerlotse'],
        2,
        'Der Schülerlotse hilft uns über die Straße.'),
    'g3_schwimmbad': ReadingComprehension(
        'Wer ist beim Schwimmen neben Marie?',
        ['Ihr Papa', 'Ihre Lehrerin', 'Ihr Bruder'],
        0,
        'Sie hat etwas Angst, aber Papa ist gleich neben ihr.'),
    'g3_wanderung': ReadingComprehension(
        'Was macht die Familie auf der Hütte?',
        [
          'Sie fährt Fahrrad.',
          'Sie isst eine Jause und trinkt Saft.',
          'Sie baut einen Schneemann.'
        ],
        1,
        'Auf der Hütte essen sie eine Jause und trinken Saft.'),
    'g3_bienen': ReadingComprehension(
        'Was sammeln die Bienen an den Blüten?',
        ['Blätter', 'Steine', 'Nektar'],
        2,
        'Sie fliegen von Blüte zu Blüte und sammeln Nektar.'),
    'g3_bibliothek': ReadingComprehension(
        'Worüber möchte Tim ein Buch lesen?',
        ['Über Dinosaurier', 'Über Autos', 'Über Zaubertricks'],
        0,
        'Tim sucht ein Buch über Dinosaurier.'),
    'g3_igel': ReadingComprehension(
        'Woraus baut der Igel sein Nest?',
        ['Aus Sand', 'Aus Laub', 'Aus Schnee'],
        1,
        'Wenn es kalt wird, baut er sich ein Nest aus Laub.'),
    'g3_flohmarkt': ReadingComprehension(
        'Was kauft Sara mit dem Geld?',
        ['Ein neues Puzzle', 'Eine Puppe', 'Ein gebrauchtes Fahrrad'],
        2,
        'Für das Geld kauft sie sich ein gebrauchtes Fahrrad.'),
    'g4_lumo_und_alina': ReadingComprehension(
        'Warum nennt Alina den Fuchs Lumo?',
        [
          'Weil seine Augen golden leuchten.',
          'Weil er gerne schläft.',
          'Weil er im Meer schwimmt.'
        ],
        0,
        'Sie nennt ihn Lumo, weil seine Augen golden leuchten.'),
    'g4_donau': ReadingComprehension(
        'Welche Tiere leben laut Text in den Auwäldern?',
        [
          'Eisbären, Robben und Pinguine',
          'Biber, Reiher und Frösche',
          'Löwen, Zebras und Giraffen'
        ],
        1,
        'In den Auwäldern an ihrem Ufer leben Biber, Reiher und Frösche.'),
    'g4_wasserkreislauf': ReadingComprehension(
        'Wann fällt Wasser als Regen zurück?',
        [
          'Wenn es keine Wolken gibt.',
          'Wenn das Wasser im See gefriert.',
          'Wenn die Tropfen schwer genug sind.'
        ],
        2,
        'Wenn die Tropfen schwer genug sind, fällt das Wasser als Regen zurück.'),
    'g4_erfinder': ReadingComprehension(
        'Was erzeugt beim Treten den Strom?',
        ['Das Rad mit dem Dynamo', 'Eine Kerze', 'Eine Taschenlampe'],
        0,
        'Beim Treten erzeugt das Rad jetzt selbst den Strom.'),
    'g4_wien': ReadingComprehension(
        'Was besucht die Klasse zuerst?',
        ['Das Riesenrad', 'Den Stephansdom', 'Das Naturhistorische Museum'],
        1,
        'Zuerst besuchen sie den Stephansdom mitten in der Stadt.'),
    'g4_streit': ReadingComprehension(
        'Warum entschuldigt sich Mia?',
        [
          'Weil sie den Bus verpasst hat.',
          'Weil sie den Ball verloren hat.',
          'Weil ihr der Streit leidtut.'
        ],
        2,
        'Nach der Schule entschuldigt sich Mia, weil ihr der Streit leidtut.'),
  };
}
