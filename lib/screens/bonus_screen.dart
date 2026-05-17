import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/reward_orchestrator.dart';

class BonusScreen extends StatefulWidget {
  const BonusScreen({super.key});

  @override
  State<BonusScreen> createState() => _BonusScreenState();
}

class _BonusScreenState extends State<BonusScreen> {
  bool _pinUnlocked = false;
  final TextEditingController _pinController = TextEditingController();

  static const String _demoPin = '1234';

  static const List<Map<String, dynamic>> _rewards = [
    {
      'emoji': '⭐',
      'title': 'Fleißige Biene',
      'desc': '5 Aufgaben richtig gelöst',
      'xpRequired': 50,
      'color': 0xFFFFD166,
    },
    {
      'emoji': '🎨',
      'title': 'Kreativ-Gutschein',
      'desc': '30 min Malzeit verdient',
      'xpRequired': 100,
      'color': 0xFF95D5B2,
    },
    {
      'emoji': '🎮',
      'title': 'Spiel-Bonus',
      'desc': '20 min freies Spielen',
      'xpRequired': 200,
      'color': 0xFF87CEEB,
    },
    {
      'emoji': '🏆',
      'title': 'Superstar',
      'desc': 'Level 5 erreicht',
      'xpRequired': 500,
      'color': 0xFFFF8C42,
    },
  ];

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _checkPin() {
    if (_pinController.text == _demoPin) {
      setState(() => _pinUnlocked = true);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falscher PIN. Demo-PIN: 1234')),
      );
    }
  }

  void _showPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eltern-PIN eingeben'),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
              onPressed: _checkPin, child: const Text('Bestätigen')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardOrchestrator>();
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          _buildHeader(context, rewards),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              itemCount: _rewards.length + (_pinUnlocked ? 0 : 1),
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) {
                if (!_pinUnlocked && i == _rewards.length) {
                  return _buildUnlockButton();
                }
                final r = _rewards[i];
                final xpReq = r['xpRequired'] as int;
                final unlocked = _pinUnlocked && rewards.xp >= xpReq;
                return _buildRewardCard(r, rewards.xp, xpReq, unlocked);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RewardOrchestrator rewards) {
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
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎁 Bonus & Gutscheine',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rewards.stars} Sterne',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${rewards.xp} XP • Level ${rewards.level}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> r, int currentXp,
      int xpReq, bool unlocked) {
    final progress = (currentXp / xpReq).clamp(0.0, 1.0);
    final accent = Color(r['color'] as int);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(r['emoji'] as String,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r['title'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (unlocked)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 22)
                      else
                        Text(
                          '$xpReq XP',
                          style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(r['desc'] as String,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: accent.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showPinDialog,
        icon: const Icon(Icons.lock_open_rounded),
        label: const Text('Mit Eltern-PIN freischalten'),
      ),
    );
  }
}
