import 'lumo_companion_agent.dart';

class LumoChildAiMessage {
  const LumoChildAiMessage({
    required this.fromChild,
    required this.text,
    required this.createdAt,
  });

  final bool fromChild;
  final String text;
  final DateTime createdAt;
}

class LumoChildAiResponse {
  const LumoChildAiResponse({
    required this.text,
    required this.topic,
    required this.safe,
    required this.suggestedEvent,
  });

  final String text;
  final String topic;
  final bool safe;
  final String suggestedEvent;
}

class LumoChildAi {
  LumoChildAi({LumoCompanionAgent? agent}) : _agent = agent ?? const LumoCompanionAgent();

  final LumoCompanionAgent _agent;
  final List<LumoChildAiMessage> _history = [];

  List<LumoChildAiMessage> get history => List.unmodifiable(_history);

  LumoChildAiResponse answer(String childText, {String currentSubject = 'Alle', Map<String, int> practice = const {}}) {
    final clean = childText.trim();
    if (clean.isEmpty) {
      return const LumoChildAiResponse(
        text: 'Ich bin da. Frag mich etwas zur Aufgabe oder such dir eine kleine Mission aus.',
        topic: 'empty',
        safe: true,
        suggestedEvent: 'idle',
      );
    }

    _history.add(LumoChildAiMessage(fromChild: true, text: clean, createdAt: DateTime.now()));
    final lower = clean.toLowerCase();
    final topic = _detectTopic(lower, currentSubject);
    final safe = !_isSensitive(lower);

    final answer = safe
        ? _answerByTopic(lower, topic, practice)
        : 'Das musst du mir nicht sagen. Frag bitte Mama, Papa oder einen vertrauten Erwachsenen. Ich helfe dir gern beim Lernen.';

    _history.add(LumoChildAiMessage(fromChild: false, text: answer, createdAt: DateTime.now()));
    if (_history.length > 16) _history.removeRange(0, _history.length - 16);

    return LumoChildAiResponse(
      text: answer,
      topic: topic,
      safe: safe,
      suggestedEvent: safe ? _eventForTopic(topic) : 'safety_redirect',
    );
  }

  String _answerByTopic(String lower, String topic, Map<String, int> practice) {
    if (topic == 'math_plus' || topic == 'math_minus' || topic == 'silben' || topic == 'reim' || topic == 'english' || topic == 'writing') {
      return _agent.answerChild(lower);
    }
    if (topic == 'help') return _agent.answerChild('hilfe');
    if (topic == 'pause') return _agent.reactToEvent('pause', practice: practice);
    if (topic == 'next') return _agent.nextSuggestion(practice);
    return _agent.answerChild(lower);
  }

  String _detectTopic(String lower, String currentSubject) {
    if (lower.contains('plus') || lower.contains('+')) return 'math_plus';
    if (lower.contains('minus') || lower.contains('-')) return 'math_minus';
    if (lower.contains('silbe')) return 'silben';
    if (lower.contains('reim')) return 'reim';
    if (lower.contains('englisch')) return 'english';
    if (lower.contains('schreib') || lower.contains('buchstabe')) return 'writing';
    if (lower.contains('hilfe') || lower.contains('versteh')) return 'help';
    if (lower.contains('pause') || lower.contains('muede')) return 'pause';
    if (lower.contains('weiter') || lower.contains('was soll')) return 'next';
    return currentSubject.toLowerCase();
  }

  String _eventForTopic(String topic) {
    if (topic == 'pause') return 'pause';
    if (topic == 'help' || topic.startsWith('math') || topic == 'silben' || topic == 'reim') return 'explain';
    return 'chat';
  }

  bool _isSensitive(String lower) {
    const blocked = ['adresse', 'telefon', 'passwort', 'wohnort', 'treffen', 'instagram', 'tiktok', 'snapchat'];
    return blocked.any(lower.contains);
  }
}
