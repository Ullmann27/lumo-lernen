import 'package:flutter/material.dart';

/// An adult explicitly agrees to a family reward. No credentials are requested.
class ParentApprovalDialog extends StatelessWidget {
  const ParentApprovalDialog({
    super.key,
    required this.rewardTitle,
    required this.costLabel,
  });

  final String rewardTitle;
  final String costLabel;

  static Future<bool> show(
    BuildContext context, {
    required String rewardTitle,
    required String costLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => ParentApprovalDialog(
            rewardTitle: rewardTitle,
            costLabel: costLabel,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: const Icon(Icons.family_restroom_rounded, size: 36),
        title: const Text('Belohnung gemeinsam einlösen'),
        content: Text(
          'Bitte gib das Gerät einer erwachsenen Person.\n\n'
          '„$rewardTitle“ kostet $costLabel. '
          'Als erwachsene Person bestätige ich, dass wir diese Belohnung erfüllen möchten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Als Erwachsene:r bestätigen'),
          ),
        ],
      );
}
