// ════════════════════════════════════════════════════════════════════════
// LUMO STORY LIBRARY VIEW — Bibliothek aller erstellten Geschichten
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_story_library.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/premium/lumo_hero_card.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import '../../widgets/premium/lumo_premium_card.dart';
import 'lumo_story_reader_screen.dart';
import 'lumo_story_setup_screen.dart';

class LumoStoryLibraryScreen extends StatefulWidget {
  const LumoStoryLibraryScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoStoryLibraryScreen> createState() =>
      _LumoStoryLibraryScreenState();
}

class _LumoStoryLibraryScreenState extends State<LumoStoryLibraryScreen> {
  bool _loaded = false;
  bool _showFavOnly = false;
  String _searchQuery = '';
  _StorySort _sort = _StorySort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await LumoStoryLibrary.instance.load();
    if (mounted) setState(() => _loaded = true);
  }

  void _openStory(StoredStory stored) async {
    await LumoStoryLibrary.instance.incrementRead(stored.id);
    if (!mounted) return;
    setState(() {});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LumoStoryReaderScreen(
          story: stored.story,
          appState: widget.appState,
          storyId: stored.id,
        ),
      ),
    );
  }

  void _createNew() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LumoStorySetupScreen(appState: widget.appState),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final lib = LumoStoryLibrary.instance;
    var stories = _showFavOnly ? lib.favorites : lib.all.toList();
    // Filter via Suche (Titel, Held, Ort, Thema)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      stories = stories.where((s) {
        final st = s.story;
        return st.title.toLowerCase().contains(q) ||
            st.heroName.toLowerCase().contains(q) ||
            st.location.toLowerCase().contains(q) ||
            st.theme.toLowerCase().contains(q);
      }).toList();
    }
    // Sortierung
    switch (_sort) {
      case _StorySort.newest:
        stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _StorySort.mostRead:
        stories.sort((a, b) => b.timesRead.compareTo(a.timesRead));
        break;
      case _StorySort.gradeAsc:
        stories.sort(
            (a, b) => a.story.gradeLevel.compareTo(b.story.gradeLevel));
        break;
    }
    return Scaffold(
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        intensity: 0.7,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(lib),
              _buildSearchAndSort(),
              Expanded(
                child: stories.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.all(LumoTokens.space16),
                        children: [
                          LumoHeroCard(
                            title: 'Neue Geschichte!',
                            subtitle: 'Lumo erfindet dir ein neues Heft',
                            icon: Icons.add_circle_rounded,
                            gradient: LumoTokens.colors.heroOrange,
                            glowColor: LumoTokens.colors.lumoOrange,
                            onTap: _createNew,
                          ),
                          const SizedBox(height: LumoTokens.space20),
                          Text('Deine Bibliothek (${stories.length})',
                              style: LumoTokens.typo.headlineMedium),
                          const SizedBox(height: LumoTokens.space12),
                          ...stories.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _StoryCard(
                                  stored: s,
                                  onTap: () => _openStory(s),
                                  onFav: () async {
                                    await lib.toggleFavorite(s.id);
                                    setState(() {});
                                  },
                                  onDelete: () => _confirmDelete(s),
                                ),
                              )),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(LumoStoryLibrary lib) {
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meine Geschichten',
                    style: LumoTokens.typo.headlineLarge),
                Text('${lib.count} Hefte erschaffen',
                    style: LumoTokens.typo.bodyMedium.copyWith(
                        color: LumoTokens.colors.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_showFavOnly
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded),
            color: LumoTokens.colors.errorSoft,
            onPressed: () =>
                setState(() => _showFavOnly = !_showFavOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: LumoTokens.space16, vertical: LumoTokens.space8),
      child: Row(children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Held, Ort oder Titel suchen…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: LumoTokens.brPill,
                borderSide: BorderSide(color: LumoTokens.colors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: LumoTokens.brPill,
                borderSide: BorderSide(color: LumoTokens.colors.outline),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<_StorySort>(
          icon: Icon(Icons.sort_rounded,
              color: LumoTokens.colors.lumoOrangeDeep),
          tooltip: 'Sortieren',
          onSelected: (v) => setState(() => _sort = v),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: _StorySort.newest, child: Text('Neueste zuerst')),
            const PopupMenuItem(
                value: _StorySort.mostRead, child: Text('Meist gelesen')),
            const PopupMenuItem(
                value: _StorySort.gradeAsc,
                child: Text('Nach Klassenstufe')),
          ],
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LumoTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text('Noch keine Geschichten',
                style: LumoTokens.typo.headlineMedium),
            const SizedBox(height: 8),
            Text(
                'Erstelle dein erstes magisches Lese-Heft!',
                style: LumoTokens.typo.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNew,
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('Erste Geschichte!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LumoTokens.colors.lumoOrange,
                foregroundColor: Colors.white,
                textStyle: LumoTokens.typo.titleLarge,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(StoredStory s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Heft loeschen?'),
        content: Text('"${s.story.title}" wirklich loeschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          TextButton(
            onPressed: () async {
              await LumoStoryLibrary.instance.delete(s.id);
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: Text('Loeschen',
                style: TextStyle(color: LumoTokens.colors.errorSoftDeep)),
          ),
        ],
      ),
    );
  }
}

enum _StorySort { newest, mostRead, gradeAsc }

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.stored,
    required this.onTap,
    required this.onFav,
    required this.onDelete,
  });
  final StoredStory stored;
  final VoidCallback onTap;
  final VoidCallback onFav;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LumoPremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LumoTokens.colors.heroLila,
              borderRadius: LumoTokens.brMedium,
            ),
            alignment: Alignment.center,
            child: const Text('📖', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: LumoTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stored.story.title,
                    style: LumoTokens.typo.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.school_rounded,
                      size: 14, color: LumoTokens.colors.textMuted),
                  const SizedBox(width: 4),
                  Text('Klasse ${stored.story.gradeLevel}',
                      style: LumoTokens.typo.bodySmall),
                  const SizedBox(width: 12),
                  if (stored.timesRead > 0) ...[
                    Icon(Icons.visibility_rounded,
                        size: 14, color: LumoTokens.colors.textMuted),
                    const SizedBox(width: 4),
                    Text('${stored.timesRead}x gelesen',
                        style: LumoTokens.typo.bodySmall),
                  ],
                ]),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: stored.story.newWords.take(3).map((w) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: LumoTokens.colors.lumoLila.withOpacity(0.1),
                          borderRadius: LumoTokens.brPill,
                        ),
                        child: Text(w,
                            style: LumoTokens.typo.labelSmall.copyWith(
                                color: LumoTokens.colors.lumoLilaDeep)),
                      )).toList(),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(stored.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                    color: LumoTokens.colors.errorSoft),
                onPressed: onFav,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: LumoTokens.colors.textMuted),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
