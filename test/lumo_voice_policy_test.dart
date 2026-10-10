import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice_policy.dart';

void main() {
  test('no repeated greeting or condescending automatic preambles', () {
    expect(LumoVoicePolicy.prepare('Hallo! Schön, dass du da bist.'),
        'Hallo! Schön, dass du da bist.');
    expect(
        LumoVoicePolicy.prepare('Was ist deine Idee?'), 'Was ist deine Idee?');
    expect(LumoVoicePolicy.prepare('Das versuchen wir zusammen!'),
        'Das versuchen wir zusammen!');
  });
  test('newlines and punctuation never leak literal group references', () {
    final text = LumoVoicePolicy.prepare('Hallo!\nSchau mal..\nWeiter?');
    expect(text, isNot(contains(r'$1')));
    expect(text, isNot(contains('..')));
    expect(text, contains('Schau mal'));
  });
  test('natural offline voice beats network-only premium voice', () {
    expect(
        LumoVoicePolicy.score({
          'name': 'natural local',
          'locale': 'de-DE',
          'quality': '400',
          'network_required': 'false',
        }),
        greaterThan(LumoVoicePolicy.score({
          'name': 'premium neural google network',
          'locale': 'de-AT',
          'quality': '500',
          'network_required': 'true',
        })));
  });
}
