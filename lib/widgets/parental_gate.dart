import 'package:flutter/material.dart';

import '../core/parent_pin_service.dart';

class ParentalGate extends StatefulWidget {
  const ParentalGate({super.key});

  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.all(20),
        child: ParentalGate(),
      ),
    );
    return ok ?? false;
  }

  @override
  State<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  static const _pinService = ParentPinService();

  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = true;
  bool _setupMode = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isSet = await _pinService.isPinSet();
    if (!mounted) return;
    setState(() {
      _setupMode = !isSet;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_setupMode) {
        final pin = _pinController.text.trim();
        final confirm = _confirmController.text.trim();
        if (pin != confirm) {
          setState(() => _error = 'Die beiden PINs stimmen nicht überein.');
          return;
        }
        await _pinService.createPin(pin);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final ok = await _pinService.verifyPin(_pinController.text.trim());
        if (ok) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          setState(() => _error = 'PIN nicht erkannt. Bitte erneut eingeben.');
        }
      }
    } on ParentPinException {
      setState(() => _error = 'Die PIN muss aus 4 bis 12 Ziffern bestehen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: _loading
          ? const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xffff7a2f), Color(0xffff9a5c)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _setupMode ? 'Eltern-PIN erstellen' : 'Bereich für Erwachsene',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xff2d2621)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(
                  _setupMode
                      ? 'Lege eine Eltern-PIN fest. Sie schützt Einstellungen, Datenschutz und Verwaltungsbereiche.'
                      : 'Bitte gib die Eltern-PIN ein, um diesen Bereich zu öffnen.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff6b6258), height: 1.35),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _pinController,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textInputAction: _setupMode ? TextInputAction.next : TextInputAction.done,
                  onSubmitted: (_) => _setupMode ? FocusScope.of(context).nextFocus() : _submit(),
                  decoration: InputDecoration(
                    hintText: _setupMode ? 'Neue PIN' : 'Eltern-PIN',
                    filled: true,
                    fillColor: const Color(0xfff8f4ee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xff766a61)),
                  ),
                ),
                if (_setupMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'PIN wiederholen',
                      filled: true,
                      fillColor: const Color(0xfff8f4ee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.verified_user_rounded, color: Color(0xff766a61)),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Color(0xffd14655), fontWeight: FontWeight.w800)),
                ],
                const SizedBox(height: 10),
                Text(
                  _pinService.forgottenPinRecoveryHint,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff8a7d72), height: 1.25),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: const Text('Abbrechen'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_setupMode ? 'PIN speichern' : 'Bestätigen'),
                    ),
                  ),
                ]),
              ],
            ),
    );
  }
}
