import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/learning_brain.dart';
import '../services/exercise_factory.dart';
import '../services/reward_orchestrator.dart';

class LernenScreen extends StatefulWidget {
  const LernenScreen({super.key});

  @override
  State<LernenScreen> createState() => _LernenScreenState();
}

class _LernenScreenState extends State<LernenScreen> {
  late Exercise _currentExercise;
  String? _selectedAnswer;
  bool? _isCorrect;
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    _currentExercise = ExerciseFactory.nextExercise();
  }

  void _onAnswerSelected(String answer) {
    if (_isCorrect != null) return;
    final brain = context.read<LearningBrain>();
    final correct = brain.checkAnswer(_currentExercise, answer);
    setState(() {
      _selectedAnswer = answer;
      _isCorrect = correct;
      if (!correct && brain.wrongAttempts >= 3) {
        _showExplanation = true;
      }
    });
    if (correct) {
      context.read<RewardOrchestrator>().addXP(10);
    }
  }

  void _nextExercise() {
    final brain = context.read<LearningBrain>();
    setState(() {
      if (_isCorrect == false && brain.wrongAttempts >= 3) {
        _currentExercise = brain.createFollowUpTask(_currentExercise);
        brain.resetWrongAttempts();
      } else {
        _currentExercise = ExerciseFactory.nextExercise();
        if (_isCorrect == true) brain.resetWrongAttempts();
      }
      _selectedAnswer = null;
      _isCorrect = null;
      _showExplanation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brain = context.watch<LearningBrain>();
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Lernen'),
        backgroundColor: AppTheme.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '❌ ${brain.wrongAttempts}/3',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildQuestionCard(),
              const SizedBox(height: 24),
              ..._currentExercise.options.map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAnswerButton(opt),
                ),
              ),
              if (_isCorrect != null) ...[
                const SizedBox(height: 16),
                _buildFeedback(),
              ],
              if (_showExplanation) ...[
                const SizedBox(height: 16),
                _buildExplanation(),
              ],
              if (_isCorrect != null || _showExplanation) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _nextExercise,
                  child: const Text('Weiter ➡️'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Card(
      color: AppTheme.lightBlue.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _currentExercise.subject,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              _currentExercise.question,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    Color bgColor = Colors.white;
    if (_selectedAnswer == option) {
      bgColor = _isCorrect == true ? AppTheme.softGreen : Colors.red.shade100;
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCorrect == null ? () => _onAnswerSelected(option) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: bgColor,
          disabledForegroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(option, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect == true
            ? AppTheme.softGreen.withOpacity(0.3)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _isCorrect == true ? AppTheme.softGreen : Colors.red.shade200),
      ),
      child: Text(
        _isCorrect == true
            ? '✅ Super gemacht! +10 XP'
            : '❌ Nicht ganz – versuch es nochmal!',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _isCorrect == true ? Colors.green.shade800 : Colors.red.shade800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildExplanation() {
    return Card(
      color: AppTheme.yellow.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Schritt-für-Schritt Erklärung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentExercise.explanation,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
