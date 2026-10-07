import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_free_companion.dart';
import 'package:lumo_lernen/widgets/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() async {
    // Initialize singleton futures in the real test zone. A wallet queue
    // created inside testWidgets retains that test's FakeAsync scheduler and
    // cannot service a later widget test after its scheduler has stopped.
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });

  Future<void> settleWork(WidgetTester tester) async {
    // The home scene has looping decorative animations, so do not wait for an
    // intentionally never-idle renderer with pumpAndSettle.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('profile displays the active school grade from the real shell',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixtureDate = DateTime(2026, 10, 3);
    for (var grade = 1; grade <= 4; grade++) {
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: AppShell(
          profile: UserProfile(
            id: 'grade-fixture-$grade',
            name: 'Testfuchs',
            age: grade + 5,
            grade: grade,
            createdAt: fixtureDate,
            lastActiveAt: fixtureDate,
          ),
          initialSection: LumoSection.profile,
        ),
      ));
      await settleWork(tester);
      final profile = find.byType(ProfileScreen);
      expect(profile, findsOneWidget);
      expect(tester.widget<ProfileScreen>(profile).grade, grade);
      expect(find.descendant(of: profile, matching: find.text('Klasse $grade')),
          findsOneWidget);
      for (var other = 1; other <= 4; other++) {
        if (other != grade) {
          expect(
              find.descendant(
                  of: profile, matching: find.text('Klasse $other')),
              findsNothing);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
      'actual shell stays usable while resizing from phone to Fold and narrow phone',
      (tester) async {
    for (final size in [
      const Size(360, 740),
      const Size(840, 560),
      const Size(941, 1672),
      const Size(280, 640)
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: const RepaintBoundary(
              key: ValueKey('shell-capture'), child: AppShell())));
      await settleWork(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(LumoFreeCompanion), findsOneWidget);
      final floor =
          tester.getRect(find.byKey(const ValueKey('lumo-companion-floor')));
      final fox = tester.getRect(find.byKey(const ValueKey('lumo-fox-button')));
      expect(floor.contains(fox.topLeft), isTrue);
      expect(floor.contains(fox.bottomRight - const Offset(.1, .1)), isTrue);
      expect(floor.top, greaterThan(200));
      final dock = find.byKey(const ValueKey('lumo-help-dock'));
      if (dock.evaluate().isNotEmpty) {
        final content = find.byKey(const PageStorageKey('lumo-home-scroll'));
        expect(tester.getRect(content).bottom,
            lessThanOrEqualTo(tester.getRect(dock).top),
            reason:
                'The fox has reserved space and cannot cover learning or game controls.');
      }
      if (Platform.environment['LUMO_CAPTURE_SHELL'] == '1') {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('shell-capture')));
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('/tmp/lumo-shell-${size.width.toInt()}x${size.height.toInt()}.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
          image.dispose();
        });
      }
      // Child action area responds, and its modal leaves existing home intact.
      await tester.tap(find.byKey(const ValueKey('lumo-fox-button')));
      await settleWork(tester);
      expect(find.text('Was möchtest du machen?'), findsOneWidget);
      await tester.tap(find.text('Diese Seite erklären'));
      await settleWork(tester);
      expect(find.text('So funktioniert diese Seite'), findsOneWidget);
      await tester.tap(find.text('Alles klar'));
      await settleWork(tester);
      if (size.width == 360) {
        final explainHome = find.byKey(const ValueKey('home-explanation'));
        await tester.scrollUntilVisible(
          explainHome,
          150,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('lumo-home-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await settleWork(tester);
        await Scrollable.ensureVisible(
          tester.element(explainHome),
          alignment: 0.5,
        );
        await tester.drag(
          find.byKey(const PageStorageKey('lumo-home-scroll')),
          const Offset(0, 80),
        );
        await settleWork(tester);
        await tester.tap(explainHome);
        await settleWork(tester);
        expect(find.text('So helfe ich dir'), findsOneWidget);
        await tester.tap(find.text('Alles klar'));
        await settleWork(tester);
      }
      // The persistent navigation is not covered by the fox floor.
      await tester.tap(find.text('Lernen').last);
      await settleWork(tester);
      expect(find.byType(LumoAkademieScreen), findsOneWidget);
      final layoutError = tester.takeException();
      expect(layoutError, isNull, reason: 'learning screen at $size');
      // Auf den Zielbild-Seiten steht Lumo als kleiner Fuchs in der Szene.
      expect(find.byType(LumoFreeCompanion), findsOneWidget);
      await tester.tap(find.text('Start').last);
      await settleWork(tester);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
    expect(tester.takeException(), isNull);
  });
}
