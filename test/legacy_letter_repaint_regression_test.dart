import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/letter_writing_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

final _ink = find.byWidgetPredicate((widget) =>
    widget is CustomPaint &&
    widget.painter.runtimeType.toString() == '_StrokesPainter');

CustomPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_ink).painter!;

List<List<Offset>> _strokes(CustomPainter painter) =>
    (painter as dynamic).strokes as List<List<Offset>>;

Future<void> _openActualPracticeRoute(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  addTearDown(app.dispose);
  const topic = LearningTopic(
    id: 'd1_buchstaben_alle',
    title: 'Alle Buchstaben A-Z',
    icon: Icons.edit_rounded,
    gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    shortDesc: 'Alle 26 Buchstaben üben',
    isWriting: true,
    writingChars: ['A', 'B'],
  );
  const subject = LearningSubject(
    id: 'deutsch1',
    name: 'Deutsch',
    color: Color(0xFF8B5CF6),
    icon: Icons.menu_book_rounded,
    topics: [topic],
  );
  await tester.pumpWidget(MaterialApp(
    home: LetterWritingScreen(appState: app, topic: topic, subject: subject),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Jetzt schreiben üben'));
  await tester.pumpAndSettle();
  expect(_ink, findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<TestGesture> _beginStroke(
  WidgetTester tester, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
  int? pointer,
}) async {
  final start = tester.getRect(_ink).topLeft + const Offset(90, 90);
  final gesture = await tester.startGesture(
    start,
    kind: kind,
    pointer: pointer,
    buttons: kPrimaryButton,
  );
  await gesture.moveTo(start + const Offset(35, 40));
  await tester.pump();
  await gesture.moveTo(start + const Offset(70, 80));
  await tester.pump();
  return gesture;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Layout must use the bundled production font, not the wide Ahem test font.
    final loader = FontLoader('Nunito');
    for (final variant in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      loader.addFont(File('assets/fonts/Nunito-$variant.ttf')
          .readAsBytes()
          .then(ByteData.sublistView));
    }
    await loader.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets('actual legacy practice route has no scrollable ancestor',
      (tester) async {
    await _openActualPracticeRoute(tester);
    expect(find.ancestor(of: _ink, matching: find.byType(Scrollable)),
        findsNothing);
    expect(find.text('Löschen'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('starting actual legacy ink requests a repaint', (tester) async {
    await _openActualPracticeRoute(tester);
    final before = _painter(tester);
    final gesture = await _beginStroke(tester);
    final after = _painter(tester);
    expect(identical(before, after), isFalse);
    expect(_strokes(after), hasLength(1));
    expect(_strokes(after).single.length, greaterThan(1));
    final bool shouldRepaint = after.shouldRepaint(before);
    await gesture.up();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(shouldRepaint, isTrue,
        reason: 'A new stroke must invalidate the old empty ink painting.');
  });

  testWidgets('extending actual legacy ink requests a repaint', (tester) async {
    await _openActualPracticeRoute(tester);
    final gesture = await _beginStroke(tester);
    final before = _painter(tester);
    final previousPoints = _strokes(before).single.length;
    await gesture.moveBy(const Offset(100, 110));
    await tester.pump();
    final after = _painter(tester);
    expect(identical(before, after), isFalse);
    expect(_strokes(after).single.length, greaterThan(previousPoints));
    final bool shouldRepaint = after.shouldRepaint(before);
    await gesture.up();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(shouldRepaint, isTrue,
        reason:
            'New points must invalidate the previously painted shorter line.');
  });

  testWidgets('clearing actual legacy ink requests a repaint', (tester) async {
    await _openActualPracticeRoute(tester);
    final gesture = await _beginStroke(tester);
    await gesture.up();
    await tester.pump();
    final before = _painter(tester);
    expect(_strokes(before), isNotEmpty);
    await tester.tap(find.text('Löschen'));
    await tester.pump();
    final after = _painter(tester);
    expect(identical(before, after), isFalse);
    expect(_strokes(after), isEmpty);
    final bool shouldRepaint = after.shouldRepaint(before);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(shouldRepaint, isTrue,
        reason:
            'Clearing all ink must invalidate the previous nonempty painting.');
  });

  testWidgets(
      'cancel discards only active stylus ink and ignores a second touch',
      (tester) async {
    await _openActualPracticeRoute(tester);
    final first = await _beginStroke(tester);
    await first.up();
    await tester.pump();
    final completed = List<Offset>.of(_strokes(_painter(tester)).single);

    final pen =
        await _beginStroke(tester, kind: PointerDeviceKind.stylus, pointer: 50);
    final pointsBeforePalm = _strokes(_painter(tester)).last.length;
    final palm = await tester.startGesture(
        tester.getCenter(_ink) + const Offset(100, 0),
        pointer: 51);
    await palm.moveBy(const Offset(60, 40));
    await palm.up();
    await tester.pump();
    expect(_strokes(_painter(tester)), hasLength(2));
    expect(_strokes(_painter(tester)).last.length, pointsBeforePalm);

    final beforeCancel = _painter(tester);
    await pen.cancel();
    await tester.pump();
    final afterCancel = _painter(tester);
    expect(_strokes(afterCancel), [completed]);
    expect(afterCancel.shouldRepaint(beforeCancel), isTrue);

    final next = await _beginStroke(tester, pointer: 52);
    await next.up();
    await tester.pump();
    expect(_strokes(_painter(tester)), hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('actual legacy canvas accepts primary mouse ink', (tester) async {
    await _openActualPracticeRoute(tester);
    final mouse = await _beginStroke(tester, kind: PointerDeviceKind.mouse);
    await mouse.up();
    await tester.pump();
    expect(_strokes(_painter(tester)), hasLength(1));
    expect(_strokes(_painter(tester)).single.length, greaterThan(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stylus movement stays within the visible legacy canvas',
      (tester) async {
    await _openActualPracticeRoute(tester);
    final rect = tester.getRect(_ink);
    final pen = await _beginStroke(tester, kind: PointerDeviceKind.stylus);
    await pen.moveTo(rect.topLeft - const Offset(40, 60));
    await tester.pump();
    await pen.moveTo(rect.bottomRight + const Offset(40, 60));
    await pen.up();
    await tester.pump();
    final points = _strokes(_painter(tester)).single;
    expect(points, contains(Offset.zero));
    expect(points, contains(Offset(rect.width, rect.height)));
    for (final point in points) {
      expect(point.dx, inInclusiveRange(0, rect.width));
      expect(point.dy, inInclusiveRange(0, rect.height));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final cancel in [false, true]) {
    testWidgets(
        'leaving legacy canvas during ink safely ignores later '
        '${cancel ? 'cancel' : 'move and up'}', (tester) async {
      await _openActualPracticeRoute(tester);
      final pen = await _beginStroke(tester, kind: PointerDeviceKind.stylus);
      expect(_strokes(_painter(tester)), isNotEmpty);
      Navigator.of(tester.element(_ink)).pop(false);
      await tester.pumpAndSettle();
      expect(_ink, findsNothing);
      if (cancel) {
        await pen.cancel();
      } else {
        await pen.moveBy(const Offset(20, 20));
        await pen.up();
      }
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Jetzt schreiben üben'));
      await tester.pumpAndSettle();
      expect(_strokes(_painter(tester)), isEmpty);
      final next = await _beginStroke(tester, kind: PointerDeviceKind.stylus);
      await next.up();
      await tester.pump();
      expect(_strokes(_painter(tester)), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final size in const [
    Size(320, 740),
    Size(690, 829),
    Size(915, 412),
  ]) {
    testWidgets('resizing actual legacy canvas to $size cancels active ink',
        (tester) async {
      await _openActualPracticeRoute(tester);
      final pen = await _beginStroke(tester, kind: PointerDeviceKind.stylus);
      expect(_strokes(_painter(tester)), isNotEmpty);
      await tester.binding.setSurfaceSize(size);
      await tester.pump();
      await pen.up();
      await tester.pump();
      expect(_strokes(_painter(tester)), isEmpty,
          reason: 'An interrupted stroke must not survive a changed canvas.');
      expect(tester.takeException(), isNull);
      for (final label in ['Löschen', 'Fertig & Weiter']) {
        final target = find
            .ancestor(
                of: find.text(label), matching: find.byType(GestureDetector))
            .first;
        final targetSize = tester.getSize(target);
        expect(targetSize.width, greaterThanOrEqualTo(48));
        expect(targetSize.height, greaterThanOrEqualTo(48));
      }
      final next = await _beginStroke(tester);
      await next.up();
      await tester.pump();
      expect(_strokes(_painter(tester)), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
