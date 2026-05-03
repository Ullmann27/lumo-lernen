import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/recent_task_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repository = RecentTaskRepository();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('RecentTaskRepository', () {
    test('saves and loads task keys per child and subject', () async {
      await repository.saveTaskKeys(
        childId: 'kind-1',
        subject: 'Deutsch',
        keys: <String>['a', 'b', 'c'],
      );

      expect(
        await repository.loadTaskKeys(childId: 'kind-1', subject: 'Deutsch'),
        <String>['a', 'b', 'c'],
      );
      expect(
        await repository.loadTaskKeys(childId: 'kind-2', subject: 'Deutsch'),
        isEmpty,
      );
    });

    test('deduplicates task keys while keeping newest occurrence', () async {
      await repository.saveTaskKeys(
        childId: 'kind',
        subject: 'Mathematik',
        keys: <String>['eins', 'zwei', 'EINS', 'drei', 'zwei'],
      );

      expect(
        await repository.loadTaskKeys(childId: 'kind', subject: 'Mathematik'),
        <String>['EINS', 'drei', 'zwei'],
      );
    });

    test('trims task keys to maxTaskKeys', () async {
      final keys = List<String>.generate(RecentTaskRepository.maxTaskKeys + 5, (index) => 'task-$index');

      await repository.saveTaskKeys(
        childId: 'kind',
        subject: 'Deutsch',
        keys: keys,
      );

      final loaded = await repository.loadTaskKeys(childId: 'kind', subject: 'Deutsch');

      expect(loaded, hasLength(RecentTaskRepository.maxTaskKeys));
      expect(loaded.first, 'task-5');
      expect(loaded.last, 'task-${RecentTaskRepository.maxTaskKeys + 4}');
    });

    test('saves, deduplicates and trims units', () async {
      final units = <String>[
        'Plus',
        'Minus',
        'plus',
        ...List<String>.generate(RecentTaskRepository.maxUnits + 3, (index) => 'Unit $index'),
      ];

      await repository.saveUnits(
        childId: 'kind',
        subject: 'Mathematik',
        units: units,
      );

      final loaded = await repository.loadUnits(childId: 'kind', subject: 'Mathematik');

      expect(loaded, hasLength(RecentTaskRepository.maxUnits));
      expect(loaded, isNot(contains('Plus')));
      expect(loaded.last, 'Unit ${RecentTaskRepository.maxUnits + 2}');
    });

    test('removes empty values and normalizes storage separators', () async {
      await repository.saveTaskKeys(
        childId: 'Kind 1',
        subject: 'Sachkunde',
        keys: <String>['', '  ', 'task|with|separator', 'normal'],
      );

      expect(
        await repository.loadTaskKeys(childId: 'Kind 1', subject: 'Sachkunde'),
        <String>['task with separator', 'normal'],
      );
    });
  });
}
