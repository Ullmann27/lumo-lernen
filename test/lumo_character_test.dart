import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';

/// Lumo als Zeichentrickfigur: Leerlauf, Jubeln, Trösten, Antippen.
void main() {
  Future<LumoCharacterController> pumpLumo(WidgetTester tester,
      {bool reduceMotion = false, VoidCallback? onTap}) async {
    final controller = LumoCharacterController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: LumoCharacter(
          pose: LumoDesignFoxPose.thumbWink,
          size: 160,
          reduceMotion: reduceMotion,
          controller: controller,
          onTap: onTap,
        ),
      ),
    ));
    return controller;
  }

  Matrix4 figureTransform(WidgetTester tester) => tester
      .widgetList<Transform>(find.descendant(
          of: find.byType(LumoCharacter), matching: find.byType(Transform)))
      .last
      .transform;

  String shownPose(WidgetTester tester) =>
      tester.widget<LumoFoxPose>(find.byType(LumoFoxPose)).pose.assetName;

  testWidgets('im Leerlauf atmet und schwankt Lumo', (tester) async {
    await pumpLumo(tester);
    await tester.pump(const Duration(milliseconds: 800));
    final first = figureTransform(tester).clone();
    await tester.pump(const Duration(milliseconds: 900));
    expect(figureTransform(tester), isNot(equals(first)),
        reason: 'Lumo steht nie ganz still');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('beim Jubeln springt Lumo in der Jubel-Pose und landet wieder',
      (tester) async {
    final controller = await pumpLumo(tester);
    await tester.pump(const Duration(milliseconds: 700));
    controller.cheer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(shownPose(tester), 'fox_cheer');
    // Mitten im Sprung ist Lumo deutlich über dem Boden.
    final lift = tester
        .widgetList<Transform>(find.descendant(
            of: find.byType(LumoCharacter), matching: find.byType(Transform)))
        .first
        .transform
        .getTranslation()
        .y;
    expect(lift, lessThan(-10));
    await tester.pump(const Duration(milliseconds: 800));
    expect(shownPose(tester), 'fox_thumb_wink');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('beim Trösten neigt sich Lumo zur Seite', (tester) async {
    final controller = await pumpLumo(tester);
    await tester.pump(const Duration(milliseconds: 700));
    controller.comfort();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));
    final m = figureTransform(tester);
    // Drehung im Uhrzeigersinn negativ: Lumo lehnt sich tröstend zur Seite.
    expect(m.entry(1, 0), lessThan(-0.03));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Antippen ruft die Aktion auf und Lumo wackelt', (tester) async {
    var taps = 0;
    await pumpLumo(tester, onTap: () => taps++);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.byType(LumoCharacter));
    await tester.pump(const Duration(milliseconds: 120));
    expect(taps, 1);
    expect(figureTransform(tester).entry(1, 0).abs(), greaterThan(0.01));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mit „Animationen reduzieren“ steht Lumo still', (tester) async {
    final controller = await pumpLumo(tester, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'keine laufende Dauer-Animation');
    final still = figureTransform(tester).clone();
    controller.comfort();
    await tester.pump(const Duration(milliseconds: 400));
    expect(figureTransform(tester), equals(still));
    // Freude zeigt Lumo dann nur über die Jubel-Pose.
    controller.cheer();
    await tester.pump();
    expect(shownPose(tester), 'fox_cheer');
    await tester.pump(const Duration(seconds: 1));
    expect(shownPose(tester), 'fox_thumb_wink');
  });
}
