import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/lumo_avatar.dart';
import '../widgets/star_badge.dart';
import '../services/reward_orchestrator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardOrchestrator>();
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hallo! 👋',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  StarBadge(stars: rewards.stars, xp: rewards.xp),
                ],
              ),
              const SizedBox(height: 24),
              const Center(child: LumoAvatar(size: 140)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Ich bin Lumo, dein Lernfreund! 🦊',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Level ${rewards.level} – ${rewards.xp} XP',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(
                context,
                icon: Icons.tips_and_updates_rounded,
                title: 'Tipp des Tages',
                body: 'Lerne jeden Tag 10 Minuten – das hilft deinem Gehirn, Neues zu behalten!',
                color: AppTheme.lightBlue,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                context,
                icon: Icons.emoji_events_rounded,
                title: 'Dein Fortschritt',
                body: '${rewards.stars} ⭐ gesammelt • Level ${rewards.level}',
                color: AppTheme.yellow,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
