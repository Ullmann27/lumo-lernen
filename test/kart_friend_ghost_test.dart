import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/kart_friends/kart_friend_ghost.dart';

/// Die Datei stammt aus dem Godot-Test kart_friend_duel_regression.gd (Rückspiel-Geist).
Uint8List _fixture() =>
    File('test/fixtures/kart_friend_ghost_lena.lumogeist').readAsBytesSync();

/// Ersetzt den Vornamen und rechnet die Prüfsumme neu (prüft die Inhaltsregeln).
Uint8List _withName(Uint8List data, List<int> name) {
  var at = 5;
  for (var i = 0; i < 5; i++) {
    at += 1 + data[at];
  }
  final oldLength = data[at];
  final body = <int>[
    ...data.sublist(0, at),
    name.length,
    ...name,
    ...data.sublist(at + 1 + oldLength, data.length - 8),
  ];
  return Uint8List.fromList(
      [...body, ...sha256.convert(body).bytes.sublist(0, 8)]);
}

void main() {
  test('Godot-Geist wird gelesen: Name, Strecke, Zeit, Textform', () {
    final result = KartFriendGhost.read(_fixture());
    expect(result.message, isNull);
    final ghost = result.ghost!;
    expect(ghost.name, 'Lena');
    expect(ghost.track, 'sonnenhafen');
    expect(ghost.trackName, 'Sonnenhafen');
    expect(ghost.timeMs, greaterThan(5000));
    expect(ghost.timeText, matches(RegExp(r'^\d+:\d\d,\d$')));
    expect(KartFriendGhost.isLaunchText(ghost.launchText), isTrue);
    expect(ghost.launchText.contains('='), isFalse);
  });

  test('leere, zu große und fremde Dateien werden abgelehnt', () {
    expect(KartFriendGhost.read(null).ghost, isNull);
    expect(KartFriendGhost.read(Uint8List(0)).message, 'Die Datei ist leer.');
    expect(KartFriendGhost.read(Uint8List(65537)).message, contains('zu groß'));
    expect(
        KartFriendGhost.read(Uint8List.fromList('%PDF-1.7'.codeUnits)).message,
        'Das ist kein Lumo-Geist.');
  });

  test('jedes gekippte Byte und jede Kürzung wird abgelehnt', () {
    final data = _fixture();
    var rejected = 0;
    for (var i = 0; i < data.length; i += 7) {
      final broken = Uint8List.fromList(data);
      broken[i] ^= 0x10;
      if (KartFriendGhost.read(broken).ghost == null) rejected++;
    }
    expect(rejected, (data.length + 6) ~/ 7);
    expect(
        KartFriendGhost.read(Uint8List.sublistView(data, 0, data.length - 1))
            .ghost,
        isNull);
    expect(
        KartFriendGhost.read(Uint8List.fromList([...data, 0])).ghost, isNull);
  });

  test('neueres Format bekommt einen Aktualisieren-Hinweis', () {
    final data = Uint8List.fromList(_fixture());
    data[4] = 2;
    expect(KartFriendGhost.read(data).message, contains('aktualisieren'));
  });

  test('Name mit Steuerzeichen wird trotz gültiger Prüfsumme abgelehnt', () {
    final data = _fixture();
    expect(KartFriendGhost.read(_withName(data, 'Mia'.codeUnits)).ghost?.name,
        'Mia');
    expect(
        KartFriendGhost.read(_withName(data, 'Mi\na'.codeUnits)).ghost, isNull);
    expect(
        KartFriendGhost.read(_withName(data, '<b>'.codeUnits)).ghost, isNull);
  });

  test('Startoption nur in der geprüften Textform', () {
    expect(KartFriendGhost.isLaunchText('LUMOGEIST1:abc'), isFalse);
    expect(KartFriendGhost.isLaunchText('http://example.com'), isFalse);
    expect(KartFriendGhost.isLaunchText('LUMOGEIST1:${'A' * 40}+'), isFalse);
  });
}
