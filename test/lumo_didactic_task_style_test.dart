import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_didactic_task_style.dart';

void main() {
  group('LumoDidacticTaskStyles', () {
    test('core progressions are available', () {
      expect(LumoDidacticTaskStyles.germanProgression, isNotEmpty);
      expect(LumoDidacticTaskStyles.mathProgression, isNotEmpty);
      expect(LumoDidacticTaskStyles.scienceProgression, isNotEmpty);
    });

    test('style lookup returns expected visual types', () {
      final german = LumoDidacticTaskStyles.styleFor(
        domain: LumoLearningDomain.german,
        action: LumoLearningAction.buildWord,
      );
      final math = LumoDidacticTaskStyles.styleFor(
        domain: LumoLearningDomain.math,
        action: LumoLearningAction.completeToTen,
      );
      final science = LumoDidacticTaskStyles.styleFor(
        domain: LumoLearningDomain.science,
        action: LumoLearningAction.readFact,
      );

      expect(german.visualType, 'word_build');
      expect(math.visualType, 'ten_frame');
      expect(science.visualType, 'fact_card');
    });
  });
}
