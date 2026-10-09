import '../../../core/statistics/game_statistics_repository.dart';
import '../../guess_the_word/domain/guess_statistics.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../../word_bridges/data/word_bridges_repository.dart';
import '../../learn_letters/data/learn_letters_repository.dart';
import '../../word_scramble/data/word_scramble_repository.dart';

/// A read-only projection of durable game statistics, never a second total.
class PlayerProgress {
  PlayerProgress({
    required this.bujho,
    required this.khoj,
    required this.quest,
    this.bridges,
    this.letters,
    this.scramble,
  });
  final GuessStatisticsBook bujho;
  final Map<String, GameStatistics> khoj;
  final Map<String, GameStatistics> quest;
  final WordBridgesRepository? bridges;
  final LearnLettersRepository? letters;
  final WordScrambleRepository? scramble;

  Map<String, int> get facts {
    final facts = <String, int>{};
    void put(GameKind game, String metric, int count) =>
        facts['${game.name}:$metric'] = count;
    void buckets(GameKind game, Map<String, GameStatistics> rows) {
      final total = rows.values.fold(
        const GameStatistics(),
        (sum, value) => sum.plus(value),
      );
      put(game, 'played', total.played);
      put(game, 'won', total.won);
      put(game, 'words', total.wordsFound);
      put(game, 'hinted', total.hintedWins);
      put(game, 'unhinted', total.won - total.hintedWins);
      for (final mode in LanguageMode.values) {
        put(
          game,
          mode.name,
          rows.entries
              .where((e) => e.key.startsWith('${mode.name}:'))
              .fold(0, (sum, e) => sum + e.value.won),
        );
      }
      put(
        game,
        'languages',
        LanguageMode.values
            .where((mode) => (facts['${game.name}:${mode.name}'] ?? 0) > 0)
            .length,
      );
      put(
        game,
        'sizes',
        const [4, 5, 6]
            .where(
              (size) => rows.entries.any(
                (e) => e.key.endsWith(':$size') && e.value.won > 0,
              ),
            )
            .length,
      );
    }

    buckets(GameKind.wordSearch, khoj);
    buckets(GameKind.wordQuest, quest);
    final records = bujho.records;
    const game = GameKind.guessTheWord;
    put(
      game,
      'played',
      records.values.fold(0, (sum, value) => sum + value.gamesPlayed),
    );
    put(
      game,
      'won',
      records.values.fold(0, (sum, value) => sum + value.gamesWon),
    );
    put(
      game,
      'firstGuess',
      records.values.fold(
        0,
        (sum, value) => sum + (value.winDistribution[1] ?? 0),
      ),
    );
    put(
      game,
      'quick',
      records.values.fold(
        0,
        (sum, value) =>
            sum +
            value.winDistribution.entries
                .where((e) => e.key <= 3)
                .fold(0, (sum, e) => sum + e.value),
      ),
    );
    put(
      game,
      'bestStreak',
      records.values.fold(
        0,
        (best, value) => best > value.bestStreak ? best : value.bestStreak,
      ),
    );
    for (final mode in LanguageMode.values) {
      put(
        game,
        mode.name,
        records.entries
            .where((e) => e.key.startsWith('${mode.name}:'))
            .fold(0, (sum, e) => sum + e.value.gamesWon),
      );
    }
    put(
      game,
      'sizes',
      const [4, 5, 6]
          .where(
            (size) => records.entries.any(
              (e) => e.key.endsWith(':$size') && e.value.gamesWon > 0,
            ),
          )
          .length,
    );
    final bridgeTotal = bridges?.total ?? const BridgeStatistics();
    put(GameKind.wordBridges, 'won', bridgeTotal.finishedSets);
    put(GameKind.wordBridges, 'played', bridgeTotal.finishedSets);
    put(GameKind.wordBridges, 'words', bridgeTotal.pairsMatched);
    for (final mode in LanguageMode.values) {
      put(
        GameKind.wordBridges,
        mode.name,
        bridges?.forMode(mode).finishedSets ?? 0,
      );
    }
    put(GameKind.wordBridges, 'perfect', bridges?.perfectSets ?? 0);
    put(GameKind.wordBridges, 'distinct', bridges?.distinctWords ?? 0);
    put(GameKind.wordBridges, 'long', bridges?.longWordSets ?? 0);
    final letterTotal = letters?.statistics ?? const LearnLettersStatistics();
    put(GameKind.learnLetters, 'won', letterTotal.roundsCompleted);
    put(GameKind.learnLetters, 'played', letterTotal.roundsCompleted);
    put(GameKind.learnLetters, 'firstTry', letterTotal.firstTryCorrect);
    put(
      GameKind.learnLetters,
      'practiced',
      letters?.mastery.values.where((count) => count >= 3).length ?? 0,
    );
    put(GameKind.learnLetters, 'listening', letters?.listeningRounds ?? 0);
    put(GameKind.learnLetters, 'perfect', letters?.perfectRounds ?? 0);
    final scrambleTotal = scramble?.total ?? const ScrambleStatistics();
    put(GameKind.wordScramble, 'won', scrambleTotal.solved);
    put(GameKind.wordScramble, 'played', scrambleTotal.solved);
    put(GameKind.wordScramble, 'words', scrambleTotal.solved);
    put(GameKind.wordScramble, 'unhinted', scrambleTotal.unhinted);
    put(GameKind.wordScramble, 'firstCheck', scrambleTotal.firstCheck);
    put(GameKind.wordScramble, 'long', scrambleTotal.long);
    put(GameKind.wordScramble, 'repeated', scrambleTotal.repeated);
    for (final mode in LanguageMode.values) {
      put(
        GameKind.wordScramble,
        mode.name,
        scramble?.forMode(mode).solved ?? 0,
      );
    }
    return Map.unmodifiable(facts);
  }
}
