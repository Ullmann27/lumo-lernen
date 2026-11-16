import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

final _bus = LumoCompanionRequests.instance;

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _frames(tester);
}

Future<LumoAppState> _openCore(WidgetTester tester,
    {Size size = const Size(600, 1400)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final date = DateTime(2026, 11, 16);
  await tester.pumpWidget(MaterialApp(
    theme: LumoAppTheme.light(),
    home: AppShell(
      profile: UserProfile(
          id: 'core-dialog',
          name: 'Mia',
          age: 9,
          grade: 4,
          createdAt: date,
          lastActiveAt: date),
      initialSection: LumoSection.learn,
    ),
  ));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
  });
  await _frames(tester);
  await _tap(tester, find.byKey(const ValueKey('learning-subject-Mathematik')));
  await _tap(
      tester,
      find.byKey(
          const ValueKey('learning-unit-Mathematik-Zahlenraum bis 1 Million')));
  expect(find.byType(LearningContent), findsOneWidget);
  expect(_bus.taskContext.value, isNotNull);
  return tester.widget<LearningContent>(find.byType(LearningContent)).appState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key);
      loader.addFont(Future.value(ByteData.sublistView(
          await File('$fonts/${entry.value}').readAsBytes())));
      await loader.load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        soundEnabled: false,
        voiceEnabled: false,
        autoReadEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
        calmMode: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    _bus.clearLearningScope();
    await RewardWalletRepository.instance.reset();
    // UI routing and task ownership are real. Artwork is a transport stub so
    // this focused test needs no duplicate asset bundle and makes no visual claim.
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(<String, Object?>{});
      }
      if (key == 'FontManifest.json') {
        return ByteData.sublistView(utf8.encode('[]'));
      }
      if (key.endsWith('.json')) return ByteData.sublistView(utf8.encode('{}'));
      if (RegExp(r'\.(?:png|webp|jpg)$').hasMatch(key)) {
        return ByteData.sublistView(png);
      }
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    _bus.clearLearningScope();
    LumoVoice.instance.isEnabled = true;
  });

  testWidgets(
      'actual Core header dialog retains current task and permitted help',
      (tester) async {
    final app = await _openCore(tester);
    final task = _bus.taskContext.value!;
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
    await _tap(tester, find.byKey(const ValueKey('mobile-lumo-button')));
    final dialog = find.byType(LumoAgentContent);
    expect(dialog, findsOneWidget);
    expect(_bus.taskContext.value?.taskId, task.taskId,
        reason: 'The Core owner must retain its exact task in its own dialog.');
    expect(find.descendant(of: dialog, matching: find.text(task.prompt)),
        findsOneWidget);
    final field = find.descendant(of: dialog, matching: find.byType(TextField));
    await tester.enterText(field, 'Erklär mir diese Aufgabe');
    tester.testTextInput.hide();
    await _tap(
        tester,
        find.descendant(
            of: dialog, matching: find.widgetWithText(FilledButton, 'Senden')));
    expect(_bus.taskContext.value!.taskId, task.taskId);
    expect(_bus.taskContext.value!.helpLevel, greaterThan(task.helpLevel));
    expect(
        find.descendant(
            of: dialog,
            matching: find.textContaining('Wir schauen auf deine Aufgabe.')),
        findsOneWidget);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    final beforeStop = _bus.learningIdentity.value!;
    await _tap(
        tester,
        find.descendant(
            of: dialog,
            matching: find.widgetWithText(OutlinedButton, 'Stopp')));
    expect(_bus.taskContext.value!.taskId, task.taskId);
    expect(_bus.isCurrentLearningIdentity(beforeStop), isFalse);
    expect(
        _bus.requestLearningAction(LumoLearningAction.hint,
            identity: beforeStop),
        isFalse);
    await _tap(tester, find.byTooltip('Zurück zur Aufgabe'));
    expect(find.byType(LumoAgentContent), findsNothing);
    expect(_bus.taskContext.value!.taskId, task.taskId);
    expect(
        _bus.requestLearningAction(LumoLearningAction.hint,
            identity: _bus.learningIdentity.value!),
        isTrue);
    await _frames(tester);
    expect(_bus.taskContext.value!.helpLevel, greaterThan(task.helpLevel));
    expect(tester.takeException(), isNull);
  });

  testWidgets('foreign overlay withdraws even an owned Core conversation',
      (tester) async {
    final app = await _openCore(tester);
    final task = _bus.taskContext.value!;
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
    await _tap(tester, find.byKey(const ValueKey('mobile-lumo-button')));
    final previous = _bus.learningIdentity.value!;
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Fremde Seite'))));
    await _frames(tester);
    expect(_bus.taskContext.value, isNull);
    expect(
        _bus.requestLearningAction(LumoLearningAction.hint, identity: previous),
        isFalse);
    navigator.pop();
    await _frames(tester);
    expect(_bus.taskContext.value!.taskId, task.taskId);
    expect(_bus.isCurrentLearningIdentity(previous), isFalse);
    expect(
        find.descendant(
            of: find.byType(LumoAgentContent),
            matching: find.text(task.prompt)),
        findsOneWidget);
    await _tap(tester, find.byTooltip('Zurück zur Aufgabe'));
    expect(_bus.taskContext.value!.taskId, task.taskId);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('task replacement retires the old dialog and its entry owner',
      (tester) async {
    final app = await _openCore(tester);
    final oldTask = _bus.taskContext.value!;
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
    await _tap(tester, find.byKey(const ValueKey('mobile-lumo-button')));
    final previous = _bus.learningIdentity.value!;
    // An external task selection must not transfer a still-open old dialog's
    // ownership to the replacement task underneath it.
    app.update(app.state.copyWith(unit: 'Zahlenstrahl'));
    await _frames(tester);
    expect(_bus.taskContext.value, isNull);
    expect(
        _bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: previous, candidate: '13'),
        isFalse);
    await _tap(tester, find.byTooltip('Zurück zur Aufgabe'));
    final current = _bus.taskContext.value!;
    expect(current.taskId, isNot(oldTask.taskId));
    expect(current.unit, 'Zahlenstrahl');
    await _tap(tester, find.byKey(const ValueKey('mobile-lumo-button')));
    expect(_bus.taskContext.value!.taskId, current.taskId,
        reason:
            'Disposing the old owner must not detach the new header entry.');
    expect(
        find.descendant(
            of: find.byType(LumoAgentContent),
            matching: find.text(current.prompt)),
        findsOneWidget);
    await _tap(tester, find.byTooltip('Zurück zur Aufgabe'));
    expect(_bus.taskContext.value!.taskId, current.taskId);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual Core and own dialog survive the shell width breakpoint',
      (tester) async {
    final app = await _openCore(tester, size: const Size(430, 1400));
    final core = tester.state(find.byType(LearningContent));
    final task = _bus.taskContext.value!;
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
    await _tap(tester, find.byKey(const ValueKey('mobile-lumo-button')));
    expect(_bus.taskContext.value!.taskId, task.taskId);
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    await _frames(tester);
    final renderer =
        tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
    expect((
      identical(tester.state(find.byType(LearningContent)), core),
      renderer.task.taskInstanceId,
      _bus.taskContext.value?.taskId
    ), (
      true,
      task.taskId,
      task.taskId
    ),
        reason:
            'Width changes must retain the Core State, model and dialog task.');
    expect(
        find.descendant(
            of: find.byType(LumoAgentContent),
            matching: find.text(task.prompt)),
        findsOneWidget);
    await _tap(tester, find.byTooltip('Zurück zur Aufgabe'));
    expect(_bus.taskContext.value!.taskId, task.taskId);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });
}
