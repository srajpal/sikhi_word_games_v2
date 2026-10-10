import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/achievements/domain/achievement.dart';
import 'package:sikhi_word_games_v2/features/achievements/domain/player_progress.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_statistics.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/data/word_scramble_repository.dart';

import 'word_scramble_game_test.dart' show scramble, solve;

void main() {
  test(
    'unsupported schema fails closed and a new save recovers independently',
    () async {
      final store = MemoryKeyValueStore();
      final repository = WordScrambleRepository(store);
      final completed = scramble();
      solve(completed);
      await repository.save(mode: LanguageMode.english, game: completed);
      await repository.save(mode: LanguageMode.english, game: scramble('BOOK'));
      final snapshot = jsonDecode(
        store.getString(WordScrambleRepository.storageKey)!,
      ) as Map<String, Object?>;
      for (final version in [0, 2, '1', null]) {
        await store.setString(
          WordScrambleRepository.storageKey,
          jsonEncode({...snapshot, 'schemaVersion': version}),
        );
        expect(repository.restore(), isNull);
        expect(repository.total.solved, 0);
        expect(repository.seen(LanguageMode.english), isEmpty);
      }
      await repository.save(mode: LanguageMode.english, game: scramble('MICE'));
      expect(repository.restore()!.game.spelling, 'MICE');
      expect(repository.total.solved, 0);
    },
  );
  test('partial moves restore exactly and keep their Romanized view', () async {
    final store = MemoryKeyValueStore(),
        repo = WordScrambleRepository(MemoryKeyValueStore());
    final repository = WordScrambleRepository(store), game = scramble('ĀSĀN');
    game.place(1);
    final first = repository.save(
      mode: LanguageMode.romanizedPanjabi,
      game: game,
      simpleRomanized: false,
    );
    game.place(0);
    await first;
    expect(repository.restore()!.game.slots.whereType<int>(), [1]);
    await repository.save(mode: LanguageMode.romanizedPanjabi, game: game);
    final saved = WordScrambleRepository(store).restore()!;
    expect(saved.game.slots, game.slots);
    expect(saved.simpleRomanized, isFalse);
    expect(repo.total.solved, 0);
  });
  test(
    'completion records once, clears the active word and unlocks badges',
    () async {
      final store = MemoryKeyValueStore(), game = scramble();
      final repo = WordScrambleRepository(store);
      await repo.save(mode: LanguageMode.english, game: game);
      solve(game);
      await Future.wait([
        repo.save(mode: LanguageMode.english, game: game),
        WordScrambleRepository(store)
            .save(mode: LanguageMode.english, game: game),
      ]);
      expect(repo.total.solved, 1);
      expect(repo.total.repeated, 1);
      expect(repo.total.firstCheck, 1);
      expect(repo.total.unhinted, 1);
      expect(repo.restore(), isNull);
      final facts = PlayerProgress(
        bujho: const GuessStatisticsBook(),
        khoj: {},
        quest: {},
        scramble: repo,
      ).facts;
      expect(
        achievements.singleWhere((a) => a.id == 'scramble_first').earned(facts),
        isTrue,
      );
      expect(facts['wordScramble:played'], 1);
    },
  );
  test('a late completion cannot remove a newer saved word', () async {
    final store = MemoryKeyValueStore();
    final repo = WordScrambleRepository(store),
        old = scramble(),
        next = scramble('BOOK');
    await repo.save(mode: LanguageMode.english, game: old);
    await repo.save(mode: LanguageMode.english, game: next);
    solve(old);
    await repo.save(mode: LanguageMode.english, game: old);
    expect(repo.restore()!.game.roundId, next.roundId);
    expect(repo.total.solved, 1);
  });
  test('language counters, hint use and long words are isolated', () async {
    final store = MemoryKeyValueStore();
    final repo = WordScrambleRepository(store), game = scramble('BANANA');
    game.hint();
    solve(game);
    await repo.save(mode: LanguageMode.romanizedPanjabi, game: game);
    expect(repo.forMode(LanguageMode.english).solved, 0);
    expect(repo.total.long, 1);
    expect(repo.total.unhinted, 0);
    await repo.resetAll();
    expect(repo.total.solved, 0);
    expect(repo.seen(LanguageMode.romanizedPanjabi), isEmpty);
  });
  test(
    'malformed history recovers without discarding valid statistics',
    () async {
      final store = MemoryKeyValueStore();
      final repo = WordScrambleRepository(store), game = scramble();
      solve(game);
      await repo.save(mode: LanguageMode.english, game: game);
      final state = jsonDecode(
        store.getString(WordScrambleRepository.storageKey)!,
      ) as Map<String, dynamic>;
      state['seen'] = false;
      state['completedRoundIds'] = 'bad';
      state['previous'] = 42;
      state['session'] = {'game': 'bad'};
      await store.setString(
        WordScrambleRepository.storageKey,
        jsonEncode(state),
      );
      expect(repo.restore(), isNull);
      await repo.save(mode: LanguageMode.english, game: scramble('BOOK'));
      expect(repo.hasActiveGame, isTrue);
      expect(repo.total.solved, 1);
    },
  );
}
