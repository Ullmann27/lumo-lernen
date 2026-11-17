import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/widgets/design/lumo_section_heading.dart';

void main() {
  testWidgets('Section heading handles narrow phone and larger text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme: LumoAppTheme.light(),
      home: Scaffold(body: MediaQuery(
        data: const MediaQueryData(size: Size(320, 650),
          textScaler: TextScaler.linear(1.6)),
        child: const Padding(padding: EdgeInsets.all(16),
          child: LumoSectionHeading(title: 'Deine Lieblingslernwelten',
            subtitle: 'Entdecke die Themen und starte eine Lernrunde.',
            icon: Icons.auto_stories_rounded)),
      ))));
    expect(find.text('Deine Lieblingslernwelten'), findsOneWidget);
    expect(find.textContaining('Entdecke die Themen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Section heading with no subtitle', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LumoSectionHeading(
        title: 'Weitere Spiele', icon: Icons.sports_esports_rounded))));
    expect(find.text('Weitere Spiele'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
