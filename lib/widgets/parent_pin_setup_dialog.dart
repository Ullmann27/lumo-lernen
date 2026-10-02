import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_settings.dart';
import '../core/parent_pin_recovery.dart';
import '../core/settings_repository.dart';

/// First-time setup, or PIN change from an already authenticated parent screen.
/// Returns only after the new credentials have been persisted successfully.
class ParentPinSetupDialog extends StatefulWidget {
  const ParentPinSetupDialog({
    super.key,
    required this.settings,
    this.recoveryCode,
  });

  final AppSettings settings;
  final String? recoveryCode;

  static Future<AppSettings?> show(
    BuildContext context, {
    required AppSettings settings,
    String? recoveryCode,
  }) =>
      showDialog<AppSettings>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ParentPinSetupDialog(
          settings: settings,
          recoveryCode: recoveryCode,
        ),
      );

  @override
  State<ParentPinSetupDialog> createState() => _ParentPinSetupDialogState();
}

class _ParentPinSetupDialogState extends State<ParentPinSetupDialog> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  String? _recoveryCode;
  String? _error;
  bool _recorded = false;
  bool _saving = false;

  void _prepareCode() {
    final pin = _pin.text;
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin) || pin != _confirmation.text) {
      setState(() => _error = 'Bitte 4 bis 8 Ziffern zweimal gleich eingeben.');
      return;
    }
    if (pin == AppSettings.initialParentPin) {
      setState(() => _error =
          'Bitte wähle eine eigene PIN statt des bisherigen Erstzugangs 2468.');
      return;
    }
    setState(() {
      _error = null;
      _recoveryCode = ParentPinRecovery.generateCode();
    });
  }

  Future<void> _save() async {
    if (_saving || !_recorded || _recoveryCode == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final hash = ParentPinRecovery.hash(_recoveryCode!);
      final recoveredWith = widget.recoveryCode;
      final next = recoveredWith == null
          ? await SettingsRepository.setParentPin(
              pin: _pin.text,
              recoveryCodeHash: hash,
              firstSetupOnly: !widget.settings.parentPinConfigured,
            )
          : await SettingsRepository.recoverParentPin(
              recoveryCode: recoveredWith,
              newPin: _pin.text,
              newRecoveryCodeHash: hash,
            );
      if (mounted) Navigator.of(context).pop(next);
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Die PIN konnte nicht gespeichert werden. Bitte erneut versuchen.');
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
  Widget build(BuildContext context) {
    final firstSetup = !widget.settings.parentPinConfigured;
    return AlertDialog(
      title: Text(firstSetup ? 'Eltern-PIN einrichten' : 'Neue Eltern-PIN'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recoveryCode == null) ...[
              Text(firstSetup
                  ? 'Für Eltern: Bisher war der Erstzugang 2468. Lege jetzt eine eigene PIN fest und bewahre sie getrennt vom Kindergerät auf.'
                  : 'Wähle eine eigene PIN mit 4 bis 8 Ziffern. Deine Lernstände bleiben erhalten.'),
              for (final entry in [
                (_pin, 'Neue PIN'),
                (_confirmation, 'PIN wiederholen')
              ])
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: entry.$1,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        InputDecoration(labelText: entry.$2, counterText: ''),
                  ),
                ),
            ] else ...[
              const Text('Dein Wiederherstellungscode',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(_recoveryCode!,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                  'Notiere diesen Code an einem sicheren Ort. Damit kannst du eine vergessene PIN ersetzen, ohne Lernstände zu löschen. Er wird nur jetzt angezeigt. Ein früherer Wiederherstellungscode wird nach dem Speichern ungültig.'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _recorded,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _recorded = value ?? false),
                title: const Text('Ich habe den Code sicher notiert.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        )),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Später'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : _recoveryCode == null
                  ? _prepareCode
                  : _recorded
                      ? _save
                      : null,
          child: Text(_recoveryCode == null ? 'Weiter' : 'PIN speichern'),
        ),
      ],
    );
  }
}

class ParentPinRecoveryDialog extends StatefulWidget {
  const ParentPinRecoveryDialog({super.key, required this.settings});

  final AppSettings settings;

  static Future<AppSettings?> show(BuildContext context) async {
    final settings = await SettingsRepository.load();
    if (!context.mounted) return null;
    return showDialog<AppSettings>(
      context: context,
      builder: (_) => ParentPinRecoveryDialog(settings: settings),
    );
  }

  @override
  State<ParentPinRecoveryDialog> createState() =>
      _ParentPinRecoveryDialogState();
}

class _ParentPinRecoveryDialogState extends State<ParentPinRecoveryDialog> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _recover() async {
    if (_busy) return;
    final code = _code.text;
    if (!ParentPinRecovery.matches(
        code, widget.settings.parentRecoveryCodeHash)) {
      setState(() => _error = 'Der Wiederherstellungscode stimmt nicht.');
      return;
    }
    setState(() => _busy = true);
    final next = await ParentPinSetupDialog.show(
      context,
      settings: widget.settings,
      recoveryCode: code,
    );
    if (!mounted) return;
    if (next != null) {
      Navigator.of(context).pop(next);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('PIN vergessen?'),
        content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.settings.hasParentRecoveryCode
                    ? 'Gib den Code ein, den du bei der PIN-Einrichtung notiert hast. Anschließend legst du eine neue PIN fest. Die Lernstände bleiben erhalten.'
                    : 'Für diese PIN wurde noch kein Wiederherstellungscode eingerichtet. Eine eigene PIN kann ohne diesen Nachweis nicht zurückgesetzt werden. Wenn du die PIN noch kennst, richte im Elternbereich einen Code ein. Bitte lösche keine App-Daten; deine Lernstände bleiben so erhalten.'),
                if (widget.settings.hasParentRecoveryCode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    enabled: !_busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                        labelText: 'Wiederherstellungscode'),
                  ),
                ],
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ))),
        actions: [
          TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Schließen')),
          if (widget.settings.hasParentRecoveryCode)
            FilledButton(
                onPressed: _busy ? null : _recover,
                child: const Text('Code prüfen')),
        ],
      );
}
