import 'package:flutter/material.dart';

import 'demo_pin_dialog.dart';
import 'holo_widgets.dart';
import 'teacher_demo_screen.dart';

/// Einstieg in die Demo-Klasse im bestehenden Lehrerbereich.
class TeacherDemoEntryCard extends StatelessWidget {
  const TeacherDemoEntryCard({super.key});

  Future<void> _open(BuildContext context) async {
    final ok = await DemoPinDialog.show(context);
    if (!ok || !context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TeacherDemoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ohne Dauer-Schimmer: Der Lehrerbereich darf zur Ruhe kommen.
    return HoloPanel(
      shimmer: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: HoloPalette.cyan, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('Demo-Klasse: Auswertung und Hausaufgaben',
                    style: TextStyle(
                        color: HoloPalette.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
              alignment: Alignment.centerLeft, child: DemoDataBadge()),
          const SizedBox(height: 10),
          HoloButton(
            key: const ValueKey('open-teacher-demo'),
            label: 'Demo öffnen',
            icon: Icons.lock_open_rounded,
            shimmer: false,
            onPressed: () => _open(context),
          ),
        ],
      ),
    );
  }
}
