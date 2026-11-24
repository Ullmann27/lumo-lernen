import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

enum RewardWriteReply {
  success,
  falseAfterMemory,
  throwAfterMemory,
  throwAfterCommit
}

/// Synthetic Android SharedPreferences boundary: native memory may change
/// before the durable-write reply. This is not a physical device experiment.
class RewardTestStore extends InMemorySharedPreferencesStore {
  RewardTestStore(Map<String, Object> values)
      : disk = values.map((key, value) => MapEntry('flutter.$key', value)),
        super.withData(
            values.map((key, value) => MapEntry('flutter.$key', value)));

  final Map<String, Object> disk;
  String? failingPrefix;
  RewardWriteReply reply = RewardWriteReply.success;
  int failuresLeft = 0;
  int targetWrites = 0;
  int confirmedTargetWrites = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final target = failingPrefix != null && key.startsWith(failingPrefix!);
    if (target) targetWrites++;
    await super.setValue(valueType, key, value);
    final outcome =
        target && failuresLeft > 0 ? reply : RewardWriteReply.success;
    if (target && failuresLeft > 0) failuresLeft--;
    if (outcome == RewardWriteReply.success ||
        outcome == RewardWriteReply.throwAfterCommit) {
      disk
        ..clear()
        ..addAll(await super.getAll());
    }
    if (outcome == RewardWriteReply.success) {
      if (target) confirmedTargetWrites++;
      return true;
    }
    if (outcome == RewardWriteReply.falseAfterMemory) return false;
    throw StateError('Synthetic uncertain storage reply');
  }
}
