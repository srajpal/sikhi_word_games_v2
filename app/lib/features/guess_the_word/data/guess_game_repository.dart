import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../domain/guess_game.dart';

class GuessGameRepository {
  const GuessGameRepository(this._store);

  static const storageKey = 'guessTheWord.activeGame';
  final KeyValueStore _store;

  Future<void> save(GuessGame game) =>
      _store.setString(storageKey, jsonEncode(game.toJson()));

  GuessGame? restore(Set<String> acceptedGuesses) {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return null;
    try {
      return GuessGame.restore(
        json: jsonDecode(encoded) as Map<String, Object?>,
        acceptedGuesses: acceptedGuesses,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> clear() => _store.remove(storageKey);
}
