import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/game_heading.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/core/themes/studio_navigation.dart';
import 'package:sikhi_word_games_v2/features/dictionary/presentation/dictionary_page.dart';
import 'package:sikhi_word_games_v2/features/game_library/data/game_launch_preferences_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  for (final size in [const Size(320, 800), const Size(1024, 768)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('primary navigation stays selected at $size and ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          SikhiWordGamesApp(
            settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
            vocabularyRepository: MemoryVocabularyRepository([_entry('APPLE')]),
          ),
        );
        await tester.pumpAndSettle();
        for (final destination in [
          StudioDestination.dictionary,
          StudioDestination.progress,
          StudioDestination.badges,
          StudioDestination.play,
        ]) {
          await tester.tap(
            find.byKey(ValueKey('destination-${destination.name}')),
          );
          await tester.pumpAndSettle();
          expect(find.byType(StudioNavigation), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            destination.index,
          );
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets('game feedback cannot follow a player to Play or Dictionary', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final preferences = GameLaunchPreferencesRepository(store);
    await preferences.save(
      GameKind.wordQuest,
      const GameLaunchOptions(language: LanguageMode.english, wordSize: 5),
    );
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(store),
        launchPreferencesRepository: preferences,
        vocabularyRepository: MemoryVocabularyRepository([_entry('APPLE')]),
      ),
    );
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('new-game-wordQuest'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.byType(StudioNavigation), findsNothing);
    await tester.tap(find.byKey(const ValueKey('word-quest-key-A')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Nice find! That letter is in the word.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.byKey(const ValueKey('destination-dictionary')));
    await tester.pumpAndSettle();
    expect(find.byType(DictionaryPage), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Khoj ignores old size preferences and includes long words', (
    tester,
  ) async {
    final sessions = WordSearchSessionRepository(MemoryKeyValueStore());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: WordSearchPage(
          vocabularyRepository: MemoryVocabularyRepository([
            for (final word in [
              'CAT',
              'BOOK',
              'APPLE',
              'PLANET',
              'ELEPHANT',
              'BLACKBERRIES',
            ])
              _entry(word),
          ]),
          sessionRepository: sessions,
          initialMode: LanguageMode.english,
          initialWordSize: 5,
          startFresh: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final session = sessions.restore()!;
    expect(session.wordSize, isNull);
    expect(session.puzzle.words.map((word) => word.word).toSet(), {
      'CAT',
      'BOOK',
      'APPLE',
      'PLANET',
      'ELEPHANT',
      'BLACKBERRIES',
    });
    expect(find.text('English'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GameHeading),
        matching: find.byType(GameLanguageHeader),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

VocabularyEntry _entry(String word) => VocabularyEntry(
  id: 'test_${word.toLowerCase()}',
  language: VocabularyLanguage.english,
  latin: word,
  gurmukhi: null,
  englishDefinition: 'A familiar everyday thing',
  latinLength: word.length,
  gurmukhiLength: null,
  acceptedGuess: true,
  solutionEligible: true,
  reviewStatus: ReviewStatus.machineChecked,
  source: 'Project editorial definition; original text for Sikhi Word Games',
);
