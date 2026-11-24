import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/kart_friends/kart_friend_ghost.dart';
import 'package:lumo_lernen/features/kart_friends/kart_friends_inbox.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'WLAN-Spiel ist ohne Elternfreigabe aus und bleibt beim Speichern erhalten',
      () {
    expect(const AppSettings().lanPlayEnabled, isFalse);
    expect(AppSettings.fromJson(const {}).lanPlayEnabled, isFalse);
    expect(AppSettings.fromJson(const {'lanPlayEnabled': 'ja'}).lanPlayEnabled,
        isFalse);
    final on = const AppSettings().copyWith(lanPlayEnabled: true);
    expect(AppSettings.fromJson(on.toJson()).lanPlayEnabled, isTrue);
    expect(AppSettings.fromJson(on.toJson()).ghostDuelEnabled, isFalse);
  });

  test('Geister-Duell ist ohne Elternfreigabe aus und unabhängig vom WLAN-Spiel',
      () {
    expect(const AppSettings().ghostDuelEnabled, isFalse);
    expect(AppSettings.fromJson(const {}).ghostDuelEnabled, isFalse);
    expect(
        AppSettings.fromJson(const {'ghostDuelEnabled': 1}).ghostDuelEnabled,
        isFalse);
    final on = const AppSettings().copyWith(ghostDuelEnabled: true);
    expect(AppSettings.fromJson(on.toJson()).ghostDuelEnabled, isTrue);
    expect(AppSettings.fromJson(on.toJson()).lanPlayEnabled, isFalse);
  });

  test('Die Einladung kennt alle 14 Kart-Strecken beim Namen', () {
    expect(KartFriendGhost.trackNames.keys.toSet(), {
      'sonnenhafen',
      'zauberwald',
      'bergwelt',
      'holo_city',
      'crystal_canyon',
      'jungle_temple',
      'candy_cloud',
      'volcano_night',
      'winter_sprint',
      'galaxy_ringway',
      'desert_drift',
      'learning_lab',
      'jungle_emerald_3600',
      'windwerk_3000',
    });
    expect(KartFriendGhost.trackNames.values.every((name) => name.length > 3),
        isTrue);
  });

  testWidgets('Elternbereich erklärt, was geteilt wird, und schaltet WLAN frei',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
    LumoVoice.instance.isEnabled = false;
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SettingsContent(appState: app)),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('settingsFriendsCard'));
    await tester.scrollUntilVisible(card, 300,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.descendant(
            of: card,
            matching: find.textContaining(
                'Vorname, das gewählte Kart und die Fahrlinie')),
        findsOneWidget);
    final open = find.byKey(const ValueKey('openFriendGhostFile'));
    expect(open, findsOneWidget);
    // Ohne Freigabe lässt sich keine Geist-Datei öffnen.
    expect(tester.widget<OutlinedButton>(open).onPressed, isNull);
    final toggle = find.widgetWithText(
        SwitchListTile, 'Gemeinsam spielen im WLAN erlauben');
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    tester.widget<SwitchListTile>(toggle).onChanged!(true);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(app.state.settings.lanPlayEnabled, isTrue);
    expect(app.state.settings.ghostDuelEnabled, isFalse);
    final duel = find.widgetWithText(SwitchListTile, 'Geister-Duell erlauben');
    expect(tester.widget<SwitchListTile>(duel).value, isFalse);
    tester.widget<SwitchListTile>(duel).onChanged!(true);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(app.state.settings.ghostDuelEnabled, isTrue);
    expect(tester.widget<OutlinedButton>(open).onPressed, isNotNull);
  });

  testWidgets(
      'Ohne Elternfreigabe zeigt ein angekommener Geist weder Namen noch Start',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    final ghost = KartFriendGhost.read(
        File('test/fixtures/kart_friend_ghost_lena.lumogeist')
            .readAsBytesSync());
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => KartFriendsInbox.showInvitation(context, app, ghost),
          child: const Text('gut'),
        ),
      ),
    ));
    await tester.tap(find.text('gut'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kartFriendNotAllowed')), findsOneWidget);
    expect(find.textContaining('Lena'), findsNothing);
    expect(find.byKey(const ValueKey('kartFriendInvitation')), findsNothing);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kartFriendNotAllowed')), findsNothing);
  });

  testWidgets('Einladung zeigt Freund, Strecke und Zeit; Ablehnung freundlich',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(ghostDuelEnabled: true));
    final ghost = KartFriendGhost.read(
        File('test/fixtures/kart_friend_ghost_lena.lumogeist')
            .readAsBytesSync());
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Column(children: [
          TextButton(
            onPressed: () =>
                KartFriendsInbox.showInvitation(context, app, ghost),
            child: const Text('gut'),
          ),
          TextButton(
            onPressed: () => KartFriendsInbox.showInvitation(context, app,
                const KartFriendGhostResult.error('Das ist kein Lumo-Geist.')),
            child: const Text('schlecht'),
          ),
        ]),
      ),
    ));
    await tester.tap(find.text('gut'));
    await tester.pumpAndSettle();
    expect(find.text('Lena fordert dich heraus!'), findsOneWidget);
    expect(find.textContaining('Sonnenhafen · Zeit'), findsOneWidget);
    expect(find.text('Gegen Lena fahren'), findsOneWidget);
    await tester.tap(find.text('Später'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kartFriendInvitation')), findsNothing);
    await tester.tap(find.text('schlecht'));
    await tester.pumpAndSettle();
    expect(find.text('Dieser Geist passt nicht'), findsOneWidget);
    expect(find.text('Das ist kein Lumo-Geist.'), findsOneWidget);
    expect(find.text('Gegen Lena fahren'), findsNothing);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
  });
}
