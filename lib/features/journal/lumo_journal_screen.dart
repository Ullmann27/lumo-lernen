// ════════════════════════════════════════════════════════════════════════
// LUMO JOURNAL — Magisches Tagebuch fuer eigene Geschichten
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 37: Heinz' Innovations-Plan Schritt 5 von 5. Tochter
// schreibt frei eigene Geschichten oder Tagebuch-Eintraege. Lumo liest
// (analysiert lokal: Wort-Anzahl, ausgewaehlte gute Woerter) und lobt
// ehrlich + motivierend. Persistenz lokal (SharedPreferences, max 50
// Eintraege).
//
// Pedagogik: freies Schreiben fuer K2-K4 fest verankert im AT-Lehrplan.
// Sicher: keine Cloud, keine Veroeffentlichung.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import 'journal_repository.dart';

class LumoJournalScreen extends StatefulWidget {
  const LumoJournalScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoJournalScreen> createState() => _LumoJournalScreenState();
}

class _LumoJournalScreenState extends State<LumoJournalScreen> {
  final _repo = const JournalRepository();
  List<JournalEntry> _entries = const [];
  bool _writing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final entries = await _repo.load();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _saveEntry(String title, String text) async {
    await _repo.add(title: title, text: text);
    HapticFeedback.mediumImpact();
    setState(() => _writing = false);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mein Lumo-Journal',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_writing)
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 28),
              onPressed: () => setState(() => _writing = true),
            ),
        ],
      ),
      body: LumoMagicBackground(
        intensity: 0.95,
        starCount: 16,
        child: SafeArea(
          child: _writing
              ? _Editor(
                  onSave: _saveEntry,
                  onCancel: () => setState(() => _writing = false),
                )
              : _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white))
                  : _EntriesList(
                      entries: _entries,
                      onNew: () => setState(() => _writing = true),
                    ),
        ),
      ),
    );
  }
}

// ── EDITOR ────────────────────────────────────────────────────────────

class _Editor extends StatefulWidget {
  const _Editor({required this.onSave, required this.onCancel});
  final void Function(String title, String text) onSave;
  final VoidCallback onCancel;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final _titleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _showPraise = false;
  _PraiseResult? _praise;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _evaluate() {
    setState(() {
      _praise = _LumoCritic.evaluate(_textCtrl.text);
      _showPraise = true;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditorHeader(),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Titel deiner Geschichte ...',
                    hintStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: LumoColors.ink300,
                    ),
                    border: InputBorder.none,
                  ),
                ),
                const Divider(color: Color(0xFFE5E7EB)),
                TextField(
                  controller: _textCtrl,
                  maxLines: 12,
                  minLines: 8,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LumoColors.ink800,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Schreib hier deine Geschichte oder '
                        'dein Tagebuch...\n\nEs war einmal...',
                    hintStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LumoColors.ink300,
                      height: 1.4,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) =>
                      setState(() => _showPraise = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_showPraise && _praise != null) ...[
            _PraiseCard(praise: _praise!),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _textCtrl.text.trim().isEmpty ? null : _evaluate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _textCtrl.text.trim().isEmpty
                            ? const [
                                Color(0xFF9CA3AF),
                                Color(0xFF6B7280)
                              ]
                            : const [
                                Color(0xFF6366F1),
                                Color(0xFFA855F7)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Lumo liest',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_praise?.canSave ?? false) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => widget.onSave(
                  _titleCtrl.text, _textCtrl.text),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFFEA580C).withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 7),
                    Text(
                      'In Lumo-Journal speichern',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/companion/lumo_think.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✨ Schreib was du moechtest',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Eine Geschichte, ein Tagebuch-Eintrag, oder was '
                  'dir heute eingefallen ist.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFCE7F3),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PraiseCard extends StatelessWidget {
  const _PraiseCard({required this.praise});
  final _PraiseResult praise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFFB923C), width: 1.6),
            ),
            child: ClipOval(
              child: Image.asset(
                praise.cheer
                    ? 'assets/companion/lumo_cheer.png'
                    : 'assets/companion/lumo_idle.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  praise.title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C2D12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  praise.message,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
                if (praise.tips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final t in praise.tips) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEA580C))),
                        Expanded(
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7C2D12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ENTRIES LIST ──────────────────────────────────────────────────────

class _EntriesList extends StatelessWidget {
  const _EntriesList({required this.entries, required this.onNew});
  final List<JournalEntry> entries;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            _Empty(onNew: onNew),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ListHeader(count: entries.length, onNew: onNew),
          );
        }
        final e = entries[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _EntryCard(entry: e),
        );
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.count, required this.onNew});
  final int count;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/companion/lumo_idle.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 30)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Geschichten',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Tippe + um eine neue zu schreiben',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFCE7F3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/companion/lumo_think.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🦊', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Dein Journal ist noch leer',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Schreib deine erste Geschichte oder einen\n'
                'Tagebuch-Eintrag. Lumo wartet schon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Jetzt schreiben',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final relative = _relativeDate(entry.createdAt);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            left: BorderSide(
                color: const Color(0xFFA855F7), width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${entry.wordCount} Woerter',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: LumoColors.ink600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            relative,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: LumoColors.ink400,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inHours < 1) return 'vor ${diff.inMinutes} Minuten';
    if (diff.inDays < 1) return 'vor ${diff.inHours} Stunden';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ── LUMO-CRITIC: lokaler Lese-Feedback-Generator ──────────────────────

class _PraiseResult {
  const _PraiseResult({
    required this.title,
    required this.message,
    required this.tips,
    required this.canSave,
    required this.cheer,
  });
  final String title;
  final String message;
  final List<String> tips;
  final bool canSave;
  final bool cheer;
}

class _LumoCritic {
  /// Liefert ein freundliches, lehrreiches Feedback. Lokal, ohne Cloud,
  /// damit Privatsphaere geschuetzt ist. Bewertet rein quantitativ
  /// (Wort-Anzahl, Satz-Anzahl, ausgewaehlte gute Woerter), keine
  /// inhaltliche Zensur.
  static _PraiseResult evaluate(String text) {
    final trimmed = text.trim();
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final sentences = trimmed
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final wordCount = words.length;
    final sentenceCount = sentences.length;

    if (wordCount < 5) {
      return const _PraiseResult(
        title: 'Schreib noch ein bisschen mehr',
        message:
            'Das ist erst der Anfang. Schreib mindestens 5 Woerter dann lese ich richtig durch.',
        tips: [],
        canSave: false,
        cheer: false,
      );
    }

    final goodWords = _countGoodWords(words);
    final hasPunctuation =
        trimmed.contains(RegExp(r'[.!?]'));
    final hasCapital =
        trimmed.split('').any((c) => RegExp(r'[A-ZÄÖÜ]').hasMatch(c));

    final tips = <String>[];
    if (!hasCapital) {
      tips.add(
          'Tipp: Namenswoerter (Tisch, Mama, Hund) schreibst du gross.');
    }
    if (!hasPunctuation) {
      tips.add('Tipp: Setze einen Punkt am Ende von jedem Satz.');
    }
    if (sentenceCount < 2 && wordCount > 30) {
      tips.add(
          'Tipp: Lange Texte in mehrere Saetze teilen, das liest sich leichter.');
    }

    String title;
    String message;
    bool cheer;
    if (wordCount >= 100) {
      title = '🌟 Spitzen-Geschichte!';
      message =
          'Wow $wordCount Woerter! Das war richtig viel zu lesen. Du hast einen tollen Schreib-Fluss!';
      cheer = true;
    } else if (wordCount >= 50) {
      title = '🦊 Schön gemacht!';
      message =
          'Ich habe deine $wordCount Woerter gelesen. Eine richtig schoene Geschichte!';
      cheer = true;
    } else if (wordCount >= 20) {
      title = '✨ Gut!';
      message =
          'Du hast $wordCount Woerter geschrieben. Probier beim naechsten Mal noch ein paar Saetze dazu - dann wird die Geschichte noch reicher.';
      cheer = false;
    } else {
      title = 'Toller Anfang!';
      message =
          'Du hast $wordCount Woerter geschrieben. Schreib doch weiter, was als naechstes passiert?';
      cheer = false;
    }

    if (goodWords >= 3) {
      message = '$message Du verwendest auch tolle Woerter wie '
          'gut beschreibende Adjektive!';
    }

    return _PraiseResult(
      title: title,
      message: message,
      tips: tips,
      canSave: true,
      cheer: cheer,
    );
  }

  /// Liest die Woerter und zaehlt 'reiche' Adjektive/Verben als
  /// positive Signale.
  static int _countGoodWords(List<String> words) {
    const goodList = <String>{
      'wunderbar', 'magisch', 'leuchtend', 'glitzernd', 'goldig',
      'vorsichtig', 'mutig', 'tapfer', 'klug', 'staunend', 'aufgeregt',
      'gluecklich', 'leise', 'schnell', 'plötzlich', 'ploetzlich',
      'leuchten', 'fluestern', 'tanzen', 'staunen', 'huepfen',
      'entdecken', 'erforschen', 'klettern', 'singen', 'lachen',
    };
    var count = 0;
    for (final w in words) {
      final lw = w.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');
      if (goodList.contains(lw)) count++;
    }
    return count;
  }
}
