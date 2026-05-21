// ════════════════════════════════════════════════════════════════════════
// LUMO MEMORY — Karten-Merkspiel mit Lumo als aktivem Gegner
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: "Lumo selbst spielt gegen das Kind, jeder hat einen Zug.
// Wie Trueffelo. KI deckt aktiv auf. Bei Memory genau jedes Paar zweimal,
// nicht mehr und nicht weniger."
//
// Spielregeln:
//   - 6x4 Raster = 24 Karten = 12 verschiedene Paare
//   - Jedes Paar genau zweimal (mathematisch garantiert via Set + shuffle)
//   - Spieler decken abwechselnd 2 Karten auf
//   - Paar gefunden -> Karte bleibt offen, gleicher Spieler nochmal
//   - Kein Paar -> Karten zu, anderer Spieler ist dran
//   - Lumo merkt sich gesehene Karten (Memory!) und nutzt das fuer
//     spaetere Zuege - mehr Lernerfolg als reine Zufallszuege
//   - Sieger: wer am Ende mehr Paare hat
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/lumo_voice.dart';

/// Symbole auf den Karten. Bewusst kindgerechte Emojis statt Asset-Bilder,
/// damit das Spiel ohne externe Assets funktioniert und visuell stabil
/// bleibt - jedes Symbol ist klar unterscheidbar.
const List<String> _kCardSymbols = <String>[
  '🦊', '⭐', '🎁', '🍎', '🌸', '🌈',
  '🚀', '🎨', '🎈', '🐝', '🌙', '🍪',
];

class LumoMemoryScreen extends StatefulWidget {
  const LumoMemoryScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoMemoryScreen> createState() => _LumoMemoryScreenState();
}

enum _Player { kind, lumo }

class _LumoMemoryScreenState extends State<LumoMemoryScreen>
    with TickerProviderStateMixin {
  static const int _rows = 4;
  static const int _cols = 6;
  static const int _totalCards = _rows * _cols; // 24
  static const int _totalPairs = _totalCards ~/ 2; // 12

  late List<String> _cards;     // Symbol pro Position
  late List<bool> _matched;     // Karte schon als Paar gefunden?
  late List<bool> _faceUp;      // Karte aktuell offen?
  int? _firstPickIdx;           // Erste aufgedeckte Karte des aktuellen Zuges
  bool _busy = false;           // Animation/Verzoegerung laeuft
  _Player _turn = _Player.kind;
  int _kindPairs = 0;
  int _lumoPairs = 0;

  // Lumo's Gedaechtnis: was hat Lumo schon gesehen?
  // Map<index, symbol>. Wenn Lumo eine Karte aufdeckt oder beobachtet,
  // wie das Kind aufdeckt, merkt er sich Position + Symbol.
  // Realistisch fuer Klasse 1: ~70% Erinnerungsrate, sonst zufaellig.
  final Map<int, String> _lumoMemory = <int, String>{};
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _setupBoard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _say('Lass uns Memory spielen! Du faengst an.');
    });
  }

  void _say(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  /// Baut das 6x4-Board so, dass JEDES Symbol genau zweimal vorkommt.
  /// Vorher koennten Duplikate >2 entstehen wenn man unsauber sampled.
  /// Hier: 12 Symbole aus der Liste auswaehlen, jedes verdoppeln,
  /// shuffeln - mathematisch garantiert 12 Paare a 2 Karten.
  void _setupBoard() {
    // Defensive: falls die Symbol-Liste irgendwann erweitert wird,
    // erste _totalPairs eindeutige nehmen.
    final symbols = _kCardSymbols.toSet().take(_totalPairs).toList();
    assert(symbols.length == _totalPairs,
        'Nicht genug einzigartige Symbole fuer $_totalPairs Paare');
    final deck = <String>[...symbols, ...symbols]; // jedes Symbol genau 2x
    deck.shuffle(_rng);
    _cards = deck;
    _matched = List<bool>.filled(_totalCards, false);
    _faceUp = List<bool>.filled(_totalCards, false);
    _firstPickIdx = null;
    _busy = false;
    _turn = _Player.kind;
    _kindPairs = 0;
    _lumoPairs = 0;
    _lumoMemory.clear();
  }

  void _tapCard(int idx) {
    if (_busy || _turn != _Player.kind) return;
    if (_matched[idx] || _faceUp[idx]) return;
    HapticFeedback.lightImpact();
    setState(() {
      _faceUp[idx] = true;
      _lumoMemory[idx] = _cards[idx]; // Lumo beobachtet mit
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
    final firstIdx = _firstPickIdx!;
    final isMatch = _cards[firstIdx] == _cards[secondIdx];
    Timer(const Duration(milliseconds: 850), () {
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
        _say(_turn == _Player.kind
            ? 'Super, ein Paar! Du bist nochmal dran.'
            : 'Ein Paar! Ich bin nochmal dran.');
        if (_turn == _Player.lumo) {
          Timer(const Duration(milliseconds: 600), _lumoTurn);
        }
      } else {
        _turn = _turn == _Player.kind ? _Player.lumo : _Player.kind;
        if (_turn == _Player.lumo) {
          _say('Mein Zug! Ich denke nach...');
          Timer(const Duration(milliseconds: 900), _lumoTurn);
        } else {
          _say('Du bist dran!');
        }
      }
    });
  }

  int? _findFaceUpUnmatched({int? excluding}) {
    for (var i = 0; i < _totalCards; i++) {
      if (i == excluding) continue;
      if (_faceUp[i] && !_matched[i]) return i;
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────
  // LUMO-KI
  // ──────────────────────────────────────────────────────────────────

  /// Lumo's Zug. Strategie:
  /// 1. Wenn Lumo ein Paar im Gedaechtnis hat -> aufdecken!
  /// 2. Sonst: eine unbekannte Karte aufdecken, schauen.
  /// 3. Mit der zweiten Karte: wenn passendes Symbol bekannt -> aufdecken,
  ///    sonst eine andere unbekannte.
  ///
  /// Klasse 1 freundlich: Lumo "vergisst" mit 25% Wahrscheinlichkeit
  /// eine bekannte Karte, damit das Kind realistische Chancen hat.
  void _lumoTurn() async {
    if (!mounted) return;
    // Erste Karte
    final firstIdx = _pickFirstLumoCard();
    if (firstIdx == null) return;
    setState(() {
      _faceUp[firstIdx] = true;
      _lumoMemory[firstIdx] = _cards[firstIdx];
      _firstPickIdx = firstIdx;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Zweite Karte: passend zur ersten?
    final firstSymbol = _cards[firstIdx];
    final secondIdx = _pickSecondLumoCard(firstIdx, firstSymbol);
    if (secondIdx == null) return;
    setState(() {
      _faceUp[secondIdx] = true;
      _lumoMemory[secondIdx] = _cards[secondIdx];
    });
    _continueTurn();
  }

  int? _pickFirstLumoCard() {
    // Bekannte Paare im Gedaechtnis suchen
    final unmatched = <int>[
      for (var i = 0; i < _totalCards; i++)
        if (!_matched[i] && !_faceUp[i]) i
    ];
    if (unmatched.isEmpty) return null;

    // Lumo "vergisst" 25% der Zeit (Klasse-1-freundlich, sonst gewinnt
    // Lumo zu oft)
    final useMemory = _rng.nextDouble() > 0.25;
    if (useMemory) {
      // Suche zwei bekannte Karten mit gleichem Symbol
      final knownBySymbol = <String, List<int>>{};
      for (final idx in unmatched) {
        final sym = _lumoMemory[idx];
        if (sym != null) {
          knownBySymbol.putIfAbsent(sym, () => <int>[]).add(idx);
        }
      }
      for (final entry in knownBySymbol.entries) {
        if (entry.value.length >= 2) {
          // Lumo erinnert sich an ein Paar - eine der beiden aufdecken.
          return entry.value.first;
        }
      }
    }
    // Sonst: zufaellige unbekannte Karte
    final unknown = unmatched.where((i) => _lumoMemory[i] == null).toList();
    final pool = unknown.isNotEmpty ? unknown : unmatched;
    return pool[_rng.nextInt(pool.length)];
  }

  int? _pickSecondLumoCard(int firstIdx, String firstSymbol) {
    final unmatched = <int>[
      for (var i = 0; i < _totalCards; i++)
        if (i != firstIdx && !_matched[i] && !_faceUp[i]) i
    ];
    if (unmatched.isEmpty) return null;
    // Bekannte Karte mit passendem Symbol?
    final useMemory = _rng.nextDouble() > 0.25;
    if (useMemory) {
      for (final idx in unmatched) {
        if (_lumoMemory[idx] == firstSymbol) return idx;
      }
    }
    // Sonst: zufaellige unbekannte Karte
    final unknown = unmatched.where((i) => _lumoMemory[i] == null).toList();
    final pool = unknown.isNotEmpty ? unknown : unmatched;
    return pool[_rng.nextInt(pool.length)];
  }

  // ──────────────────────────────────────────────────────────────────
  // SPIEL-ENDE
  // ──────────────────────────────────────────────────────────────────

  bool _isGameOver() {
    return _matched.every((m) => m);
  }

  void _onGameOver() {
    HapticFeedback.heavyImpact();
    final kindWon = _kindPairs > _lumoPairs;
    final draw = _kindPairs == _lumoPairs;
    final stars = kindWon ? 5 : (draw ? 3 : 2);
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 8);
    final msg = kindWon
        ? 'Wow, du hast gewonnen! $stars Sterne fuer dich!'
        : draw
            ? 'Unentschieden! Beide gleich gut. $stars Sterne!'
            : 'Diesmal habe ich gewonnen. Nochmal probieren? $stars Sterne fuer den Mut!';
    _say(msg);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          kindWon ? '🎉 Du hast gewonnen!' : (draw ? '🤝 Unentschieden' : '🦊 Lumo gewinnt'),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 22),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Du: $_kindPairs Paare    Lumo: $_lumoPairs Paare',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.star_rounded,
                    size: 38,
                    color: i < stars
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFD1D5DB)),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(_setupBoard);
            },
            child: const Text('Nochmal!',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Zur Spielewelt',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildScoreBar(),
            Expanded(child: _buildGrid()),
            _buildTurnIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFEA580C)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Expanded(
          child: Center(
            child: Text('Memory mit Lumo 🦊',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Neu starten',
          onPressed: () => setState(_setupBoard),
        ),
      ]),
    );
  }

  Widget _buildScoreBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _scorePill('Du', _kindPairs, const Color(0xFFFB923C),
              isActive: _turn == _Player.kind)),
          const SizedBox(width: 12),
          Expanded(child: _scorePill('Lumo 🦊', _lumoPairs, const Color(0xFF8B5CF6),
              isActive: _turn == _Player.lumo)),
        ],
      ),
    );
  }

  Widget _scorePill(String label, int score, Color color,
      {required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2.4),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.32), blurRadius: 14, offset: const Offset(0, 4))]
            : null,
      ),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : color)),
        const Spacer(),
        Text('$score',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : color)),
      ]),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _cols,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _totalCards,
        itemBuilder: (_, i) => _buildCard(i),
      ),
    );
  }

  Widget _buildCard(int idx) {
    final showFront = _faceUp[idx] || _matched[idx];
    final isMatched = _matched[idx];
    return GestureDetector(
      onTap: () => _tapCard(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: showFront
                ? (isMatched
                    ? const [Color(0xFFDCFCE7), Color(0xFFA7F3D0)]
                    : const [Color(0xFFFEF3C7), Color(0xFFFDE68A)])
                : const [Color(0xFFC084FC), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: showFront
                ? (isMatched ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))
                : const Color(0xFF6D28D9),
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: showFront
            ? Text(_cards[idx], style: const TextStyle(fontSize: 32))
            : const Text('?',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    final isKind = _turn == _Player.kind;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      child: Text(
        isKind
            ? (_busy ? 'Lass die Karten kurz...' : 'Du bist dran! Tipp 2 Karten.')
            : (_busy ? 'Lumo denkt nach 🦊...' : 'Lumo ist dran!'),
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: LumoColors.ink700),
      ),
    );
  }
}
