import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const bank = QuizQuestionBank();

  test('preferSubject keeps twenty questions and the default seed path', () {
    final a = bank.generateGameQuestions(grade: 3, random: math.Random(2013));
    final b = bank.generateGameQuestions(
      grade: 3,
      random: math.Random(2013),
      preferSubject: null,
    );
    expect(a.map((q) => q.id).toList(), b.map((q) => q.id).toList());
    expect(a, hasLength(20));

    for (final subject in ['Deutsch', 'Mathe', 'Sachunterricht']) {
      final picked = bank.generateGameQuestions(
        grade: 2,
        random: math.Random(5),
        preferSubject: subject,
      );
      expect(picked, hasLength(20), reason: subject);
      expect(picked.last.subject, 'Logik-Finale');
      expect(
        picked.where((q) => q.subject == subject).length,
        greaterThan(6),
        reason: subject,
      );
    }
  });

  testWidgets('category chips restart a round and jokers animate immediately',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
      voiceEnabled: false,
      soundEnabled: false,
      reduceAnimations: true,
    ));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: QuizShowContent(appState: app, previewQuestionSeed: 7),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(const ValueKey('quiz-category-alle')), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz-category-Deutsch')), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz-category-Mathe')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('quiz-category-Sachunterricht')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('quiz-category-Mathe')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(const ValueKey('lumo-meister-stage')), findsOneWidget);

    final fifty = find.text('50:50');
    expect(fifty, findsOneWidget);
    await tester.ensureVisible(fifty);
    await tester.tap(fifty);
    await tester.pump();
    expect(
        find.byKey(const ValueKey('quiz-joker-fx-50:50-true')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
