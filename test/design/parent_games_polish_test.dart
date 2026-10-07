import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_shop_repository.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';
import 'package:lumo_lernen/features/settings/writing_report_card.dart';
import 'package:lumo_lernen/features/rewards/test_photo_entry_card.dart';
import 'package:lumo_lernen/features/learning/learning_dna_card.dart';
import 'package:lumo_lernen/domain/learning/learning_dna.dart';

const boundaryKey = ValueKey('polish-capture');
const bridge = MethodChannel('lumo_lernen/bridge');

Future<void> settleData(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['LUMO_POLISH_CAPTURES'];
  if (directory == null) return;
  // Wait for the actual asset decoders, not a guessed wall-clock delay.
  // Otherwise a screenshot can capture empty art even though the asset exists.
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    await Future.wait(images.map(
        (element) => precacheImage((element.widget as Image).image, element)));
  });
  await tester.pump();
  final render =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('No actual rendered PNG');
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

Future<LumoAppState> stateFor(WidgetTester tester,
    {Size size = const Size(360, 800)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState();
  app.update(app.state.copyWith(childName: 'Probe', grade: 2));
  app.updateSettings(const AppSettings(
    reduceAnimations: true,
    calmMode: true,
    voiceEnabled: false,
    soundEnabled: false,
    autoReadEnabled: false,
  ));
  await SettingsRepository.save(app.state.settings);
  addTearDown(app.dispose);
  return app;
}

Future<void> mount(WidgetTester tester, Widget child,
    {double textScale = 1}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData.light().copyWith(
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Nunito')),
    builder: (context, body) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: body!,
    ),
    home: Scaffold(body: RepaintBoundary(key: boundaryKey, child: child)),
  ));
  await settleData(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito');
    font.addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
    font.addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, null);
  });

  testWidgets(
      'parent area uses a local dark theme without changing outside theme or permissions',
      (tester) async {
    final app = await stateFor(tester);
    await mount(tester, SettingsContent(appState: app));
    await capture(tester, 'parent_phone_top');
    final inside = tester.element(find.text('Elternbereich'));
    expect(Theme.of(inside).brightness, Brightness.dark);
    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light);
    expect(app.state.settings.aiProxyEnabled, isFalse);
    expect(app.state.settings.scannerEnabled, isFalse);
    expect(app.state.settings.microphoneEnabled, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'reset confirmation inherits night style and cancel leaves profile and stars intact',
      (tester) async {
    final app = await stateFor(tester);
    final stars = app.state.stars;
    await mount(tester, SettingsContent(appState: app));
    final button = find.widgetWithText(OutlinedButton, 'Profil zuruecksetzen');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 400));
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(Theme.of(tester.element(dialog)).brightness, Brightness.dark);
    expect(
        Theme.of(tester.element(dialog))
            .dialogTheme
            .backgroundColor!
            .computeLuminance(),
        lessThan(.1));
    await tester.tap(find.text('Abbrechen'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.state.childName, 'Probe');
    expect(app.state.stars, stars);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'daily goal remains interactive and persists without enabling online access',
      (tester) async {
    final app = await stateFor(tester);
    await mount(tester, SettingsContent(appState: app));
    final goal = find.text('5 Aufgaben');
    await tester.ensureVisible(goal);
    await tester.pump();
    await tester.tap(goal);
    await settleData(tester);
    final settings = await SettingsRepository.load();
    expect(settings.dailyGoal, 5);
    expect(settings.aiProxyEnabled, isFalse);
    expect(settings.microphoneEnabled, isFalse);
    await capture(tester, 'parent_controls');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'test note feedback and persisted note refer to the submitted selection',
      (tester) async {
    final app = await stateFor(tester, size: const Size(400, 1100));
    await mount(tester,
        SingleChildScrollView(child: TestPhotoEntryCard(appState: app)));
    await tester.enterText(find.byType(TextField), 'Mathe');
    await tester.tap(find.text('2'));
    final save = find.text('Punkte hinzufügen');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settleData(tester);
    expect(find.text('25 Punkte für Note 2 in Mathe hinzugefügt!'),
        findsOneWidget);
    final saved = await const RewardShopRepository().load('local_probe_2');
    expect(saved.testPhotos, hasLength(1));
    expect(saved.testPhotos.single.note, 2);
    expect(saved.testPhotos.single.pointsAwarded, 25);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('parent report child surfaces are dark rather than pastel white',
      (tester) async {
    await stateFor(tester, size: const Size(400, 1100));
    const dna = LearningDna(
        childName: 'Probe', recentProgress: 'Noch keine Aufgaben bearbeitet.');
    await mount(
        tester,
        const SingleChildScrollView(
            child: Column(children: [
          WritingReportCard(),
          LearningDnaParentCard(dna: dna),
        ])));
    for (final type in [WritingReportCard, LearningDnaParentCard]) {
      final container = find
          .descendant(of: find.byType(type), matching: find.byType(Container))
          .first;
      final box =
          tester.widget<Container>(container).decoration! as BoxDecoration;
      final gradient = box.gradient! as LinearGradient;
      expect(gradient.colors.every((color) => color.computeLuminance() < .2),
          isTrue,
          reason:
              '$type must not repaint the night theme with pale backgrounds');
    }
    await capture(tester, 'parent_reports');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'both real game start controls appear before the decorative world',
      (tester) async {
    final app = await stateFor(tester);
    await mount(tester, GamesContent(appState: app));
    await capture(tester, 'games_phone');
    for (final name in ['launch-lumo-cards', 'launch-lumo-kart']) {
      final button = find.byKey(ValueKey(name));
      expect(button, findsOneWidget);
      final rect = tester.getRect(button);
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.bottom, lessThanOrEqualTo(800));
      expect(button.hitTestable(), findsOneWidget);
    }
    expect(find.text('Lumo Cards'), findsOneWidget);
    expect(find.text('Lumo Kart'), findsOneWidget);
    expect(find.textContaining('Keine Lernfragen'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'game entries resize without replacing state or clipping enlarged labels',
      (tester) async {
    final app = await stateFor(tester);
    await mount(tester, GamesContent(appState: app));
    final initial = tester.state(find.byType(GamesContent));
    for (final entry in <(String, Size, double)>[
      ('games_inner', const Size(840, 740), 1),
      ('games_tablet', const Size(1280, 800), 1),
      ('games_large_text', const Size(360, 800), 2),
      ('games_outer_return', const Size(360, 800), 1),
    ]) {
      await tester.binding.setSurfaceSize(entry.$2);
      await mount(tester, GamesContent(appState: app), textScale: entry.$3);
      expect(tester.state(find.byType(GamesContent)), same(initial));
      expect(tester.takeException(), isNull, reason: entry.$1);
      await capture(tester, entry.$1);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Cards rapid double activation opens one route and permits returning',
      (tester) async {
    final app = await stateFor(tester);
    final observer = _PushObserver();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [observer],
      theme: ThemeData.light().copyWith(
          textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Nunito')),
      home: Scaffold(body: GamesContent(appState: app)),
    ));
    await settleData(tester);
    final before = observer.count;
    final cardButton = find.byKey(const ValueKey('launch-lumo-cards'));
    expect(cardButton, findsOneWidget);
    final onPressed = tester.widget<FilledButton>(cardButton).onPressed!;
    onPressed();
    onPressed();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(observer.count - before, 1);
    expect(find.byType(LumoCardsScreen), findsOneWidget);
    final routeContext = tester.element(find.byType(LumoCardsScreen));
    Navigator.of(routeContext).pop();
    await tester.pump(const Duration(seconds: 3));
    await settleData(tester);
    expect(find.byType(LumoCardsScreen), findsNothing);
    expect(tester.widget<FilledButton>(cardButton).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Kart spotlight uses the existing native launcher and unlocks after return',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final app = await stateFor(tester);
      final returned = Completer<Map<String, Object?>>();
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, (call) {
        calls.add(call);
        return returned.future;
      });
      await mount(tester, GamesContent(appState: app));
      final start = find.byKey(const ValueKey('launch-lumo-kart'));
      final onPressed = tester.widget<FilledButton>(start).onPressed!;
      onPressed();
      onPressed();
      await settleData(tester);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'launch3D');
      expect((calls.single.arguments as Map)['scene'], 'kart');
      expect(tester.widget<FilledButton>(start).onPressed, isNull);
      returned.complete({'destination': 'games'});
      await settleData(tester);
      expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _PushObserver extends NavigatorObserver {
  int count = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    count++;
    super.didPush(route, previousRoute);
  }
}
