import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';

void main() {
  test('saves, restores, and clears an interrupted game', () async {
    final store = MemoryKeyValueStore();
    final repository = GuessGameRepository(store);
    final game = GuessGame(
      solution: 'APPLE',
      acceptedGuesses: {'APPLE', 'AMPLE'},
    )..submit('AMPLE');

    await repository.save(game);
    final restored = repository.restore({'APPLE', 'AMPLE'});
    expect(restored, isNotNull);
    expect(restored!.turns.single.guess, 'AMPLE');

    await repository.clear();
    expect(repository.restore({'APPLE', 'AMPLE'}), isNull);
  });

  test('ignores malformed saved data safely', () {
    final store = MemoryKeyValueStore()
      ..values[GuessGameRepository.storageKey] = '{invalid';
    expect(GuessGameRepository(store).restore({'APPLE'}), isNull);
  });
}
