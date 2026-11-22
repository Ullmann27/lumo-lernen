import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/local_backup_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/backup/local_backup.dart';
import 'package:lumo_lernen/features/backup/local_backup_card.dart';

LocalBackup _backup() => LocalBackup.create(preferences: {
      'lumo_journal_entries':
          '[{"id":"own-text","text":"Bleibt erhalten","createdAt":1234}]',
      'lumo_intro_seen': true,
    }, nativeFiles: [
      LocalBackupFile('run_records.cfg', utf8.encode('[record]\ntime=12.5\n'))
    ], now: DateTime.utc(2026, 11, 22));

class _Repository extends LocalBackupRepository {
  LocalBackup? selected = _backup();
  bool saved = false;
  bool restored = false;
  int restores = 0;
  @override
  Future<Map<String, dynamic>> status() async => {'previousAvailable': false};
  @override
  Future<LocalBackup?> choose() async => selected;
  @override
  Future<bool> saveBackup(LumoAppState app) async => saved;
  @override
  Future<void> restore(LumoAppState app, LocalBackup archive) async {
    restored = true;
    restores++;
  }
}

class _HeldWalletStore extends InMemorySharedPreferencesStore {
  _HeldWalletStore()
      : super.withData({
          'flutter.lumo_reward_wallet_v1':
              jsonEncode(const RewardWallet(stars: 10, xp: 80).toJson())
        });
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.lumo_reward_wallet_v1' && !entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalBackupRepository.channel, null);
    SharedPreferences.setMockInitialValues({});
  });

  test('native picker cancellation never stages a restore', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalBackupRepository.channel, (call) async {
      calls.add(call.method);
      return null;
    });
    expect(await const LocalBackupRepository().choose(), isNull);
    expect(calls, ['pickBackup']);
  });

  test(
      'export keeps pending events plus fresh wallet and a cancelled save changes nothing',
      () async {
    final original = {
      'lumo_journal_entries': '[{"id":"j","text":"unverändert","createdAt":1}]',
      'lumo_reward_wallet_v1': jsonEncode(
          const RewardWallet(stars: 50, gameResultIds: ['already-paid'])
              .toJson())
    };
    SharedPreferences.setMockInitialValues(original);
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    final calls = <String>[];
    LocalBackup? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalBackupRepository.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'snapshotNative') {
        expect(app.resetting, true);
        return [
          {
            'path': 'lumo_game_events.json',
            'data': Uint8List.fromList(utf8
                .encode('{"results":[{"resultId":"pending-win","stars":4}]}'))
          }
        ];
      }
      if (call.method == 'saveBackup') {
        sent = LocalBackup.parse(call.arguments as Uint8List);
        return false;
      }
      throw StateError('Unexpected method');
    });
    expect(await const LocalBackupRepository().saveBackup(app), false);
    expect(sent!.preferences, original);
    expect(
        utf8.decode(sent!.nativeFiles.single.bytes), contains('pending-win'));
    expect(calls, ['snapshotNative', 'saveBackup']);
    final prefs = await SharedPreferences.getInstance();
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, original);
    expect(app.resetting, false);
  });

  test('failed staging does not close and releases the pause', () async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalBackupRepository.channel, (call) async {
      calls.add(call.method);
      expect(app.resetting, true);
      return false;
    });
    await expectLater(const LocalBackupRepository().restore(app, _backup()),
        throwsStateError);
    expect(calls, ['stageRestore']);
    expect(app.resetting, false);
    expect(app.backupBusy, false);
  });

  test(
      'restore stages reviewed bytes while paused and closes only after durable acknowledgement',
      () async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalBackupRepository.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'stageRestore') {
        expect(app.resetting, true);
        expect(LocalBackup.parse(call.arguments as Uint8List).digest,
            _backup().digest);
        app.addRewards(stars: 99, xp: 99);
        expect(app.hasPendingRewards, false);
        return true;
      }
      return null;
    });
    await const LocalBackupRepository().restore(app, _backup());
    expect(calls, ['stageRestore', 'closeForRestore']);
  });

  test('pending wallet write finishes before a backup can read it', () async {
    final store = _HeldWalletStore();
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    await wallet.load();
    final app = LumoAppState(walletRepository: wallet);
    addTearDown(app.dispose);
    app.addStars(7);
    await store.entered.future;
    var enteredSnapshot = false;
    final pending = app.withBackupStoragePaused(() async {
      enteredSnapshot = true;
      expect(app.resetting, true);
      final prefs = await SharedPreferences.getInstance();
      expect(
          (jsonDecode(prefs.getString('lumo_reward_wallet_v1')!)
              as Map)['stars'],
          17);
    });
    await Future<void>.delayed(Duration.zero);
    expect(enteredSnapshot, false);
    store.release.complete();
    await pending;
    expect(enteredSnapshot, true);
    expect(app.hasPendingRewards, false);
    expect(app.resetting, false);
  });

  Future<void> mount(WidgetTester tester, _Repository repository) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LocalBackupCard(
                    app: app, repository: repository, available: true)))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      '390dp review requires adult checkbox, cancellation performs no restore',
      (tester) async {
    final repository = _Repository();
    await mount(tester, repository);
    final importButton = find.byKey(const ValueKey('backup-import'));
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();
    expect(find.text('Geprüfte Sicherung wiederherstellen?'), findsOneWidget);
    final confirmation = tester.widget<FilledButton>(
        find.byKey(const ValueKey('backup-confirm-restore')));
    expect(confirmation.onPressed, isNull);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repository.restored, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual adult confirmation invokes exactly one staged restore',
      (tester) async {
    final repository = _Repository();
    await mount(tester, repository);
    await tester.ensureVisible(find.byKey(const ValueKey('backup-import')));
    await tester.tap(find.byKey(const ValueKey('backup-import')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('backup-confirm-restore')));
    await tester.pumpAndSettle();
    expect(repository.restores, 1);
    expect(find.textContaining('Bitte öffne Lumo erneut'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled Android selection remains a clean UI cancellation',
      (tester) async {
    final repository = _Repository()..selected = null;
    await mount(tester, repository);
    await tester.ensureVisible(find.byKey(const ValueKey('backup-import')));
    await tester.tap(find.byKey(const ValueKey('backup-import')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dateiauswahl abgebrochen'), findsOneWidget);
    expect(find.byKey(const ValueKey('backup-confirm-restore')), findsNothing);
    expect(repository.restores, 0);
    expect(tester.getSize(find.byKey(const ValueKey('backup-export'))).height,
        greaterThanOrEqualTo(48));
  });
}
