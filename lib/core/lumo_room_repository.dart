import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rewards/reward_shop.dart';
import '../domain/room/lumo_room.dart';

class LumoRoomRepository {
  const LumoRoomRepository();
  static final Map<String, Future<void>> _writes = {};

  static String profileKey(String ownerId) =>
      'lumo.room.profile.${sha256.convert(utf8.encode(ownerId))}';

  Future<LumoRoomProfile> load(String ownerId) async {
    if (ownerId.trim().isEmpty || ownerId.length > 160) {
      throw ArgumentError('Ein Kinderprofil ist erforderlich');
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(profileKey(ownerId));
    if (raw == null) return LumoRoomProfile(ownerId: ownerId);
    final profile = LumoRoomProfile.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>());
    if (profile.ownerId != ownerId)
      throw const FormatException('Falsches Zimmerprofil');
    return profile;
  }

  Future<LumoRoomProfile> stagePurchase(
      {required String ownerId,
      required LumoRoomItem item,
      required void Function() validateOwner}) {
    if (item.cost <= 0 || !identical(item, LumoRoomCatalog.byId(item.id))) {
      throw ArgumentError('Ungültiger Zimmergegenstand');
    }
    return _update(ownerId, validateOwner, (profile) {
      // The first confirmed quote remains the identity for every retry,
      // including two independently opened screens or process restart.
      if (profile.purchases.any((v) => v.itemId == item.id)) return profile;
      return profile.copyWith(purchases: [
        ...profile.purchases,
        LumoRoomPurchase(
            itemId: item.id,
            receipt: RewardShopRedemption(
              transactionId: LumoRoomCatalog.purchaseId(ownerId, item.id),
              ownerId: ownerId,
              itemId: item.receiptItemId,
              itemRevision: 1,
              title: item.title,
              emoji: item.emoji,
              cost: item.cost,
              minLevel: 1,
              category: CustomRewardCategory.lumo,
              description: 'Gegenstand für Lumos Zimmer',
              redeemedAt: DateTime.now().toUtc(),
            )),
      ]);
    });
  }

  Future<LumoRoomProfile> confirmPurchase(
          {required String ownerId,
          required String itemId,
          required void Function() validateOwner}) =>
      _update(
          ownerId,
          validateOwner,
          (profile) => profile.copyWith(purchases: [
                for (final value in profile.purchases)
                  value.itemId == itemId
                      ? LumoRoomPurchase(
                          itemId: value.itemId,
                          receipt: value.receipt,
                          confirmed: true)
                      : value,
              ]));

  Future<LumoRoomProfile> equip(
          {required String ownerId,
          required LumoRoomItem item,
          required List<RewardShopRedemption> receipts,
          required void Function() validateOwner}) =>
      _update(ownerId, validateOwner, (profile) {
        if (!LumoRoomCatalog.owns(ownerId, item, receipts)) {
          throw StateError('Dieser Gegenstand ist noch nicht gekauft.');
        }
        if (item.kind == LumoRoomItemKind.theme)
          return profile.copyWith(theme: item.id);
        final equipped = {...profile.equipped};
        if (item.kind == LumoRoomItemKind.scarf) {
          equipped.removeWhere((id) => id.startsWith('scarf_'));
        }
        equipped.add(item.id);
        return profile.copyWith(equipped: equipped);
      });

  static LumoRoomActionRequest newAction(
      String ownerId, LumoRoomActionKind kind) {
    final random = Random.secure();
    final nonce = List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    return LumoRoomActionRequest(
        actionId: 'room:${sha256.convert(utf8.encode(ownerId))}:$nonce',
        ownerId: ownerId,
        kind: kind);
  }

  Future<LumoRoomProfile> stageAction(
      {required LumoRoomActionRequest request,
      required void Function() validateOwner}) {
    request.validate();
    return _update(request.ownerId, validateOwner, (profile) {
      for (final existing in profile.pendingActions) {
        if (existing.actionId != request.actionId) continue;
        if (existing.kind != request.kind)
          throw StateError('Die Zimmeraktion hat sich geändert.');
        return profile;
      }
      if (profile.pendingActions.length >= 20) {
        throw StateError('Bitte schließe zuerst die wartende Zimmeraktion ab.');
      }
      return profile
          .copyWith(pendingActions: [...profile.pendingActions, request]);
    });
  }

  Future<LumoRoomProfile> finishAction(
          {required String ownerId,
          required String actionId,
          required void Function() validateOwner}) =>
      _update(
          ownerId,
          validateOwner,
          (profile) => profile.copyWith(
              pendingActions: profile.pendingActions
                  .where((v) => v.actionId != actionId)
                  .toList()));

  Future<LumoRoomProfile> _update(String ownerId, void Function() validateOwner,
      LumoRoomProfile Function(LumoRoomProfile) mutate) {
    final before = _writes[ownerId] ?? Future<void>.value();
    final work = before.then((_) async {
      validateOwner();
      final profile = await load(ownerId);
      validateOwner();
      final next = mutate(profile);
      final prefs = await SharedPreferences.getInstance();
      validateOwner();
      if (!await prefs.setString(
          profileKey(ownerId), jsonEncode(next.toJson()))) {
        throw StateError(
            'Dein Zimmer konnte noch nicht gespeichert werden. Bitte erneut versuchen.');
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

  static Future<void> flushPendingWrites() async {
    while (_writes.isNotEmpty) {
      await Future.wait(_writes.values.toList());
    }
  }
}
