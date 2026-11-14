import 'dart:ui' show SemanticsAction, SemanticsFlag;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/widgets/profile_screen.dart';

/// Profil nach Bild 07 mit echten Werten statt der Beispielzahlen.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Profil zeigt echte Werte und führt in Einstellungen und Laden',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.binding.setSurfaceSize(const Size(392, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      final sections = <LumoSection>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            appState: app,
            onSection: sections.add,
            childName: 'Mia',
            grade: 2,
            stars: 12,
            xp: 520,
            level: 2,
          ),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('Entdecker:in'), findsOneWidget);
      expect(find.text('Klasse 2'), findsOneWidget);
      expect(find.text('120 / 400 XP'), findsWidgets);
      expect(find.text('Level 3 erreichen'), findsOneWidget);
      expect(find.text('12/50'), findsOneWidget, reason: 'Sternensammler');
      expect(find.text('0 Tage'), findsOneWidget);
      expect(
          find.text('Noch nichts eingelöst. Sammle Sterne und such dir im '
              'Belohnungs-Laden etwas aus!'),
          findsOneWidget);

      final edit = find.byKey(const ValueKey('profile-edit'));
      final editNode = tester.getSemantics(edit);
      expect(editNode.label, 'Profil bearbeiten',
          reason:
              'Android must expose the button, not only a whole-card label.');
      expect(
          editNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(
          editNode.getSemanticsData().hasFlag(SemanticsFlag.isButton), isTrue);
      await tester.tap(edit);
      await tester.tap(find.byKey(const ValueKey('profile-rewards-all')));
      await tester.ensureVisible(find.byKey(const ValueKey('profile-extras')));
      await tester.tap(find.byKey(const ValueKey('profile-extras')));
      expect(sections,
          [LumoSection.settings, LumoSection.rewards, LumoSection.rewards]);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Profil-Extras öffnet die vorhandenen Einstellungen als echte Schaltfläche',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final app = LumoAppState();
    final sections = <LumoSection>[];
    try {
      await tester.binding.setSurfaceSize(const Size(392, 1400));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            appState: app,
            onSection: sections.add,
            childName: 'Mia',
            grade: 2,
            stars: 12,
            xp: 520,
            level: 2,
          ),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      final extrasRow = find.ancestor(
        of: find.byKey(const ValueKey('profile-extras')),
        matching: find.byType(Row),
      ).first;
      final actions = find.descendant(
        of: extrasRow,
        matching: find.byType(InkWell),
      );
      expect(actions, findsNWidgets(2));
      final profile = actions.last;
      await tester.ensureVisible(profile);
      await tester.pump();
      expect(tester.getSize(profile).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(profile).height, greaterThanOrEqualTo(48));
      await tester.tap(profile);
      expect(sections, [LumoSection.settings]);
      expect(find.text('Dein Profil'), findsOneWidget);
      expect(find.text('Klasse und Einstellungen ansehen'), findsOneWidget);
      expect(find.textContaining('bald verfügbar'), findsNothing);
      final node = tester.getSemantics(
          find.byKey(const ValueKey('profile-settings')));
      expect(node.label, contains('Dein Profil'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.getSemanticsData().hasFlag(SemanticsFlag.isButton), isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app.dispose();
      semantics.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  test('Level-Titel steigen mit dem Level', () {
    expect(ProfileScreen.levelTitle(1), 'Entdecker:in');
    expect(ProfileScreen.levelTitle(3), 'Forscher:in');
    expect(ProfileScreen.levelTitle(6), 'Lernprofi');
    expect(ProfileScreen.levelTitle(9), 'Lern-Meister:in');
  });
}
