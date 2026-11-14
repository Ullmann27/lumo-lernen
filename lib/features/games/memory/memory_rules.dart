import 'dart:math' as math;

/// The Flutter adapter delegates dealing, sizes and rewards to MemoryBoard.
abstract interface class MemoryCatalog {
  List<String> deal(String difficulty, math.Random random, String pack);
  int cardCount(String difficulty);
  bool containsMotif(String motif);
  int starsFor(String difficulty, {required bool won, required bool draw});
}

const memoryDifficulties = ['leicht', 'mittel', 'schwer', 'knifflig', 'profi'];
const memoryPacks = ['alle', 'tiere', 'weltall', 'garten'];

/// Record the original Random API calls, not card choices. Replaying these
/// calls resumes the same dealer/opponent stream after process recreation.
class MemoryRandom implements math.Random {
  MemoryRandom(this.seed) : _random = math.Random(seed);
  final int seed;
  final math.Random _random;
  final List<int> calls = [];

  factory MemoryRandom.restore(Object? raw) {
    if (raw is! Map || raw['seed'] is! int || raw['calls'] is! List) {
      throw const FormatException('Ungültiger Memory-Zufallszustand');
    }
    final random = MemoryRandom(raw['seed'] as int);
    final calls = raw['calls'] as List;
    if (calls.length > 200000) {
      throw const FormatException('Memory-Zufallsprotokoll zu groß');
    }
    for (final call in calls) {
      if (call is! int || call < -2 || call == 0 || call > 0x100000000) {
        throw const FormatException('Ungültiger Memory-Zufallsaufruf');
      }
      if (call == -1) {
        random.nextDouble();
      } else if (call == -2) {
        random.nextBool();
      } else {
        random.nextInt(call);
      }
    }
    return random;
  }

  @override
  int nextInt(int max) {
    final value = _random.nextInt(max);
    calls.add(max);
    return value;
  }

  @override
  double nextDouble() {
    final value = _random.nextDouble();
    calls.add(-1);
    return value;
  }

  @override
  bool nextBool() {
    final value = _random.nextBool();
    calls.add(-2);
    return value;
  }

  Map<String, Object?> toJson() => {'seed': seed, 'calls': [...calls]};
}

/// The existing Memory turn rules extracted from LumoMemoryScreen.
/// Native views receive publicState only and cannot read the private deck.
class MemoryRules {
  MemoryRules._(this.catalog, this.random, this.difficulty, this.pack);
  final MemoryCatalog catalog;
  final MemoryRandom random;
  final String difficulty;
  final String pack;
  late final List<String> cards;
  late final List<bool> matched;
  late final List<bool> faceUp;
  final Map<int, String> known = {};
  String turn = 'kind';
  String phase = 'select';
  String line = 'Lass uns Memory spielen! Du fängst an.';
  int? first;
  int remainingMs = 0;
  int kindPairs = 0;
  int lumoPairs = 0;
  int kindMoves = 0;
  int kindStreak = 0;

  factory MemoryRules.start(
    MemoryCatalog catalog,
    MemoryRandom random,
    String difficulty,
    String pack,
  ) {
    if (!memoryDifficulties.contains(difficulty) || !memoryPacks.contains(pack)) {
      throw const FormatException('Unbekannte Memory-Einstellung');
    }
    final rules = MemoryRules._(catalog, random, difficulty, pack);
    rules.cards = catalog.deal(difficulty, random, pack);
    rules.matched = List<bool>.filled(rules.cards.length, false);
    rules.faceUp = List<bool>.filled(rules.cards.length, false);
    rules._validate();
    return rules;
  }

  factory MemoryRules.restore(MemoryCatalog catalog, Map<String, dynamic> value) {
    String string(String key) {
      final result = value[key];
      if (result is! String) throw FormatException('Memory-Feld fehlt: ' + key);
      return result;
    }
    int integer(String key, int maximum) {
      final result = value[key];
      if (result is! int || result < 0 || result > maximum) {
        throw FormatException('Ungültiges Memory-Feld: ' + key);
      }
      return result;
    }
    List<T> list<T>(String key) {
      final raw = value[key];
      if (raw is! List || raw.any((item) => item is! T)) {
        throw FormatException('Ungültige Memory-Liste: ' + key);
      }
      return raw.cast<T>().toList();
    }

    final rules = MemoryRules._(
      catalog, MemoryRandom.restore(value['random']),
      string('difficulty'), string('pack'),
    );
    rules.cards = list<String>('cards');
    rules.matched = list<bool>('matched');
    rules.faceUp = list<bool>('faceUp');
    rules.turn = string('turn');
    rules.phase = string('phase');
    rules.line = string('line');
    rules.remainingMs = integer('remainingMs', 900);
    rules.kindPairs = integer('kindPairs', 12);
    rules.lumoPairs = integer('lumoPairs', 12);
    rules.kindMoves = integer('kindMoves', 1000000);
    rules.kindStreak = integer('kindStreak', 12);
    final first = value['first'];
    if (first != null && (first is! int || first < 0 || first >= rules.cards.length)) {
      throw const FormatException('Ungültige erste Memory-Karte');
    }
    rules.first = first as int?;
    final known = value['known'];
    if (known is! Map) throw const FormatException('Ungültiges Lumo-Gedächtnis');
    for (final entry in known.entries) {
      final index = int.tryParse(entry.key.toString());
      if (index == null || entry.value is! String ||
          index.toString() != entry.key.toString()) {
        throw const FormatException('Ungültiger Gedächtniseintrag');
      }
      rules.known[index] = entry.value as String;
    }
    rules._validate();
    return rules;
  }

  bool get complete => phase == 'complete';
  bool get busy => phase != 'select' && !complete;
  bool get canFlip => !complete && turn == 'kind' && phase == 'select';
  int get stars => catalog.starsFor(
    difficulty, won: kindPairs > lumoPairs, draw: kindPairs == lumoPairs,
  );

  bool flip(int index) {
    if (!canFlip || index < 0 || index >= cards.length ||
        matched[index] || faceUp[index]) return false;
    _reveal(index);
    if (first == null) {
      first = index;
    } else {
      kindMoves++;
      phase = 'resolve';
      remainingMs = 850;
    }
    return true;
  }

  void _reveal(int index) {
    faceUp[index] = true;
    known[index] = cards[index];
  }

  /// Time is advanced only by the current Dart owner while its host is active.
  /// A full pending interval executes exactly the historical turn callback.
  bool elapse(int milliseconds) {
    if (milliseconds < 0 || milliseconds > 60000) {
      throw ArgumentError.value(milliseconds, 'milliseconds');
    }
    if (remainingMs == 0 || complete || milliseconds == 0) return false;
    var budget = milliseconds;
    var changed = false;
    while (remainingMs > 0 && budget > 0 && !complete) {
      if (budget < remainingMs) {
        remainingMs -= budget;
        changed = true;
        break;
      }
      budget -= remainingMs;
      remainingMs = 0;
      changed = true;
      switch (phase) {
        case 'resolve':
          _resolve();
        case 'botFirst':
          final index = _pickFirstLumoCard();
          if (index == null) throw StateError('Lumo hat keine erste Karte');
          _reveal(index);
          first = index;
          phase = 'botSecond';
          remainingMs = 900;
        case 'botSecond':
          final index = _pickSecondLumoCard(first!, cards[first!]);
          if (index == null) throw StateError('Lumo hat keine zweite Karte');
          _reveal(index);
          phase = 'resolve';
          remainingMs = 850;
        default:
          throw StateError('Ungültige Memory-Zeitphase');
      }
    }
    return changed;
  }

  void _resolve() {
    final a = first!;
    final b = List<int>.generate(cards.length, (i) => i)
        .firstWhere((i) => i != a && faceUp[i] && !matched[i]);
    final same = cards[a] == cards[b];
    if (same) {
      matched[a] = matched[b] = true;
      if (turn == 'kind') {
        kindPairs++;
        kindStreak++;
      } else {
        lumoPairs++;
      }
    } else {
      faceUp[a] = faceUp[b] = false;
      if (turn == 'kind') kindStreak = 0;
    }
    first = null;
    phase = 'select';
    if (matched.every((value) => value)) {
      phase = 'complete';
      line = kindPairs > lumoPairs
          ? 'Wow, du hast gewonnen! $stars Sterne für dich!'
          : kindPairs == lumoPairs
              ? 'Unentschieden! Beide gleich gut. $stars Sterne!'
              : 'Diesmal habe ich gewonnen. Nochmal probieren? $stars Sterne für den Mut!';
      return;
    }
    if (same) {
      if (turn == 'kind') {
        line = kindStreak >= 2
            ? 'Combo x$kindStreak! Super gemacht!'
            : 'Super, ein Paar! Du bist nochmal dran.';
      } else {
        line = 'Ein Paar! Ich bin nochmal dran.';
        phase = 'botFirst';
        remainingMs = 600;
      }
    } else {
      turn = turn == 'kind' ? 'lumo' : 'kind';
      line = turn == 'lumo' ? 'Mein Zug! Ich denke nach...' : 'Du bist dran!';
      if (turn == 'lumo') {
        phase = 'botFirst';
        remainingMs = 900;
      }
    }
  }

  // Same iteration order, Random calls and 25% forgetting as the original UI.
  int? _pickFirstLumoCard() {
    final unmatched = <int>[
      for (var i = 0; i < cards.length; i++)
        if (!matched[i] && !faceUp[i]) i
    ];
    if (unmatched.isEmpty) return null;
    if (random.nextDouble() > 0.25) {
      final remembered = <String, List<int>>{};
      for (final idx in unmatched) {
        final motif = known[idx];
        if (motif != null) remembered.putIfAbsent(motif, () => <int>[]).add(idx);
      }
      for (final entry in remembered.entries) {
        if (entry.value.length >= 2) return entry.value.first;
      }
    }
    final unknown = unmatched.where((i) => known[i] == null).toList();
    final pool = unknown.isNotEmpty ? unknown : unmatched;
    return pool[random.nextInt(pool.length)];
  }

  int? _pickSecondLumoCard(int firstIdx, String motif) {
    final unmatched = <int>[
      for (var i = 0; i < cards.length; i++)
        if (i != firstIdx && !matched[i] && !faceUp[i]) i
    ];
    if (unmatched.isEmpty) return null;
    if (random.nextDouble() > 0.25) {
      for (final idx in unmatched) {
        if (known[idx] == motif) return idx;
      }
    }
    final unknown = unmatched.where((i) => known[i] == null).toList();
    final pool = unknown.isNotEmpty ? unknown : unmatched;
    return pool[random.nextInt(pool.length)];
  }

  void _validate() {
    if (!memoryDifficulties.contains(difficulty) || !memoryPacks.contains(pack) ||
        cards.length != catalog.cardCount(difficulty) ||
        matched.length != cards.length || faceUp.length != cards.length ||
        !const ['kind', 'lumo'].contains(turn) ||
        !const ['select', 'resolve', 'botFirst', 'botSecond', 'complete'].contains(phase) ||
        line.length > 500) throw const FormatException('Ungültige Memory-Runde');
    final counts = <String, int>{};
    for (final card in cards) {
      if (!catalog.containsMotif(card)) throw const FormatException('Unbekanntes Motiv');
      counts[card] = (counts[card] ?? 0) + 1;
    }
    if (counts.length * 2 != cards.length || counts.values.any((count) => count != 2)) {
      throw const FormatException('Memory benötigt eindeutige Paare');
    }
    var matchedCount = 0;
    final open = <int>[];
    for (var i = 0; i < cards.length; i++) {
      if (matched[i]) {
        matchedCount++;
        if (!faceUp[i]) throw const FormatException('Gefundenes Paar verdeckt');
        final partner = cards.indexOf(cards[i]) == i ? cards.lastIndexOf(cards[i]) : cards.indexOf(cards[i]);
        if (!matched[partner]) throw const FormatException('Unvollständiges Memory-Paar');
      } else if (faceUp[i]) {
        open.add(i);
      }
    }
    if (matchedCount != (kindPairs + lumoPairs) * 2 || kindStreak > kindPairs ||
        kindPairs > kindMoves || kindPairs < 0 || lumoPairs < 0) {
      throw const FormatException('Memory-Punktestand widersprüchlich');
    }
    for (final entry in known.entries) {
      if (entry.key < 0 || entry.key >= cards.length || cards[entry.key] != entry.value) {
        throw const FormatException('Gedächtnis gehört nicht zum Brett');
      }
    }
    if (open.any((i) => known[i] != cards[i])) {
      throw const FormatException('Sichtbare Karte fehlt im Gedächtnis');
    }
    if (phase == 'select' && (turn != 'kind' || remainingMs != 0 ||
        open.length > 1 || (open.isEmpty ? first != null : first != open.single))) {
      throw const FormatException('Ungültige Auswahlphase');
    }
    if (phase == 'resolve' && (open.length != 2 || !open.contains(first) ||
        remainingMs < 1 || remainingMs > 850)) {
      throw const FormatException('Ungültige Paarauflösung');
    }
    if (phase == 'botFirst' && (turn != 'lumo' || open.isNotEmpty ||
        first != null || remainingMs < 1 || remainingMs > 900)) {
      throw const FormatException('Ungültiger erster Lumo-Zug');
    }
    if (phase == 'botSecond' && (turn != 'lumo' || open.length != 1 ||
        first != open.single || remainingMs < 1 || remainingMs > 900)) {
      throw const FormatException('Ungültiger zweiter Lumo-Zug');
    }
    if (phase == 'complete' && (matchedCount != cards.length ||
        open.isNotEmpty || first != null || remainingMs != 0)) {
      throw const FormatException('Unvollständiges Memory-Ergebnis');
    }
    if (phase != 'complete' && matchedCount == cards.length) {
      throw const FormatException('Memory-Abschluss fehlt');
    }
  }

  Map<String, Object?> toJson() => {
    'difficulty': difficulty, 'pack': pack, 'cards': [...cards],
    'matched': [...matched], 'faceUp': [...faceUp], 'turn': turn, 'phase': phase,
    'first': first, 'remainingMs': remainingMs, 'kindPairs': kindPairs,
    'lumoPairs': lumoPairs, 'kindMoves': kindMoves, 'kindStreak': kindStreak,
    'known': {for (final entry in known.entries) entry.key.toString(): entry.value},
    'line': line, 'random': random.toJson(),
  };

  Map<String, Object?> get publicState => {
    'difficulty': difficulty, 'pack': pack, 'count': cards.length,
    'cards': [
      for (var i = 0; i < cards.length; i++)
        {'index': i, 'faceUp': faceUp[i], 'matched': matched[i],
         'motif': faceUp[i] ? cards[i] : null}
    ],
    'turn': turn, 'phase': phase, 'kindPairs': kindPairs, 'lumoPairs': lumoPairs,
    'kindMoves': kindMoves, 'kindStreak': kindStreak, 'line': line,
    'remainingMs': remainingMs, 'complete': complete, 'stars': complete ? stars : 0,
  };
}
