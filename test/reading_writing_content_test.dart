import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/reading/reading_domain.dart';
import 'package:lumo_lernen/domain/writing/writing_word_bank.dart';
import 'package:lumo_lernen/features/reading/reading_text_library.dart';

/// Lese- und Schreibinhalte fuer Klasse 1-4: echte Rechtschreibung, genug Texte
/// und Diktatwoerter pro Klasse, Silben mit allen Vokalen.
void main() {
  test('Reading Buddy hat sechs Texte pro Klasse mit eindeutigen IDs', () {
    for (final grade in [1, 2, 3, 4]) {
      expect(ReadingTextLibrary.forGrade(grade), hasLength(6), reason: 'Klasse $grade');
    }
    final ids = ReadingTextLibrary.all.map((t) => t.id).toSet();
    expect(ids, hasLength(ReadingTextLibrary.all.length));
  });

  test('Lesetexte nutzen Umlaute und ß statt Ersatzschreibung', () {
    // Spracherkennung liefert echte Woerter; "Maeuse" oder "heisst" wuerden nie passen.
    const forbidden = [
      'bluehen', 'heisst', 'schlaeft', 'Maeuse', 'grossen', 'Baeckerei', 'Baeckerin',
      'frueh', 'Strasse', 'ueber', 'Laender', 'fliesst', 'Oesterreich', 'mundet',
    ];
    for (final text in ReadingTextLibrary.all) {
      final content = '${text.title} ${text.lines.join(' ')}';
      for (final word in forbidden) {
        expect(content.contains(word), isFalse, reason: '${text.id}: "$word"');
      }
    }
  });

  test('Schreibcoach hat Diktatwoerter fuer jede Klasse, nur A-Z', () {
    for (final grade in [1, 2, 3, 4]) {
      expect(WritingWordBank.forGrade(grade).length, greaterThanOrEqualTo(8), reason: 'Klasse $grade');
    }
    final ids = WritingWordBank.all.map((t) => t.id).toSet();
    expect(ids, hasLength(WritingWordBank.all.length));
    for (final task in WritingWordBank.all) {
      expect(task.word, matches(RegExp(r'^[A-Za-z]+$')), reason: task.id);
      expect(task.length, lessThanOrEqualTo(10), reason: '${task.id} passt auf die Schreiblinie');
      expect(task.spokenPrompt, contains(task.word));
    }
  });

  test('Silbentrennung erkennt a und e als Vokale', () {
    expect(SyllableWordColorizer.simpleSyllables('Banane'), ['Ba', 'na', 'ne']);
    expect(SyllableWordColorizer.simpleSyllables('Garten').length, greaterThan(1));
  });
}
