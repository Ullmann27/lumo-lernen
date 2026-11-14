import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/home/widgets/lumo_subject_showcase_card.dart';
import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Premium learning cards: complete description, progress and tap',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(160, 198));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LumoSubjectShowcaseCard(
              subject: 'Mathematik',
              shortName: 'Mathe',
              subtitle: 'Zahlen, Rechnen und Formen',
              icon: Icons.calculate_rounded,
              accent: const Color(0xFFFFC04A),
              completed: 5,
              onTap: () => pressed++,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Mathe'), findsOneWidget);
      expect(find.text('Zahlen, Rechnen und Formen'), findsOneWidget);
      expect(find.text('5 Aufgaben geschafft'), findsOneWidget);
      expect(find.text('MEIN FORTSCHRITT'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, .5);
      await tester.tap(find.byKey(const ValueKey('home-island-mathe')));
      expect(pressed, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (device, size, textScale) in <(String, Size, double)>[
    ('phone', const Size(393, 852), 1.0),
    ('fold-cover', const Size(320, 740), 1.2),
    ('fold-open', const Size(840, 960), 1.0),
    ('large-text', const Size(900, 1200), 1.5),
  ]) {
    testWidgets('Real home premium islands $device', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      final sections = <LumoSection>[];
      addTearDown(state.dispose);
      const captureKey = ValueKey('home-1989-boundary');
      await tester.pumpWidget(
        MaterialApp(
          theme: LumoAppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: RepaintBoundary(
                key: captureKey,
                child: HomeContent(appState: state, onSection: sections.add),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      final testsCard = find.byKey(const ValueKey('home-secondary-tests'));
      final rewardsCard = find.byKey(const ValueKey('home-secondary-rewards'));
      for (final (card, title) in [
        (testsCard, 'Tests'),
        (rewardsCard, 'Belohnungen'),
      ]) {
        final cardRect = tester.getRect(card);
        expect(cardRect.width, greaterThanOrEqualTo(48));
        expect(cardRect.height, greaterThanOrEqualTo(48));
        final titleFinder = find.descendant(
          of: card,
          matching: find.text(title),
        );
        final paragraph = tester.renderObject<RenderParagraph>(titleFinder);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: title.length),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          boxes,
          hasLength(1),
          reason: '$device must keep the complete $title label on one line',
        );
        final textRect = boxes.single.toRect().shift(
          paragraph.localToGlobal(Offset.zero),
        );
        expect(textRect.left, greaterThanOrEqualTo(cardRect.left));
        expect(textRect.right, lessThanOrEqualTo(cardRect.right));
        expect(textRect.top, greaterThanOrEqualTo(cardRect.top));
        expect(textRect.bottom, lessThanOrEqualTo(cardRect.bottom));
      }
      if (device == 'fold-cover') {
        expect(find.byKey(const ValueKey('home-learn')), findsOneWidget);
        expect(find.byKey(const ValueKey('home-games')), findsOneWidget);
        expect(testsCard.hitTestable(), findsOneWidget);
        expect(rewardsCard.hitTestable(), findsOneWidget);
        await tester.tap(testsCard);
        await tester.pump();
        await tester.tap(rewardsCard);
        await tester.pump();
        expect(sections, [LumoSection.tests, LumoSection.rewards]);
        await tester.pump(const Duration(milliseconds: 500));
      }
      final out = Platform.environment['LUMO_1989_CARD_CAPTURES'];
      if (out != null) {
        await captureLumoBoundary(tester, captureKey, '$out/$device-start.png');
      }
      final homeList = find.byKey(
        const PageStorageKey<String>('lumo-home-scroll'),
      );
      final homeScroll = find
          .descendant(of: homeList, matching: find.byType(Scrollable))
          .first;
      final expansion = find.byKey(
        const PageStorageKey<String>('home-all-subjects'),
      );
      final subjects = find.descendant(
        of: expansion,
        matching: find.text('Alle Fächer direkt öffnen'),
      );
      await tester.scrollUntilVisible(
        subjects.hitTestable(),
        270,
        scrollable: homeScroll,
        maxScrolls: 140,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(subjects.hitTestable(), findsOneWidget);
      await tester.tap(subjects);
      await tester.pump(const Duration(milliseconds: 650));
      expect(
        find.descendant(of: expansion, matching: find.text('Deine Lernfächer')),
        findsOneWidget,
      );
      final first = find.byKey(const ValueKey('home-island-mathe'));
      await tester.scrollUntilVisible(
        first.hitTestable(),
        270,
        scrollable: homeScroll,
        maxScrolls: 140,
      );
      await Scrollable.ensureVisible(tester.element(first), alignment: .08);
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        first.hitTestable(),
        findsOneWidget,
        reason: '$device must display the real opened first subject card',
      );
      final firstRect = tester.getRect(first);
      final viewport = tester.getRect(find.byKey(captureKey));
      expect(firstRect.left, greaterThanOrEqualTo(viewport.left));
      expect(firstRect.right, lessThanOrEqualTo(viewport.right));
      expect(firstRect.top, greaterThanOrEqualTo(viewport.top));
      expect(firstRect.bottom, lessThanOrEqualTo(viewport.bottom));
      debugPrint(
        '[HomeCapture] device=$device '
        'scroll=${tester.state<ScrollableState>(homeScroll).position.pixels} '
        'firstSubject=$firstRect viewport=$viewport',
      );
      final deutsch = find.byKey(const ValueKey('home-island-deutsch'));
      expect(deutsch, findsOneWidget);
      if (size.width < 460) {
        final matheRect = tester.getRect(first);
        final deutschRect = tester.getRect(deutsch);
        expect(
          deutschRect.top,
          greaterThanOrEqualTo(matheRect.bottom),
          reason: 'Narrow phone needs full-width legible card rows',
        );
        expect(deutschRect.left, closeTo(matheRect.left, 1));
      }
      expect(
        tester.takeException(),
        isNull,
        reason: 'No small-cover/Fold overflow for $device',
      );
      if (out != null) {
        await captureLumoBoundary(
          tester,
          captureKey,
          '$out/$device-learning-cards.png',
        );
        expect(
          first.hitTestable(),
          findsOneWidget,
          reason: 'The subject card must remain visible through rasterization',
        );
        final capturedRect = tester.getRect(first);
        expect(capturedRect.left, closeTo(firstRect.left, .001));
        expect(capturedRect.top, closeTo(firstRect.top, .001));
        expect(capturedRect.right, closeTo(firstRect.right, .001));
        expect(capturedRect.bottom, closeTo(firstRect.bottom, .001));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
    });
  }
}
