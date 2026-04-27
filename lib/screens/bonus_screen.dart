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
    {'title': '⭐ Fleißige Biene', 'desc': '5 Aufgaben richtig gelöst', 'xpRequired': 50},
    {'title': '🎨 Kreativ-Gutschein', 'desc': '30 min Malzeit verdient', 'xpRequired': 100},
    {'title': '🎮 Spiel-Bonus', 'desc': '20 min freies Spielen', 'xpRequired': 200},
    {'title': '🏆 Superstar', 'desc': 'Level 5 erreicht', 'xpRequired': 500},
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
      appBar: AppBar(
        title: const Text('Bonus & Gutscheine'),
        backgroundColor: AppTheme.yellow,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.orange.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${rewards.stars} Sterne',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${rewards.xp} XP • Level ${rewards.level}',
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Belohnungen',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _rewards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final r = _rewards[i];
                    final unlocked = _pinUnlocked &&
                        rewards.xp >= (r['xpRequired'] as int);
                    return Card(
                      child: ListTile(
                        leading: Text(r['title'].toString().split(' ').first,
                            style: const TextStyle(fontSize: 28)),
                        title: Text(r['title'].toString().substring(
                            r['title'].toString().indexOf(' ') + 1)),
                        subtitle: Text(r['desc'] as String),
                        trailing: unlocked
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : Text('${r['xpRequired']} XP',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
              if (!_pinUnlocked) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showPinDialog,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Mit Eltern-PIN freischalten'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
