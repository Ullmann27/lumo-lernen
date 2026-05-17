import 'package:flutter/foundation.dart';
import 'local_store.dart';

/// The learner's grade / difficulty level.
enum ClassLevel {
  klasse1, // easy exercises only
  klasse2, // easy + medium
  fortgeschritten, // all three tiers
}

extension ClassLevelLabel on ClassLevel {
  String get label {
    switch (this) {
      case ClassLevel.klasse1:
        return 'Klasse 1';
      case ClassLevel.klasse2:
        return 'Klasse 2';
      case ClassLevel.fortgeschritten:
        return 'Fortgeschritten';
    }
  }

  String get emoji {
    switch (this) {
      case ClassLevel.klasse1:
        return '🌱';
      case ClassLevel.klasse2:
        return '📚';
      case ClassLevel.fortgeschritten:
        return '🚀';
    }
  }
}

class ClassSettings extends ChangeNotifier {
  static const _key = 'class_level';

  final LocalStore _store;

  ClassSettings(this._store);

  ClassLevel get level {
    final stored = _store.get<String>(_key);
    switch (stored) {
      case 'klasse2':
        return ClassLevel.klasse2;
      case 'fortgeschritten':
        return ClassLevel.fortgeschritten;
      default:
        return ClassLevel.klasse1;
    }
  }

  void setLevel(ClassLevel lvl) {
    switch (lvl) {
      case ClassLevel.klasse1:
        _store.set(_key, 'klasse1');
        break;
      case ClassLevel.klasse2:
        _store.set(_key, 'klasse2');
        break;
      case ClassLevel.fortgeschritten:
        _store.set(_key, 'fortgeschritten');
        break;
    }
    notifyListeners();
  }
}
