import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:lumo_lernen/features/story/widgets/lumo_story_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Every mystery page renders Lumo over the existing clue scene',
      (tester) async {
    final paths = <String>{};
    for (final page in [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LumoStoryScene(page: page, height: 226)),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      final foxes = tester.widgetList<Image>(find.byType(Image))
          .where((image) => image.image is AssetImage)
          .map((image) => (image.image as AssetImage).assetName)
          .where((path) => path.startsWith('assets/lumo_design/fox/'))
          .toList();
      expect(foxes, hasLength(1), reason: 'Page $page must show real Lumo');
      paths.add(foxes.single);
      final data = await rootBundle.load(foxes.single);
      expect(data.lengthInBytes, greaterThan(1000));
      expect(tester.takeException(), isNull);
    }
    expect(paths.length, greaterThanOrEqualTo(4),
        reason: 'Mystery illustrations should not all reuse the same fox pose');
  });
}
