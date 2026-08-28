import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';

void main() {
  test('persists used solution IDs offline', () async {
    final store = MemoryKeyValueStore();
    final repository = SolutionHistoryRepository(store);

    await repository.save(
      const SolutionHistory(
        usedIds: {'english_hero', 'english_book'},
        lastSelectedId: 'english_book',
      ),
    );

    expect(repository.load().usedIds, {'english_hero', 'english_book'});
    expect(repository.load().lastSelectedId, 'english_book');
  });

  test('malformed history falls back to an empty rotation', () {
    final store = MemoryKeyValueStore()
      ..values[SolutionHistoryRepository.storageKey] = 'not json';

    expect(SolutionHistoryRepository(store).load().usedIds, isEmpty);
  });
}
