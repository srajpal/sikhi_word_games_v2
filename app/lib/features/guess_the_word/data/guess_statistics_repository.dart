import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../domain/guess_statistics.dart';

class GuessStatisticsRepository {
  const GuessStatisticsRepository(this._store);

  static const storageKey = 'guessTheWord.statistics';
  final KeyValueStore _store;

  GuessStatisticsBook load() {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return const GuessStatisticsBook();
    try {
      return GuessStatisticsBook.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      );
    } on FormatException {
      return const GuessStatisticsBook();
    } on TypeError {
      return const GuessStatisticsBook();
    }
  }

  Future<void> save(GuessStatisticsBook statistics) =>
      _store.setString(storageKey, jsonEncode(statistics.toJson()));
}
