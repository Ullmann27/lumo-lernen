import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/native_profile_key_repository.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';
import 'package:lumo_lernen/features/settings/native_game_saves_card.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';

const bridge = MethodChannel('lumo_lernen/bridge');
const salt = 'synthetic-native-ui-2017';
const repo = NativeProfileKeyRepository();
const captureKey = ValueKey('native-profile-capture');
String oldKey(String name, int grade) =>
    'p_${sha256.convert(utf8.encode('$salt|$name|$grade')).toString().substring(0, 32)}';

Future<void> frames(WidgetTester tester, [int count = 25]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['LUMO_NATIVE_PROFILE_CAPTURE_DIR'];
  if (directory == null) return;
  await frames(tester, 5);
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('No actual Flutter-rendered pixels');
    final path = File('$directory/$name.png');
    await path.parent.create(recursive: true);
    await path.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> mount(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
          theme: LumoAppTheme.light(), home: Scaffold(body: child))));
  await frames(tester);
}

Future<List<String>> prepare(LumoAppState app, {bool school = true}) async {
  app.update(app.state.copyWith(childName: 'Testkind', grade: 2));
  app.updateSettings(const AppSettings(
      voiceEnabled: false,
      autoReadEnabled: false,
      soundEnabled: false,
      reduceAnimations: true,
      requireDailyMissionForGames: false));
  final ids = <String>[];
  if (school) {
    final directory = await app.school.addClass('Gleiche Klasse', 2);
    final classId = directory.classes.last.id;
    await app.school.addStudent(classId, 'Testkind');
    final students = await app.school.addStudent(classId, 'Testkind');
    ids.addAll(students.students.map((student) => student.id));
    await app.school.setActiveStudent(ids.first);
  }
  await app.loadLearningProfile();
  return ids;
}

Future<void> mountLaunch(WidgetTester tester, LumoAppState app,
        {String? legacyKey}) =>
    mount(
        tester,
        Builder(
            builder: (context) => ElevatedButton(
                onPressed: () => launchLumo3D(context,
                    scene: 'puzzle', appState: app, legacyGameKey: legacyKey),
                child: const Text('Normales Puzzle öffnen'))));

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await frames(tester);
}

class DelayedLeaseState extends LumoAppState {
  bool hold = false;
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<LearningProfileLease> captureLearningProfile() {
    final captured = super.captureLearningProfile();
    if (!hold) return captured;
    hold = false;
    return captured.then((owner) async {
      entered.complete();
      await release.future;
      return owner;
    });
  }
}

class RejectMappingStore extends InMemorySharedPreferencesStore {
  RejectMappingStore()
      : super.withData({
          'flutter.${NativeProfileKeyRepository.saltKey}': salt,
        });
  bool reject = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (reject && key == 'flutter.${NativeProfileKeyRepository.storageKey}') {
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

class InvalidatedLeaseState extends LumoAppState {
  bool leaseValid = true;
  @override
  bool canUseLearningLease(LearningProfileLease lease) =>
      leaseValid && super.canUseLearningLease(lease);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  setUpAll(() async {
    final font = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {NativeProfileKeyRepository.saltKey: salt});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    LumoVoice.instance.isEnabled = false;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      calls.add(call);
      return <String, Object?>{'destination': 'games'};
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, null);
  });

  testWidgets(
      'real same-name students keep distinct launcher keys through grade, name and app restart',
      (tester) async {
    late LumoAppState app;
    try {
      final ids = (await tester.runAsync(() async {
        app = LumoAppState();
        return prepare(app);
      }))!;
      await mountLaunch(tester, app);
      for (final id in ids) {
        await tester.runAsync(() async {
          await app.school.setActiveStudent(id);
          await app.loadLearningProfile();
        });
        await tap(tester, find.text('Normales Puzzle öffnen'));
      }
      expect(calls, hasLength(2));
      final first = (calls[0].arguments as Map)['childKey'];
      final second = (calls[1].arguments as Map)['childKey'];
      expect(first, isNot(second));
      expect(first, isNot(oldKey('Testkind', 2)));
      expect(second, isNot(oldKey('Testkind', 2)));
      app.update(app.state.copyWith(childName: 'Neuer Name', grade: 4));
      await tap(tester, find.text('Normales Puzzle öffnen'));
      expect((calls.last.arguments as Map)['childKey'], second);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.runAsync(() async {
        app = LumoAppState();
        app.update(app.state.copyWith(childName: 'Wieder gestartet', grade: 3));
        await app.loadLearningProfile();
      });
      await mountLaunch(tester, app);
      await tap(tester, find.text('Normales Puzzle öffnen'));
      expect((calls.last.arguments as Map)['childKey'], second);
      expect(
          await tester.runAsync(() => app.school.activeStudentId()), ids.last);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'actual solo upgrade launcher retains 2017 key and original native filenames',
      (tester) async {
    late LumoAppState app;
    try {
      await tester.runAsync(() async {
        app = LumoAppState();
        await prepare(app, school: false);
      });
      await mountLaunch(tester, app);
      await tap(tester, find.text('Normales Puzzle öffnen'));
      expect(
          (calls.single.arguments as Map)['childKey'], oldKey('Testkind', 2));
      app.update(app.state.copyWith(childName: 'Umbenannt', grade: 4));
      await tap(tester, find.text('Normales Puzzle öffnen'));
      expect((calls.last.arguments as Map)['childKey'], oldKey('Testkind', 2));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'actual parent entry cancel, adult assignment, separate old launch and Phone/Fold layout',
      (tester) async {
    late LumoAppState app;
    try {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      final ids = (await tester.runAsync(() async {
        app = LumoAppState();
        return prepare(app);
      }))!;
      await mount(tester, SettingsContent(appState: app));
      await tester
          .ensureVisible(find.byKey(const ValueKey('native-game-saves-open')));
      await capture(tester, 'native_profiles_parent_entry');
      await tap(tester, find.byKey(const ValueKey('native-game-saves-open')));
      final before =
          (await tester.runAsync(() => repo.inspect(ids.first)))!.primaryKey;
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-assign')));
      expect(find.byType(AlertDialog), findsOneWidget);
      await capture(tester, 'native_profiles_adult_confirmation');
      await tap(tester, find.text('Abbrechen'));
      expect((await tester.runAsync(() => repo.inspect(ids.first)))!.legacy,
          isEmpty);
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-assign')));
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-confirm')));
      final keys = (await tester.runAsync(() => repo.inspect(ids.first)))!;
      expect(keys.primaryKey, before);
      expect(keys.legacy.single.key, oldKey('Testkind', 2));
      for (final size in [const Size(412, 915), const Size(840, 760)]) {
        await tester.binding.setSurfaceSize(size);
        final open = find.byKey(
            ValueKey('native-game-legacy-open-${keys.legacy.single.key}'));
        await tester.ensureVisible(open);
        await frames(tester);
        final rect = tester.getRect(open);
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
        await capture(
            tester,
            size.width == 412
                ? 'native_profiles_phone'
                : 'native_profiles_fold');
      }
      await tap(
          tester,
          find.byKey(
              ValueKey('native-game-legacy-open-${keys.legacy.single.key}')));
      expect(calls, hasLength(1));
      expect(
          (calls.single.arguments as Map)['childKey'], oldKey('Testkind', 2));
      expect((calls.single.arguments as Map)['grade'], 2);
      await tap(tester, find.byType(BackButton));
      await mountLaunch(tester, app);
      await tap(tester, find.text('Normales Puzzle öffnen'));
      expect((calls.last.arguments as Map)['childKey'], before);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('profile switch during adult dialog cancels assignment',
      (tester) async {
    late LumoAppState app;
    try {
      final ids = (await tester.runAsync(() async {
        app = LumoAppState();
        return prepare(app);
      }))!;
      await mount(tester,
          SingleChildScrollView(child: NativeGameSavesCard(appState: app)));
      await tap(tester, find.byKey(const ValueKey('native-game-saves-open')));
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-assign')));
      await tester.runAsync(() async {
        await app.school.setActiveStudent(ids.last);
        await app.loadLearningProfile();
      });
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-confirm')));
      expect((await tester.runAsync(() => repo.inspect(ids.first)))!.legacy,
          isEmpty);
      expect((await tester.runAsync(() => repo.inspect(ids.last)))!.legacy,
          isEmpty);
      expect(calls, isEmpty);
      expect(find.textContaining('aktive Kinderprofil wurde gewechselt'),
          findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'rejected adult assignment leaves old key unclaimed and shows retry',
      (tester) async {
    final store = RejectMappingStore();
    SharedPreferencesStorePlatform.instance = store;
    late LumoAppState app;
    try {
      final ids = (await tester.runAsync(() async {
        app = LumoAppState();
        return prepare(app);
      }))!;
      await mount(tester,
          SingleChildScrollView(child: NativeGameSavesCard(appState: app)));
      await tap(tester, find.byKey(const ValueKey('native-game-saves-open')));
      store.reject = true;
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-assign')));
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-confirm')));
      expect((await tester.runAsync(() => repo.inspect(ids.first)))!.legacy,
          isEmpty);
      expect(
          find.byKey(const ValueKey('native-game-save-error')), findsOneWidget);
      expect(calls, isEmpty);
      store.reject = false;
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-assign')));
      await tap(
          tester, find.byKey(const ValueKey('native-game-legacy-confirm')));
      expect((await tester.runAsync(() => repo.inspect(ids.first)))!.legacy,
          hasLength(1));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'captured lease changed before launch never opens another child save',
      (tester) async {
    late DelayedLeaseState app;
    try {
      final ids = (await tester.runAsync(() async {
        app = DelayedLeaseState();
        return prepare(app);
      }))!;
      await mountLaunch(tester, app);
      app.hold = true;
      await tester.tap(find.text('Normales Puzzle öffnen'));
      await frames(tester);
      expect(app.entered.isCompleted, isTrue);
      await tester.runAsync(() async {
        await app.school.setActiveStudent(ids.last);
        await app.loadLearningProfile();
      });
      app.release.complete();
      await frames(tester);
      expect(calls, isEmpty);
      expect((await tester.runAsync(() => repo.inspect(ids.first)))!.primaryKey,
          isNull);
      await tap(tester, find.text('Normales Puzzle öffnen'));
      expect(calls, hasLength(1));
      expect((calls.single.arguments as Map)['childKey'],
          (await tester.runAsync(() => repo.inspect(ids.last)))!.primaryKey);
    } finally {
      if (!app.release.isCompleted) app.release.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'native return rejects an invalidated lease before generation changes',
      (tester) async {
    late InvalidatedLeaseState app;
    final returned = Completer<Map<String, Object?>>();
    bool? result;
    try {
      await tester.runAsync(() async {
        app = InvalidatedLeaseState();
        await prepare(app, school: false);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, (call) {
        calls.add(call);
        return returned.future;
      });
      await mount(
          tester,
          Builder(
              builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await launchLumo3D(context,
                        scene: 'puzzle', appState: app);
                  },
                  child: const Text('Start'))));
      final generation = app.profileGeneration;
      await tap(tester, find.text('Start'));
      expect(calls, hasLength(1));
      app.leaseValid = false;
      expect(app.profileGeneration, generation);
      returned.complete({'destination': 'games'});
      await frames(tester);
      expect(result, isFalse);
    } finally {
      if (!returned.isCompleted) returned.complete({'destination': 'games'});
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
