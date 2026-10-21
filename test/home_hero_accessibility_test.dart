import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';

import 'helpers/lumo_capture.dart';

void main() {
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (width, scale) in [(840.0, 1.0), (393.0, 2.0), (320.0, 1.2)]) {
    testWidgets('Home keeps the complete fox and welcome at $width / $scale',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      addTearDown(state.dispose);
      state.update(state.state.copyWith(childName: 'Mia'));
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child:
              Scaffold(body: HomeContent(appState: state, onSection: (_) {})),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      final hero = find.byKey(const ValueKey('home-adventure-hero'));
      final fox =
          find.descendant(of: hero, matching: find.byType(LumoCharacter));
      final heroRect = tester.getRect(hero).inflate(.001);
      final foxRect = tester.getRect(fox);
      expect(heroRect.contains(foxRect.topLeft), isTrue,
          reason: 'Original ears must not be clipped at the top of the hero');
      expect(heroRect.contains(foxRect.bottomRight), isTrue,
          reason: 'Original feet and tail must remain inside the hero');
      const caption = 'Bereit für ein neues Abenteuer?';
      final paragraph =
          tester.renderObject<RenderParagraph>(find.text(caption));
      final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: caption.length));
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        // Font glyph bounds can extend a fraction beyond the rounded line box.
        expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 1),
            reason: 'Every line of the welcome must be visible at large text');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
