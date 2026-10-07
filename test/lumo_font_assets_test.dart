import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Die runde Schrift der Zielbilder (Nunito) ist fest eingebunden, damit das
/// Handy nicht auf eine Ersatzschrift ausweicht.
void main() {
  test('Nunito ist mit vier Schnitten in pubspec.yaml eingetragen', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- family: Nunito'));
    for (final cut in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      final path = 'assets/fonts/Nunito-$cut.ttf';
      expect(pubspec, contains('asset: $path'));
      expect(File(path).lengthSync(), greaterThan(20000), reason: path);
    }
    expect(File('assets/fonts/OFL.txt').readAsStringSync(),
        contains('SIL Open Font License'));
  });
}
