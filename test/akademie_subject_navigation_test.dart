import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Sachkunde in Klasse 2 reveals its real topics after tapping',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(grade: 2));

    await tester.pumpWidget(
      MaterialApp(
        home: LumoAkademieScreen(appState: appState),
      ),
    );
    await tester.pump();

    final sachkunde =
        find.byKey(const ValueKey('learning-area-sachkunde'));
    await tester.ensureVisible(sachkunde);
    await tester.tap(sachkunde);
    await tester.pumpAndSettle();

    expect(find.text('Jahreszeiten'), findsOneWidget);
    expect(find.text('Wetter'), findsOneWidget);
    expect(find.text('Verkehr'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
