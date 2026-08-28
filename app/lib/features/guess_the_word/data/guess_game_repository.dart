import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../domain/guess_game.dart';
import '../domain/language_mode.dart';

class RestoredGuessSession {
  const RestoredGuessSession({required this.mode, required this.game});

  final LanguageMode mode;
  final GuessGame game;
}

class GuessGameRepository {
  const GuessGameRepository(this._store);

  static const storageKey = 'guessTheWord.activeGame';
  final KeyValueStore _store;

  Future<void> save({required GuessGame game, required LanguageMode mode}) =>
      _store.setString(
        storageKey,
        jsonEncode({
          'schemaVersion': 1,
          'mode': mode.name,
          'game': game.toJson(),
        }),
      );

  RestoredGuessSession? restore(
    Set<String> Function(LanguageMode mode, int wordLength) acceptedGuesses,
  ) {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      if (json['schemaVersion'] != 1 ||
          json['mode'] is! String ||
          json['game'] is! Map<String, Object?>) {
        return null;
      }
      final matchingModes = LanguageMode.values.where(
        (mode) => mode.name == json['mode'],
      );
      if (matchingModes.isEmpty) return null;
      final mode = matchingModes.first;
      final gameJson = json['game']! as Map<String, Object?>;
      final solution = gameJson['solution'];
      if (solution is! String) return null;
      final provisional = GuessGame(
        solution: solution,
        acceptedGuesses: const {},
      );
      final game = GuessGame.restore(
        json: gameJson,
        acceptedGuesses: acceptedGuesses(mode, provisional.wordLength),
      );
      if (game.status != GuessGameStatus.playing) return null;
      return RestoredGuessSession(mode: mode, game: game);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> clear() => _store.remove(storageKey);
}
