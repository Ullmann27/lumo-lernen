import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rewards/reward_shop.dart';
import '../domain/rewards/reward_catalog.dart';

/// Persistiert RewardShopState in SharedPreferences pro Kind.
class RewardShopRepository {
  const RewardShopRepository();

  static final Map<String, Future<void>> _writes = {};

  String _key(String childId) => 'lumo.reward_shop.$childId';

  Future<RewardShopState> load(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(childId));
    if (raw == null || raw.isEmpty) return const RewardShopState();
    final json = jsonDecode(raw);
    if (json is! Map) {
      throw const FormatException('Ungültiger Shop-Speicherstand');
    }
    return RewardShopState.fromJson(json.cast<String, Object?>());
  }

  Future<void> save(String childId, RewardShopState state) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key(childId), jsonEncode(state.toJson()))) {
      throw StateError('Der Shop konnte noch nicht gespeichert werden');
    }
  }

  static String _randomId() {
    final random = Random.secure();
    return List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String newDefinitionId() => 'custom_${_randomId()}';

  static String profileKey(String ownerId) =>
      'lumo.reward_shop.profile.${sha256.convert(utf8.encode(ownerId))}';

  static String legacyChildId(String name, int grade) {
    final safe = name.trim().isEmpty
        ? 'kind'
        : name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safe}_$grade';
  }

  static RewardShopRedemption createRedemption({
    required String ownerId,
    required RewardItem item,
  }) {
    if (item.currency != RewardCurrency.stars) {
      throw ArgumentError('Neue Gutscheine werden mit Sternen eingelöst');
    }
    final receipt = RewardShopRedemption(
      transactionId:
          'shop:${sha256.convert(utf8.encode(ownerId))}:${_randomId()}',
      ownerId: ownerId,
      itemId: item.id,
      itemRevision: item.revision,
      title: item.title,
      emoji: item.emoji,
      description: item.description,
      cost: item.cost,
      minLevel: item.minLevel,
      category: item.category,
      redeemedAt: DateTime.now().toUtc(),
    );
    receipt.validate();
    return receipt;
  }

  Future<RewardShopProfile> loadProfile(String ownerId) async {
    if (ownerId.trim().isEmpty || ownerId.length > 160) {
      throw ArgumentError('Ein Kinderprofil ist erforderlich');
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(profileKey(ownerId));
    if (raw == null) return RewardShopProfile(ownerId: ownerId);
    final value = RewardShopProfile.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>());
    if (value.ownerId != ownerId) {
      throw const FormatException('Gutscheine gehören zu einem anderen Profil');
    }
    return value;
  }

  Future<RewardShopProfile> saveDefinition({
    required String ownerId,
    required CustomRewardDefinition definition,
    required void Function() validateOwner,
  }) {
    definition.validate();
    return _update(ownerId, validateOwner, (current) {
      CustomRewardDefinition? previous;
      for (final item in current.currentDefinitions) {
        if (item.id == definition.id) previous = item;
      }
      if (previous != null &&
          previous.revision == definition.revision &&
          jsonEncode(previous.toJson()) == jsonEncode(definition.toJson())) {
        // An identical retry must still obtain a positive disk confirmation.
        return current;
      }
      if (definition.revision != (previous?.revision ?? 0) + 1) {
        throw StateError(
            'Dieser Gutschein wurde inzwischen geändert. Bitte neu öffnen.');
      }
      if (previous == null && current.currentDefinitions.length >= 100) {
        throw StateError('Bis zu 100 eigene Gutscheine sind möglich.');
      }
      if (current.revisions.length >= 5000) {
        throw StateError(
            'Der Gutschein-Speicher ist voll. Bestehende Belege bleiben erhalten.');
      }
      return current.copyWith(revisions: [...current.revisions, definition]);
    });
  }

  Future<RewardShopProfile> stageRedemption({
    required RewardShopRedemption redemption,
    required void Function() validateOwner,
  }) {
    redemption.validate();
    return _update(redemption.ownerId, validateOwner, (current) {
      for (final value in current.pendingRedemptions) {
        if (value.transactionId != redemption.transactionId) continue;
        if (jsonEncode(value.toJson()) != jsonEncode(redemption.toJson())) {
          throw StateError('Eine bestätigte Einlösung darf sich nicht ändern');
        }
        return current;
      }
      if (redemption.itemId.startsWith('custom_')) {
        final originals = current.revisions.where((v) =>
            v.id == redemption.itemId && v.revision == redemption.itemRevision);
        if (originals.length != 1 || !_matches(originals.single, redemption)) {
          throw StateError('Die ursprüngliche Gutschein-Definition fehlt');
        }
      } else {
        final originals =
            RewardCatalog.all.where((item) => item.id == redemption.itemId);
        if (originals.length != 1 ||
            originals.single.title != redemption.title ||
            originals.single.cost != redemption.cost ||
            originals.single.currency != RewardCurrency.stars ||
            originals.single.emoji != redemption.emoji ||
            originals.single.minLevel != redemption.minLevel ||
            originals.single.revision != redemption.itemRevision) {
          throw StateError('Die ursprüngliche Katalog-Belohnung fehlt');
        }
      }
      if (current.pendingRedemptions.length >= 100) {
        throw StateError('Bitte schließe zuerst die wartenden Einlösungen ab.');
      }
      return current.copyWith(pendingRedemptions: [
        ...current.pendingRedemptions,
        redemption,
      ]);
    });
  }

  static bool _matches(
          CustomRewardDefinition item, RewardShopRedemption receipt) =>
      item.active &&
      item.title == receipt.title &&
      item.emoji == receipt.emoji &&
      item.description == receipt.description &&
      item.cost == receipt.cost &&
      item.minLevel == receipt.minLevel &&
      item.category == receipt.category;

  Future<RewardShopProfile> finishRedemption({
    required String ownerId,
    required String transactionId,
    required void Function() validateOwner,
  }) =>
      _update(
          ownerId,
          validateOwner,
          (current) => current.copyWith(
                pendingRedemptions: current.pendingRedemptions
                    .where((v) => v.transactionId != transactionId)
                    .toList(),
              ));

  Future<RewardShopProfile> _update(
    String ownerId,
    void Function() validateOwner,
    RewardShopProfile Function(RewardShopProfile) change,
  ) {
    final before = _writes[ownerId] ?? Future<void>.value();
    final work = before.then((_) async {
      validateOwner();
      final current = await loadProfile(ownerId);
      validateOwner();
      final next = change(current);
      final prefs = await SharedPreferences.getInstance();
      validateOwner();
      final saved =
          await prefs.setString(profileKey(ownerId), jsonEncode(next.toJson()));
      if (!saved) {
        throw StateError(
            'Der Gutschein konnte noch nicht gespeichert werden. Bitte erneut versuchen.');
      }
      return next;
    });
    late final Future<void> tail;
    void release() {
      if (identical(_writes[ownerId], tail)) _writes.remove(ownerId);
    }

    tail = work.then<void>((_) => release(),
        onError: (Object _, StackTrace __) => release());
    _writes[ownerId] = tail;
    return work;
  }

  /// Backup waits for accepted writes, then reads the complete preference set.
  static Future<void> flushPendingWrites() async {
    while (_writes.isNotEmpty) {
      await Future.wait(_writes.values.toList());
    }
  }
}
