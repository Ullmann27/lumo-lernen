import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/consent_service.dart';

class DatenschutzScreen extends StatelessWidget {
  const DatenschutzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final consent = context.watch<ConsentService>();
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Datenschutz & Einstellungen'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Einwilligungen',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Alle Funktionen, die Mikrofon, Fotos oder Cloud nutzen, '
              'erfordern deine ausdrückliche Zustimmung.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _buildConsentTile(
              context,
              title: 'Mikrofon',
              subtitle: 'Für Spracheingabe und Ausspracheübungen',
              icon: Icons.mic_rounded,
              value: consent.microphone,
              onChanged: (v) => consent.setMicrophone(v),
            ),
            _buildConsentTile(
              context,
              title: 'Foto-Analyse',
              subtitle: 'Fotos von Aufgaben scannen',
              icon: Icons.camera_alt_rounded,
              value: consent.photoAnalysis,
              onChanged: (v) => consent.setPhotoAnalysis(v),
            ),
            _buildConsentTile(
              context,
              title: 'KI-Stimme',
              subtitle: 'Text-to-Speech Sprachausgabe',
              icon: Icons.record_voice_over_rounded,
              value: consent.aiVoice,
              onChanged: (v) => consent.setAiVoice(v),
            ),
            _buildConsentTile(
              context,
              title: 'Cloud-Synchronisierung',
              subtitle: 'Lernfortschritt in der Cloud speichern',
              icon: Icons.cloud_sync_rounded,
              value: consent.cloudSync,
              onChanged: (v) => consent.setCloudSync(v),
            ),
            const SizedBox(height: 24),
            Text('Daten', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Daten exportieren'),
              subtitle: const Text('Lernfortschritt als JSON herunterladen'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export wird vorbereitet...')),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded,
                  color: Colors.red),
              title: const Text('Alle Daten löschen',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('Lernfortschritt unwiderruflich löschen'),
              onTap: () => _showDeleteConfirm(context, consent),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Datenschutzhinweise',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      '• Keine Werbung\n'
                      '• Keine In-App-Käufe für Kinder\n'
                      '• Keine Standortdaten\n'
                      '• Kein offener Chat für Kinder\n'
                      '• Daten werden lokal gespeichert',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppTheme.turquoise),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.turquoise,
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ConsentService consent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daten löschen?'),
        content: const Text(
            'Alle Lernfortschritte werden unwiderruflich gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              consent.deleteAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alle Daten wurden gelöscht.')),
              );
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
