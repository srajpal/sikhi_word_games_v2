import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_share.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';

void main() {
  test('builds a completed result without revealing guesses or solution', () {
    final game = GuessGame(
      solution: 'APPLE',
      acceptedGuesses: {'GRAPE', 'APPLE'},
    );
    game.submit('GRAPE');
    game.submit('APPLE');

    final result = buildSpoilerSafeResult(
      game: game,
      mode: LanguageMode.english,
    );

    expect(
      result,
      'Sikhi Word Games · English · 5 letters · 2/6\n\n××↔↔✓\n✓✓✓✓✓',
    );
    expect(result, isNot(contains('APPLE')));
    expect(result, isNot(contains('GRAPE')));
  });

  test('uses X for a lost game', () {
    final game = GuessGame(
      solution: 'APPLE',
      acceptedGuesses: {'GRAPE'},
      maximumAttempts: 1,
    );
    game.submit('GRAPE');
    expect(
      buildSpoilerSafeResult(game: game, mode: LanguageMode.mixedLatin),
      contains('X/1'),
    );
  });

  test('refuses to share an unfinished game', () {
    final game = GuessGame(solution: 'APPLE', acceptedGuesses: {'APPLE'});
    expect(
      () => buildSpoilerSafeResult(game: game, mode: LanguageMode.english),
      throwsStateError,
    );
  });
}
