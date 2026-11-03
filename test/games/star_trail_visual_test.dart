import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/star_trail/star_trail_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in <(String, Size)>[
    ('phone 360x800', const Size(360, 800)),
    ('Fold inner 690x829', const Size(690, 829)),
    ('tablet 1024x768', const Size(1024, 768)),
  ]) {
    testWidgets('Sternenpfad original Lumo and play on ' + entry.$1,
        (tester) async {
      await tester.binding.setSurfaceSize(entry.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: LumoStarTrailScreen()));
      await tester.pump(const Duration(milliseconds: 550));
      expect(find.byType(LumoCharacter), findsOneWidget);
      expect(find.text('Gemeinsam über die Wolken!'), findsOneWidget);
      expect(find.text('WÄHLE DEINE NÄCHSTE KARTE'), findsOneWidget);
      expect(find.text('Sternlaterne'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final lantern = find.text('Sternlaterne');
      await tester.ensureVisible(lantern);
      await tester.pump();
      await tester.tap(lantern);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('1/12'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
