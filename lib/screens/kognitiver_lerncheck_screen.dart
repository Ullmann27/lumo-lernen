import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KognitiverLernCheckScreen extends StatefulWidget {
  const KognitiverLernCheckScreen({super.key});

  @override
  State<KognitiverLernCheckScreen> createState() =>
      _KognitiverLernCheckScreenState();
}

class _KognitiverLernCheckScreenState
    extends State<KognitiverLernCheckScreen> with SingleTickerProviderStateMixin {
  int _currentQuestion = 0;
  final Map<int, int> _answers = {};

  late final AnimationController _resultController;
  late final Animation<double> _resultScale;
  late final Animation<double> _resultOpacity;

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

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
    _resultOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  void _answer(int optionIndex) {
    setState(() {
      _answers[_currentQuestion] = optionIndex;
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _resultController.forward(from: 0);
      }
    });
  }

  String get _profile {
    if (_answers.length < _questions.length) return '';
    final avg = _answers.values.reduce((a, b) => a + b) / _answers.length;
    if (avg <= 1) return 'Stark 💪';
    if (avg <= 2) return 'Gut 👍';
    return 'Mit Unterstützung 🤝';
  }

  Color get _profileColor {
    if (_answers.isEmpty) return AppTheme.orange;
    final avg = _answers.values.reduce((a, b) => a + b) / _answers.length;
    if (avg <= 1) return AppTheme.softGreen;
    if (avg <= 2) return AppTheme.turquoise;
    return AppTheme.orange;
  }

  @override
  Widget build(BuildContext context) {
    final done = _answers.length == _questions.length;
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: done ? _buildResult() : _buildQuestion(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD166), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🧠 Kognitiver Lern-Check',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _buildStepDots(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDots() {
    return Row(
      children: List.generate(_questions.length, (i) {
        final isDone = i < _answers.length;
        final isCurrent =
            i == _currentQuestion && _answers.length < _questions.length;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 8,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.white
                  : isCurrent
                      ? Colors.white.withOpacity(0.6)
                      : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentQuestion];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frage ${_currentQuestion + 1} von ${_questions.length}',
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.yellow.withOpacity(0.3),
                AppTheme.orange.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.yellow.withOpacity(0.4)),
          ),
          child: Text(
            q['text'] as String,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 24),
        ...(q['options'] as List<String>).asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _answer(entry.key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D2D2D),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(entry.value,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: const Row(
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dies ist kein IQ-Test. Lumo erstellt ein Unterstützungsprofil.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return FadeTransition(
      opacity: _resultOpacity,
      child: ScaleTransition(
        scale: _resultScale,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _profileColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _profileColor, width: 3),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dein Lernprofil:',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                _profile,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _profileColor,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Lumo hat dein Profil gespeichert und passt deine Aufgaben an! 🦊',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _currentQuestion = 0;
                  _answers.clear();
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Neu starten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
