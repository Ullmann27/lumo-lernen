import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';

class _ControlledStoryStore extends InMemorySharedPreferencesStore {
  _ControlledStoryStore() : super.empty();
  Completer<bool>? write;
  int storyWrites = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.lumo_story_library_v1') {
      storyWrites++;
      final pending = write;
      if (pending != null && !await pending.future) return false;
    }
    return super.setValue(valueType, key, value);
  }
}

LumoStory _story(String title) => LumoStory(
      title: title,
      heroName: 'Lumo',
      location: 'Wald',
      theme: 'Freundschaft',
      gradeLevel: 2,
      newWords: const ['Mut'],
      pages: const [LumoStoryPage(pageNum: 1, text: 'Lumo findet Mut.', imagePrompt: 'fox')],
    );

void main() {
  testWidgets('story completion waits for disk, rejects failed writes and retries once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = _ControlledStoryStore();
    SharedPreferencesStorePlatform.instance = store;
    final oldVoice = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = oldVoice);
    final state = LumoAppState();
    addTearDown(state.dispose);
    final library = LumoStoryLibrary.instance;
    await tester.runAsync(() => library.addStory(_story('Vorhandenes Heft')));
    final oldStory = library.all.single;
    final oldJson = oldStory.toJson();

    Future<void> open(String title) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => LumoStoryReaderScreen(story: _story(title), appState: state),
          )),
          child: const Text('Öffnen'),
        )),
      ));
      await tester.tap(find.text('Öffnen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> finish() async {
      await tester.runAsync(() => tester.tap(find.text('Erzähl mir die Geschichte!')));
      await tester.pump();
    }

    await open('Neues Heft');
    store.write = Completer<bool>();
    await finish();
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await finish(); // Repeat tap while the storage Future is still unresolved.
    expect(store.storyWrites, 2); // One seed plus one new story write.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(LumoStoryReaderScreen), findsOneWidget);
    store.write!.complete(true);
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect((jsonDecode(preferences.getString('lumo_story_library_v1')!) as List).length, 2);
    expect(library.all.where((s) => s.id == oldStory.id).single.toJson(), oldJson);
    await tester.tap(find.text('Fertig'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LumoStoryReaderScreen), findsNothing);

    store.write = Completer<bool>();
    await open('Heft nach Speicherfehler');
    await finish();
    store.write!.complete(false);
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsNothing);
    expect(find.textContaining('nicht gespeichert'), findsOneWidget);
    expect(library.count, 2);
    expect(library.all.where((s) => s.id == oldStory.id).single.toJson(), oldJson);
    store.write = null;
    await finish();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsOneWidget);
    expect(library.count, 3);
    expect(library.all.where((s) => s.story.title == 'Heft nach Speicherfehler'), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
