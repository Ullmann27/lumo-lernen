import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/home/home_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final file = File('$fonts/${entry.value}');
      if (file.existsSync()) {
        final loader = FontLoader(entry.key);
        loader.addFont(
            Future.value(ByteData.sublistView(await file.readAsBytes())));
        await loader.load();
      }
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RewardWalletRepository.instance.reset();
  });

  Widget home(LumoAppState state, ValueChanged<LumoSection> onSection,
          {double textScale = 1, ValueChanged<String>? onBrowseSubject}) =>
      MaterialApp(
        theme: LumoAppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
              body: HomeContent(
                  appState: state,
                  onSection: onSection,
                  onBrowseSubject: onBrowseSubject)),
        ),
      );

  testWidgets('Lernen and Spielen stay visible and usable across Fold resize',
      (tester) async {
    final state = LumoAppState();
    final sections = <LumoSection>[];
    final learn = find.byKey(const ValueKey('home-learn'));
    final games = find.byKey(const ValueKey('home-games'));
    for (final size in [
      const Size(360, 740),
      const Size(840, 560),
      const Size(280, 640),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
          home(state, sections.add, textScale: size.width == 280 ? 1.4 : 1));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$size');
      for (final action in [learn, games]) {
        expect(action, findsOneWidget, reason: '$size');
        final rect = tester.getRect(action);
        expect(rect.left, isNonNegative);
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThan(size.height));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      if (size.width > 540) {
        expect(tester.getTopLeft(learn).dy, tester.getTopLeft(games).dy);
      }
      await tester.tap(learn);
      await tester.tap(games);
      expect(sections.sublist(sections.length - 2),
          [LumoSection.learn, LumoSection.games]);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('home uses persisted daily learning and live wallet values',
      (tester) async {
    final state = (await tester.runAsync(() async {
      final savedState = LumoAppState();
      await savedState.recordLearningAnswer(
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          correct: true,
          taskId: 'home-progress-math-1');
      await savedState.recordLearningAnswer(
          subject: 'Deutsch',
          unit: 'Silben',
          correct: true,
          taskId: 'home-progress-german-1');
      await savedState.recordLearningAnswer(
          subject: 'Deutsch',
          unit: 'Silben',
          correct: false,
          taskId: 'home-progress-german-wrong');
      savedState.addStars(17);
      savedState.addXp(425);
      await savedState.flushRewards();
      savedState.dispose();
      final restored = LumoAppState();
      await restored.hydrateFromWallet();
      await restored.loadLearningProfile();
      await restored.loadDailyMission();
      return restored;
    }))!;
    await tester.binding.setSurfaceSize(const Size(840, 1200));
    await tester.pumpWidget(home(state, (_) {}));
    await tester.pump();
    final missionProgress = find.byKey(const ValueKey('home-mission-progress'));
    await tester.scrollUntilVisible(missionProgress, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(state.dailyMission!.stations, hasLength(3));
    expect(state.dailyMission!.targetCount, 12);
    expect(state.dailyMission!.completedCount, 2);
    expect(find.text('2 von 12 · Dein Fortschritt wird gespeichert.'),
        findsOneWidget);
    for (final station in state.dailyMission!.stations) {
      final tile = find.byKey(ValueKey('mission-station-${station.subject}'));
      expect(tile, findsOneWidget);
      expect(station.target, 4);
      expect(station.completed,
          ['Mathematik', 'Deutsch'].contains(station.subject) ? 1 : 0);
      expect(
          find.descendant(
              of: tile,
              matching:
                  find.text('${station.completed} von 4 Aufgaben gelöst')),
          findsOneWidget);
      expect(
          find.descendant(
              of: tile, matching: find.byIcon(Icons.diamond_outlined)),
          findsOneWidget);
    }
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-daily-progress')), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(find.text('17 Sterne'), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('25 / 400 XP bis Level 3'), findsOneWidget);
    expect(find.text('Heute: 2 von 3 Aufgaben'), findsOneWidget);
    expect(find.text('1 Lerntag in Folge'), findsOneWidget);
    // The duplicate subject-progress cards are intentionally folded away.
    // Real wallet values above remain visible in the compact home overview.
    expect(find.textContaining('1 Aufgabe geschafft'), findsNothing);
    expect(find.byKey(const ValueKey('home-daily-task-0')), findsNothing,
        reason:
            'Generic task rows must not replace persisted mission stations.');
    await tester.runAsync(() async {
      state.addStars(3);
      state.addXp(10);
      await state.flushRewards();
    });
    await tester.pump();
    expect(find.text('20 Sterne'), findsOneWidget);
    expect(find.text('35 / 400 XP bis Level 3'), findsOneWidget);
    expect(state.dailyMission!.completedCount, 2,
        reason: 'Wallet rewards are not assessed mission answers.');
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('home uses the supplied 3D icons and Kart artwork',
      (tester) async {
    final state = LumoAppState();
    addTearDown(state.dispose);
    state.update(state.state.copyWith(childName: 'Mia'));
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(home(state, (_) {}));
    await tester.pump();

    for (final title in ['lernen', 'spielen']) {
      expect(
        find.byKey(ValueKey('lumo-color-tile-icon-$title')),
        findsOneWidget,
      );
    }
    expect(find.text('Hallo, Mia!'), findsOneWidget);
    expect(
        find.textContaining('Bereit für ein neues Abenteuer?',
            findRichText: true),
        findsOneWidget);
    // Kart's secondary promotional banner is intentionally below the
    // priority learning routes. ListView lazily builds its offscreen children:
    // scroll there before checking the real original illustration.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-kart-banner')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('home-kart-image')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('a saved weak topic opens the matching practice', (tester) async {
    final state = (await tester.runAsync(() async {
      final savedState = LumoAppState();
      for (var i = 0; i < 4; i++) {
        await savedState.recordLearningAnswer(
            subject: 'Deutsch', unit: 'Silben', correct: false);
      }
      savedState.dispose();
      final restored = LumoAppState();
      restored.update(restored.state.copyWith(grade: 4));
      await restored.loadLearningProfile();
      return restored;
    }))!;
    final recommendation = state.topLearningRecommendation()!;
    final sections = <LumoSection>[];
    await tester.binding.setSurfaceSize(const Size(840, 1200));
    await tester.pumpWidget(home(state, sections.add));
    await tester.pump();
    await tester.tap(find.text(recommendation.cta));
    expect(state.state.subject, 'Deutsch');
    expect(state.state.unit, 'Silben');
    expect(state.state.grade, 4);
    expect(sections, [LumoSection.exercises]);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('home subject cards browse topics and delegate to the shell',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(840, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final delegateToShell in [false, true]) {
      final state = LumoAppState();
      final sections = <LumoSection>[];
      final subjects = <String>[];
      await tester.runAsync(state.loadDailyMission);
      await tester.pumpWidget(home(state, sections.add,
          onBrowseSubject: delegateToShell ? subjects.add : null));
      final allSubjects =
          find.byKey(const PageStorageKey<String>('home-all-subjects'));
      await tester.scrollUntilVisible(allSubjects, 180,
          scrollable: find.byType(Scrollable).first);
      await Scrollable.ensureVisible(tester.element(allSubjects),
          alignment: .5);
      await tester.tap(allSubjects);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (final entry in [
        (subject: 'Mathematik', island: 'mathe'),
        (subject: 'Deutsch', island: 'deutsch'),
        (subject: 'Englisch', island: 'englisch'),
        (subject: 'Sachunterricht', island: 'sachkunde'),
      ]) {
        final card = find.byKey(ValueKey('home-island-${entry.island}'));
        await Scrollable.ensureVisible(tester.element(card), alignment: .5);
        await tester.pump();
        expect(card.hitTestable(), findsOneWidget);
        await tester.tap(card);
        if (delegateToShell) {
          expect(subjects.last, entry.subject);
          expect(sections, isEmpty);
        } else {
          expect(state.state.subject, entry.subject);
          expect(sections.last, LumoSection.learn);
        }
        expect(state.state.unit, 'Alle',
            reason: 'A subject choice must not silently resume an exercise.');
      }
      expect(sections, isNot(contains(LumoSection.exercises)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    }
  });

  testWidgets('Kart discovery uses the same in-app game selection',
      (tester) async {
    final state = LumoAppState();
    state.update(state.state.copyWith(settings: const AppSettings()));
    await tester.runAsync(state.loadDailyMission);
    final sections = <LumoSection>[];
    await tester.binding.setSurfaceSize(const Size(840, 1600));
    await tester.pumpWidget(home(state, sections.add));
    final discover = find.text('Mehr mit Lumo entdecken');
    // Nine learning islands now precede discovery. The outer scroll view
    // lazily builds offscreen content; ensureVisible cannot find a widget
    // that has not been built yet. Scroll until it really exists instead.
    await tester.scrollUntilVisible(
      discover,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(discover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final kartEntry = find.byKey(const ValueKey('home-discover-kart'));
    // The expanded discovery list exceeds the viewport. Scroll the actual
    // target into the center before tapping: tapping a tile outside the
    // screen would silently miss and obscure a genuine navigation regression.
    // Immediate ensureVisible must not await a 250ms animation inside
    // testWidgets without a concurrent frame pump: that leaves the Future
    // pending and the test eventually times out after ten minutes.
    await Scrollable.ensureVisible(
      tester.element(kartEntry),
      alignment: 0.5,
    );
    await tester.pump();
    expect(tester.getCenter(kartEntry).dy, inInclusiveRange(0, 1599));
    await tester.tap(kartEntry);
    expect(sections, [LumoSection.games]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.binding.setSurfaceSize(null);
  });
}
