import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  testWidgets('LumoColorTile fits compact four-column Home height',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 184,
              height: 136.8,
              child: LumoColorTile(
                icon: Icons.menu_book_rounded,
                title: 'Lernen',
                subtitle: 'Mathe, Deutsch und mehr',
                color: const Color(0xFF536DFE),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Lernen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
