import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';

class _FailingStoryStore extends InMemorySharedPreferencesStore {
  _FailingStoryStore() : super.empty();

  bool refuseStoryWrites = false;
  int refused = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (refuseStoryWrites && key == 'flutter.lumo_story_library_v1') {
      refused++;
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

LumoStory _example() => const LumoStory(
      title: 'Das sichere Geschichtenbuch',
      heroName: 'Lumo',
      location: 'Garten',
      theme: 'Freundschaft',
      gradeLevel: 2,
      newWords: ['Freund'],
      pages: [
        LumoStoryPage(
          pageNum: 1,
          text: 'Lumo liest mit seinen Freunden.',
          imagePrompt: '',
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FailingStoryStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = _FailingStoryStore();
    SharedPreferencesStorePlatform.instance = store;
  });
  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Malformed existing library is never silently overwritten', () async {
    final prefs = await SharedPreferences.getInstance();
    const corrupted = '[{"id": "original", "story": {broken json';
    await prefs.setString('lumo_story_library_v1', corrupted);
    final library = LumoStoryLibrary.testInstance();

    await expectLater(library.load(), throwsA(isA<FormatException>()));
    expect(prefs.getString('lumo_story_library_v1'), corrupted);
    await expectLater(library.addStory(_example()),
        throwsA(isA<FormatException>()));
    expect(prefs.getString('lumo_story_library_v1'), corrupted);
    expect(library.count, 0);
    expect(store.refused, 0);

    // A repaired archive can be loaded without restarting the app.
    await prefs.setString('lumo_story_library_v1', '[]');
    await library.load();
    expect(library.count, 0);
    await library.addStory(_example());
    expect(library.count, 1);
  });

  test('Failed favorite, read count and delete writes roll back', () async {
    final prefs = await SharedPreferences.getInstance();
    final library = LumoStoryLibrary.testInstance();
    final saved = await library.addStory(_example());
    final diskBefore = prefs.getString('lumo_story_library_v1');
    expect(diskBefore, isNotNull);
    store.refuseStoryWrites = true;

    await expectLater(library.incrementRead(saved.id),
        throwsA(isA<StateError>()));
    expect(library.all.single.timesRead, 0);
    expect(prefs.getString('lumo_story_library_v1'), diskBefore);

    await expectLater(library.toggleFavorite(saved.id),
        throwsA(isA<StateError>()));
    expect(library.all.single.isFavorite, isFalse);
    expect(prefs.getString('lumo_story_library_v1'), diskBefore);

    await expectLater(library.delete(saved.id), throwsA(isA<StateError>()));
    expect(library.count, 1);
    expect(library.all.single.id, saved.id);
    expect(prefs.getString('lumo_story_library_v1'), diskBefore);
    expect(store.refused, 3);

    store.refuseStoryWrites = false;
    await library.toggleFavorite(saved.id);
    expect(library.all.single.isFavorite, isTrue);
    await library.incrementRead(saved.id);
    expect(library.all.single.timesRead, 1);
    await library.delete(saved.id);
    expect(library.count, 0);
  });
}
