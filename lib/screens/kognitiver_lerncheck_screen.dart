import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KognitiverLernCheckScreen extends StatefulWidget {
  const KognitiverLernCheckScreen({super.key});

  @override
  State<KognitiverLernCheckScreen> createState() =>
      _KognitiverLernCheckScreenState();
}

class _KognitiverLernCheckScreenState
    extends State<KognitiverLernCheckScreen> {
  int _currentQuestion = 0;
  final Map<int, int> _answers = {};

  static const List<Map<String, dynamic>> _questions = [
    {
      'text': 'Wie leicht fällt es dir, neue Wörter zu lesen?',
      'options': ['Sehr leicht', 'Leicht', 'Manchmal schwer', 'Sehr schwer'],
    },
    {
      'text': 'Wie gut kannst du Zahlen im Kopf zusammenzählen?',
      'options': ['Sehr gut', 'Gut', 'Geht so', 'Schwierig'],
    },
    {
      'text': 'Merkst du dir Geschichten gut?',
      'options': ['Sehr gut', 'Gut', 'Manchmal', 'Selten'],
    },
    {
      'text': 'Wie oft übst du zu Hause?',
      'options': ['Täglich', 'Oft', 'Manchmal', 'Selten'],
    },
  ];

  void _answer(int optionIndex) {
    setState(() {
      _answers[_currentQuestion] = optionIndex;
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      }
    });
  }

  String get _profile {
    if (_answers.length < _questions.length) return '';
    final avg = _answers.values.reduce((a, b) => a + b) / _answers.length;
    if (avg <= 1) return 'Stark';
    if (avg <= 2) return 'Gut';
    return 'Mit Unterstützung';
  }

  @override
  Widget build(BuildContext context) {
    final done = _answers.length == _questions.length;
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Kognitiver Lern-Check'),
        backgroundColor: AppTheme.yellow,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: done ? _buildResult() : _buildQuestion(),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentQuestion];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _currentQuestion / _questions.length,
          backgroundColor: Colors.grey.shade200,
          color: AppTheme.orange,
        ),
        const SizedBox(height: 24),
        Text(
          'Frage ${_currentQuestion + 1} von ${_questions.length}',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Text(
          q['text'] as String,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        ...(q['options'] as List<String>).asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _answer(entry.key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                    child: Text(entry.value),
                  ),
                ),
              ),
            ),
        const Spacer(),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'ℹ️ Dies ist kein IQ-Test. Lumo erstellt ein Unterstützungsprofil, um dir besser helfen zu können.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Dein Lernprofil:', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            _profile,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.orange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lumo hat dein Profil gespeichert und passt deine Aufgaben an! 🦊',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() {
              _currentQuestion = 0;
              _answers.clear();
            }),
            child: const Text('Neu starten'),
          ),
        ],
      ),
    );
  }
}
