import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/statistics/game_statistics_repository.dart';

void main() {
  test(
    'separates games, modes and lengths and persists finished retries',
    () async {
      final store = MemoryKeyValueStore();
      final quest = GameStatisticsRepository(store, 'wordQuest');
      await quest.record(mode: 'english', size: 4, won: false);
      await quest.record(mode: 'english', size: 4, won: true);
      await quest.record(mode: 'gurmukhi', size: 5, won: true, hintsUsed: 1);
      final restored = GameStatisticsRepository(store, 'wordQuest');
      expect(restored.forMode('english', 4).played, 2);
      expect(restored.forMode('english', 4).won, 1);
      expect(restored.forMode('english', 5).played, 0);
      expect(restored.total.played, 3);
      expect(restored.total.hintedWins, 1);
      expect(GameStatisticsRepository(store, 'wordSearch').total.played, 0);
    },
  );
  test(
    'corrupt or inconsistent statistics safely reset on next result',
    () async {
      final store = MemoryKeyValueStore();
      final repository = GameStatisticsRepository(store, 'wordSearch');
      for (final bad in [
        'broken',
        '{}',
        '{"schemaVersion":2}',
        '{"schemaVersion":1,"buckets":{"english:4":{"played":1,"won":2,"hintedWins":0,"wordsFound":0}}}',
      ]) {
        store.values[repository.storageKey] = bad;
        expect(repository.total.played, 0);
        await repository.record(
          mode: 'english',
          size: null,
          won: true,
          wordsFound: 8,
        );
        expect(repository.total.played, 1);
        expect(repository.total.wordsFound, 8);
      }
    },
  );
}
