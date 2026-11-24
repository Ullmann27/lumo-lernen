import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/home/widgets/lumo_subject_register.dart';
import 'package:lumo_lernen/features/onboarding/lumo_intro_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Register zeigt fünf gleich große Fach-Kacheln >= 48 dp',
      (tester) async {
    final opened = <String>[];
    var games = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LumoSubjectRegister(
            onSubject: opened.add,
            onGames: () => games++,
          ),
        ),
      ),
    ));
    final ids = [
      'Mathematik',
      'Deutsch',
      'Englisch',
      'Sachunterricht',
      'games'
    ];
    Size? first;
    for (final id in ids) {
      final f = find.byKey(ValueKey('home-register-$id'));
      expect(f, findsOneWidget);
      final size = tester.getSize(f);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      first ??= size;
      expect(size, first, reason: 'einheitliche Kachelgröße');
    }
    expect(find.text('Sachkunde'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-register-Mathematik')));
    await tester
        .tap(find.byKey(const ValueKey('home-register-Sachunterricht')));
    await tester.tap(find.byKey(const ValueKey('home-register-games')));
    expect(opened, ['Mathematik', 'Sachunterricht']);
    expect(games, 1);
  });

  testWidgets('Intro lässt sich durchblättern, überspringen und merkt sich das',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => LumoIntroTour.show(context, speak: false),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('lumo-intro-tour')), findsOneWidget);
    expect(find.text(LumoIntroTour.steps.first.title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('intro-next')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(LumoIntroTour.steps[1].title), findsOneWidget);
    final skip = find.byKey(const ValueKey('intro-skip'));
    expect(tester.getSize(skip).height, greaterThanOrEqualTo(48));
    await tester.tap(skip);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('lumo-intro-tour')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(LumoIntroTour.seenKey), isTrue);
  });
}
