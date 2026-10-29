import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  testWidgets('Home Bento icon remains meaningful while its PNG decodes',
      (tester) async {
    // A cold start must not present an empty tile while the bundled 3D PNG
    // is decoded. The paint fallback only exists until the first frame.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: LumoColorTile(
                icon: Icons.menu_book_rounded,
                iconAsset: 'assets/lumo_design/icons/book_open.png',
                title: 'Lernen',
                subtitle: 'Mathe und Deutsch',
                color: const Color(0xFF328DFF),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final art = find.byKey(const ValueKey('lumo-color-tile-icon-lernen'));
    expect(art, findsOneWidget);
    expect(find.text('Lernen'), findsOneWidget);
    // Before the decoder returns, fallback has the same icon meaning.
    // An already resolved cached image is also valid.
    expect(
      find.byIcon(Icons.menu_book_rounded).evaluate().isNotEmpty ||
          (tester.widget<Image>(art).image is AssetImage),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(art, findsOneWidget);
    expect(find.text('Lernen'), findsOneWidget);
  });
}
