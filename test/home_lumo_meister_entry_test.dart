import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home exposes Lumo-Meister and opens the real 20-question show',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = LumoAppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeContent(
            appState: appState,
            onSection: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final discover =
        find.byKey(const PageStorageKey<String>('home-discover'));
    if (discover.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        discover,
        350,
        scrollable: find.byType(Scrollable).first,
      );
    }
    expect(discover, findsOneWidget);

    await tester.tap(discover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final meister = find.text('Wer wird Lumo-Meister?');
    expect(meister, findsOneWidget);
    await tester.scrollUntilVisible(
      meister,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(meister);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(QuizShowContent), findsOneWidget);
    expect(find.text('Wer wird Lumo-Meister?'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
