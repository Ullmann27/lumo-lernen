import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_tutor_hint_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lumo tutor uses dark readable glass and transparent original art',
      (tester) async {
    var spoken = 0;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LumoTutorHintCard(
            text: 'Zähle die Münzen Schritt für Schritt.',
            onSpeak: () => spoken++,
          ),
        ),
      ),
    ));
    // Lumo breathes/changes poses continuously unless reduced motion is on.
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Lumo erklärt'), findsOneWidget);
    expect(find.text('Zähle die Münzen Schritt für Schritt.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-hint-animated-fox')),
        findsOneWidget);
    final fox = tester.widget<LumoCharacter>(
        find.byKey(const ValueKey('lumo-hint-animated-fox')));
    expect(fox.pose, LumoDesignFoxPose.teacherStick);
    expect(fox.ambientPoses, contains(LumoDesignFoxPose.bookPoint));

    final surface = tester.widget<Container>(
        find.byKey(const ValueKey('lumo-hologlass-tutor-card')));
    final decor = surface.decoration! as BoxDecoration;
    final gradient = decor.gradient! as LinearGradient;
    expect(gradient.colors.first, const Color(0xF00A3768));
    expect(gradient.colors.last, const Color(0xF0071B3E));
    final text = tester.widget<Text>(
        find.byKey(const ValueKey('lumo-hint-readable-text')));
    expect(text.style!.color, const Color(0xFFF3FAFF));

    await tester.tap(find.byKey(const ValueKey('lumo-hint-listen')));
    await tester.pump();
    expect(spoken, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fold or narrow view with large text has no tutor overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: LumoTutorHintCard(
              text: 'Lies zuerst, wie viel eine Münze oder ein Schein '
                  'wert ist. Zähle immer diesen Wert weiter.',
              onSpeak: () {},
              reduceMotion: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Lumo erklärt'), findsOneWidget);
    expect(find.text('Tipp anhören'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the included German friendly hint intro has real local audio',
      (tester) async {
    await LumoVoiceClips.ensureFreeLoaded();
    final clip = LumoVoiceClips.freeLookup('Hier ist ein kleiner Tipp:');
    expect(clip, isNotNull);
    expect(clip!.assetSource, contains('lumo_free/'));
  });
}
