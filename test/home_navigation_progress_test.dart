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
          {double textScale = 1}) =>
      MaterialApp(
        theme: LumoAppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
              body: HomeContent(appState: state, onSection: onSection)),
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
          subject: 'Mathematik', unit: 'Plus bis 10', correct: true);
      await savedState.recordLearningAnswer(
          subject: 'Deutsch', unit: 'Silben', correct: true);
      await savedState.recordLearningAnswer(
          subject: 'Deutsch', unit: 'Silben', correct: false);
      savedState.addStars(17);
      savedState.addXp(425);
      await savedState.flushRewards();
      savedState.dispose();
      final restored = LumoAppState();
      await restored.hydrateFromWallet();
      await restored.loadLearningProfile();
      return restored;
    }))!;
    await tester.binding.setSurfaceSize(const Size(840, 1200));
    await tester.pumpWidget(home(state, (_) {}));
    await tester.pump();
    expect(find.text('17 Sterne'), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('25 / 400 XP bis Level 3'), findsOneWidget);
    expect(find.text('Heute: 2 von 3 Aufgaben'), findsOneWidget);
    expect(find.text('1 Lerntag in Folge'), findsOneWidget);
    expect(find.textContaining('1 Aufgabe geschafft'), findsNWidgets(2));
    await tester.runAsync(() async {
      state.addStars(3);
      state.addXp(10);
      await state.flushRewards();
    });
    await tester.pump();
    expect(find.text('20 Sterne'), findsOneWidget);
    expect(find.text('35 / 400 XP bis Level 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
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

  testWidgets('Kart discovery uses the same in-app game selection',
      (tester) async {
    final state = LumoAppState();
    state.update(state.state.copyWith(settings: const AppSettings()));
    final sections = <LumoSection>[];
    await tester.binding.setSurfaceSize(const Size(840, 1600));
    await tester.pumpWidget(home(state, sections.add));
    final discover = find.text('Mehr mit Lumo entdecken');
    await tester.ensureVisible(discover);
    await tester.tap(discover);
    await tester.pumpAndSettle();
    final kartEntry = find.byKey(const ValueKey('home-discover-kart'));
    await tester.ensureVisible(kartEntry);
    await tester.tap(kartEntry);
    expect(sections, [LumoSection.games]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.binding.setSurfaceSize(null);
  });
}
