import 'package:flutter/foundation.dart';

/// Local asset failures must remain visible in Android logs even when the UI
/// offers a fallback. Call only for bundled assets, never user/network content.
void reportLumoAssetError(String asset, Object error) {
  assert(asset.startsWith('assets/'));
  debugPrint(
      'LUMO_ASSET_ERROR asset=$asset type=${error.runtimeType} error=$error');
}
