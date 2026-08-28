import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_statistics.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';

void main() {
  test('records wins, losses, streaks, and guess distribution', () {
    var book = const GuessStatisticsBook();
    book = book.record(
      mode: LanguageMode.english,
      wordLength: 5,
      won: true,
      attempts: 3,
    );
    book = book.record(
      mode: LanguageMode.english,
      wordLength: 5,
      won: true,
      attempts: 2,
    );
    book = book.record(
      mode: LanguageMode.english,
      wordLength: 5,
      won: false,
      attempts: 6,
    );

    final statistics = book.forGame(LanguageMode.english, 5);
    expect(statistics.gamesPlayed, 3);
    expect(statistics.gamesWon, 2);
    expect(statistics.winPercentage, 67);
    expect(statistics.currentStreak, 0);
    expect(statistics.bestStreak, 2);
    expect(statistics.winDistribution, {3: 1, 2: 1});
    expect(book.forGame(LanguageMode.gurmukhi, 5).gamesPlayed, 0);
  });

  test('persists a versioned statistics book offline', () async {
    final store = MemoryKeyValueStore();
    final repository = GuessStatisticsRepository(store);
    final book = const GuessStatisticsBook().record(
      mode: LanguageMode.gurmukhi,
      wordLength: 4,
      won: true,
      attempts: 1,
    );

    await repository.save(book);

    final restored = repository.load().forGame(LanguageMode.gurmukhi, 4);
    expect(restored.gamesPlayed, 1);
    expect(restored.gamesWon, 1);
    expect(restored.currentStreak, 1);
    expect(restored.winDistribution, {1: 1});
  });

  test('falls back safely when stored statistics are malformed', () async {
    final store = MemoryKeyValueStore();
    await store.setString(GuessStatisticsRepository.storageKey, '{broken');
    expect(
      GuessStatisticsRepository(store)
          .load()
          .forGame(LanguageMode.english, 5)
          .gamesPlayed,
      0,
    );
  });
}
