import 'package:flutter/foundation.dart';
import 'learning_brain.dart';

class AgentMessage {
  final String text;
  final bool isUser;
  const AgentMessage({required this.text, required this.isUser});
}

class CompanionAgent extends ChangeNotifier {
  LearningBrain? _brain;

  final List<AgentMessage> _messages = [
    const AgentMessage(
      text: 'Hallo! Ich bin Lumo 🦊 Ich helfe dir beim Lernen! Was möchtest du üben?',
      isUser: false,
    ),
  ];

  List<AgentMessage> get messages => List.unmodifiable(_messages);

  /// Connect to LearningBrain so Lumo can give personalised hints.
  void attachBrain(LearningBrain brain) {
    _brain = brain;
  }

  void handleInput(String input) {
    _messages.add(AgentMessage(text: input, isUser: true));
    final response = _generateResponse(input.toLowerCase());
    _messages.add(AgentMessage(text: response, isUser: false));
    notifyListeners();
  }

  String _generateResponse(String input) {
    // Personalised suggestion based on known weak topics
    final weakTopics = _brain?.wrongTopics ?? [];

    if (weakTopics.isNotEmpty &&
        (input.contains('was') || input.contains('übe') ||
            input.contains('hilfe') || input.contains('tipp'))) {
      final topic = weakTopics.last;
      return 'Lumo weiß, dass "$topic" noch etwas schwierig ist. '
          'Ich empfehle dir, im "Lernen"-Bereich mehr "$topic"-Aufgaben zu üben! 🦊✨';
    }
    if (weakTopics.isNotEmpty && weakTopics.length >= 2) {
      if (input.contains('schwach') || input.contains('schlecht') ||
          input.contains('probleme')) {
        return 'Ich sehe, bei "${weakTopics.join('" und "')}" üben wir noch. '
            'Das schaffst du! 💪';
      }
    }

    if (input.contains('mathe') ||
        input.contains('rechnen') ||
        input.contains('+') ||
        input.contains('-')) {
      return 'Super! Mathe macht Spaß! 🔢 Soll ich dir eine Rechenaufgabe geben?';
    }
    if (input.contains('lesen') ||
        input.contains('buchstabe') ||
        input.contains('wort')) {
      return 'Toll! Lesen ist wichtig! 📚 Welches Wort möchtest du üben?';
    }
    if (input.contains('hilfe') ||
        input.contains('verstehe') ||
        input.contains('nicht')) {
      return 'Kein Problem! Ich erkläre dir das Schritt für Schritt. '
          'Welche Aufgabe ist schwierig?';
    }
    if (input.contains('hallo') ||
        input.contains('hi') ||
        input.contains('hey')) {
      return 'Hallo! 🦊 Schön, dass du da bist! Womit soll ich dir heute helfen?';
    }
    if (input.contains('danke')) {
      return 'Gern geschehen! Du machst das super! ⭐';
    }
    if (input.contains('müde') || input.contains('pause')) {
      return 'Eine kurze Pause ist gut! 😊 Komm dann wieder, wenn du ausgeruht bist!';
    }
    if (input.length < 3) {
      return 'Hm, kannst du das etwas genauer sagen? 🦊';
    }

    // Fallback: personalised if we know weak areas
    if (weakTopics.isNotEmpty) {
      return 'Das ist eine tolle Frage! 🌟 Übrigens: bei "${weakTopics.last}" '
          'kannst du noch stärker werden. Soll ich dir helfen?';
    }
    return 'Das ist eine tolle Frage! 🌟 Im Bereich "Lernen" kannst du passende '
        'Aufgaben finden. Soll ich dir eine zeigen?';
  }
}
