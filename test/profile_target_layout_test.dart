import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/kart_fleet_catalog.dart';
import 'package:lumo_lernen/domain/rewards/reward_shop.dart';
import 'package:lumo_lernen/features/report/lernbericht_screen.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_premium_effects.dart';
import 'package:lumo_lernen/widgets/profile_screen.dart';

import 'helpers/lumo_capture.dart';

/// Profil nach Heinz' Zielbild vom 17.11.2026: echte gespeicherte Werte,
/// kein Überlauf auf Handy, Fold und im Querformat, große Tippflächen.
const _student = 'local-profil-layout';

const _tappable = [
  ValueKey('profile-edit'),
  ValueKey('profile-rewards-all'),
  ValueKey('profile-extras'),
  ValueKey('profile-settings'),
  ValueKey('profile-report'),
];

String _day(int daysAgo) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day - daysAgo);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

SkillRecord _skill(String subject, String unit, int correct) => SkillRecord(
      skillId: '${subject.toLowerCase()}::${unit.toLowerCase()}',
      subject: subject,
      unit: unit,
      correct: correct,
    );

/// Gespeicherter Spielstand: 37 Sterne (47 gesammelt, 10 eingelöst), 520 XP,
/// zwei Spielergebnisse, fünf Lerntage in Folge, 7 richtige Aufgaben (davon
/// 3 in Logik) und eine eingelöste Belohnung.
Future<void> _seed({bool reduceAnimations = true}) async {
  SharedPreferences.setMockInitialValues({
    'lumo_app_settings_v1': jsonEncode(AppSettings(
      soundEnabled: false,
      voiceEnabled: false,
      autoReadEnabled: false,
      reduceAnimations: reduceAnimations,
    ).toJson()),
    LegacyLearningDataRepository.localIdKey: _student,
    LearningDataNamespace.keyFor('lumo_progress_daily', _student): jsonEncode({
      for (var i = 0; i < 5; i++) _day(i): 1 + i,
    }),
    LearningDataNamespace.keyFor('lumo_progress_skills', _student): jsonEncode({
      for (final skill in [
        _skill('Mathematik', 'Plus bis 10', 4),
        _skill('Logik', 'Muster', 3),
      ])
        skill.skillId: skill.toJson(),
    }),
    'lumo.reward_shop.local_mia_2': jsonEncode(RewardShopState(
      redeemed: [
        RedeemedReward(
          itemId: 'sticker_aussuchen',
          title: 'Sticker aussuchen',
          redeemedAt: DateTime(2026, 11, 14),
          cost: 10,
          currency: RewardCurrency.stars,
        ),
      ],
    ).toJson()),
  });
  final wallet = RewardWalletRepository.instance;
  await wallet.reset();
  await wallet.applyRewardDelta(starsDelta: 41, xpDelta: 480);
  await wallet.awardGameResult(resultId: 'layout-1', stars: 3, xp: 20);
  await wallet.awardGameResult(resultId: 'layout-2', stars: 3, xp: 20);
  await wallet.applyRewardDelta(starsDelta: -10);
}

Future<LumoAppState> _pumpProfile(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  List<LumoSection>? sections,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // Im echten Zeitfluss anlegen und laden: Die Speicher-Futures des
  // App-Zustands dürfen nicht an der angehaltenen Testuhr hängen.
  final app = (await tester.runAsync(() async {
    final app = LumoAppState();
    await app.ensureSettingsLoaded();
    await app.loadLearningProfile();
    await app.hydrateFromWallet();
    return app;
  }).timeout(const Duration(seconds: 20)))!;
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: AnimatedBuilder(
        animation: app,
        builder: (context, _) => ProfileScreen(
          appState: app,
          onSection: (section) => sections?.add(section),
          childName: 'Mia',
          grade: 2,
          stars: app.state.stars,
          xp: app.state.xp,
          level: app.state.level,
          showWordmark: size.width < 720,
        ),
      ),
    ),
  ));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return app;
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 400));
  app.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(_seed);

  testWidgets('zeigt Level, XP, Sterne, Serie und Abzeichen aus dem Spielstand',
      (tester) async {
    final app = await _pumpProfile(tester, size: const Size(390, 1500));

    // Wallet: 520 XP → Level 2 (1 + 520 ÷ 400), 120 XP im Level, 37 Sterne.
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('Entdecker:in'), findsOneWidget);
    expect(find.text('Klasse 2'), findsOneWidget);
    expect(find.text('120 / 400 XP'), findsNWidgets(2));
    expect(find.text('37'), findsOneWidget);
    expect(find.text('Level 3 erreichen'), findsOneWidget);

    // Lernprofil: fünf Lerntage in Folge.
    expect(find.text('5 Tage'), findsOneWidget);
    expect(find.text('Stark dran geblieben!'), findsOneWidget);
    expect(find.bySemanticsLabel('Lerntage der letzten Woche: 5 von 7'),
        findsWidgets);

    // Abzeichen mit ihrem gespeicherten Zähler und der nächsten Stufe.
    for (final label in [
      'Lernprofi: 7 von 10',
      'Spieler:in: 2 von 5',
      'Tüftler:in: 3 von 5',
      // Gesammelte Sterne, nicht der Kontostand nach dem Einlösen.
      'Sternensammler: 47 von 50',
      'Held:in: 5 von 7',
    ]) {
      expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
    }
    for (final text in ['7/10', '2/5', '3/5', '47/50', '5/7']) {
      expect(find.text(text), findsOneWidget);
    }

    // Regal: die im Laden eingelöste Belohnung mit Datum.
    expect(find.text('Sticker aussuchen'), findsOneWidget);
    expect(find.text('(14.11.)'), findsOneWidget);
    expect(find.textContaining('Noch nichts eingelöst'), findsNothing);

    // Regal: mit 47 verdienten Sternen sind die Karts bis „Blitz“ (32 ★) frei.
    // Die drei zuletzt verdienten stehen im Regal, „Terra“ (48 ★) ist das Ziel.
    for (final id in ['blitz', 'zuri_volt', 'turbo']) {
      expect(find.byKey(ValueKey('profile-kart-$id')), findsOneWidget,
          reason: id);
    }
    expect(find.text('Blitz'), findsOneWidget);
    expect(find.text('Zuri Volt'), findsOneWidget);
    expect(find.text('Aurora GT'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-kart-terra')), findsOneWidget);
    expect(find.text('Terra'), findsOneWidget);
    expect(find.text('Noch 1'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Nächstes Kart Terra, noch 1 Stern'), findsWidgets);
    // Ein Kart, das mehr Sterne braucht, wird nicht als Besitz gezeigt.
    expect(find.byKey(const ValueKey('profile-kart-stella')), findsNothing);

    // Nichts aus dem Zielbild, das es in der App nicht gibt.
    expect(find.textContaining('Avatar'), findsNothing);
    expect(find.textContaining('Outfits'), findsNothing);
    expect(find.textContaining('300 XP'), findsNothing);
    expect(tester.takeException(), isNull);
    await _close(tester, app);
  });

  test('Kart-Flotte: Freischaltung folgt den verdienten Sternen', () {
    expect(KartFleetCatalog.unlocked(0).map((k) => k.id),
        ['gecko_velo', 'comet']);
    expect(KartFleetCatalog.next(0)!.id, 'boru_rally');
    expect(KartFleetCatalog.next(0)!.unlockStars, 4);
    expect(KartFleetCatalog.unlocked(47).first.id, 'blitz');
    expect(KartFleetCatalog.unlocked(47).length, 10);
    expect(KartFleetCatalog.next(47)!.id, 'terra');
    expect(KartFleetCatalog.all.length, 24);
    expect(KartFleetCatalog.unlocked(120).length, 14);
    expect(KartFleetCatalog.next(120)!.id, 'kupferpfeil');
    expect(KartFleetCatalog.unlocked(159).length, 23);
    expect(KartFleetCatalog.next(159)!.id, 'werkmeister');
    expect(KartFleetCatalog.unlocked(160).length, 24);
    expect(KartFleetCatalog.next(160), isNull);
    // Schwellen steigen nie ab; jede Kennung ist eindeutig.
    final stars = KartFleetCatalog.all.map((k) => k.unlockStars).toList();
    expect(stars, [...stars]..sort());
    expect(KartFleetCatalog.all.map((k) => k.id).toSet().length,
        KartFleetCatalog.all.length);
  });

  testWidgets('neu verdiente Sterne und Spiele erscheinen ohne Neuaufbau',
      (tester) async {
    final app = await _pumpProfile(tester, size: const Size(390, 1500));
    expect(find.text('2/5'), findsOneWidget);
    await tester.runAsync(() async {
      await RewardWalletRepository.instance
          .awardGameResult(resultId: 'layout-3', stars: 3, xp: 20);
      await app.hydrateFromWallet();
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('3/5'), findsNWidgets(2),
        reason: 'Spieler:in, Tüftler:in');
    expect(find.text('40'), findsOneWidget);
    expect(find.text('140 / 400 XP'), findsNWidgets(2));
    expect(find.text('50/100'), findsOneWidget, reason: 'Sternensammler');
    expect(tester.takeException(), isNull);
    await _close(tester, app);
  });

  for (final (name, size, scale) in [
    ('Fold zu 320×640', const Size(320, 640), 1.0),
    ('Fold zu 320×640, Schrift 1,3', const Size(320, 640), 1.3),
    ('Handy 390×844', const Size(390, 844), 1.0),
    ('Handy 390×844, Schrift 1,3', const Size(390, 844), 1.3),
    ('Fold offen 840×760', const Size(840, 760), 1.0),
    ('Fold offen 840×760, Schrift 1,3', const Size(840, 760), 1.3),
    ('Querformat 844×390', const Size(844, 390), 1.0),
    ('Querformat 844×390, Schrift 1,3', const Size(844, 390), 1.3),
  ]) {
    testWidgets('kein Überlauf, Tippflächen ab 48 dp: $name', (tester) async {
      final sections = <LumoSection>[];
      final app = await _pumpProfile(tester,
          size: size, textScale: scale, sections: sections);
      expect(tester.takeException(), isNull, reason: 'erster Bildschirm');
      final list = find.byType(Scrollable).first;
      for (final key in _tappable) {
        final target = find.byKey(key);
        await tester.scrollUntilVisible(target, 120, scrollable: list);
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull, reason: 'bis $key');
        final box = tester.getSize(target);
        expect(box.width, greaterThanOrEqualTo(48), reason: '$key Breite');
        expect(box.height, greaterThanOrEqualTo(48), reason: '$key Höhe');
        final view = tester.getRect(find.byType(ProfileScreen));
        final rect = tester.getRect(target);
        expect(rect.left, greaterThanOrEqualTo(view.left), reason: '$key');
        expect(rect.right, lessThanOrEqualTo(view.right), reason: '$key');
      }
      // Jede Schaltfläche im Profil, nicht nur die bekannten Schlüssel.
      final inkWells = find.descendant(
          of: find.byType(ProfileScreen), matching: find.byType(InkWell));
      for (final element in inkWells.evaluate()) {
        final box = element.size!;
        expect(box.width, greaterThanOrEqualTo(48));
        expect(box.height, greaterThanOrEqualTo(48));
      }
      // Bis ganz nach unten und wieder hoch: nirgends ein Überlauf.
      await tester.drag(list, const Offset(0, -3000));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'Listenende');
      await tester.drag(list, const Offset(0, 6000));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'Listenanfang');
      expect(find.text('Level 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('profile-edit')));
      expect(sections, [LumoSection.settings]);
      await _close(tester, app);
    });
  }

  testWidgets('alle Wege des Profils führen zu echten Bereichen',
      (tester) async {
    final sections = <LumoSection>[];
    final app = await _pumpProfile(tester,
        size: const Size(390, 1500), sections: sections);
    for (final key in _tappable.take(4)) {
      await tester.tap(find.byKey(key));
      await tester.pump();
    }
    expect(sections, [
      LumoSection.settings,
      LumoSection.rewards,
      LumoSection.rewards,
      LumoSection.settings,
    ]);

    await tester.tap(find.byKey(const ValueKey('profile-report')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LernberichtScreen), findsOneWidget);
    expect(find.text('Mein Lernbericht'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _close(tester, app);
  });

  testWidgets('„Animationen reduzieren“ hält das Profil ruhig', (tester) async {
    final app = await _pumpProfile(tester, size: const Size(390, 844));
    expect(app.state.settings.reduceAnimations, isTrue);
    expect(find.byType(LumoGlowPulse), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'keine laufende Animation');
    expect(tester.takeException(), isNull);
    await _close(tester, app);
  });

  testWidgets(
      'ohne Reduzierung lebt das Profil: Leisten und Avatar bewegen sich',
      (tester) async {
    await tester.runAsync(() => _seed(reduceAnimations: false));
    final app = await _pumpProfile(tester, size: const Size(390, 844));
    expect(app.state.settings.reduceAnimations, isFalse);
    expect(find.byType(LumoGlowPulse), findsOneWidget);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await _close(tester, app);
  });
}
