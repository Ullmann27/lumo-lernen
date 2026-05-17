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
  final Set<int> _redeemed = {};

  static const String _demoPin = '1234';

  // ── 32 vouchers across 6 categories ──────────────────────────────────────
  static const List<Map<String, dynamic>> _rewards = [
    // ── Aktivitäten ──────────────────────────────────────────────────────────
    {
      'emoji': '🎨',
      'title': 'Malzeit',
      'desc': '30 min Malen & Basteln',
      'xpRequired': 80,
      'color': 0xFF95D5B2,
      'category': 'Aktivitäten',
    },
    {
      'emoji': '🚴',
      'title': 'Fahrradtour',
      'desc': 'Gemeinsame Radtour mit der Familie',
      'xpRequired': 150,
      'color': 0xFF4ECDC4,
      'category': 'Aktivitäten',
    },
    {
      'emoji': '🏊',
      'title': 'Schwimmen',
      'desc': 'Ausflug ins Schwimmbad',
      'xpRequired': 300,
      'color': 0xFF87CEEB,
      'category': 'Aktivitäten',
    },
    {
      'emoji': '⚽',
      'title': 'Sportzeit',
      'desc': '30 min Sport deiner Wahl',
      'xpRequired': 100,
      'color': 0xFF95D5B2,
      'category': 'Aktivitäten',
    },
    {
      'emoji': '🌳',
      'title': 'Spielplatz extra',
      'desc': 'Extra Spielplatz-Zeit nach dem Mittag',
      'xpRequired': 60,
      'color': 0xFF95D5B2,
      'category': 'Aktivitäten',
    },
    {
      'emoji': '🧗',
      'title': 'Erlebnisbad',
      'desc': 'Ausflug ins Erlebnisbad',
      'xpRequired': 500,
      'color': 0xFF4ECDC4,
      'category': 'Aktivitäten',
    },
    {
      'emoji': '🦁',
      'title': 'Tiergarten',
      'desc': 'Ausflug in den Tiergarten',
      'xpRequired': 450,
      'color': 0xFF95D5B2,
      'category': 'Aktivitäten',
    },
    // ── Familienzeit ─────────────────────────────────────────────────────────
    {
      'emoji': '👨‍👧',
      'title': 'Papa-Tochter-Ausflug',
      'desc': 'Ein besonderer Ausflug mit Papa',
      'xpRequired': 400,
      'color': 0xFF87CEEB,
      'category': 'Familienzeit',
    },
    {
      'emoji': '👩‍👧',
      'title': 'Mama-Tochter-Ausflug',
      'desc': 'Ein besonderer Ausflug mit Mama',
      'xpRequired': 400,
      'color': 0xFFE0AAFF,
      'category': 'Familienzeit',
    },
    {
      'emoji': '🧺',
      'title': 'Picknick',
      'desc': 'Familien-Picknick im Park',
      'xpRequired': 200,
      'color': 0xFF95D5B2,
      'category': 'Familienzeit',
    },
    {
      'emoji': '🎡',
      'title': 'Family Park',
      'desc': 'Ausflug in den Freizeitpark',
      'xpRequired': 600,
      'color': 0xFFFF8C42,
      'category': 'Familienzeit',
    },
    // ── Spaß & Spiel ─────────────────────────────────────────────────────────
    {
      'emoji': '🎮',
      'title': 'Spiel-Bonus',
      'desc': '20 min freies Spielen',
      'xpRequired': 200,
      'color': 0xFF87CEEB,
      'category': 'Spaß & Spiel',
    },
    {
      'emoji': '🧩',
      'title': 'Puzzle-Abend',
      'desc': 'Puzzle-Zeit mit der Familie',
      'xpRequired': 120,
      'color': 0xFFFFD166,
      'category': 'Spaß & Spiel',
    },
    {
      'emoji': '🎲',
      'title': 'Spieleabend',
      'desc': 'Brettspiel nach Wahl',
      'xpRequired': 180,
      'color': 0xFFFF8C42,
      'category': 'Spaß & Spiel',
    },
    {
      'emoji': '🎬',
      'title': 'Kinoabend zuhause',
      'desc': 'Film-Abend nach Wahl mit Popcorn',
      'xpRequired': 250,
      'color': 0xFFE0AAFF,
      'category': 'Spaß & Spiel',
    },
    {
      'emoji': '🧱',
      'title': 'Lego-Zeit',
      'desc': '1 Stunde Bauen mit Lego',
      'xpRequired': 150,
      'color': 0xFF87CEEB,
      'category': 'Spaß & Spiel',
    },
    {
      'emoji': '🔬',
      'title': 'Experimentierkasten',
      'desc': 'Experimente nach Wahl durchführen',
      'xpRequired': 350,
      'color': 0xFF4ECDC4,
      'category': 'Spaß & Spiel',
    },
    // ── Genuss & Essen ───────────────────────────────────────────────────────
    {
      'emoji': '🍦',
      'title': 'Eis holen',
      'desc': 'Eine Kugel Eis nach Wahl',
      'xpRequired': 50,
      'color': 0xFFFFD166,
      'category': 'Genuss',
    },
    {
      'emoji': '🍕',
      'title': 'Pizzaabend',
      'desc': 'Pizza-Abend mit Wunschbelag',
      'xpRequired': 350,
      'color': 0xFFFF8C42,
      'category': 'Genuss',
    },
    {
      'emoji': '🥤',
      'title': 'Lieblingsgetränk',
      'desc': 'Lieblingsgetränk nach Wahl',
      'xpRequired': 60,
      'color': 0xFF87CEEB,
      'category': 'Genuss',
    },
    {
      'emoji': '🍫',
      'title': 'Lieblingsjause',
      'desc': 'Lieblingsjause selbst aussuchen',
      'xpRequired': 40,
      'color': 0xFFE0AAFF,
      'category': 'Genuss',
    },
    // ── Kreativ & Lernen ─────────────────────────────────────────────────────
    {
      'emoji': '🎨',
      'title': 'Sticker aussuchen',
      'desc': '5 Sticker selbst aussuchen',
      'xpRequired': 70,
      'color': 0xFFFFD166,
      'category': 'Kreativ & Lernen',
    },
    {
      'emoji': '📚',
      'title': 'Buch aussuchen',
      'desc': 'Ein neues Buch selbst aussuchen',
      'xpRequired': 300,
      'color': 0xFF4ECDC4,
      'category': 'Kreativ & Lernen',
    },
    {
      'emoji': '✂️',
      'title': 'Bastelset',
      'desc': 'Ein Bastelset nach Wahl',
      'xpRequired': 200,
      'color': 0xFF95D5B2,
      'category': 'Kreativ & Lernen',
    },
    {
      'emoji': '📚',
      'title': 'Bücherei-Besuch',
      'desc': 'Ausflug in die Bücherei',
      'xpRequired': 180,
      'color': 0xFF4ECDC4,
      'category': 'Kreativ & Lernen',
    },
    // ── Auszeichnungen ───────────────────────────────────────────────────────
    {
      'emoji': '⭐',
      'title': 'Fleißige Biene',
      'desc': '5 Aufgaben richtig gelöst',
      'xpRequired': 50,
      'color': 0xFFFFD166,
      'category': 'Auszeichnung',
    },
    {
      'emoji': '🌟',
      'title': 'Lernstar',
      'desc': '10 Aufgaben in einer Woche',
      'xpRequired': 100,
      'color': 0xFFFFD166,
      'category': 'Auszeichnung',
    },
    {
      'emoji': '🏆',
      'title': 'Superstar',
      'desc': 'Level 5 erreicht',
      'xpRequired': 500,
      'color': 0xFFFF8C42,
      'category': 'Auszeichnung',
    },
    {
      'emoji': '💎',
      'title': 'Quiz-Champion',
      'desc': 'Alle 15 Quiz-Fragen richtig beantwortet',
      'xpRequired': 1000,
      'color': 0xFF87CEEB,
      'category': 'Auszeichnung',
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

  void _redeemReward(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${_rewards[index]['emoji']} Einlösen'),
        content: Text(
          '"${_rewards[index]['title']}" einlösen?\n\n'
          '${_rewards[index]['desc']}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              setState(() => _redeemed.add(index));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '🎉 "${_rewards[index]['title']}" wurde eingelöst!'),
                  backgroundColor: AppTheme.softGreen,
                ),
              );
            },
            child: const Text('Einlösen ✅'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardOrchestrator>();

    // Group rewards by category
    final categories = <String, List<int>>{};
    for (int i = 0; i < _rewards.length; i++) {
      final cat = _rewards[i]['category'] as String;
      categories.putIfAbsent(cat, () => []).add(i);
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          _buildHeader(context, rewards),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                if (!_pinUnlocked) _buildUnlockButton(),
                if (!_pinUnlocked) const SizedBox(height: 16),
                for (final entry in categories.entries) ...[
                  _buildCategoryHeader(entry.key),
                  const SizedBox(height: 8),
                  for (final idx in entry.value) ...[
                    _buildRewardCard(idx, rewards.xp),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        category,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
            letterSpacing: 1.2),
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
                    const Spacer(),
                    if (_redeemed.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_redeemed.length} eingelöst',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildRewardCard(int index, int currentXp) {
    final r = _rewards[index];
    final xpReq = r['xpRequired'] as int;
    final accent = Color(r['color'] as int);
    final unlocked = _pinUnlocked && currentXp >= xpReq;
    final alreadyRedeemed = _redeemed.contains(index);
    final progress = (currentXp / xpReq).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: alreadyRedeemed
            ? Colors.grey.shade100
            : Colors.white,
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(alreadyRedeemed ? 0.1 : 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  r['emoji'] as String,
                  style: TextStyle(
                      fontSize: 26,
                      color: alreadyRedeemed
                          ? Colors.grey
                          : null),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r['title'] as String,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: alreadyRedeemed
                                ? Colors.grey
                                : null),
                      ),
                      if (alreadyRedeemed)
                        const Text('✅ Eingelöst',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))
                      else if (unlocked)
                        GestureDetector(
                          onTap: () => _redeemReward(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Einlösen',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        )
                      else
                        Text(
                          '$xpReq XP',
                          style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r['desc'] as String,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  if (!alreadyRedeemed)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
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

