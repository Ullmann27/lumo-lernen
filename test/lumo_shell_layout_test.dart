import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_free_companion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Nunito is not bundled by the app; Android uses its system fallback.
    // Load the SDK's Roboto fallback for realistic widths instead of Ahem.
    final folder =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf'
    }.entries) {
      final file = File('$folder/${entry.value}');
      if (file.existsSync()) {
        final font = FontLoader(entry.key);
        font.addFont(
            Future.value(ByteData.sublistView(await file.readAsBytes())));
        await font.load();
      }
    }
  });

  Future<void> settleWork(WidgetTester tester) async {
    // The home scene has looping decorative animations, so do not wait for an
    // intentionally never-idle renderer with pumpAndSettle.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets(
      'actual shell stays usable while resizing from phone to Fold and narrow phone',
      (tester) async {
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
    for (final size in [
      const Size(360, 740),
      const Size(840, 560),
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
        await tester.tap(find.text("Lumo zeigt's dir"));
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
