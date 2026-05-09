import 'primary_school_word_data.dart';

/// Deterministische Deutsch-Templates für Volksschule 1-4.
class GermanTaskTemplates {
  const GermanTaskTemplates._();

  static const List<GermanTaskTemplate> templates = <GermanTaskTemplate>[
    GermanTaskTemplate(id: 'g1_letter_sound', grade: 1, unit: 'Buchstaben-Lautierung', kind: GermanTemplateKind.letterSound, promptPattern: 'laut-zu-buchstabe'),
    GermanTaskTemplate(id: 'g1_rhyme', grade: 1, unit: 'Reime', kind: GermanTemplateKind.rhymeRecognition, promptPattern: 'echter-reim'),
    GermanTaskTemplate(id: 'g1_start_sound', grade: 1, unit: 'Anfangslaute', kind: GermanTemplateKind.startSound, promptPattern: 'gleicher-anlaut'),
    GermanTaskTemplate(id: 'g1_word_image', grade: 1, unit: 'Wort-Bild-Zuordnung', kind: GermanTemplateKind.wordImage, promptPattern: 'wort-bild'),
    GermanTaskTemplate(id: 'g1_sentence_order', grade: 1, unit: 'Erste Sätze', kind: GermanTemplateKind.sentenceOrder, promptPattern: 'satzstellung-einfach'),
    GermanTaskTemplate(id: 'g1_syllables', grade: 1, unit: 'Silben', kind: GermanTemplateKind.syllables, promptPattern: 'silben-klatschen'),
    GermanTaskTemplate(id: 'g1_articles', grade: 1, unit: 'Artikel', kind: GermanTemplateKind.article, promptPattern: 'artikel-nomen'),

    GermanTaskTemplate(id: 'g2_family', grade: 2, unit: 'Wortfamilien', kind: GermanTemplateKind.wordFamily, promptPattern: 'wortfamilie'),
    GermanTaskTemplate(id: 'g2_plural', grade: 2, unit: 'Einzahl und Mehrzahl', kind: GermanTemplateKind.plural, promptPattern: 'mehrzahl'),
    GermanTaskTemplate(id: 'g2_diminutive', grade: 2, unit: 'Verkleinerungsform', kind: GermanTemplateKind.diminutive, promptPattern: 'verkleinerung'),
    GermanTaskTemplate(id: 'g2_opposites', grade: 2, unit: 'Gegenteile', kind: GermanTemplateKind.opposites, promptPattern: 'gegenteil'),
    GermanTaskTemplate(id: 'g2_categories', grade: 2, unit: 'Oberbegriffe', kind: GermanTemplateKind.categories, promptPattern: 'oberbegriff'),
    GermanTaskTemplate(id: 'g2_nouns', grade: 2, unit: 'Namenwoerter', kind: GermanTemplateKind.wordTypes, promptPattern: 'wortart-nomen'),
    GermanTaskTemplate(id: 'g2_verbs', grade: 2, unit: 'Tunwoerter', kind: GermanTemplateKind.wordTypes, promptPattern: 'wortart-verb'),
    GermanTaskTemplate(id: 'g2_adjectives', grade: 2, unit: 'Wiewoerter', kind: GermanTemplateKind.wordTypes, promptPattern: 'wortart-adjektiv'),

    GermanTaskTemplate(id: 'g3_synonyms', grade: 3, unit: 'Synonyme', kind: GermanTemplateKind.synonyms, promptPattern: 'synonym'),
    GermanTaskTemplate(id: 'g3_word_types', grade: 3, unit: 'Wortarten', kind: GermanTemplateKind.wordTypes, promptPattern: 'wortarten-unterscheiden'),
    GermanTaskTemplate(id: 'g3_tense', grade: 3, unit: 'Zeitformen', kind: GermanTemplateKind.pastTense, promptPattern: 'vergangenheit'),
    GermanTaskTemplate(id: 'g3_comparison', grade: 3, unit: 'Steigerung', kind: GermanTemplateKind.comparison, promptPattern: 'steigerung'),
    GermanTaskTemplate(id: 'g3_verb_form', grade: 3, unit: 'Verbformen', kind: GermanTemplateKind.verbForm, promptPattern: 'verb-kongruenz'),

    GermanTaskTemplate(id: 'g4_sentence_parts', grade: 4, unit: 'Satzglieder', kind: GermanTemplateKind.sentenceParts, promptPattern: 'satzglied'),
    GermanTaskTemplate(id: 'g4_direct_speech', grade: 4, unit: 'Direkte Rede', kind: GermanTemplateKind.directSpeech, promptPattern: 'direkte-rede'),
    GermanTaskTemplate(id: 'g4_commas', grade: 4, unit: 'Kommas in Aufzählungen', kind: GermanTemplateKind.commas, promptPattern: 'komma-aufzaehlung'),
    GermanTaskTemplate(id: 'g4_compounds', grade: 4, unit: 'Zusammensetzungen', kind: GermanTemplateKind.compounds, promptPattern: 'zusammensetzung-bedeutung'),
  ];

  static List<GermanTaskTemplate> templatesForGrade(int grade, {String? unit}) {
    final capped = grade.clamp(1, 4);
    final normalized = _normalizeUnit(unit ?? 'Alle');
    final pool = templates.where((template) => template.grade <= capped).where((template) {
      if (normalized == 'Alle') return true;
      if (_normalizeUnit(template.unit) == normalized) return true;
      return _legacyUnitAliases[normalized]?.contains(template.unit) ?? false;
    }).toList(growable: false);
    if (pool.isNotEmpty) return pool;
    return templates.where((template) => template.grade <= capped).toList(growable: false);
  }

  static GermanConcreteTask generate({required int grade, required String unit, required int seed}) {
    final pool = templatesForGrade(grade, unit: unit);
    final template = pool[_positive(seed, pool.length)];
    return template.concretize(seed + template.id.hashCode);
  }

  static const Map<String, List<String>> _legacyUnitAliases = <String, List<String>>{
    'Anfangslaute': <String>['Anfangslaute', 'Buchstaben-Lautierung'],
    'Endlaute': <String>['Anfangslaute'],
    'Buchstaben': <String>['Buchstaben-Lautierung'],
    'Wortschatz': <String>['Oberbegriffe', 'Synonyme', 'Gegenteile'],
    'Satz verstehen': <String>['Erste Sätze', 'Satzglieder'],
    'Satz bauen': <String>['Erste Sätze', 'Verbformen'],
    'Namenwoerter': <String>['Namenwoerter'],
    'Namenswoerter': <String>['Namenwoerter'],
    'Hauptwoerter': <String>['Namenwoerter'],
    'Tunwoerter': <String>['Tunwoerter'],
    'Wiewoerter': <String>['Wiewoerter'],
    'Einzahl und Mehrzahl': <String>['Einzahl und Mehrzahl'],
    'Wort-Bild schreiben': <String>['Wort-Bild-Zuordnung'],
  };
}

class GermanTaskTemplate {
  const GermanTaskTemplate({required this.id, required this.grade, required this.unit, required this.kind, required this.promptPattern});

  final String id;
  final int grade;
  final String unit;
  final GermanTemplateKind kind;
  final String promptPattern;

  GermanConcreteTask concretize(int seed) {
    switch (kind) {
      case GermanTemplateKind.letterSound:
        final entry = _letterSounds[_positive(seed, _letterSounds.length)];
        return _choice('Welcher Buchstabe macht den Laut „${entry.sound}“?', entry.letter, entry.choices, 'Sprich den Laut langsam und suche den passenden Buchstaben.', 'letters');
      case GermanTemplateKind.rhymeRecognition:
        final pair = PrimarySchoolWordData.rhymePairForSeed(seed);
        final distractors = _nouns(seed, grade, except: pair.toSet()).take(3).toList();
        return _choice('Was reimt sich auf ${pair.first}?', pair.last, <String>[pair.last, ...distractors], 'Reimwörter klingen am Ende gleich.', 'rhyme');
      case GermanTemplateKind.startSound:
        final word = PrimarySchoolWordData.firstSoundWordForGrade(grade, seed: seed) ?? 'Apfel';
        final first = word.substring(0, 1).toUpperCase();
        final distractors = _confusableLetters(first);
        return _choice('Welches Wort beginnt mit demselben Laut wie $word?', word, <String>[word, ..._nouns(seed + 5, grade, except: <String>{word}).where((w) => !w.toUpperCase().startsWith(first)).take(3)], 'Höre auf den ersten Laut: $first.', 'sound');
      case GermanTemplateKind.wordImage:
        final word = PrimarySchoolWordData.nounForGrade(grade, seed);
        return _choice('Welches Wort passt zum Bild: ${_emojiFor(word)}?', word, <String>[word, ..._nouns(seed + 3, grade, except: <String>{word}).take(3)], 'Verbinde das Bild mit dem passenden Namenwort.', 'word_image');
      case GermanTemplateKind.sentenceOrder:
        final noun = PrimarySchoolWordData.nounForGrade(grade, seed);
        final article = PrimarySchoolWordData.articleFor(noun) ?? 'das';
        final verb = _simpleVerb(seed);
        final correct = '${_cap(article)} $noun $verb.';
        return _choice('Welcher Satz ist richtig?', correct, <String>[correct, '$noun $article $verb.', '$verb $article $noun.', '${_cap(article)} $verb $noun.'], 'Ein deutscher Aussagesatz beginnt mit dem Satzanfang, dann folgt das Tunwort an zweiter Stelle.', 'sentence');
      case GermanTemplateKind.syllables:
        final word = _wordWithSyllables(seed, grade);
        final syllables = PrimarySchoolWordData.syllablesFor(word) ?? <String>[word];
        return _choice('Wie viele Silben hat $word?', '${syllables.length}', <String>['${syllables.length}', '${syllables.length + 1}', '${(syllables.length - 1).clamp(1, 9)}'], 'Klatsche jede Silbe: ${syllables.join(' - ')}.', 'syllables');
      case GermanTemplateKind.article:
        final noun = PrimarySchoolWordData.nounForGrade(grade, seed);
        final answer = PrimarySchoolWordData.articleFor(noun) ?? 'der';
        return _choice('Welcher Artikel passt zu $noun?', answer, <String>['der', 'die', 'das'], 'Sprich Artikel und Wort zusammen: $answer $noun.', 'article');
      case GermanTemplateKind.wordFamily:
        final family = _families[_positive(seed, _families.length)];
        return _choice('Welche Wörter gehören zur Wortfamilie „${family.root}“?', family.answer, <String>[family.answer, ...family.distractors], 'Wortfamilien haben denselben Wortstamm.', 'family');
      case GermanTemplateKind.plural:
        final item = _plurals[_positive(seed, _plurals.length)];
        return _choice('Welche Mehrzahl ist richtig: ${item.singular}?', item.plural, <String>[item.plural, ...item.distractors], 'Die Mehrzahl sagt: mehr als eines.', 'plural');
      case GermanTemplateKind.diminutive:
        final item = _diminutives[_positive(seed, _diminutives.length)];
        return _choice('Was ist die Verkleinerungsform von ${item.base}?', item.answer, <String>[item.answer, ...item.distractors], 'Verkleinerungen enden oft auf -chen oder -lein.', 'diminutive');
      case GermanTemplateKind.opposites:
        final item = _opposites[_positive(seed, _opposites.length)];
        return _choice('Was ist das Gegenteil von ${item.left}?', item.right, <String>[item.right, ...item.distractors], 'Gegenteile beschreiben die andere Seite einer Eigenschaft.', 'opposite');
      case GermanTemplateKind.categories:
        final item = _categories[_positive(seed, _categories.length)];
        return _choice('Was ist der Oberbegriff für ${item.examples.join(', ')}?', item.category, <String>[item.category, ...item.distractors], 'Ein Oberbegriff fasst mehrere passende Wörter zusammen.', 'category');
      case GermanTemplateKind.synonyms:
        final item = _synonyms[_positive(seed, _synonyms.length)];
        return _choice('Welches Wort bedeutet dasselbe wie ${item.left}?', item.right, <String>[item.right, ...item.distractors], 'Synonyme haben eine ähnliche Bedeutung.', 'synonym');
      case GermanTemplateKind.wordTypes:
        final selector = seed % 3;
        if (selector == 0 || promptPattern.contains('nomen')) {
          final answer = PrimarySchoolWordData.nounForGrade(grade, seed);
          return _choice('Welches Wort ist ein Namenwort?', answer, <String>[answer, PrimarySchoolWordData.verbForGrade(grade, seed + 1), PrimarySchoolWordData.adjectiveForGrade(grade, seed + 2)], 'Namenwörter bezeichnen Menschen, Tiere, Pflanzen und Dinge.', 'word_type');
        }
        if (selector == 1 || promptPattern.contains('verb')) {
          final answer = PrimarySchoolWordData.verbForGrade(grade, seed);
          return _choice('Welches Wort ist ein Tunwort?', answer, <String>[answer, PrimarySchoolWordData.nounForGrade(grade, seed + 1), PrimarySchoolWordData.adjectiveForGrade(grade, seed + 2)], 'Tunwörter sagen, was jemand macht.', 'word_type');
        }
        final answer = PrimarySchoolWordData.adjectiveForGrade(grade, seed);
        return _choice('Welches Wort ist ein Wiewort?', answer, <String>[answer, PrimarySchoolWordData.nounForGrade(grade, seed + 1), PrimarySchoolWordData.verbForGrade(grade, seed + 2)], 'Wiewörter beschreiben Eigenschaften.', 'word_type');
      case GermanTemplateKind.pastTense:
        final item = _pastTenses[_positive(seed, _pastTenses.length)];
        return _choice('Was ist die Vergangenheit von „${item.left}“?', item.right, <String>[item.right, ...item.distractors], 'Die Vergangenheit erzählt, was schon passiert ist.', 'tense');
      case GermanTemplateKind.comparison:
        final item = _comparisons[_positive(seed, _comparisons.length)];
        return _choice('Wie heißt die Steigerung von „${item.base}“?', item.answer, <String>[item.answer, ...item.distractors], 'Viele Wiewörter steigern wir mit -er und „am …sten“.', 'comparison');
      case GermanTemplateKind.verbForm:
        final item = _verbForms[_positive(seed, _verbForms.length)];
        return _choice('${item.prompt}', item.answer, <String>[item.answer, ...item.distractors], 'Das Tunwort muss zur Person passen.', 'verb_form');
      case GermanTemplateKind.sentenceParts:
        final item = _sentenceParts[_positive(seed, _sentenceParts.length)];
        return _choice('Welches Satzglied ist im Satz „${item.sentence}“ ${item.question}?', item.answer, <String>[item.answer, ...item.distractors], 'Frage nach dem Satzglied, dann findest du es leichter.', 'sentence_part');
      case GermanTemplateKind.directSpeech:
        final item = _directSpeech[_positive(seed, _directSpeech.length)];
        return _choice('Welche direkte Rede ist richtig?', item.answer, <String>[item.answer, ...item.distractors], 'Direkte Rede steht in Anführungszeichen und wird mit Begleitsatz verbunden.', 'direct_speech');
      case GermanTemplateKind.commas:
        final item = _commas[_positive(seed, _commas.length)];
        return _choice('Wo steht das Komma richtig?', item.answer, <String>[item.answer, ...item.distractors], 'Bei Aufzählungen trennen Kommas die einzelnen Wörter.', 'comma');
      case GermanTemplateKind.compounds:
        final item = _compounds[_positive(seed, _compounds.length)];
        return _choice('Was bedeutet „${item.compound}“?', item.answer, <String>[item.answer, ...item.distractors], 'Zusammensetzungen verbinden zwei Wörter zu einem neuen Wort.', 'compound');
    }
  }

  GermanConcreteTask _choice(String prompt, String answer, List<String> rawChoices, String explanation, String visual) {
    final choices = <String>[answer];
    for (final choice in rawChoices) {
      if (choice.trim().isNotEmpty && choice != answer && !choices.contains(choice)) choices.add(choice);
      if (choices.length == 4) break;
    }
    while (choices.length < 3) {
      choices.add('anderes Wort ${choices.length}');
    }
    return GermanConcreteTask(
      unit: unit,
      prompt: prompt,
      answer: answer,
      choices: choices,
      explanation: explanation,
      visual: visual,
      difficulty: grade,
      promptPattern: promptPattern,
    );
  }
}

class GermanConcreteTask {
  const GermanConcreteTask({required this.unit, required this.prompt, required this.answer, required this.choices, required this.explanation, required this.visual, required this.difficulty, required this.promptPattern});

  final String unit;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String visual;
  final int difficulty;
  final String promptPattern;
}

enum GermanTemplateKind {
  letterSound,
  rhymeRecognition,
  startSound,
  wordImage,
  sentenceOrder,
  syllables,
  article,
  wordFamily,
  plural,
  diminutive,
  opposites,
  categories,
  synonyms,
  wordTypes,
  pastTense,
  comparison,
  verbForm,
  sentenceParts,
  directSpeech,
  commas,
  compounds,
}

class _LetterSound {
  const _LetterSound(this.sound, this.letter, this.choices);
  final String sound;
  final String letter;
  final List<String> choices;
}

class _PairItem {
  const _PairItem(this.left, this.right, this.distractors);
  final String left;
  final String right;
  final List<String> distractors;
}

class _PluralItem {
  const _PluralItem(this.singular, this.plural, this.distractors);
  final String singular;
  final String plural;
  final List<String> distractors;
}

class _DiminutiveItem {
  const _DiminutiveItem(this.base, this.answer, this.distractors);
  final String base;
  final String answer;
  final List<String> distractors;
}

class _FamilyItem {
  const _FamilyItem(this.root, this.answer, this.distractors);
  final String root;
  final String answer;
  final List<String> distractors;
}

class _CategoryItem {
  const _CategoryItem(this.examples, this.category, this.distractors);
  final List<String> examples;
  final String category;
  final List<String> distractors;
}

class _ComparisonItem {
  const _ComparisonItem(this.base, this.answer, this.distractors);
  final String base;
  final String answer;
  final List<String> distractors;
}

class _VerbFormItem {
  const _VerbFormItem(this.prompt, this.answer, this.distractors);
  final String prompt;
  final String answer;
  final List<String> distractors;
}

class _SentencePartItem {
  const _SentencePartItem(this.sentence, this.question, this.answer, this.distractors);
  final String sentence;
  final String question;
  final String answer;
  final List<String> distractors;
}

class _DirectSpeechItem {
  const _DirectSpeechItem(this.answer, this.distractors);
  final String answer;
  final List<String> distractors;
}

class _CommaItem {
  const _CommaItem(this.answer, this.distractors);
  final String answer;
  final List<String> distractors;
}

class _CompoundItem {
  const _CompoundItem(this.compound, this.answer, this.distractors);
  final String compound;
  final String answer;
  final List<String> distractors;
}

const List<_LetterSound> _letterSounds = <_LetterSound>[
  _LetterSound('mmmm', 'M', <String>['M', 'N', 'W', 'B']),
  _LetterSound('ssss', 'S', <String>['S', 'F', 'Sch', 'Z']),
  _LetterSound('schhhh', 'Sch', <String>['Sch', 'S', 'Ch', 'Sp']),
  _LetterSound('ffff', 'F', <String>['F', 'W', 'V', 'S']),
  _LetterSound('rrrr', 'R', <String>['R', 'L', 'N', 'M']),
  _LetterSound('aaaa', 'A', <String>['A', 'O', 'E', 'U']),
];

const List<_FamilyItem> _families = <_FamilyItem>[
  _FamilyItem('fahr', 'fahren, Fahrrad, Fahrer', <String>['malen, Maler, Bild', 'lesen, Buch, leise', 'Wasser, Wolke, Wind']),
  _FamilyItem('spiel', 'spielen, Spiel, Spielzeug', <String>['laufen, Läufer, schnell', 'Schule, Tafel, Kreide', 'Apfel, Birne, Obst']),
  _FamilyItem('mal', 'malen, Maler, Gemälde', <String>['fahren, Bus, Straße', 'singen, Lied, Ton', 'rechnen, Zahl, Plus']),
  _FamilyItem('les', 'lesen, Leser, Lesebuch', <String>['springen, Seil, Turnsaal', 'essen, Teller, Suppe', 'gehen, Weg, Schuh']),
];

const List<_PluralItem> _plurals = <_PluralItem>[
  _PluralItem('der Hund', 'die Hunde', <String>['die Hunden', 'die Hund', 'der Hunde']),
  _PluralItem('die Katze', 'die Katzen', <String>['die Kätze', 'die Katze', 'der Katzen']),
  _PluralItem('das Buch', 'die Bücher', <String>['die Buche', 'die Bucher', 'das Bücher']),
  _PluralItem('der Apfel', 'die Äpfel', <String>['die Apfels', 'die Apfeln', 'der Äpfel']),
  _PluralItem('die Semmel', 'die Semmeln', <String>['die Semmels', 'der Semmeln', 'die Semmel']),
  _PluralItem('das Kind', 'die Kinder', <String>['die Kinde', 'die Kinds', 'das Kinder']),
  _PluralItem('der Baum', 'die Bäume', <String>['die Baume', 'die Baums', 'der Bäume']),
  _PluralItem('die Schule', 'die Schulen', <String>['die Schules', 'der Schulen', 'die Schule']),
];

const List<_DiminutiveItem> _diminutives = <_DiminutiveItem>[
  _DiminutiveItem('Buch', 'Büchlein', <String>['Bucher', 'Buchig', 'Buchung']),
  _DiminutiveItem('Haus', 'Häuschen', <String>['Hauser', 'Hauslein', 'Häuser']),
  _DiminutiveItem('Maus', 'Mäuschen', <String>['Mäuser', 'Mausen', 'Mauslein']),
  _DiminutiveItem('Katze', 'Kätzchen', <String>['Katzen', 'Katzlein', 'Katzung']),
  _DiminutiveItem('Hund', 'Hündchen', <String>['Hunde', 'Hundchen ohne Umlaut', 'Hundung']),
];

const List<_PairItem> _opposites = <_PairItem>[
  _PairItem('groß', 'klein', <String>['warm', 'rund', 'schnell']),
  _PairItem('hell', 'dunkel', <String>['weich', 'laut', 'neu']),
  _PairItem('warm', 'kalt', <String>['klein', 'glatt', 'bunt']),
  _PairItem('laut', 'leise', <String>['hell', 'lang', 'rot']),
  _PairItem('schnell', 'langsam', <String>['hoch', 'frisch', 'voll']),
  _PairItem('voll', 'leer', <String>['spitz', 'rund', 'süß']),
];

const List<_CategoryItem> _categories = <_CategoryItem>[
  _CategoryItem(<String>['Apfel', 'Banane', 'Birne'], 'Obst', <String>['Werkzeug', 'Kleidung', 'Verkehr']),
  _CategoryItem(<String>['Hund', 'Katze', 'Hase'], 'Tiere', <String>['Pflanzen', 'Möbel', 'Gefühle']),
  _CategoryItem(<String>['Hammer', 'Säge', 'Zange'], 'Werkzeug', <String>['Obst', 'Schulsachen', 'Sport']),
  _CategoryItem(<String>['Hose', 'Jacke', 'Schuh'], 'Kleidung', <String>['Getränke', 'Wetter', 'Zahlen']),
  _CategoryItem(<String>['Bus', 'Zug', 'Auto'], 'Fahrzeuge', <String>['Blumen', 'Körperteile', 'Berufe']),
  _CategoryItem(<String>['Semmel', 'Topfen', 'Marille'], 'Essen aus Österreich', <String>['Werkzeuge', 'Verkehrszeichen', 'Formen']),
];

const List<_PairItem> _synonyms = <_PairItem>[
  _PairItem('schnell', 'rasch', <String>['langsam', 'klein', 'rund']),
  _PairItem('schön', 'hübsch', <String>['schwer', 'traurig', 'spitz']),
  _PairItem('sprechen', 'reden', <String>['laufen', 'essen', 'schlafen']),
  _PairItem('beginnen', 'anfangen', <String>['enden', 'verlieren', 'fallen']),
  _PairItem('klug', 'gescheit', <String>['müde', 'nass', 'leer']),
  _PairItem('fröhlich', 'lustig', <String>['wütend', 'hart', 'gerade']),
];

const List<_PairItem> _pastTenses = <_PairItem>[
  _PairItem('gehen', 'ging', <String>['gehte', 'geht', 'gegangen ist falsch hier']),
  _PairItem('laufen', 'lief', <String>['laufte', 'läuft', 'gelauft']),
  _PairItem('sehen', 'sah', <String>['sehte', 'sieht', 'geseht']),
  _PairItem('kommen', 'kam', <String>['kommte', 'kommt', 'gekommt']),
  _PairItem('essen', 'aß', <String>['esste', 'isst', 'geesst']),
  _PairItem('schreiben', 'schrieb', <String>['schreibte', 'schreibt', 'geschreibt']),
];

const List<_ComparisonItem> _comparisons = <_ComparisonItem>[
  _ComparisonItem('schön', 'schöner, am schönsten', <String>['schön, am schöner', 'schönste, schöner', 'schöner, am schön']),
  _ComparisonItem('schnell', 'schneller, am schnellsten', <String>['schnell, am schneller', 'schnellst, schneller', 'schneller, am schnell']),
  _ComparisonItem('groß', 'größer, am größten', <String>['großer, am großten', 'groß, am größer', 'größte, größer']),
  _ComparisonItem('gut', 'besser, am besten', <String>['guter, am gutsten', 'guter, am besten', 'besser, am gutesten']),
  _ComparisonItem('viel', 'mehr, am meisten', <String>['vieler, am vielsten', 'mehr, am vielsten', 'viele, am meisten']),
];

const List<_VerbFormItem> _verbForms = <_VerbFormItem>[
  _VerbFormItem('Wir _____ (gehen) in die Schule.', 'gehen', <String>['geht', 'gehe', 'gehst']),
  _VerbFormItem('Du _____ (lesen) ein Buch.', 'liest', <String>['lesen', 'lese', 'lest']),
  _VerbFormItem('Ich _____ (spielen) im Garten.', 'spiele', <String>['spielst', 'spielt', 'spielen']),
  _VerbFormItem('Sie _____ (rechnen) die Aufgabe.', 'rechnet', <String>['rechne', 'rechnen', 'rechnest']),
  _VerbFormItem('Ihr _____ (singen) ein Lied.', 'singt', <String>['singe', 'singen', 'singst']),
];

const List<_SentencePartItem> _sentenceParts = <_SentencePartItem>[
  _SentencePartItem('Lena liest am Nachmittag ein Buch.', 'Wer?', 'Lena', <String>['liest', 'am Nachmittag', 'ein Buch']),
  _SentencePartItem('Der Hund bellt im Garten.', 'Was tut er?', 'bellt', <String>['Der Hund', 'im Garten', 'laut']),
  _SentencePartItem('Opa fährt mit dem Zug nach Wien.', 'Wohin?', 'nach Wien', <String>['Opa', 'fährt', 'mit dem Zug']),
  _SentencePartItem('Im Winter rodeln die Kinder am Hügel.', 'Wann?', 'Im Winter', <String>['die Kinder', 'am Hügel', 'rodeln']),
];

const List<_DirectSpeechItem> _directSpeech = <_DirectSpeechItem>[
  _DirectSpeechItem('Lena sagt: „Ich komme gleich.“', <String>['Lena sagt Ich komme gleich.', '„Lena sagt: Ich komme gleich.“', 'Lena sagt: Ich komme gleich.']),
  _DirectSpeechItem('„Ich habe Hunger“, sagt Tom.', <String>['Ich habe Hunger, sagt Tom.', '„Ich habe Hunger, sagt Tom.“', 'Ich habe Hunger sagt Tom.']),
  _DirectSpeechItem('Mama fragt: „Kommst du mit?“', <String>['Mama fragt Kommst du mit?', '„Mama fragt: Kommst du mit?“', 'Mama fragt: Kommst du mit?']),
];

const List<_CommaItem> _commas = <_CommaItem>[
  _CommaItem('Ich packe Heft, Stift, Buch und Jause ein.', <String>['Ich packe Heft Stift Buch und Jause ein.', 'Ich packe Heft, Stift Buch und Jause ein.', 'Ich packe Heft Stift, Buch, und Jause ein.']),
  _CommaItem('Wir kaufen Äpfel, Birnen, Semmeln und Topfen.', <String>['Wir kaufen Äpfel Birnen Semmeln und Topfen.', 'Wir kaufen Äpfel, Birnen Semmeln und Topfen.', 'Wir kaufen Äpfel Birnen, Semmeln, und Topfen.']),
  _CommaItem('Im Federpennal sind Bleistift, Schere, Kleber und Lineal.', <String>['Im Federpennal sind Bleistift Schere Kleber und Lineal.', 'Im Federpennal sind Bleistift, Schere Kleber und Lineal.', 'Im Federpennal sind Bleistift Schere, Kleber, und Lineal.']),
];

const List<_CompoundItem> _compounds = <_CompoundItem>[
  _CompoundItem('Sonnenblume', 'eine Blume, die zur Sonne passt', <String>['eine Sonne aus Blumen', 'eine Blume ohne Licht', 'ein Tier im Garten']),
  _CompoundItem('Schultasche', 'eine Tasche für die Schule', <String>['eine Schule in einer Tasche', 'eine Tasche für Tiere', 'eine Tasche aus Papier']),
  _CompoundItem('Wasserflasche', 'eine Flasche für Wasser', <String>['Wasser in Form einer Flasche', 'eine Flasche für Sand', 'ein Spielzeug']),
  _CompoundItem('Bücherregal', 'ein Regal für Bücher', <String>['ein Buch aus Holz', 'ein Regal für Schuhe', 'ein Heft mit Linien']),
  _CompoundItem('Verkehrsschild', 'ein Schild im Verkehr', <String>['ein Verkehr aus Schildern', 'ein Schild im Garten', 'ein Spielplan']),
];

List<String> _nouns(int seed, int grade, {Set<String> except = const <String>{}}) {
  final source = PrimarySchoolWordData.nounsForGrade(grade);
  return List<String>.generate(source.length, (index) => source[(index + _positive(seed, source.length)) % source.length])
      .where((word) => !except.contains(word))
      .toList(growable: false);
}

String _simpleVerb(int seed) {
  const verbs = <String>['liest', 'malt', 'spielt', 'lacht', 'singt', 'turnt', 'schreibt', 'rechnet'];
  return verbs[_positive(seed, verbs.length)];
}

String _wordWithSyllables(int seed, int grade) {
  final words = PrimarySchoolWordData.nounsForGrade(grade).where((word) => (PrimarySchoolWordData.syllablesFor(word)?.length ?? 0) > 1).toList(growable: false);
  if (words.isEmpty) return PrimarySchoolWordData.nounForGrade(grade, seed);
  return words[_positive(seed, words.length)];
}

String _emojiFor(String word) {
  final lower = word.toLowerCase();
  if (lower.contains('hund')) return '🐶';
  if (lower.contains('katze')) return '🐱';
  if (lower.contains('apfel')) return '🍎';
  if (lower.contains('banane')) return '🍌';
  if (lower.contains('blume')) return '🌼';
  if (lower.contains('baum')) return '🌳';
  if (lower.contains('auto')) return '🚗';
  if (lower.contains('bus')) return '🚌';
  if (lower.contains('buch')) return '📘';
  if (lower.contains('ball')) return '⚽';
  return '🖼️';
}

List<String> _confusableLetters(String letter) {
  const map = <String, List<String>>{
    'A': <String>['O', 'E', 'U'],
    'B': <String>['P', 'D', 'R'],
    'D': <String>['T', 'B', 'P'],
    'F': <String>['W', 'V', 'S'],
    'G': <String>['K', 'C', 'J'],
    'M': <String>['N', 'W', 'B'],
    'S': <String>['Z', 'F', 'Sch'],
    'Sch': <String>['S', 'Sp', 'Ch'],
  };
  return map[letter] ?? const <String>['A', 'M', 'S'];
}

String _cap(String value) => value.isEmpty ? value : value.substring(0, 1).toUpperCase() + value.substring(1);
String _normalizeUnit(String value) => value.replaceAll('ö', 'oe').replaceAll('ä', 'ae').replaceAll('ü', 'ue');
int _positive(int seed, int length) => length <= 1 ? 0 : (seed & 0x7fffffff) % length;
