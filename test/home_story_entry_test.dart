import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home opens grade-filtered Geschichten Lesen & verstehen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(grade: 2));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeContent(appState: app, onSection: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    final discover =
        find.byKey(const PageStorageKey<String>('home-discover'));
    await tester.scrollUntilVisible(
      discover,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(discover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final stories =
        find.byKey(const ValueKey('home-discover-stories'));
    expect(stories, findsOneWidget);
    await tester.dragUntilVisible(
      stories,
      find.byType(Scrollable).first,
      const Offset(0, -260),
    );
    await tester.pump();
    await tester.tap(stories);
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(LumoStoryLibraryScreen), findsOneWidget);
    expect(find.text('Geschichten · Lesen & verstehen'), findsOneWidget);
    expect(find.textContaining('2. Klasse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
