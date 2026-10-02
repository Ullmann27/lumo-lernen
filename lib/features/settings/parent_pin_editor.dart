import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../widgets/parent_pin_setup_dialog.dart';

/// Lives inside the authenticated parent area; credentials are saved by the
/// setup dialog before onSaved updates the live app state.
class ParentPinEditor extends StatefulWidget {
  const ParentPinEditor({
    super.key,
    required this.settings,
    required this.onSaved,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSaved;

  @override
  State<ParentPinEditor> createState() => _ParentPinEditorState();
}

class _ParentPinEditorState extends State<ParentPinEditor> {
  String? _message;
  bool _editing = false;

  Future<void> _edit() async {
    if (_editing) return;
    setState(() => _editing = true);
    try {
      final next =
          await ParentPinSetupDialog.show(context, settings: widget.settings);
      if (!mounted || next == null) return;
      widget.onSaved(next);
      setState(() =>
          _message = 'Eltern-PIN und Wiederherstellungscode gespeichert.');
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Eltern-PIN',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(!widget.settings.parentPinConfigured
              ? 'Noch keine eigene PIN eingerichtet. Der bisherige Erstzugang lautet 2468. Bitte lege jetzt eine eigene PIN fest.'
              : widget.settings.hasParentRecoveryCode
                  ? 'Eigene PIN und Wiederherstellungscode sind eingerichtet.'
                  : 'Deine eigene PIN bleibt gültig. Richte zusätzlich einen Wiederherstellungscode ein, damit du bei einer vergessenen PIN keine Lernstände verlierst.'),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _editing ? null : _edit,
            child: Text(widget.settings.parentPinConfigured
                ? 'PIN und Wiederherstellungscode ändern'
                : 'Eigene PIN einrichten'),
          ),
        ],
      );
}
