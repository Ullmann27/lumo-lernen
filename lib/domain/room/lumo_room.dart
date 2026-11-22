import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../rewards/reward_shop.dart';

enum LumoRoomItemKind { decoration, scarf, theme }

class LumoRoomItem {
  const LumoRoomItem(this.id, this.title, this.emoji, this.cost, this.kind);
  final String id;
  final String title;
  final String emoji;
  final int cost;
  final LumoRoomItemKind kind;
  String get receiptItemId => 'lumo_room_$id';
}

/// Exact entries and star prices from SHOP in the supplied HTML 05. The
/// original demo's starting stars/XP are deliberately not granted again.
abstract final class LumoRoomCatalog {
  static const items = <LumoRoomItem>[
    LumoRoomItem(
        'plant', 'Lumo-Pflanze', '🌱', 80, LumoRoomItemKind.decoration),
    LumoRoomItem(
        'rug', 'Sternenteppich', '🟠', 120, LumoRoomItemKind.decoration),
    LumoRoomItem(
        'pet', 'Mini-Haustier', '🐾', 180, LumoRoomItemKind.decoration),
    LumoRoomItem('star', 'Sternlampe', '⭐', 220, LumoRoomItemKind.decoration),
    LumoRoomItem('scarf_blue', 'Blauer Schal', '🔵', 0, LumoRoomItemKind.scarf),
    LumoRoomItem(
        'scarf_green', 'Grüner Schal', '🟢', 160, LumoRoomItemKind.scarf),
    LumoRoomItem('scarf_rose', 'Rosa Schal', '🌸', 160, LumoRoomItemKind.scarf),
    LumoRoomItem(
        'room_space', 'Sternenraum', '🌌', 300, LumoRoomItemKind.theme),
  ];

  static LumoRoomItem byId(String id) => items.firstWhere((v) => v.id == id);

  static String purchaseId(String ownerId, String itemId) =>
      'shop:${sha256.convert(utf8.encode(ownerId))}:'
      '${sha256.convert(utf8.encode('lumo-room-v1:$itemId')).toString().substring(0, 32)}';

  static bool owns(String ownerId, LumoRoomItem item,
          Iterable<RewardShopRedemption> receipts) =>
      item.cost == 0 ||
      receipts.any((r) =>
          r.ownerId == ownerId &&
          r.transactionId == purchaseId(ownerId, item.id) &&
          r.itemId == item.receiptItemId &&
          r.itemRevision == 1 &&
          r.cost == item.cost);
}

enum LumoRoomActionKind { pet, feed }

class LumoRoomActionRequest {
  const LumoRoomActionRequest(
      {required this.actionId, required this.ownerId, required this.kind});
  final String actionId;
  final String ownerId;
  final LumoRoomActionKind kind;

  void validate() {
    final prefix = 'room:${sha256.convert(utf8.encode(ownerId))}:';
    if (ownerId.trim().isEmpty ||
        ownerId.length > 160 ||
        !RegExp(r'^room:[a-f0-9]{64}:[a-f0-9]{32}$').hasMatch(actionId) ||
        !actionId.startsWith(prefix)) {
      throw const FormatException('Ungültige Zimmeraktion');
    }
  }

  Map<String, Object?> toJson() =>
      {'actionId': actionId, 'ownerId': ownerId, 'kind': kind.name};
  factory LumoRoomActionRequest.fromJson(Map<String, Object?> value) {
    final result = LumoRoomActionRequest(
        actionId: value['actionId'] as String,
        ownerId: value['ownerId'] as String,
        kind: LumoRoomActionKind.values.byName(value['kind'] as String));
    result.validate();
    return result;
  }
}

class LumoRoomActionReceipt {
  const LumoRoomActionReceipt(
      {required this.request, required this.performedAt});
  final LumoRoomActionRequest request;
  final DateTime performedAt;
  int get starsDelta => request.kind == LumoRoomActionKind.pet ? 5 : -10;
  int get xpDelta => request.kind == LumoRoomActionKind.feed ? 20 : 0;

  Map<String, Object?> toJson() => {
        ...request.toJson(),
        'performedAt': performedAt.toIso8601String(),
        'starsDelta': starsDelta,
        'xpDelta': xpDelta,
      };

  factory LumoRoomActionReceipt.fromJson(Map<String, Object?> value) {
    final result = LumoRoomActionReceipt(
        request: LumoRoomActionRequest.fromJson(value),
        performedAt: DateTime.parse(value['performedAt'] as String));
    if (value['starsDelta'] != result.starsDelta ||
        value['xpDelta'] != result.xpDelta) {
      throw const FormatException('Widersprüchliche Zimmerbelohnung');
    }
    return result;
  }
}

/// Thrown before any wallet write, so a rejected action can leave the pending
/// queue safely. Other storage errors retain its identity for an exact retry.
class LumoRoomActionUnavailable implements Exception {
  const LumoRoomActionUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

DateTime? lumoRoomNextPraise(
    String ownerId, Iterable<LumoRoomActionReceipt> receipts) {
  DateTime? latest;
  for (final receipt in receipts) {
    if (receipt.request.ownerId == ownerId &&
        receipt.request.kind == LumoRoomActionKind.pet &&
        (latest == null || receipt.performedAt.isAfter(latest)))
      latest = receipt.performedAt;
  }
  return latest?.add(const Duration(minutes: 5));
}

class LumoRoomPurchase {
  const LumoRoomPurchase(
      {required this.itemId, required this.receipt, this.confirmed = false});
  final String itemId;
  final RewardShopRedemption receipt;
  final bool confirmed;

  Map<String, Object?> toJson() =>
      {'itemId': itemId, 'receipt': receipt.toJson(), 'confirmed': confirmed};
  factory LumoRoomPurchase.fromJson(
          Map<String, Object?> value) =>
      LumoRoomPurchase(
          itemId: value['itemId'] as String,
          receipt: RewardShopRedemption.fromJson(
              (value['receipt'] as Map).cast<String, Object?>()),
          confirmed: value['confirmed'] as bool);
}

class LumoRoomProfile {
  LumoRoomProfile({
    required this.ownerId,
    List<LumoRoomPurchase> purchases = const [],
    Set<String> equipped = const {'scarf_blue'},
    this.theme = 'starter',
    List<LumoRoomActionRequest> pendingActions = const [],
  })  : purchases = List.unmodifiable(purchases),
        equipped = Set.unmodifiable(equipped),
        pendingActions = List.unmodifiable(pendingActions);

  final String ownerId;
  final List<LumoRoomPurchase> purchases;
  final Set<String> equipped;
  final String theme;
  final List<LumoRoomActionRequest> pendingActions;

  LumoRoomProfile copyWith(
          {List<LumoRoomPurchase>? purchases,
          Set<String>? equipped,
          String? theme,
          List<LumoRoomActionRequest>? pendingActions}) =>
      LumoRoomProfile(
          ownerId: ownerId,
          purchases: purchases ?? this.purchases,
          equipped: equipped ?? this.equipped,
          theme: theme ?? this.theme,
          pendingActions: pendingActions ?? this.pendingActions);

  Map<String, Object?> toJson() => {
        'version': 1,
        'ownerId': ownerId,
        'purchases': purchases.map((v) => v.toJson()).toList(),
        'equipped': equipped.toList()..sort(),
        'theme': theme,
        'pendingActions': pendingActions.map((v) => v.toJson()).toList()
      };

  factory LumoRoomProfile.fromJson(Map<String, Object?> value) {
    if (value['version'] != 1 ||
        (value['purchases'] as List).length > 7 ||
        (value['pendingActions'] as List).length > 20) {
      throw const FormatException('Unbekannter Zimmer-Speicherstand');
    }
    final result = LumoRoomProfile(
        ownerId: value['ownerId'] as String,
        purchases: (value['purchases'] as List)
            .map((v) =>
                LumoRoomPurchase.fromJson((v as Map).cast<String, Object?>()))
            .toList(),
        equipped: (value['equipped'] as List).cast<String>().toSet(),
        theme: value['theme'] as String,
        pendingActions: (value['pendingActions'] as List)
            .map((v) => LumoRoomActionRequest.fromJson(
                (v as Map).cast<String, Object?>()))
            .toList());
    final ids = <String>{};
    for (final purchase in result.purchases) {
      final item = LumoRoomCatalog.byId(purchase.itemId);
      if (item.cost == 0 ||
          !ids.add(item.id) ||
          !LumoRoomCatalog.owns(result.ownerId, item, [purchase.receipt]) ||
          purchase.receipt.title != item.title) {
        throw const FormatException('Ungültiger Zimmerkauf');
      }
    }
    if (result.ownerId.trim().isEmpty ||
        result.ownerId.length > 160 ||
        !{'starter', 'room_space'}.contains(result.theme) ||
        result.equipped
            .any((id) => !LumoRoomCatalog.items.any((v) => v.id == id)) ||
        result.equipped.where((id) => id.startsWith('scarf_')).length != 1 ||
        result.pendingActions.any((v) => v.ownerId != result.ownerId) ||
        result.pendingActions.map((v) => v.actionId).toSet().length !=
            result.pendingActions.length) {
      throw const FormatException('Widersprüchlicher Zimmer-Speicherstand');
    }
    return result;
  }
}
