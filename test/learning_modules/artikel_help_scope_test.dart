import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/artikel_lernen/artikel_lernen_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App state whose active child can be switched without the school backend.
class _SwitchableProfileState extends LumoAppState {
  _SwitchableProfileState() : super(walletRepository: RewardWalletRepository());

  int generation = 0;

  @override
  int get profileGeneration => generation;

  void switchProfile() {
    generation++;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  Future<_SwitchableProfileState> openArtikel(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = _SwitchableProfileState();
    await tester
        .pumpWidget(MaterialApp(home: ArtikelLernenScreen(appState: state)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return state;
  }

  String currentPrompt() =>
      LumoCompanionRequests.instance.taskContext.value!.prompt;

  testWidgets(
      'Der/Die/Das: Hinweise beziehen sich auf das aktive Wort und '
      'vergeben keine Punkte', (tester) async {
    final state = await openArtikel(tester);
    final requests = LumoCompanionRequests.instance;
    final prompt = currentPrompt();
    final word = RegExp('„(.+)“').firstMatch(prompt)!.group(1)!;
    final starsBefore = state.state.stars;
    final xpBefore = state.state.xp;

    for (var level = 1; level <= 3; level++) {
      requests.requestTaskHelp();
      await tester.pump();
      expect(find.text('Lumos Hinweis $level'), findsOneWidget);
      final help =
          tester.widget<Text>(find.byKey(const ValueKey('module-help-text')));
      expect(help.data, contains(word), reason: 'Hinweis $level');
      expect(requests.taskContext.value!.helpLevel, level);
      expect(currentPrompt(), prompt,
          reason: 'Hilfe wechselt die Aufgabe nicht');
    }

    expect(state.state.stars, starsBefore);
    expect(state.state.xp, xpBefore);
    expect(requests.taskContext.value!.lastCorrect, isNull,
        reason: 'Ein Hinweis bewertet keine Antwort');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    state.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Der/Die/Das: Profilwechsel entfernt den Hilfekontext',
      (tester) async {
    final state = await openArtikel(tester);
    final requests = LumoCompanionRequests.instance;

    requests.requestTaskHelp();
    await tester.pump();
    expect(find.byKey(const ValueKey('module-help-panel')), findsOneWidget);
    expect(requests.taskContext.value, isNotNull);

    state.switchProfile();
    await tester.pump();

    expect(requests.taskContext.value, isNull,
        reason: 'Der alte Aufgabenbezug darf nicht beim neuen Kind bleiben');
    expect(find.byKey(const ValueKey('module-help-panel')), findsNothing,
        reason: 'Der Hinweis des vorigen Kindes darf nicht sichtbar bleiben');

    requests.requestTaskHelp();
    await tester.pump();
    expect(find.byKey(const ValueKey('module-help-panel')), findsNothing,
        reason: 'Hilfe für die alte Aufgabe darf nicht neu starten');
    expect(requests.taskContext.value, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    state.dispose();
    expect(tester.takeException(), isNull);
  });
}
