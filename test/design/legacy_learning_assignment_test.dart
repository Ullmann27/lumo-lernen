import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _captureKey = ValueKey('legacy-parent-capture');

class _ParentStorageFailure extends InMemorySharedPreferencesStore {
  _ParentStorageFailure(Map<String, Object> values)
      : super.withData(
            values.map((key, value) => MapEntry('flutter.$key', value)));

  String? rejectKey;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      key == rejectKey ? false : super.setValue(valueType, key, value);
}

Map<String, Object> _legacyFixture() => {
      'lumo_school_v1': jsonEncode(const SchoolDirectory(
        classes: [
          SchoolClass(
              id: 'class-one',
              name: '1a',
              grade: 1,
              teacherIds: ['teacher-local']),
        ],
        students: [
          SchoolStudent(id: 'student-a', name: 'Kind A', classId: 'class-one'),
          SchoolStudent(id: 'student-b', name: 'Kind B', classId: 'class-one'),
          SchoolStudent(
              id: 'student-c',
              name: 'Alexandra Maximiliane',
              classId: 'class-one'),
        ],
      ).toJson()),
      'lumo_progress_skills': jsonEncode({
        'mathematik::plus bis 10': SkillRecord(
          skillId: 'mathematik::plus bis 10',
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          correct: 6,
          lastSeen: DateTime(2026, 10, 9),
        ).toJson(),
      }),
      'lumo_progress_daily': '{"2026-10-09":6}',
      'lumo_progress_last': '{"Mathematik":"Plus bis 10"}',
      'lumo_cosmos_items_v1': '[{"t":1,"x":0.3,"y":0.4,"s":1.0,"r":0.0}]',
      'lumo_cosmos_meta_v1': '{"c":6,"s":1,"d":"2026-10-09"}',
    };

Future<void> _settle(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<LumoAppState> _mount(WidgetTester tester,
    {Size size = const Size(412, 915), double textScale = 1}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState();
  app.update(app.state.copyWith(childName: 'Geräteprofil', grade: 1));
  app.updateSettings(const AppSettings(
    reduceAnimations: true,
    calmMode: true,
    voiceEnabled: false,
    soundEnabled: false,
    autoReadEnabled: false,
  ));
  await SettingsRepository.save(app.state.settings);
  addTearDown(app.dispose);
  await tester.pumpWidget(RepaintBoundary(
    key: _captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LumoAppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: const Scaffold(body: Text('Start')),
      initialRoute: '/eltern',
      routes: {
        '/eltern': (_) => Scaffold(body: SettingsContent(appState: app)),
      },
    ),
  ));
  await _settle(tester);
  return app;
}

Future<void> _capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['LUMO_PROFILE_CAPTURES'];
  if (directory == null) return;
  await tester.runAsync(() async {
    await Future.wait(tester.widgetList<Image>(find.byType(Image)).map(
        (image) =>
            precacheImage(image.image, tester.element(find.byWidget(image)))));
  });
  await tester.pump(const Duration(milliseconds: 400));
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) throw StateError('The real parent screen did not render');
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _selectChild(WidgetTester tester, String label) async {
  final selector = find.byKey(const ValueKey('legacy-learning-child'));
  await tester.ensureVisible(selector);
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'));
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(_legacyFixture());
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets(
      'parents discover unassigned legacy learning without a default child',
      (tester) async {
    final originals = _legacyFixture();
    final app = await _mount(tester);
    final card = find.byKey(const ValueKey('legacy-learning-assignment'));
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pump();
    expect(find.text('Vorhandenen Lernstand zuordnen'), findsOneWidget);
    final assign = tester.widget<FilledButton>(
        find.byKey(const ValueKey('legacy-learning-assign')));
    expect(assign.onPressed, isNull);
    expect(await app.school.activeStudentId(), isNull);
    final prefs = await SharedPreferences.getInstance();
    for (final key in originals.keys.where((key) => key != 'lumo_school_v1')) {
      expect(prefs.getString(key), originals[key]);
    }
    await _capture(tester, 'legacy_parent_phone');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancel and Android back leave the legacy owner undecided',
      (tester) async {
    final app = await _mount(tester);
    await _selectChild(tester, 'Kind A · 1a');
    for (final useBack in [false, true]) {
      final assign = find.byKey(const ValueKey('legacy-learning-assign'));
      await tester.ensureVisible(assign);
      await tester.tap(assign);
      await tester.pumpAndSettle();
      expect(find.text('Lernstand für Kind A übernehmen?'), findsOneWidget);
      if (useBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.text('Abbrechen'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
          find.byKey(const ValueKey('legacy-learning-child')), findsOneWidget);
      expect(await app.school.activeStudentId(), isNull);
      final legacy = await LegacyLearningDataRepository().inspect();
      expect(legacy.assignedStudentId, isNull);
      expect(legacy.pendingAssignment, isFalse);
      expect(legacy.reservedStudentId, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(LegacyLearningDataRepository.claimKey), isFalse);
      expect(prefs.containsKey(LegacyLearningDataRepository.stageKey), isFalse);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('explicit parent choice restores legacy learning to A only',
      (tester) async {
    final originals = _legacyFixture();
    final app = await _mount(tester, size: const Size(840, 780));
    await _selectChild(tester, 'Kind A · 1a');
    final assign = find.byKey(const ValueKey('legacy-learning-assign'));
    await tester.ensureVisible(assign);
    await tester.tap(assign);
    await tester.pumpAndSettle();
    await _capture(tester, 'legacy_parent_fold_confirm');
    await tester.tap(find.text('Als Erwachsene:r zuordnen'));
    await _settle(tester);
    expect(find.text('Lernstand zugeordnet'), findsOneWidget);
    await app.school.setActiveStudent('student-a');
    await app.loadLearningProfile();
    expect(app.learningSkills()['mathematik::plus bis 10']?.correct, 6);
    await app.school.setActiveStudent('student-b');
    await app.loadLearningProfile();
    expect(app.learningSkills(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    for (final key in originals.keys.where((key) => key != 'lumo_school_v1')) {
      expect(prefs.getString(key), originals[key]);
    }
    await _capture(tester, 'legacy_parent_fold_assigned');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('child choice survives Fold resizing and large readable text',
      (tester) async {
    await _mount(tester, size: const Size(320, 740), textScale: 1.5);
    const selectedLabel = 'Alexandra Maximiliane · 1a';
    await _selectChild(tester, selectedLabel);
    for (final size in [const Size(840, 780), const Size(320, 740)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump();
      final assign = find.byKey(const ValueKey('legacy-learning-assign'));
      await tester.ensureVisible(assign);
      await tester.pump();
      expect(tester.widget<FilledButton>(assign).onPressed, isNotNull);
      expect(find.text(selectedLabel), findsOneWidget);
      final selector =
          tester.getRect(find.byKey(const ValueKey('legacy-learning-child')));
      final label = tester.getRect(find.text(selectedLabel));
      expect(label.top, greaterThanOrEqualTo(selector.top));
      expect(label.bottom, lessThanOrEqualTo(selector.bottom));
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(
        find.byKey(const ValueKey('legacy-learning-assignment')));
    await tester.pump();
    await _capture(tester, 'legacy_parent_large_text');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a fresh install needs no legacy assignment card',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _mount(tester);
    expect(
        find.byKey(const ValueKey('legacy-learning-assignment')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a missing reserved child cannot receive an unnamed confirmation',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      ..._legacyFixture(),
      LegacyLearningDataRepository.claimKey:
          '{"version":1,"owner":"removed-child","state":"prepared"}',
    });
    await _mount(tester);
    final assign = tester.widget<FilledButton>(
        find.byKey(const ValueKey('legacy-learning-assign')));
    expect(assign.onPressed, isNull);
    expect(find.textContaining('nicht mehr verfügbar'), findsOneWidget);
    expect((await LegacyLearningDataRepository().inspect()).reservedStudentId,
        'removed-child');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a successful empty retry clears an earlier storage error',
      (tester) async {
    final store = _ParentStorageFailure(_legacyFixture())
      ..rejectKey = 'flutter.${LegacyLearningDataRepository.localIdKey}';
    SharedPreferencesStorePlatform.instance = store;
    await _mount(tester);
    final retry = find.text('Erneut prüfen');
    expect(retry, findsOneWidget);
    store.rejectKey = null;
    final prefs = await SharedPreferences.getInstance();
    for (final key in LegacyLearningDataRepository.legacyKeys) {
      await prefs.remove(key);
    }
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await _settle(tester);
    expect(
        find.byKey(const ValueKey('legacy-learning-assignment')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an interrupted parent assignment retries only for the reserved child',
      (tester) async {
    final store = _ParentStorageFailure(_legacyFixture())
      ..rejectKey = 'flutter.${LegacyLearningDataRepository.stageKey}';
    SharedPreferencesStorePlatform.instance = store;
    final app = await _mount(tester);
    await _selectChild(tester, 'Kind A · 1a');
    final assign = find.byKey(const ValueKey('legacy-learning-assign'));
    await tester.ensureVisible(assign);
    await tester.tap(assign);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Als Erwachsene:r zuordnen'));
    await tester.pumpAndSettle();
    await _settle(tester);
    final pending = await LegacyLearningDataRepository().inspect();
    expect(pending.assignedStudentId, isNull);
    expect(pending.reservedStudentId, 'student-a');
    expect(tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('legacy-learning-child'))).onChanged, isNull);
    expect(tester.widget<FilledButton>(assign).onPressed, isNull);
    store.rejectKey = null;
    final retry = find.text('Erneut prüfen');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await _settle(tester);
    expect(tester.widget<FilledButton>(assign).onPressed, isNotNull);
    await tester.ensureVisible(assign);
    await tester.tap(assign);
    await tester.pumpAndSettle();
    expect(find.text('Lernstand für Kind A übernehmen?'), findsOneWidget);
    await tester.tap(find.text('Als Erwachsene:r zuordnen'));
    await tester.pumpAndSettle();
    await _settle(tester);
    expect(find.text('Lernstand zugeordnet'), findsOneWidget);
    await app.school.setActiveStudent('student-a');
    await app.loadLearningProfile();
    expect(app.learningSkills()['mathematik::plus bis 10']?.correct, 6);
    await app.school.setActiveStudent('student-b');
    await app.loadLearningProfile();
    expect(app.learningSkills(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('returning from child management refreshes the available owners',
      (tester) async {
    final app = await _mount(tester);
    final teacher = find.byKey(const ValueKey('open-teacher-area'));
    await tester.ensureVisible(teacher);
    await tester.tap(teacher);
    await tester.pumpAndSettle();
    await app.school.addStudent('class-one', 'Neues Kind');
    await app.school.removeStudent('student-b');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _settle(tester);
    final selector = find.byKey(const ValueKey('legacy-learning-child'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    expect(find.text('Neues Kind · 1a'), findsWidgets);
    expect(find.text('Kind B · 1a'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'rapid confirmation taps keep the parent page open and assign once',
      (tester) async {
    await _mount(tester);
    await _selectChild(tester, 'Kind A · 1a');
    final assign = find.byKey(const ValueKey('legacy-learning-assign'));
    await tester.ensureVisible(assign);
    await tester.tap(assign);
    await tester.pumpAndSettle();
    final confirm = find.text('Als Erwachsene:r zuordnen');
    final position = tester.getCenter(confirm);
    await tester.tapAt(position);
    await tester.tapAt(position);
    await tester.pumpAndSettle();
    await _settle(tester);
    expect(find.byType(SettingsContent), findsOneWidget);
    expect(find.text('Lernstand zugeordnet'), findsOneWidget);
    expect((await LegacyLearningDataRepository().inspect()).assignedStudentId,
        'student-a');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
