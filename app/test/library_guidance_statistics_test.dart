import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/data/game_launch_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_statistics.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('NotoSerif')
          ..addFont(rootBundle.load('assets/fonts/noto_serif/NotoSerif.ttf')))
        .load();
    await (FontLoader(
      'NotoSans',
    )..addFont(rootBundle.load('assets/fonts/noto_sans/NotoSans.ttf'))).load();
  });
  for (final saved in [false, true]) {
    testWidgets('320px library actions share a row with saved=$saved', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryKeyValueStore();
      final games = GuessGameRepository(store);
      if (saved) {
        await games.save(
          mode: LanguageMode.english,
          game: GuessGame(solution: 'APPLE', acceptedGuesses: const {'APPLE'}),
        );
      }
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          gameRepository: games,
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(
        const ValueKey('game-card-semantics-guessTheWord'),
      );
      final newGame = find.byKey(const ValueKey('new-game-guessTheWord'));
      final options = find.descendant(
        of: card,
        matching: find.byTooltip('New game options'),
      );
      final newRect = tester.getRect(newGame);
      final optionsRect = tester.getRect(options);
      expect(newRect.center.dy, closeTo(optionsRect.center.dy, 1));
      expect(newRect.height, greaterThanOrEqualTo(48));
      expect(optionsRect.height, greaterThanOrEqualTo(48));
      expect(optionsRect.width, greaterThanOrEqualTo(48));
      if (saved) {
        final continueButton = find.byKey(
          const ValueKey('continue-game-guessTheWord'),
        );
        final continueRect = tester.getRect(continueButton);
        expect(continueRect.center.dy, closeTo(newRect.center.dy, 1));
        expect(continueRect.height, greaterThanOrEqualTo(48));
        expect(continueRect.right, lessThan(newRect.left));
      } else {
        expect(find.text('Continue'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('two-column gallery keeps each game semantics together', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final store = MemoryKeyValueStore();
      await tester.pumpWidget(
        SikhiWordGamesApp(settingsRepository: AppSettingsRepository(store)),
      );
      await tester.pumpAndSettle();
      final bujho = tester.getSemantics(
        find.byKey(const ValueKey('game-card-semantics-guessTheWord')),
      );
      final khoj = tester.getSemantics(
        find.byKey(const ValueKey('game-card-semantics-wordSearch')),
      );
      final bujhoTree = bujho.toStringDeep();
      final khojTree = khoj.toStringDeep();
      expect(bujho.id, isNot(khoj.id));
      expect(bujhoTree, contains('Bujho'));
      expect(bujhoTree, contains('Guess the Word'));
      expect(bujhoTree, contains('Figure out the word, one guess at a time.'));
      expect(bujhoTree, contains('New game'));
      expect(bujhoTree, isNot(contains('Khoj')));
      expect(khojTree, contains('Khoj'));
      expect(khojTree, contains('Word Search'));
      expect(khojTree, contains('Find hidden words in a sea of letters.'));
      expect(khojTree, contains('New game'));
      expect(khojTree, isNot(contains('Bujho')));
      expect(
        tester
            .getCenter(find.byKey(const ValueKey('new-game-guessTheWord')))
            .dy,
        tester.getCenter(find.byKey(const ValueKey('new-game-wordSearch'))).dy,
        reason: 'Tablet game-card actions should align across each row',
      );
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('game-card-semantics-guessTheWord')),
            )
            .width,
        tester
            .getSize(
              find.byKey(const ValueKey('game-card-semantics-wordSearch')),
            )
            .width,
        reason: 'Bujho shares the same tablet card width as every other game',
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('home summary retains old Bujho totals and separates new games', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final bujho = GuessStatisticsRepository(store);
    final khoj = WordSearchSessionRepository(store);
    final quest = WordQuestSessionRepository(store);
    await bujho.save(
      const GuessStatisticsBook().record(
        mode: LanguageMode.english,
        wordLength: 4,
        won: true,
        attempts: 2,
      ),
    );
    await khoj.statistics.record(
      mode: 'english',
      size: 4,
      won: true,
      wordsFound: 6,
    );
    await quest.statistics.record(mode: 'english', size: 4, won: false);
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(store),
        statisticsRepository: bujho,
        wordSearchSessionRepository: khoj,
        wordQuestSessionRepository: quest,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose a game'), findsNothing);
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('3 rounds finished'), findsOneWidget);
    expect(find.text('7 words solved'), findsOneWidget);
    expect(find.text('1 puzzle finished, 6 words found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'app routes show independent first-launch guides and retain Skip',
    (tester) async {
      final store = MemoryKeyValueStore();
      final guides = GameGuideRepository(store);
      final preferences = GameLaunchPreferencesRepository(store);
      for (final game in GameKind.values) {
        await preferences.save(
          game,
          const GameLaunchOptions(language: LanguageMode.english, wordSize: 5),
        );
      }
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          guideRepository: guides,
          launchPreferencesRepository: preferences,
          vocabularyRepository: const MemoryVocabularyRepository([
            VocabularyEntry(
              id: 'apple',
              language: VocabularyLanguage.english,
              wordNetTagCount: 3,
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
          ]),
        ),
      );
      await tester.pumpAndSettle();
      for (var index = 0; index < 3; index++) {
        final button = find.byKey(
          ValueKey('new-game-${GameKind.values[index].name}'),
        );
        // The compact gallery puts two games in the same row. Center the
        // exact control and settle layout before tapping after a route return.
        await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
        await tester.pumpAndSettle();
        expect(button.hitTestable(), findsOneWidget);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text('Step 1 of 3'), findsOneWidget);
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(guides.hasSeen(GameKind.values[index]), isTrue);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
      }
      final button = find.byKey(const ValueKey('new-game-guessTheWord'));
      await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
