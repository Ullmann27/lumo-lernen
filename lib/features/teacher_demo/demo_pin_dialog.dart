import 'package:flutter/material.dart';

import 'holo_widgets.dart';

/// Einfache PIN-Sperre für den Lehrkräfte-Demobereich. Die Demo-PIN wird
/// bewusst angezeigt: Sie schützt vor versehentlichem Öffnen durch Kinder,
/// ist aber kein Ersatz für eine echte Anmeldung.
class DemoPinDialog extends StatefulWidget {
  const DemoPinDialog({super.key});

  static const String demoPin = '2026';

  static Future<bool> show(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const DemoPinDialog(),
      ) ??
      false;

  @override
  State<DemoPinDialog> createState() => _DemoPinDialogState();
}

class _DemoPinDialogState extends State<DemoPinDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim() == DemoPinDialog.demoPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Die PIN stimmt nicht.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: HoloPalette.night,
      icon: const Icon(Icons.lock_rounded, color: HoloPalette.cyan, size: 34),
      title: const Text('Für Lehrkräfte',
          style: TextStyle(color: HoloPalette.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Demo-PIN: ${DemoPinDialog.demoPin}',
              style: TextStyle(
                  color: HoloPalette.amber, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('demo-pin-field'),
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: const TextStyle(color: HoloPalette.text, fontSize: 22),
            decoration: InputDecoration(
              labelText: 'PIN',
              errorText: _error,
              labelStyle: const TextStyle(color: HoloPalette.muted),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('demo-pin-ok'),
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _submit,
          child: const Text('Öffnen'),
        ),
      ],
    );
  }
}
