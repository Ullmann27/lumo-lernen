import 'primary_school_word_data.dart';

/// Deterministische Deutsch-Templates für Volksschule 1-4.
class GermanTaskTemplates {
  const GermanTaskTemplates._();

  static const List<GermanTaskTemplate> templates = <GermanTaskTemplate>[
    GermanTaskTemplate(
        id: 'g1_letter_sound',
        grade: 1,
        unit: 'Buchstaben-Lautierung',
        kind: GermanTemplateKind.letterSound,
        promptPattern: 'laut-zu-buchstabe'),
    GermanTaskTemplate(
        id: 'g1_rhyme',
        grade: 1,
        unit: 'Reime',
        kind: GermanTemplateKind.rhymeRecognition,
        promptPattern: 'echter-reim'),
    GermanTaskTemplate(
        id: 'g1_start_sound',
        grade: 1,
        unit: 'Anfangslaute',
        kind: GermanTemplateKind.startSound,
        promptPattern: 'anlaut-hoeren'),
    GermanTaskTemplate(
        id: 'g1_end_sound',
        grade: 1,
        unit: 'Endlaute',
        kind: GermanTemplateKind.endSound,
        promptPattern: 'endlaut-hoeren'),
    GermanTaskTemplate(
        id: 'g1_word_image',
        grade: 1,
        unit: 'Wort-Bild-Zuordnung',
        kind: GermanTemplateKind.wordImage,
        promptPattern: 'wort-bild'),
    GermanTaskTemplate(
        id: 'g1_sentence_order',
        grade: 1,
        unit: 'Erste Sätze',
        kind: GermanTemplateKind.sentenceOrder,
        promptPattern: 'satzstellung-einfach'),
    GermanTaskTemplate(
        id: 'g1_syllables',
        grade: 1,
        unit: 'Silben',
        kind: GermanTemplateKind.syllables,
        promptPattern: 'silben-klatschen'),
    GermanTaskTemplate(
        id: 'g1_articles',
        grade: 1,
        unit: 'Artikel',
        kind: GermanTemplateKind.article,
        promptPattern: 'artikel-nomen'),

    GermanTaskTemplate(
        id: 'g2_family',
        grade: 2,
        unit: 'Wortfamilien',
        kind: GermanTemplateKind.wordFamily,
        promptPattern: 'wortfamilie'),
    GermanTaskTemplate(
        id: 'g2_plural',
        grade: 2,
        unit: 'Einzahl und Mehrzahl',
        kind: GermanTemplateKind.plural,
        promptPattern: 'mehrzahl'),
    GermanTaskTemplate(
        id: 'g2_diminutive',
        grade: 2,
        unit: 'Verkleinerungsform',
        kind: GermanTemplateKind.diminutive,
        promptPattern: 'verkleinerung'),
    GermanTaskTemplate(
        id: 'g2_opposites',
        grade: 2,
        unit: 'Gegenteile',
        kind: GermanTemplateKind.opposites,
        promptPattern: 'gegenteil'),
    GermanTaskTemplate(
        id: 'g2_categories',
        grade: 2,
        unit: 'Oberbegriffe',
        kind: GermanTemplateKind.categories,
        promptPattern: 'oberbegriff'),
    GermanTaskTemplate(
        id: 'g2_nouns',
        grade: 2,
        unit: 'Namenwoerter',
        kind: GermanTemplateKind.wordTypes,
        promptPattern: 'wortart-nomen'),
    GermanTaskTemplate(
        id: 'g2_verbs',
        grade: 2,
        unit: 'Tunwoerter',
        kind: GermanTemplateKind.wordTypes,
        promptPattern: 'wortart-verb'),
    GermanTaskTemplate(
        id: 'g2_adjectives',
        grade: 2,
        unit: 'Wiewoerter',
        kind: GermanTemplateKind.wordTypes,
        promptPattern: 'wortart-adjektiv'),

    GermanTaskTemplate(
        id: 'g3_synonyms',
        grade: 3,
        unit: 'Synonyme',
        kind: GermanTemplateKind.synonyms,
        promptPattern: 'synonym'),
    GermanTaskTemplate(
        id: 'g3_word_types',
        grade: 3,
        unit: 'Wortarten',
        kind: GermanTemplateKind.wordTypes,
        promptPattern: 'wortarten-unterscheiden'),
    GermanTaskTemplate(
        id: 'g3_tense',
        grade: 3,
        unit: 'Zeitformen',
        kind: GermanTemplateKind.pastTense,
        promptPattern: 'vergangenheit'),
    GermanTaskTemplate(
        id: 'g3_comparison',
        grade: 3,
        unit: 'Steigerung',
        kind: GermanTemplateKind.comparison,
        promptPattern: 'steigerung'),
    GermanTaskTemplate(
        id: 'g3_verb_form',
        grade: 3,
        unit: 'Verbformen',
        kind: GermanTemplateKind.verbForm,
        promptPattern: 'verb-kongruenz'),
    // Neue Klasse-3-Lehrplan-Templates (AT 2026-06-03):
    GermanTaskTemplate(
        id: 'g3_case_nom_akk',
        grade: 3,
        unit: 'Wer-Fall und Wen-Fall',
        kind: GermanTemplateKind.caseNomAkk,
        promptPattern: 'fall-bestimmen'),
    GermanTaskTemplate(
        id: 'g3_capitalization',
        grade: 3,
        unit: 'Großschreibung',
        kind: GermanTemplateKind.capitalization,
        promptPattern: 'grossbuchstabe'),
    GermanTaskTemplate(
        id: 'g3_ie_or_i',
        grade: 3,
        unit: 'ie oder i',
        kind: GermanTemplateKind.ieOrI,
        promptPattern: 'lang-i-rechtschreibung'),

    GermanTaskTemplate(
        id: 'g4_sentence_parts',
        grade: 4,
        unit: 'Satzglieder',
        kind: GermanTemplateKind.sentenceParts,
        promptPattern: 'satzglied'),
    GermanTaskTemplate(
        id: 'g4_direct_speech',
        grade: 4,
        unit: 'Direkte Rede',
        kind: GermanTemplateKind.directSpeech,
        promptPattern: 'direkte-rede'),
    GermanTaskTemplate(
        id: 'g4_commas',
        grade: 4,
        unit: 'Kommas in Aufzählungen',
        kind: GermanTemplateKind.commas,
        promptPattern: 'komma-aufzaehlung'),
    GermanTaskTemplate(
        id: 'g4_compounds',
        grade: 4,
        unit: 'Zusammensetzungen',
        kind: GermanTemplateKind.compounds,
        promptPattern: 'zusammensetzung-bedeutung'),
    // Neue Klasse-4-Lehrplan-Templates (AT 2026-06-03):
    GermanTaskTemplate(
        id: 'g4_four_cases',
        grade: 4,
        unit: 'Die 4 Fälle',
        kind: GermanTemplateKind.fourCases,
        promptPattern: 'vier-faelle'),
    GermanTaskTemplate(
        id: 'g4_dass_das',
        grade: 4,
        unit: 'dass oder das',
        kind: GermanTemplateKind.dassDas,
        promptPattern: 'dass-das'),
    GermanTaskTemplate(
        id: 'g4_adverbs',
        grade: 4,
        unit: 'Umstandswörter',
        kind: GermanTemplateKind.adverbs,
        promptPattern: 'adverb-bestimmen'),
    GermanTaskTemplate(
        id: 'g4_plusquam',
        grade: 4,
        unit: 'Vorvergangenheit',
        kind: GermanTemplateKind.plusquamperfect,
        promptPattern: 'plusquamperfekt'),
  ];

  static bool supportsUnit(int grade, String unit) {
    final normalized = _normalizeUnit(unit);
    if (normalized == 'Alle') return true;
    final capped = grade.clamp(1, 4);
    return templates.any((template) => template.grade <= capped &&
        (_normalizeUnit(template.unit) == normalized ||
            (_legacyUnitAliases[normalized]?.contains(template.unit) ?? false)));
  }

  static List<GermanTaskTemplate> templatesForGrade(int grade, {String? unit}) {
    final capped = grade.clamp(1, 4);
    final normalized = _normalizeUnit(unit ?? 'Alle');
    final pool = templates
        .where((template) => template.grade <= capped)
        .where((template) {
      if (normalized == 'Alle') return true;
      if (_normalizeUnit(template.unit) == normalized) return true;
      return _legacyUnitAliases[normalized]?.contains(template.unit) ?? false;
    }).toList(growable: false);
    if (pool.isNotEmpty) return pool;
    return templates
        .where((template) => template.grade <= capped)
        .toList(growable: false);
  }

  /// Liefert nur Templates der EXAKTEN Klasse (keine Wiederholung). Wird
  /// im Hauptpool genutzt damit das Niveau zur Stufe passt (Heinz
  /// 2026-06-03: "auf jede Schulstufe angepasst").
  static List<GermanTaskTemplate> templatesForGradeStrict(int grade,
      {String? unit}) {
    final capped = grade.clamp(1, 4);
    final normalized = _normalizeUnit(unit ?? 'Alle');
    final pool = templates
        .where((template) => template.grade == capped)
        .where((template) {
      if (normalized == 'Alle') return true;
      if (_normalizeUnit(template.unit) == normalized) return true;
      return _legacyUnitAliases[normalized]?.contains(template.unit) ?? false;
    }).toList(growable: false);
    if (pool.isNotEmpty) return pool;
    return templatesForGrade(grade, unit: unit);
  }

  static GermanConcreteTask generate(
      {required int grade, required String unit, required int seed}) {
    // Die Auswahl der Familie muss unabhängig vom Wiederholungsviertel sein.
    // seed % pool.length ließ bei Pools mit acht Familien manche nie zu.
    final available = templatesForGrade(grade, unit: unit);
    final current =
        available.where((item) => item.grade == grade.clamp(1, 4)).toList();
    final earlier =
        available.where((item) => item.grade < grade.clamp(1, 4)).toList();
    final pool = seed.abs() % 4 == 0 && earlier.isNotEmpty
        ? earlier
        : current.isNotEmpty
            ? current
            : available;
    final template = pool[_positive(seed ~/ 4, pool.length)];
    return template.concretize(
      seed ~/ (4 * pool.length) + (seed % 4) * 997 + template.id.hashCode,
    );
  }

  static const Map<String, List<String>> _legacyUnitAliases =
      <String, List<String>>{
    'Anfangslaute': <String>['Anfangslaute', 'Buchstaben-Lautierung'],
    'Endlaute': <String>['Endlaute'],
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
  const GermanTaskTemplate(
      {required this.id,
      required this.grade,
      required this.unit,
      required this.kind,
      required this.promptPattern});

  final String id;
  final int grade;
  final String unit;
  final GermanTemplateKind kind;
  final String promptPattern;

  GermanConcreteTask concretize(int seed) {
    switch (kind) {
      case GermanTemplateKind.letterSound:
        final entry = _letterSounds[_positive(seed, _letterSounds.length)];
        return _choice(
            'Welche Buchstaben passen zum Laut „${entry.sound}“?',
            entry.letter,
            entry.choices,
            'Sprich den Laut langsam und suche den passenden Buchstaben.',
            'letters');
      case GermanTemplateKind.rhymeRecognition:
        final pair = PrimarySchoolWordData.rhymePairForSeed(seed);
        final excluded = <String>{
          ...pair.map((word) => word.toLowerCase()),
          ...PrimarySchoolWordData.rhymePartnersFor(pair.first)
        };
        final distractors = _nouns(seed, grade)
            .where((word) => !excluded.contains(word.toLowerCase()))
            .take(3)
            .toList();
        return _choice(
            'Was reimt sich auf ${pair.first}?',
            pair.last,
            <String>[pair.last, ...distractors],
            'Reimwörter klingen am Ende gleich.',
            'rhyme');
      case GermanTemplateKind.startSound:
        final word =
            PrimarySchoolWordData.firstSoundWordForGrade(grade, seed: seed) ??
                'Apfel';
        final first = PrimarySchoolWordData.initialSoundFor(word)!;
        return _choice(
            'Mit welchem Laut beginnt $word?',
            first,
            _letterChoices(first, seed),
            'Sprich $word langsam. Der erste Laut ist $first.',
            'sound');
      case GermanTemplateKind.endSound:
        final word =
            PrimarySchoolWordData.endSoundWordForGrade(grade, seed: seed) ??
                'Stift';
        final last = PrimarySchoolWordData.finalSoundFor(word)!;
        return _choice(
            'Mit welchem Laut endet $word?',
            last,
            _letterChoices(last, seed + 11),
            'Sprich $word langsam. Der letzte Laut ist $last.',
            'sound');
      case GermanTemplateKind.wordImage:
        final words = _wordImages.keys.toList(growable: false);
        final word = words[_positive(seed, words.length)];
        return _choice(
            'Welches Wort passt zum Bild: ${_wordImages[word]}?',
            word,
            <String>[
              word,
              ...List<String>.generate(
                      words.length,
                      (index) =>
                          words[_positive(seed + index + 1, words.length)])
                  .where((item) => item != word)
                  .take(3)
            ],
            'Verbinde das Bild mit dem passenden Namenwort.',
            'word_image');
      case GermanTemplateKind.sentenceOrder:
        final item = _sentenceActors[_positive(seed, _sentenceActors.length)];
        final noun = item[1];
        final article = item[0];
        final verb = item[2];
        final correct = '${_cap(article)} $noun $verb.';
        return _choice(
            'Welcher Aussagesatz ist richtig?',
            correct,
            <String>[
              correct,
              '$noun $article $verb.',
              '$verb $article $noun.',
              '${_cap(article)} $verb $noun.'
            ],
            'In diesen kurzen Aussagesätzen steht zuerst, wer etwas tut. Danach steht das Tunwort.',
            'sentence');
      case GermanTemplateKind.syllables:
        final word = _wordWithSyllables(seed, grade);
        final syllables =
            PrimarySchoolWordData.syllablesFor(word) ?? <String>[word];
        return _choice(
            'Wie viele Silben hat $word?',
            '${syllables.length}',
            <String>[
              '${syllables.length}',
              '${syllables.length + 1}',
              '${syllables.length == 1 ? 3 : syllables.length - 1}'
            ],
            'Klatsche jede Silbe: ${syllables.join(' - ')}.',
            'syllables');
      case GermanTemplateKind.article:
        final nouns = PrimarySchoolWordData.nounsForGrade(grade)
            .where((word) =>
                PrimarySchoolWordData.categoryFor(word) != 'Österreich')
            .toList(growable: false);
        final noun = nouns[_positive(seed, nouns.length)];
        final answer = PrimarySchoolWordData.articleFor(noun)!;
        return _choice(
            'Welcher Artikel passt zu $noun?',
            answer,
            <String>['der', 'die', 'das'],
            'Sprich Artikel und Wort zusammen: $answer $noun.',
            'article');
      case GermanTemplateKind.wordFamily:
        final family = _families[_positive(seed, _families.length)];
        return _choice(
            'Welche Wörter gehören zur Wortfamilie „${family.root}“?',
            family.answer,
            <String>[family.answer, ...family.distractors],
            'Wortfamilien haben denselben Wortstamm.',
            'family');
      case GermanTemplateKind.plural:
        final item = _plurals[_positive(seed, _plurals.length)];
        return _choice(
            'Welche Mehrzahl ist richtig: ${item.singular}?',
            item.plural,
            <String>[item.plural, ...item.distractors],
            'Die Mehrzahl sagt: mehr als eines.',
            'plural');
      case GermanTemplateKind.diminutive:
        final item = _diminutives[_positive(seed, _diminutives.length)];
        return _choice(
            'Was ist die Verkleinerungsform von ${item.base}?',
            item.answer,
            <String>[item.answer, ...item.distractors],
            'Verkleinerungen enden oft auf -chen oder -lein.',
            'diminutive');
      case GermanTemplateKind.opposites:
        final item = _opposites[_positive(seed, _opposites.length)];
        return _choice(
            'Was ist das Gegenteil von ${item.left}?',
            item.right,
            <String>[item.right, ...item.distractors],
            'Gegenteile beschreiben die andere Seite einer Eigenschaft.',
            'opposite');
      case GermanTemplateKind.categories:
        final item = _categories[_positive(seed, _categories.length)];
        return _choice(
            'Was ist der Oberbegriff für ${item.examples.join(', ')}?',
            item.category,
            <String>[item.category, ...item.distractors],
            'Ein Oberbegriff fasst mehrere passende Wörter zusammen.',
            'category');
      case GermanTemplateKind.synonyms:
        final item = _synonyms[_positive(seed, _synonyms.length)];
        return _choice(
            'Welches Wort bedeutet dasselbe wie ${item.left}?',
            item.right,
            <String>[item.right, ...item.distractors],
            'Synonyme haben eine ähnliche Bedeutung.',
            'synonym');
      case GermanTemplateKind.wordTypes:
        final selector = promptPattern.contains('nomen')
            ? 0
            : promptPattern.contains('verb')
                ? 1
                : promptPattern.contains('adjektiv')
                    ? 2
                    : _positive(seed, 3);
        if (selector == 0) {
          final answer = PrimarySchoolWordData.nounForGrade(grade, seed);
          return _choice(
              'Welches Wort ist ein Namenwort?',
              answer,
              <String>[
                answer,
                PrimarySchoolWordData.verbForGrade(grade, seed + 1),
                PrimarySchoolWordData.adjectiveForGrade(grade, seed + 2)
              ],
              'Namenwörter bezeichnen Menschen, Tiere, Pflanzen und Dinge.',
              'word_type');
        }
        if (selector == 1) {
          final answer = PrimarySchoolWordData.verbForGrade(grade, seed);
          return _choice(
              'Welches Wort ist ein Tunwort?',
              answer,
              <String>[
                answer,
                PrimarySchoolWordData.nounForGrade(grade, seed + 1),
                PrimarySchoolWordData.adjectiveForGrade(grade, seed + 2)
              ],
              'Tunwörter sagen, was jemand macht.',
              'word_type');
        }
        final answer = PrimarySchoolWordData.adjectiveForGrade(grade, seed);
        return _choice(
            'Welches Wort ist ein Wiewort?',
            answer,
            <String>[
              answer,
              PrimarySchoolWordData.nounForGrade(grade, seed + 1),
              PrimarySchoolWordData.verbForGrade(grade, seed + 2)
            ],
            'Wiewörter beschreiben Eigenschaften.',
            'word_type');
      case GermanTemplateKind.pastTense:
        final item = _pastTenses[_positive(seed, _pastTenses.length)];
        return _choice(
            'Wie heißt „${item.left}“ in der Mitvergangenheit (Präteritum)?',
            item.right,
            <String>[item.right, ...item.distractors],
            'Die Mitvergangenheit (Präteritum) erzählt von früher: Er ging, er lief, er sah.',
            'tense');
      case GermanTemplateKind.comparison:
        final item = _comparisons[_positive(seed, _comparisons.length)];
        return _choice(
            'Welche beiden Steigerungsformen gehören zu „${item.base}“?',
            item.answer,
            <String>[item.answer, ...item.distractors],
            'Viele Wiewörter steigern wir mit -er und „am …sten“.',
            'comparison');
      case GermanTemplateKind.verbForm:
        final item = _verbForms[_positive(seed, _verbForms.length)];
        return _choice(
            '${item.prompt}',
            item.answer,
            <String>[item.answer, ...item.distractors],
            'Das Tunwort muss zur Person passen.',
            'verb_form');
      case GermanTemplateKind.sentenceParts:
        final item = _sentenceParts[_positive(seed, _sentenceParts.length)];
        return _choice(
            'Lies: „${item.sentence}“ Welche Wörter antworten auf „${item.question}“?',
            item.answer,
            <String>[item.answer, ...item.distractors],
            'Frage nach dem Satzglied, dann findest du es leichter.',
            'sentence_part');
      case GermanTemplateKind.directSpeech:
        final item = _directSpeech[_positive(seed, _directSpeech.length)];
        return _choice(
            'Wo steht die wörtliche Rede in Anführungszeichen und der Begleitsatz außerhalb?',
            item.answer,
            <String>[item.answer, ...item.distractors],
            'Direkte Rede steht in Anführungszeichen und wird mit Begleitsatz verbunden.',
            'direct_speech');
      case GermanTemplateKind.commas:
        final item = _commas[_positive(seed, _commas.length)];
        return _choice(
            'Wo steht das Komma richtig?',
            item.answer,
            <String>[item.answer, ...item.distractors],
            'Bei Aufzählungen trennen Kommas die einzelnen Wörter.',
            'comma');
      case GermanTemplateKind.compounds:
        final item = _compounds[_positive(seed, _compounds.length)];
        return _choice(
            'Was bedeutet „${item.compound}“?',
            item.answer,
            <String>[item.answer, ...item.distractors],
            'Zusammensetzungen verbinden zwei Wörter zu einem neuen Wort.',
            'compound');
      case GermanTemplateKind.caseNomAkk:
        final item = _caseNomAkkItems[_positive(seed, _caseNomAkkItems.length)];
        return _choice(
          'Welcher Fall ist „${item.phrase}“ im Satz „${item.sentence}“?',
          item.answer,
          <String>[item.answer, ...item.distractors],
          'Frage „Wer/Was?“ für den Wer-Fall (Nominativ), „Wen/Was?“ für den Wen-Fall (Akkusativ).',
          'case',
        );
      case GermanTemplateKind.capitalization:
        final item =
            _capitalizationItems[_positive(seed, _capitalizationItems.length)];
        return _choice(
          'Welches kleingeschriebene Namenwort musst du verbessern? „${item.sentence}“',
          item.answer,
          <String>[item.answer, ...item.distractors],
          'Nomen (Namenwörter) und Satzanfänge schreibt man immer groß.',
          'capitalization',
        );
      case GermanTemplateKind.ieOrI:
        final item = _ieOrIItems[_positive(seed, _ieOrIItems.length)];
        return _choice(
          'Wie schreibt man das Wort richtig?',
          item.answer,
          <String>[item.answer, ...item.distractors],
          'Bei lang gesprochenem i schreibt man meist „ie“ (Tier, Brief). Kurz gesprochenes i bleibt „i“.',
          'spelling',
        );
      case GermanTemplateKind.fourCases:
        final item = _fourCasesItems[_positive(seed, _fourCasesItems.length)];
        return _choice(
          'Welcher Fall? „${item.phrase}“ im Satz „${item.sentence}“',
          item.answer,
          <String>[item.answer, ...item.distractors],
          'Wer/Was = 1. Fall, Wessen = 2. Fall, Wem = 3. Fall, Wen/Was = 4. Fall.',
          'case',
        );
      case GermanTemplateKind.dassDas:
        final item = _dassDasItems[_positive(seed, _dassDasItems.length)];
        return _choice(
          'Welches Wort passt? „${item.sentence}“',
          item.answer,
          <String>[item.answer, ...item.distractors],
          '„Das“ kannst du hier durch „dieses“ oder „welches“ ersetzen. „Dass“ verbindet Sätze, zum Beispiel: Ich hoffe, dass du kommst.',
          'dass_das',
        );
      case GermanTemplateKind.adverbs:
        final item = _adverbItems[_positive(seed, _adverbItems.length)];
        return _choice(
          'Welches Wort sagt hier, wann, wie oft oder wo etwas passiert? „${item.sentence}“',
          item.answer,
          <String>[item.answer, ...item.distractors],
          'Diese Umstandswörter (Adverbien) nennen eine Zeit oder einen Ort: heute, morgen, draußen, dort.',
          'adverb',
        );
      case GermanTemplateKind.plusquamperfect:
        final item = _plusquamItems[_positive(seed, _plusquamItems.length)];
        return _choice(
          'Er … Welche Form von „${item.verb}“ steht in der Vorvergangenheit (Plusquamperfekt)?',
          item.answer,
          <String>[item.answer, ...item.distractors],
          'Die Vorvergangenheit bildet man mit „hatte/war“ und dem Partizip: Als ich kam, hatte er schon gegessen.',
          'tense',
        );
    }
  }

  List<String> _letterChoices(String answer, int seed) {
    const bank = <String>[
      'A',
      'B',
      'D',
      'E',
      'F',
      'I',
      'K',
      'L',
      'M',
      'N',
      'R',
      'S',
      'T',
      'W',
      'Sch',
      'Ch',
      'Au',
      'U'
    ];
    final normalized = answer.toLowerCase();
    final result = <String>[answer];
    for (var i = 0; result.length < 4 && i < bank.length; i++) {
      final candidate = bank[_positive(seed + i * 5, bank.length)];
      if (candidate.toLowerCase() != normalized &&
          !result
              .any((item) => item.toLowerCase() == candidate.toLowerCase())) {
        result.add(candidate);
      }
    }
    return result;
  }

  GermanConcreteTask _choice(String prompt, String answer,
      List<String> rawChoices, String explanation, String visual) {
    final choices = <String>[answer];
    for (final choice in rawChoices) {
      if (choice.trim().isNotEmpty &&
          choice != answer &&
          !choices.contains(choice)) choices.add(choice);
      if (choices.length == 4) break;
    }
    assert(choices.length >= 3,
        'Deutschaufgaben benötigen echte Antwortmöglichkeiten.');
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
  const GermanConcreteTask(
      {required this.unit,
      required this.prompt,
      required this.answer,
      required this.choices,
      required this.explanation,
      required this.visual,
      required this.difficulty,
      required this.promptPattern});

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
  endSound,
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
  // AT-Lehrplan-Erweiterungen 2026-06-03 (Klassen 3 + 4):
  caseNomAkk,
  capitalization,
  ieOrI,
  fourCases,
  dassDas,
  adverbs,
  plusquamperfect,
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
  const _SentencePartItem(
      this.sentence, this.question, this.answer, this.distractors);
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

// AT-Lehrplan-Erweiterungen 2026-06-03 - Klasse 3+4 Datenklassen:

class _CaseItem {
  const _CaseItem(this.sentence, this.phrase, this.answer, this.distractors);
  final String sentence;
  final String phrase;
  final String answer;
  final List<String> distractors;
}

class _SentenceMcItem {
  const _SentenceMcItem(this.sentence, this.answer, this.distractors);
  final String sentence;
  final String answer;
  final List<String> distractors;
}

class _SimpleMcItem {
  const _SimpleMcItem(this.answer, this.distractors);
  final String answer;
  final List<String> distractors;
}

class _VerbFormMcItem {
  const _VerbFormMcItem(this.verb, this.answer, this.distractors);
  final String verb;
  final String answer;
  final List<String> distractors;
}

const List<_LetterSound> _letterSounds = <_LetterSound>[
  _LetterSound('mmmm', 'M', <String>['M', 'N', 'W', 'B']),
  _LetterSound('ssss', 'S', <String>['S', 'F', 'Sch', 'Z']),
  _LetterSound('schhhh', 'Sch', <String>['Sch', 'S', 'Ch', 'Sp']),
  _LetterSound('ffff', 'F', <String>['F', 'W', 'M', 'S']),
  _LetterSound('rrrr', 'R', <String>['R', 'L', 'N', 'M']),
  _LetterSound('aaaa', 'A', <String>['A', 'O', 'E', 'U']),
];

const List<_FamilyItem> _families = <_FamilyItem>[
  _FamilyItem('fahr', 'fahren, Fahrrad, Fahrer', <String>[
    'malen, Maler, Bild',
    'lesen, Buch, leise',
    'Wasser, Wolke, Wind'
  ]),
  _FamilyItem('spiel', 'spielen, Spiel, Spielzeug', <String>[
    'laufen, Läufer, schnell',
    'Schule, Tafel, Kreide',
    'Apfel, Birne, Obst'
  ]),
  _FamilyItem('mal', 'malen, Maler, Gemälde', <String>[
    'fahren, Bus, Straße',
    'singen, Lied, Ton',
    'rechnen, Zahl, Plus'
  ]),
  _FamilyItem('les', 'lesen, Leser, Lesebuch', <String>[
    'springen, Seil, Turnsaal',
    'essen, Teller, Suppe',
    'gehen, Weg, Schuh'
  ]),
];

const List<_PluralItem> _plurals = <_PluralItem>[
  _PluralItem(
      'der Hund', 'die Hunde', <String>['die Hunden', 'die Hund', 'der Hunde']),
  _PluralItem('die Katze', 'die Katzen',
      <String>['die Kätze', 'die Katze', 'der Katzen']),
  _PluralItem('das Buch', 'die Bücher',
      <String>['die Buche', 'die Bucher', 'das Bücher']),
  _PluralItem('der Apfel', 'die Äpfel',
      <String>['die Apfels', 'die Apfeln', 'der Äpfel']),
  _PluralItem('die Semmel', 'die Semmeln',
      <String>['die Semmels', 'der Semmeln', 'die Semmel']),
  _PluralItem('das Kind', 'die Kinder',
      <String>['die Kinde', 'die Kinds', 'das Kinder']),
  _PluralItem(
      'der Baum', 'die Bäume', <String>['die Baume', 'die Baums', 'der Bäume']),
  _PluralItem('die Schule', 'die Schulen',
      <String>['die Schules', 'der Schulen', 'die Schule']),
];

const List<_DiminutiveItem> _diminutives = <_DiminutiveItem>[
  _DiminutiveItem('Buch', 'Büchlein', <String>['Bucher', 'Buchig', 'Buchung']),
  _DiminutiveItem('Haus', 'Häuschen', <String>['Hauser', 'Hauslein', 'Häuser']),
  _DiminutiveItem('Maus', 'Mäuschen', <String>['Mäuser', 'Mausen', 'Mauslein']),
  _DiminutiveItem(
      'Katze', 'Kätzchen', <String>['Katzen', 'Katzlein', 'Katzung']),
  _DiminutiveItem('Hund', 'Hündchen', <String>['Hunde', 'Hundchen', 'Hundung']),
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
  _CategoryItem(<String>['Apfel', 'Banane', 'Birne'], 'Obst',
      <String>['Werkzeug', 'Kleidung', 'Verkehr']),
  _CategoryItem(<String>['Hund', 'Katze', 'Hase'], 'Tiere',
      <String>['Pflanzen', 'Möbel', 'Gefühle']),
  _CategoryItem(<String>['Hammer', 'Säge', 'Zange'], 'Werkzeug',
      <String>['Obst', 'Schulsachen', 'Sport']),
  _CategoryItem(<String>['Hose', 'Jacke', 'Schuh'], 'Kleidung',
      <String>['Getränke', 'Wetter', 'Zahlen']),
  _CategoryItem(<String>['Bus', 'Zug', 'Auto'], 'Fahrzeuge',
      <String>['Blumen', 'Körperteile', 'Berufe']),
  _CategoryItem(<String>['Semmel', 'Topfen', 'Marille'], 'Lebensmittel',
      <String>['Werkzeuge', 'Verkehrszeichen', 'Formen']),
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
  _PairItem('gehen', 'ging', <String>['gehte', 'geht', 'gehen']),
  _PairItem('laufen', 'lief', <String>['laufte', 'läuft', 'gelauft']),
  _PairItem('sehen', 'sah', <String>['sehte', 'sieht', 'geseht']),
  _PairItem('kommen', 'kam', <String>['kommte', 'kommt', 'gekommt']),
  _PairItem('essen', 'aß', <String>['esste', 'isst', 'geesst']),
  _PairItem(
      'schreiben', 'schrieb', <String>['schreibte', 'schreibt', 'geschreibt']),
];

const List<_ComparisonItem> _comparisons = <_ComparisonItem>[
  _ComparisonItem('schön', 'schöner, am schönsten',
      <String>['schön, am schöner', 'schönste, schöner', 'schöner, am schön']),
  _ComparisonItem('schnell', 'schneller, am schnellsten', <String>[
    'schnell, am schneller',
    'schnellst, schneller',
    'schneller, am schnell'
  ]),
  _ComparisonItem('groß', 'größer, am größten',
      <String>['großer, am großten', 'groß, am größer', 'größte, größer']),
  _ComparisonItem('gut', 'besser, am besten',
      <String>['guter, am gutsten', 'guter, am besten', 'besser, am gutesten']),
  _ComparisonItem('viel', 'mehr, am meisten', <String>[
    'vieler, am vielsten',
    'mehr, am vielsten',
    'viele, am meisten'
  ]),
];

const List<_VerbFormItem> _verbForms = <_VerbFormItem>[
  _VerbFormItem('Wir _____ (gehen) in die Schule.', 'gehen',
      <String>['geht', 'gehe', 'gehst']),
  _VerbFormItem(
      'Du _____ (lesen) ein Buch.', 'liest', <String>['lesen', 'lese', 'lest']),
  _VerbFormItem('Ich _____ (spielen) im Garten.', 'spiele',
      <String>['spielst', 'spielt', 'spielen']),
  _VerbFormItem('Lena _____ (rechnen) die Aufgabe.', 'rechnet',
      <String>['rechne', 'rechnen', 'rechnest']),
  _VerbFormItem('Ihr _____ (singen) ein Lied.', 'singt',
      <String>['singe', 'singen', 'singst']),
];

const List<_SentencePartItem> _sentenceParts = <_SentencePartItem>[
  _SentencePartItem('Lena liest am Nachmittag ein Buch.', 'Wer?', 'Lena',
      <String>['liest', 'am Nachmittag', 'ein Buch']),
  _SentencePartItem('Der Hund bellt im Garten.', 'Was tut er?', 'bellt',
      <String>['Der Hund', 'im Garten', 'laut']),
  _SentencePartItem('Opa fährt mit dem Zug nach Wien.', 'Wohin?', 'nach Wien',
      <String>['Opa', 'fährt', 'mit dem Zug']),
  _SentencePartItem('Im Winter rodeln die Kinder am Hügel.', 'Wann?',
      'Im Winter', <String>['die Kinder', 'am Hügel', 'rodeln']),
];

const List<_DirectSpeechItem> _directSpeech = <_DirectSpeechItem>[
  _DirectSpeechItem('Lena sagt: „Ich komme gleich.“', <String>[
    'Lena sagt Ich komme gleich.',
    '„Lena sagt: Ich komme gleich.“',
    'Lena sagt: Ich komme gleich.'
  ]),
  _DirectSpeechItem('„Ich habe Hunger“, sagt Tom.', <String>[
    'Ich habe Hunger, sagt Tom.',
    '„Ich habe Hunger, sagt Tom.“',
    'Ich habe Hunger sagt Tom.'
  ]),
  _DirectSpeechItem('Mama fragt: „Kommst du mit?“', <String>[
    'Mama fragt Kommst du mit?',
    '„Mama fragt: Kommst du mit?“',
    'Mama fragt: Kommst du mit?'
  ]),
];

const List<_CommaItem> _commas = <_CommaItem>[
  _CommaItem('Ich packe Heft, Stift, Buch und Jause ein.', <String>[
    'Ich packe Heft Stift Buch und Jause ein.',
    'Ich packe Heft, Stift Buch und Jause ein.',
    'Ich packe Heft Stift, Buch, und Jause ein.'
  ]),
  _CommaItem('Wir kaufen Äpfel, Birnen, Semmeln und Topfen.', <String>[
    'Wir kaufen Äpfel Birnen Semmeln und Topfen.',
    'Wir kaufen Äpfel, Birnen Semmeln und Topfen.',
    'Wir kaufen Äpfel Birnen, Semmeln, und Topfen.'
  ]),
  _CommaItem(
      'Im Federpennal sind Bleistift, Schere, Kleber und Lineal.', <String>[
    'Im Federpennal sind Bleistift Schere Kleber und Lineal.',
    'Im Federpennal sind Bleistift, Schere Kleber und Lineal.',
    'Im Federpennal sind Bleistift Schere, Kleber, und Lineal.'
  ]),
];

const List<_CompoundItem> _compounds = <_CompoundItem>[
  _CompoundItem(
      'Sonnenblume', 'eine Pflanze mit großen gelben Blüten', <String>[
    'eine Sonne aus Blumen',
    'eine Blume ohne Licht',
    'ein Tier im Garten'
  ]),
  _CompoundItem('Schultasche', 'eine Tasche für die Schule', <String>[
    'eine Schule in einer Tasche',
    'eine Tasche für Tiere',
    'eine Tasche aus Papier'
  ]),
  _CompoundItem('Wasserflasche', 'eine Flasche für Wasser', <String>[
    'Wasser in Form einer Flasche',
    'eine Flasche für Sand',
    'ein Spielzeug'
  ]),
  _CompoundItem('Bücherregal', 'ein Regal für Bücher', <String>[
    'ein Buch aus Holz',
    'ein Regal für Schuhe',
    'ein Heft mit Linien'
  ]),
  _CompoundItem('Verkehrsschild', 'ein Schild im Verkehr', <String>[
    'ein Verkehr aus Schildern',
    'ein Schild im Garten',
    'ein Spielplan'
  ]),
];

List<String> _nouns(int seed, int grade,
    {Set<String> except = const <String>{}}) {
  final source = PrimarySchoolWordData.nounsForGrade(grade);
  return List<String>.generate(
          source.length,
          (index) =>
              source[(index + _positive(seed, source.length)) % source.length])
      .where((word) => !except.contains(word))
      .toList(growable: false);
}

const List<List<String>> _sentenceActors = <List<String>>[
  <String>['das', 'Kind', 'lacht'],
  <String>['der', 'Hund', 'bellt'],
  <String>['die', 'Katze', 'schläft'],
  <String>['der', 'Vogel', 'singt'],
  <String>['die', 'Blume', 'blüht'],
  <String>['die', 'Sonne', 'scheint'],
  <String>['das', 'Auto', 'fährt'],
  <String>['die', 'Maus', 'frisst'],
  <String>['die', 'Biene', 'summt'],
  <String>['der', 'Fuchs', 'schleicht'],
  <String>['der', 'Hase', 'hüpft'],
  <String>['die', 'Kuh', 'frisst'],
];

String _wordWithSyllables(int seed, int grade) {
  final words = PrimarySchoolWordData.nounsForGrade(grade)
      .where(
          (word) => (PrimarySchoolWordData.syllablesFor(word)?.length ?? 0) > 0)
      .toList(growable: false);
  if (words.isEmpty) return PrimarySchoolWordData.nounForGrade(grade, seed);
  return words[_positive(seed, words.length)];
}

const Map<String, String> _wordImages = <String, String>{
  'Hund': '🐶',
  'Katze': '🐱',
  'Maus': '🐭',
  'Hase': '🐰',
  'Fuchs': '🦊',
  'Kuh': '🐮',
  'Schwein': '🐷',
  'Biene': '🐝',
  'Apfel': '🍎',
  'Banane': '🍌',
  'Birne': '🍐',
  'Karotte': '🥕',
  'Baum': '🌳',
  'Auto': '🚗',
  'Bus': '🚌',
  'Buch': '📘',
  'Ball': '⚽',
  'Sonne': '☀️',
  'Mond': '🌙',
  'Haus': '🏠',
};

String _cap(String value) => value.isEmpty
    ? value
    : value.substring(0, 1).toUpperCase() + value.substring(1);
String _normalizeUnit(String value) =>
    value.replaceAll('ö', 'oe').replaceAll('ä', 'ae').replaceAll('ü', 'ue');
int _positive(int seed, int length) =>
    length <= 1 ? 0 : (seed & 0x7fffffff) % length;

// AT-Lehrplan-Erweiterungen 2026-06-03 - Klasse 3+4 Daten:

const List<_CaseItem> _caseNomAkkItems = <_CaseItem>[
  _CaseItem('Der Hund bellt im Garten.', 'Der Hund', 'Wer-Fall',
      <String>['Wen-Fall', 'Wem-Fall']),
  _CaseItem('Lisa füttert die Katze.', 'die Katze', 'Wen-Fall',
      <String>['Wer-Fall', 'Wem-Fall']),
  _CaseItem('Das Kind liest ein Buch.', 'Das Kind', 'Wer-Fall',
      <String>['Wen-Fall', 'Wem-Fall']),
  _CaseItem('Der Lehrer erklärt die Aufgabe.', 'die Aufgabe', 'Wen-Fall',
      <String>['Wer-Fall', 'Wem-Fall']),
  _CaseItem('Die Sonne scheint heute warm.', 'Die Sonne', 'Wer-Fall',
      <String>['Wen-Fall', 'Wem-Fall']),
  _CaseItem('Mama bäckt einen Kuchen.', 'einen Kuchen', 'Wen-Fall',
      <String>['Wer-Fall', 'Wem-Fall']),
];

const List<_SentenceMcItem> _capitalizationItems = <_SentenceMcItem>[
  _SentenceMcItem('Die kinder spielen im Garten.', 'Kinder',
      <String>['spielen', 'im', 'Die']),
  _SentenceMcItem(
      'Mein Bruder liest ein buch.', 'Buch', <String>['liest', 'ein', 'Mein']),
  _SentenceMcItem('Wir gehen heute in die schule.', 'Schule',
      <String>['gehen', 'heute', 'in']),
  _SentenceMcItem('Papa kocht die suppe für uns.', 'Suppe',
      <String>['kocht', 'für', 'uns']),
  _SentenceMcItem(
      'Der hund jagt eine Katze.', 'Hund', <String>['jagt', 'eine', 'Der']),
  _SentenceMcItem('Ich male einen schönen baum.', 'Baum',
      <String>['male', 'einen', 'schönen']),
];

const List<_SimpleMcItem> _ieOrIItems = <_SimpleMcItem>[
  _SimpleMcItem('Fisch', <String>['Fiesch', 'Fihsch', 'Fysch']),
  _SimpleMcItem('Kind', <String>['Kiend', 'Kihnd', 'Kynd']),
  _SimpleMcItem('Winter', <String>['Wienter', 'Wihnter', 'Wynter']),
  _SimpleMcItem('Kiste', <String>['Kieste', 'Kihste', 'Kyste']),
  _SimpleMcItem('Tier', <String>['Tir', 'Thier', 'Tyr']),
  _SimpleMcItem('Brief', <String>['Brif', 'Briff', 'Bryf']),
  _SimpleMcItem('viel', <String>['vil', 'viell', 'vihl']),
  _SimpleMcItem('Spiegel', <String>['Spigel', 'Spihgel', 'Schpiegel']),
  _SimpleMcItem('lieben', <String>['liben', 'lihben', 'lyben']),
  _SimpleMcItem('Knie', <String>['Kni', 'Knih', 'Kniee']),
  _SimpleMcItem('Sieg', <String>['Sig', 'Siegk', 'Siegge']),
  _SimpleMcItem('hier', <String>['hir', 'hihr', 'hiher']),
];

const List<_CaseItem> _fourCasesItems = <_CaseItem>[
  _CaseItem('Der Fuchs läuft durch den Wald.', 'Der Fuchs', 'Wer-Fall (1.)',
      <String>['Wessen-Fall (2.)', 'Wem-Fall (3.)', 'Wen-Fall (4.)']),
  _CaseItem('Das Kind zeichnet ein Haus.', 'Das Kind', 'Wer-Fall (1.)',
      <String>['Wessen-Fall (2.)', 'Wem-Fall (3.)', 'Wen-Fall (4.)']),
  _CaseItem('Der Bauer gibt der Kuh Heu.', 'der Kuh', 'Wem-Fall (3.)',
      <String>['Wer-Fall (1.)', 'Wen-Fall (4.)']),
  _CaseItem('Das Auto des Vaters ist rot.', 'des Vaters', 'Wessen-Fall (2.)',
      <String>['Wem-Fall (3.)', 'Wer-Fall (1.)']),
  _CaseItem('Anna schenkt ihrer Mutter Blumen.', 'ihrer Mutter',
      'Wem-Fall (3.)', <String>['Wessen-Fall (2.)', 'Wen-Fall (4.)']),
  _CaseItem('Wir besuchen die Großeltern.', 'die Großeltern', 'Wen-Fall (4.)',
      <String>['Wer-Fall (1.)', 'Wem-Fall (3.)']),
  _CaseItem('Die Tür des Hauses ist offen.', 'des Hauses', 'Wessen-Fall (2.)',
      <String>['Wer-Fall (1.)', 'Wen-Fall (4.)']),
  _CaseItem('Die Lehrerin lobt den Schüler.', 'den Schüler', 'Wen-Fall (4.)',
      <String>['Wer-Fall (1.)', 'Wem-Fall (3.)']),
];

const List<_SentenceMcItem> _dassDasItems = <_SentenceMcItem>[
  _SentenceMcItem('Ich weiß, ___ du gewinnst.', 'dass', <String>['das', 'daß']),
  _SentenceMcItem('___ Buch liegt am Tisch.', 'Das', <String>['Dass', 'Daß']),
  _SentenceMcItem(
      'Mama hofft, ___ es nicht regnet.', 'dass', <String>['das', 'daß']),
  _SentenceMcItem('Ich nehme ___ rote Heft.', 'das', <String>['dass', 'daß']),
  _SentenceMcItem('Er sagt, ___ er müde ist.', 'dass', <String>['das', 'daß']),
  _SentenceMcItem(
      'Ich sehe, ___ Lumo dort schläft.', 'dass', <String>['das', 'daß']),
];

const List<_SentenceMcItem> _adverbItems = <_SentenceMcItem>[
  _SentenceMcItem('Wir spielen heute Fußball.', 'heute',
      <String>['Wir', 'spielen', 'Fußball']),
  _SentenceMcItem(
      'Lumo wartet draußen.', 'draußen', <String>['Lumo', 'wartet']),
  _SentenceMcItem('Morgen kommt Oma zu Besuch.', 'Morgen',
      <String>['Oma', 'kommt', 'Besuch']),
  _SentenceMcItem(
      'Der Hund schläft dort.', 'dort', <String>['Der', 'Hund', 'schläft']),
  _SentenceMcItem(
      'Wir gehen oft schwimmen.', 'oft', <String>['Wir', 'gehen', 'schwimmen']),
  _SentenceMcItem('Anna bleibt hier.', 'hier', <String>['Anna', 'bleibt']),
];

const List<_VerbFormMcItem> _plusquamItems = <_VerbFormMcItem>[
  _VerbFormMcItem(
      'lesen', 'hatte gelesen', <String>['liest', 'las', 'wird lesen']),
  _VerbFormMcItem(
      'gehen', 'war gegangen', <String>['geht', 'ging', 'wird gehen']),
  _VerbFormMcItem('schreiben', 'hatte geschrieben',
      <String>['schreibt', 'schrieb', 'wird schreiben']),
  _VerbFormMcItem(
      'kommen', 'war gekommen', <String>['kommt', 'kam', 'wird kommen']),
  _VerbFormMcItem('spielen', 'hatte gespielt',
      <String>['spielt', 'spielte', 'wird spielen']),
  _VerbFormMcItem(
      'singen', 'hatte gesungen', <String>['singt', 'sang', 'wird singen']),
];
