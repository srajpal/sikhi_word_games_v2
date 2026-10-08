import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_evaluator.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/keyboard_feedback.dart';

void main() {
  test(
    'keyboard retains the strongest clue across duplicates and later guesses',
    () {
      final game =
          GuessGame(solution: 'APPLE', acceptedGuesses: {'PAPAL', 'GRAPE'})
            ..submit('PAPAL')
            ..submit('GRAPE');
      expect(keyboardLetterResults(game.turns), {
        'P': LetterResult.correct,
        'A': LetterResult.present,
        'L': LetterResult.present,
        'G': LetterResult.absent,
        'R': LetterResult.absent,
        'E': LetterResult.correct,
      });
    },
  );

  test('disables letters known to be absent', () {
    final game = GuessGame(solution: 'APPLE', acceptedGuesses: {'GRAPE'})
      ..submit('GRAPE');

    expect(unavailableKeyboardCharacters(game.turns), {'G', 'R'});
  });

  test('keeps a repeated letter available when any occurrence matches', () {
    final game = GuessGame(solution: 'APPLE', acceptedGuesses: {'PAPAL'})
      ..submit('PAPAL');

    final unavailable = unavailableKeyboardCharacters(game.turns);
    expect(unavailable, isNot(contains('A')));
    expect(unavailable, isNot(contains('P')));
  });
}
