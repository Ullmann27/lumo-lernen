// True raster captures of the same production Flutter screens on two source
// revisions. The baseline 1986 has no Denkprofil intro or explorer mode.
// Run the same test on each checked-out revision; never draw mock screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/features/tests/cognitive_profile_screen.dart';
import 'package:lumo_lernen/features/tests/iq_test_screen.dart';

import '../helpers/lumo_capture.dart';
import '../iq/iq_test_support.dart';

final String? _directory = Platform.environment['LUMO_VISUAL_CAPTURE_DIR'];
const _boundary = ValueKey('lumo-visual-compare');

const _screens = <String, Size>{
  'phone-412x915': Size(412, 915),
  'fold-cover-344x882': Size(344, 882),
  'fold-open-690x829': Size(690, 829),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIqFonts);
  setUp(() async => resetIqEnvironment());

  for (final entry in _screens.entries) {
    testWidgets('Real Denkprofil before/after UI on ${entry.key}', (tester) async {
      await tester.binding.setSurfaceSize(entry.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = iqTestApp();
      addTearDown(state.dispose);

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: _boundary,
          child: CognitiveProfileScreen(appState: state),
        ),
      ));
      await settleIq(tester);

      // 1986: original question screen; 1987: new Lumo welcome screen.
      await captureLumoBoundary(tester, _boundary,
          '$_directory/${entry.key}/denkprofil-01-oeffnen.png', pixelRatio: 1.5);

      final start = find.byKey(const ValueKey('cognitive-start-button'));
      if (start.evaluate().isNotEmpty) {
        await tester.ensureVisible(start);
        await tester.tap(start);
        await settleIq(tester);
      }
      // In both commits this is the actual first Denkprofil question UI.
      await captureLumoBoundary(tester, _boundary,
          '$_directory/${entry.key}/denkprofil-02-erste-frage.png',
          pixelRatio: 1.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, skip: _directory == null);

    testWidgets('Real Knobeltest before/after UI on ${entry.key}', (tester) async {
      await tester.binding.setSurfaceSize(entry.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final homeState = iqTestApp();
      addTearDown(homeState.dispose);

      // Real regular UI, no session injected, so extended option is shown
      // in 1987 (and absent by design in 1986).
      await tester.pumpWidget(iqScreenApp(homeState, boundary: _boundary));
      await settleIq(tester);
      await captureLumoBoundary(tester, _boundary,
          '$_directory/${entry.key}/knobel-01-start.png', pixelRatio: 1.5);
      await tester.pumpWidget(const SizedBox.shrink());

      final state = iqTestApp();
      addTearDown(state.dispose);
      final session = IqTestSession(grade: 2, seed: 41);
      await tester.pumpWidget(
          iqScreenApp(state, session: session, boundary: _boundary));
      await settleIq(tester);
      await startIqTest(tester);
      await captureLumoBoundary(tester, _boundary,
          '$_directory/${entry.key}/knobel-02-bereich.png', pixelRatio: 1.5);
      await leaveAreaIntro(tester);
      await captureLumoBoundary(tester, _boundary,
          '$_directory/${entry.key}/knobel-03-raetsel.png', pixelRatio: 1.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, skip: _directory == null);
  }
}
