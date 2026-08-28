import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';

class SolutionHistoryRepository {
  const SolutionHistoryRepository(this._store);

  static const storageKey = 'guessTheWord.usedSolutions';
  final KeyValueStore _store;

  Set<String> load() {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return {};
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      if (json['schemaVersion'] != 1 || json['usedIds'] is! List<Object?>) {
        return {};
      }
      return {
        for (final id in json['usedIds']! as List<Object?>)
          if (id is String) id,
      };
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  Future<void> save(Iterable<String> usedIds) => _store.setString(
    storageKey,
    jsonEncode({'schemaVersion': 1, 'usedIds': usedIds.toList()}),
  );
}
