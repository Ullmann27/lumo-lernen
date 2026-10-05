import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die 142 Einzelbilder aus Heinz' Bildtafeln (docs/design_targets/2026-10-04/tafeln/
/// manifest.json) muessen als WebP im App-Bundle liegen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = jsonDecode(
    File('docs/design_targets/2026-10-04/tafeln/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final images = (manifest['bilder'] as List).cast<Map<String, dynamic>>();

  test('Manifest listet alle 142 Einzelbilder', () {
    expect(images, hasLength(142));
    expect(images.map((image) => image['datei']).toSet(), hasLength(142));
  });

  for (final image in images) {
    final path = image['datei'] as String;
    test('$path ist als WebP gebuendelt', () async {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      expect(bytes.length, image['bytes']);
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(bytes.sublist(8, 12)), 'WEBP');
    });
  }
}
