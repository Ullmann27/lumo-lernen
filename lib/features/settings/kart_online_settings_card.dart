import 'package:flutter/material.dart';

import '../../core/app_settings.dart';

/// Adult-only setup. Opening this card never connects to the game relay.
class KartOnlineSettingsCard extends StatefulWidget {
  const KartOnlineSettingsCard({
    super.key,
    required this.settings,
    required this.onSave,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings) onSave;

  @override
  State<KartOnlineSettingsCard> createState() => _KartOnlineSettingsCardState();
}

class _KartOnlineSettingsCardState extends State<KartOnlineSettingsCard> {
  late final TextEditingController _address =
      TextEditingController(text: widget.settings.kartOnlineUrl);
  bool _saving = false;
  String? _error;

  @override
  void didUpdateWidget(covariant KartOnlineSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.kartOnlineUrl != widget.settings.kartOnlineUrl) {
      _address.text = widget.settings.kartOnlineUrl;
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save({bool? enabled}) async {
    if (_saving) return;
    final raw = _address.text.trim();
    final address = AppSettings.sanitizeKartOnlineUrl(raw);
    if ((raw.isNotEmpty && address.isEmpty) ||
        (enabled == true && address.isEmpty)) {
      setState(() => _error =
          'Bitte eine verschlüsselte Spielserver-Adresse mit wss:// eintragen.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(widget.settings.copyWith(
        kartOnlineEnabled: address.isNotEmpty &&
            (enabled ?? widget.settings.kartOnlineEnabled),
        kartOnlineUrl: address,
      ));
    } catch (_) {
      if (mounted) setState(() => _error = 'Speichern nicht möglich. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured =
        AppSettings.sanitizeKartOnlineUrl(widget.settings.kartOnlineUrl).isNotEmpty;
    return Card(
      key: const ValueKey('kartOnlineSettingsCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Lumo Kart · Online-Rennen',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Mit einem selbst gewählten Spielernamen Freunde finden, '
              'eine Einladung annehmen und gleichzeitig gegeneinander fahren. '
              'Es gibt keinen freien Chat und keine automatische Suche nach Fremden.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Der Spielserver erhält euren Spielernamen, eine Gerätekennung und '
              'Rennbewegungen. Lernstände, echter Name, Mikrofon und Kontakte '
              'werden dafür nicht übertragen.',
            ),
            SwitchListTile.adaptive(
              key: const ValueKey('kartOnlineConsent'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Online-Rennen erlauben'),
              subtitle: Text(configured
                  ? 'Verbindet erst, wenn im Kart „Online“ geöffnet wird.'
                  : 'Der Spielserver muss zuerst eingerichtet werden.'),
              value: widget.settings.kartOnlineEnabled,
              onChanged: _saving ? null : (value) => _save(enabled: value),
            ),
            ExpansionTile(
              key: const ValueKey('kartOnlineConnectionSettings'),
              tilePadding: EdgeInsets.zero,
              title: const Text('Spielserver-Verbindung'),
              initiallyExpanded: !configured,
              children: [
                TextField(
                  key: const ValueKey('kartOnlineEndpoint'),
                  controller: _address,
                  enabled: !_saving,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Verschlüsselte Server-Adresse',
                    hintText: 'wss://…/ws',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('kartOnlineSave'),
                    onPressed: _saving ? null : () => _save(),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Verbindung speichern'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Text(_error!,
                    key: const ValueKey('kartOnlineSettingsError'),
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
    );
  }
}
