import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/curriculum_activities_screen.dart';
import 'package:lumo_lernen/features/learning_modules/farben/farben_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late bool voiceWasEnabled;
  setUp(() {
    voiceWasEnabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        soundEnabled: false,
        reduceAnimations: true,
        calmMode: true,
      ).toJson()),
    });
  });
  tearDown(() => LumoVoice.instance.isEnabled = voiceWasEnabled);

  Future<LumoAppState> open(WidgetTester tester, int grade) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(grade: grade));
    await tester
        .pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    return app;
  }

  Future<void> tools(WidgetTester tester) async {
    final entry = find.byKey(const ValueKey('learning-advanced-entry'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
  }

  testWidgets('existing colour lesson opens from academy tools without rewards',
      (tester) async {
    final app = await open(tester, 1);
    final before = (app.state.grade, app.state.stars, app.state.xp);
    await tools(tester);
    final colours = find.byKey(const ValueKey('academy-tool-s1_farben'));
    await tester.ensureVisible(colours);
    expect(colours, findsOneWidget);
    expect(tester.getSize(colours).height, greaterThanOrEqualTo(48));
    await tester.tap(colours);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byType(FarbenScreen), findsOneWidget);
    expect((app.state.grade, app.state.stars, app.state.xp), before);
    expect(tester.takeException(), isNull);
    final back = find.byTooltip('Zur Lernübersicht');
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byType(LumoAkademieScreen), findsOneWidget);
    expect((app.state.grade, app.state.stars, app.state.xp), before);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('browsing first grade does not enable a school-grade reward path',
      (tester) async {
    final app = await open(tester, 2);
    await tester.tap(find.byKey(const ValueKey('grade-pill-1')));
    await tester.pump();
    await tools(tester);
    expect(find.byKey(const ValueKey('academy-tool-s1_farben')), findsNothing);
    expect(app.state.grade, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'existing language and science activities follow the browsed grade',
      (tester) async {
    final app = await open(tester, 2);
    final before = (app.state.grade, app.state.stars, app.state.xp);
    await tester.tap(find.byKey(const ValueKey('grade-pill-4')));
    await tester.pump();
    await tools(tester);
    for (final subject in ['Deutsch', 'Englisch', 'Sachunterricht']) {
      final entry = find.byKey(ValueKey('academy-activity-$subject'));
      await tester.ensureVisible(entry);
      // The expanded tools sit inside an animated ListView. Flush its new
      // viewport geometry before hit testing, especially after Navigator.pop.
      await tester.pump(const Duration(milliseconds: 160));
      await tester.ensureVisible(entry);
      await tester.pump();
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      await tester.tap(entry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      final screen = tester.widget<CurriculumActivitiesScreen>(
          find.byType(CurriculumActivitiesScreen));
      expect(screen.grade, 4);
      expect(screen.subject, subject);
      expect(
          find.text(
              PrimaryActivityCatalog.forGrade(4, subject: subject).first.title),
          findsOneWidget);
      expect((app.state.grade, app.state.stars, app.state.xp), before);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Zurück'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
    }
    expect((app.state.grade, app.state.stars, app.state.xp), before);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
