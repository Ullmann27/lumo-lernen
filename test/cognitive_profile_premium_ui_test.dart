import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';
import 'package:lumo_lernen/features/tests/cognitive_profile_screen.dart';
import 'package:lumo_lernen/features/tests/iq/iq_start_view.dart';
import 'package:lumo_lernen/features/tests/iq/iq_widgets.dart';

import 'iq/iq_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIqFonts);
  setUp(() async => resetIqEnvironment());

  for (final size in <Size>[const Size(360, 640), const Size(412, 915),
      const Size(690, 829), const Size(915, 412)]) {
    testWidgets('Denkprofil shares premium hero/skills and starts on $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = iqTestApp();
      addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CognitiveProfileScreen(appState: app),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(IqHeroHeader), findsOneWidget);
      expect(find.text('Lumo Denkprofil'), findsOneWidget);
      expect(find.byType(IqSkillChip),
          findsNWidgets(CognitiveDomain.values.length));
      expect(find.byKey(const ValueKey('cognitive-start-button')),
          findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('cognitive-start-button')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(IqHeroHeader), findsNothing);
      expect(find.byKey(const ValueKey('cognitive-next')), findsOneWidget);
      // In short landscape view ListView builds only visible rows. Assert
      // the actual rendered cards without mistaking laziness for a loss.
      expect(find.byType(IqTile), findsAtLeastNWidgets(3));
      expect(find.text('1/50'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
