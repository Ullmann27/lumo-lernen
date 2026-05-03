import '../domain/reading/reading_domain.dart';

class ReadingTextCleaner {
  const ReadingTextCleaner();

  String sentence(String value) => value
      .replaceAll(RegExp(r'[.!?;:]+'), '')
      .replaceAll(RegExp(r'[„“"()]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Story cleanStory(Story story) {
    return Story(
      id: story.id,
      title: sentence(story.title),
      grade: story.grade,
      level: story.level,
      targetSkills: story.targetSkills,
      signature: story.signature,
      sentences: story.sentences.map((s) {
        final clean = sentence(s.text)
            .replaceAll('Neüs', 'Neues')
            .replaceAll('Baürnhof', 'Bauernhof')
            .replaceAll('genaüm Schaün', 'genauem Schauen')
            .replaceAll('Schaün', 'Schauen');
        return StorySentence(
          id: s.id,
          index: s.index,
          text: clean,
          words: const SyllableWordColorizer().tokenize(clean, problemWords: s.words.where((w) => w.isProblemWord).map((w) => w.text).toList(growable: false)),
        );
      }).toList(growable: false),
    );
  }
}
