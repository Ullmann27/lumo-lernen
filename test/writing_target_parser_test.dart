import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/writing_target_parser.dart';

void main() {
  group('WritingTargetParser', () {
    test('parses word prompts with and without colon', () {
      expect(WritingTargetParser.parse('Schreibe das Wort: Mama'), 'Mama');
      expect(WritingTargetParser.parse('Schreibe das Wort Banane.'), 'Banane');
      expect(WritingTargetParser.parse('Schreibe das Wort: „Lumo“'), 'Lumo');
      expect(WritingTargetParser.parse('Schreibe das Wort: „Fuchs“.'), 'Fuchs');
    });

    test('parses sentence and number prompts', () {
      expect(WritingTargetParser.parse('Schreibe: Lumo lernt.'), 'Lumo lernt.');
      expect(WritingTargetParser.parse('Schreibe den Satz: Lumo liest.'), 'Lumo liest.');
      expect(WritingTargetParser.parse('Schreibe die Zahl 7 schön und langsam.'), '7');
    });

    test('parses singular and plural letter prompts', () {
      expect(WritingTargetParser.parse('Buchstaben A'), 'A');
      expect(WritingTargetParser.parse('Buchstabe B'), 'B');
      expect(WritingTargetParser.parse('großes Ü'), 'Ü');
    });
  });
}
