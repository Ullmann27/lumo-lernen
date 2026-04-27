import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/memory_graph.dart';

class MemoryGraphScreen extends StatelessWidget {
  const MemoryGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final graph = context.watch<MemoryGraph>();
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('MemoryGraph / Lernbaum'),
        backgroundColor: AppTheme.softGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dein Lernbaum 🌳',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                'Hier siehst du, welche Fähigkeiten du schon gut beherrschst.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ...graph.skills.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSkillCard(context, entry.key, entry.value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCard(BuildContext context, String skill, double progress) {
    Color color;
    if (progress >= 0.7) {
      color = AppTheme.softGreen;
    } else if (progress >= 0.4) {
      color = AppTheme.yellow;
    } else {
      color = Colors.orange.shade300;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(skill,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
