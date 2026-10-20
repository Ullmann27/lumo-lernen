import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget hub({
    required int grade,
    required void Function(String, String) onUnit,
    VoidCallback? onAdvanced,
    VoidCallback? onRead,
    ValueChanged<String>? onPractical,
  }) => MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF0C2140),
      body: LumoLearningHub(
        grade: grade,
        onStartUnit: onUnit,
        onAdvanced: onAdvanced ?? () {},
        onReading: onRead ?? () {},
        onPracticalSubject: onPractical ?? (_) {},
      ),
    ),
  );

  testWidgets('four primary subjects precede grade-specific topics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? selectedSubject;
    String? selectedUnit;
    await tester.pumpWidget(hub(
      grade: 4, onUnit: (s, u) {
        selectedSubject = s;
        selectedUnit = u;
      },
    ));
    expect(find.byKey(const ValueKey('learning-profile-grade')),
        findsOneWidget);
    expect(find.text('4. Klasse · aus deinem Profil'), findsOneWidget);
    for (final name in ['Mathematik', 'Deutsch', 'Englisch', 'Sachunterricht']) {
      expect(find.byKey(ValueKey('learning-subject-$name')), findsOneWidget);
    }
    // The secondary section is intentionally below the first viewport.
    // Verify it after the primary subject -> real unit path, not by assuming
    // Flutter has eagerly mounted an offscreen ListView child.
    expect(find.byKey(const ValueKey('learning-extra-Musik')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('learning-subject-Mathematik')));
    await tester.pump();
    expect(find.text('Themen · Mathematik'), findsOneWidget);
    final topics = Curriculum.unitsForGrade(
        'Mathematik', 4, currentGradeOnly: true);
    expect(topics, isNotEmpty);
    final first = find.byKey(ValueKey('learning-unit-Mathematik-${topics.first}'));
    await tester.ensureVisible(first);
    await tester.tap(first);
    expect(selectedSubject, 'Mathematik');
    expect(selectedUnit, topics.first);
    expect(find.text('4. Klasse · aus deinem Profil'), findsOneWidget);
    final back = find.byKey(const ValueKey('learning-back-to-subjects'));
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pump();
    final more = find.byKey(const PageStorageKey<String>('learning-other-subjects'));
    await tester.scrollUntilVisible(more, 180,
        scrollable: find.byType(Scrollable).first, maxScrolls: 15);
    expect(more, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional reading and advanced tools stay reachable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var advanced = 0;
    var reading = 0;
    String? practical;
    await tester.pumpWidget(hub(
      grade: 3, onUnit: (_, __) {},
      onAdvanced: () => advanced++,
      onRead: () => reading++,
      onPractical: (s) => practical = s,
    ));
    final more = find.byKey(const PageStorageKey<String>('learning-other-subjects'));
    await tester.scrollUntilVisible(more, 180,
        scrollable: find.byType(Scrollable).first, maxScrolls: 15);
    await tester.tap(more);
    // ExpansionTile rebuilds and animates its clipped children. Pump until
    // the row can actually accept pointer events, not merely until its key
    // appears in the element tree.
    await tester.pumpAndSettle();
    final readingEntry = find.byKey(const ValueKey('learning-extra-Lesen'));
    await tester.ensureVisible(readingEntry);
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(readingEntry).onTap, isNotNull);
    await tester.tap(readingEntry);
    await tester.pump();
    expect(reading, 1);
    final music = find.byKey(const ValueKey('learning-extra-Musik'));
    await tester.ensureVisible(music);
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(music).onTap, isNotNull);
    await tester.tap(music);
    await tester.pump();
    expect(practical, 'Musik');
    final openAdvanced = find.byKey(const ValueKey('learning-advanced-entry'));
    await tester.scrollUntilVisible(openAdvanced, 180,
        scrollable: find.byType(Scrollable).first, maxScrolls: 15);
    await tester.pumpAndSettle();
    await tester.tap(openAdvanced);
    await tester.pump();
    expect(advanced, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small cover and unfolded Fold preserve clear subject actions',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [const Size(320, 720), const Size(900, 1100)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(hub(grade: 2, onUnit: (_, __) {}));
      await tester.pump();
      for (final name in ['Mathematik', 'Deutsch', 'Englisch', 'Sachunterricht']) {
        final entry = find.byKey(ValueKey('learning-subject-$name'));
        await tester.ensureVisible(entry);
        final bounds = tester.getRect(entry);
        expect(bounds.width, greaterThanOrEqualTo(120));
        expect(bounds.height, greaterThanOrEqualTo(48));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
      }
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
