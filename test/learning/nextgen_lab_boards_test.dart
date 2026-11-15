import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/lab/learning_manipulatives.dart';
import 'package:lumo_lernen/widgets/design/lumo_task_object_art.dart';

import '../helpers/lumo_capture.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double width = 412,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 1000),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF071D35),
          body: RepaintBoundary(
            key: const ValueKey('nextgen-board-capture'),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('calm token editing bypasses AnimatedSize and keeps the live row',
      (tester) async {
    var selected = <int>[];
    await _show(
        tester,
        StatefulBuilder(
            builder: (context, setState) => LearningTokenWorkbench(
                tokens: const ['ne', 'Ba', 'na'],
                selected: selected,
                reduceMotion: true,
                onChanged: (next) => setState(() => selected = next))));
    expect(find.byType(AnimatedSize), findsNothing);
    for (final index in [1, 2, 0]) {
      await tester.tap(find.byKey(ValueKey('token-bank-$index')));
      await tester.pump();
    }
    expect(selected, [1, 2, 0]);
    expect(find.byKey(const ValueKey('token-work-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('token-work-2')));
    await tester.pump();
    expect(selected, [1, 0]);
    expect(find.byKey(const ValueKey('token-bank-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bridge movement limit keeps the remainder for the next learning step',
      (tester) async {
    var moved = 0;
    var calls = 0;
    await _show(
        tester,
        StatefulBuilder(
            builder: (context, setState) => QuantityBridgeBoard(
                start: 8,
                addend: 5,
                moved: moved,
                maxMoved: 2,
                onChanged: (next) {
                  calls++;
                  setState(() => moved = next);
                })));
    for (final index in [0, 1]) {
      await tester.tap(find.byKey(ValueKey('quantity-bank-$index')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('quantity-bank-2')));
    await tester.tap(find.byKey(const ValueKey('quantity-add')));
    await tester.pumpAndSettle();
    expect(moved, 2);
    expect(calls, 2);
    for (var i = 2; i < 5; i++) {
      expect(find.byKey(ValueKey('quantity-bank-$i')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('quantity-remove')));
    await tester.pumpAndSettle();
    expect(moved, 1);
    await tester.tap(find.byKey(const ValueKey('quantity-bank-1')));
    await tester.pumpAndSettle();
    expect(moved, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('8 + 5 moves exactly two and keeps the other three in reserve', (
    tester,
  ) async {
    var moved = 0;
    final focus = <String>[];
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => QuantityBridgeBoard(
          start: 8,
          addend: 5,
          moved: moved,
          reveal: true,
          onObjectFocus: focus.add,
          onChanged: (value) => setState(() => moved = value),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('ten_frame')), findsOneWidget);
    expect(find.byKey(const ValueKey('addend')), findsOneWidget);
    expect(find.text('Bis 10 fehlen 2.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quantity-bank-0')));
    await tester.pumpAndSettle();
    expect(find.text('Jetzt fehlen noch 1 bis 10.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quantity-bank-1')));
    await tester.pumpAndSettle();
    expect(moved, 2);
    expect(focus, ['reserve-0', 'reserve-1']);
    expect(find.text('Das Zehnerfeld ist voll: 10.'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      expect(find.byKey(ValueKey('quantity-placed-$i')), findsOneWidget);
      expect(find.byKey(ValueKey('quantity-bank-$i')), findsNothing);
    }
    for (var i = 2; i < 5; i++) {
      expect(find.byKey(ValueKey('quantity-bank-$i')), findsOneWidget);
    }
    expect(
      find.textContaining('= 13'),
      findsNothing,
      reason: 'The board never submits or declares a computed answer.',
    );
    await tester.tap(find.byKey(const ValueKey('quantity-placed-1')));
    await tester.pumpAndSettle();
    expect(moved, 1);
    expect(focus.last, 'ten-slot-9');
  });

  for (final width in [240.0, 320.0, 344.0, 412.0, 840.0]) {
    testWidgets('all ten slots remain visible and >=48dp at width $width', (
      tester,
    ) async {
      await _show(
        tester,
        QuantityBridgeBoard(start: 8, addend: 5, moved: 2, onChanged: (_) {}),
        width: width,
        scale: 1.4,
      );
      final rects = List.generate(
        10,
        (i) => tester.getRect(find.byKey(ValueKey('ten-slot-$i'))),
      );
      for (final rect in rects) {
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Banane has the actual asset and exactly three dynamic syllables',
    (tester) async {
      final reads = <int>[];
      var wholeReads = 0;
      await _show(
        tester,
        SyllableLearningBoard(
          word: 'Banane',
          syllables: const ['Ba', 'na', 'ne'],
          activeIndex: 1,
          onReadSegment: reads.add,
          onReadWord: () => wholeReads++,
        ),
      );
      final picture = tester.widget<LumoTaskObjectArt>(
        find.byKey(const ValueKey('syllable-word-picture')),
      );
      expect(picture.name, 'Banane');
      expect(
        LumoTaskObjectArt.assetForName(picture.name),
        endsWith('/banane.webp'),
      );
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('syllable_$i')), findsOneWidget);
        final size = tester.getSize(
          find.byKey(ValueKey('syllable-segment-$i')),
        );
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      await tester.tap(find.byKey(const ValueKey('syllable-segment-2')));
      await tester.tap(find.byKey(const ValueKey('syllable-read-word')));
      expect(reads, [2]);
      expect(wholeReads, 1);
      await tester.pump(const Duration(seconds: 3));
      final active = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byKey(const ValueKey('syllable-segment-1')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(
        active.properties.selected,
        isTrue,
        reason: 'Only the speech owner changes focus, never a visual timer.',
      );
    },
  );

  testWidgets('invalid syllable data does not fabricate segmentation', (
    tester,
  ) async {
    await _show(
      tester,
      const SyllableLearningBoard(word: 'Banane', syllables: ['Ba', 'ne']),
    );
    expect(find.text('Banane'), findsOneWidget);
    expect(find.byKey(const ValueKey('syllable-segment-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pattern hint marks repeated groups without answering', (
    tester,
  ) async {
    int? selected;
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => PatternBuildBoard(
          sequence: const ['Kreis', 'Dreieck', 'Kreis', 'Dreieck', 'Kreis'],
          options: const ['Kreis', 'Dreieck', 'Quadrat'],
          selected: selected,
          revealGroup: true,
          onChanged: (value) => setState(() => selected = value),
        ),
      ),
      width: 344,
      scale: 1.4,
    );
    expect(find.byKey(const ValueKey('pattern_group')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('pattern-group-$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('pattern_next')), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(selected, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('pattern-option-2')));
    await tester.tap(find.byKey(const ValueKey('pattern-option-2')));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(
      find.text('?'),
      findsOneWidget,
      reason: 'A candidate is not an evaluated answer.',
    );
    expect(find.textContaining('Richtig'), findsNothing);
    expect(find.textContaining('Falsch'), findsNothing);
    for (var i = 0; i < 3; i++) {
      final size = tester.getSize(find.byKey(ValueKey('pattern-option-$i')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pattern reset, disable and unknown shape do not invent answers',
    (tester) async {
      var calls = 0;
      await _show(
        tester,
        PatternBuildBoard(
          sequence: const ['Kreis', 'Dreieck', 'Kreis'],
          options: const ['Dreieck', 'Herz'],
          selected: 1,
          enabled: false,
          onChanged: (_) => calls++,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('pattern-option-0')));
      expect(calls, 0);
      expect(
        find.byIcon(Icons.help_outline_rounded),
        findsOneWidget,
        reason: 'An unsupported shape must not be drawn as a square.',
      );
      await _show(
        tester,
        PatternBuildBoard(
          sequence: const ['Dreieck', 'Kreis', 'Dreieck'],
          options: const ['Kreis', 'Dreieck'],
          onChanged: (_) => calls++,
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('real Flutter board captures for the joined examples', (
    tester,
  ) async {
    final directory = Platform.environment['LUMO_NEXTGEN_BOARD_CAPTURES'];
    if (directory == null) return;
    await loadLumoCaptureFonts();
    final boards = <String, Widget>{
      'bridge-8-plus-5': QuantityBridgeBoard(
        start: 8,
        addend: 5,
        moved: 2,
        reveal: true,
        onChanged: (_) {},
      ),
      'banane-syllables': SyllableLearningBoard(
        word: 'Banane',
        syllables: const ['Ba', 'na', 'ne'],
        activeIndex: 1,
        onReadSegment: (_) {},
        onReadWord: () {},
      ),
      'pattern-hint': PatternBuildBoard(
        sequence: const ['Kreis', 'Dreieck', 'Kreis', 'Dreieck', 'Kreis'],
        options: const ['Kreis', 'Dreieck', 'Quadrat'],
        revealGroup: true,
        onChanged: (_) {},
      ),
    };
    for (final entry in boards.entries) {
      await _show(tester, entry.value);
      await captureLumoBoundary(
        tester,
        const ValueKey('nextgen-board-capture'),
        '$directory/${entry.key}.png',
      );
      expect(tester.takeException(), isNull);
    }
  });
}
