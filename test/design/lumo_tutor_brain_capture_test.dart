import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_place_value_workshop.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

const boundaryKey = ValueKey('tutor-production-route');
final captureDir = Platform.environment['LUMO_TUTOR_BRAIN_CAPTURES'];
Future<void> capture(WidgetTester tester, String name) async {
  if (captureDir == null) return;
  await tester.runAsync(() async {
    await Future.wait(find.byType(Image).evaluate().map((e) => precacheImage((e.widget as Image).image, e)));
  });
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final path = File('$captureDir/$name.png');
    await path.parent.create(recursive: true);
    await path.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final (label, size, scale) in [
    ('phone', const Size(360, 820), 1.0),
    ('small-large-text', const Size(280, 740), 2.0),
    ('fold-open', const Size(880, 1000), 1.0),
  ]) {
    testWidgets('real home daily plan opens real task and workshop: $label', (tester) async {
      final oldError = FlutterError.onError;
      FlutterError.onError = (d) { File('/tmp/tutor-render-error.txt').writeAsStringSync(d.toString(), mode: FileMode.append); oldError?.call(d); };
      addTearDown(() => FlutterError.onError = oldError);
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
      addTearDown(() => LumoVoice.instance.isEnabled = true);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.runAsync(() async {
        await app.school.setActiveStudent('capture-child');
        await app.loadLearningProfile();
        await app.recordTutorEvidence(subject: 'Mathematik', unit: 'Zehner und Einer',
          evidence: const LearningEvidence(taskId: 'known-assisted', correct: true, helpLevel: 2));
      });
      app.updateSettings(const AppSettings(voiceEnabled: false, autoReadEnabled: false,
        soundEnabled: false, reduceAnimations: true));
      app.update(app.state.copyWith(grade: 2, section: LumoSection.home));
      await tester.pumpWidget(MaterialApp(theme: LumoAppTheme.light(),
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: RepaintBoundary(key: boundaryKey, child: child!)),
        home: Scaffold(backgroundColor: const Color(0xFF071B3B), body: LumoSceneBackground(
          scene: LumoScene.learning, child: AnimatedBuilder(animation: app, builder: (context, _) =>
            app.state.section == LumoSection.home
              ? HomeContent(appState: app, onSection: (section) => app.update(app.state.copyWith(section: section)))
              : LearningContent(appState: app))))));
      await tester.pump();
      final start = find.byKey(const ValueKey('lumo-daily-plan-start-0'));
      await tester.scrollUntilVisible(start, 300, scrollable: find.byType(Scrollable).first, maxScrolls: 30);
      await tester.pump();
      await capture(tester, '$label-daily-plan');
      await tester.tap(start);
      await tester.pump();
      expect(app.state.section, LumoSection.exercises);
      expect(find.byType(AdaptiveTaskRenderer), findsOneWidget);
      final taskId = LumoCompanionRequests.instance.taskContext.value!.taskId;
      for (var i = 0; i < 3; i++) {
        LumoCompanionRequests.instance.requestTaskHelp();
        await tester.pump();
      }
      expect(find.byType(LumoPlaceValueWorkshop), findsOneWidget);
      final workshop = find.byKey(const ValueKey('lumo-place-value-workshop'));
      await tester.ensureVisible(workshop);
      await tester.pump();
      await capture(tester, '$label-workshop');
      expect(LumoCompanionRequests.instance.taskContext.value!.taskId, taskId);
      expect(LumoCompanionRequests.instance.tutor.helpLevel, 3);
      expect(app.learningJourney().values.single.independentCorrect, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
