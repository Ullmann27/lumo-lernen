import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Explicit model-use assent, not an identity verification or privacy consent.
/// A full parental PIN/account verification remains a separate release gate.
class LocalVoiceLicenseDialog extends StatefulWidget {
  const LocalVoiceLicenseDialog({super.key, required this.license});
  final String license;

  static Future<bool> show(BuildContext context) async {
    final license = await rootBundle
        .loadString('assets/audio/voice/lumo_free/LICENSE-MODEL.txt');
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (_) => LocalVoiceLicenseDialog(license: license),
        ) ??
        false;
  }

  @override
  State<LocalVoiceLicenseDialog> createState() => _LocalLicenseState();
}

class _LocalLicenseState extends State<LocalVoiceLicenseDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.sizeOf(context).height - 48,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Neue Sätze kostenlos vorlesen',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                const Text(
                  'Für Erwachsene: Lumo Frei ist eine KI-erzeugte deutsche '
                  'Stimme. Neue Texte werden nur auf diesem Gerät vertont. '
                  'Dafür wird kein Sprach-API-Aufruf abgerechnet und kein '
                  'Text an einen Sprachserver übertragen.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: SingleChildScrollView(
                    child: SelectableText(widget.license,
                        style: const TextStyle(fontSize: 14, height: 1.4)),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _accepted,
                  controlAffinity: ListTileControlAffinity.leading,
                  titleAlignment: ListTileTitleAlignment.top,
                  title: const Text(
                      'Als erwachsene Person akzeptiere ich für die lokale '
                      'Sprachfunktion die obenstehenden Modellbedingungen '
                      'einschließlich der Nutzungsbeschränkungen.'),
                  onChanged: (value) =>
                      setState(() => _accepted = value == true),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Abbrechen'),
                    ),
                    FilledButton(
                      onPressed: _accepted
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: const Text('Lokale Stimme freigeben'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
