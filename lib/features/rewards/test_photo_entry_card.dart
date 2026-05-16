import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/reward_shop_repository.dart';
import '../../domain/rewards/reward_shop.dart';

/// Karte fuer Eltern um Test-Noten einzugeben.
///
/// Heinz' Wunsch: Bei guten Test-Noten gibt es Punkte.
/// Eltern fotografieren den Test (oder ueberspringen das Foto),
/// geben Fach und Note ein, App vergibt Punkte automatisch.
///
/// Noten-Skala (Oesterreich):
///   1 (Sehr gut)     = 50 Punkte
///   2 (Gut)          = 25 Punkte
///   3 (Befriedigend) = 10 Punkte
///   4 (Genuegend)    =  3 Punkte
///   5 (Nicht gen.)   =  0 Punkte
class TestPhotoEntryCard extends StatefulWidget {
  const TestPhotoEntryCard({
    super.key,
    required this.appState,
    this.onAdded,
  });

  final LumoAppState appState;
  final VoidCallback? onAdded;

  @override
  State<TestPhotoEntryCard> createState() => _TestPhotoEntryCardState();
}

class _TestPhotoEntryCardState extends State<TestPhotoEntryCard> {
  static const _engine = RewardShopEngine();
  static const _repo = RewardShopRepository();
  final _picker = ImagePicker();
  final _subjectController = TextEditingController();
  int _selectedNote = 1;
  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (file == null || !mounted) return;
      setState(() => _imagePath = file.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto konnte nicht aufgenommen werden.')),
      );
    }
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib das Fach ein (z.B. Mathe, Deutsch).')),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final current = await _repo.load(_childId);
      final updated = _engine.addTestPhoto(
        current,
        subject: subject,
        grade: widget.appState.state.grade,
        note: _selectedNote,
        imagePath: _imagePath,
      );
      await _repo.save(_childId, updated);
      if (!mounted) return;
      final points = TestPhotoEntry.pointsForNote(_selectedNote);
      // Reset Form
      _subjectController.clear();
      setState(() {
        _selectedNote = 1;
        _imagePath = null;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: points > 0 ? const Color(0xFF22C55E) : LumoColors.ink500,
          content: Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  points > 0
                      ? '$points Punkte für Note $_selectedNote in $subject hinzugefügt!'
                      : 'Eintrag für $subject gespeichert.',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
      widget.onAdded?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notePoints = TestPhotoEntry.pointsForNote(_selectedNote);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDF4FF), Color(0xFFFAE8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text('📸', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test-Note eingeben',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF581C87),
                      ),
                    ),
                    Text(
                      'Foto vom Test + Note → Punkte zum Einlösen',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Foto-Vorschau oder Aufnahme-Button
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_imagePath!),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => setState(() => _imagePath = null),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Foto entfernen', style: TextStyle(fontSize: 12)),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickPhoto,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Foto vom Test machen (optional)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFFC4B5FD), width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          const SizedBox(height: 12),
          // Fach-Eingabe
          TextField(
            controller: _subjectController,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'Fach',
              hintText: 'z.B. Mathe, Deutsch, Sachunterricht',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Note (Österreich)',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
          ),
          const SizedBox(height: 6),
          // Note-Auswahl 1-5
          Row(
            children: List.generate(5, (i) {
              final note = i + 1;
              final selected = note == _selectedNote;
              final color = _noteColor(note);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  child: InkWell(
                    onTap: _saving ? null : () => setState(() => _selectedNote = note),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(colors: [color, color.withOpacity(0.75)])
                            : LinearGradient(colors: [Colors.white, Colors.white.withOpacity(0.95)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color, width: 1.6),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$note',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Punkte-Vorschau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: notePoints > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: notePoints > 0 ? const Color(0xFF22C55E) : const Color(0xFFFCA5A5),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(notePoints > 0 ? '💎' : '💪', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notePoints > 0
                        ? 'Gibt $notePoints Punkte zum Einlösen für ${widget.appState.state.childName}.'
                        : 'Diese Note gibt keine Punkte. Beim nächsten Mal klappt es bestimmt!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: notePoints > 0 ? const Color(0xFF14532D) : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Speichern-Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_saving ? 'Speichert…' : 'Punkte hinzufügen'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _noteColor(int note) {
    switch (note) {
      case 1: return const Color(0xFF22C55E);
      case 2: return const Color(0xFF84CC16);
      case 3: return const Color(0xFFFFB800);
      case 4: return const Color(0xFFEA580C);
      default: return const Color(0xFFEF4444);
    }
  }
}
