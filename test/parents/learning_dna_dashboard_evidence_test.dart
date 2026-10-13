import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/domain/learning/learning_dna_engine.dart';
import 'package:lumo_lernen/features/learning/learning_dna_card.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:lumo_lernen/features/parents/widgets/lumo_insight_heatmap.dart';
import 'package:shared_preferences/shared_preferences.dart';

const boundaryKey = ValueKey('dna-evidence-capture');
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.ci-results/learning-dna/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  testWidgets(
      'live dashboard replaces profile evidence and preserves AI permission',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.runAsync(() async {
      app.updateSettings(AppSettings(
          aiProxyEnabled: false,
          voiceEnabled: false,
          reduceAnimations: true,
          calmMode: true));
      await app.school.setActiveStudent('widget-dna-a');
      await app.recordLearningAnswer(
          subject: 'Deutsch',
          unit: 'Artikel',
          correct: true,
          requireSaved: true);
      await app.recordLearningAnswer(
          subject: 'Deutsch',
          unit: 'Artikel',
          correct: false,
          requireSaved: true);
    });
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
            key: boundaryKey, child: LumoInsightDashboard(appState: app))));
    await frames(tester);
    expect(find.text('50% · 1 von 2 Antworten richtig'), findsOneWidget);
    expect(
        find.text('Kleine Stichprobe – noch keine Einordnung'), findsOneWidget);
    expect(find.text('Heute'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('KI fragen'));
    await tester.tap(find.text('KI fragen'));
    await frames(tester);
    expect(find.textContaining('noch nicht freigegeben'), findsOneWidget);
    expect(app.state.settings.aiProxyEnabled, false);
    await tester.runAsync(() async {
      await app.school.setActiveStudent('widget-dna-b');
      await app.loadLearningProfile();
    });
    await frames(tester);
    expect(find.text('50% · 1 von 2 Antworten richtig'), findsNothing);
    expect(find.textContaining('noch nicht freigegeben'), findsNothing);
    expect(find.text('Noch keine Daten'), findsOneWidget);
    await tester.runAsync(() async {
      await app.school.setActiveStudent('widget-dna-a');
      await app.loadLearningProfile();
    });
    await frames(tester);
    expect(find.text('50% · 1 von 2 Antworten richtig'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'observations show counts at large text size across phone and inner display widths',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final dna =
        const LearningDnaEngine().compute(state: LumoSessionState(), skills: {
      'small': SkillRecord(
          skillId: 'small',
          subject: 'Deutsch',
          unit: 'Artikel',
          correct: 1,
          wrong: 1),
      'empty':
          SkillRecord(skillId: 'empty', subject: 'Lesen', unit: 'Geschichten'),
      'many': SkillRecord(
          skillId: 'many',
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          correct: 7,
          wrong: 3),
    });
    for (final width in [360.0, 800.0]) {
      tester.view.physicalSize = Size(width, 960);
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 960),
                  textScaler: const TextScaler.linear(1.5)),
              child: Scaffold(
                  body: RepaintBoundary(
                      key: boundaryKey,
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            LumoInsightHeatmap(entries: dna.skillObservations),
                            const SizedBox(height: 16),
                            LearningDnaParentCard(dna: dna)
                          ])))))));
      await tester.pump();
      expect(find.text('50% · 1 von 2 Antworten richtig'), findsNWidgets(2));
      expect(find.text('70% · 7 von 10 Antworten richtig'), findsNWidgets(2));
      expect(find.text('Noch keine Antworten'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await capture(tester, 'observations-${width.toInt()}-large-text');
    }
  });
}
