import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/statistics/game_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/data/game_launch_preferences_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';

void main() {
  test('fresh-start repositories remove only owned player data keys', () async {
    final store = MemoryKeyValueStore();
    for (final key in [
      GuessGameRepository.storageKey,
      GuessStatisticsRepository.storageKey,
      SolutionHistoryRepository.storageKey,
      WordSearchSessionRepository.storageKey,
      'wordSearch.statistics.v1',
      WordQuestSessionRepository.storageKey,
      'wordQuest.statistics.v1',
      WordBridgesRepository.storageKey,
      GameLaunchPreferencesRepository.storageKey,
      AppSettingsRepository.storageKey,
      for (final game in GameKind.values) 'gameGuide.v1.${game.name}',
    ]) {
      await store.setString(key, 'old player data');
    }
    await store.setString('unrelated.preference', 'keep');
    await store.setString('content.cache', 'keep');
    await GuessGameRepository(store).resetAll();
    await GuessStatisticsRepository(store).resetAll();
    await SolutionHistoryRepository(store).resetAll();
    await WordSearchSessionRepository(store).resetAll();
    await WordQuestSessionRepository(store).resetAll();
    await WordBridgesRepository(store).resetAll();
    await GameLaunchPreferencesRepository(store).resetAll();
    await GameGuideRepository(store).resetAll();
    await AppSettingsRepository(store).reset();
    expect(store.values, {
      'unrelated.preference': 'keep',
      'content.cache': 'keep',
    });
    for (final game in GameKind.values) {
      expect(GameGuideRepository(store).hasSeen(game), isFalse);
    }
  });

  test(
    'Jodo reset waits for pending writes across repository instances',
    () async {
      final store = _PausedStore();
      final repository = WordBridgesRepository(store);
      final pending = repository.save(
        mode: LanguageMode.english,
        game: _game(),
      );
      await store.started.future;
      var resetFinished = false;
      final reset = WordBridgesRepository(store)
          .resetAll()
          .then((_) => resetFinished = true);
      await Future<void>.delayed(Duration.zero);
      expect(resetFinished, isFalse);
      store.release.complete();
      await pending;
      await reset;
      expect(store.getString(WordBridgesRepository.storageKey), isNull);
      expect(repository.total.finishedSets, 0);
      expect(repository.restore(), isNull);
    },
  );

  test(
    'statistics reset drains a pending record from a separate instance',
    () async {
      final store = _PausedStore();
      final pending = GameStatisticsRepository(
        store,
        'wordQuest',
      ).record(mode: 'english', size: 5, won: true);
      await store.started.future;
      final reset = WordQuestSessionRepository(store).resetAll();
      store.release.complete();
      await pending;
      await reset;
      expect(GameStatisticsRepository(store, 'wordQuest').total.played, 0);
      expect(store.getString('wordQuest.statistics.v1'), isNull);
    },
  );

  test(
    'failed writes and removes report errors without poisoning later resets',
    () async {
      final store = _FailingStore();
      final repository = WordBridgesRepository(store);
      await expectLater(
        repository.save(mode: LanguageMode.english, game: _game()),
        throwsStateError,
      );
      store.failWrites = false;
      await repository.save(mode: LanguageMode.english, game: _game());
      store.failRemoves = true;
      await expectLater(repository.resetAll(), throwsStateError);
      expect(repository.hasActiveGame, isTrue);
      store.failRemoves = false;
      await repository.resetAll();
      expect(repository.hasActiveGame, isFalse);
      await repository.save(mode: LanguageMode.english, game: _game());
      expect(repository.hasActiveGame, isTrue);
    },
  );
}

WordBridgesGame _game() => WordBridgesGame(
  pairs: [
    for (var index = 0; index < 4; index++)
      BridgePair(id: '$index', word: 'word $index', meaning: 'meaning $index'),
  ],
);

class _PausedStore extends MemoryKeyValueStore {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> setString(String key, String value) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await super.setString(key, value);
  }
}

class _FailingStore extends MemoryKeyValueStore {
  bool failWrites = true;
  bool failRemoves = false;

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('write failed');
    await super.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    if (failRemoves) throw StateError('remove failed');
    await super.remove(key);
  }
}
