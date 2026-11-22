import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'lumo_achievement.dart';

/// One immutable, catalog-priced payout for one child and one achievement.
/// The wallet persists this receipt in the same snapshot as its stars.
class AchievementClaim {
  const AchievementClaim({required this.ownerId, required this.achievementId});

  final String ownerId;
  final String achievementId;

  String get claimId =>
      'achievement:${sha256.convert(utf8.encode(ownerId))}:$achievementId';

  int get stars {
    validate();
    return LumoAchievementCatalog.byId(achievementId)!.rewardStars;
  }

  void validate() {
    if (ownerId.trim() != ownerId ||
        ownerId.isEmpty ||
        ownerId.length > 160 ||
        ownerId.runes.any((v) => v < 32) ||
        LumoAchievementCatalog.byId(achievementId) == null) {
      throw ArgumentError('Ungültige profilgebundene Auszeichnung.');
    }
  }

  Map<String, Object> toJson() => {
        'ownerId': ownerId,
        'achievementId': achievementId,
        'claimId': claimId,
        'stars': stars,
      };

  factory AchievementClaim.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value.keys.toSet().difference(const {
          'ownerId',
          'achievementId',
          'claimId',
          'stars'
        }).isNotEmpty ||
        value['ownerId'] is! String ||
        value['achievementId'] is! String) {
      throw const FormatException('Ungültiger Auszeichnungsbeleg.');
    }
    final claim = AchievementClaim(
        ownerId: value['ownerId'] as String,
        achievementId: value['achievementId'] as String);
    claim.validate();
    if (value['claimId'] != claim.claimId || value['stars'] != claim.stars) {
      throw const FormatException(
          'Auszeichnungsbeleg passt nicht zum Katalog.');
    }
    return claim;
  }
}
