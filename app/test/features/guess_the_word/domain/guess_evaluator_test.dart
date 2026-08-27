import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_evaluator.dart';

void main() {
  group('GuessEvaluator', () {
    test('marks exact, present, and absent letters', () {
      final result = GuessEvaluator.evaluate(solution: 'APPLE', guess: 'AMPLE');
      expect(result.map((letter) => letter.result), [
        LetterResult.correct,
        LetterResult.absent,
        LetterResult.correct,
        LetterResult.correct,
        LetterResult.correct,
      ]);
    });

    test('does not award duplicate guess letters more than once', () {
      final result = GuessEvaluator.evaluate(solution: 'APPLE', guess: 'PAPAL');
      expect(result.map((letter) => letter.result), [
        LetterResult.present,
        LetterResult.present,
        LetterResult.correct,
        LetterResult.absent,
        LetterResult.present,
      ]);
    });

    test('reserves exact matches before duplicate present letters', () {
      final result = GuessEvaluator.evaluate(solution: 'LEVEL', guess: 'HELLO');
      expect(result.map((letter) => letter.result), [
        LetterResult.absent,
        LetterResult.correct,
        LetterResult.present,
        LetterResult.present,
        LetterResult.absent,
      ]);
    });

    test('counts a Gurmukhi base letter and vowel sign as one grapheme', () {
      expect(GuessEvaluator.visibleLength('ਕਿ'), 1);
      expect(GuessEvaluator.graphemes('ਕਿਤਾਬ'), ['ਕਿ', 'ਤਾ', 'ਬ']);
    });

    test('rejects a different grapheme length', () {
      expect(
        () => GuessEvaluator.evaluate(solution: 'APPLE', guess: 'APP'),
        throwsArgumentError,
      );
    });
  });
}
