import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lumo_lernen/app/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';

void main() {
  testWidgets('library real runtime phone and Fold', (tester) async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final stored = [
      for (final title in [
        'Das Geheimnis der Sterneninsel',
        'Lumo und der mutige Waldfuchs'
      ])
        StoredStory(
            id: title,
            story: LumoStory(
                title: title,
                heroName: 'Lumo',
                location: 'Sterneninsel',
                theme: 'Freundschaft',
                gradeLevel: 2,
                newWords: const [
                  'Sternenlicht',
                  'Freundschaft'
                ],
                pages: const [
                  LumoStoryPage(
                      pageNum: 1,
                      text:
                          'Lumo öffnet sein leuchtendes Buch. Zwischen den Seiten entdeckt er eine kleine Sterneninsel.',
                      imagePrompt: '')
                ]),
            createdAt: DateTime(2026, 10, 14),
            timesRead: 2,
            isFavorite: false)
    ];
    SharedPreferences.setMockInitialValues({
      'lumo_story_library_v1':
          jsonEncode(stored.map((s) => s.toJson()).toList())
    });
    await tester.runAsync(() => LumoStoryLibrary.instance.load());
    final state = LumoAppState();
    addTearDown(state.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final target in [
      ('phone', const Size(360, 800)),
      ('fold', const Size(967, 805)),
      ('cover-large', const Size(280, 700)),
      ('landscape', const Size(640, 360))
    ]) {
      await tester.binding.setSurfaceSize(target.$2);
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: MediaQuery(
              data: MediaQueryData(
                  size: target.$2,
                  textScaler:
                      TextScaler.linear(target.$1 == 'cover-large' ? 1.6 : 1)),
              child: RepaintBoundary(
                  key: const ValueKey('capture'),
                  child: LumoStoryLibraryScreen(
                      key: ValueKey(target.$1), appState: state)))));
      await tester.pump();
      await tester.runAsync(() async {
        for (final w in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(w.image, tester.element(find.byWidget(w)));
        }
      });
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull, reason: target.$1);
      final folder = Platform.environment['LUMO_LIBRARY_CAPTURE'];
      if (folder != null) {
        final render = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture')));
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final f = File('$folder/library-${target.$1}.png');
          await f.parent.create(recursive: true);
          await f.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      // A real preview tap must reveal the saved page, without marking it read.
      final before = jsonEncode(
          LumoStoryLibrary.instance.all.map((s) => s.toJson()).toList());
      final preview = find.byKey(ValueKey('story-preview-${stored.first.id}'));
      await tester.scrollUntilVisible(preview, 220,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('story-library-scroll')),
                matching: find.byType(Scrollable),
              )
              .first);
      await tester.ensureVisible(preview);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(preview);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byKey(const ValueKey('story-preview-text')), findsOneWidget);
      expect(
          find.textContaining('Zwischen den Seiten entdeckt'), findsOneWidget);
      expect(
          jsonEncode(
              LumoStoryLibrary.instance.all.map((s) => s.toJson()).toList()),
          before);
      // Back is reachable even when large text makes the page itself scroll.
      Navigator.of(
              tester.element(find.byKey(const ValueKey('story-preview-text'))))
          .pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byKey(const ValueKey('story-preview-text')), findsNothing);
      expect(tester.takeException(), isNull, reason: 'preview ${target.$1}');
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('lumo_story_library_v1'),
            jsonEncode(stored.map((s) => s.toJson()).toList()));
      });
      await tester.pumpWidget(const SizedBox());
    }
  });
}
