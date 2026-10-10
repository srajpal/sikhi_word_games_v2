import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/guess_the_word_page.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/domain/word_search_puzzle.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  for (final kind in ['Bujho', 'Khoj', 'Quest']) {
    for (final stale in [false, true]) {
      if (kind == 'Bujho' && !stale) continue;
      testWidgets(
        '$kind starts despite rejected ${stale ? 'stale' : 'empty'} save cleanup',
        (tester) async {
          final store = _RejectedClearStore();
          final guesses = GuessGameRepository(store);
          final search = WordSearchSessionRepository(store);
          final quest = WordQuestSessionRepository(store);
          if (stale) {
            switch (kind) {
              case 'Bujho':
                await guesses.save(
                  mode: LanguageMode.english,
                  game: GuessGame(
                    solution: 'HOLD',
                    acceptedGuesses: {'HOLD', 'PLAY'},
                  ),
                );
              case 'Khoj':
                await search.save(
                  mode: LanguageMode.english,
                  wordSize: 4,
                  puzzle: _puzzle('HOLD'),
                  foundWords: const {},
                );
              case 'Quest':
                await quest.save(
                  mode: LanguageMode.english,
                  wordSize: 4,
                  game: WordQuestGame(solution: 'HOLD'),
                );
            }
          }
          await tester.pumpWidget(
            MaterialApp(
              theme: AppThemes.forChoice(AppThemeChoice.modern),
              home: switch (kind) {
                'Bujho' => GuessTheWordPage(
                  vocabularyRepository: _restoreVocabulary,
                  statisticsRepository: GuessStatisticsRepository(store),
                  gameRepository: guesses,
                  solutionHistoryRepository: SolutionHistoryRepository(store),
                  hapticLevel: HapticFeedbackLevel.off,
                  reducedMotion: true,
                ),
                'Khoj' => WordSearchPage(
                  vocabularyRepository: _restoreVocabulary,
                  sessionRepository: search,
                  initialMode: LanguageMode.english,
                  initialWordSize: 4,
                ),
                _ => WordQuestPage(
                  vocabularyRepository: _restoreVocabulary,
                  sessionRepository: quest,
                  initialMode: LanguageMode.english,
                  initialWordSize: 4,
                  hapticLevel: HapticFeedbackLevel.off,
                  reducedMotion: true,
                ),
              },
            ),
          );
          await tester.pumpAndSettle();
          switch (kind) {
            case 'Bujho':
              expect(
                guesses.restore((_, _) => {'HOLD', 'PLAY'})?.game.solution,
                'PLAY',
              );
            case 'Khoj':
              expect(search.restore()?.puzzle.words.single.word, 'PLAY');
            case 'Quest':
              expect(quest.restore()?.game.solution, 'PLAY');
          }
          expect(find.textContaining('Unable to load'), findsNothing);
          expect(
            find.text(
              'Progress could not be saved on this device. You can keep playing.',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('Bujho restores precomposed nukta solutions with played turns', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final games = GuessGameRepository(store);
    const words = {'ਸ਼ਬਦਕ', 'ਕਲਮਕ'};
    final game = GuessGame(solution: 'ਸ਼ਬਦਕ', acceptedGuesses: words);
    game.submit('ਕਲਮਕ');
    await games.save(mode: LanguageMode.gurmukhi, game: game);
    final vocabulary = MemoryVocabularyRepository([
      for (final word in words)
        VocabularyEntry(
          id: word,
          language: VocabularyLanguage.panjabi,
          latin: 'TEST',
          gurmukhi: word,
          englishDefinition: 'A test fixture',
          latinLength: 4,
          gurmukhiLength: 4,
          acceptedGuess: true,
          solutionEligible: true,
          reviewStatus: ReviewStatus.machineChecked,
          source: 'Project editorial definition; original text for Sikhi Word Games',
        ),
    ]);
    for (var launch = 0; launch < 2; launch++) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.modern),
          home: GuessTheWordPage(
            vocabularyRepository: vocabulary,
            statisticsRepository: GuessStatisticsRepository(store),
            gameRepository: games,
            solutionHistoryRepository: SolutionHistoryRepository(store),
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final restored = games.restore((_, _) => words)!;
      expect(restored.mode, LanguageMode.gurmukhi);
      expect(restored.game.solution, game.solution);
      expect(restored.game.turns.single.guess, 'ਕਲਮਕ');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Bujho replaces a restored target that is now guess-only', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final games = GuessGameRepository(store);
    await games.save(
      mode: LanguageMode.english,
      game: GuessGame(solution: 'HOLD', acceptedGuesses: {'HOLD', 'PLAY'}),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: GuessTheWordPage(
          vocabularyRepository: _restoreVocabulary,
          statisticsRepository: GuessStatisticsRepository(store),
          gameRepository: games,
          solutionHistoryRepository: SolutionHistoryRepository(store),
          hapticLevel: HapticFeedbackLevel.off,
          reducedMotion: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final restored = games.restore((_, _) => {'HOLD', 'PLAY'});
    expect(restored?.mode, LanguageMode.english);
    expect(restored?.game.solution, 'PLAY');
  });

  testWidgets('Bujho preserves a restored target that remains playable', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final games = GuessGameRepository(store);
    await games.save(
      mode: LanguageMode.english,
      game: GuessGame(solution: 'PLAY', acceptedGuesses: {'PLAY', 'HOLD'}),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: GuessTheWordPage(
          vocabularyRepository: _restoreVocabulary,
          statisticsRepository: GuessStatisticsRepository(store),
          gameRepository: games,
          solutionHistoryRepository: SolutionHistoryRepository(store),
          hapticLevel: HapticFeedbackLevel.off,
          reducedMotion: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(games.restore((_, _) => {'HOLD', 'PLAY'})?.game.solution, 'PLAY');
  });

  testWidgets('Khoj replaces held targets but preserves valid saved puzzles', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final sessions = WordSearchSessionRepository(store);
    await sessions.save(
      mode: LanguageMode.english,
      wordSize: 4,
      puzzle: _puzzle('HOLD'),
      foundWords: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: WordSearchPage(
          vocabularyRepository: _restoreVocabulary,
          sessionRepository: sessions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(sessions.restore()!.mode, LanguageMode.english);
    expect(sessions.restore()!.wordSize, isNull);
    expect(
      sessions.restore()!.puzzle.words.map((word) => word.word),
      isNot(contains('HOLD')),
    );

    await sessions.save(
      mode: LanguageMode.english,
      wordSize: 4,
      puzzle: _puzzle('PLAY'),
      foundWords: const {},
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: WordSearchPage(
          vocabularyRepository: _restoreVocabulary,
          sessionRepository: sessions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(sessions.restore()!.puzzle.cells, _puzzle('PLAY').cells);
    expect(sessions.restore()!.wordSize, 4);
    expect(sessions.restore()!.puzzle.words.single.word, 'PLAY');
  });
}

class _RejectedClearStore extends MemoryKeyValueStore {
  @override
  Future<void> remove(String key) async =>
      throw StateError('Storage rejected removal');
}

WordSearchPuzzle _puzzle(String word) => WordSearchPuzzle(
  cells: [
    word.split(''),
    const ['A', 'B', 'C', 'D'],
    const ['E', 'F', 'G', 'H'],
    const ['I', 'J', 'K', 'L'],
  ],
  words: [
    PlacedWord(
      word: word,
      start: const GridPoint(0, 0),
      direction: WordSearchDirection.east,
    ),
  ],
);

const _restoreVocabulary = MemoryVocabularyRepository([
  VocabularyEntry(
    id: 'play',
    language: VocabularyLanguage.english,
    wordNetTagCount: 3,
    latin: 'PLAY',
    gurmukhi: null,
    englishDefinition: 'Take part in a game',
    latinLength: 4,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'hold',
    language: VocabularyLanguage.english,
    wordNetTagCount: 3,
    latin: 'HOLD',
    gurmukhi: null,
    englishDefinition: 'Keep in your hand',
    latinLength: 4,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: false,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);
