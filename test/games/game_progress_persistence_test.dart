import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repo = GameProgressRepository();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nacheinander gespeicherte Ergebnisse bleiben erhalten', () async {
    await repo.recordResult(childId: 'k', levelId: 1, starsEarned: 2);
    await repo.recordResult(childId: 'k', levelId: 2, starsEarned: 3);
    final s = await repo.loadStars('k');
    expect(s[1], 2);
    expect(s[2], 3);
  });

  test('beschaedigter Stand faellt auf Sicherung zurueck', () async {
    await repo.recordResult(childId: 'k', levelId: 1, starsEarned: 2);
    await repo.recordResult(childId: 'k', levelId: 2, starsEarned: 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lumo.games.stars.k', '{kaputt');
    final s = await repo.loadStars('k');
    expect(s[1], 2);
    final rt = repo.buildRuntime(s);
    expect(rt[1].locked, isFalse);
  });

  test('kein Downgrade der Sterne', () async {
    await repo.recordResult(childId: 'k', levelId: 1, starsEarned: 3);
    final s = await repo.recordResult(childId: 'k', levelId: 1, starsEarned: 1);
    expect(s[1], 3);
  });

  test('unbekannte Level-IDs bleiben beim Speichern erhalten', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lumo.games.stars.k', '{"9999":2,"1":1}');
    await repo.recordResult(childId: 'k', levelId: 2, starsEarned: 1);
    expect((await repo.loadStars('k')).containsKey(9999), isFalse);
    expect(prefs.getString('lumo.games.stars.k'), contains('"9999":2'));
  });
}
