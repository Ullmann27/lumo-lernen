import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

/// Spielewelt: Ein im Üben sicher gelöstes Thema öffnet die passende
/// Lernspiel-Stufe sichtbar, mit dem gemessenen Grund. Ohne Daten bleibt sie
/// zu.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  Future<LumoAppState> open(WidgetTester tester, {required bool practised}) async {
    await tester.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late final LumoAppState app;
    await tester.runAsync(() async {
      app = LumoAppState();
      app.update(app.state.copyWith(childName: 'Mia', grade: 2));
      app.updateSettings(const AppSettings(
          reduceAnimations: true,
          calmMode: true,
          voiceEnabled: false,
          soundEnabled: false,
          autoReadEnabled: false));
      await SettingsRepository.save(app.state.settings);
      if (practised) {
        final owner = await app.captureLearningProfile();
        await app.attemptLog.appendAll([
          for (var i = 0; i < 10; i++)
            Attempt(
                id: 'plus100-$i',
                studentId: owner.logStudentId,
                subject: 'Mathematik',
                unit: 'Plus bis 100',
                competency: 'Addition ohne Zehnerübergang',
                correct: i != 3,
                at: DateTime.utc(2026, 11, 20, 9, i),
                prompt: '${20 + i} + 13 = ?'),
        ]);
      }
    });
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GamesContent(appState: app))));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    final extra = find.text('Zusätzliche Spielmodi');
    await tester.scrollUntilVisible(extra, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(extra);
    await tester.pump(const Duration(milliseconds: 400));
    return app;
  }

  testWidgets('sicher geübtes Plus bis 100 öffnet Level 39 mit Begründung',
      (tester) async {
    await open(tester, practised: true);
    final title = find.text('Plus bis 100');
    for (var i = 0; i < 40 && tester.getCenter(title).dy > 760; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 600));
    final note = find.byKey(const ValueKey('level-evidence-note'));
    expect(note, findsOneWidget);
    expect(tester.widget<Text>(note).data,
        contains('„Plus bis 100“ beim Üben schon sicher kannst: 9 von 10'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ohne Übungsdaten bleibt Level 39 gesperrt', (tester) async {
    await open(tester, practised: false);
    expect(find.text('Plus bis 100', skipOffstage: false), findsNothing);
    expect(find.byKey(const ValueKey('level-evidence-note')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
