import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_shop_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/rewards/reward_shop.dart';
import 'package:lumo_lernen/features/rewards/custom_rewards_card.dart';
import 'package:lumo_lernen/features/rewards/reward_shop_content.dart';
import 'package:lumo_lernen/widgets/parent_approval_dialog.dart';
import 'package:lumo_lernen/widgets/profile_screen.dart';
import 'reward_test_store.dart';

const _walletKey = 'lumo_reward_wallet_v1';
const _owner = 'parent-voucher-child-a';
const _initialWallet = RewardWallet(
    stars: 200,
    xp: 800,
    level: 3,
    totalEarnedStars: 500,
    gameResultIds: ['race-1', 'parent:old-task-reward', 'recognized:old-task']);
const _seed = CustomRewardDefinition(
    id: 'custom_33333333333333333333333333333333',
    revision: 1,
    title: 'Picknick mit Oma',
    emoji: '🧺',
    cost: 80,
    category: CustomRewardCategory.leisure,
    minLevel: 2);

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<LumoAppState> _app(WidgetTester tester) async {
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.school.setActiveStudent(_owner);
    await app.hydrateFromWallet();
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        reduceAnimations: true,
        calmMode: true));
  });
  return app;
}

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
      builder: (context, value) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: value!),
      home: Scaffold(body: child),
    );

Future<void> _field(WidgetTester tester, String key, String value) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await _frames(tester, 3);
  await tester.enterText(field, value);
}

Future<void> _newEditor(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(_host(CustomRewardsCard(appState: app)));
  await tester.tap(find.byKey(const ValueKey('custom-rewards-open')));
  await _frames(tester);
  await tester.tap(find.byKey(const ValueKey('custom-reward-add')));
  await _frames(tester);
}

Future<void> _fill(WidgetTester tester) async {
  await _field(tester, 'custom-reward-title', 'Picknick mit Oma');
  await _field(tester, 'custom-reward-emoji', '🧺');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final category = find.byKey(const ValueKey('custom-reward-category-family'));
  await Scrollable.ensureVisible(tester.element(category), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(category);
  await _frames(tester, 15);
  await tester.tap(find.text('Freizeit').last);
  await _frames(tester, 15);
  await _field(tester, 'custom-reward-cost', '80');
  await _field(tester, 'custom-reward-level', '2');
  await _field(
      tester, 'custom-reward-description', 'Am Sonntag gemeinsam aussuchen.');
}

Finder _redeemButton(String id) => find.descendant(
    of: find.byKey(ValueKey('reward-card-$id')),
    matching: find.widgetWithText(FilledButton, 'Einlösen'));

Future<void> _doubleTap(WidgetTester tester, Finder button) async {
  final position = tester.getCenter(button);
  await tester.tapAt(position);
  await tester.tapAt(position);
}

void main() {
  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
    SharedPreferences.setMockInitialValues({
      _walletKey: jsonEncode(_initialWallet.toJson()),
    });
  });
  tearDown(RewardShopRepository.flushPendingWrites);

  testWidgets(
      'Parent UI creates a voucher; restart, cancel, redeem, edit and archive retain the original history',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    var app = await _app(tester);
    try {
      await _newEditor(tester, app);
      await _fill(tester);
      // Real consecutive pointer taps use the same position, even after the
      // first tap has inserted a route barrier or disabled the control.
      await _doubleTap(
          tester, find.byKey(const ValueKey('custom-reward-save')));
      await _frames(tester, 35);
      expect(find.byKey(const ValueKey('custom-reward-editor-error')),
          findsNothing);
      final created = (await const RewardShopRepository().loadProfile(_owner))
          .currentDefinitions
          .single;
      expect((created.title, created.cost, created.minLevel, created.category),
          ('Picknick mit Oma', 80, 2, CustomRewardCategory.leisure));
      expect(created.description, 'Am Sonntag gemeinsam aussuchen.');
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();

      app = await _app(tester);
      await tester.pumpWidget(_host(RewardShopContent(appState: app)));
      await _frames(tester, 35);
      expect(find.text('Picknick mit Oma'), findsOneWidget);
      expect(find.text('Sticker aussuchen'), findsOneWidget);
      await tester.ensureVisible(_redeemButton(created.id));
      await _frames(tester, 3);
      await tester.tap(_redeemButton(created.id));
      await _frames(tester);
      expect(find.byType(ParentApprovalDialog), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await _frames(tester);
      expect((await RewardWalletRepository().load()).stars, 200);
      expect((await RewardWalletRepository().load()).shopRedemptions, isEmpty);

      await _doubleTap(tester, _redeemButton(created.id));
      await _frames(tester);
      expect(find.byType(ParentApprovalDialog), findsOneWidget);
      await tester.tap(find.text('Als Erwachsene:r bestätigen'));
      await _frames(tester, 35);
      final paid = await RewardWalletRepository().load();
      expect(paid.stars, 120);
      expect(paid.shopRedemptions, hasLength(1));
      final receipt = paid.shopRedemptions.single;
      expect(receipt.title, 'Picknick mit Oma');
      expect(receipt.cost, 80);
      expect(
          (await const RewardShopRepository().loadProfile(_owner))
              .pendingRedemptions,
          isEmpty);
      expect(find.byKey(ValueKey('reward-history-${receipt.transactionId}')),
          findsOneWidget);

      await tester.pumpWidget(_host(CustomRewardsScreen(appState: app)));
      await _frames(tester);
      await tester
          .tap(find.byKey(ValueKey('custom-reward-edit-${created.id}')));
      await _frames(tester);
      await _field(tester, 'custom-reward-title', 'Picknick mit Familie');
      await _field(tester, 'custom-reward-cost', '110');
      await tester.tap(find.byKey(const ValueKey('custom-reward-save')));
      await _frames(tester, 30);
      await tester
          .tap(find.byKey(ValueKey('custom-reward-toggle-${created.id}')));
      await _frames(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Deaktivieren'));
      await _frames(tester, 30);
      final archived = await const RewardShopRepository().loadProfile(_owner);
      expect(archived.revisions, hasLength(3));
      expect(archived.currentDefinitions.single.active, isFalse);
      expect(
          (await RewardWalletRepository().load())
              .shopRedemptions
              .single
              .toJson(),
          receipt.toJson());

      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      app = await _app(tester);
      await tester.pumpWidget(_host(RewardShopContent(appState: app)));
      await _frames(tester, 30);
      expect(find.byKey(ValueKey('reward-card-${created.id}')), findsNothing);
      expect(find.byKey(ValueKey('reward-history-${receipt.transactionId}')),
          findsOneWidget);
      expect(app.state.stars, 120);
      await tester.pumpWidget(_host(ProfileScreen(
          appState: app,
          onSection: (_) {},
          childName: 'Lena',
          grade: 1,
          stars: app.state.stars,
          xp: app.state.xp,
          level: app.state.level)));
      await _frames(tester, 30);
      expect(find.text('Picknick mit Oma'), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Semantics &&
              widget.properties.label == 'Spieler:in: 1 von 5'),
          findsOneWidget,
          reason:
              'Eltern-, erkannte Aufgaben und Gutscheinbelege sind keine gespielten Spiele.');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets(
      'Own voucher remains locked until its actual wallet level is reached',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {_walletKey: jsonEncode(const RewardWallet(stars: 200).toJson())});
    await const RewardShopRepository().saveDefinition(
        ownerId: _owner, definition: _seed, validateOwner: () {});
    final app = await _app(tester);
    await tester.pumpWidget(_host(RewardShopContent(appState: app)));
    await _frames(tester);
    expect(find.text('Ab Level 2'), findsOneWidget);
    expect(_redeemButton(_seed.id), findsNothing);
    await tester.runAsync(() async {
      app.addXp(400);
      await app.flushRewards();
    });
    await _frames(tester);
    expect(_redeemButton(_seed.id), findsOneWidget);
    expect((await RewardWalletRepository().load()).shopRedemptions, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('A profile switch while the editor is open disables the old save',
      (tester) async {
    final app = await _app(tester);
    await _newEditor(tester, app);
    await _fill(tester);
    await tester
        .runAsync(() => app.school.setActiveStudent('parent-voucher-child-b'));
    await _frames(tester);
    final button = tester
        .widget<FilledButton>(find.byKey(const ValueKey('custom-reward-save')));
    expect(button.onPressed, isNull);
    expect(find.textContaining('Das Kinderprofil hat gewechselt.'),
        findsOneWidget);
    expect(
        (await const RewardShopRepository().loadProfile(_owner))
            .currentDefinitions,
        isEmpty);
    expect(
        (await const RewardShopRepository()
                .loadProfile('parent-voucher-child-b'))
            .currentDefinitions,
        isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets(
      'A profile switch during adult approval cannot debit either child',
      (tester) async {
    await const RewardShopRepository().saveDefinition(
        ownerId: _owner, definition: _seed, validateOwner: () {});
    final app = await _app(tester);
    await tester.pumpWidget(_host(RewardShopContent(appState: app)));
    await _frames(tester);
    await tester.ensureVisible(_redeemButton(_seed.id));
    await _frames(tester, 3);
    await tester.tap(_redeemButton(_seed.id));
    await _frames(tester);
    await tester
        .runAsync(() => app.school.setActiveStudent('parent-voucher-child-b'));
    await _frames(tester);
    await tester.tap(find.text('Als Erwachsene:r bestätigen'));
    await _frames(tester);
    final saved = await RewardWalletRepository().load();
    expect(saved.stars, 200);
    expect(saved.shopRedemptions, isEmpty);
    expect(
        (await const RewardShopRepository().loadProfile(_owner))
            .pendingRedemptions,
        isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets(
      'A failed parent save remains visible and retries the same definition durably',
      (tester) async {
    final store =
        RewardTestStore({_walletKey: jsonEncode(_initialWallet.toJson())});
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app(tester);
    await _newEditor(tester, app);
    await _fill(tester);
    store
      ..failingPrefix = 'flutter.lumo.reward_shop.profile.'
      ..reply = RewardWriteReply.falseAfterMemory
      ..failuresLeft = 1;
    await tester.tap(find.byKey(const ValueKey('custom-reward-save')));
    await _frames(tester);
    expect(find.byKey(const ValueKey('custom-reward-editor-error')),
        findsOneWidget);
    expect(find.text('Speichern erneut versuchen'), findsOneWidget);
    expect(store.confirmedTargetWrites, 0);
    await tester.tap(find.byKey(const ValueKey('custom-reward-save')));
    await _frames(tester, 30);
    expect(
        find.byKey(const ValueKey('custom-reward-editor-error')), findsNothing);
    final durable = RewardShopProfile.fromJson((jsonDecode(
            store.disk['flutter.${RewardShopRepository.profileKey(_owner)}']
                as String) as Map)
        .cast<String, Object?>());
    expect(durable.revisions, hasLength(1));
    expect(store.confirmedTargetWrites, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets(
      'An interrupted debit resumes after cold restart with the original receipt',
      (tester) async {
    final store =
        RewardTestStore({_walletKey: jsonEncode(_initialWallet.toJson())});
    SharedPreferencesStorePlatform.instance = store;
    await const RewardShopRepository().saveDefinition(
        ownerId: _owner, definition: _seed, validateOwner: () {});
    var app = await _app(tester);
    try {
      await tester.pumpWidget(_host(RewardShopContent(appState: app)));
      await _frames(tester);
      store
        ..failingPrefix = 'flutter.$_walletKey'
        ..reply = RewardWriteReply.falseAfterMemory
        ..failuresLeft = 1;
      await tester.ensureVisible(_redeemButton(_seed.id));
      await _frames(tester, 3);
      await tester.tap(_redeemButton(_seed.id));
      await _frames(tester);
      await tester.tap(find.text('Als Erwachsene:r bestätigen'));
      await _frames(tester);
      expect(find.text('Einlösung abschließen'), findsOneWidget);
      expect(store.confirmedTargetWrites, 0);
      final pending = (await const RewardShopRepository().loadProfile(_owner))
          .pendingRedemptions
          .single;
      final diskWallet = RewardWallet.fromJson(
          jsonDecode(store.disk['flutter.$_walletKey'] as String)
              as Map<String, dynamic>);
      expect(diskWallet.stars, 200);
      expect(diskWallet.shopRedemptions, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      // Simulate process death: retain only the separately modeled durable
      // disk, not the Dart/native preference cache from the failed reply.
      SharedPreferences.setMockInitialValues(store.disk.map(
          (key, value) => MapEntry(key.substring('flutter.'.length), value)));
      app = await _app(tester);
      await tester.pumpWidget(_host(RewardShopContent(appState: app)));
      await _frames(tester);
      expect(find.text('Einlösung abschließen'), findsOneWidget);
      final resume = find.widgetWithText(FilledButton, 'Einlösung abschließen');
      await tester.ensureVisible(resume);
      await _frames(tester, 3);
      await _doubleTap(tester, resume);
      await _frames(tester);
      await tester.tap(find.text('Als Erwachsene:r bestätigen'));
      await _frames(tester, 30);
      final confirmed = await RewardWalletRepository().load();
      expect(confirmed.stars, 120);
      expect(confirmed.shopRedemptions, hasLength(1));
      expect(confirmed.shopRedemptions.single.transactionId,
          pending.transactionId);
      expect(
          (await const RewardShopRepository().loadProfile(_owner))
              .pendingRedemptions,
          isEmpty);
      expect(find.text('Einlösung abschließen'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    }
  });

  testWidgets(
      'Editing and deactivating during approval preserves the price that was displayed',
      (tester) async {
    const repo = RewardShopRepository();
    await repo.saveDefinition(
        ownerId: _owner, definition: _seed, validateOwner: () {});
    final app = await _app(tester);
    await tester.pumpWidget(_host(RewardShopContent(appState: app)));
    await _frames(tester);
    await tester.ensureVisible(_redeemButton(_seed.id));
    await _frames(tester, 3);
    await tester.tap(_redeemButton(_seed.id));
    await _frames(tester);
    expect(find.textContaining('80 Sterne'), findsOneWidget);
    await tester.runAsync(() => repo.saveDefinition(
        ownerId: _owner,
        definition: _seed.nextRevision(
            title: 'Neue Vereinbarung', cost: 150, active: false),
        validateOwner: () {}));
    await tester.tap(find.text('Als Erwachsene:r bestätigen'));
    await _frames(tester, 30);
    final wallet = await RewardWalletRepository().load();
    expect(wallet.stars, 120);
    expect(wallet.shopRedemptions.single.title, _seed.title);
    expect(wallet.shopRedemptions.single.itemRevision, 1);
    expect(wallet.shopRedemptions.single.cost, 80);
    expect((await repo.loadProfile(_owner)).currentDefinitions.single.active,
        isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets(
      'Editor and shop remain usable on a narrow screen with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    await const RewardShopRepository().saveDefinition(
        ownerId: _owner, definition: _seed, validateOwner: () {});
    final app = await _app(tester);
    try {
      await tester
          .pumpWidget(_host(CustomRewardsScreen(appState: app), scale: 1.6));
      await _frames(tester);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
          find.byKey(ValueKey('custom-reward-edit-${_seed.id}')));
      await _frames(tester, 3);
      await tester.tap(find.byKey(ValueKey('custom-reward-edit-${_seed.id}')));
      await _frames(tester);
      expect(find.text('Gutschein bearbeiten'), findsOneWidget);
      await _field(tester, 'custom-reward-cost', '90');
      await tester.tap(find.byKey(const ValueKey('custom-reward-save')));
      await _frames(tester);
      expect(
          (await const RewardShopRepository().loadProfile(_owner))
              .currentDefinitions
              .single
              .cost,
          90);
      expect(tester.takeException(), isNull);
      await tester
          .pumpWidget(_host(RewardShopContent(appState: app), scale: 1.6));
      await _frames(tester);
      await tester.ensureVisible(_redeemButton(_seed.id));
      await _frames(tester, 3);
      await tester.tap(_redeemButton(_seed.id));
      await _frames(tester);
      expect(find.byType(ParentApprovalDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });
}
