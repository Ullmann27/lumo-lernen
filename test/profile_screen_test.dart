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

  test('Level-Titel steigen mit dem Level', () {
    expect(ProfileScreen.levelTitle(1), 'Entdecker:in');
    expect(ProfileScreen.levelTitle(3), 'Forscher:in');
    expect(ProfileScreen.levelTitle(6), 'Lernprofi');
    expect(ProfileScreen.levelTitle(9), 'Lern-Meister:in');
  });
}
