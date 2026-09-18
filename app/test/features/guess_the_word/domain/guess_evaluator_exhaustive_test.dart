import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_evaluator.dart';

void main() {
  for (final alphabet in [
    ['A', 'B'],
    ['ਕਿ', 'ਤਾ'],
  ]) {
    test('exhaustive duplicate accounting for $alphabet at lengths 4 to 6', () {
      for (var length = 4; length <= 6; length++) {
        final words = [
          for (var mask = 0; mask < (1 << length); mask++)
            [for (var i = 0; i < length; i++) alphabet[(mask >> i) & 1]],
        ];
        for (final solution in words) {
          for (final guess in words) {
            final result = GuessEvaluator.evaluate(
              solution: solution.join(),
              guess: guess.join(),
            );
            for (var i = 0; i < length; i++) {
              expect(
                result[i].result == LetterResult.correct,
                solution[i] == guess[i],
              );
            }
            for (final letter in alphabet) {
              final awarded = result
                  .where(
                    (r) =>
                        r.grapheme == letter && r.result != LetterResult.absent,
                  )
                  .length;
              expect(
                awarded,
                min(
                  solution.where((c) => c == letter).length,
                  guess.where((c) => c == letter).length,
                ),
              );
            }
          }
        }
      }
    });
  }
}
