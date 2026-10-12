import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/deutsch/lumo_deutsch_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_setup_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  test('jede Volksschulklasse fuehrt Geschichten als Deutsch-Lernthema', () {
    for (final grade in LumoCurriculum.grades) {
      final deutsch =
          grade.subjects.firstWhere((subject) => subject.name == 'Deutsch');
      final stories = deutsch.topics
          .where((topic) => topic.id.endsWith('_geschichten'))
          .toList();

      expect(
        stories,
        hasLength(1),
        reason: '${grade.grade}. Klasse braucht ein Geschichten-Thema',
      );
      expect(stories.single.shortDesc.toLowerCase(), contains('verstehen'));
    }
  });

  testWidgets('Lernpfad sperrt die Geschichte auf die gewaehlte Schulstufe',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: LumoStorySetupScreen(
          appState: appState,
          initialGrade: 3,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('3. Klasse · Lernpfad'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('1. Klasse'), findsNothing);
    expect(find.text('2. Klasse'), findsNothing);
    expect(find.text('4. Klasse'), findsNothing);
  });

  testWidgets('Deutsch-Bereich zeigt Geschichten direkt sichtbar an',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(grade: 3));

    await tester.pumpWidget(
      MaterialApp(
        home: LumoDeutschScreen(
          appState: appState,
          random: math.Random(7),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Geschichten'), findsOneWidget);
    expect(find.text('Lesen & verstehen'), findsOneWidget);
  });
}
