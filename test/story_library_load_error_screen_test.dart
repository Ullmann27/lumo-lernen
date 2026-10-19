import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';

void main() {
  testWidgets('Damaged stories show retry, preserve bytes, and recover',
      (tester) async {
    const raw = '{"damaged": [original story bytes';
    SharedPreferences.setMockInitialValues({'lumo_story_library_v1': raw});
    await tester.binding.setSurfaceSize(const Size(412, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(
      home: LumoStoryLibraryScreen(appState: state),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Bücherei kann gerade nicht geladen werden'),
        findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_story_library_v1'), raw);
    expect(find.text('Neue Geschichte!'), findsNothing,
        reason: 'An unreadable archive may never be silently overwritten');
    expect(tester.takeException(), isNull);

    await prefs.setString('lumo_story_library_v1', '[]');
    await tester.tap(find.byKey(const ValueKey('lumo-library-retry-load')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('LUMOS STERNENBIBLIOTHEK'), findsOneWidget);
    expect(find.textContaining('Bücherei kann gerade nicht geladen werden'),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
