import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';

void main() {
  test(
    'failed platform writes propagate and do not block the next write',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesKeyValueStore(preferences);
      await expectLater(
        KeyValueStoreWrites.setString(store, 'game', 'first'),
        throwsStateError,
      );
      preferences.succeed = true;
      await KeyValueStoreWrites.setString(store, 'game', 'retry');
      expect(preferences.saved, 'retry');
    },
  );
}

class _Preferences implements SharedPreferences {
  bool succeed = false;
  String? saved;
  @override
  Future<bool> setString(String key, String value) async {
    if (succeed) saved = value;
    return succeed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
