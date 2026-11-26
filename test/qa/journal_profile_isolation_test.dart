import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/backup/local_backup.dart';
import 'package:lumo_lernen/features/journal/journal_repository.dart';
import 'package:lumo_lernen/features/journal/lumo_journal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const a = JournalRepository(schoolOwnerId: 'school-a');
  const b = JournalRepository(schoolOwnerId: 'school-b');
  const device = JournalRepository(schoolOwnerId: null);
  bool current() => true;
  final legacy = jsonEncode([
    {'id': 'old', 'text': 'Altbestand', 'title': 'Alt',
      'createdAt': 1700000000000, 'wordCount': 1}
  ]);
  setUp(() => SharedPreferences.setMockInitialValues({
    JournalRepository.deviceKey: legacy,
  }));

  test('Schulkinder sind getrennt; Gerätejournal bleibt unverändert', () async {
    expect(await a.load(isCurrent: current), isEmpty);
    expect(await b.load(isCurrent: current), isEmpty);
    await a.add(text: 'Nur Kind A', title: 'A', isCurrent: current);
    await b.add(text: 'Nur Kind B', title: 'B', isCurrent: current);
    expect((await a.load(isCurrent: current)).single.text, 'Nur Kind A');
    expect((await b.load(isCurrent: current)).single.text, 'Nur Kind B');
    expect((await device.load(isCurrent: current)).single.text, 'Altbestand');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(JournalRepository.deviceKey), legacy);
    await prefs.reload();
    expect((await a.load(isCurrent: current)).single.title, 'A');
  });

  test('parallele Schreibvorgänge bleiben vollständig und profilgebunden', () async {
    await Future.wait([
      for (var i = 0; i < 8; i++)
        a.add(text: 'Text $i', title: '', isCurrent: current),
    ]);
    final entries = await a.load(isCurrent: current);
    expect(entries.length, 8);
    expect(entries.map((e) => e.id).toSet().length, 8);
    expect(await b.load(isCurrent: current), isEmpty);
  });

  test('veralteter Profilzugriff und beschädigte Bytes werden nicht überschrieben', () async {
    await expectLater(a.add(text: 'Falsch', title: '', isCurrent: () => false),
        throwsStateError);
    await expectLater(a.load(isCurrent: () => false), throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    final key = JournalRepository.schoolKey('school-a');
    await prefs.setString(key, '{kaputt');
    await expectLater(a.add(text: 'Neu', title: '', isCurrent: current),
        throwsFormatException);
    expect(prefs.getString(key), '{kaputt');
  });

  test('Sicherung erhält beide Journale und lehnt fremden Besitz ab', () async {
    await a.add(text: 'A', title: '', isCurrent: current);
    await b.add(text: 'B', title: '', isCurrent: current);
    final prefs = await SharedPreferences.getInstance();
    final keyA = JournalRepository.schoolKey('school-a');
    final keyB = JournalRepository.schoolKey('school-b');
    final values = <String, Object>{
      JournalRepository.deviceKey: legacy,
      keyA: prefs.getString(keyA)!,
      keyB: prefs.getString(keyB)!,
    };
    final archive = LocalBackup.create(preferences: values, nativeFiles: []);
    final restored = LocalBackup.parse(archive.bytes);
    expect(restored.preferences, values);
    expect(
      () => LocalBackup.create(preferences: {
        ...values, keyB: values[keyA]!,
      }, nativeFiles: []),
      throwsFormatException,
    );
    SharedPreferences.setMockInitialValues(restored.preferences);
    expect((await a.load(isCurrent: current)).single.text, 'A');
    expect((await b.load(isCurrent: current)).single.text, 'B');
  });

  testWidgets('Profilwechsel schließt sichtbare Liste und alte Editor-Sitzung',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('school-a');
    await a.add(text: 'Privat A', title: 'Privat A', isCurrent: current);
    await b.add(text: 'Privat B', title: 'Privat B', isCurrent: current);
    await tester.pumpWidget(MaterialApp(home: LumoJournalScreen(appState: app)));
    await tester.pumpAndSettle();
    expect(find.text('Privat A'), findsWidgets);
    expect(find.text('Privat B'), findsNothing);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).last, 'Entwurf A');
    await app.school.setActiveStudent('school-b');
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Das Kinderprofil hat gewechselt'), findsOneWidget);
    expect(find.text('Privat A'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(home: LumoJournalScreen(appState: app)));
    await tester.pumpAndSettle();
    expect(find.text('Privat B'), findsWidgets);
    expect(find.text('Privat A'), findsNothing);
  });
}
