import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rewards/reward_shop.dart';

/// Persistiert RewardShopState in SharedPreferences pro Kind.
class RewardShopRepository {
  const RewardShopRepository();

  String _key(String childId) => 'lumo.reward_shop.$childId';

  Future<RewardShopState> load(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(childId));
      if (raw == null || raw.isEmpty) return const RewardShopState();
      final json = jsonDecode(raw);
      if (json is! Map) return const RewardShopState();
      return RewardShopState.fromJson(json.cast<String, Object?>());
    } catch (_) {
      return const RewardShopState();
    }
  }

  Future<void> save(String childId, RewardShopState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(childId), jsonEncode(state.toJson()));
    } catch (_) {
      // Ignorieren - im Notfall verliert das Kind ein paar Sterne,
      // aber die App soll nicht crashen.
    }
  }
}
