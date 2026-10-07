#!/usr/bin/env python3
"""Adapt only the existing layout test to explicitly expand the world.

No coverage is discarded: primary controls/secondary games are checked before
expansion; all portals and unavailable-game feedback are checked after it.
"""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parents[2]
p = root/'test/games/games_world_layout_test.dart'
if hashlib.sha256(p.read_bytes()).hexdigest() != '73b240e7777a4e17a2ad8be1ebc27373fe20bdd81212466d0e0c35a116222162':
    raise SystemExit('Layout test changed; do not overwrite')
s=p.read_text()
s=s.replace("    expect(find.bySemanticsLabel('Lumo Spielewelt'), findsOneWidget);", """    expect(find.byKey(const ValueKey('launch-lumo-cards')), findsOneWidget);
    expect(find.byKey(const ValueKey('launch-lumo-kart')), findsOneWidget);
    await tester.ensureVisible(find.text('Weitere Spielwelten entdecken'));
    await tester.tap(find.text('Weitere Spielwelten entdecken'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Lumo Spielewelt'), findsOneWidget);""")
s=s.replace("    await tester.tap(find.byKey(const ValueKey('spielwelt-portal-rhythm')));", """    await tester.ensureVisible(find.text('Weitere Spielwelten entdecken'));
    await tester.tap(find.text('Weitere Spielwelten entdecken'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.byKey(const ValueKey('spielwelt-portal-rhythm')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('spielwelt-portal-rhythm')));""")
s=s.replace("      'Vier gewinnt',\n      'Würfel-Wettlauf',\n      'Lumo Kart',\n",'')
s=s.replace("    expect(find.byKey(const ValueKey('launch-lumo-cards')), findsOneWidget);", """    expect(find.byKey(const ValueKey('launch-lumo-cards')), findsOneWidget);
    for (final title in ['Vier gewinnt', 'Würfel-Wettlauf', 'Lumo Kart']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.bySemanticsLabel(RegExp('Losfahren')), findsOneWidget);
""")
s=s.replace("    expect(find.bySemanticsLabel(RegExp('Losfahren')), findsOneWidget,\n        reason: 'Android-Prüfung tippt auf „Losfahren“');\n    expect(find.byKey(const ValueKey('launch-lumo-kart')), findsOneWidget);",'')
if hashlib.sha256(s.encode()).hexdigest() != '0c94f2190074faac41bc2a8374957f55d9a4199cd4cbc8ffcaa7d77e6a384833':
    raise SystemExit('Unexpected test-patch output')
p.write_text(s)
