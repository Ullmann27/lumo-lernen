// Erzeugt Bildschirmfotos der Lehrkräfte-Demo (keine Prüfung, nur Bilder):
// flutter test --update-goldens tool/teacher_demo_shots/teacher_demo_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_class_data.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_homework.dart';
import 'package:lumo_lernen/features/teacher_demo/teacher_demo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/box/sdk/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']) {
    roboto.addFont(Future.value(ByteData.sublistView(File('$dir/$f').readAsBytesSync())));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(
        ByteData.sublistView(File('$dir/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

void main() {
  final now = DateTime(2026, 11, 24, 12);

  Widget host(Widget child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: app!,
        ),
        home: child,
      );

  setUpAll(_loadFonts);

  Future<void> phone(WidgetTester tester, double height) async {
    tester.view.physicalSize = Size(1080, height * 2.7);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
  }

  testWidgets('Klassenübersicht', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await phone(tester, 800);
    await tester.pumpWidget(host(TeacherDemoScreen(now: now)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/01_klassenuebersicht.png'));
  });

  testWidgets('Auswertung Demo-Kind 1', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await phone(tester, 2600);
    await tester.pumpWidget(host(DemoChildDetailScreen(
        report: DemoChildReport.build(demoChildren.first, now: now))));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/02_auswertung_demo_kind_1.png'));
  });

  testWidgets('Hausaufgaben mit Auswertung', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = DemoHomeworkStore();
    final hw = DemoHomework(
      id: 'hw-shot',
      subject: 'Mathematik',
      unit: 'Minus bis 100',
      count: 6,
      due: now.add(const Duration(days: 2)),
      note: 'Denk an den Zehnerübergang!',
      studentIds: [demoChildren[0].id, demoChildren[1].id],
      createdAt: now,
    );
    await store.add(hw);
    final tasks = hw.tasksFor(demoChildren[0].id);
    await store.recordResult(hw.id, demoChildren[0].id, [
      for (var i = 0; i < tasks.length; i++)
        HomeworkItemResult(
          prompt: tasks[i].prompt,
          expected: tasks[i].answer,
          given: i == 2 || i == 4
              ? tasks[i].choices.firstWhere((c) => c != tasks[i].answer)
              : tasks[i].answer,
          durationMs: 5000 + i * 1300,
          hintUsed: i == 4,
        ),
    ]);
    await phone(tester, 1500);
    await tester.pumpWidget(host(TeacherDemoScreen(now: now, store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hausaufgaben'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/03_hausaufgaben.png'));
  });
}
