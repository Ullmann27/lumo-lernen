import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Placeholder for the upcoming Online-Wettbewerbe feature.
/// Cloud / Ranglisten features will be activated in a later release.
class WettbewerbScreen extends StatelessWidget {
  const WettbewerbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF6A3DE8)],
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Wettbewerbe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🔒 Demnächst verfügbar',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coming-soon hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D1B69).withOpacity(0.08),
                  const Color(0xFF6A3DE8).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF6A3DE8).withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Text('🏆', style: TextStyle(fontSize: 64)),
                SizedBox(height: 16),
                Text(
                  'Online-Wettbewerbe',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Bald kannst du dich mit anderen Schülerinnen und '
                  'Schülern messen – fair, sicher und spaßig!',
                  style: TextStyle(
                      fontSize: 14, color: Colors.black54, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Was dich erwartet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._features.map((f) => _buildFeatureRow(f)),
          const SizedBox(height: 28),
          // Cloud/Leaderboard locked section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 40, color: Colors.grey),
                const SizedBox(height: 10),
                const Text(
                  'Ranglisten & Cloud-Speicher',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  'Werden aktiviert, sobald die Wettbewerbsfunktion '
                  'bereit ist. Datenschutz und Sicherheit werden '
                  'sorgfältig vorbereitet.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(Map<String, String> f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f['emoji']!, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['title']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(f['desc']!,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _features = [
    {
      'emoji': '🎯',
      'title': 'Klassenquiz',
      'desc': 'Tritt gegen Mitschüler in einem fairen Wissensquiz an.',
    },
    {
      'emoji': '⏱️',
      'title': 'Wochenrangliste',
      'desc': 'Sammle XP und steige in der Schulrangliste auf.',
    },
    {
      'emoji': '🛡️',
      'title': 'Sicher & datenschutzkonform',
      'desc': 'Nur mit Elternfreigabe, keine persönlichen Daten.',
    },
    {
      'emoji': '🎁',
      'title': 'Sonderprämien',
      'desc': 'Gewinne extra Gutscheine und exklusive Abzeichen.',
    },
  ];
}
