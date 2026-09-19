import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/widgets/reset_app_data_dialog.dart';
import 'package:sikhi_word_games_v2/features/game_library/data/game_launch_preferences_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_statistics.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';

void main() {
  testWidgets('reset dialog blocks duplicate actions and Back while saving', (
    tester,
  ) async {
    final pending = Completer<void>();
    var resetCalls = 0;
    await tester.pumpWidget(
      _dialogHost(
        onReset: () {
          resetCalls++;
          return pending.future;
        },
      ),
    );
    await tester.tap(find.text('Open reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset all data'));
    await tester.pump();
    expect(resetCalls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    expect(find.text('Resetting...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Reset all app data?'), findsOneWidget);
    expect(resetCalls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('App data reset. Ready for a fresh start.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset confirmation stays readable at 320px and double text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var resetCalls = 0;
    await tester.pumpWidget(
      _dialogHost(
        textScaler: const TextScaler.linear(2),
        onReset: () async {
          resetCalls++;
        },
      ),
    );
    await tester.tap(find.text('Open reset'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Reset all app data?'), findsOneWidget);
    final cancel = find.widgetWithText(TextButton, 'Cancel');
    final reset = find.widgetWithText(FilledButton, 'Reset all data');
    for (final action in [cancel, reset]) {
      expect(action.hitTestable(), findsOneWidget);
      final bounds = tester.getRect(action);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(320));
      expect(bounds.height, greaterThanOrEqualTo(48));
    }
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(resetCalls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('cancel reset preserves every stored value', (tester) async {
    final store = MemoryKeyValueStore();
    await _seed(store);
    final before = Map<String, String>.of(store.values);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    await _openConfirmation(tester);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(store.values, before);
    expect(find.text('Reset all app data?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed reset clears owned data and restores fresh launch', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    await _seed(store);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    await _openConfirmation(tester);
    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();

    expect(store.values, {'unrelated.preference': 'keep me'});
    expect(find.byType(AlertDialog), findsNothing);
    final defaults = AppSettingsRepository(store).load();
    expect(defaults.theme, const AppSettings().theme);
    expect(defaults.hapticLevel, const AppSettings().hapticLevel);
    expect(defaults.reducedMotion, const AppSettings().reducedMotion);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme,
      AppThemes.forChoice(const AppSettings().theme).colorScheme,
    );
    expect(GuessGameRepository(store).hasActiveGame, isFalse);
    expect(GuessStatisticsRepository(store).load().records, isEmpty);
    expect(SolutionHistoryRepository(store).load().usedIds, isEmpty);
    expect(WordSearchSessionRepository(store).statistics.total.played, 0);
    expect(WordQuestSessionRepository(store).statistics.total.played, 0);
    expect(WordBridgesRepository(store).total.finishedSets, 0);
    for (final game in GameKind.values) {
      expect(GameGuideRepository(store).hasSeen(game), isFalse);
      final preferences = GameLaunchPreferencesRepository(store).load(game);
      expect(preferences.language, LanguageMode.english);
      expect(preferences.wordSize, 5);
    }

    final play = find.byKey(const ValueKey('new-game-guessTheWord'));
    await tester.ensureVisible(play);
    await tester.pumpAndSettle();
    await tester.tap(play);
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed reset reports partial failure and can be retried', (
    tester,
  ) async {
    final store = _FailingRemoveStore();
    await _seed(store);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    await _openConfirmation(tester);
    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Reset could not finish. Some data may have been cleared. Try again.',
      ),
      findsOneWidget,
    );
    expect(store.getString('unrelated.preference'), 'keep me');
    store.failRemove = false;
    expect(find.text('Could not reset: Bujho statistics.'), findsOneWidget);
    expect(store.values.keys.toSet(), {
      'unrelated.preference',
      GuessStatisticsRepository.storageKey,
    });
    final retry = find.text('Reset all data');
    if (retry.evaluate().isEmpty) {
      await _tapVisible(tester, find.text('Reset all app data'));
    }
    await _tapVisible(tester, find.text('Reset all data'));
    expect(store.values, {'unrelated.preference': 'keep me'});
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openConfirmation(WidgetTester tester) async {
  await tester.tap(find.byTooltip('App settings'));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text('Reset all app data'));
  expect(find.text('Reset all app data?'), findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _seed(MemoryKeyValueStore store) async {
  await store.setString('unrelated.preference', 'keep me');
  await AppSettingsRepository(store).save(
    const AppSettings(
      theme: AppThemeChoice.dark,
      hapticLevel: HapticFeedbackLevel.off,
      reducedMotion: true,
    ),
  );
  for (final game in GameKind.values) {
    await GameGuideRepository(store).markSeen(game);
    await GameLaunchPreferencesRepository(store).save(
      game,
      const GameLaunchOptions(language: LanguageMode.gurmukhi, wordSize: 6),
    );
  }
  await GuessGameRepository(store).save(
    game: GuessGame(solution: 'APPLE', acceptedGuesses: {'APPLE'}),
    mode: LanguageMode.english,
  );
  await GuessStatisticsRepository(store).save(
    const GuessStatisticsBook().record(
      mode: LanguageMode.english,
      wordLength: 5,
      won: true,
      attempts: 2,
    ),
  );
  await SolutionHistoryRepository(store).save(
    const SolutionHistory(
      usedIds: {'english_apple'},
      lastSelectedId: 'english_apple',
    ),
  );
  // Reset also removes unreadable/older stored payloads instead of preserving
  // them merely because a repository cannot restore them.
  for (final key in [
    WordSearchSessionRepository.storageKey,
    WordQuestSessionRepository.storageKey,
    WordBridgesRepository.storageKey,
    LearnLettersRepository.storageKey,
    WordSearchSessionRepository(store).statistics.storageKey,
    WordQuestSessionRepository(store).statistics.storageKey,
  ]) {
    await store.setString(key, '{}');
  }
}

SikhiWordGamesApp _app(MemoryKeyValueStore store) => SikhiWordGamesApp(
  settingsRepository: AppSettingsRepository(store),
  guideRepository: GameGuideRepository(store),
  vocabularyRepository: _vocabulary,
  gameRepository: GuessGameRepository(store),
  statisticsRepository: GuessStatisticsRepository(store),
  solutionHistoryRepository: SolutionHistoryRepository(store),
  wordSearchSessionRepository: WordSearchSessionRepository(store),
  wordQuestSessionRepository: WordQuestSessionRepository(store),
  wordBridgesRepository: WordBridgesRepository(store),
  learnLettersRepository: LearnLettersRepository(store),
  launchPreferencesRepository: GameLaunchPreferencesRepository(store),
);

class _FailingRemoveStore extends MemoryKeyValueStore {
  bool failRemove = true;

  @override
  Future<void> remove(String key) async {
    if (failRemove && key == GuessStatisticsRepository.storageKey) {
      throw StateError('Test storage unavailable');
    }
    await super.remove(key);
  }
}

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

Widget _dialogHost({
  required Future<void> Function() onReset,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  theme: AppThemes.forChoice(AppThemeChoice.sikhi),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => showResetAppDataDialog(context, onReset: onReset),
          child: const Text('Open reset'),
        ),
      ),
    ),
  ),
);
