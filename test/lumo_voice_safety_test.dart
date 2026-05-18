import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_premium_voice.dart';
import 'package:lumo_lernen/widgets/fox/lumo_living_avatar.dart';

void main() {
  group('LumoPremiumVoice safety', () {
    test('is disabled when no endpoint is configured', () {
      final voice = LumoPremiumVoice();
      expect(voice.configured, isFalse);
    });

    test('sanitizes obvious private data before premium TTS', () {
      final sanitized = LumoPremiumVoice.sanitizeForPremiumTts(
        'Hallo Lena! Schreib an kind@example.com oder +43 660 1234567 in 2230 Gänserndorf. ⭐',
      );

      expect(sanitized, isNot(contains('kind@example.com')));
      expect(sanitized, isNot(contains('+43')));
      expect(sanitized, isNot(contains('2230')));
      expect(sanitized, isNot(contains('⭐')));
    });
  });

  testWidgets('LumoLivingAvatar smoke test renders without plugin calls', (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LumoLivingAvatar(
              appState: appState,
              onTap: () {},
              height: 220,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LumoLivingAvatar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });
}
