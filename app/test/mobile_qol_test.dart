import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/core/themes/quest_lantern.dart';
import 'package:sikhi_word_games_v2/features/achievements/presentation/achievement_feedback.dart';
import 'package:sikhi_word_games_v2/features/game_library/data/game_launch_preferences_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/domain/learn_letters_game.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/settings/presentation/settings_page.dart';

import 'word_scramble_page_test.dart' show fixture;

class DeferredVocabulary implements VocabularyRepository {
  final completer = Completer<List<VocabularyEntry>>();
  @override
  Future<List<VocabularyEntry>> load() => completer.future;
}

class FailingWrites extends MemoryKeyValueStore {
  bool fail = false;
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Test save failure');
    await super.setString(key, value);
  }
}

void surface(WidgetTester tester, Size size, [double scale = 1]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'settings navigation finishes promptly, reduced motion $reduced',
      (tester) async {
        final store = MemoryKeyValueStore();
        final settings = AppSettingsRepository(store);
        await settings.save(AppSettings(reducedMotion: reduced));
        await tester.pumpWidget(
          SikhiWordGamesApp(
            settingsRepository: settings,
            vocabularyRepository: const MemoryVocabularyRepository([]),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('App settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 130));
        final route = ModalRoute.of(tester.element(find.byType(SettingsPage)))!;
        expect(
          route.transitionDuration,
          reduced ? Duration.zero : const Duration(milliseconds: 120),
        );
        expect(route.animation!.status, AnimationStatus.completed);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a failed completion save does not announce a badge, retry does',
    (tester) async {
      final store = FailingWrites();
      final letters = LearnLettersRepository(store);
      final game = letters.newGame(practiceMode: LetterPracticeMode.listening);
      for (var i = 0; i < 4; i++) {
        game.answer(game.currentLetter.id);
        game.next();
      }
      await letters.save(game);
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          learnLettersRepository: letters,
          vocabularyRepository: const MemoryVocabularyRepository([]),
        ),
      );
      await tester.pumpAndSettle();
      final resume = find.byKey(const ValueKey('continue-game-learnLetters'));
      await tester.ensureVisible(resume);
      await tester.pumpAndSettle();
      await tester.tap(resume);
      await tester.pumpAndSettle();
      store.fail = true;
      final answer = find.byKey(
        ValueKey('letter-choice-${game.currentLetter.id}'),
      );
      await tester.ensureVisible(answer);
      await tester.pumpAndSettle();
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(letters.statistics.roundsCompleted, 0);
      expect(find.byKey(const ValueKey('achievement-unlocked')), findsNothing);
      store.fail = false;
      await tester.ensureVisible(find.text('Retry saving'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry saving'));
      await tester.pumpAndSettle();
      expect(letters.statistics.roundsCompleted, 1);
      expect(find.text('First page'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('achievement-unlocked')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final size in [
    const Size(320, 800),
    const Size(390, 844),
    const Size(800, 1100),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('all six home cards have equal heights at $size/$scale', (
        tester,
      ) async {
        surface(tester, size, scale);
        final store = MemoryKeyValueStore();
        final games = GuessGameRepository(store);
        await games.save(
          mode: LanguageMode.english,
          game: GuessGame(solution: 'BIRD', acceptedGuesses: {'BIRD'}),
        );
        await tester.pumpWidget(
          SikhiWordGamesApp(
            settingsRepository: AppSettingsRepository(store),
            gameRepository: games,
            vocabularyRepository: MemoryVocabularyRepository([
              fixture('BIRD', LanguageMode.english),
            ]),
          ),
        );
        await tester.pumpAndSettle();
        final heights = GameKind.values
            .map(
              (game) => tester
                  .getSize(
                    find.byKey(ValueKey('game-card-semantics-${game.name}')),
                  )
                  .height,
            )
            .toSet();
        expect(heights.length, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Learn Letters defaults to listening and offers both types from Play',
    (tester) async {
      surface(tester, const Size(390, 844));
      final store = MemoryKeyValueStore();
      final letters = LearnLettersRepository(store);
      final preferences = GameLaunchPreferencesRepository(store);
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          learnLettersRepository: letters,
          launchPreferencesRepository: preferences,
          vocabularyRepository: const MemoryVocabularyRepository([]),
        ),
      );
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('new-game-learnLetters'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(letters.restore()!.practiceMode, LetterPracticeMode.listening);
      expect(find.byKey(const ValueKey('letter-target')), findsNothing);
      expect(find.byIcon(Icons.hearing), findsNothing);
      final choice = letters.restore()!.choices.first;
      expect(
        tester.widget<Text>(find.text(choice.gurmukhi)).style!.fontSize,
        48,
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      final type = find.byTooltip('Game type');
      await tester.ensureVisible(type);
      await tester.pumpAndSettle();
      await tester.tap(type);
      await tester.pumpAndSettle();
      await tester.tap(find.text('See the letter and find its name'));
      await tester.tap(find.text('Start new game'));
      await tester.pumpAndSettle();
      expect(letters.restore()!.practiceMode, LetterPracticeMode.name);
      expect(
        preferences.load(GameKind.learnLetters).letterPracticeMode,
        LetterPracticeMode.name,
      );
      expect(find.byKey(const ValueKey('letter-target')), findsOneWidget);
      final roundId = letters.restore()!.roundId;
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      final resume = find.byKey(const ValueKey('continue-game-learnLetters'));
      await tester.ensureVisible(resume);
      await tester.pumpAndSettle();
      await tester.tap(resume);
      await tester.pumpAndSettle();
      expect(letters.restore()!.roundId, roundId);
      expect(letters.restore()!.practiceMode, LetterPracticeMode.name);
    },
  );

  for (final game in GameKind.values.where(
    (game) => game != GameKind.learnLetters,
  )) {
    testWidgets('$game header uses chosen language while loading', (
      tester,
    ) async {
      surface(tester, const Size(800, 1100));
      final store = MemoryKeyValueStore();
      final preferences = GameLaunchPreferencesRepository(store);
      await preferences.save(
        game,
        const GameLaunchOptions(
          language: LanguageMode.romanizedPanjabi,
          wordSize: 4,
        ),
      );
      final words = DeferredVocabulary();
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          launchPreferencesRepository: preferences,
          vocabularyRepository: words,
        ),
      );
      await tester.pumpAndSettle();
      final play = find.byKey(ValueKey('new-game-${game.name}'));
      await tester.ensureVisible(play);
      await tester.pumpAndSettle();
      await tester.tap(play);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 130));
      expect(
        tester.widget<GameLanguageHeader>(find.byType(GameLanguageHeader)).mode,
        LanguageMode.romanizedPanjabi,
      );
      expect(find.text('English'), findsNothing);
      words.completer.complete([
        for (final spelling in ['ASAN', 'KITAAB', 'PANI', 'PHUL'])
          fixture(spelling, LanguageMode.romanizedPanjabi),
      ]);
      await tester.pumpAndSettle();
      expect(
        tester.widget<GameLanguageHeader>(find.byType(GameLanguageHeader)).mode,
        LanguageMode.romanizedPanjabi,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final game in GameKind.values) {
    testWidgets('$game has the same ordered menu labels and icons', (
      tester,
    ) async {
      surface(tester, const Size(800, 1100));
      final store = MemoryKeyValueStore();
      final preferences = GameLaunchPreferencesRepository(store);
      await preferences.save(
        game,
        const GameLaunchOptions(language: LanguageMode.english, wordSize: 4),
      );
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          launchPreferencesRepository: preferences,
          vocabularyRepository: MemoryVocabularyRepository([
            for (final spelling in ['BIRD', 'FISH', 'TREE', 'SONG'])
              fixture(spelling, LanguageMode.english),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      final play = find.byKey(ValueKey('new-game-${game.name}'));
      await tester.ensureVisible(play);
      await tester.pumpAndSettle();
      await tester.tap(play);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is PopupMenuButton).first,
      );
      await tester.pumpAndSettle();
      final labels = [
        'New game',
        'Game settings',
        'How to play',
        'Statistics',
        'Dictionary',
        'Celebration settings',
      ];
      var previous = -1.0;
      for (final label in labels) {
        final text = find.text(label).last;
        final y = tester.getTopLeft(text).dy;
        expect(y, greaterThan(previous));
        previous = y;
        final row = find.ancestor(of: text, matching: find.byType(Row)).first;
        expect(
          find.descendant(of: row, matching: find.byType(Icon)),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('full alphabet and lantern both stay visible on a tablet', (
    tester,
  ) async {
    surface(tester, const Size(1024, 768));
    final store = MemoryKeyValueStore();
    final preferences = GameLaunchPreferencesRepository(store);
    await preferences.save(
      GameKind.wordQuest,
      const GameLaunchOptions(language: LanguageMode.english, wordSize: 4),
    );
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(store),
        launchPreferencesRepository: preferences,
        vocabularyRepository: MemoryVocabularyRepository([
          fixture('BIRD', LanguageMode.english),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('new-game-wordQuest')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-wordQuest')));
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.byType(QuestLantern)).dy, lessThan(768));
    final key = find.byKey(const ValueKey('word-quest-key-Z'));
    expect(tester.getBottomRight(key).dy, lessThan(768));
    await tester.tap(find.byTooltip('Use easier letter bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Use full alphabet'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestLantern), findsOneWidget);
    expect(tester.getBottomRight(find.byType(QuestLantern)).dy, lessThan(768));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'badges announce names once, queue awards and respect existing progress',
    (tester) async {
      final facts = <String, int>{};
      Widget mount() => MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.dark),
        home: AchievementFeedback(
          game: GameKind.wordScramble,
          facts: () => facts,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AchievementFeedback.check(context),
                child: const Text('Saved'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(mount());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('achievement-unlocked')), findsNothing);
      facts['wordScramble:won'] = 10;
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('Pieces together'), findsOneWidget);
      expect(find.text('1 more to celebrate'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss achievement'));
      await tester.pumpAndSettle();
      expect(find.text('Word maker'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss achievement'));
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('achievement-unlocked')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(mount());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('achievement-unlocked')), findsNothing);
    },
  );
}
