import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';

void main() {
  test('saves, restores, and clears an interrupted game', () async {
    final store = MemoryKeyValueStore();
    final repository = GuessGameRepository(store);
    final game = GuessGame(
      solution: 'APPLE',
      acceptedGuesses: {'APPLE', 'AMPLE'},
    )..submit('AMPLE');

    await repository.save(game: game, mode: LanguageMode.english);
    final restored = repository.restore((mode, length) {
      expect(mode, LanguageMode.english);
      expect(length, 5);
      return {'APPLE', 'AMPLE'};
    });
    expect(restored, isNotNull);
    expect(restored!.mode, LanguageMode.english);
    expect(restored.game.turns.single.guess, 'AMPLE');

    await repository.clear();
    expect(repository.restore((mode, length) => {'APPLE', 'AMPLE'}), isNull);
  });

  test('ignores malformed saved data safely', () {
    final store = MemoryKeyValueStore()
      ..values[GuessGameRepository.storageKey] = '{invalid';
    expect(
      GuessGameRepository(store).restore((mode, length) => {'APPLE'}),
      isNull,
    );
    expect(GuessGameRepository(store).hasActiveGame, isFalse);
  });

  test('does not advertise structurally invalid saved data', () {
    final store = MemoryKeyValueStore()
      ..values[GuessGameRepository.storageKey] =
          '{"schemaVersion":1,"mode":"english","game":'
          '{"schemaVersion":1,"solution":"APPLE",'
          '"maximumAttempts":0,"guesses":[]}}';

    final repository = GuessGameRepository(store);
    expect(repository.hasActiveGame, isFalse);
    expect(repository.restore((mode, length) => {'APPLE'}), isNull);
  });

  test('does not advertise invalid guesses or a completed game', () async {
    final store = MemoryKeyValueStore();
    final repository = GuessGameRepository(store);
    store.values[GuessGameRepository.storageKey] =
        '{"schemaVersion":1,"mode":"english","game":'
        '{"schemaVersion":1,"solution":"APPLE",'
        '"maximumAttempts":6,"guesses":[123]}}';
    expect(repository.hasActiveGame, isFalse);

    final completed = GuessGame(solution: 'APPLE', acceptedGuesses: {'APPLE'})
      ..submit('APPLE');
    await repository.save(game: completed, mode: LanguageMode.english);
    expect(repository.hasActiveGame, isFalse);
  });

  test('does not restore a completed game', () async {
    final store = MemoryKeyValueStore();
    final repository = GuessGameRepository(store);
    final game = GuessGame(solution: 'APPLE', acceptedGuesses: {'APPLE'})
      ..submit('APPLE');
    await repository.save(game: game, mode: LanguageMode.english);
    expect(repository.restore((mode, length) => {'APPLE'}), isNull);
  });
}
