import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/achievements/domain/achievement.dart';
import 'package:sikhi_word_games_v2/features/achievements/domain/player_progress.dart';
import 'package:sikhi_word_games_v2/features/achievements/presentation/achievements_page.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_statistics.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/domain/learn_letters_game.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_game.dart';

void main() {
  test(
    '60 distinct goals, ten per game, clamp progress and unlock at threshold',
    () {
      expect(achievements.length, 60);
      expect(achievements.map((badge) => badge.id).toSet().length, 60);
      for (final game in GameKind.values) {
        expect(achievements.where((badge) => badge.game == game).length, 10);
      }
      for (final badge in achievements) {
        final key = '${badge.game.name}:${badge.metric}';
        expect(badge.earned({key: badge.target - 1}), isFalse);
        expect(badge.earned({key: badge.target}), isTrue);
        expect(badge.progress({key: badge.target + 10}), badge.target);
        expect(badge.progress({key: -1}), 0);
      }
    },
  );
  test('old statistics qualify without fabricating unrecorded milestones', () {
    final book = const GuessStatisticsBook().record(
      mode: LanguageMode.gurmukhi,
      wordLength: 4,
      won: true,
      attempts: 2,
    );
    final facts = PlayerProgress(bujho: book, khoj: {}, quest: {}).facts;
    expect(
      achievements.singleWhere((b) => b.id == 'bujho_gurmukhi').earned(facts),
      isTrue,
    );
    expect(facts['guessTheWord:quick'], 1);
    expect(facts['guessTheWord:sizes'], 1);
    expect(facts['wordBridges:perfect'], 0);
    expect(facts['learnLetters:listening'], 0);
  });
  test(
    'completed listening and perfect bridge facts persist once and reset',
    () async {
      final store = MemoryKeyValueStore();
      final letters = LearnLettersRepository(store);
      final round = letters.newGame(practiceMode: LetterPracticeMode.listening);
      for (var i = 0; i < 5; i++) {
        round.answer(round.currentLetter.id);
        if (i < 4) round.next();
      }
      await letters.save(round);
      await letters.save(round);
      expect(LearnLettersRepository(store).listeningRounds, 1);
      expect(letters.perfectRounds, 1);
      final bridges = WordBridgesRepository(store);
      final set = WordBridgesGame(
        pairs: const [
          BridgePair(id: 'a', word: 'APPLE', meaning: 'Round fruit'),
          BridgePair(id: 'b', word: 'CHAIR', meaning: 'A seat'),
          BridgePair(id: 'c', word: 'MILK', meaning: 'White drink'),
          BridgePair(id: 'd', word: 'DOOR', meaning: 'Entrance panel'),
        ],
      );
      for (final pair in set.wordOrder) {
        set.selectWord(pair.id);
        set.selectMeaning(pair.id);
      }
      await bridges.save(mode: LanguageMode.english, game: set);
      await bridges.save(mode: LanguageMode.english, game: set);
      expect(WordBridgesRepository(store).perfectSets, 1);
      expect(bridges.distinctWords, 4);
      expect(bridges.longWordSets, 1);
      await letters.resetAll();
      await bridges.resetAll();
      expect(letters.listeningRounds, 0);
      expect(bridges.perfectSets, 0);
    },
  );
  testWidgets(
    'badges remain readable at 320px and doubled text in all themes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final theme in AppThemeChoice.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.forChoice(theme),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(2),
              ),
              child: AchievementsPage(
                progress: PlayerProgress(
                  bujho: const GuessStatisticsBook(),
                  khoj: {},
                  quest: {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('First discovery'), findsOneWidget);
        await tester.ensureVisible(find.text('All thirty-five'));
        expect(tester.takeException(), isNull);
      }
    },
  );
}
