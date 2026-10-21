// Genuine production-widget rasterizations; no painted text or concept images.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_motion.dart';
import '../helpers/lumo_capture.dart';

void main() {
  final out = Platform.environment['LUMO_SPATIAL_CAPTURES'];
  setUpAll(loadLumoCaptureFonts);
  for (final size in lumoCaptureSizes.entries) {
    testWidgets('spatial reading and home ${size.key}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final voice = LumoVoice.instance.isEnabled;
      final motion = LumoMotion.appReduced;
      LumoVoice.instance.isEnabled = false;
      LumoMotion.appReduced = true;
      addTearDown(() {
        LumoVoice.instance.isEnabled = voice;
        LumoMotion.appReduced = motion;
      });
      await tester.binding.setSurfaceSize(size.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      addTearDown(state.dispose);
      const boundary = ValueKey('spatial-capture');
      Future<void> show(Widget child) async {
        await tester.pumpWidget(MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: LumoAppTheme.light(),
            home: RepaintBoundary(key: boundary, child: child)));
        await tester.pump(const Duration(milliseconds: 500));
      }

      Future<void> capture(String name) async {
        await captureLumoBoundary(
            tester, boundary, '$out/$name-${size.key}.png',
            pixelRatio: 1.5);
        expect(tester.takeException(), isNull);
      }

      await show(
          Scaffold(body: HomeContent(appState: state, onSection: (_) {})));
      await capture('home');
      // Lumo 1992 deliberately keeps the nine premium subject cards behind
      // an optional entry. Capture the actual navigation path rather than
      // searching for a card that is intentionally not mounted initially.
      final chooser = find.text('Alle Fächer direkt öffnen');
      // ListView builds children lazily. On unfolded Fold the subject chooser
      // may not exist yet, so first scroll the actual home list forward until
      // it is mounted. Never ask scrollUntilVisible for a missing element.
      final homeScroll = find.byType(Scrollable).first;
      for (var step = 0; step < 48 && chooser.evaluate().isEmpty; step++) {
        await tester.drag(homeScroll, const Offset(0, -260));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(chooser, findsOneWidget,
          reason: 'Subject chooser must be reachable on all phone/Fold sizes');
      await tester.ensureVisible(chooser);
      await tester.pump(const Duration(milliseconds: 250));
      expect(chooser.hitTestable(), findsOneWidget);
      await tester.tap(chooser);
      await tester.pump(const Duration(milliseconds: 650));
      // ExpansionTile cards may be lazily mounted on unfolded Fold screens.
      // Scroll in bounded steps before asking Flutter for a target element:
      // scrollUntilVisible throws Bad state if the target is not mounted yet.
      final firstSubject = find.byKey(const ValueKey('home-island-mathe'));
      final listScroller = find.byType(Scrollable).first;
      for (var step = 0;
          step < 26 && firstSubject.evaluate().isEmpty;
          step++) {
        await tester.drag(listScroller, const Offset(0, -280));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(firstSubject, findsOneWidget,
          reason: 'Mathe must remain reachable in the expanded home list');
      await tester.ensureVisible(firstSubject);
      await tester.pump(const Duration(milliseconds: 350));
      await capture('subjects');
      await tester.pumpWidget(const SizedBox.shrink());
      final story = LumoStoryGenerator.instance.generateReadingAdventure(
          hero: 'Fuchs',
          location: 'Zauberwald',
          theme: 'Geheimnis',
          gradeLevel: 2);
      await show(LumoStoryReaderScreen(story: story, appState: state));
      await capture('reading');
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('lumo-story-continue')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }
      final wrong = find.text(story.pages[4].exercise!.options!
          .firstWhere((o) => o != story.pages[4].exercise!.correctAnswer));
      await tester.ensureVisible(wrong);
      await tester.pump();
      await tester.tap(wrong);
      await tester.pump();
      await tester.ensureVisible(find.text(
          'Noch nicht. Lies die Hinweise der vorherigen Seiten noch einmal und versuche es erneut.'));
      await capture('retry');
      await tester.pumpWidget(const SizedBox.shrink());
    }, skip: out == null);
  }
}
