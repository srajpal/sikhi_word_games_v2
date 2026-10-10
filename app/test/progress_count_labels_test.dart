import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/achievements/domain/player_progress.dart';
import 'package:sikhi_word_games_v2/features/game_library/presentation/progress_page.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_statistics.dart';

void main() {
  for (final (count, round, puzzle, word, set, pair, answer) in [
    (0, 'rounds', 'puzzles', 'words', 'sets', 'pairs', 'first-try answers'),
    (1, 'round', 'puzzle', 'word', 'set', 'pair', 'first-try answer'),
    (2, 'rounds', 'puzzles', 'words', 'sets', 'pairs', 'first-try answers'),
  ]) {
    testWidgets('Progress uses correct count labels for $count', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.modern),
          home: ProgressPage(progress: _CountProgress(count)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('$count $round finished'), findsOneWidget);
      expect(
        find.text('$count $puzzle finished, $count $word found'),
        findsOneWidget,
      );
      expect(
        find.text('$count $set finished, $count $pair matched'),
        findsOneWidget,
      );
      expect(
        find.text('$count $round finished, $count $answer'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

/// Isolates presentation from statistics accounting and its game-specific limits.
class _CountProgress extends PlayerProgress {
  _CountProgress(this.count)
    : super(bujho: const GuessStatisticsBook(), khoj: {}, quest: {});
  final int count;
  @override
  Map<String, int> get facts => {
    'wordSearch:played': count,
    'wordSearch:words': count,
    'wordBridges:won': count,
    'wordBridges:words': count,
    'learnLetters:won': count,
    'learnLetters:firstTry': count,
  };
}
