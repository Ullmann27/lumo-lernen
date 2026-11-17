import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/legacy_learning_data.dart';
import 'lumo_cards_bot_policy.dart';
import 'lumo_cards_session.dart';

/// Three completed, independently rewarded rounds. Classic Cards keeps its slot.
class LumoCardsCup {
  const LumoCardsCup({required this.id, this.results = const []});
  final String id;
  final List<({String roundId, bool won})> results;
  bool get complete => results.length == 3;
  int get wins => results.where((result) => result.won).length;
  int get nextRound => results.length;
  String get medal => !complete
      ? ''
      : switch (wins) {
          3 => 'Goldpokal',
          2 => 'Silberpokal',
          1 => 'Bronzepokal',
          _ => 'Entdeckerpokal',
        };
  static const opponents = [
    (difficulty: LumoCardsDifficulty.relaxed, style: LumoCardsStyle.collector),
    (difficulty: LumoCardsDifficulty.clever, style: LumoCardsStyle.adventurous),
    (difficulty: LumoCardsDifficulty.expert, style: LumoCardsStyle.planner),
  ];
  LumoCardsCup record(
      {required int round, required String roundId, required bool won}) {
    if (round < 0 || round > 2) throw StateError('Unexpected cup round');
    final existing = results.where((result) => result.roundId == roundId);
    if (existing.isNotEmpty) {
      if (round < results.length &&
          results[round].roundId == roundId &&
          existing.first.won == won) {
        return this;
      }
      throw StateError('Conflicting cup result');
    }
    if (complete ||
        round != results.length ||
        !RegExp(r'^cards-[a-f0-9]{32}$').hasMatch(roundId)) {
      throw StateError('Unexpected cup round');
    }
    return LumoCardsCup(
        id: id,
        results: List.unmodifiable([...results, (roundId: roundId, won: won)]));
  }

  Map<String, Object?> encode(String owner, int grade) => {
        'version': 1,
        'id': id,
        'owner': owner,
        'grade': grade,
        'results': [
          for (final result in results)
            {'roundId': result.roundId, 'won': result.won}
        ],
      };
  static LumoCardsCup decode(String raw, String owner, int grade) {
    if (raw.length > 4096) throw const FormatException('Cup size');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != 1 ||
        data['owner'] != owner ||
        data['grade'] != grade ||
        data['id'] is! String ||
        !RegExp(r'^cards-[a-f0-9]{32}$').hasMatch(data['id'] as String) ||
        data['results'] is! List ||
        (data['results'] as List).length > 3) {
      throw const FormatException('Invalid cup');
    }
    var cup = LumoCardsCup(id: data['id'] as String);
    for (final value in data['results'] as List) {
      if (value is! Map ||
          value['roundId'] is! String ||
          value['won'] is! bool) {
        throw const FormatException('Invalid cup result');
      }
      cup = cup.record(
          round: cup.nextRound,
          roundId: value['roundId'] as String,
          won: value['won'] as bool);
    }
    return cup;
  }
}

class LumoCardsCupRepository {
  LumoCardsCupRepository({required String studentId, required this.grade})
      : owner = sha256.convert(utf8.encode(studentId)).toString();
  final String owner;
  final int grade;
  String get storageKey => 'lumo.cards.cup.v1.$owner.$grade';
  Future<LumoCardsCup> load({required bool Function() canWrite}) =>
      LearningStorage.run((prefs) async {
        if (!canWrite()) throw StateError('Cup profile changed');
        final raw = prefs.getString(storageKey);
        if (raw != null) return LumoCardsCup.decode(raw, owner, grade);
        final cup = LumoCardsCup(id: LumoCardsRound.newId());
        await LearningStorage.write(
            prefs, storageKey, jsonEncode(cup.encode(owner, grade)));
        return cup;
      });
  Future<LumoCardsCup> record(
          {required String cupId,
          required int round,
          required String roundId,
          required bool won,
          required bool Function() canWrite}) =>
      LearningStorage.run((prefs) async {
        if (!canWrite()) throw StateError('Cup profile changed');
        final raw = prefs.getString(storageKey);
        if (raw == null) throw StateError('Cup missing');
        final cup = LumoCardsCup.decode(raw, owner, grade);
        if (cup.id != cupId) throw StateError('Cup replaced');
        final next = cup.record(round: round, roundId: roundId, won: won);
        await LearningStorage.write(
            prefs, storageKey, jsonEncode(next.encode(owner, grade)));
        return next;
      });
  Future<LumoCardsCup> restart(
          {required String cupId, required bool Function() canWrite}) =>
      LearningStorage.run((prefs) async {
        if (!canWrite()) throw StateError('Cup profile changed');
        final raw = prefs.getString(storageKey);
        if (raw == null) throw StateError('Cup missing');
        final old = LumoCardsCup.decode(raw, owner, grade);
        if (old.id != cupId || !old.complete) {
          throw StateError('Cup not completed');
        }
        final next = LumoCardsCup(id: LumoCardsRound.newId());
        await LearningStorage.write(
            prefs, storageKey, jsonEncode(next.encode(owner, grade)));
        return next;
      });
}
