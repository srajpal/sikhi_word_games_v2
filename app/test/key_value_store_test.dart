import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';

void main() {
  test(
    'completion cleanup waits for statistics and precedes the next round',
    () async {
      final store = MemoryKeyValueStore();
      await store.setString('game', 'old');
      final stats = Completer<void>();
      final clear = KeyValueStoreWrites.remove(
        store,
        'game',
        after: stats.future,
      );
      final next = KeyValueStoreWrites.setString(store, 'game', 'new');
      await Future<void>.delayed(Duration.zero);
      expect(store.getString('game'), 'old');
      stats.complete();
      await clear;
      await next;
      expect(store.getString('game'), 'new');
    },
  );
  test(
    'failed statistics retain the saved game and allow later writes',
    () async {
      final store = MemoryKeyValueStore();
      await store.setString('game', 'old');
      final stats = Completer<void>();
      final clear = KeyValueStoreWrites.remove(
        store,
        'game',
        after: stats.future,
      );
      final check = expectLater(clear, throwsStateError);
      stats.completeError(StateError('disk full'));
      await check;
      expect(store.getString('game'), 'old');
      await KeyValueStoreWrites.setString(store, 'game', 'new');
      expect(store.getString('game'), 'new');
    },
  );
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
