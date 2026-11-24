import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_interaction_feedback_policy.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup greeting references a genuine packaged voice clip', () async {
    final catalog = jsonDecode(await rootBundle.loadString(
      'assets/audio/voice/lumo_free/catalog.json',
    )) as Map<String, dynamic>;
    final clips = catalog['clips'] as Map<String, dynamic>;
    final key = LumoVoiceClips.keyFor(
      LumoInteractionFeedbackPolicy.recordedGreeting);
    expect(clips.containsKey(key), isTrue);
    final clip = clips[key] as Map<String, dynamic>;
    expect(clip['style'], 'greeting');
    expect(clip['ms'], greaterThan(1000));
  });

  test('welcome follows profile, voice preference and deep-link guards', () {
    bool greet(bool profile, bool deep, bool voice, bool auto) =>
        LumoInteractionFeedbackPolicy.shouldGreet(
          hasProfile: profile, isDeepLink: deep,
          enabled: voice, autoRead: auto);
    expect(greet(true, false, true, true), isTrue);
    expect(greet(false, false, true, true), isFalse);
    expect(greet(true, true, true, true), isFalse);
    expect(greet(true, false, false, true), isFalse);
    expect(greet(true, false, true, false), isFalse);
  });

  test('navigation tap obeys mute preference', () {
    expect(LumoInteractionFeedbackPolicy.shouldPlayTap(
      soundEnabled: true, destinationChanged: true), isTrue);
    expect(LumoInteractionFeedbackPolicy.shouldPlayTap(
      soundEnabled: false, destinationChanged: true), isFalse);
    expect(LumoInteractionFeedbackPolicy.shouldPlayTap(
      soundEnabled: true, destinationChanged: false), isFalse);
  });
}
