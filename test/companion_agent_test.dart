import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/services/companion_agent.dart';

void main() {
  group('CompanionAgent', () {
    test('has initial greeting message', () {
      final agent = CompanionAgent();
      expect(agent.messages, isNotEmpty);
      expect(agent.messages.first.isUser, isFalse);
    });

    test('handleInput adds user message and response', () {
      final agent = CompanionAgent();
      final before = agent.messages.length;
      agent.handleInput('Hallo');
      expect(agent.messages.length, equals(before + 2));
      expect(agent.messages[agent.messages.length - 2].isUser, isTrue);
      expect(agent.messages.last.isUser, isFalse);
    });

    test('responds to math topic', () {
      final agent = CompanionAgent();
      agent.handleInput('Ich will Mathe üben');
      final response = agent.messages.last.text;
      expect(response, isNotEmpty);
    });

    test('responds to help request', () {
      final agent = CompanionAgent();
      agent.handleInput('Ich brauche Hilfe');
      final response = agent.messages.last.text;
      expect(response, isNotEmpty);
    });

    test('user message content preserved', () {
      final agent = CompanionAgent();
      agent.handleInput('Buchstaben üben');
      final userMsg = agent.messages[agent.messages.length - 2];
      expect(userMsg.text, equals('Buchstaben üben'));
      expect(userMsg.isUser, isTrue);
    });
  });
}
