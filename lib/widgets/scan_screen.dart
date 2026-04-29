import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Stabiler Foto-/Review-Scanner ohne ML-Kit-Abhaengigkeit.
/// OCR bleibt architektonisch vorbereitet, wird aber erst nach gruenem APK-Build
/// wieder als on-device Modul aktiviert.
class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.onTextDetected,
    required this.onCancel,
  });

  final ValueChanged<String> onTextDetected;
  final VoidCallback onCancel;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _previewPath;

  @override
  void dispose() {
    _textController.dispose();
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
      if (!mounted) return;
      setState(() {
        _busy = false;
        _previewPath = file?.path;
      });
      if (file == null) return;
      _textController.text = 'Foto wurde übernommen. OCR wird im nächsten stabilen Schritt wieder aktiviert. Du kannst die erkannte Aufgabe hier vorerst selbst eintragen.';
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Es hat nicht geklappt. Versuch es noch einmal.';
      });
    }
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Bitte trage kurz ein, was auf der Aufgabe steht.');
      return;
    }
    widget.onTextDetected(text);
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
        border: Border.all(color: Colors.white.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(color: Colors.deepOrange.withValues(alpha: .10), blurRadius: 24, offset: const Offset(0, 14)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.photo_camera_rounded, color: Color(0xffff7a2f), size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aufgabe fotografieren',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xff2d2621)),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Mach ein Foto deiner Aufgabe. Bis OCR wieder stabil aktiviert ist, kannst du den Aufgabentext darunter eintragen.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xff766a61), height: 1.3),
            ),
            const SizedBox(height: 14),
            if (_previewPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(_previewPath!),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const Row(children: [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6)),
                SizedBox(width: 12),
                Expanded(child: Text('Lumo übernimmt dein Foto…', style: TextStyle(fontWeight: FontWeight.w800))),
              ]),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _textController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Aufgabe oder Text eintragen',
                hintText: 'z.B. 12 + 7 = ? oder Silben von Schokolade',
              ),
            ),
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
                  const Icon(Icons.info_outline_rounded, color: Color(0xffd14655), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff8b1d27)))),
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
                  label: const Text('Galerie'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _submitText,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Übernehmen'),
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xff10a894)),
            ),
          ],
        ),
      ),
    );
  }
}
