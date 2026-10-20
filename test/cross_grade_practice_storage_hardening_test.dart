import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';

const _scope =
    'cross_grade_practice_v1:hardening:3:Mathematik:Plus bis 1000';

class _ControlledStore extends InMemorySharedPreferencesStore {
  _ControlledStore(Map<String, Object> initial)
      : super.withData(initial.map((key, value) => MapEntry('flutter.$key', value)));

  Completer<void>? loadGate;
  String? rejectedKey;
  int rejectedWrites = 0;

  @override
  Future<Map<String, Object>> getAll() async {
    final gate = loadGate;
    if (gate != null) await gate.future;
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == rejectedKey) {
      rejectedWrites++;
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(
    home: CrossGradePracticeScreen(
      profileName: 'Hardening',
      enrolledGrade: 2,
      lessonGrade: 3,
      subject: 'Mathematik',
      unit: 'Plus bis 1000',
    ),
  ));
  await _frames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('answers wait for the existing practice counters to load',
      (tester) async {
    final store = _ControlledStore({
      '$_scope:answered': 7,
      '$_scope:correct': 3,
    });
    final gate = Completer<void>();
    store.loadGate = gate;
    SharedPreferencesStorePlatform.instance = store;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await _open(tester);
    final choice = find.byKey(const ValueKey('cross-grade-choice-0'));
    expect(tester.widget<OutlinedButton>(choice).onPressed, isNull,
        reason: 'An answer must not overwrite counters that are still loading.');
    gate.complete();
    await _frames(tester);
    expect(tester.widget<OutlinedButton>(choice).onPressed, isNotNull);
    expect(find.text('Extra-Übungen: 7 · richtig: 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('native false keeps Next locked and Retry does not count twice',
      (tester) async {
    final store = _ControlledStore({
      '$_scope:answered': 5,
      '$_scope:correct': 2,
      'lumo_progress_skills': '{"preserved":true}',
      'lumo_progress_daily': '{}',
    });
    SharedPreferencesStorePlatform.instance = store;
    await _open(tester);
    store.rejectedKey = 'flutter.$_scope:answered';
    await tester.runAsync(() => tester.tap(
        find.byKey(const ValueKey('cross-grade-choice-0'))));
    await _frames(tester);
    // An incorrect first choice now receives a second chance before any
    // counter write. Finish that question to reach the storage-failure path.
    if (find.text('Prüfe das Rechenzeichen und rechne in kleinen Schritten.').evaluate().isNotEmpty) {
      await tester.runAsync(() => tester.tap(
        find.byKey(const ValueKey('cross-grade-choice-1'))));
      await _frames(tester);
    }
    expect(store.rejectedWrites, greaterThan(0));
    final next = find.byKey(const ValueKey('cross-grade-next'));
    // Seit der Lumo-Bühne (#315) liegt „Weiter“ unterhalb des vorab gebauten
    // Bereichs der Liste: wie ein Kind dorthin scrollen, dann streng prüfen.
    await tester.scrollUntilVisible(next, 200,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.pump();
    expect(tester.widget<FilledButton>(next).onPressed, isNull,
        reason: 'Next must wait for successful storage of the accepted answer.');
    expect(find.byKey(const ValueKey('cross-grade-save-error')), findsOneWidget);
    final retry = find.byKey(const ValueKey('cross-grade-save-retry'));
    expect(retry, findsOneWidget);
    store.rejectedKey = null;
    await tester.ensureVisible(retry);
    await tester.runAsync(() => tester.tap(retry));
    await _frames(tester);
    expect(find.byKey(const ValueKey('cross-grade-save-error')), findsNothing);
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    final disk = await tester.runAsync(store.getAll);
    expect(disk!['flutter.$_scope:answered'], 6,
        reason: 'Retry saves the same accepted answer, not another attempt.');
    expect(disk['flutter.lumo_progress_skills'], '{"preserved":true}');
    expect(disk['flutter.lumo_progress_daily'], '{}');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invalid stored counters are reported without resetting history',
      (tester) async {
    final store = _ControlledStore({
      '$_scope:answered': -1,
      '$_scope:correct': 3,
    });
    SharedPreferencesStorePlatform.instance = store;
    await _open(tester);
    expect(find.byKey(const ValueKey('cross-grade-load-error')), findsOneWidget);
    expect(tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('cross-grade-choice-0'))).onPressed, isNull);
    final disk = await tester.runAsync(store.getAll);
    expect(disk!['flutter.$_scope:answered'], -1);
    expect(disk['flutter.$_scope:correct'], 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
