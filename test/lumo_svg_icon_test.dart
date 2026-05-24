import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_icon_paths.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_svg_icon.dart';

/// Smoke-Tests fuer LumoSvgIcon. Im Test-Kontext ist rootBundle leer,
/// daher rendert flutter_svg eine leere Placeholder-Box - das ist OK,
/// wir verifizieren nur "kein Crash".
void main() {
  group('LumoSvgIcon', () {
    testWidgets('rendert ohne Exception bei valid LumoIconPaths-Pfad',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LumoSvgIcon(
              path: LumoIconPaths.settings,
              size: 24,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert mit color-Tint ohne Crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LumoSvgIcon(
              path: LumoIconPaths.star,
              size: 32,
              color: Colors.orange,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('faengt fehlende Asset-Datei ab (kein Crash)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LumoSvgIcon(
              path: 'assets/icons/__nonexistent__.svg',
              size: 24,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      // flutter_svg gibt bei fehlendem Asset eine leere Box zurueck -
      // kein roter Error-Widget-Crash.
      expect(tester.takeException(), isNull);
    });
  });
}
