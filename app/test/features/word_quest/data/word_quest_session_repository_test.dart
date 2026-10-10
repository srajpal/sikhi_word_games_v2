import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';

void main() {
  test(
    'keyboard choice round-trips and old saves default to the full alphabet',
    () async {
      final store = MemoryKeyValueStore();
      final repository = WordQuestSessionRepository(store);
      await repository.save(
        mode: LanguageMode.english,
        wordSize: 5,
        fullKeyboard: false,
        game: WordQuestGame(solution: 'APPLE'),
      );
      expect(repository.restore()!.fullKeyboard, isFalse);
      final saved = jsonDecode(
        store.getString(WordQuestSessionRepository.storageKey)!,
      ) as Map<String, Object?>;
      saved.remove('fullKeyboard');
      store.values[WordQuestSessionRepository.storageKey] = jsonEncode(saved);
      expect(repository.restore()!.fullKeyboard, isTrue);
      for (final invalid in [null, 'false', 0, [], {}]) {
        store.values[WordQuestSessionRepository.storageKey] = jsonEncode({
          ...saved,
          'fullKeyboard': invalid,
        });
        expect(repository.restore(), isNull);
      }
    },
  );
  test('rejects an old conjunct size label while retaining progress', () async {
    final store = MemoryKeyValueStore()..values['player.progress'] = 'retained';
    final repository = WordQuestSessionRepository(store);
    await repository.save(
      mode: LanguageMode.gurmukhi,
      wordSize: 4,
      game: WordQuestGame(solution: 'ਅਪ੍ਰੈਲ'),
    );
    expect(repository.restore(), isNull);
    expect(repository.hasActiveGame, isFalse);
    expect(store.values['player.progress'], 'retained');
  });
  test(
    'old unfinished quests keep their original budget across repeated saves',
    () async {
      final store = MemoryKeyValueStore();
      final repository = WordQuestSessionRepository(store);
      store.values[WordQuestSessionRepository.storageKey] = jsonEncode({
        'schemaVersion': 1,
        'mode': 'english',
        'wordSize': 5,
        'game': (WordQuestGame(
          solution: 'APPLE',
          maximumTries: 6,
        )..guess('A')).toJson(),
      });
      final old = repository.restore()!;
      expect(old.game.maximumTries, 6);
      await repository.save(
        mode: old.mode,
        wordSize: old.wordSize,
        game: old.game,
      );
      expect(repository.restore()!.game.maximumTries, 6);
      await repository.save(
        mode: LanguageMode.english,
        wordSize: 5,
        game: WordQuestGame(solution: 'APPLE'),
      );
      expect(repository.restore()!.game.maximumTries, 4);
    },
  );
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
