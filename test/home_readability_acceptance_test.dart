import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

// Acceptance evidence for the Home implementation merged in PR #178.
// This does not mandate a column count or shrink the user's chosen text scale.
// No Android, exact font parity, screenshot, or device-FPS approval is implied.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Match the existing home_navigation_progress_test.dart fixture. Ahem's
    // square glyphs must not silently substitute for real text measurement.
    final fontDirectory = Directory(
      '${File(Platform.resolvedExecutable).parent.parent.parent.path}'
      '/material_fonts',
    );
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final file = File('${fontDirectory.path}/${entry.value}');
      if (!file.existsSync()) {
        throw StateError('Readability font fixture missing: ${file.path}');
      }
      final loader = FontLoader(entry.key);
      loader.addFont(
        Future.value(ByteData.sublistView(await file.readAsBytes())),
      );
      await loader.load();
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RewardWalletRepository.instance.reset();
  });

  final cases = <({Size size, double scale})>[
    (size: const Size(320, 720), scale: 1.0),
    (size: const Size(360, 800), scale: 1.0),
    (size: const Size(393, 852), scale: 1.0),
    (size: const Size(412, 915), scale: 1.0),
    (size: const Size(600, 960), scale: 1.0),
    (size: const Size(768, 1024), scale: 1.0),
    (size: const Size(840, 720), scale: 1.0),
    (size: const Size(1024, 768), scale: 1.0),
    (size: const Size(1280, 800), scale: 1.0),
    (size: const Size(393, 852), scale: 1.4),
    (size: const Size(840, 720), scale: 1.4),
  ];
  const routes = <String, LumoSection>{
    'Lernen': LumoSection.learn,
    'Spielen': LumoSection.games,
    'Tests': LumoSection.tests,
    'Belohnungen': LumoSection.rewards,
  };

  for (final sample in cases) {
    final caseName = '${sample.size.width.toInt()}x'
        '${sample.size.height.toInt()} text=${sample.scale}';
    testWidgets('Home primary labels remain readable: $caseName', (tester) async {
      final state = LumoAppState();
      final destinations = <LumoSection>[];
      state.update(state.state.copyWith(
        childName: 'Mia',
        settings: const AppSettings(
          reduceAnimations: true,
          voiceEnabled: false,
          autoReadEnabled: false,
          aiProxyEnabled: false,
        ),
      ));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(sample.size);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: sample.size,
            devicePixelRatio: 1,
            disableAnimations: true,
            textScaler: TextScaler.linear(sample.scale),
          ),
          child: Scaffold(
            body: HomeContent(
              appState: state,
              onSection: destinations.add,
            ),
          ),
        ),
      ));
      await tester.pump();

      final problems = <String>[];
      void collectLayoutErrors() {
        Object? error;
        while ((error = tester.takeException()) != null) {
          problems.add('Flutter layout/runtime error: $error');
        }
      }

      collectLayoutErrors();
      for (final entry in routes.entries) {
        final tile = find.byWidgetPredicate(
          (widget) => widget is LumoColorTile && widget.title == entry.key,
        );
        expect(tile, findsOneWidget, reason: '$caseName / ${entry.key}');
        await tester.ensureVisible(tile);
        await tester.pump();
        collectLayoutErrors();

        final label = find.descendant(
          of: tile,
          matching: find.byWidgetPredicate(
            (widget) => widget is RichText &&
                widget.text.toPlainText() == entry.key,
          ),
        );
        expect(label, findsOneWidget, reason: '$caseName / ${entry.key}');
        final paragraph = tester.renderObject<RenderParagraph>(label);
        final size = tester.getSize(tile);
        if (paragraph.didExceedMaxLines) {
          problems.add('${entry.key}: title truncated; '
              'text width=${paragraph.size.width.toStringAsFixed(2)}, '
              'tile=${size.width.toStringAsFixed(2)}x'
              '${size.height.toStringAsFixed(2)}, '
              'maxLines=${paragraph.maxLines}');
        }
        if (size.width < 44 || size.height < 44) {
          problems.add('${entry.key}: touch target smaller than 44 dp: $size');
        }
        // An invisible or clipped label must not be hidden by the fact that a
        // tap still fires. Both rendering and the original callback are tested.
        final before = destinations.length;
        await tester.tap(tile);
        await tester.pump();
        expect(destinations.length, before + 1,
            reason: '$caseName / ${entry.key}: route not invoked once');
        expect(destinations.last, entry.value);
        collectLayoutErrors();
      }
      // ignore: avoid_print
      print('HOME_READABILITY $caseName: '
          '${problems.isEmpty ? "PASS" : problems.join(" | ")}');
      expect(problems, isEmpty,
          reason: 'Primary labels must remain readable without ellipses; '
              'see docs/RESPONSIVE_DEVICE_MATRIX.md. $caseName');
    });
  }
}
