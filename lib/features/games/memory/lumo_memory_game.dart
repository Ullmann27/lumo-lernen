// ════════════════════════════════════════════════════════════════════════
// LUMO MEMORY — Karten-Merkspiel mit Lumo als aktivem Gegner
// ════════════════════════════════════════════════════════════════════════
// Optik nach Heinz' Bild „Lumo Memory“: leuchtende Karten, Tierbilder,
// Lumo schaut zu und reagiert. Spielregeln:
//   - Jedes Motiv kommt genau zweimal vor (siehe MemoryBoard.deal).
//   - Kind und Lumo decken abwechselnd zwei Karten auf.
//   - Paar gefunden -> Karten bleiben offen, derselbe Spieler ist nochmal dran.
//   - Kein Paar -> Karten drehen sich ruhig zurück, der andere ist dran.
//   - Lumo merkt sich gesehene Karten, vergisst aber manchmal (kindgerecht).
//   - Sieger: wer am Ende mehr Paare hat.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../../../domain/games/memory_board.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../shared/lumo_game_pause_scope.dart';

class LumoMemoryScreen extends StatefulWidget {
  const LumoMemoryScreen({
    super.key,
    required this.appState,
    this.seed,
    this.difficulty,
  });

  final int? seed;
  final LumoAppState appState;

  /// Feste Stufe (Tests). Ohne Angabe gilt die zuletzt gespielte Stufe.
  final MemoryDifficulty? difficulty;

  @override
  State<LumoMemoryScreen> createState() => _LumoMemoryScreenState();
}

enum _Player { kind, lumo }

class _LumoMemoryScreenState extends State<LumoMemoryScreen> {
  static const _prefsKey = 'lumo_memory_v2';
  static const _flip = Duration(milliseconds: 460);

  late MemoryDifficulty _difficulty;
  late List<MemoryMotif> _cards;
  late List<bool> _matched;
  late List<bool> _faceUp;
  int? _firstPickIdx;
  bool _busy = false;
  _Player _turn = _Player.kind;
  int _kindPairs = 0;
  int _lumoPairs = 0;
  int _kindMoves = 0;
  int _generation = 0;
  String _lumoLine = 'Lass uns Memory spielen! Du fängst an.';

  /// Beste Zugzahl je Stufe (Name der Stufe -> Züge), gespeichert.
  Map<String, int> _best = <String, int>{};

  final Map<int, MemoryMotif> _lumoMemory = <int, MemoryMotif>{};
  late final math.Random _rng;
  final _clock = LumoGameTurnClock();
  final LumoCharacterController _lumo = LumoCharacterController();
  bool _rewardGiven = false;

  int get _total => _difficulty.cards;

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  @override
  void initState() {
    super.initState();
    _rng = widget.seed == null ? math.Random() : math.Random(widget.seed);
    _difficulty = widget.difficulty ?? MemoryDifficulty.schwer;
    _setupBoard();
    if (widget.difficulty == null) _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _say('Lass uns Memory spielen! Du fängst an.');
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    _lumo.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || !mounted) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final saved = MemoryDifficulty.values
          .where((d) => d.name == json['difficulty'])
          .firstOrNull;
      final best = <String, int>{
        for (final e in ((json['best'] as Map?) ?? const {}).entries)
          e.key.toString(): (e.value as num).toInt(),
      };
      setState(() {
        _best = best;
        // Nur wechseln, solange noch nichts gespielt wurde.
        if (saved != null &&
            saved != _difficulty &&
            _kindMoves == 0 &&
            !_faceUp.any((up) => up)) {
          _difficulty = saved;
          _setupBoard();
        }
      });
    } catch (_) {}
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode({'difficulty': _difficulty.name, 'best': _best}));
    } catch (_) {}
  }

  void _say(String text) {
    if (mounted) setState(() => _lumoLine = text);
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _setupBoard() {
    _clock.cancel();
    _rewardGiven = false;
    _generation++;
    _cards = MemoryBoard.deal(_difficulty, _rng);
    _matched = List<bool>.filled(_total, false);
    _faceUp = List<bool>.filled(_total, false);
    _firstPickIdx = null;
    _busy = false;
    _turn = _Player.kind;
    _kindPairs = 0;
    _lumoPairs = 0;
    _kindMoves = 0;
    _lumoMemory.clear();
  }

  void _restart({MemoryDifficulty? difficulty}) {
    setState(() {
      if (difficulty != null) _difficulty = difficulty;
      _setupBoard();
      _lumoLine = 'Neue Runde! Du fängst an.';
    });
    _saveStats();
  }

  void _tapCard(int idx) {
    if (_clock.value || _busy || _turn != _Player.kind) return;
    if (_matched[idx] || _faceUp[idx]) return;
    HapticFeedback.lightImpact();
    setState(() {
      _faceUp[idx] = true;
      _lumoMemory[idx] = _cards[idx];
    });
    _continueTurn();
  }

  void _continueTurn() {
    if (_firstPickIdx == null) {
      _firstPickIdx = _findFaceUpUnmatched();
      return;
    }
    final secondIdx = _findFaceUpUnmatched(excluding: _firstPickIdx);
    if (secondIdx == null) return;
    _busy = true;
    if (_turn == _Player.kind) _kindMoves++;
    final firstIdx = _firstPickIdx!;
    final isMatch = _cards[firstIdx] == _cards[secondIdx];
    _clock.schedule(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        if (isMatch) {
          _matched[firstIdx] = true;
          _matched[secondIdx] = true;
          if (_turn == _Player.kind) {
            _kindPairs++;
          } else {
            _lumoPairs++;
          }
        } else {
          _faceUp[firstIdx] = false;
          _faceUp[secondIdx] = false;
        }
        _firstPickIdx = null;
        _busy = false;
      });
      if (_isGameOver()) {
        _onGameOver();
        return;
      }
      if (isMatch) {
        HapticFeedback.mediumImpact();
        if (_turn == _Player.kind) {
          _lumo.cheer();
          _say('Super, ein Paar! Du bist nochmal dran.');
        } else {
          _lumo.wiggle();
          _say('Ein Paar! Ich bin nochmal dran.');
          _clock.schedule(const Duration(milliseconds: 600), _lumoTurn);
        }
      } else {
        setState(() {
          _turn = _turn == _Player.kind ? _Player.lumo : _Player.kind;
        });
        if (_turn == _Player.lumo) {
          _say('Mein Zug! Ich denke nach...');
          _clock.schedule(const Duration(milliseconds: 900), _lumoTurn);
        } else {
          _say('Du bist dran!');
        }
      }
    });
  }

  int? _findFaceUpUnmatched({int? excluding}) {
    for (var i = 0; i < _total; i++) {
      if (i == excluding) continue;
      if (_faceUp[i] && !_matched[i]) return i;
    }
    return null;
  }

  // ── Lumo-KI ──────────────────────────────────────────────────────────
  // Lumo deckt eine Karte auf; kennt er die Partnerkarte, nimmt er sie –
  // aber mit 25 % Wahrscheinlichkeit „vergisst“ er sie, damit das Kind
  // faire Chancen hat.

  void _lumoTurn() {
    if (!mounted || _turn != _Player.lumo || _isGameOver()) return;
    final firstIdx = _pickFirstLumoCard();
    if (firstIdx == null) return;
    setState(() {
      _faceUp[firstIdx] = true;
      _lumoMemory[firstIdx] = _cards[firstIdx];
      _firstPickIdx = firstIdx;
    });
    _clock.schedule(const Duration(milliseconds: 900), () {
      if (!mounted || _turn != _Player.lumo) return;
      final secondIdx = _pickSecondLumoCard(firstIdx, _cards[firstIdx]);
      if (secondIdx == null) return;
      setState(() {
        _faceUp[secondIdx] = true;
        _lumoMemory[secondIdx] = _cards[secondIdx];
      });
      _continueTurn();
    });
  }

  int? _pickFirstLumoCard() {
    final unmatched = <int>[
      for (var i = 0; i < _total; i++)
        if (!_matched[i] && !_faceUp[i]) i
    ];
    if (unmatched.isEmpty) return null;
    if (_rng.nextDouble() > 0.25) {
      final known = <MemoryMotif, List<int>>{};
      for (final idx in unmatched) {
        final motif = _lumoMemory[idx];
        if (motif != null) known.putIfAbsent(motif, () => <int>[]).add(idx);
      }
      for (final entry in known.entries) {
        if (entry.value.length >= 2) return entry.value.first;
      }
    }
    final unknown = unmatched.where((i) => _lumoMemory[i] == null).toList();
    final pool = unknown.isNotEmpty ? unknown : unmatched;
    return pool[_rng.nextInt(pool.length)];
  }

  int? _pickSecondLumoCard(int firstIdx, MemoryMotif motif) {
    final unmatched = <int>[
      for (var i = 0; i < _total; i++)
        if (i != firstIdx && !_matched[i] && !_faceUp[i]) i
    ];
    if (unmatched.isEmpty) return null;
    if (_rng.nextDouble() > 0.25) {
      for (final idx in unmatched) {
        if (_lumoMemory[idx] == motif) return idx;
      }
    }
    final unknown = unmatched.where((i) => _lumoMemory[i] == null).toList();
    final pool = unknown.isNotEmpty ? unknown : unmatched;
    return pool[_rng.nextInt(pool.length)];
  }

  // ── Spielende ────────────────────────────────────────────────────────

  bool _isGameOver() => _matched.every((m) => m);

  void _onGameOver() {
    if (_rewardGiven) return;
    _rewardGiven = true;
    HapticFeedback.heavyImpact();
    final kindWon = _kindPairs > _lumoPairs;
    final draw = _kindPairs == _lumoPairs;
    final stars = _difficulty.starsFor(won: kindWon, draw: draw);
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 8);
    var record = false;
    if (kindWon) {
      final old = _best[_difficulty.name];
      if (old == null || _kindMoves < old) {
        _best[_difficulty.name] = _kindMoves;
        record = old != null;
      }
    }
    _saveStats();
    if (kindWon) {
      _lumo.cheer();
    } else if (!draw) {
      _lumo.comfort();
    }
    final msg = kindWon
        ? 'Wow, du hast gewonnen! $stars Sterne für dich!'
        : draw
            ? 'Unentschieden! Beide gleich gut. $stars Sterne!'
            : 'Diesmal habe ich gewonnen. Nochmal probieren? $stars Sterne für den Mut!';
    _say(msg);
    final title = kindWon
        ? 'Du hast gewonnen!'
        : (draw ? 'Unentschieden' : 'Lumo gewinnt');
    final reduce = _reduceMotion;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LumoGameResultBack(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: _ResultCard(
            title: title,
            pairsLine: 'Du: $_kindPairs Paare    Lumo: $_lumoPairs Paare',
            stars: stars,
            maxStars: 5,
            record: record,
            moves: kindWon ? _kindMoves : null,
            won: kindWon,
            reduceMotion: reduce,
            onAgain: () {
              Navigator.of(dialogContext).pop();
              _restart();
            },
            onBack: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  // ── Oberfläche ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LumoGamePauseScope(
      clock: _clock,
      onRestart: () => _restart(),
      child: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        body: LumoSceneBackground(
          scene: LumoScene.games,
          dimmed: true,
          child: SafeArea(
            child: LayoutBuilder(builder: (context, c) {
              final landscape = c.maxWidth >= c.maxHeight * 1.12;
              return landscape
                  ? _buildLandscape(c.maxWidth, c.maxHeight)
                  : _buildPortrait(c.maxWidth, c.maxHeight);
            }),
          ),
        ),
      ),
    );
  }

  Widget _topBar({required double logoHeight}) {
    return SizedBox(
      height: math.max(56.0, logoHeight + 4),
      child: Row(children: [
        _RoundIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Pausieren / Zurück',
          onTap: _clock.pause,
        ),
        Expanded(
          child: Center(
            child: Semantics(
              header: true,
              label: 'Memory mit Lumo',
              excludeSemantics: true,
              child: Image.asset(
                'assets/lumo_design/memory/logo_memory.png',
                height: logoHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        _RoundIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Neu starten',
          onTap: _clock.pause,
        ),
      ]),
    );
  }

  Widget _lumoFigure(double size) => LumoCharacter(
        key: const ValueKey('memory-lumo'),
        pose: LumoDesignFoxPose.spielweltWave,
        celebratePose: LumoDesignFoxPose.spielweltJump,
        size: size,
        shadow: false,
        reduceMotion: _reduceMotion,
        controller: _lumo,
        onTap: _lumo.wiggle,
      );

  Widget _scores() => Row(children: [
        Expanded(
          child: _ScorePill(
            label: 'Du',
            score: _kindPairs,
            color: LumoVisualTokens.gold,
            active: _turn == _Player.kind,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScorePill(
            label: 'Lumo',
            score: _lumoPairs,
            color: LumoVisualTokens.cyanBright,
            active: _turn == _Player.lumo,
          ),
        ),
      ]);

  String get _turnText => _turn == _Player.kind
      ? (_busy ? 'Lass die Karten kurz...' : 'Du bist dran! Tipp 2 Karten.')
      : (_busy ? 'Lumo denkt nach...' : 'Lumo ist dran!');

  Widget _chips() => _DifficultyChips(
        selected: _difficulty,
        best: _best,
        onSelect: (d) => d == _difficulty ? null : _restart(difficulty: d),
      );

  Widget _buildPortrait(double w, double h) {
    final roomy = h >= 760;
    // Lumo lehnt sich wie im Zielbild hinter dem Brett hervor: Ein Teil der
    // Figur verschwindet hinter der Steinplatte, die Pfoten liegen am Rand.
    final lumoSize = roomy
        ? math.min(w * .5, 210.0)
        : (h >= 620 ? math.min(w * .34, 128.0) : 0.0);
    final hidden = lumoSize * .26;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(children: [
        _topBar(logoHeight: roomy ? math.min(96, h * .11) : 46),
        _scores(),
        const SizedBox(height: 4),
        if (lumoSize > 0)
          SizedBox(
            height: lumoSize - hidden,
            child: LayoutBuilder(builder: (context, c) {
              final width = c.maxWidth;
              // Lumo steht links der Mitte, die Sprechblase rechts daneben –
              // nichts davon verdeckt sein Gesicht.
              final lumoLeft = roomy ? width * .30 - lumoSize / 2 + lumoSize * .18 : 0.0;
              final bubbleLeft = lumoLeft + lumoSize * .78;
              return Stack(clipBehavior: Clip.none, children: [
                if (roomy)
                  Positioned(
                    left: 0,
                    top: 6,
                    width: lumoSize * .40,
                    child: _FloatingCard(
                        motif: MemoryMotif.panda,
                        angle: -.16,
                        phase: 0,
                        reduceMotion: _reduceMotion),
                  ),
                Positioned(
                  left: lumoLeft,
                  top: 0,
                  width: lumoSize,
                  height: lumoSize,
                  child: _lumoFigure(lumoSize),
                ),
                Positioned(
                  left: bubbleLeft,
                  right: 0,
                  top: roomy ? lumoSize * .12 : 4,
                  child: _SpeechBubble(text: _lumoLine),
                ),
              ]);
            }),
          ),
        Expanded(child: _board()),
        const SizedBox(height: 6),
        _TurnText(text: _turnText),
        const SizedBox(height: 4),
        _chips(),
      ]),
    );
  }

  Widget _buildLandscape(double w, double h) {
    final panelW = math.min(w * .36, 360.0);
    final lumoSize = math.min(h * .52, panelW * .8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(children: [
        SizedBox(
          width: panelW,
          child: Column(children: [
            _topBar(logoHeight: math.min(84, h * .18)),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      height: lumoSize,
                      width: panelW,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Positioned(
                          left: 0,
                          top: lumoSize * .08,
                          width: panelW * .28,
                          child: _FloatingCard(
                              motif: MemoryMotif.giraffe,
                              angle: -.18,
                              phase: .2,
                              reduceMotion: _reduceMotion),
                        ),
                        Positioned(
                          right: 0,
                          top: lumoSize * .02,
                          width: panelW * .28,
                          child: _FloatingCard(
                              motif: MemoryMotif.pinguin,
                              angle: .16,
                              phase: .7,
                              reduceMotion: _reduceMotion),
                        ),
                        Center(child: _lumoFigure(lumoSize)),
                      ]),
                    ),
                    _SpeechBubble(text: _lumoLine),
                  ]),
                ),
              ),
            ),
            _scores(),
            const SizedBox(height: 6),
            _TurnText(text: _turnText),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(children: [
            Expanded(child: _board()),
            const SizedBox(height: 8),
            _chips(),
          ]),
        ),
      ]),
    );
  }

  Widget _board() {
    final reduce = _reduceMotion;
    // Steinplatte: kühles Schiefergrau mit Cyan-Schimmer am Rand, darunter
    // ein weicher Schatten für Tiefe (Zielbild: Karten liegen auf Stein).
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF0394866), Color(0xF2222C45), Color(0xF5141B30)],
          stops: [0, .55, 1],
        ),
        border: Border.all(color: const Color(0xAA37D2FD), width: 1.6),
        boxShadow: [
          BoxShadow(
              color: LumoVisualTokens.cyan.withOpacity(.25), blurRadius: 18),
          const BoxShadow(
              color: Color(0x88020A24), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(builder: (context, c) {
          const gap = 8.0;
          const aspect = .74;
          final grid =
              MemoryBoard.bestGrid(_total, c.maxWidth, c.maxHeight, gap: gap);
          final cardW = math.min(
            (c.maxWidth - gap * (grid.cols - 1)) / grid.cols,
            ((c.maxHeight - gap * (grid.rows - 1)) / grid.rows) * aspect,
          );
          final cardH = cardW / aspect;
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var r = 0; r < grid.rows; r++) ...[
                if (r > 0) const SizedBox(height: gap),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var col = 0; col < grid.cols; col++) ...[
                    if (col > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: cardW,
                      height: cardH,
                      child: _card(r * grid.cols + col, reduce),
                    ),
                  ],
                ]),
              ],
            ]),
          );
        }),
      ),
    );
  }

  Widget _card(int idx, bool reduce) {
    final showFront = _faceUp[idx] || _matched[idx];
    final motif = _cards[idx];
    return Semantics(
      label: 'Memory Karte ${idx + 1}'
          '${showFront ? ', ${motif.label}' : ', verdeckt'}',
      button: !_matched[idx],
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('memory-card-$idx'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapCard(idx),
        child: _MemoryCard(
          key: ValueKey('memory-card-$_generation-$idx'),
          index: idx,
          motif: motif,
          faceUp: showFront,
          matched: _matched[idx],
          reduceMotion: reduce,
          duration: _flip,
        ),
      ),
    );
  }
}

// ═══════════════════════════ Karte mit 3D-Flip ═══════════════════════════

class _MemoryCard extends StatefulWidget {
  const _MemoryCard({
    super.key,
    required this.index,
    required this.motif,
    required this.faceUp,
    required this.matched,
    required this.reduceMotion,
    required this.duration,
  });

  final int index;
  final MemoryMotif motif;
  final bool faceUp;
  final bool matched;
  final bool reduceMotion;
  final Duration duration;

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: w.faceUp ? 1 : 0),
        duration: w.reduceMotion ? const Duration(milliseconds: 1) : w.duration,
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) {
          final front = t > .5;
          final double lift = 1.0 +
              (w.reduceMotion ? 0.0 : .04 * math.sin(t * math.pi)) +
              (_pressed && !w.faceUp ? .03 : 0.0);
          final face = front
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _CardFront(motif: w.motif, matched: w.matched),
                )
              : _CardBack(index: w.index);
          return Transform.scale(
            scale: lift,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0014)
                ..rotateY(t * math.pi),
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  face,
                  if (w.matched && !w.reduceMotion)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: const _MatchSparkle(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey('memory-back-$index'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3C8CFF), Color(0xFF1B52C8)],
        ),
        border: Border.all(color: const Color(0xFFBDEBFF), width: 2.2),
        boxShadow: [
          BoxShadow(
              color: LumoVisualTokens.cyan.withOpacity(.55), blurRadius: 12),
          const BoxShadow(
              color: Color(0x66020A24), blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(fit: StackFit.expand, children: [
        // Innerer Rahmen wie auf der Kartenrückseite des Zielbilds.
        Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x66FFFFFF), width: 1),
            ),
          ),
        ),
        const Center(
          child: FractionallySizedBox(
            widthFactor: .62,
            child: FittedBox(
              child: Icon(Icons.star_rounded,
                  color: Color(0xFF9FE4FF),
                  shadows: [Shadow(color: Color(0xAAFFFFFF), blurRadius: 12)]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.motif, required this.matched});
  final MemoryMotif motif;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final glow = matched ? const Color(0xFFFFD86B) : const Color(0xFF7FE3FF);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: matched ? const Color(0xFFFFE9A6) : const Color(0xFFD9F6FF),
            width: 3),
        boxShadow: [
          BoxShadow(
              color: glow.withOpacity(matched ? .85 : .55),
              blurRadius: matched ? 18 : 12,
              spreadRadius: matched ? 2 : 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: motif.sticker
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [motif.tintLight, motif.tintDark],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(motif.path,
                      fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                ),
              )
            : Image.asset(motif.path,
                fit: BoxFit.cover, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

/// Goldene Funken, die einmal aus einem gefundenen Paar herausfliegen.
class _MatchSparkle extends StatelessWidget {
  const _MatchSparkle();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(painter: _SparklePainter(t)),
      );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (.55 + .5 * t);
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * 2 * math.pi + .3;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      final fade = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = const Color(0xFFFFE08A).withOpacity(fade);
      canvas.drawCircle(p, 2.4 + 2 * fade, paint);
      canvas.drawRect(
          Rect.fromCenter(center: p, width: 9 * fade + 2, height: 1.4), paint);
      canvas.drawRect(
          Rect.fromCenter(center: p, width: 1.4, height: 9 * fade + 2), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

// ═══════════════════════════ Kleine Bausteine ═══════════════════════════

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xCC0B2A5C),
          side: const BorderSide(color: Color(0xAA37D2FD)),
        ),
      );
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.score,
    required this.color,
    required this.active,
  });
  final String label;
  final int score;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xF20E3A7A) : const Color(0xB30B2A5C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : const Color(0x6637D2FD),
              width: active ? 2.4 : 1.2),
          boxShadow: active
              ? [BoxShadow(color: color.withOpacity(.55), blurRadius: 14)]
              : null,
        ),
        child: Row(children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
          const Spacer(),
          Icon(Icons.favorite_rounded, color: color, size: 18),
          const SizedBox(width: 6),
          Text('$score',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color)),
        ]),
      );
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xD90B2A5C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x9937D2FD)),
        ),
        child: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textScaler:
              MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.25),
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white),
        ),
      );
}

class _TurnText extends StatelessWidget {
  const _TurnText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textScaler:
            MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
        style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Color(0xCC03193F), blurRadius: 6)]),
      );
}

class _DifficultyChips extends StatelessWidget {
  const _DifficultyChips(
      {required this.selected, required this.best, required this.onSelect});
  final MemoryDifficulty selected;
  final Map<String, int> best;
  final ValueChanged<MemoryDifficulty> onSelect;

  @override
  Widget build(BuildContext context) {
    final record = best[selected.name];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        for (final d in MemoryDifficulty.values) ...[
          if (d != MemoryDifficulty.values.first) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: d == selected,
              label: 'Schwierigkeit ${d.label}, ${d.cards} Karten',
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('memory-diff-${d.name}'),
                onTap: () => onSelect(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: d == selected
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF63E4FF), Color(0xFF1E7FE0)])
                        : null,
                    color: d == selected ? null : const Color(0xB30B2A5C),
                    border: Border.all(
                        color: d == selected
                            ? const Color(0xFFBDF4FF)
                            : const Color(0x6637D2FD),
                        width: 1.6),
                    boxShadow: d == selected
                        ? [
                            BoxShadow(
                                color: LumoVisualTokens.cyan.withOpacity(.55),
                                blurRadius: 12)
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(d.label,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ]),
      if (record != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Dein Rekord: $record Züge',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFE08A))),
        ),
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.pairsLine,
    required this.stars,
    required this.maxStars,
    required this.record,
    required this.moves,
    required this.won,
    required this.reduceMotion,
    required this.onAgain,
    required this.onBack,
  });

  final String title;
  final String pairsLine;
  final int stars;
  final int maxStars;
  final bool record;
  final int? moves;
  final bool won;
  final bool reduceMotion;
  final VoidCallback onAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF2123F86), Color(0xF2071A3E)],
          ),
          border: Border.all(color: const Color(0xCC53DDFD), width: 2),
          boxShadow: [
            BoxShadow(
                color: LumoVisualTokens.cyan.withOpacity(.4), blurRadius: 24),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            LumoCharacter(
              pose: won
                  ? LumoDesignFoxPose.spielweltJump
                  : LumoDesignFoxPose.spielweltWave,
              size: 120,
              shadow: false,
              reduceMotion: reduceMotion,
              celebratePose: null,
            ),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(pairsLine,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6F4FF))),
            if (moves != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    record
                        ? 'Neuer Rekord: $moves Züge!'
                        : 'Geschafft in $moves Zügen',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFE08A))),
              ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < maxStars; i++)
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.star_rounded,
                      size: 38,
                      color: i < stars
                          ? LumoVisualTokens.gold
                          : const Color(0x55FFFFFF)),
                ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onAgain,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E9BE8),
                  shape: const StadiumBorder(
                      side: BorderSide(color: Color(0xFFBDF4FF), width: 2)),
                ),
                child: const Text('Nochmal!',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: onBack,
                child: const Text('Zur Spielewelt',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}


/// Schwebende, leicht gedrehte Tierkarte als Deko neben Lumo (Zielbild 02).
class _FloatingCard extends StatefulWidget {
  const _FloatingCard({
    required this.motif,
    required this.angle,
    required this.phase,
    required this.reduceMotion,
  });
  final MemoryMotif motif;
  final double angle;
  final double phase;
  final bool reduceMotion;

  @override
  State<_FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<_FloatingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: .74,
        child: _CardFront(motif: widget.motif, matched: false),
      ),
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        child: card,
        builder: (context, child) {
          final t = math.sin((_c.value + widget.phase) * 2 * math.pi);
          return Transform.translate(
            offset: Offset(0, t * 4),
            child: Transform.rotate(angle: widget.angle + t * .03, child: child),
          );
        },
      ),
    );
  }
}
