import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/services/recognition_engine.dart';

void main() {
  group('RecognitionEngine', () {
    test('recognizes addition "12 + 7"', () {
      final result = RecognitionEngine.recognize('12 + 7');
      expect(result.type, equals('Addition'));
      expect(result.answer, equals('19'));
    });

    test('recognizes subtraction "18 - 5"', () {
      final result = RecognitionEngine.recognize('18 - 5');
      expect(result.type, equals('Subtraktion'));
      expect(result.answer, equals('13'));
    });

    test('recognizes number sequence "2, 4, 6, ?"', () {
      final result = RecognitionEngine.recognize('2, 4, 6, ?');
      expect(result.type, equals('Zahlenreihe'));
      expect(result.answer, equals('8'));
    });

    test('recognizes initial letter "Anfangsbuchstabe Mama"', () {
      final result = RecognitionEngine.recognize('Anfangsbuchstabe Mama');
      expect(result.type, equals('Anfangsbuchstabe'));
      expect(result.answer, equals('M'));
    });

    test('recognizes rhyme "Was reimt sich auf Haus?"', () {
      final result = RecognitionEngine.recognize('Was reimt sich auf Haus?');
      expect(result.type, equals('Reimwort'));
      expect(result.answer, isNotEmpty);
    });

    test('recognizes grade "Neue Note Mathe 2"', () {
      final result = RecognitionEngine.recognize('Neue Note Mathe 2');
      expect(result.type, equals('Note gespeichert'));
    });

    test('returns unknown for unrecognized input', () {
      final result = RecognitionEngine.recognize('blablabla xyz');
      expect(result.type, equals('Unbekannt'));
    });
  });
}
