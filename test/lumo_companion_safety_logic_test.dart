import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/companion/lumo_companion_core.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';

void main() {
  group('LumoCompanion safety routing', () {
    test('allows normal learning help for math tasks', () {
      final result = _engine().handleText(
        input: _input('Ich brauche Hilfe bei der Matheaufgabe'),
        context: _context(),
      );

      expect(result.safety.allowed, isTrue);
      expect(result.intent.intent, CompanionIntent.doesNotUnderstand);
      expect(result.plan.shouldStartTutoring, isTrue);
      expect(result.response.text, isNot(contains('Erwachsenen')));
    });

    test('asks clarification for isolated help', () {
      final result = _engine().handleText(
        input: _input('Hilfe'),
        context: _context(),
      );

      expect(result.safety.allowed, isTrue);
      expect(result.intent.intent, CompanionIntent.needsClarification);
      expect(result.plan.shouldStartTutoring, isFalse);
      expect(result.plan.shouldGenerateTask, isFalse);
      expect(result.response.text, 'Wobei brauchst du Hilfe? Geht es um eine Aufgabe oder fühlst du dich nicht gut?');
    });

    test('asks clarification for bare ich brauche hilfe', () {
      final result = _engine().handleText(
        input: _input('Ich brauche Hilfe'),
        context: _context(),
      );

      expect(result.safety.allowed, isTrue);
      expect(result.intent.intent, CompanionIntent.needsClarification);
      expect(result.response.visualAction, VisualActionType.foxThink);
    });

    test('triggers safety mode for fear and being alone', () {
      final result = _engine().handleText(
        input: _input('Ich habe Angst und bin allein zuhause'),
        context: _context(),
      );

      expect(result.safety.allowed, isFalse);
      expect(result.safety.riskLevel, SafetyRiskLevel.parentNeeded);
      expect(result.plan.intent, CompanionIntent.unsafe);
      expect(result.response.text, contains('Erwachsenen'));
    });

    test('triggers safety mode for injury', () {
      final result = _engine().handleText(
        input: _input('Ich bin verletzt und es hat wehgetan'),
        context: _context(),
      );

      expect(result.safety.allowed, isFalse);
      expect(result.safety.reason, 'wellbeing');
      expect(result.response.visualAction, VisualActionType.showCalmBreak);
    });
  });
}

LumoCompanionEngine _engine() => const LumoCompanionEngine();

ChildInput _input(String text) => ChildInput(
      childId: 'local_lena_1',
      type: ChildInputType.text,
      text: text,
      subject: LearningSubject.mathematik,
      skillId: const SkillId('math.addition'),
    );

CompanionContext _context() => const CompanionContext(
      memory: ChildLearningMemory(
        childId: 'local_lena_1',
        childName: 'Lena',
        grade: 1,
        weakSkills: <SkillId>[SkillId('math.addition')],
      ),
      activeSubject: LearningSubject.mathematik,
      activeSkill: SkillId('math.addition'),
    );
