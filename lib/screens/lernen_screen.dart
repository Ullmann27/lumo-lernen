import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/class_settings.dart';
import '../services/learning_brain.dart';
import '../services/exercise_factory.dart';
import '../services/reward_orchestrator.dart';

// ── Schulheft ruled-paper background ─────────────────────────────────────────

class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.45)
      ..strokeWidth = 1.0;
    const lineSpacing = 28.0;
    const topOffset = 44.0;
    for (double y = topOffset; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    // Left margin red line
    final marginPaint = Paint()
      ..color = Colors.red.withOpacity(0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        const Offset(36, 0), Offset(36, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Main screen ───────────────────────────────────────────────────────────────

class LernenScreen extends StatefulWidget {
  const LernenScreen({super.key});

  @override
  State<LernenScreen> createState() => _LernenScreenState();
}

class _LernenScreenState extends State<LernenScreen>
    with SingleTickerProviderStateMixin {
  // Initialised with a placeholder; replaced in first addPostFrameCallback
  Exercise _currentExercise = ExerciseFactory.allExercises.first;
  String? _selectedAnswer;
  bool? _isCorrect;
  bool _showExplanation = false;

  // Track the last 8 question texts to avoid immediate repeats
  final _recentQuestions = <String>{};
  static const _recentCap = 8;

  late final AnimationController _feedbackController;
  late final Animation<double> _feedbackScale;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );
    // Defer reading context until after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNext();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _loadNext({bool followUp = false}) {
    final brain = context.read<LearningBrain>();
    final settings = context.read<ClassSettings>();
    Exercise next;
    if (followUp) {
      next = brain.createFollowUpTask(_currentExercise);
    } else {
      next = ExerciseFactory.randomForLevel(
        settings.level,
        recentQuestions: _recentQuestions,
      );
    }
    // Update recent set
    _recentQuestions.add(next.question);
    if (_recentQuestions.length > _recentCap) {
      _recentQuestions.remove(_recentQuestions.first);
    }
    setState(() {
      _currentExercise = next;
      _selectedAnswer = null;
      _isCorrect = null;
      _showExplanation = false;
    });
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
    _feedbackController.forward(from: 0);
    if (correct) {
      context.read<RewardOrchestrator>().addXP(10);
    }
  }

  void _nextExercise() {
    final brain = context.read<LearningBrain>();
    final followUp = _isCorrect == false && brain.wrongAttempts >= 3;
    if (!followUp && _isCorrect == true) brain.resetWrongAttempts();
    if (followUp) brain.resetWrongAttempts();
    _loadNext(followUp: followUp);
  }

  @override
  Widget build(BuildContext context) {
    final brain = context.watch<LearningBrain>();
    final livesLeft = (3 - brain.wrongAttempts).clamp(0, 3);
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          _buildHeader(context, livesLeft),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                    ScaleTransition(
                      scale: _feedbackScale,
                      child: _buildFeedback(brain),
                    ),
                  ],
                  if (_showExplanation) ...[
                    const SizedBox(height: 16),
                    _buildExplanation(),
                  ],
                  if (_isCorrect != null || _showExplanation) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextExercise,
                        child: const Text('Weiter ➡️'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int livesLeft) {
    final settings = context.watch<ClassSettings>();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFF5F15)],
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Lernen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${settings.level.emoji} ${settings.level.label}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      i < livesLeft ? '❤️' : '🖤',
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7), // light yellow – school notebook
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _RuledPaperPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(44, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.turquoise.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentExercise.subject,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2A7A75),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _currentExercise.question,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    final isSelected = _selectedAnswer == option;
    Color bgColor = Colors.white;
    Color borderColor = Colors.transparent;
    if (isSelected) {
      bgColor =
          _isCorrect == true ? AppTheme.softGreen : Colors.red.shade100;
      borderColor =
          _isCorrect == true ? AppTheme.softGreen : Colors.red.shade300;
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isCorrect == null ? () => _onAnswerSelected(option) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: bgColor,
          disabledForegroundColor: Colors.black87,
          elevation: isSelected ? 0 : 2,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(option, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  // Personalised feedback using LearningBrain wrong topics
  Widget _buildFeedback(LearningBrain brain) {
    final correct = _isCorrect == true;
    String message;
    if (correct) {
      message = 'Super gemacht! +10 XP 🎉';
    } else if (brain.wrongTopics.isNotEmpty) {
      final topic = brain.wrongTopics.last;
      message = '💪 Noch nicht ganz – üben wir "$topic" zusammen!';
    } else {
      message = '💪 Nicht ganz – versuch es nochmal!';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: correct
              ? [
                  AppTheme.softGreen.withOpacity(0.4),
                  AppTheme.softGreen.withOpacity(0.15)
                ]
              : [Colors.red.shade100, Colors.red.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: correct ? AppTheme.softGreen : Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            correct ? '🎉' : '💪',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: correct
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.yellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.yellow, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Schritt-für-Schritt Erklärung',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _currentExercise.explanation,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

