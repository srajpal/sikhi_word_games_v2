import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/game_library/data/game_launch_preferences_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';

void main() {
  test('keeps launch choices separate for each game mode', () async {
    final repository = GameLaunchPreferencesRepository(MemoryKeyValueStore());

    await repository.save(
      GameKind.guessTheWord,
      const GameLaunchOptions(language: null, wordSize: 6),
    );
    await repository.save(
      GameKind.wordSearch,
      const GameLaunchOptions(language: LanguageMode.gurmukhi, wordSize: null),
    );

    final guess = repository.load(GameKind.guessTheWord);
    expect(guess.language, isNull);
    expect(guess.wordSize, 6);

    final search = repository.load(GameKind.wordSearch);
    expect(search.language, LanguageMode.gurmukhi);
    expect(search.wordSize, isNull);

    final quest = repository.load(GameKind.wordQuest);
    expect(quest.language, LanguageMode.english);
    expect(quest.wordSize, 5);
  });

  test('falls back safely for malformed or unsupported preferences', () async {
    final store = MemoryKeyValueStore();
    final repository = GameLaunchPreferencesRepository(store);
    await store.setString(
      GameLaunchPreferencesRepository.storageKey,
      '{"guessTheWord":{"language":"not-a-language","wordSize":9}}',
    );

    final preferences = repository.load(GameKind.guessTheWord);
    expect(preferences.language, LanguageMode.english);
    expect(preferences.wordSize, 5);
  });
}
