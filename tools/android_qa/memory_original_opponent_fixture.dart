import 'dart:math' as math;
import 'memory_original_board_fixture.dart';

/// Exact two opponent methods from published Host 078, blob
/// 033e3a70bd7fff21506bea014cc16a8ee1558c06. Only this test wrapper is new.
class OriginalMemoryOpponent {
  OriginalMemoryOpponent(this._cards, this._rng);
  final List<MemoryMotif> _cards;
  final math.Random _rng;
  late List<bool> _matched;
  late List<bool> _faceUp;
  final Map<int, MemoryMotif> _lumoMemory = {};
  int get _total => _cards.length;
  void observe(List<bool> matched, List<bool> faceUp, Map<int, String> known) {
    _matched = [...matched];
    _faceUp = [...faceUp];
    _lumoMemory
      ..clear()
      ..addAll(known.map((index, name) => MapEntry(index, MemoryMotif.values.byName(name))));
  }
  int? first() => _pickFirstLumoCard();
  int? second(int first) => _pickSecondLumoCard(first, _cards[first]);

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

}
