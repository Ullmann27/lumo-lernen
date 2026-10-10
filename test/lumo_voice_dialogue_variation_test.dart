import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning_modules/lumo_phrases.dart';

void main() {
  test('alle zwoelf Lobsprueche kommen vor einer Wiederholung', () {
    final cycle = List<String>.generate(12, (_) => LumoPhrases.correct());
    expect(cycle.toSet().length, 12);
    final firstNext = LumoPhrases.correct();
    expect(firstNext, isNot(cycle.last),
        reason: 'Keine direkte Wiederholung am Beginn eines neuen Durchlaufs');
  });

  test('Trost und Tipps wechseln ebenfalls die Formulierung', () {
    final help = List<String>.generate(5, (_) => LumoPhrases.hint());
    expect(help.toSet().length, 5);
    final comfort =
        List<String>.generate(5, (_) => LumoPhrases.comfort());
    expect(comfort.toSet().length, 5);
    final gentle =
        List<String>.generate(7, (_) => LumoPhrases.wrongGentle());
    expect(gentle.toSet().length, 7);
  });
}
