import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/reading_story_memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Eight-page story contract remains valid with original API', () {
    final story = LumoStoryGenerator.instance.generate(
      hero: 'Prinzessin', location: 'Weltraum',
      theme: 'Freundschaft', gradeLevel: 2,
    );
    expect(story.pages, hasLength(8));
    expect(story.pages.map((page) => page.pageNum).toList(),
        List<int>.generate(8, (index) => index + 1));
    expect(story.heroName, 'Prinzessin');
    expect(story.location, 'Weltraum');
    expect(story.pages[1].text, contains('Lumo'));
    expect(story.pages[1].text, contains('Sternenkompass'));
    expect(story.pages[1].exercise, isNotNull);
    expect(story.pages[4].exercise, isNotNull);
  });

  test('Same selections rotate through distinct actual plots', () {
    final first = LumoStoryGenerator.instance.generate(
      hero: 'Prinzessin', location: 'Weltraum', theme: 'Abenteuer',
      gradeLevel: 3, companion: 'Eule', magicItem: 'Mondschlüssel',
      variationSeed: 0,
    );
    final second = LumoStoryGenerator.instance.generate(
      hero: 'Prinzessin', location: 'Weltraum', theme: 'Abenteuer',
      gradeLevel: 3, companion: 'Eule', magicItem: 'Mondschlüssel',
      variationSeed: 1,
    );
    expect(first.pages, hasLength(8));
    expect(second.pages, hasLength(8));
    expect(first.pages[1].text, contains('Eule'));
    expect(second.pages[3].text, contains('Mondschlüssel'));
    expect(first.pages[3].text, isNot(second.pages[3].text));
    expect(first.pages[5].text, isNot(second.pages[5].text));
    expect(second.gradeLevel, 3);
  });

  test('Recent-story memory remains isolated by child and grade', () async {
    final repository = ReadingStoryMemoryRepository();
    await repository.remember(childId: 'a', grade: 2,
      signature: 'prinzessin|weltraum|abenteuer|lumo|zauberbuch|v0');
    final another = ReadingStoryMemoryRepository();
    final loaded = await another.loadRecent(childId: 'a', grade: 2);
    expect(loaded, hasLength(1));
    expect(loaded.single, endsWith('|v0'));
    expect(await another.loadRecent(childId: 'b', grade: 2), isEmpty);
    expect(await another.loadRecent(childId: 'a', grade: 1), isEmpty);
  });
}
