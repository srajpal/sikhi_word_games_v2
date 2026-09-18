import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// Serializes writes to an exact app key, including across repository instances.
/// Reset callers must first stop producers (such as a game page being disposed).
class KeyValueStoreWrites {
  static final _queues = Expando<Map<String, Future<void>>>();

  static Future<void> run(
    KeyValueStore store,
    String key,
    Future<void> Function() action,
  ) {
    final queues = _queues[store] ??= {};
    final previous = queues[key] ?? Future<void>.value();
    final result = previous.then((_) => action());
    // A failed write is reported to its caller but must not block a later reset.
    queues[key] = result.catchError((Object _) {});
    return result;
  }

  static Future<void> setString(
    KeyValueStore store,
    String key,
    String value,
  ) => run(store, key, () => store.setString(key, value));

  static Future<void> remove(KeyValueStore store, String key) =>
      run(store, key, () => store.remove(key));
}

class SharedPreferencesKeyValueStore implements KeyValueStore {
  const SharedPreferencesKeyValueStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    if (!await _preferences.remove(key)) {
      throw StateError('Unable to remove saved app data');
    }
  }
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
