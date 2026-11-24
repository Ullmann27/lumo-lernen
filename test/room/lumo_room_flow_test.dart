import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_room_repository.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/room/lumo_room.dart';
import 'package:lumo_lernen/features/room/lumo_room_screen.dart';
import '../rewards/reward_test_store.dart';

const _key = 'lumo_reward_wallet_v1';
const _owner = 'room-ui-child-a';
const _other = 'room-ui-child-b';
const _initial = RewardWallet(stars: 2000, xp: 500, totalEarnedStars: 3000);

Future<void> _frames(WidgetTester tester, [int count = 15]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<LumoAppState> _app(WidgetTester tester, {bool voice = false}) async {
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.school.setActiveStudent(_owner);
    await app.hydrateFromWallet();
    app.updateSettings(AppSettings(
        voiceEnabled: voice,
        autoReadEnabled: false,
        reduceAnimations: true,
        calmMode: true));
  });
  return app;
}

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
    theme: ThemeData(fontFamily: 'Nunito', useMaterial3: true),
    builder: (context, value) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: value!),
    home: Scaffold(body: child));

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 260,
        scrollable: find.byType(Scrollable).first, maxScrolls: 40);
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await _frames(tester, 4);
  await tester.tap(target);
  await _frames(tester, 20);
}

Future<void> _top(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, 9000));
  await _frames(tester, 15);
}

Future<void> _buy(WidgetTester tester, String id) async {
  await _tap(tester, 'room-buy-$id');
  final item = LumoRoomCatalog.byId(id);
  expect(find.textContaining('kostet ${item.cost} Sterne'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('room-price-confirm')));
  await _frames(tester, 25);
  expect(find.byKey(const ValueKey('room-error')), findsNothing);
}

Future<void> _capture(WidgetTester tester, String name) async {
  await _top(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('lumo-room-preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(
        Platform.environment['LUMO_ROOM_SCREENSHOT_DIR'] ??
            '/tmp/lumo-integration-20261122');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Nunito');
    for (final variant in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      fonts.addFont(rootBundle.load('assets/fonts/Nunito-$variant.ttf'));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
    SharedPreferences.setMockInitialValues(
        {_key: jsonEncode(_initial.toJson())});
  });
  tearDown(LumoRoomRepository.flushPendingWrites);

  testWidgets(
      'Actual Home entry buys, equips and renders all historical room items across restart and profile switches',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    var app = await _app(tester);
    try {
      await tester.pumpWidget(_host(LumoRoomCard(appState: app)));
      await tester.tap(find.byKey(const ValueKey('lumo-room-open')));
      await _frames(tester, 30);
      expect(
          find.byKey(const ValueKey('room-scarf-scarf_blue')), findsOneWidget);
      expect(find.byKey(const ValueKey('room-theme-starter')), findsOneWidget);
      await _capture(tester, 'lumo-room-starter');
      await _tap(tester, 'room-buy-plant');
      await tester.tap(find.text('Abbrechen'));
      await _frames(tester);
      expect((await RewardWalletRepository().load()).stars, 2000);
      expect(
          (await const LumoRoomRepository().load(_owner)).purchases, isEmpty);
      for (final id in [
        'plant',
        'rug',
        'pet',
        'star',
        'scarf_green',
        'scarf_rose',
        'room_space'
      ]) {
        await _buy(tester, id);
        await _tap(tester, 'room-equip-$id');
      }
      await _capture(tester, 'lumo-room-equipped');
      for (final id in ['plant', 'rug', 'pet', 'star']) {
        expect(find.byKey(ValueKey('room-equipped-$id')), findsOneWidget);
      }
      expect(
          find.byKey(const ValueKey('room-scarf-scarf_rose')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('room-scarf-scarf_green')), findsNothing);
      expect(find.byKey(const ValueKey('room-original-lumo')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('room-theme-room_space')), findsOneWidget);
      final paid = await RewardWalletRepository().load();
      expect(paid.stars, 780);
      expect(paid.shopRedemptions, hasLength(7));
      expect(paid.gameResultIds, isEmpty);
      expect(paid.totalEarnedStars, 3000);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      app = await _app(tester);
      await tester.pumpWidget(_host(LumoRoomScreen(appState: app)));
      await _frames(tester, 30);
      expect(
          find.byKey(const ValueKey('room-scarf-scarf_rose')), findsOneWidget);
      expect(find.byKey(const ValueKey('room-equipped-plant')), findsOneWidget);
      expect(app.state.stars, 780);
      await tester.runAsync(() => app.school.setActiveStudent(_other));
      await _frames(tester, 30);
      expect(
          find.byKey(const ValueKey('room-scarf-scarf_blue')), findsOneWidget);
      expect(find.byKey(const ValueKey('room-theme-starter')), findsOneWidget);
      expect(find.byKey(const ValueKey('room-equipped-plant')), findsNothing);
      expect(app.state.stars, 780,
          reason: 'Wallet stays shared; room inventory belongs to the child.');
      await tester.runAsync(() => app.school.setActiveStudent(_owner));
      await _frames(tester, 30);
      expect(
          find.byKey(const ValueKey('room-scarf-scarf_rose')), findsOneWidget);
      expect(find.byKey(const ValueKey('room-equipped-plant')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets(
      'Praise, snack confirmation and dance use the original amounts without repeat rewards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    final app = await _app(tester);
    try {
      await tester.pumpWidget(_host(LumoRoomScreen(appState: app)));
      await _frames(tester, 25);
      await _tap(tester, 'room-praise');
      expect(app.state.stars, 2005);
      expect(
          find.byKey(const ValueKey('room-praise-cooldown')), findsOneWidget);
      await _tap(tester, 'room-praise');
      expect(app.state.stars, 2005);
      await _tap(tester, 'room-feed');
      expect(find.text('Der Snack kostet 10 Sterne. Dafür bekommst du 20 XP.'),
          findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await _frames(tester);
      expect(app.state.stars, 2005);
      await _tap(tester, 'room-feed');
      await tester.tap(find.byKey(const ValueKey('room-price-confirm')));
      await _frames(tester, 25);
      expect(app.state.stars, 1995);
      expect(app.state.xp, 520);
      await _tap(tester, 'room-dance');
      expect(find.text('Tanzpause. Danach geht es frisch weiter.'),
          findsOneWidget);
      final balance = await RewardWalletRepository().load();
      expect(balance.stars, 1995);
      expect(balance.roomActions.map((v) => v.request.kind),
          [LumoRoomActionKind.pet, LumoRoomActionKind.feed]);
      expect(balance.earnedStarsByOwner, {_owner: 5});
      expect(balance.gameResultIds, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets(
      'Uncertain purchase survives cold restart and the same confirmed quote costs stars once',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    final store = RewardTestStore({_key: jsonEncode(_initial.toJson())});
    SharedPreferencesStorePlatform.instance = store;
    var app = await _app(tester);
    try {
      await tester.pumpWidget(_host(LumoRoomScreen(appState: app)));
      await _frames(tester, 25);
      store
        ..failingPrefix = 'flutter.$_key'
        ..reply = RewardWriteReply.falseAfterMemory
        ..failuresLeft = 1;
      await _tap(tester, 'room-buy-plant');
      await tester.tap(find.byKey(const ValueKey('room-price-confirm')));
      await _frames(tester, 25);
      final quote = (await const LumoRoomRepository().load(_owner))
          .purchases
          .single
          .receipt;
      expect(app.state.stars, 2000);
      await _top(tester);
      expect(find.byKey(const ValueKey('room-equipped-plant')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      SharedPreferences.setMockInitialValues(store.disk
          .map((k, v) => MapEntry(k.substring('flutter.'.length), v)));
      app = await _app(tester);
      await tester.pumpWidget(_host(LumoRoomScreen(appState: app)));
      await _frames(tester, 25);
      final retry = find.widgetWithText(FilledButton, 'Kauf erneut bestätigen');
      await Scrollable.ensureVisible(tester.element(retry), alignment: .5);
      await _frames(tester, 5);
      await tester.tap(retry);
      await _frames(tester, 15);
      await tester.tap(find.byKey(const ValueKey('room-price-confirm')));
      await _frames(tester, 25);
      final saved = await RewardWalletRepository().load();
      expect(saved.stars, 1920);
      expect(saved.shopRedemptions.single.toJson(), quote.toJson());
      await _tap(tester, 'room-equip-plant');
      await _top(tester);
      expect(find.byKey(const ValueKey('room-equipped-plant')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets(
      'Changing child during a price confirmation cannot buy for either child',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    final app = await _app(tester);
    try {
      await tester.pumpWidget(_host(LumoRoomScreen(appState: app)));
      await _frames(tester, 25);
      await _tap(tester, 'room-buy-plant');
      await tester.runAsync(() => app.school.setActiveStudent(_other));
      await _frames(tester, 20);
      await tester.tap(find.byKey(const ValueKey('room-price-confirm')));
      await _frames(tester, 20);
      final wallet = await RewardWalletRepository().load();
      expect(wallet.stars, 2000);
      expect(wallet.shopRedemptions, isEmpty);
      expect(
          (await const LumoRoomRepository().load(_owner)).purchases, isEmpty);
      expect(
          (await const LumoRoomRepository().load(_other)).purchases, isEmpty);
      expect(find.textContaining('Das Kinderprofil hat gewechselt'),
          findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets(
      '320-dp room with 1.6 text scaling has reachable price and equip controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    final app = await _app(tester);
    try {
      await tester.pumpWidget(_host(LumoRoomScreen(appState: app), scale: 1.6));
      await _frames(tester, 25);
      await _buy(tester, 'plant');
      expect(
          tester.getSize(find.byKey(const ValueKey('room-equip-plant'))).height,
          greaterThanOrEqualTo(48));
      await _tap(tester, 'room-equip-plant');
      await _top(tester);
      expect(find.byKey(const ValueKey('room-equipped-plant')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets(
      'Room cancels its pending speech on child switch and disposal without cancelling a newer speaker',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    final app = await _app(tester, voice: true);
    final voice = _RoomVoice();
    try {
      await tester
          .pumpWidget(_host(LumoRoomScreen(appState: app, voice: voice)));
      await _frames(tester, 25);
      await _tap(tester, 'room-dance');
      expect(voice.spoken, hasLength(1));
      await tester.runAsync(() => app.school.setActiveStudent(_other));
      await _frames(tester, 25);
      expect(voice.stops, 1);
      voice.finish();
      await _frames(tester);
      expect(voice.spoken, hasLength(1),
          reason:
              'Late synthesis completion cannot start the old room sentence again.');
      await _tap(tester, 'room-dance');
      expect(voice.spoken, hasLength(2));
      final newer = voice.speakAndWait('Die andere Seite spricht.');
      final stops = voice.stops;
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
      expect(voice.stops, stops);
      voice.finish();
      await newer;
      expect(tester.takeException(), isNull);
    } finally {
      voice.finish();
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      voice.status.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });
}

class _RoomVoice implements LumoVoice {
  @override
  final status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  @override
  final identity = LumoVoiceIdentity.freeOffline;
  @override
  int requestRevision = 0;
  int stops = 0;
  final spoken = <String>[];
  final pending = <Completer<void>>[];

  @override
  Future<void> speakAndWait(String text,
      {VoiceStyle style = VoiceStyle.warm, double speedFactor = 1}) async {
    requestRevision++;
    status.value = VoiceStatus.preparing;
    spoken.add(text);
    final done = Completer<void>();
    pending.add(done);
    await done.future;
  }

  @override
  Future<void> stop() async {
    requestRevision++;
    stops++;
    status.value = VoiceStatus.idle;
  }

  void finish() {
    for (final task in pending) {
      if (!task.isCompleted) task.complete();
    }
    status.value = VoiceStatus.idle;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
