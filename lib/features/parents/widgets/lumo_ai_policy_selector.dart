import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/lumo_ai_learning_access.dart';
import '../../shared/widgets/lumo_modern_card.dart';

class LumoAiPolicySelector extends StatelessWidget {
  const LumoAiPolicySelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  final LumoAiLearningMode currentMode;
  final ValueChanged<LumoAiLearningMode> onModeChanged;

  static const List<_AiPolicyOption> _options = <_AiPolicyOption>[
    _AiPolicyOption(
      mode: LumoAiLearningMode.chatOnly,
      icon: '💬',
      title: 'Nur KI-Chat',
      description: 'Lumo antwortet nur im Chat-Modus.',
    ),
    _AiPolicyOption(
      mode: LumoAiLearningMode.learningHelp,
      icon: '💡',
      title: 'Aufgabenhilfe',
      description: 'Lumo darf Aufgaben kindgerecht erklären.',
    ),
    _AiPolicyOption(
      mode: LumoAiLearningMode.readingHelp,
      icon: '📖',
      title: 'Lesehilfe',
      description: 'Lumo darf beim Lesen ruhig coachen.',
    ),
    _AiPolicyOption(
      mode: LumoAiLearningMode.fullCoach,
      icon: '🚀',
      title: 'Voller Lumo-Coach',
      description: 'Lumo darf Chat, Aufgaben, Lesen, Tests und Scanner unterstützen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LumoModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Lumo KI-Assistent', style: LumoTextStyles.heading2),
          const SizedBox(height: 6),
          Text(
            'Wähle, wie Lumo dein Kind beim Lernen unterstützen darf.',
            style: LumoTextStyles.body.copyWith(color: LumoColors.ink600),
          ),
          const SizedBox(height: 16),
          Column(
            children: _options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AiPolicyOptionTile(
                  option: option,
                  selected: currentMode == option.mode,
                  onTap: () => onModeChanged(option.mode),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _AiPolicyOptionTile extends StatelessWidget {
  const _AiPolicyOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _AiPolicyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? LumoColors.orange : LumoColors.ink100;
    final background = selected ? LumoColors.orange.withOpacity(.10) : Colors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(LumoRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LumoRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LumoRadius.md),
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1.1),
          ),
          child: Row(
            children: <Widget>[
              _AiPolicyIcon(icon: option.icon, selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      option.title,
                      style: LumoTextStyles.heading3.copyWith(
                        color: selected ? LumoColors.orange : LumoColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.description,
                      style: LumoTextStyles.body.copyWith(
                        color: selected ? LumoColors.ink700 : LumoColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? LumoColors.orange : LumoColors.ink300,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiPolicyIcon extends StatelessWidget {
  const _AiPolicyIcon({
    required this.icon,
    required this.selected,
  });

  final String icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.white : LumoColors.orangeSurface,
        borderRadius: BorderRadius.circular(LumoRadius.md),
        boxShadow: selected ? LumoShadow.pill : null,
      ),
      child: Text(
        icon,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class _AiPolicyOption {
  const _AiPolicyOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
  });

  final LumoAiLearningMode mode;
  final String icon;
  final String title;
  final String description;
}
