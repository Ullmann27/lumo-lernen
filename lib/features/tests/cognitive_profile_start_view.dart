import 'package:flutter/material.dart';

import '../../domain/cognitive/cognitive_profile.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_motion.dart';
import 'iq/iq_start_view.dart';
import 'iq/iq_style.dart';
import 'iq/iq_widgets.dart';

/// Denkprofil uses the same real premium Lumo hero, glass panels, category
/// chips and action bar as the Knobel-Test, with its own five-domain content.
class CognitiveProfileStartView extends StatelessWidget {
  const CognitiveProfileStartView({
    super.key,
    required this.onStart,
    required this.onBack,
    this.questionCount = 50,
  });

  final VoidCallback onStart;
  final VoidCallback onBack;
  final int questionCount;

  static const _domains = <(IconData, Color)>[
    (Icons.auto_awesome_mosaic_rounded, Color(0xFF35D6FF)),
    (Icons.calculate_rounded, Color(0xFFFFD43B)),
    (Icons.record_voice_over_rounded, Color(0xFFFF8F3D)),
    (Icons.view_in_ar_rounded, Color(0xFF9170FF)),
    (Icons.psychology_rounded, Color(0xFF46D36B)),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 720 && c.maxWidth >= c.maxHeight * 1.1;
          final hero = IqHeroHeader(
            reduced: LumoMotion.reduced(context),
            scale: c.maxWidth >= 600 ? 1.2 : 1,
            title: 'Lumo Denkprofil',
            subtitle: 'Deine Stärken entdecken',
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IqPanel(
                strong: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fünf Denk-Bereiche',
                        style: iqText(16, weight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < CognitiveDomain.values.length; i++)
                          IqSkillChip(
                            label: CognitiveDomain.values[i].label,
                            icon: _domains[i].$1,
                            color: _domains[i].$2,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: IqChip(
                  label: '$questionCount Aufgaben · ohne Zeitdruck',
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(height: 12),
              IqPanel(
                accent: LumoVisualTokens.muted,
                radius: 22,
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.family_restroom_rounded,
                        color: LumoVisualTokens.cyanBright, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hinweis für Eltern',
                              style: iqText(14, weight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text(
                            'Dieses Denkprofil zeigt schulstufenbezogene '
                            'Lernstärken in fünf Bereichen. Es ist kein '
                            'klinisch normierter IQ-Test und berechnet '
                            'bewusst keine IQ-Zahl.',
                            style: iqText(12.5,
                                color: LumoVisualTokens.muted,
                                weight: FontWeight.w700,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          return Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
                  child: IqRoundButton(
                    key: const ValueKey('cognitive-back'),
                    icon: Icons.arrow_back_rounded,
                    label: 'Zurück',
                    onPressed: onBack,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1000 : 560),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: hero),
                                const SizedBox(width: 24),
                                Expanded(child: details),
                              ],
                            )
                          : Column(
                              children: [
                                hero,
                                const SizedBox(height: 14),
                                details,
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              IqBottomBar(
                child: IqPrimaryButton(
                  key: const ValueKey('cognitive-start-button'),
                  label: 'Denkprofil starten',
                  icon: Icons.play_arrow_rounded,
                  height: 62,
                  onPressed: onStart,
                ),
              ),
            ],
          );
        },
      );
}
