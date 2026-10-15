// ════════════════════════════════════════════════════════════════════════
// LUMO STORY LIBRARY VIEW — Bibliothek aller erstellten Geschichten
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_story_library.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/design/lumo_glass_optics.dart';
import '../../widgets/fox/lumo_character.dart';
import '../../theme/lumo_visual_tokens.dart';

import 'lumo_story_reader_screen.dart';
import 'lumo_story_setup_screen.dart';

class LumoStoryLibraryScreen extends StatefulWidget {
  const LumoStoryLibraryScreen({
    super.key,
    required this.appState,
    this.gradeLevel,
  });
  final LumoAppState appState;

  /// Optionaler Lernpfadfilter; ohne Filter bleiben alle Hefte sichtbar.
  final int? gradeLevel;

  @override
  State<LumoStoryLibraryScreen> createState() => _LumoStoryLibraryScreenState();
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
        builder: (_) => LumoStorySetupScreen(
          appState: widget.appState,
          initialGrade: widget.gradeLevel,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lib = LumoStoryLibrary.instance;
    var stories = _showFavOnly ? lib.favorites : lib.all.toList();
    if (widget.gradeLevel != null) {
      stories = stories
          .where((stored) => stored.story.gradeLevel == widget.gradeLevel)
          .toList();
    }
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
        stories
            .sort((a, b) => a.story.gradeLevel.compareTo(b.story.gradeLevel));
        break;
    }
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.library,
        dimmed: true,
        child: SafeArea(
            child: ListView(
          key: const PageStorageKey('story-library-scroll'),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildTopBar(lib),
            _buildSearchAndSort(),
            Padding(padding: const EdgeInsets.all(16), child: _libraryPortal()),
            if (stories.isEmpty)
              _buildEmpty()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deine Bibliothek (${stories.length})',
                          style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 700 &&
                                MediaQuery.textScalerOf(context).scale(1) <= 1.3
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 16) /
                                columns;
                        return Wrap(spacing: 16, runSpacing: 16, children: [
                          for (final s in stories)
                            SizedBox(
                                width: width,
                                child: _StoryCard(
                                  stored: s,
                                  onTap: () => _openStory(s),
                                  onFav: () async {
                                    await lib.toggleFavorite(s.id);
                                    if (mounted) setState(() {});
                                  },
                                  onDelete: () => _confirmDelete(s),
                                )),
                        ]);
                      }),
                    ]),
              ),
          ],
        )),
      ),
    );
  }

  Widget _libraryPortal() => LumoGlassCard(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(builder: (context, constraints) {
          final showFox = constraints.maxWidth > 300;
          return Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('LUMOS STERNENBIBLIOTHEK',
                      style: TextStyle(
                          color: LumoVisualTokens.cyanBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  const Text('Ein Buch.\nEine neue Welt.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          height: 1.12)),
                  const SizedBox(height: 10),
                  const Text(
                      'Lies hinein und entdecke dein nächstes Abenteuer.',
                      style: TextStyle(
                          color: LumoVisualTokens.muted, fontSize: 14)),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                      onPressed: _createNew,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Neue Geschichte!'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: LumoVisualTokens.cyanBright,
                          foregroundColor: LumoVisualTokens.navigation)),
                ])),
            if (showFox)
              SizedBox(
                  width: 125,
                  height: 160,
                  child: LumoLightPlinth(
                      child: LumoCharacter(
                    pose: LumoDesignFoxPose.bookWelcome,
                    size: 125,
                    idleHops: false,
                    reduceMotion:
                        widget.appState.state.settings.reduceAnimations ||
                            widget.appState.state.settings.calmMode ||
                            MediaQuery.disableAnimationsOf(context),
                  ))),
          ]);
        }),
      );

  Widget _buildTopBar(LumoStoryLibrary lib) {
    final visibleCount = widget.gradeLevel == null
        ? lib.count
        : lib.all
            .where((stored) => stored.story.gradeLevel == widget.gradeLevel)
            .length;
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Der Titel bleibt neben Zurück- und Favoritenknopf
                // einzeilig, auch auf dem schmalen Fold-Außendisplay.
                Tooltip(
                  message: widget.gradeLevel == null
                      ? 'Meine Geschichten'
                      : 'Geschichten · Lesen & verstehen',
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.gradeLevel == null
                          ? 'Meine Geschichten'
                          : 'Geschichten · Lesen & verstehen',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: LumoTokens.typo.headlineLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
                Text(
                    widget.gradeLevel == null
                        ? '$visibleCount Hefte erschaffen'
                        : '${widget.gradeLevel}. Klasse · $visibleCount Hefte',
                    style: LumoTokens.typo.bodyMedium
                        .copyWith(color: LumoVisualTokens.muted)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_showFavOnly
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded),
            color: LumoTokens.colors.errorSoft,
            onPressed: () => setState(() => _showFavOnly = !_showFavOnly),
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
              fillColor: LumoVisualTokens.navigation,
              border: OutlineInputBorder(
                borderRadius: LumoTokens.brPill,
                borderSide: BorderSide(
                    color: LumoVisualTokens.cyan.withValues(alpha: .45)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: LumoTokens.brPill,
                borderSide: BorderSide(
                    color: LumoVisualTokens.cyan.withValues(alpha: .45)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<_StorySort>(
          icon:
              Icon(Icons.sort_rounded, color: LumoTokens.colors.lumoOrangeDeep),
          tooltip: 'Sortieren',
          onSelected: (v) => setState(() => _sort = v),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: _StorySort.newest, child: Text('Neueste zuerst')),
            const PopupMenuItem(
                value: _StorySort.mostRead, child: Text('Meist gelesen')),
            const PopupMenuItem(
                value: _StorySort.gradeAsc, child: Text('Nach Klassenstufe')),
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
            Image.asset('assets/lumo_design/icons/book_open.png',
                height: 100, excludeFromSemantics: true),
            const SizedBox(height: 16),
            Text(
                _searchQuery.isNotEmpty || _showFavOnly
                    ? 'Keine passenden Geschichten'
                    : 'Noch keine Geschichten',
                style: LumoTokens.typo.headlineMedium
                    .copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Erstelle dein erstes magisches Lese-Heft!',
                style: LumoTokens.typo.bodyLarge
                    .copyWith(color: LumoVisualTokens.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNew,
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('Erste Geschichte!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LumoVisualTokens.cyanBright,
                foregroundColor: LumoVisualTokens.navigation,
                textStyle: LumoTokens.typo.titleLarge,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
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
  Widget build(BuildContext context) => LumoGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _StoryBookCover(),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(stored.story.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    height: 1.18)),
                            const SizedBox(height: 10),
                            Wrap(spacing: 10, runSpacing: 4, children: [
                              Text('Klasse ${stored.story.gradeLevel}',
                                  style: const TextStyle(
                                      color: LumoVisualTokens.cyanBright)),
                              if (stored.timesRead > 0)
                                Text('${stored.timesRead}x gelesen',
                                    style: const TextStyle(
                                        color: LumoVisualTokens.muted)),
                            ]),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              for (final word in stored.story.newWords.take(3))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0x5537D2FD),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(word,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                )
                            ]),
                          ])),
                    ]),
              )),
          const SizedBox(height: 12),
          const Divider(color: Color(0x3337D2FD), height: 1),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                TextButton.icon(
                    key: ValueKey('story-preview-${stored.id}'),
                    onPressed: () => _preview(context),
                    icon: const Icon(Icons.auto_stories_rounded, size: 20),
                    label: const Text('Hineinlesen')),
                IconButton(
                    tooltip: stored.isFavorite
                        ? 'Favorit entfernen'
                        : 'Als Favorit merken',
                    onPressed: onFav,
                    icon: Icon(
                        stored.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: const Color(0xFFFF8BAD))),
                IconButton(
                    tooltip: 'Geschichte löschen',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: LumoVisualTokens.muted)),
              ]),
        ]),
      );

  // Preview is read-only: only opening the reader increments the stored count.
  void _preview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: LumoVisualTokens.navigation,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .65,
        minChildSize: .35,
        maxChildSize: .95,
        builder: (_, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              const Text('DEIN LESEFENSTER',
                  style: TextStyle(
                      color: LumoVisualTokens.cyanBright,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Text(stored.story.title,
                  style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              LumoGlassCard(
                  child: Text(
                      stored.story.pages.isEmpty
                          ? 'Dieses Heft enthält noch keine Seite.'
                          : stored.story.pages.first.text,
                      key: const ValueKey('story-preview-text'),
                      style: const TextStyle(
                          fontSize: 19, height: 1.65, color: Colors.white))),
              const SizedBox(height: 20),
              FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onTap();
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Geschichte öffnen')),
              TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Zur Bibliothek')),
            ]),
      ),
    );
  }
}

class _StoryBookCover extends StatelessWidget {
  const _StoryBookCover();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: SizedBox(
          width: 70,
          height: 100,
          child: Stack(children: [
            Positioned(
                left: 6,
                right: 0,
                top: 3,
                bottom: 0,
                child: Container(
                    decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(colors: [
                    Color(0xFF96C3DD),
                    Color(0xFFF4F0D9),
                    Color(0xFF6894A8)
                  ]),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x88000000),
                        blurRadius: 12,
                        offset: Offset(4, 6))
                  ],
                ))),
            Positioned(
                left: 0,
                right: 5,
                top: 0,
                bottom: 5,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.asset('assets/lumo_design/bg/bg_library.png',
                          fit: BoxFit.cover),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                        Color(0xEE03193F),
                        Color(0x5503193F),
                        Color(0x2203193F)
                      ], stops: [
                        0,
                        .13,
                        1
                      ]))),
                      Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                              'assets/lumo_design/icons/book_open.png',
                              width: 43,
                              height: 43)),
                      CustomPaint(painter: const LumoGlassOptics(radius: 8)),
                    ]))),
          ])));
}
