import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('1936 recovered Kart artwork is bundled into the app', () async {
    const assets = [
      'assets/lumo_design/characters/fox_kart_front.webp',
      'assets/lumo_design/kart_items/turbo_pad.webp',
      'assets/lumo_design/deco/finish_gate.webp',
      'assets/lumo_design/rewards/reward_trophy.webp',
      'assets/lumo_design/garage/steering_wheel.webp',
      'assets/lumo_design/track/ramp.webp',
      'assets/lumo_design/buildings/observatory.webp',
      'assets/lumo_design/nature/rainbow_waterfall.webp',
    ];
    for (final path in assets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000), reason: path);
    }
  });

  testWidgets('shared Lumo glass uses the recovered premium multilayer surface',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: LumoGlassCard(child: Text('Premium-Lumo')),
        ),
      ),
    ));

    final decorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .toList();
    final glass = decorations.where((d) => d.gradient is LinearGradient);
    expect(glass, isNotEmpty);
    final gradient = glass.first.gradient! as LinearGradient;
    expect(gradient.colors.length, greaterThanOrEqualTo(4));
    expect(find.text('Premium-Lumo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
