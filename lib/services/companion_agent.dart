import 'package:flutter/foundation.dart';

class AgentMessage {
  final String text;
  final bool isUser;
  const AgentMessage({required this.text, required this.isUser});
}

class CompanionAgent extends ChangeNotifier {
  final List<AgentMessage> _messages = [
    const AgentMessage(
      text: 'Hallo! Ich bin Lumo 🦊 Ich helfe dir beim Lernen! Was möchtest du üben?',
      isUser: false,
    ),
  ];

  List<AgentMessage> get messages => List.unmodifiable(_messages);

  void handleInput(String input) {
    _messages.add(AgentMessage(text: input, isUser: true));
    final response = _generateSafeResponse(input.toLowerCase());
    _messages.add(AgentMessage(text: response, isUser: false));
    notifyListeners();
  }

  String _generateSafeResponse(String input) {
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
      return 'Kein Problem! Ich erkläre dir das Schritt für Schritt. Welche Aufgabe ist schwierig?';
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
    return 'Das ist eine tolle Frage! 🌟 Im Bereich "Lernen" kannst du passende Aufgaben finden. Soll ich dir eine zeigen?';
  }
}
