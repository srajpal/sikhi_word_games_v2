import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';

void main() {
  test('rejects invalid guesses without consuming an attempt', () {
    final game = GuessGame(
      solution: 'APPLE',
      acceptedGuesses: {'APPLE', 'AMPLE'},
    );
    expect(game.submit('APP').rejection, GuessRejection.wrongLength);
    expect(game.submit('ANGEL').rejection, GuessRejection.notAccepted);
    expect(game.turns, isEmpty);
  });

  test('wins and rejects later submissions', () {
    final game = GuessGame(solution: 'APPLE', acceptedGuesses: {'APPLE'});
    expect(game.submit('APPLE').isAccepted, isTrue);
    expect(game.status, GuessGameStatus.won);
    expect(game.submit('APPLE').rejection, GuessRejection.gameOver);
  });

  test('loses after the configured number of accepted guesses', () {
    final game = GuessGame(
      solution: 'APPLE',
      acceptedGuesses: {'APPLE', 'AMPLE'},
      maximumAttempts: 2,
    );
    game.submit('AMPLE');
    game.submit('AMPLE');
    expect(game.status, GuessGameStatus.lost);
    expect(game.turns, hasLength(2));
  });

  test('supports Gurmukhi grapheme-based games', () {
    final game = GuessGame(solution: 'ਬਾਗ', acceptedGuesses: {'ਬਾਗ', 'ਘਰ'});
    expect(game.wordLength, 2);
    expect(game.submit('ਘਰ').isAccepted, isTrue);
    expect(game.submit('ਬਾਗ').isAccepted, isTrue);
    expect(game.status, GuessGameStatus.won);
  });

  test('round-trips an interrupted game through a versioned snapshot', () {
    final original = GuessGame(
      solution: 'APPLE',
      acceptedGuesses: {'APPLE', 'AMPLE'},
    )..submit('AMPLE');
    final restored = GuessGame.restore(
      json: original.toJson(),
      acceptedGuesses: {'APPLE', 'AMPLE'},
    );
    expect(restored.solution, 'APPLE');
    expect(restored.turns.single.guess, 'AMPLE');
    expect(restored.status, GuessGameStatus.playing);
  });

  test('rejects unsupported snapshot schemas', () {
    expect(
      () => GuessGame.restore(
        json: const {'schemaVersion': 2},
        acceptedGuesses: const {},
      ),
      throwsFormatException,
    );
  });
}
