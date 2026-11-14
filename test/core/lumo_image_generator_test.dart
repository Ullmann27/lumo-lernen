import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_image_generator.dart';

void main() {
  final generator = LumoImageGenerator.instance;

  test('ohne Elternfreigabe wird nie eine Online-Adresse gebaut', () {
    // Online-Bilder sind Online-KI (pollinations.ai): IP-Adresse und Themenwort verlassen das
    // Gerät. Sie gehören hinter den Elternschalter, der in frischen Einstellungen aus ist.
    expect(generator.buildSafeImageUrl('Hund'), isNull);
    expect(generator.buildSafeImageUrl('rote Blume', allowOnline: false), isNull);
    expect(generator.buildSafeImageUrl('Apfel', width: 256, height: 256), isNull);
  });

  test('mit Freigabe: nur Themen der Positivliste, übersetzt, ohne freien Kindertext', () {
    final url = generator.buildSafeImageUrl('Hund', allowOnline: true);
    expect(url, isNotNull);
    final uri = Uri.parse(url!);
    expect(uri.host, 'image.pollinations.ai');
    expect(uri.queryParameters['safe'], 'true');
    expect(Uri.decodeComponent(uri.path), contains('dog'));
    // Freier Kindertext wird nie gesendet: Aus dem Satz bleibt nur das übersetzte Themenwort.
    final personal = generator.buildSafeImageUrl(
        'Zeig mir bitte den Hund von Anna Müller aus der Hauptstraße 5',
        allowOnline: true);
    expect(personal, isNotNull);
    final sent = Uri.decodeComponent(Uri.parse(personal!).path).toLowerCase();
    expect(sent, contains('dog'));
    for (final secret in ['anna', 'müller', 'mueller', 'hauptstraße', 'hauptstrasse', '5']) {
      expect(sent.contains(secret), isFalse, reason: '„$secret“ darf nicht in der Adresse stehen');
    }
    // Was nicht auf der Positivliste steht, wird auch mit Freigabe nicht angefragt.
    expect(generator.buildSafeImageUrl('Pistole', allowOnline: true), isNull);
  });

  test('Orange als einziges Motiv sendet keinen persönlichen Freitext', () {
    const input = 'Zeig mir orange, ich heiße SYNTHETIC_NAME_2708 '
        'und wohne in SYNTHETIC_ADDRESS_2708.';
    final url = generator.buildSafeImageUrl(input, allowOnline: true);
    expect(url, isNotNull);
    final sent = Uri.parse(url!).pathSegments.last;
    expect(sent, isNot(contains('SYNTHETIC_NAME_2708')));
    expect(sent, isNot(contains('SYNTHETIC_ADDRESS_2708')));
    expect(sent, isNot(contains('Zeig mir')));
    expect(sent, startsWith('orange, '));
  });

  test('Orange ohne weiteres Motiv bleibt die erlaubte Frucht', () {
    for (final input in ['Orange', 'orange', 'Zeig mir eine Orange']) {
      final url = generator.buildSafeImageUrl(input, allowOnline: true);
      expect(url, isNotNull, reason: input);
      expect(Uri.parse(url!).pathSegments.last, startsWith('orange, '),
          reason: input);
    }
  });

  test('Farbe und Motiv werden ausschließlich aus festen Werten gebaut', () {
    const cases = {
      'orange Auto': 'orange-colored car',
      'orange Apfel': 'orange-colored apple',
      'rot Hund': 'red-colored dog',
      'blau Katze': 'blue-colored cat',
      'gruen Baum': 'green-colored tree',
      'pink Blume': 'pink-colored flower',
    };
    for (final entry in cases.entries) {
      final url = generator.buildSafeImageUrl(
          '${entry.key} SYNTHETIC_PRIVATE_MARKER_2708',
          allowOnline: true);
      expect(url, isNotNull, reason: entry.key);
      final uri = Uri.parse(url!);
      expect(uri.host, 'image.pollinations.ai');
      expect(uri.queryParameters['safe'], 'true');
      expect(uri.pathSegments.last, startsWith('${entry.value}, '),
          reason: entry.key);
      expect(uri.pathSegments.last,
          isNot(contains('SYNTHETIC_PRIVATE_MARKER_2708')));
    }
  });

  test('Farbe allein und nicht erlaubte Motive erzeugen keine Online-Adresse', () {
    for (final input in [
      '',
      'blau SYNTHETIC_PRIVATE_MARKER_2708',
      'SYNTHETIC_PRIVATE_MARKER_2708',
      'Pistole',
    ]) {
      expect(generator.buildSafeImageUrl(input, allowOnline: true), isNull,
          reason: input);
    }
  });

  test('Orange und Farb-Motiv-Kombinationen benötigen weiterhin Elternfreigabe',
      () {
    for (final input in [
      'Orange',
      'Zeig mir orange SYNTHETIC_PRIVATE_MARKER_2708',
      'orange Auto',
      'blau Katze',
    ]) {
      expect(generator.buildSafeImageUrl(input), isNull, reason: input);
      expect(generator.buildSafeImageUrl(input, allowOnline: false), isNull,
          reason: input);
    }
  });
}
