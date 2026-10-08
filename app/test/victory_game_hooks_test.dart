import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/widgets/victory_celebration.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/presentation/word_bridges_page.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';

import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/guess_the_word_page.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WordBridgesContent content;
  setUpAll(() async {
    content = await WordBridgesContent.load(AssetVocabularyRepository());
  });
  testWidgets(
    'Jodo celebrates final match once and stays silent when reopened',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final repository = WordBridgesRepository(MemoryKeyValueStore());
        var sounds = 0;
        Widget page() => _scope(
          game: GameKind.wordBridges,
          playSound: () async {
            sounds++;
          },
          child: WordBridgesPage(
            vocabularyRepository: AssetVocabularyRepository(),
            repository: repository,
            contentFuture: Future.value(content),
            initialMode: LanguageMode.english,
          ),
        );
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        expect(sounds, 0);
        final pairs = repository.restore()!.game.wordOrder;
        Future<void> activate(String side, String id) async {
          final finder = find.byKey(ValueKey('bridge-$side-$id'));
          await tester.ensureVisible(finder);
          final node = tester.getSemantics(finder);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
            node.id,
            SemanticsAction.tap,
          );
          await tester.pumpAndSettle();
        }

        await activate('word', pairs[0].id);
        await activate('meaning', pairs[1].id);
        expect(sounds, 0, reason: 'A mismatch must not celebrate.');
        for (var index = 0; index < pairs.length; index++) {
          await activate('word', pairs[index].id);
          expect(sounds, 0);
          await activate('meaning', pairs[index].id);
          expect(sounds, index == pairs.length - 1 ? 1 : 0);
        }
        await tester.pumpAndSettle();
        expect(sounds, 1);
        expect(repository.restore(), isNull);
        expect(repository.total.finishedSets, 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        expect(repository.restore()!.game.isComplete, isFalse);
        expect(repository.total.finishedSets, 1);
        expect(
          sounds,
          1,
          reason: 'Reopening after a completed set is not a new win.',
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final win in [true, false]) {
    testWidgets('Bujho ${win ? 'win celebrates once' : 'loss stays silent'}', (
      tester,
    ) async {
      final store = MemoryKeyValueStore();
      final repository = GuessGameRepository(store);
      final vocabulary = MemoryVocabularyRepository([
        ...await _vocabulary.load(),
        _bread,
      ]);
      final game = GuessGame(
        solution: 'APPLE',
        acceptedGuesses: {'APPLE', 'BREAD'},
      );
      for (var attempt = 0; attempt < 5; attempt++) {
        game.submit('BREAD');
      }
      await repository.save(game: game, mode: LanguageMode.english);
      var sounds = 0;
      await tester.pumpWidget(
        _scope(
          game: GameKind.guessTheWord,
          playSound: () async {
            sounds++;
          },
          child: GuessTheWordPage(
            vocabularyRepository: vocabulary,
            statisticsRepository: GuessStatisticsRepository(store),
            gameRepository: repository,
            solutionHistoryRepository: SolutionHistoryRepository(store),
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(sounds, 0);
      const keys = {
        'A': LogicalKeyboardKey.keyA,
        'P': LogicalKeyboardKey.keyP,
        'L': LogicalKeyboardKey.keyL,
        'E': LogicalKeyboardKey.keyE,
        'B': LogicalKeyboardKey.keyB,
        'R': LogicalKeyboardKey.keyR,
        'D': LogicalKeyboardKey.keyD,
      };
      for (final letter in (win ? 'APPLE' : 'BREAD').split('')) {
        await tester.sendKeyEvent(keys[letter]!, character: letter);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.text(win ? 'You found it!' : 'No guesses remain.'),
        findsOneWidget,
      );
      expect(sounds, win ? 1 : 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(sounds, win ? 1 : 0);
      expect(repository.hasActiveGame, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Khoj celebrates only the final word and ignores completed selections',
    (tester) async {
      final vocabulary = MemoryVocabularyRepository([
        ...await _vocabulary.load(),
        _bread,
      ]);
      final repository = WordSearchSessionRepository(MemoryKeyValueStore());
      var sounds = 0;
      await tester.pumpWidget(
        _scope(
          game: GameKind.wordSearch,
          playSound: () async {
            sounds++;
          },
          child: WordSearchPage(
            vocabularyRepository: vocabulary,
            sessionRepository: repository,
            initialMode: LanguageMode.english,
            initialWordSize: 5,
            startFresh: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(sounds, 0);
      final words = repository.restore()!.puzzle.words;
      expect(words.length, greaterThan(1));
      for (var index = 0; index < words.length; index++) {
        final cells = words[index].cells();
        final start = cells.first;
        final end = cells.last;
        final startCenter = tester.getCenter(
          find.byKey(ValueKey('word-search-cell-${start.row}-${start.column}')),
        );
        final endCenter = tester.getCenter(
          find.byKey(ValueKey('word-search-cell-${end.row}-${end.column}')),
        );
        final gesture = await tester.startGesture(startCenter);
        await gesture.moveTo(endCenter);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(sounds, index == words.length - 1 ? 1 : 0);
      }
      expect(repository.hasActiveGame, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(sounds, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final useHint in [false, true]) {
    testWidgets(
      'Quest celebrates completion by ${useHint ? 'hint' : 'guess'} once',
      (tester) async {
        final repository = WordQuestSessionRepository(MemoryKeyValueStore());
        final game = WordQuestGame(solution: 'APPLE')
          ..guess('A')
          ..guess('P')
          ..guess('L');
        await repository.save(
          mode: LanguageMode.english,
          wordSize: 5,
          game: game,
        );
        var sounds = 0;
        await tester.pumpWidget(
          _scope(
            game: GameKind.wordQuest,
            playSound: () async {
              sounds++;
            },
            child: WordQuestPage(
              vocabularyRepository: _vocabulary,
              hapticLevel: HapticFeedbackLevel.off,
              reducedMotion: true,
              sessionRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(sounds, 0, reason: 'Resuming progress must not celebrate.');
        final action = find.byKey(
          ValueKey(useHint ? 'word-quest-hint' : 'word-quest-key-E'),
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(sounds, 1);
        await tester.pump(const Duration(seconds: 3));
        expect(
          sounds,
          1,
          reason: 'Completion rebuilds must not celebrate again.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _scope({
  required GameKind game,
  required Future<void> Function() playSound,
  required Widget child,
}) => MaterialApp(
  theme: AppThemes.forChoice(AppThemeChoice.modern),
  home: VictoryCelebration(
    game: game,
    settings: const AppSettings(reducedMotion: true),
    onSettingsChanged: (_) {},
    playSound: playSound,
    child: child,
  ),
);

const _vocabulary = MemoryVocabularyRepository([
  VocabularyEntry(
    id: 'english_apple',
    language: VocabularyLanguage.english,
    latin: 'APPLE',
    gurmukhi: null,
    englishDefinition: 'A round fruit',
    latinLength: 5,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);

const _bread = VocabularyEntry(
  id: 'english_bread',
  language: VocabularyLanguage.english,
  latin: 'BREAD',
  gurmukhi: null,
  englishDefinition: 'Food baked from flour and water',
  latinLength: 5,
  gurmukhiLength: null,
  acceptedGuess: true,
  solutionEligible: true,
  reviewStatus: ReviewStatus.machineChecked,
  source: 'Project editorial definition; original text for Sikhi Word Games',
);
