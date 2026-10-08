import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';

void main() {
  test(
    'rejects unsupported word sizes and changed adaptive try budgets',
    () async {
      final store = MemoryKeyValueStore();
      final repository = WordQuestSessionRepository(store);
      for (final size in [-1, 0, 3, 7, 100]) {
        await repository.save(
          mode: LanguageMode.english,
          wordSize: size,
          game: WordQuestGame(solution: 'APPLE'),
        );
        expect(
          repository.restore(),
          isNull,
          reason: 'Unsupported word size $size',
        );
        expect(repository.hasActiveGame, isFalse);
      }
      for (final tries in [1, 5, 7, 100]) {
        store.values[WordQuestSessionRepository.storageKey] = jsonEncode({
          'schemaVersion': 1,
          'mode': 'english',
          'wordSize': 5,
          'game': {
            ...WordQuestGame(solution: 'APPLE').toJson(),
            'maximumTries': tries,
          },
        });
        expect(
          repository.restore(),
          isNull,
          reason: 'Changed try budget $tries',
        );
        expect(repository.hasActiveGame, isFalse);
      }
    },
  );
  test('round-trips an unfinished quest', () async {
    final repository = WordQuestSessionRepository(MemoryKeyValueStore());
    final game = WordQuestGame(solution: 'APPLE');
    game.guess('A');

    await repository.save(mode: LanguageMode.english, wordSize: 5, game: game);

    final restored = repository.restore();
    expect(restored?.mode, LanguageMode.english);
    expect(restored?.wordSize, 5);
    expect(restored?.game.solution, 'APPLE');
    expect(restored?.game.guessedGraphemes, {'A'});
    expect(repository.hasActiveGame, isTrue);
  });

  test('does not restore a completed quest', () async {
    final repository = WordQuestSessionRepository(MemoryKeyValueStore());
    final game = WordQuestGame(solution: 'A');
    game.guess('A');

    await repository.save(mode: LanguageMode.english, wordSize: 1, game: game);

    expect(repository.restore(), isNull);
    expect(repository.hasActiveGame, isFalse);
  });
}
