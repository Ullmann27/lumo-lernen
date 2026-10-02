import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentPinEditor extends StatefulWidget {
  const ParentPinEditor({super.key, required this.onSave});

  final Future<void> Function(String) onSave;

  @override
  State<ParentPinEditor> createState() => _ParentPinEditorState();
}

class _ParentPinEditorState extends State<ParentPinEditor> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  String? _message;
  bool _saving = false;

  Future<void> _save() async {
    final pin = _pin.text;
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin) || pin != _confirmation.text) {
      setState(
        () => _message = 'Bitte 4 bis 8 Ziffern zweimal gleich eingeben.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(pin);
      if (!mounted) return;
      _pin.clear();
      _confirmation.clear();
      setState(() => _message = 'Eltern-PIN gespeichert.');
    } catch (_) {
      if (mounted)
        setState(
          () => _message =
              'Die PIN konnte nicht gespeichert werden. Bitte erneut versuchen.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Eltern-PIN ändern',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      for (final entry in [
        (_pin, 'Neue PIN'),
        (_confirmation, 'PIN wiederholen'),
      ])
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: entry.$1,
            enabled: !_saving,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: entry.$2, counterText: ''),
          ),
        ),
      if (_message != null) Text(_message!),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _saving ? null : _save,
        child: const Text('PIN speichern'),
      ),
    ],
  );
}
