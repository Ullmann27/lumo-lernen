import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/parent_pin_service.dart';

void main() {
  group('ParentPinService', () {
    const service = ParentPinService();

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('requires setup when no PIN exists', () async {
      expect(await service.isPinSet(), isFalse);
      expect(await service.verifyPin('1234'), isFalse);
    });

    test('creates salt and hash without storing raw PIN', () async {
      await service.createPin('2468');
      final prefs = await SharedPreferences.getInstance();

      expect(await service.isPinSet(), isTrue);
      expect(prefs.getString(ParentPinService.saltKey), isNotNull);
      expect(prefs.getString(ParentPinService.hashKey), isNotNull);
      expect(prefs.getString(ParentPinService.createdAtKey), isNotNull);
      expect(prefs.getString(ParentPinService.hashKey), isNot('2468'));
      expect(prefs.getKeys().where((key) => prefs.get(key) == '2468'), isEmpty);
    });

    test('validates correct PIN and rejects wrong PIN', () async {
      await service.createPin('1357');

      expect(await service.verifyPin('1357'), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
      expect(await service.verifyPin('abcd'), isFalse);
    });

    test('rejects invalid PIN shape', () async {
      expect(() => service.createPin('12'), throwsA(isA<ParentPinException>()));
      expect(() => service.createPin('abcd'), throwsA(isA<ParentPinException>()));
    });

    test('factory reset PIN removal removes all PIN keys', () async {
      await service.createPin('1234');
      await service.removePinForFactoryResetOnly();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(ParentPinService.saltKey), isFalse);
      expect(prefs.containsKey(ParentPinService.hashKey), isFalse);
      expect(prefs.containsKey(ParentPinService.createdAtKey), isFalse);
      expect(await service.isPinSet(), isFalse);
    });
  });
}
