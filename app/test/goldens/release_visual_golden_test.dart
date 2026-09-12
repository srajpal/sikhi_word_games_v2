import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/guess_the_word_page.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/domain/word_search_puzzle.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'NotoSans',
    )..addFont(rootBundle.load('assets/fonts/noto_sans/NotoSans.ttf'))).load();
    await (FontLoader('NotoSansGurmukhi')..addFont(
          rootBundle.load(
            'assets/fonts/noto_sans_gurmukhi/NotoSansGurmukhi.ttf',
          ),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final themeChoice in AppThemeChoice.values) {
    final themeName = themeChoice.name;

    testWidgets('shared components render in $themeName', (tester) async {
      _setGoldenSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.forChoice(themeChoice),
          home: const _SharedComponentsFixture(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('images/shared_components_$themeName.png'),
      );
    }, tags: 'golden');

    testWidgets('Bujho restored round renders in $themeName', (tester) async {
      _setGoldenSurface(tester);
      final store = MemoryKeyValueStore();
      final games = GuessGameRepository(store);
      await games.save(
        mode: LanguageMode.english,
        game: GuessGame(solution: 'APPLE', acceptedGuesses: {'APPLE', 'GRAPE'})
          ..submit('GRAPE'),
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.forChoice(themeChoice),
          home: GuessTheWordPage(
            vocabularyRepository: _vocabulary,
            statisticsRepository: GuessStatisticsRepository(store),
            gameRepository: games,
            solutionHistoryRepository: SolutionHistoryRepository(store),
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('images/bujho_restored_$themeName.png'),
      );
    }, tags: 'golden');

    testWidgets('Khoj active puzzle renders in $themeName', (tester) async {
      _setGoldenSurface(tester);
      final sessions = WordSearchSessionRepository(MemoryKeyValueStore());
      await sessions.save(
        mode: LanguageMode.english,
        wordSize: 4,
        puzzle: _puzzle,
        foundWords: const {},
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.forChoice(themeChoice),
          home: WordSearchPage(
            vocabularyRepository: _vocabulary,
            sessionRepository: sessions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('images/khoj_active_$themeName.png'),
      );
    }, tags: 'golden');

    testWidgets('Word Quest completed round renders in $themeName', (
      tester,
    ) async {
      _setGoldenSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.forChoice(themeChoice),
          home: WordQuestPage(
            vocabularyRepository: _vocabulary,
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
            sessionRepository: WordQuestSessionRepository(
              MemoryKeyValueStore(),
            ),
            initialMode: LanguageMode.english,
            initialWordSize: 5,
            startFresh: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('YOUR CLUE'), findsOneWidget);
      for (final (key, character) in [
        (LogicalKeyboardKey.keyA, 'a'),
        (LogicalKeyboardKey.keyP, 'p'),
        (LogicalKeyboardKey.keyL, 'l'),
        (LogicalKeyboardKey.keyE, 'e'),
      ]) {
        await tester.sendKeyDownEvent(key, character: character);
        await tester.sendKeyUpEvent(key);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('You found the word!'), findsOneWidget);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('images/word_quest_complete_$themeName.png'),
      );
    }, tags: 'golden');
  }
}

void _setGoldenSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _SharedComponentsFixture extends StatelessWidget {
  const _SharedComponentsFixture();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Visual system')),
      body: GameBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GamePanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Shared game components',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        GameStatusPill(
                          icon: Icons.translate,
                          child: Text('English'),
                        ),
                        GameStatusPill(
                          icon: Icons.favorite,
                          child: Text('5 tries'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        for (final color in [
                          tokens.correct,
                          tokens.present,
                          tokens.absent,
                        ]) ...[
                          Expanded(
                            child: Container(
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: tokens.tileRadius,
                              ),
                              child: const Text(
                                'A',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    const GameGradientButton(
                      label: 'Start game',
                      icon: Icon(Icons.play_arrow),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _puzzle = WordSearchPuzzle(
  cells: [
    ['T', 'E', 'S', 'T', 'A', 'B'],
    ['A', 'B', 'C', 'D', 'E', 'F'],
    ['G', 'H', 'I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P', 'Q', 'R'],
    ['S', 'T', 'U', 'V', 'W', 'X'],
    ['Y', 'Z', 'A', 'B', 'C', 'D'],
  ],
  words: [
    PlacedWord(
      word: 'TEST',
      start: GridPoint(0, 0),
      direction: WordSearchDirection.east,
    ),
  ],
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
  VocabularyEntry(
    id: 'english_grape',
    language: VocabularyLanguage.english,
    latin: 'GRAPE',
    gurmukhi: null,
    englishDefinition: 'A small fruit',
    latinLength: 5,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: false,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'english_test',
    language: VocabularyLanguage.english,
    latin: 'TEST',
    gurmukhi: null,
    englishDefinition: 'A check of how something works',
    latinLength: 4,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);
