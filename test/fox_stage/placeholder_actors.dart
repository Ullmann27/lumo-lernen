import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lumo_lernen/widgets/fox/stage/lumo_actor_library.dart';

/// Liest den Platzhalter-Bildsatz (nur für Tests, wird nicht ausgeliefert).
class _FixtureBundle extends CachingAssetBundle {
  _FixtureBundle(this.root);
  final String root;

  @override
  Future<ByteData> load(String key) async {
    final file = File('$root/${key.split('/').last}');
    final bytes = await file.readAsBytes();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

const _fixture = 'test/fixtures/lumo_actor_placeholder';

Future<LumoActorLibrary> loadPlaceholderActors() =>
    LumoActorLibrary.load(_FixtureBundle(_fixture), basePath: 'fixture');
