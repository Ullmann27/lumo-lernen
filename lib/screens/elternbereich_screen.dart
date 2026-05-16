import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/reward_orchestrator.dart';
import '../services/memory_graph.dart';
import '../services/wwm_question_service.dart';

class ElternbereichScreen extends StatefulWidget {
  const ElternbereichScreen({super.key});

  @override
  State<ElternbereichScreen> createState() => _ElternbereichScreenState();
}

class _ElternbereichScreenState extends State<ElternbereichScreen> {
  bool _authenticated = false;
  final TextEditingController _pinController = TextEditingController();
  static const String _demoPin = '1234';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _authenticate() {
    if (_pinController.text == _demoPin) {
      setState(() => _authenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falscher PIN. Demo-PIN: 1234')),
      );
    }
  }

  void _showWhyRecommended(String topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warum empfiehlt Lumo das?'),
        content: Text(
          'Lumo hat bemerkt, dass "$topic" noch geübt werden kann. '
          'Basierend auf den letzten 5 Aufgaben und dem Lernprofil empfiehlt '
          'Lumo mehr Übung in diesem Bereich.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Verstanden')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Elternbereich'),
        backgroundColor: AppTheme.softGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _authenticated ? _buildDashboard() : _buildPinEntry(),
      ),
    );
  }

  Widget _buildPinEntry() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom_rounded,
                size: 80, color: Color(0xFF95D5B2)),
            const SizedBox(height: 24),
            const Text('Elternbereich',
                style:
                    TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Bitte gib den Eltern-PIN ein',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('Anmelden'),
            ),
            const SizedBox(height: 8),
            const Text('Demo-PIN: 1234',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final rewards = context.watch<RewardOrchestrator>();
    final memGraph = context.watch<MemoryGraph>();
    final wwmService = context.read<WwmQuestionService>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('⭐', '${rewards.stars}', 'Sterne'),
              const SizedBox(width: 12),
              _buildStatCard('🏆', 'Level ${rewards.level}', '${rewards.xp} XP'),
              const SizedBox(width: 12),
              _buildStatCard('🤖', '${wwmService.apiCallCount}', 'KI-Spiele'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Empfohlene Themen',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ...memGraph.weakSkills.map((skill) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(skill),
                    subtitle: const Text('Lumo empfiehlt mehr Übung'),
                    trailing: OutlinedButton(
                      onPressed: () => _showWhyRecommended(skill),
                      child: const Text('Warum?'),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _authenticated = false),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Abmelden'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: Card(
        color: AppTheme.softGreen.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
