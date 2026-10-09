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
}
