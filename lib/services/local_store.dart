// Local storage service – stub using in-memory map
// Production: use shared_preferences or sqflite
class LocalStore {
  final Map<String, dynamic> _data = {};

  void set(String key, dynamic value) {
    _data[key] = value;
  }

  T? get<T>(String key) {
    final value = _data[key];
    if (value is T) return value;
    return null;
  }

  void remove(String key) {
    _data.remove(key);
  }

  void clear() {
    _data.clear();
  }
}
