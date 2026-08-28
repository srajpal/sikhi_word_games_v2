import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/keyboard_feedback.dart';

void main() {
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
