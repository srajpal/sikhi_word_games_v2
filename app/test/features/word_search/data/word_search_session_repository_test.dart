import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/domain/word_search_puzzle.dart';

void main() {
  test('round-trips an unfinished puzzle', () async {
    final repository = WordSearchSessionRepository(MemoryKeyValueStore());
    final puzzle = WordSearchPuzzle(
      cells: List.generate(5, (_) => List.filled(5, 'A')),
      words: [
        const PlacedWord(
          word: 'CAT',
          start: GridPoint(0, 0),
          direction: WordSearchDirection.east,
        ),
        const PlacedWord(
          word: 'DOG',
          start: GridPoint(1, 0),
          direction: WordSearchDirection.east,
        ),
      ],
    );

    await repository.save(
      mode: LanguageMode.english,
      wordSize: 5,
      puzzle: puzzle,
      foundWords: {'CAT'},
    );

    final restored = repository.restore();
    expect(restored?.mode, LanguageMode.english);
    expect(restored?.wordSize, 5);
    expect(restored?.puzzle.cells, puzzle.cells);
    expect(restored?.puzzle.words.length, 2);
    expect(restored?.foundWords, {'CAT'});
    expect(repository.hasActiveGame, isTrue);
  });

  test('rejects malformed or completed snapshots', () async {
    final store = MemoryKeyValueStore();
    final repository = WordSearchSessionRepository(store);
    await store.setString(WordSearchSessionRepository.storageKey, '{}');
    expect(repository.restore, returnsNormally);
    expect(repository.restore(), isNull);
    expect(repository.hasActiveGame, isFalse);

    final puzzle = WordSearchPuzzle(
      cells: List.generate(5, (_) => List.filled(5, 'A')),
      words: [
        const PlacedWord(
          word: 'CAT',
          start: GridPoint(0, 0),
          direction: WordSearchDirection.east,
        ),
      ],
    );
    await repository.save(
      mode: LanguageMode.english,
      wordSize: 3,
      puzzle: puzzle,
      foundWords: {'CAT'},
    );
    expect(repository.restore(), isNull);
    expect(repository.hasActiveGame, isFalse);
  });
}
