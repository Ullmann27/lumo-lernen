import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/lumo_visual_tokens.dart';

/// A grade-4 creative-writing exercise, independent of enrolled-grade XP.
/// Children can draft and save their own text without an AI dependency.
class CrossGradeWritingScreen extends StatefulWidget {
  const CrossGradeWritingScreen({
    super.key,
    required this.profileName,
    required this.enrolledGrade,
  });

  final String profileName;
  final int enrolledGrade;

  @override
  State<CrossGradeWritingScreen> createState() =>
      _CrossGradeWritingScreenState();
}

class _CrossGradeWritingScreenState extends State<CrossGradeWritingScreen> {
  final _controller = TextEditingController();
  int _promptIndex = 0;
  bool _saved = false;

  static const _prompts = <({String title, String prompt, String hint})>[
    (
      title: 'Ein unerwartetes Abenteuer',
      prompt: 'Lumo entdeckt vor der Schule eine geheimnisvolle Karte. '
          'Erzähle, wohin sie führt und was er dort erlebt.',
      hint: 'Gliedere deine Geschichte in Anfang, Hauptteil und Schluss.',
    ),
    (
      title: 'Ein Brief aus der Zukunft',
      prompt: 'Schreibe einen Brief an ein Kind in zwanzig Jahren. '
          'Was möchtest du erzählen und was möchtest du wissen?',
      hint: 'Denke an Anrede, verständliche Sätze und einen Gruß am Ende.',
    ),
    (
      title: 'Sachtext: Mein Lieblingsort',
      prompt: 'Beschreibe einen Ort in Österreich so genau, dass jemand '
          'ihn sich vorstellen kann, ohne ihn je gesehen zu haben.',
      hint: 'Ordne die wichtigsten Informationen und verwende genaue Wörter.',
    ),
    (
      title: 'Eine Meinung begründen',
      prompt: 'Soll es in der Schule täglich mehr Zeit zum freien '
          'Lesen geben? Schreibe deine Meinung und begründe sie.',
      hint: 'Schreibe deine Position, mindestens zwei Gründe und einen Schluss.',
    ),
  ];

  String get _scope {
    final safeName = widget.profileName.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9äöüß]+'),
          '_',
        );
    return 'cross_grade_writing_v1:${safeName.isEmpty ? 'kind' : safeName}:4:aufsatz';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _promptIndex = (prefs.getInt('$_scope:prompt') ?? 0)
          .clamp(0, _prompts.length - 1);
      _controller.text = prefs.getString('$_scope:draft:$_promptIndex') ?? '';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_scope:draft:$_promptIndex', _controller.text);
    await prefs.setInt('$_scope:prompt', _promptIndex);
    if (mounted) setState(() => _saved = true);
  }

  Future<void> _nextPrompt() async {
    await _save();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _promptIndex = (_promptIndex + 1) % _prompts.length;
      _controller.text =
          prefs.getString('$_scope:draft:$_promptIndex') ?? '';
      _saved = false;
    });
    await prefs.setInt('$_scope:prompt', _promptIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _prompts[_promptIndex];
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10294D),
        foregroundColor: Colors.white,
        title: const Text('4. Klasse · Aufsätze'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              exercise.title,
              key: const ValueKey('cross-grade-writing-topic'),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(exercise.prompt,
                style: const TextStyle(color: Colors.white, fontSize: 17)),
            const SizedBox(height: 12),
            Text(exercise.hint,
                style: const TextStyle(
                  color: Color(0xFF8EE5EC),
                  fontSize: 15,
                )),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('cross-grade-writing-input'),
              controller: _controller,
              onChanged: (_) {
                if (_saved) setState(() => _saved = false);
              },
              maxLines: 9,
              minLines: 6,
              maxLength: 5000,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Dein eigener Text',
                labelStyle: const TextStyle(color: Color(0xFFBAEAF3)),
                filled: true,
                fillColor: const Color(0xFF16345B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const Text(
              'Prüfe: Sind Anfang, Hauptteil und Schluss erkennbar? '
              'Sind deine Sätze verständlich? Hast du die Schreibweise kontrolliert?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('cross-grade-writing-save'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Text auf diesem Gerät speichern'),
            ),
            if (_saved)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Gespeichert – die Profilklasse und regulären Sterne '
                  'bleiben unverändert.',
                  key: ValueKey('cross-grade-writing-saved'),
                  style: TextStyle(color: Color(0xFF77F0B8)),
                ),
              ),
            OutlinedButton(
              key: const ValueKey('cross-grade-writing-next'),
              onPressed: _nextPrompt,
              child: const Text('Nächste Schreibidee'),
            ),
            const SizedBox(height: 10),
            Text(
              'Freies Schreiben zum Vor- oder Wiederholen. '
              'Dein Schulprofil bleibt in der ${widget.enrolledGrade}. Klasse.',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
