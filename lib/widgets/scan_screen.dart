import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Aufgaben-Scanner.
///
/// **Privacy / Play Store:**
/// - Verwendet `image_picker` → öffnet die SYSTEM-Kamera-UI.
///   Damit gilt das Standard-System-Permission-Dialog;
///   keine eigene Custom-UI, weniger Angriffsfläche.
/// - Verwendet `google_mlkit_text_recognition` → ON-DEVICE OCR
///   (TensorFlow Lite Modell läuft lokal).
///   Es werden KEINE Bilder oder Texte an externe Server gesendet.
///   Bilder werden nur temporär gespeichert (Image-Picker-Cache des OS).
/// - Kein Hochladen, kein Cloud-Upload, kein Tracking.
///
/// Geeignet für die "Designed for Families"-Kategorie im Play Store.
class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.onTextDetected,
    required this.onCancel,
  });

  /// Wird mit dem erkannten Text aufgerufen.
  final ValueChanged<String> onTextDetected;

  /// Wird beim Abbrechen / Schließen aufgerufen.
  final VoidCallback onCancel;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  late final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _busy = false;
  String? _error;
  String? _previewPath;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) {
        setState(() => _busy = false);
        return;
      }
      setState(() => _previewPath = file.path);

      final input = InputImage.fromFilePath(file.path);
      final result = await _recognizer.processImage(input);
      final text = result.text.trim();

      if (!mounted) return;
      setState(() => _busy = false);

      if (text.isEmpty) {
        setState(() => _error = 'Ich konnte keinen Text erkennen. '
            'Versuch es nochmal mit besserem Licht!');
        return;
      }
      widget.onTextDetected(text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Es hat nicht geklappt. Versuch es noch einmal.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xfffff4e3), Color(0xfffffaf2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.photo_camera_rounded, color: Color(0xffff7a2f), size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aufgabe fotografieren',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff2d2621),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Mach ein Foto deiner Hausaufgabe oder Schularbeit – '
            'Lumo erkennt den Text und hilft dir.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xff766a61),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Vorschau
          if (_previewPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(_previewPath!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          if (_busy) ...[
            const SizedBox(height: 16),
            Row(children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Lumo schaut sich dein Foto an…',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffffe4e6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffffc2c8)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xffd14655), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xff8b1d27),
                    ),
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _capture(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Foto machen'),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : () => _capture(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Aus Galerie wählen'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : widget.onCancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Abbrechen'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '🛡️ Dein Foto bleibt auf deinem Gerät. Es wird nichts ins Internet gesendet.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xff10a894),
            ),
          ),
        ],
      ),
    );
  }
}
