import 'package:flutter_test/flutter_test.dart';

/// Construct storage queues in the same native zone used to await their I/O.
/// An already completed Future created in FakeAsync still retains that zone;
/// pumping it before runAsync does not move later queue continuations there.
Future<T> nativeStorageFixture<T extends Object>(
  WidgetTester tester,
  T Function() create,
) async {
  final fixture = await tester.runAsync(() async => create());
  expect(fixture, isNotNull, reason: 'The storage fixture must be constructed');
  return fixture!;
}
